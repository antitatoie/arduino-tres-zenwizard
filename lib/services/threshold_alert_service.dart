import '../models/settings_config.dart';
import '../models/telemetry_data.dart';

class EnvironmentEvaluation {
  final bool isLightOptimal;
  final bool isTempOptimal;
  final bool isHumidityOptimal;
  final String lightStatusMessage;

  const EnvironmentEvaluation({
    required this.isLightOptimal,
    required this.isTempOptimal,
    required this.isHumidityOptimal,
    required this.lightStatusMessage,
  });
}

class ThresholdAlertService {
  EnvironmentEvaluation evaluate(TelemetryData data, SettingsConfig config) {
    final isLightOk = data.lux >= config.lightAlertThresholdLux;
    final isTempOk = data.temperature >= config.minTempCelsius &&
        data.temperature <= config.maxTempCelsius;
    final isHumOk = data.humidity >= 30.0 && data.humidity <= 65.0;

    final lightMsg = isLightOk
        ? 'Lighting optimal — ${data.lux.toStringAsFixed(0)} lx detected'
        : 'Low lighting warning — ${data.lux.toStringAsFixed(0)} lx (< ${config.lightAlertThresholdLux.toInt()} lx)';

    return EnvironmentEvaluation(
      isLightOptimal: isLightOk,
      isTempOptimal: isTempOk,
      isHumidityOptimal: isHumOk,
      lightStatusMessage: lightMsg,
    );
  }
}