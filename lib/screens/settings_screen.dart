import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const List<List<String>> _preferences = [
    ['Pomodoro Duration', '25 min'],
    ['Break Duration', '5 min'],
    ['Light Alert Threshold', '< 300 lux'],
    ['Temp Alert Range', '20°C – 26°C'],
  ];

  @override
  Widget build(BuildContext context) {
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

          // User Profile Card
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
            child: Row(
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
                        color: const Color(0xFF2E8BFF).withValues(alpha: 0.2),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: const Text(
                    'AK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alex Kim',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Smart Workspace Setup 1',
                      style: TextStyle(
                        color: Color(0xFF8A99AD),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Preferences Card
          Container(
            padding: const EdgeInsets.fromLTRB(17, 19, 17, 3),
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
                ...List.generate(_preferences.length, (i) {
                  final item = _preferences[i];
                  return Container(
                    constraints: const BoxConstraints(minHeight: 51),
                    decoration: BoxDecoration(
                      border: i == 0
                          ? null
                          : const Border(
                              top: BorderSide(
                                color: Color(0xFF202A39),
                                width: 1,
                              ),
                            ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item[0],
                          style: const TextStyle(
                            color: Color(0xFFA4AFBF),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          item[1],
                          style: const TextStyle(
                            color: Color(0xFF4BA2FF),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
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
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF10B981),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sensor array connected',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Arduino Uno R3 • USB Serial (COM3)',
                          style: TextStyle(
                            color: Color(0xFF718096),
                            fontSize: 10,
                          ),
                        ),
                      ],
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