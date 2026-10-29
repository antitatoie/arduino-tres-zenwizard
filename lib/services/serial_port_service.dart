import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/telemetry_data.dart';
import 'ble_service.dart';
import 'serial_port_adapter.dart';

class SerialPortService {
  final SerialPortAdapter _adapter = createSerialPortAdapter();
  final BleService _bleService;
  StreamSubscription<String>? _lineSubscription;
  StreamSubscription<TelemetryData>? _bleTelemetrySubscription;
  Timer? _mockTimer;
  String? _activePortName;

  final StreamController<TelemetryData> _telemetryController =
      StreamController<TelemetryData>.broadcast();

  SerialPortService({BleService? bleService})
      : _bleService = bleService ?? BleService() {
    _bleTelemetrySubscription =
        _bleService.telemetryStream.listen((TelemetryData data) {
      if (isMockRunning) {
        _mockTimer?.cancel();
        _mockTimer = null;
      }
      if (!_telemetryController.isClosed) {
        _telemetryController.add(data);
      }
    });
  }

  BleService get bleService => _bleService;

  Stream<TelemetryData> get telemetryStream => _telemetryController.stream;

  bool get isUsbConnected => _adapter.isOpen;

  bool get isBleConnected => _bleService.isConnected;

  bool get isConnected => isUsbConnected || isBleConnected;

  bool get isMockRunning => _mockTimer != null && _mockTimer!.isActive;

  bool get isDesktopSerialSupported => !kIsWeb && _adapter.isSupported;

  String get activePortLabel {
    if (isBleConnected) {
      return _bleService.activeDeviceLabel;
    }
    if (isUsbConnected) {
      return _activePortName ?? 'USB Serial';
    }
    return 'Mock Mode (Sim)';
  }

  List<String> getAvailablePorts() {
    if (kIsWeb || !_adapter.isSupported) return const [];
    return _adapter.getAvailablePorts();
  }

  Future<bool> connect(String portName, {int baudRate = 9600}) async {
    if (kIsWeb || !_adapter.isSupported) {
      startMockStream();
      return false;
    }

    await disconnectUsb();

    try {
      if (!_adapter.openPort(portName, baudRate)) {
        return false;
      }

      _activePortName = portName;
      final inputStream = _adapter.inputStream;
      if (inputStream == null) {
        await disconnectUsb();
        return false;
      }

      // CRITICAL FIX: Buffer partial Uint8List USB chunks until '\n'
      _lineSubscription = inputStream
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
      await disconnectUsb();
      return false;
    }
  }

  /// Starts simulated telemetry when running in Chrome/Web or without hardware
  void startMockStream() {
    if (isConnected) return;
    _mockTimer?.cancel();
    if (!_telemetryController.isClosed) {
      _telemetryController.add(
        TelemetryData(
          lux: 419.0,
          temperature: 23.8,
          humidity: 52.0,
          timestamp: DateTime.now(),
        ),
      );
    }

    int tick = 0;
    _mockTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (isConnected || _telemetryController.isClosed) return;
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
    final startIdx = rawLine.indexOf('{');
    final endIdx = rawLine.lastIndexOf('}');
    if (startIdx < 0 || endIdx <= startIdx) return;

    final line = rawLine.substring(startIdx, endIdx + 1).trim();

    // Guard against unquoted NaN from legacy firmware
    if (line.contains('nan') || line.contains('NaN')) return;

    try {
      final Map<String, dynamic> decoded = jsonDecode(line);
      if (decoded.containsKey('status')) {
        debugPrint('Arduino Handshake: ${decoded['status']}');
        return;
      }

      final telemetry = TelemetryData.fromJson(decoded);
      if (!_telemetryController.isClosed) {
        _telemetryController.add(telemetry);
      }
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
    if (isUsbConnected) {
      try {
        _adapter.writeBytes(Uint8List.fromList(utf8.encode(payload)));
      } catch (e) {
        debugPrint('Serial TX Error: $e');
      }
    }
    if (isBleConnected) {
      _bleService.sendCommand(payload);
    }
  }

  Future<void> disconnectUsb() async {
    _mockTimer?.cancel();
    _mockTimer = null;

    await _lineSubscription?.cancel();
    _lineSubscription = null;

    _adapter.closePort();
    _activePortName = null;
  }

  Future<void> disconnect() async {
    await disconnectUsb();
    if (isBleConnected) {
      await _bleService.disconnect();
    }
  }

  void dispose() {
    _bleTelemetrySubscription?.cancel();
    disconnectUsb();
    _bleService.dispose();
    _telemetryController.close();
  }
}
