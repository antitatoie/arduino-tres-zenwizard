class SettingsConfig {
  final int pomodoroDurationMinutes;
  final int breakDurationMinutes;
  final int longBreakDurationMinutes;
  final double minLightLux;
  final double maxLightLux;
  final double minTempCelsius;
  final double maxTempCelsius;
  final double minHumidity;
  final double maxHumidity;
  final bool isBuzzerMuted;
  final bool isVibrationEnabled;

  const SettingsConfig({
    this.pomodoroDurationMinutes = 25,
    this.breakDurationMinutes = 5,
    this.longBreakDurationMinutes = 15,
    double? minLightLux,
    double? lightAlertThresholdLux,
    this.maxLightLux = 1000.0,
    this.minTempCelsius = 18.0,
    this.maxTempCelsius = 26.0,
    this.minHumidity = 30.0,
    this.maxHumidity = 65.0,
    this.isBuzzerMuted = false,
    this.isVibrationEnabled = true,
  }) : minLightLux = minLightLux ?? lightAlertThresholdLux ?? 300.0;

  // Backward compatibility alias for lightAlertThresholdLux
  double get lightAlertThresholdLux => minLightLux;

  SettingsConfig copyWith({
    int? pomodoroDurationMinutes,
    int? breakDurationMinutes,
    int? longBreakDurationMinutes,
    double? minLightLux,
    double? maxLightLux,
    double? lightAlertThresholdLux,
    double? minTempCelsius,
    double? maxTempCelsius,
    double? minHumidity,
    double? maxHumidity,
    bool? isBuzzerMuted,
    bool? isVibrationEnabled,
  }) {
    return SettingsConfig(
      pomodoroDurationMinutes:
          pomodoroDurationMinutes ?? this.pomodoroDurationMinutes,
      breakDurationMinutes: breakDurationMinutes ?? this.breakDurationMinutes,
      longBreakDurationMinutes:
          longBreakDurationMinutes ?? this.longBreakDurationMinutes,
      minLightLux: minLightLux ?? lightAlertThresholdLux ?? this.minLightLux,
      maxLightLux: maxLightLux ?? this.maxLightLux,
      minTempCelsius: minTempCelsius ?? this.minTempCelsius,
      maxTempCelsius: maxTempCelsius ?? this.maxTempCelsius,
      minHumidity: minHumidity ?? this.minHumidity,
      maxHumidity: maxHumidity ?? this.maxHumidity,
      isBuzzerMuted: isBuzzerMuted ?? this.isBuzzerMuted,
      isVibrationEnabled: isVibrationEnabled ?? this.isVibrationEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pomodoroDurationMinutes': pomodoroDurationMinutes,
      'breakDurationMinutes': breakDurationMinutes,
      'longBreakDurationMinutes': longBreakDurationMinutes,
      'minLightLux': minLightLux,
      'maxLightLux': maxLightLux,
      'lightAlertThresholdLux': minLightLux,
      'minTempCelsius': minTempCelsius,
      'maxTempCelsius': maxTempCelsius,
      'minHumidity': minHumidity,
      'maxHumidity': maxHumidity,
      'isBuzzerMuted': isBuzzerMuted,
      'isVibrationEnabled': isVibrationEnabled,
    };
  }

  factory SettingsConfig.fromJson(Map<String, dynamic> json) {
    final parsedMinLight = (json['minLightLux'] as num?)?.toDouble() ??
        (json['lightAlertThresholdLux'] as num?)?.toDouble() ??
        300.0;
    final parsedMaxLight =
        (json['maxLightLux'] as num?)?.toDouble() ?? 1000.0;
    final parsedMinHum = (json['minHumidity'] as num?)?.toDouble() ?? 30.0;
    final parsedMaxHum = (json['maxHumidity'] as num?)?.toDouble() ?? 65.0;

    return SettingsConfig(
      pomodoroDurationMinutes:
          (json['pomodoroDurationMinutes'] as num?)?.toInt() ?? 25,
      breakDurationMinutes:
          (json['breakDurationMinutes'] as num?)?.toInt() ?? 5,
      longBreakDurationMinutes:
          (json['longBreakDurationMinutes'] as num?)?.toInt() ?? 15,
      minLightLux: parsedMinLight,
      maxLightLux: parsedMaxLight,
      minTempCelsius: (json['minTempCelsius'] as num?)?.toDouble() ?? 18.0,
      maxTempCelsius: (json['maxTempCelsius'] as num?)?.toDouble() ?? 26.0,
      minHumidity: parsedMinHum,
      maxHumidity: parsedMaxHum,
      isBuzzerMuted: json['isBuzzerMuted'] == true,
      isVibrationEnabled: json['isVibrationEnabled'] != false,
    );
  }
}