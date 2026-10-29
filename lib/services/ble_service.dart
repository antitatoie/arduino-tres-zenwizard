import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/telemetry_data.dart';

class BleDiscoveredDevice {
  final String id;
  final String name;
  final int rssi;
  final bool isHm10Candidate;
  final BluetoothDevice? device;

  const BleDiscoveredDevice({
    required this.id,
    required this.name,
    required this.rssi,
    required this.isHm10Candidate,
    this.device,
  });
}

class BleService {
  static const String targetDeviceId = '7C:01:0A:39:14:00';
  static const String hm10ServiceUuid = '0000ffe0-0000-1000-8000-00805f9b34fb';
  static const String hm10ServiceShort = 'ffe0';
  static const String hm10CharacteristicUuid =
      '0000ffe1-0000-1000-8000-00805f9b34fb';
  static const String hm10CharacteristicShort = 'ffe1';

  static const List<String> hm10KnownNames = [
    'HMSoft',
    'HM-10',
    'BT05',
    'MLT-BT05',
    'BleSerial',
    'ZenWizard',
  ];

  static const int maxBlePacketBytes = 20;

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _uartCharacteristic;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;
  StreamSubscription<List<int>>? _lineSubscription;
  StreamController<List<int>>? _rawByteChunkController;
  String _bleRxBuffer = '';
  int _notificationCount = 0;
  bool _isAutoConnecting = false;

  final List<BleDiscoveredDevice> _discoveredDevices = [];
  bool _isScanning = false;
  String? _connectedDeviceName;
  String? _lastError;

  final StreamController<TelemetryData> _telemetryController =
      StreamController<TelemetryData>.broadcast();
  final StreamController<void> _stateChangeController =
      StreamController<void>.broadcast();

  Stream<TelemetryData> get telemetryStream => _telemetryController.stream;
  Stream<void> get onStateChanged => _stateChangeController.stream;

  bool get isConnected =>
      _connectedDevice != null && _uartCharacteristic != null;
  bool get isScanning => _isScanning;
  String? get lastError => _lastError;
  int get notificationCount => _notificationCount;
  List<BleDiscoveredDevice> get discoveredDevices =>
      List.unmodifiable(_discoveredDevices);

  String get activeDeviceLabel =>
      isConnected ? (_connectedDeviceName ?? 'HM-10 BLE') : 'BLE Disconnected';

  bool get isBleSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);

  /// Requests Android 12+ (API 31+) BLUETOOTH_SCAN, BLUETOOTH_CONNECT, and
  /// legacy ACCESS_FINE_LOCATION permissions gracefully before scanning.
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final statuses = await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.locationWhenInUse,
        ].request();

        final scanOk = statuses[Permission.bluetoothScan]?.isGranted ?? false;
        final connectOk =
            statuses[Permission.bluetoothConnect]?.isGranted ?? false;
        final locationOk =
            statuses[Permission.locationWhenInUse]?.isGranted ?? false;

        if (!scanOk && !connectOk && !locationOk) {
          _lastError = 'Bluetooth permissions denied';
          _notifyStateChanged();
          return false;
        }
        return true;
      } catch (e) {
        debugPrint('BLE permission check failed: $e');
        _lastError = 'Permission error: $e';
        _notifyStateChanged();
        return false;
      }
    }
    return true;
  }

  static bool matchesTargetDevice({
    required String id,
    required String name,
  }) {
    if (id.trim().toUpperCase() == targetDeviceId.toUpperCase()) {
      return true;
    }
    final upperName = name.trim().toUpperCase();
    return upperName == 'BT05' || upperName == 'MLT-BT05';
  }

  static bool matchesHm10({
    required String name,
    required Iterable<String> advertisedServiceUuids,
    String id = '',
  }) {
    if (id.isNotEmpty && matchesTargetDevice(id: id, name: name)) {
      return true;
    }

    final lowerUuidMatch = advertisedServiceUuids.any((uuid) {
      final lower = uuid.toLowerCase();
      return lower == hm10ServiceUuid || lower.contains(hm10ServiceShort);
    });
    if (lowerUuidMatch) return true;

    final lowerName = name.toLowerCase();
    if (lowerName.isEmpty) return false;
    return hm10KnownNames.any((known) => lowerName.contains(known.toLowerCase()));
  }

  Future<void> startScan({
    Duration timeout = const Duration(seconds: 6),
    bool autoConnectTarget = true,
  }) async {
    if (!isBleSupported) {
      _lastError = 'BLE not supported on this platform';
      _notifyStateChanged();
      return;
    }

    final permitted = await requestPermissions();
    if (!permitted) return;

    await stopScan();
    _discoveredDevices.clear();
    _lastError = null;
    _isScanning = true;
    _notifyStateChanged();

    try {
      _scanSubscription = FlutterBluePlus.onScanResults.listen(
        (results) {
          BleDiscoveredDevice? autoConnectCandidate;

          for (final r in results) {
            final advName = r.advertisementData.advName.trim();
            final platformName = r.device.platformName.trim();
            final resolvedName = advName.isNotEmpty
                ? advName
                : (platformName.isNotEmpty ? platformName : '');

            final serviceUuids = r.advertisementData.serviceUuids
                .map((g) => g.str.toLowerCase())
                .toList();

            final remoteIdStr = r.device.remoteId.str;
            final isHm10 = matchesHm10(
              id: remoteIdStr,
              name: resolvedName,
              advertisedServiceUuids: serviceUuids,
            );

            // Include HM-10 matches or named BLE peripherals
            if (!isHm10 && resolvedName.isEmpty) continue;

            final displayName = resolvedName.isNotEmpty
                ? resolvedName
                : (remoteIdStr.toUpperCase() == targetDeviceId
                    ? 'BT05'
                    : 'HM-10 ($remoteIdStr)');

            final entry = BleDiscoveredDevice(
              id: remoteIdStr,
              name: displayName,
              rssi: r.rssi,
              isHm10Candidate: isHm10,
              device: r.device,
            );

            final existingIdx =
                _discoveredDevices.indexWhere((d) => d.id == entry.id);
            if (existingIdx >= 0) {
              _discoveredDevices[existingIdx] = entry;
            } else {
              _discoveredDevices.add(entry);
            }

            if (autoConnectTarget &&
                !isConnected &&
                !_isAutoConnecting &&
                matchesTargetDevice(id: entry.id, name: entry.name)) {
              autoConnectCandidate = entry;
            }
          }

          // Sort target device first, then HM-10 candidates, then by RSSI
          _discoveredDevices.sort((a, b) {
            final aTarget = matchesTargetDevice(id: a.id, name: a.name);
            final bTarget = matchesTargetDevice(id: b.id, name: b.name);
            if (aTarget != bTarget) {
              return aTarget ? -1 : 1;
            }
            if (a.isHm10Candidate != b.isHm10Candidate) {
              return a.isHm10Candidate ? -1 : 1;
            }
            return b.rssi.compareTo(a.rssi);
          });
          _notifyStateChanged();

          if (autoConnectCandidate != null &&
              !isConnected &&
              !_isAutoConnecting) {
            _isAutoConnecting = true;
            unawaited(
              connectToDiscoveredDevice(autoConnectCandidate).whenComplete(() {
                _isAutoConnecting = false;
              }),
            );
          }
        },
        onError: (e) {
          debugPrint('BLE scan stream error: $e');
        },
      );

      await FlutterBluePlus.startScan(timeout: timeout);
    } catch (e) {
      debugPrint('Failed to start BLE scan: $e');
      _lastError = 'Scan failed: $e';
    } finally {
      _isScanning = false;
      _notifyStateChanged();
    }
  }

  Future<void> stopScan() async {
    if (!isBleSupported) return;
    try {
      if (_isScanning) {
        await FlutterBluePlus.stopScan();
      }
    } catch (_) {}
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    _isScanning = false;
    _notifyStateChanged();
  }

  Future<bool> connectToDiscoveredDevice(BleDiscoveredDevice target) async {
    if (target.device == null) return false;
    return connectToDevice(target.device!, displayName: target.name);
  }

  Future<bool> connectToDevice(
    BluetoothDevice device, {
    String? displayName,
  }) async {
    await stopScan();
    await disconnect();

    if (!isBleSupported) {
      return false;
    }

    final permitted = await requestPermissions();
    if (!permitted) return false;

    try {
      await device.connect(
        timeout: const Duration(seconds: 10),
        autoConnect: false,
      );

      _connectedDevice = device;
      _connectedDeviceName = displayName?.isNotEmpty == true
          ? displayName
          : (device.platformName.isNotEmpty
              ? device.platformName
              : 'HM-10 (${device.remoteId.str})');

      _connectionStateSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _cleanupConnectionState();
          _notifyStateChanged();
        }
      });

      final services = await device.discoverServices();
      BluetoothCharacteristic? targetChar;

      for (final service in services) {
        final sUuid = service.uuid.str.toLowerCase();
        if (sUuid == hm10ServiceUuid || sUuid.contains(hm10ServiceShort)) {
          for (final c in service.characteristics) {
            final cUuid = c.uuid.str.toLowerCase();
            if (cUuid == hm10CharacteristicUuid ||
                cUuid.contains(hm10CharacteristicShort)) {
              targetChar = c;
              break;
            }
          }
          // Fallback within FFE0: pick any characteristic supporting notify or indicate
          if (targetChar == null) {
            for (final c in service.characteristics) {
              if (c.properties.notify || c.properties.indicate) {
                targetChar = c;
                break;
              }
            }
          }
        }
        if (targetChar != null) break;
      }

      // Fallback: search any service for characteristic FFE1 if custom service wrapper
      if (targetChar == null) {
        for (final service in services) {
          for (final c in service.characteristics) {
            final cUuid = c.uuid.str.toLowerCase();
            if (cUuid == hm10CharacteristicUuid ||
                cUuid.contains(hm10CharacteristicShort)) {
              targetChar = c;
              break;
            }
          }
          if (targetChar != null) break;
        }
      }

      if (targetChar == null) {
        _lastError = 'HM-10 UART characteristic (FFE1) not found';
        await disconnect();
        return false;
      }

      _uartCharacteristic = targetChar;
      _setupChunkedLineParser(targetChar.lastValueStream);
      try {
        await targetChar.setNotifyValue(true);
      } catch (e) {
        debugPrint('BLE setNotifyValue warning (continuing): $e');
      }

      _lastError = null;
      _notifyStateChanged();
      return true;
    } catch (e) {
      debugPrint('BLE Connection Error: $e');
      _lastError = 'Connection failed: $e';
      await disconnect();
      return false;
    }
  }

  /// Sets up the UTF-8 + LineSplitter pipeline so 36-byte JSON lines split
  /// across multiple 20-byte HM-10 BLE notifications are reassembled cleanly.
  void _setupChunkedLineParser(Stream<List<int>> rawByteStream) {
    _lineSubscription?.cancel();
    _bleRxBuffer = '';
    _lineSubscription = rawByteStream.listen(
      (bytes) {
        if (bytes.isEmpty) return;
        _notificationCount++;
        _bleRxBuffer += utf8.decode(bytes, allowMalformed: true);

        var newlineIndex = _bleRxBuffer.indexOf('\n');
        while (newlineIndex >= 0) {
          final line = _bleRxBuffer.substring(0, newlineIndex);
          _bleRxBuffer = _bleRxBuffer.substring(newlineIndex + 1);
          _handleIncomingLine(line);
          newlineIndex = _bleRxBuffer.indexOf('\n');
        }

        // A corrupt peripheral should not be able to grow this buffer forever.
        if (_bleRxBuffer.length > 512) {
          debugPrint('BLE RX buffer overflow; dropping partial frame');
          _bleRxBuffer = '';
        }
      },
      onError: (err) => debugPrint('BLE RX Error: $err'),
      cancelOnError: false,
    );
  }

  /// Exposed for testing 20-byte BLE packet chunk reassembly without hardware.
  @visibleForTesting
  void attachTestByteStream(Stream<List<int>> chunkStream) {
    _setupChunkedLineParser(chunkStream);
  }

  /// Splits UTF-8 command payload into 20-byte BLE MTU chunks when needed.
  static List<List<int>> chunkPayloadBytes(
    String command, {
    int chunkSize = maxBlePacketBytes,
  }) {
    final payload = command.endsWith('\n') ? command : '$command\n';
    final bytes = utf8.encode(payload);
    final List<List<int>> chunks = [];
    for (int i = 0; i < bytes.length; i += chunkSize) {
      final end =
          (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
      chunks.add(bytes.sublist(i, end));
    }
    return chunks;
  }

  Future<void> sendCommand(String command) async {
    final char = _uartCharacteristic;
    if (!isConnected || char == null) {
      debugPrint('BLE Mock/Offline TX -> ${command.trim()}');
      return;
    }

    try {
      final chunks = chunkPayloadBytes(command);
      final useWithoutResponse = char.properties.writeWithoutResponse;
      for (final chunk in chunks) {
        await char.write(chunk, withoutResponse: useWithoutResponse);
      }
    } catch (e) {
      debugPrint('BLE TX Error: $e');
    }
  }

  void _handleIncomingLine(String rawLine) {
    final startIdx = rawLine.indexOf('{');
    final endIdx = rawLine.lastIndexOf('}');
    if (startIdx < 0 || endIdx <= startIdx) return;

    final line = rawLine.substring(startIdx, endIdx + 1).trim();
    if (line.contains('nan') || line.contains('NaN')) return;

    try {
      final Map<String, dynamic> decoded = jsonDecode(line);
      if (decoded.containsKey('status')) {
        debugPrint('HM-10 BLE Handshake: ${decoded['status']}');
        return;
      }

      final telemetry = TelemetryData.fromJson(decoded);
      _telemetryController.add(telemetry);
    } catch (e) {
      debugPrint('Dropped malformed BLE frame: $line');
    }
  }

  void _cleanupConnectionState() {
    _lineSubscription?.cancel();
    _lineSubscription = null;
    _bleRxBuffer = '';
    _rawByteChunkController?.close();
    _rawByteChunkController = null;
    _uartCharacteristic = null;
    _connectedDevice = null;
    _connectedDeviceName = null;
  }

  Future<void> disconnect() async {
    await _connectionStateSubscription?.cancel();
    _connectionStateSubscription = null;

    final device = _connectedDevice;
    _cleanupConnectionState();

    if (device != null) {
      try {
        await device.disconnect();
      } catch (_) {}
    }
    _notifyStateChanged();
  }

  void _notifyStateChanged() {
    if (!_stateChangeController.isClosed) {
      _stateChangeController.add(null);
    }
  }

  void dispose() {
    stopScan();
    disconnect();
    _telemetryController.close();
    _stateChangeController.close();
  }
}
