import 'package:flutter/material.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  static const List<int> _bars = [52, 68, 43, 77, 100, 60, 36];
  static const List<String> _days = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
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
                'ANALYTICS',
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
                'Your Focus Stats',
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

          // Weekly Focus Bar Chart Card
          Container(
            height: 260,
            padding: const EdgeInsets.fromLTRB(18, 19, 18, 17),
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
                  'WEEKLY FOCUS',
                  style: TextStyle(
                    color: Color(0xFF718096),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 19),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Color(0xFF263143),
                          width: 1,
                        ),
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Reserve 22px for label + gap at the bottom of each column
                        final double maxBarHeight =
                            (constraints.maxHeight - 22).clamp(0.0, 200.0);

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(_days.length, (i) {
                            final bool isActive = i == 4; // Friday highlighted
                            final double barHeight =
                                maxBarHeight * (_bars[i] / 100.0);

                            return Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      width: 26,
                                      height: barHeight,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: isActive
                                              ? const [
                                                  Color(0xFF5DB0FF),
                                                  Color(0xFF1877ED),
                                                ]
                                              : const [
                                                  Color(0xFF293D5D),
                                                  Color(0xFF1C2A40),
                                                ],
                                        ),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(6),
                                          topRight: Radius.circular(6),
                                          bottomLeft: Radius.circular(2),
                                          bottomRight: Radius.circular(2),
                                        ),
                                        boxShadow: isActive
                                            ? [
                                                BoxShadow(
                                                  color: const Color(0xFF2E8BFF)
                                                      .withValues(alpha: 0.4),
                                                  blurRadius: 18,
                                                ),
                                              ]
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      height: 12,
                                      child: Text(
                                        _days[i],
                                        style: TextStyle(
                                          color: isActive
                                              ? const Color(0xFF57AAFF)
                                              : const Color(0xFF647188),
                                          fontSize: 9,
                                          fontWeight: isActive
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2x2 Summary Grid
          const Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'TOTAL SESSIONS',
                  value: '25',
                  sub: 'Completed',
                  valueColor: Color(0xFF2E8BFF),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _SummaryCard(
                  label: 'FOCUS TIME',
                  value: '10.4',
                  sub: 'Hours',
                  valueColor: Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'AVG TEMP',
                  value: '22.1',
                  sub: '°C',
                  valueColor: Color(0xFFF59E0B),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _SummaryCard(
                  label: 'BEST DAY',
                  value: 'Fri',
                  sub: '5 sessions',
                  valueColor: Color(0xFF2E8BFF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color valueColor;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(16),
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
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF718096),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 27,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.1,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: const TextStyle(
              color: Color(0xFF718096),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}