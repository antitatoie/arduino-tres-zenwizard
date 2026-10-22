import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../models/pomodoro_state.dart';
import '../models/user_profile.dart';
import '../services/serial_port_service.dart';

class TimerProvider extends ChangeNotifier {
  final SerialPortService _serialService;
  final void Function(int completedSessions, double totalFocusMinutes)?
      onSessionCompleted;
  final AudioPlayer? _audioPlayer;
  Timer? _timer;

  int _workDurationSeconds = 25 * 60;
  int _breakDurationSeconds = 5 * 60;
  int _longBreakDurationSeconds = 15 * 60;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  int _completedSessions = 0;
  double _totalFocusMinutes = 0.0;
  PomodoroPhase _phase = PomodoroPhase.focus;

  TimerProvider(
    this._serialService, {
    this.onSessionCompleted,
    AudioPlayer? audioPlayer,
  }) : _audioPlayer = audioPlayer;

  int get remainingSeconds => _remainingSeconds;
  int get workDurationSeconds => _workDurationSeconds;
  int get breakDurationSeconds => _breakDurationSeconds;
  int get longBreakDurationSeconds => _longBreakDurationSeconds;
  bool get isRunning => _isRunning;
  int get completedSessions => _completedSessions;
  double get totalFocusMinutes => _totalFocusMinutes;
  double get totalFocusHours => _totalFocusMinutes / 60.0;
  PomodoroPhase get phase => _phase;

  int get cycleSessionNumber => ((_completedSessions % 4) == 0 && _completedSessions > 0)
      ? 4
      : (_completedSessions % 4);

  int get currentPhaseTotalSeconds {
    switch (_phase) {
      case PomodoroPhase.focus:
        return _workDurationSeconds;
      case PomodoroPhase.shortBreak:
        return _breakDurationSeconds;
      case PomodoroPhase.longBreak:
        return _longBreakDurationSeconds;
    }
  }

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
    _longBreakDurationSeconds = profile.settings.longBreakDurationMinutes * 60;
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
      // Long break every 4 completed sessions
      if (_completedSessions > 0 && _completedSessions % 4 == 0) {
        _phase = PomodoroPhase.longBreak;
        _remainingSeconds = _longBreakDurationSeconds;
      } else {
        _phase = PomodoroPhase.shortBreak;
        _remainingSeconds = _breakDurationSeconds;
      }
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
    // Play pleasant in-app chime notification
    _playChime();

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

  void setLongBreakDurationMinutes(int minutes) {
    _longBreakDurationSeconds = minutes * 60;
    if (!_isRunning && _phase == PomodoroPhase.longBreak) {
      _remainingSeconds = _longBreakDurationSeconds;
    }
    notifyListeners();
  }

  Future<void> _playChime() async {
    if (_audioPlayer == null) return;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('audio/chime.wav'), volume: 0.8);
    } catch (e) {
      debugPrint('Failed to play in-app chime: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer?.dispose();
    super.dispose();
  }
}