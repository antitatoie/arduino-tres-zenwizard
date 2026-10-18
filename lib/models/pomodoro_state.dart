enum PomodoroPhase {
  focus,
  shortBreak,
}

class PomodoroState {
  final int remainingSeconds;
  final int totalSeconds;
  final bool isRunning;
  final int completedSessions;
  final PomodoroPhase phase;

  const PomodoroState({
    this.remainingSeconds = 25 * 60,
    this.totalSeconds = 25 * 60,
    this.isRunning = false,
    this.completedSessions = 25,
    this.phase = PomodoroPhase.focus,
  });

  double get progress {
    if (totalSeconds <= 0) return 0.0;
    return (remainingSeconds / totalSeconds).clamp(0.0, 1.0);
  }

  String get formattedTime {
    final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}