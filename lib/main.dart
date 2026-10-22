import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/environment_provider.dart';
import 'providers/timer_provider.dart';
import 'screens/home_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/settings_screen.dart';
import 'services/serial_port_service.dart';
import 'services/threshold_alert_service.dart';

void main() {
  runApp(const ZenWizardApp());
}

class ZenWizardApp extends StatefulWidget {
  const ZenWizardApp({super.key});

  @override
  State<ZenWizardApp> createState() => _ZenWizardAppState();
}

class _ZenWizardAppState extends State<ZenWizardApp> {
  late final SerialPortService _serialService;
  late final ThresholdAlertService _alertService;
  late final EnvironmentProvider _environmentProvider;
  late final TimerProvider _timerProvider;

  @override
  void initState() {
    super.initState();
    _serialService = SerialPortService();
    _alertService = ThresholdAlertService();
    _timerProvider = TimerProvider(
      _serialService,
      audioPlayer: AudioPlayer(),
      onSessionCompleted: (sessions, focusMinutes) {
        _environmentProvider.recordProfileSessionStats(sessions, focusMinutes);
      },
    );
    _environmentProvider = EnvironmentProvider(
      _serialService,
      _alertService,
      onActiveProfileChanged: (profile) {
        _timerProvider.applyProfile(profile);
      },
    );
    _timerProvider.applyProfile(_environmentProvider.activeProfile);
  }

  @override
  void dispose() {
    _environmentProvider.dispose();
    _timerProvider.dispose();
    _serialService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _environmentProvider),
        ChangeNotifierProvider.value(value: _timerProvider),
      ],
      child: MaterialApp(
        title: 'ZenWizard',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0B0F17),
          fontFamily: 'Inter',
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF2E8BFF),
            secondary: Color(0xFF10B981),
            tertiary: Color(0xFFF59E0B),
            surface: Color(0xFF151C28),
          ),
        ),
        home: const AppShell(),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  void _switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(onOpenSettings: () => _switchTab(2)),
      const StatsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF070A10),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -1.2),
            radius: 1.1,
            colors: [
              Color(0xFF142038),
              Color(0xFF070A10),
            ],
            stops: [0.0, 0.43],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Container(
              height: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF0B0F17),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black,
                    blurRadius: 80,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: screens[_currentIndex],
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          height: 88,
                          padding: const EdgeInsets.fromLTRB(52, 6, 52, 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D121B)
                                .withValues(alpha: 0.94),
                            border: const Border(
                              top: BorderSide(
                                color: Color(0xFF222C3C),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildNavItem(
                                index: 0,
                                icon: Icons.timer_outlined,
                                label: 'Timer',
                              ),
                              _buildNavItem(
                                index: 1,
                                icon: Icons.bar_chart_rounded,
                                label: 'Stats',
                              ),
                              _buildNavItem(
                                index: 2,
                                icon: Icons.person_outline_rounded,
                                label: 'Profile',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isActive = _currentIndex == index;
    final Color itemColor =
        isActive ? const Color(0xFF63ADFF) : const Color(0xFF69768A);

    return GestureDetector(
      onTap: () => _switchTab(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 39,
              height: 36,
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF2E8BFF).withValues(alpha: 0.16)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isActive
                    ? Border.all(
                        color: const Color(0xFF2E8BFF).withValues(alpha: 0.12),
                        width: 1,
                      )
                    : null,
              ),
              child: Icon(
                icon,
                size: 21,
                color: itemColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: itemColor,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}