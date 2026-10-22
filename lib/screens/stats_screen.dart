import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/telemetry_data.dart';
import '../providers/environment_provider.dart';
import '../providers/timer_provider.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

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
    final envProvider = context.watch<EnvironmentProvider>();
    final timerProvider = context.watch<TimerProvider>();
    final history = envProvider.history;
    final activeProfile = envProvider.activeProfile;

    final weeklySessions = activeProfile.weeklySessions;
    final int maxWeeklySession = weeklySessions.isEmpty
        ? 1
        : weeklySessions.reduce((a, b) => a > b ? a : b);
    final double maxBarScale =
        maxWeeklySession > 0 ? maxWeeklySession.toDouble() : 1.0;

    int bestDayIndex = 0;
    int bestDayCount = 0;
    for (int i = 0; i < weeklySessions.length && i < _days.length; i++) {
      if (weeklySessions[i] > bestDayCount) {
        bestDayCount = weeklySessions[i];
        bestDayIndex = i;
      }
    }
    final String bestDayLabel = _days[bestDayIndex];
    final String bestDaySub =
        bestDayCount == 1 ? '1 session' : '$bestDayCount sessions';

    final int currentWeekdayIndex = (DateTime.now().weekday - 1).clamp(0, 6);

    final double avgTemp = history.isEmpty
        ? 22.1
        : history.map((e) => e.temperature).reduce((a, b) => a + b) /
            history.length;

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

          // Live Lux Line Chart Card (fl_chart)
          _TelemetryLineChartCard(
            title: 'LIVE LIGHT TELEMETRY (LUX)',
            unit: 'lx',
            lineColor: const Color(0xFF2E8BFF),
            history: history,
            valueExtractor: (d) => d.lux,
            defaultValue: 419.0,
          ),
          const SizedBox(height: 12),

          // Live Temperature Line Chart Card (fl_chart)
          _TelemetryLineChartCard(
            title: 'LIVE TEMPERATURE TELEMETRY (°C)',
            unit: '°C',
            lineColor: const Color(0xFF10B981),
            history: history,
            valueExtractor: (d) => d.temperature,
            defaultValue: 23.8,
          ),
          const SizedBox(height: 12),

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
                            final int count =
                                i < weeklySessions.length ? weeklySessions[i] : 0;
                            final bool isToday = i == currentWeekdayIndex;
                            final bool isBestDay = i == bestDayIndex && count > 0;
                            final bool isHighlighted = isToday || isBestDay;
                            final double calculatedHeight =
                                maxBarHeight * (count / maxBarScale);
                            final double barHeight = count == 0
                                ? 4.0
                                : calculatedHeight.clamp(4.0, maxBarHeight);

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
                                          colors: isHighlighted
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
                                        boxShadow: isHighlighted
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
                                          color: isHighlighted
                                              ? const Color(0xFF57AAFF)
                                              : const Color(0xFF647188),
                                          fontSize: 9,
                                          fontWeight: isHighlighted
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
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'TOTAL SESSIONS',
                  value: '${timerProvider.completedSessions}',
                  sub: 'Completed',
                  valueColor: const Color(0xFF2E8BFF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryCard(
                  label: 'FOCUS TIME',
                  value: timerProvider.totalFocusHours.toStringAsFixed(1),
                  sub: 'Hours',
                  valueColor: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'AVG TEMP',
                  value: avgTemp.toStringAsFixed(1),
                  sub: '°C',
                  valueColor: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryCard(
                  label: 'BEST DAY',
                  value: bestDayLabel,
                  sub: bestDaySub,
                  valueColor: const Color(0xFF2E8BFF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TelemetryLineChartCard extends StatelessWidget {
  final String title;
  final String unit;
  final Color lineColor;
  final List<TelemetryData> history;
  final double Function(TelemetryData) valueExtractor;
  final double defaultValue;

  const _TelemetryLineChartCard({
    required this.title,
    required this.unit,
    required this.lineColor,
    required this.history,
    required this.valueExtractor,
    required this.defaultValue,
  });

  @override
  Widget build(BuildContext context) {
    final List<FlSpot> spots = history.isEmpty
        ? [FlSpot(0, defaultValue), FlSpot(1, defaultValue)]
        : List.generate(
            history.length,
            (i) => FlSpot(i.toDouble(), valueExtractor(history[i])),
          );

    final double latestVal =
        history.isEmpty ? defaultValue : valueExtractor(history.last);

    return Container(
      height: 185,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF718096),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              Text(
                '${latestVal.toStringAsFixed(1)} $unit',
                style: TextStyle(
                  color: lineColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: Color(0xFF222C3C),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: lineColor,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: lineColor.withValues(alpha: 0.14),
                    ),
                  ),
                ],
              ),
            ),
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