import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/environment_provider.dart';
import '../providers/timer_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showCreateProfileDialog(
    BuildContext context,
    EnvironmentProvider envProvider,
  ) {
    final nameController = TextEditingController();
    final deskController = TextEditingController(
      text: 'Desk · Station 04 · Floor 2',
    );

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF151C28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
            side: const BorderSide(color: Color(0xFF222C3C)),
          ),
          title: const Text(
            'New Workspace Profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'NAME',
                style: TextStyle(
                  color: Color(0xFF718096),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: nameController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. Alex Kim',
                  hintStyle: const TextStyle(color: Color(0xFF647188)),
                  filled: true,
                  fillColor: const Color(0xFF0E141E),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF222C3C)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF2E8BFF)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'WORKSPACE / DESK',
                style: TextStyle(
                  color: Color(0xFF718096),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: deskController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. Desk · Station 04 · Floor 2',
                  hintStyle: const TextStyle(color: Color(0xFF647188)),
                  filled: true,
                  fillColor: const Color(0xFF0E141E),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF222C3C)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF2E8BFF)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF8A99AD), fontSize: 12),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E8BFF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                envProvider.createProfile(
                  name: name,
                  workspaceSubtitle: deskController.text.trim(),
                );
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                'Create & Switch',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showProfileSwitcherSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF121923),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Color(0xFF222C3C)),
      ),
      builder: (sheetContext) {
        return Consumer<EnvironmentProvider>(
          builder: (ctx, envProvider, _) {
            final profiles = envProvider.profiles;
            final activeId = envProvider.activeProfile.id;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'SWITCH WORKSPACE PROFILE',
                          style: TextStyle(
                            color: Color(0xFF718096),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF4BA2FF),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            _showCreateProfileDialog(context, envProvider);
                          },
                          icon: const Icon(Icons.add_rounded, size: 15),
                          label: const Text(
                            'New Profile',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: profiles.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, index) {
                          final profile = profiles[index];
                          final isActive = profile.id == activeId;

                          return GestureDetector(
                            onTap: () {
                              envProvider.switchProfile(profile.id);
                              Navigator.of(sheetContext).pop();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFF1A2639)
                                    : const Color(0xFF151C28),
                                border: Border.all(
                                  color: isActive
                                      ? const Color(0xFF2E8BFF)
                                      : const Color(0xFF222C3C),
                                ),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFF4BA2FF),
                                          Color(0xFF176AD5),
                                        ],
                                      ),
                                    ),
                                    child: Text(
                                      profile.initials,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          profile.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${profile.workspaceSubtitle} • < ${profile.settings.lightAlertThresholdLux.toInt()} lx',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF8A99AD),
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isActive)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2E8BFF)
                                            .withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Active',
                                        style: TextStyle(
                                          color: Color(0xFF63ADFF),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    )
                                  else
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Color(0xFF8A99AD),
                                        size: 18,
                                      ),
                                      tooltip: 'Delete Profile',
                                      onPressed: () {
                                        envProvider.deleteProfile(profile.id);
                                      },
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final envProvider = context.watch<EnvironmentProvider>();
    final timerProvider = context.watch<TimerProvider>();
    final config = envProvider.config;
    final activeProfile = envProvider.activeProfile;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 116),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // App Header
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ARDUINO ENVIRONMENT',
                style: TextStyle(
                  color: Color(0xFF718096),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 7),
              Text(
                'Workspace Status',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.9,
                  height: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Page Title
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ACCOUNT',
                style: TextStyle(
                  color: Color(0xFF718096),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 7),
              Text(
                'Profile & Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.35,
                  height: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // User Profile Card (with Switch & + New Profile actions)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF171F2B),
                  Color(0xFF121923),
                ],
              ),
              border: Border.all(color: const Color(0xFF222C3C)),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF4BA2FF),
                            Color(0xFF176AD5),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF2E8BFF).withValues(alpha: 0.2),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Text(
                        activeProfile.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activeProfile.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            activeProfile.workspaceSubtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF8A99AD),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 34,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFF1E293B),
                            foregroundColor: const Color(0xFF63ADFF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(color: Color(0xFF2A3547)),
                            ),
                          ),
                          onPressed: () => _showProfileSwitcherSheet(context),
                          icon: const Icon(Icons.swap_horiz_rounded, size: 15),
                          label: Text(
                            'Switch Profile (${envProvider.profiles.length})',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 34,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFF2E8BFF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () =>
                            _showCreateProfileDialog(context, envProvider),
                        icon: const Icon(Icons.add_rounded, size: 15),
                        label: const Text(
                          'New',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Preferences Card with Interactive Controls
          Container(
            padding: const EdgeInsets.fromLTRB(17, 19, 17, 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF171F2B),
                  Color(0xFF121923),
                ],
              ),
              border: Border.all(color: const Color(0xFF222C3C)),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PREFERENCES',
                  style: TextStyle(
                    color: Color(0xFF718096),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                _StepperRow(
                  label: 'Pomodoro Duration',
                  valueText: '${config.pomodoroDurationMinutes} min',
                  showTopBorder: false,
                  onDecrement: config.pomodoroDurationMinutes > 5
                      ? () {
                          final next = config.pomodoroDurationMinutes - 5;
                          envProvider.updateConfig(
                            config.copyWith(pomodoroDurationMinutes: next),
                          );
                          timerProvider.setWorkDurationMinutes(next);
                        }
                      : null,
                  onIncrement: config.pomodoroDurationMinutes < 90
                      ? () {
                          final next = config.pomodoroDurationMinutes + 5;
                          envProvider.updateConfig(
                            config.copyWith(pomodoroDurationMinutes: next),
                          );
                          timerProvider.setWorkDurationMinutes(next);
                        }
                      : null,
                ),
                _StepperRow(
                  label: 'Break Duration',
                  valueText: '${config.breakDurationMinutes} min',
                  showTopBorder: true,
                  onDecrement: config.breakDurationMinutes > 1
                      ? () {
                          final next = config.breakDurationMinutes - 1;
                          envProvider.updateConfig(
                            config.copyWith(breakDurationMinutes: next),
                          );
                          timerProvider.setBreakDurationMinutes(next);
                        }
                      : null,
                  onIncrement: config.breakDurationMinutes < 30
                      ? () {
                          final next = config.breakDurationMinutes + 1;
                          envProvider.updateConfig(
                            config.copyWith(breakDurationMinutes: next),
                          );
                          timerProvider.setBreakDurationMinutes(next);
                        }
                      : null,
                ),
                _StepperRow(
                  label: 'Light Alert Threshold',
                  valueText: '< ${config.lightAlertThresholdLux.toInt()} lux',
                  showTopBorder: true,
                  onDecrement: config.lightAlertThresholdLux > 50
                      ? () {
                          final next = config.lightAlertThresholdLux - 25.0;
                          envProvider.updateConfig(
                            config.copyWith(lightAlertThresholdLux: next),
                          );
                        }
                      : null,
                  onIncrement: config.lightAlertThresholdLux < 1000
                      ? () {
                          final next = config.lightAlertThresholdLux + 25.0;
                          envProvider.updateConfig(
                            config.copyWith(lightAlertThresholdLux: next),
                          );
                        }
                      : null,
                ),
                _StepperRow(
                  label: 'Min Temp Alert',
                  valueText: '${config.minTempCelsius.toInt()}°C',
                  showTopBorder: true,
                  onDecrement: config.minTempCelsius > 10.0
                      ? () {
                          final next = config.minTempCelsius - 1.0;
                          envProvider.updateConfig(
                            config.copyWith(minTempCelsius: next),
                          );
                        }
                      : null,
                  onIncrement: config.minTempCelsius < config.maxTempCelsius - 1.0
                      ? () {
                          final next = config.minTempCelsius + 1.0;
                          envProvider.updateConfig(
                            config.copyWith(minTempCelsius: next),
                          );
                        }
                      : null,
                ),
                _StepperRow(
                  label: 'Max Temp Alert',
                  valueText: '${config.maxTempCelsius.toInt()}°C',
                  showTopBorder: true,
                  onDecrement: config.maxTempCelsius > config.minTempCelsius + 1.0
                      ? () {
                          final next = config.maxTempCelsius - 1.0;
                          envProvider.updateConfig(
                            config.copyWith(maxTempCelsius: next),
                          );
                        }
                      : null,
                  onIncrement: config.maxTempCelsius < 40.0
                      ? () {
                          final next = config.maxTempCelsius + 1.0;
                          envProvider.updateConfig(
                            config.copyWith(maxTempCelsius: next),
                          );
                        }
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Device Status Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 19),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF171F2B),
                  Color(0xFF121923),
                ],
              ),
              border: Border.all(color: const Color(0xFF222C3C)),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DEVICE STATUS',
                  style: TextStyle(
                    color: Color(0xFF718096),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 17),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: envProvider.isConnected
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: envProvider.isConnected
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            envProvider.isConnected
                                ? 'Sensor array connected'
                                : 'Simulated sensor stream active',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Arduino Uno R3 • ${envProvider.activePortLabel}',
                            style: const TextStyle(
                              color: Color(0xFF718096),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  final String label;
  final String valueText;
  final bool showTopBorder;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  const _StepperRow({
    required this.label,
    required this.valueText,
    required this.showTopBorder,
    this.onDecrement,
    this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 51),
      decoration: BoxDecoration(
        border: showTopBorder
            ? const Border(
                top: BorderSide(
                  color: Color(0xFF202A39),
                  width: 1,
                ),
              )
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFA4AFBF),
                fontSize: 12,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StepButton(
                icon: Icons.remove_rounded,
                onTap: onDecrement,
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 64,
                child: Text(
                  valueText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF4BA2FF),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StepButton(
                icon: Icons.add_rounded,
                onTap: onIncrement,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: const Color(0xFF151C28),
          border: Border.all(
            color: enabled ? const Color(0xFF2A3547) : const Color(0xFF1B2330),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 14,
          color: enabled ? const Color(0xFF8A99AD) : const Color(0xFF434E61),
        ),
      ),
    );
  }
}