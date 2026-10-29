import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_config.dart';
import '../models/telemetry_data.dart';
import '../models/user_profile.dart';
import '../services/ble_service.dart';
import '../services/serial_port_service.dart';
import '../services/threshold_alert_service.dart';

class EnvironmentProvider extends ChangeNotifier {
  static const String _prefsProfilesKey = 'zenwizard_user_profiles_v1';
  static const String _prefsActiveProfileIdKey =
      'zenwizard_active_profile_id_v1';

  final SerialPortService _serialService;
  final ThresholdAlertService _alertService;
  final void Function(UserProfile profile)? onActiveProfileChanged;
  StreamSubscription<TelemetryData>? _subscription;
  StreamSubscription<void>? _bleStateSubscription;

  List<UserProfile> _profiles = _seedDefaultProfiles();
  String _activeProfileId = 'profile_krizha';

  SettingsConfig _config = const SettingsConfig();
  TelemetryData? _latestTelemetry;
  EnvironmentEvaluation? _latestEvaluation;
  final List<TelemetryData> _history = [];
  bool _wasBleConnected = false;

  EnvironmentProvider(
    this._serialService,
    this._alertService, {
    this.onActiveProfileChanged,
  }) {
    _config = activeProfile.settings;
    _subscription =
        _serialService.telemetryStream.listen(_onTelemetryReceived);
    _bleStateSubscription = _serialService.bleService.onStateChanged.listen((_) {
      final nowBleConnected = _serialService.isBleConnected;
      if (nowBleConnected && !_wasBleConnected) {
        _syncHardwareSettings();
      }
      _wasBleConnected = nowBleConnected;
      if (!_serialService.isConnected && !_serialService.isMockRunning) {
        _serialService.startMockStream();
      }
      notifyListeners();
    });
    _initConnection();
    _loadProfilesFromPrefs();
  }

  static List<UserProfile> _seedDefaultProfiles() {
    return const [
      UserProfile(
        id: 'profile_krizha',
        name: 'Krizha Garcia',
        workspaceSubtitle: 'Desk · Station 01 · Floor 2',
        settings: SettingsConfig(
          pomodoroDurationMinutes: 25,
          breakDurationMinutes: 5,
          lightAlertThresholdLux: 300.0,
          minTempCelsius: 18.0,
          maxTempCelsius: 26.0,
        ),
        completedSessions: 25,
        totalFocusMinutes: 625.0,
        weeklySessions: [3, 4, 3, 5, 6, 3, 1],
      ),
      UserProfile(
        id: 'profile_timothy',
        name: 'Timothy Lontac',
        workspaceSubtitle: 'Desk · Station 02 · Floor 2',
        settings: SettingsConfig(
          pomodoroDurationMinutes: 30,
          breakDurationMinutes: 5,
          lightAlertThresholdLux: 350.0,
          minTempCelsius: 18.0,
          maxTempCelsius: 26.0,
        ),
        completedSessions: 18,
        totalFocusMinutes: 540.0,
        weeklySessions: [2, 3, 4, 3, 4, 2, 0],
      ),
      UserProfile(
        id: 'profile_marcus',
        name: 'Marcus Marcaida',
        workspaceSubtitle: 'Desk · Station 03 · Floor 2',
        settings: SettingsConfig(
          pomodoroDurationMinutes: 20,
          breakDurationMinutes: 5,
          lightAlertThresholdLux: 250.0,
          minTempCelsius: 18.0,
          maxTempCelsius: 26.0,
        ),
        completedSessions: 14,
        totalFocusMinutes: 280.0,
        weeklySessions: [1, 2, 2, 3, 4, 1, 1],
      ),
    ];
  }

  Future<void> _loadProfilesFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawProfiles = prefs.getString(_prefsProfilesKey);
      final savedActiveId = prefs.getString(_prefsActiveProfileIdKey);

      if (rawProfiles != null && rawProfiles.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(rawProfiles);
        final loaded = decoded
            .whereType<Map<String, dynamic>>()
            .map(UserProfile.fromJson)
            .toList();
        if (loaded.isNotEmpty) {
          _profiles = loaded;
        }
      } else {
        _profiles = _seedDefaultProfiles();
        await _saveProfilesToPrefs();
      }

      if (savedActiveId != null &&
          _profiles.any((p) => p.id == savedActiveId)) {
        _activeProfileId = savedActiveId;
      } else {
        _activeProfileId = _profiles.first.id;
      }

      _applyActiveProfile(syncSerial: true);
    } catch (e) {
      debugPrint('Failed to load profiles from SharedPreferences: $e');
    }
  }

  Future<void> _saveProfilesToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_profiles.map((p) => p.toJson()).toList());
      await prefs.setString(_prefsProfilesKey, encoded);
      await prefs.setString(_prefsActiveProfileIdKey, _activeProfileId);
    } catch (e) {
      debugPrint('Failed to save profiles to SharedPreferences: $e');
    }
  }

  void _applyActiveProfile({required bool syncSerial}) {
    final profile = activeProfile;
    _config = profile.settings;
    if (syncSerial) {
      _serialService.sendCommand(
        'CMD:LUX_MIN:${_config.minLightLux.toStringAsFixed(0)}',
      );
      _serialService.sendCommand(
        _config.isBuzzerMuted ? 'CMD:BUZZER:MUTE' : 'CMD:BUZZER:UNMUTE',
      );
    }
    if (_latestTelemetry != null) {
      _latestEvaluation = _alertService.evaluate(_latestTelemetry!, _config);
    }
    onActiveProfileChanged?.call(profile);
    notifyListeners();
  }

  Future<void> _initConnection() async {
    if (_serialService.isDesktopSerialSupported) {
      final ports = _serialService.getAvailablePorts();
      if (ports.isNotEmpty) {
        final connected = await _serialService.connect(ports.first);
        if (connected) {
          _syncHardwareSettings();
          notifyListeners();
          return;
        }
      }
    }

    // Fallback to simulated telemetry until hardware or BLE auto-connect streams live packets
    _serialService.startMockStream();
    notifyListeners();

    // Auto-scan and connect to BT05 (7C:01:0A:39:14:00) on mobile startup
    if (isMobilePlatform && isBleSupported) {
      unawaited(_serialService.bleService.startScan(autoConnectTarget: true));
    }
  }

  void _syncHardwareSettings() {
    _serialService.sendCommand(
      'CMD:LUX_MIN:${_config.minLightLux.toStringAsFixed(0)}',
    );
    _serialService.sendCommand(
      _config.isBuzzerMuted ? 'CMD:BUZZER:MUTE' : 'CMD:BUZZER:UNMUTE',
    );
  }

  List<UserProfile> get profiles => List.unmodifiable(_profiles);

  UserProfile get activeProfile {
    return _profiles.firstWhere(
      (p) => p.id == _activeProfileId,
      orElse: () => _profiles.first,
    );
  }

  SettingsConfig get config => _config;
  TelemetryData? get latestTelemetry => _latestTelemetry;
  EnvironmentEvaluation? get latestEvaluation => _latestEvaluation;
  List<TelemetryData> get history => List.unmodifiable(_history);
  bool get isConnected => _serialService.isConnected;
  bool get isUsbConnected => _serialService.isUsbConnected;
  bool get isBleConnected => _serialService.isBleConnected;
  bool get isBleScanning => _serialService.bleService.isScanning;
  String? get bleLastError => _serialService.bleService.lastError;
  List<BleDiscoveredDevice> get discoveredBleDevices =>
      _serialService.bleService.discoveredDevices;
  bool get isMobilePlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  bool get isBleSupported => _serialService.bleService.isBleSupported;
  String get activePortLabel => _serialService.activePortLabel;
  List<String> get availablePorts => _serialService.getAvailablePorts();

  Future<void> switchProfile(String profileId) async {
    if (!_profiles.any((p) => p.id == profileId)) return;
    _activeProfileId = profileId;
    _applyActiveProfile(syncSerial: true);
    await _saveProfilesToPrefs();
  }

  Future<void> createProfile({
    required String name,
    required String workspaceSubtitle,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;
    final cleanSub = workspaceSubtitle.trim().isEmpty
        ? 'Desk · Station 01 · Floor 1'
        : workspaceSubtitle.trim();

    final newProfile = UserProfile(
      id: 'profile_${DateTime.now().millisecondsSinceEpoch}',
      name: cleanName,
      workspaceSubtitle: cleanSub,
      settings: const SettingsConfig(),
      completedSessions: 0,
      totalFocusMinutes: 0.0,
    );

    _profiles = [..._profiles, newProfile];
    _activeProfileId = newProfile.id;
    _applyActiveProfile(syncSerial: true);
    await _saveProfilesToPrefs();
  }

  Future<void> deleteProfile(String profileId) async {
    if (profileId == _activeProfileId || _profiles.length <= 1) return;
    _profiles = _profiles.where((p) => p.id != profileId).toList();
    notifyListeners();
    await _saveProfilesToPrefs();
  }

  Future<void> recordProfileSessionStats(
    int completedSessions,
    double totalFocusMinutes,
  ) async {
    final index = _profiles.indexWhere((p) => p.id == _activeProfileId);
    if (index == -1) return;

    // DateTime.weekday: 1 (Mon) to 7 (Sun) -> index 0 to 6
    final currentDayIndex = (DateTime.now().weekday - 1).clamp(0, 6);
    final currentWeekly = List<int>.from(_profiles[index].weeklySessions);
    while (currentWeekly.length < 7) {
      currentWeekly.add(0);
    }
    currentWeekly[currentDayIndex] = currentWeekly[currentDayIndex] + 1;

    final updated = _profiles[index].copyWith(
      completedSessions: completedSessions,
      totalFocusMinutes: totalFocusMinutes,
      weeklySessions: currentWeekly,
    );
    final nextList = List<UserProfile>.from(_profiles);
    nextList[index] = updated;
    _profiles = nextList;
    notifyListeners();
    await _saveProfilesToPrefs();
  }

  Future<bool> connectToPort(String portName) async {
    final ok = await _serialService.connect(portName);
    if (ok) {
      _syncHardwareSettings();
    }
    notifyListeners();
    return ok;
  }

  Future<void> disconnectPort() async {
    await _serialService.disconnect();
    _serialService.startMockStream();
    notifyListeners();
  }

  void refreshPorts() {
    notifyListeners();
  }

  Future<void> startBleScan() async {
    await _serialService.bleService.startScan();
    notifyListeners();
  }

  Future<void> stopBleScan() async {
    await _serialService.bleService.stopScan();
    notifyListeners();
  }

  Future<bool> connectToBleDevice(BleDiscoveredDevice device) async {
    final ok = await _serialService.bleService.connectToDiscoveredDevice(device);
    if (ok) {
      _syncHardwareSettings();
    }
    notifyListeners();
    return ok;
  }

  Future<void> disconnectBle() async {
    await _serialService.bleService.disconnect();
    if (!_serialService.isConnected) {
      _serialService.startMockStream();
    }
    notifyListeners();
  }

  void _onTelemetryReceived(TelemetryData data) {
    _latestTelemetry = data;
    _latestEvaluation = _alertService.evaluate(data, _config);
    _history.add(data);
    if (_history.length > 120) {
      _history.removeAt(0); // Keep rolling window for charts
    }
    notifyListeners();
  }

  Future<void> updateConfig(SettingsConfig newConfig) async {
    _config = newConfig;
    final index = _profiles.indexWhere((p) => p.id == _activeProfileId);
    if (index != -1) {
      final nextList = List<UserProfile>.from(_profiles);
      nextList[index] = _profiles[index].copyWith(settings: newConfig);
      _profiles = nextList;
    }
    // Sync settings to Arduino Uno hardware (Lux + Buzzer Mute)
    _syncHardwareSettings();
    if (_latestTelemetry != null) {
      _latestEvaluation = _alertService.evaluate(_latestTelemetry!, _config);
    }
    notifyListeners();
    await _saveProfilesToPrefs();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _bleStateSubscription?.cancel();
    super.dispose();
  }
}