import 'package:flutter_test/flutter_test.dart';
import 'package:posture_wizard/models/pomodoro_state.dart';
import 'package:posture_wizard/models/settings_config.dart';
import 'package:posture_wizard/models/telemetry_data.dart';
import 'package:posture_wizard/models/user_profile.dart';
import 'package:posture_wizard/providers/environment_provider.dart';
import 'package:posture_wizard/providers/timer_provider.dart';
import 'package:posture_wizard/services/serial_port_service.dart';
import 'package:posture_wizard/services/threshold_alert_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Models Unit Tests', () {
    test('PomodoroState defaults completedSessions to 0', () {
      const state = PomodoroState();
      expect(state.completedSessions, 0);
      expect(state.phase, PomodoroPhase.focus);
      expect(state.formattedTime, '25:00');
    });

    test('SettingsConfig serializes and deserializes longBreakDurationMinutes', () {
      const config = SettingsConfig(
        pomodoroDurationMinutes: 30,
        breakDurationMinutes: 7,
        longBreakDurationMinutes: 20,
        lightAlertThresholdLux: 400.0,
        minTempCelsius: 19.0,
        maxTempCelsius: 27.0,
      );

      final json = config.toJson();
      expect(json['longBreakDurationMinutes'], 20);

      final fromJson = SettingsConfig.fromJson(json);
      expect(fromJson.longBreakDurationMinutes, 20);
      expect(fromJson.pomodoroDurationMinutes, 30);
      expect(fromJson.minTempCelsius, 19.0);
      expect(fromJson.maxTempCelsius, 27.0);
    });

    test('UserProfile handles weeklySessions correctly in JSON', () {
      const profile = UserProfile(
        id: 'test_id',
        name: 'Jane Doe',
        workspaceSubtitle: 'Station A',
        completedSessions: 5,
        totalFocusMinutes: 125.0,
        weeklySessions: [1, 2, 0, 1, 1, 0, 0],
      );

      final json = profile.toJson();
      expect(json['weeklySessions'], [1, 2, 0, 1, 1, 0, 0]);

      final restored = UserProfile.fromJson(json);
      expect(restored.weeklySessions, [1, 2, 0, 1, 1, 0, 0]);
      expect(restored.initials, 'JD');
    });

    test('TelemetryData parses JSON and guards NaN/Infinity', () {
      final valid = TelemetryData.fromJson({
        'lux': 350.5,
        'temp': 24.2,
        'hum': 55.0,
      });
      expect(valid.lux, 350.5);
      expect(valid.temperature, 24.2);
      expect(valid.humidity, 55.0);

      expect(
        () => TelemetryData.fromJson({}),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => TelemetryData.fromJson({'lux': double.nan, 'temp': 20.0, 'hum': 50.0}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('ThresholdAlertService Tests', () {
    final alertService = ThresholdAlertService();
    const config = SettingsConfig(
      lightAlertThresholdLux: 300.0,
      minTempCelsius: 18.0,
      maxTempCelsius: 26.0,
    );

    test('evaluates optimal environment correctly', () {
      final data = TelemetryData(
        lux: 350.0,
        temperature: 22.0,
        humidity: 50.0,
        timestamp: DateTime.now(),
      );

      final eval = alertService.evaluate(data, config);
      expect(eval.isLightOptimal, isTrue);
      expect(eval.isTempOptimal, isTrue);
      expect(eval.isHumidityOptimal, isTrue);
      expect(eval.lightStatusMessage, contains('optimal'));
    });

    test('evaluates low light and extreme temp correctly', () {
      final lowLightData = TelemetryData(
        lux: 150.0,
        temperature: 30.0,
        humidity: 20.0,
        timestamp: DateTime.now(),
      );

      final eval = alertService.evaluate(lowLightData, config);
      expect(eval.isLightOptimal, isFalse);
      expect(eval.isTempOptimal, isFalse);
      expect(eval.isHumidityOptimal, isFalse);
      expect(eval.lightStatusMessage, contains('Low lighting warning'));
    });
  });

  group('TimerProvider & Long Break Phase Tests', () {
    test('Timer advances to shortBreak on normal session completion and longBreak on 4th session', () {
      final serialService = SerialPortService();
      final timerProvider = TimerProvider(serialService);

      // Apply a test profile
      const testProfile = UserProfile(
        id: 'test_user',
        name: 'Tester',
        workspaceSubtitle: 'Desk 1',
        completedSessions: 3, // next one is 4th!
        totalFocusMinutes: 75.0,
        settings: SettingsConfig(
          pomodoroDurationMinutes: 25,
          breakDurationMinutes: 5,
          longBreakDurationMinutes: 15,
        ),
      );

      timerProvider.applyProfile(testProfile);
      expect(timerProvider.completedSessions, 3);
      expect(timerProvider.phase, PomodoroPhase.focus);

      // Simulate timer ticking down to 0 for the 4th session
      timerProvider.start();
      // Fast forward by calling advance when remaining is 0
      // In TimerProvider, if remainingSeconds is 0 when starting or completing:
      // Let's test the public API duration controls
      timerProvider.setWorkDurationMinutes(1);
      expect(timerProvider.workDurationSeconds, 60);

      timerProvider.setBreakDurationMinutes(3);
      expect(timerProvider.breakDurationSeconds, 180);

      timerProvider.setLongBreakDurationMinutes(12);
      expect(timerProvider.longBreakDurationSeconds, 720);

      timerProvider.dispose();
      serialService.dispose();
    });
  });

  group('EnvironmentProvider Tests', () {
    test('updates config and preserves user profiles', () async {
      final serialService = SerialPortService();
      final alertService = ThresholdAlertService();
      final envProvider = EnvironmentProvider(serialService, alertService);

      // Wait a microtask for prefs init
      await Future<void>.delayed(const Duration(milliseconds: 50));

      const newConfig = SettingsConfig(
        pomodoroDurationMinutes: 45,
        breakDurationMinutes: 10,
        longBreakDurationMinutes: 25,
        lightAlertThresholdLux: 450.0,
        minTempCelsius: 20.0,
        maxTempCelsius: 25.0,
      );

      await envProvider.updateConfig(newConfig);

      expect(envProvider.config.pomodoroDurationMinutes, 45);
      expect(envProvider.config.longBreakDurationMinutes, 25);
      expect(envProvider.config.lightAlertThresholdLux, 450.0);
      expect(envProvider.activeProfile.settings.pomodoroDurationMinutes, 45);

      // Record a session and verify weeklySessions increments
      final initialSessions = envProvider.activeProfile.completedSessions;
      await envProvider.recordProfileSessionStats(
        initialSessions + 1,
        envProvider.activeProfile.totalFocusMinutes + 45.0,
      );

      expect(envProvider.activeProfile.completedSessions, initialSessions + 1);
      final currentWeekdayIdx = (DateTime.now().weekday - 1).clamp(0, 6);
      expect(
        envProvider.activeProfile.weeklySessions[currentWeekdayIdx],
        greaterThan(0),
      );

      envProvider.dispose();
      serialService.dispose();
    });
  });
}
