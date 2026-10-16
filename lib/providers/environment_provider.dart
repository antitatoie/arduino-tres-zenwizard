import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/settings_config.dart';
import '../models/telemetry_data.dart';
import '../services/serial_port_service.dart';
import '../services/threshold_alert_service.dart';

class EnvironmentProvider extends ChangeNotifier {
  final SerialPortService _serialService;
  final ThresholdAlertService _alertService;
  StreamSubscription<TelemetryData>? _subscription;

  SettingsConfig _config = const SettingsConfig();
  TelemetryData? _latestTelemetry;
  EnvironmentEvaluation? _latestEvaluation;
  final List<TelemetryData> _history = [];

  EnvironmentProvider(this._serialService, this._alertService) {
    _subscription =
        _serialService.telemetryStream.listen(_onTelemetryReceived);
    _initConnection();
  }

  Future<void> _initConnection() async {
    final ports = _serialService.getAvailablePorts();
    if (ports.isNotEmpty) {
      final connected = await _serialService.connect(ports.first);
      if (connected) {
        notifyListeners();
        return;
      }
    }
    // Fallback to simulated telemetry when in Chrome or unplugged
    _serialService.startMockStream();
    notifyListeners();
  }

  SettingsConfig get config => _config;
  TelemetryData? get latestTelemetry => _latestTelemetry;
  EnvironmentEvaluation? get latestEvaluation => _latestEvaluation;
  List<TelemetryData> get history => List.unmodifiable(_history);
  bool get isConnected => _serialService.isConnected;
  String get activePortLabel => _serialService.activePortLabel;
  List<String> get availablePorts => _serialService.getAvailablePorts();

  Future<bool> connectToPort(String portName) async {
    final ok = await _serialService.connect(portName);
    notifyListeners();
    return ok;
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

  void updateConfig(SettingsConfig newConfig) {
    _config = newConfig;
    // Sync new Lux threshold to Arduino Uno hardware LED
    _serialService.sendCommand(
      'CMD:LUX_MIN:${newConfig.lightAlertThresholdLux.toStringAsFixed(0)}',
    );
    if (_latestTelemetry != null) {
      _latestEvaluation = _alertService.evaluate(_latestTelemetry!, _config);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}