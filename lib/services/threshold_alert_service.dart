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
    final isLightOk =
        data.lux >= config.minLightLux && data.lux <= config.maxLightLux;
    final isTempOk = data.temperature >= config.minTempCelsius &&
        data.temperature <= config.maxTempCelsius;
    final isHumOk = data.humidity >= config.minHumidity &&
        data.humidity <= config.maxHumidity;

    final String lightMsg;
    if (data.lux < config.minLightLux) {
      lightMsg =
          'Low light warning — ${data.lux.toStringAsFixed(0)} lx (< ${config.minLightLux.toInt()} lx)';
    } else if (data.lux > config.maxLightLux) {
      lightMsg =
          'Excess light warning — ${data.lux.toStringAsFixed(0)} lx (> ${config.maxLightLux.toInt()} lx)';
    } else {
      lightMsg =
          'Lighting optimal — ${data.lux.toStringAsFixed(0)} lx detected';
    }

    return EnvironmentEvaluation(
      isLightOptimal: isLightOk,
      isTempOptimal: isTempOk,
      isHumidityOptimal: isHumOk,
      lightStatusMessage: lightMsg,
    );
  }
}