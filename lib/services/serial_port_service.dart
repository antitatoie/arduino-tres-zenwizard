import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import '../models/telemetry_data.dart';

class SerialPortService {
  SerialPort? _port;
  SerialPortReader? _reader;
  StreamSubscription<String>? _lineSubscription;
  Timer? _mockTimer;
  String? _activePortName;

  final StreamController<TelemetryData> _telemetryController =
      StreamController<TelemetryData>.broadcast();

  Stream<TelemetryData> get telemetryStream => _telemetryController.stream;

  bool get isConnected => _port != null && _port!.isOpen;

  bool get isMockRunning => _mockTimer != null && _mockTimer!.isActive;

  String get activePortLabel =>
      isConnected ? (_activePortName ?? 'USB Serial') : 'Mock Mode (Sim)';

  List<String> getAvailablePorts() {
    if (kIsWeb) return const [];
    try {
      return SerialPort.availablePorts;
    } catch (e) {
      debugPrint('SerialPort enumeration unavailable: $e');
      return const [];
    }
  }

  Future<bool> connect(String portName, {int baudRate = 9600}) async {
    if (kIsWeb) {
      startMockStream();
      return false;
    }

    await disconnect();

    try {
      final port = SerialPort(portName);
      if (!port.openReadWrite()) {
        port.dispose();
        return false;
      }

      final config = SerialPortConfig()
        ..baudRate = baudRate
        ..bits = 8
        ..stopBits = 1
        ..parity = SerialPortParity.none
        ..setFlowControl(SerialPortFlowControl.none);
      port.config = config;

      _port = port;
      _activePortName = portName;
      _reader = SerialPortReader(port);

      // CRITICAL FIX: Buffer partial Uint8List USB chunks until '\n'
      _lineSubscription = _reader!.stream
          .map((Uint8List data) => utf8.decode(data, allowMalformed: true))
          .transform(const LineSplitter())
          .listen(
            _handleIncomingLine,
            onError: (err) => debugPrint('Serial RX Error: $err'),
            cancelOnError: false,
          );

      // Wait for Arduino Uno CH340 DTR auto-reset bootloader (2000ms)
      await Future.delayed(const Duration(milliseconds: 2000));
      return true;
    } catch (e) {
      debugPrint('Failed to connect to $portName: $e');
      await disconnect();
      return false;
    }
  }

  /// Starts simulated telemetry when running in Chrome/Web or without hardware
  void startMockStream() {
    _mockTimer?.cancel();
    _telemetryController.add(
      TelemetryData(
        lux: 419.0,
        temperature: 23.8,
        humidity: 52.0,
        timestamp: DateTime.now(),
      ),
    );

    int tick = 0;
    _mockTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      tick++;
      final double simulatedLux = 415.0 + ((tick % 5) * 2.0);
      final double simulatedTemp = 23.6 + ((tick % 3) * 0.1);
      final double simulatedHum = 52.0 + ((tick % 2) * 1.0);
      _telemetryController.add(
        TelemetryData(
          lux: simulatedLux,
          temperature: simulatedTemp,
          humidity: simulatedHum,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  void _handleIncomingLine(String rawLine) {
    final line = rawLine.trim();
    if (!line.startsWith('{') || !line.endsWith('}')) return;

    // Guard against unquoted NaN from legacy firmware
    if (line.contains('nan') || line.contains('NaN')) return;

    try {
      final Map<String, dynamic> decoded = jsonDecode(line);
      if (decoded.containsKey('status')) {
        debugPrint('Arduino Handshake: ${decoded['status']}');
        return;
      }

      final telemetry = TelemetryData.fromJson(decoded);
      _telemetryController.add(telemetry);
    } catch (e) {
      debugPrint('Dropped malformed frame: $line');
    }
  }

  void sendCommand(String command) {
    final payload = command.endsWith('\n') ? command : '$command\n';
    if (!isConnected) {
      debugPrint('Mock TX -> ${payload.trim()}');
      return;
    }
    try {
      _port!.write(Uint8List.fromList(utf8.encode(payload)));
    } catch (e) {
      debugPrint('Serial TX Error: $e');
    }
  }

  Future<void> disconnect() async {
    _mockTimer?.cancel();
    _mockTimer = null;

    await _lineSubscription?.cancel();
    _lineSubscription = null;

    _reader?.close();
    _reader = null;

    if (_port != null) {
      try {
        if (_port!.isOpen) _port!.close();
        _port!.dispose();
      } catch (_) {}
      _port = null;
      _activePortName = null;
    }
  }

  void dispose() {
    disconnect();
    _telemetryController.close();
  }
}