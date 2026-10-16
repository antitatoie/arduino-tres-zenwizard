class TelemetryData {
  final double lux;
  final double temperature;
  final double humidity;
  final DateTime timestamp;

  const TelemetryData({
    required this.lux,
    required this.temperature,
    required this.humidity,
    required this.timestamp,
  });

  factory TelemetryData.fromJson(Map<String, dynamic> json) {
    double? parseSafeDouble(dynamic val) {
      if (val == null) return null;
      if (val is num) {
        final d = val.toDouble();
        return (d.isNaN || d.isInfinite) ? null : d;
      }
      if (val is String) {
        final parsed = double.tryParse(val);
        return (parsed == null || parsed.isNaN || parsed.isInfinite)
            ? null
            : parsed;
      }
      return null;
    }

    final luxVal = parseSafeDouble(json['lux'] ?? json['light']);
    final tempVal = parseSafeDouble(json['temp'] ?? json['temperature']);
    final humVal = parseSafeDouble(json['hum'] ?? json['humidity']);

    if (luxVal == null || tempVal == null || humVal == null) {
      throw const FormatException('Invalid or NaN telemetry fields');
    }

    return TelemetryData(
      lux: luxVal,
      temperature: tempVal,
      humidity: humVal,
      timestamp: DateTime.now(),
    );
  }
}