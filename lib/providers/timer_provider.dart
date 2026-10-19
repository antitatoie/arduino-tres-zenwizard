import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/pomodoro_state.dart';
import '../models/user_profile.dart';
import '../services/serial_port_service.dart';

class TimerProvider extends ChangeNotifier {
  final SerialPortService _serialService;
  final void Function(int completedSessions, double totalFocusMinutes)?
      onSessionCompleted;
  Timer? _timer;

  int _workDurationSeconds = 25 * 60;
  int _breakDurationSeconds = 5 * 60;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  int _completedSessions = 25;
  double _totalFocusMinutes = 625.0;
  PomodoroPhase _phase = PomodoroPhase.focus;

  TimerProvider(this._serialService, {this.onSessionCompleted});

  int get remainingSeconds => _remainingSeconds;
  int get workDurationSeconds => _workDurationSeconds;
  int get breakDurationSeconds => _breakDurationSeconds;
  bool get isRunning => _isRunning;
  int get completedSessions => _completedSessions;
  double get totalFocusMinutes => _totalFocusMinutes;
  double get totalFocusHours => _totalFocusMinutes / 60.0;
  PomodoroPhase get phase => _phase;

  int get currentPhaseTotalSeconds =>
      _phase == PomodoroPhase.focus ? _workDurationSeconds : _breakDurationSeconds;

  PomodoroState get state => PomodoroState(
        remainingSeconds: _remainingSeconds,
        totalSeconds: currentPhaseTotalSeconds,
        isRunning: _isRunning,
        completedSessions: _completedSessions,
        phase: _phase,
      );

  double get progress => state.progress;

  String get formattedTime => state.formattedTime;

  void applyProfile(UserProfile profile) {
    _timer?.cancel();
    _isRunning = false;
    _phase = PomodoroPhase.focus;
    _workDurationSeconds = profile.settings.pomodoroDurationMinutes * 60;
    _breakDurationSeconds = profile.settings.breakDurationMinutes * 60;
    _remainingSeconds = _workDurationSeconds;
    _completedSessions = profile.completedSessions;
    _totalFocusMinutes = profile.totalFocusMinutes;
    notifyListeners();
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
    if (_remainingSeconds <= 0) {
      _advancePhaseAndResetRemaining();
    }
    _isRunning = true;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
        if (_remainingSeconds == 0) {
          _onTimerComplete();
        }
      } else {
        _onTimerComplete();
      }
    });
  }

  void pause() {
    _timer?.cancel();
    _isRunning = false;
    _serialService.sendCommand('CMD:POMODORO_STOP');
    notifyListeners();
  }

  void _advancePhaseAndResetRemaining() {
    if (_phase == PomodoroPhase.focus) {
      _phase = PomodoroPhase.shortBreak;
      _remainingSeconds = _breakDurationSeconds;
    } else {
      _phase = PomodoroPhase.focus;
      _remainingSeconds = _workDurationSeconds;
    }
  }

  void _onTimerComplete() {
    _timer?.cancel();
    _isRunning = false;
    _remainingSeconds = 0;
    if (_phase == PomodoroPhase.focus) {
      _completedSessions++;
      _totalFocusMinutes += (_workDurationSeconds / 60.0);
      onSessionCompleted?.call(_completedSessions, _totalFocusMinutes);
    }
    // Trigger non-blocking RGB LED flash + Active Buzzer on Arduino Uno
    _serialService.sendCommand('CMD:POMODORO_ALERT');
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _isRunning = false;
    _phase = PomodoroPhase.focus;
    _remainingSeconds = _workDurationSeconds;
    _serialService.sendCommand('CMD:POMODORO_STOP');
    notifyListeners();
  }

  void setWorkDurationMinutes(int minutes) {
    _workDurationSeconds = minutes * 60;
    if (!_isRunning && _phase == PomodoroPhase.focus) {
      _remainingSeconds = _workDurationSeconds;
    }
    notifyListeners();
  }

  void setBreakDurationMinutes(int minutes) {
    _breakDurationSeconds = minutes * 60;
    if (!_isRunning && _phase == PomodoroPhase.shortBreak) {
      _remainingSeconds = _breakDurationSeconds;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}