class SettingsConfig {
  final int pomodoroDurationMinutes;
  final int breakDurationMinutes;
  final int longBreakDurationMinutes;
  final double lightAlertThresholdLux;
  final double minTempCelsius;
  final double maxTempCelsius;

  const SettingsConfig({
    this.pomodoroDurationMinutes = 25,
    this.breakDurationMinutes = 5,
    this.longBreakDurationMinutes = 15,
    this.lightAlertThresholdLux = 300.0,
    this.minTempCelsius = 18.0,
    this.maxTempCelsius = 26.0,
  });

  SettingsConfig copyWith({
    int? pomodoroDurationMinutes,
    int? breakDurationMinutes,
    int? longBreakDurationMinutes,
    double? lightAlertThresholdLux,
    double? minTempCelsius,
    double? maxTempCelsius,
  }) {
    return SettingsConfig(
      pomodoroDurationMinutes:
          pomodoroDurationMinutes ?? this.pomodoroDurationMinutes,
      breakDurationMinutes: breakDurationMinutes ?? this.breakDurationMinutes,
      longBreakDurationMinutes:
          longBreakDurationMinutes ?? this.longBreakDurationMinutes,
      lightAlertThresholdLux:
          lightAlertThresholdLux ?? this.lightAlertThresholdLux,
      minTempCelsius: minTempCelsius ?? this.minTempCelsius,
      maxTempCelsius: maxTempCelsius ?? this.maxTempCelsius,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pomodoroDurationMinutes': pomodoroDurationMinutes,
      'breakDurationMinutes': breakDurationMinutes,
      'longBreakDurationMinutes': longBreakDurationMinutes,
      'lightAlertThresholdLux': lightAlertThresholdLux,
      'minTempCelsius': minTempCelsius,
      'maxTempCelsius': maxTempCelsius,
    };
  }

  factory SettingsConfig.fromJson(Map<String, dynamic> json) {
    return SettingsConfig(
      pomodoroDurationMinutes:
          (json['pomodoroDurationMinutes'] as num?)?.toInt() ?? 25,
      breakDurationMinutes:
          (json['breakDurationMinutes'] as num?)?.toInt() ?? 5,
      longBreakDurationMinutes:
          (json['longBreakDurationMinutes'] as num?)?.toInt() ?? 15,
      lightAlertThresholdLux:
          (json['lightAlertThresholdLux'] as num?)?.toDouble() ?? 300.0,
      minTempCelsius: (json['minTempCelsius'] as num?)?.toDouble() ?? 18.0,
      maxTempCelsius: (json['maxTempCelsius'] as num?)?.toDouble() ?? 26.0,
    );
  }
}