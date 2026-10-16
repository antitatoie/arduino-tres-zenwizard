class SettingsConfig {
  final int pomodoroDurationMinutes;
  final int breakDurationMinutes;
  final double lightAlertThresholdLux;
  final double minTempCelsius;
  final double maxTempCelsius;

  const SettingsConfig({
    this.pomodoroDurationMinutes = 25,
    this.breakDurationMinutes = 5,
    this.lightAlertThresholdLux = 300.0,
    this.minTempCelsius = 18.0,
    this.maxTempCelsius = 26.0,
  });

  SettingsConfig copyWith({
    int? pomodoroDurationMinutes,
    int? breakDurationMinutes,
    double? lightAlertThresholdLux,
    double? minTempCelsius,
    double? maxTempCelsius,
  }) {
    return SettingsConfig(
      pomodoroDurationMinutes:
          pomodoroDurationMinutes ?? this.pomodoroDurationMinutes,
      breakDurationMinutes: breakDurationMinutes ?? this.breakDurationMinutes,
      lightAlertThresholdLux:
          lightAlertThresholdLux ?? this.lightAlertThresholdLux,
      minTempCelsius: minTempCelsius ?? this.minTempCelsius,
      maxTempCelsius: maxTempCelsius ?? this.maxTempCelsius,
    );
  }
}