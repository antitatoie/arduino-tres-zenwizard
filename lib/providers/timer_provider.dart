import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/serial_port_service.dart';

class TimerProvider extends ChangeNotifier {
  final SerialPortService _serialService;
  Timer? _timer;

  int _workDurationSeconds = 25 * 60;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  int _completedSessions = 25;

  TimerProvider(this._serialService);

  int get remainingSeconds => _remainingSeconds;
  int get workDurationSeconds => _workDurationSeconds;
  bool get isRunning => _isRunning;
  int get completedSessions => _completedSessions;

  double get progress {
    if (_workDurationSeconds <= 0) return 0.0;
    if (_remainingSeconds == _workDurationSeconds && !_isRunning) {
      return 0.78;
    }
    return (_remainingSeconds / _workDurationSeconds).clamp(0.0, 1.0);
  }

  String get formattedTime {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void toggle() {
    if (_isRunning) {
      pause();
    } else {
      start();
    }
  }

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _onTimerComplete();
      }
    });
  }

  void pause() {
    _timer?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  void _onTimerComplete() {
    _timer?.cancel();
    _isRunning = false;
    _completedSessions++;
    // Trigger non-blocking RGB LED flash + Active Buzzer on Arduino Uno
    _serialService.sendCommand('CMD:POMODORO_ALERT');
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _isRunning = false;
    _remainingSeconds = _workDurationSeconds;
    _serialService.sendCommand('CMD:POMODORO_STOP');
    notifyListeners();
  }

  void setWorkDurationMinutes(int minutes) {
    _workDurationSeconds = minutes * 60;
    if (!_isRunning) {
      _remainingSeconds = _workDurationSeconds;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}