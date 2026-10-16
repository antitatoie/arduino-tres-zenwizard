import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/environment_provider.dart';
import '../providers/timer_provider.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback? onOpenSettings;

  const HomeScreen({super.key, this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    final envProvider = context.watch<EnvironmentProvider>();
    final timerProvider = context.watch<TimerProvider>();

    final telemetry = envProvider.latestTelemetry;
    final evaluation = envProvider.latestEvaluation;

    final double lux = telemetry?.lux ?? 419.0;
    final double temp = telemetry?.temperature ?? 23.8;
    final double hum = telemetry?.humidity ?? 52.0;

    final bool isLightOk = evaluation?.isLightOptimal ?? true;
    final bool isTempOk = evaluation?.isTempOptimal ?? true;
    final bool isHumOk = evaluation?.isHumidityOptimal ?? true;

    final String bannerText = evaluation?.lightStatusMessage ??
        'Lighting optimal — ${lux.toStringAsFixed(0)} lx detected';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 116),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Header (Wrapped in Expanded to prevent horizontal overflow)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ARDUINO ENVIRONMENT',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
              ),
              const SizedBox(width: 8),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF151C28),
                  border: Border.all(color: const Color(0xFF222C3C)),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: Color(0xFF8A99AD),
                    size: 20,
                  ),
                  onPressed: onOpenSettings,
                  tooltip: 'Settings',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 3-Column Sensor Metric Grid
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Light',
                  value: '${lux.toStringAsFixed(0)} lx',
                  status: isLightOk ? 'Optimal' : 'Low Light',
                  icon: Icons.wb_sunny_outlined,
                  primaryColor: isLightOk
                      ? const Color(0xFF2E8BFF)
                      : const Color(0xFFEF4444),
                  statusColor: isLightOk
                      ? const Color(0xFF4AA8FF)
                      : const Color(0xFFF87171),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricCard(
                  label: 'Temp',
                  value: '${temp.toStringAsFixed(1)} °C',
                  status: isTempOk ? 'Good' : 'Alert',
                  icon: Icons.thermostat_outlined,
                  primaryColor: const Color(0xFF10B981),
                  statusColor: const Color(0xFF34D399),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricCard(
                  label: 'Humidity',
                  value: '${hum.toStringAsFixed(0)} %',
                  status: isHumOk ? 'Normal' : 'Alert',
                  icon: Icons.water_drop_outlined,
                  primaryColor: const Color(0xFFF59E0B),
                  statusColor: const Color(0xFFFBBF24),
                ),
              ),
            ],
          ),

          // Pomodoro Timer Section
          const SizedBox(height: 34),
          const Center(
            child: Text(
              'POMODORO TIMER',
              style: TextStyle(
                color: Color(0xFF718096),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Circular Conic Timer Ring
          Center(
            child: SizedBox(
              width: 228,
              height: 228,
              child: CustomPaint(
                painter: _TimerRingPainter(progress: timerProvider.progress),
                child: Center(
                  child: Container(
                    width: 212,
                    height: 212,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Color(0xFF141D2A),
                          Color(0xFF0B0F17),
                        ],
                        stops: [0.0, 0.7],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          timerProvider.formattedTime,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            color: Colors.white,
                            fontSize: 46,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -2.0,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'FOCUS',
                          style: TextStyle(
                            color: Color(0xFF718096),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 23),

          // Start & Reset Pill Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: timerProvider.toggle,
                child: Container(
                  width: 112,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E8BFF),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2E8BFF).withValues(alpha: 0.28),
                        blurRadius: 22,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Text(
                    timerProvider.isRunning ? 'Pause' : 'Start',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: timerProvider.reset,
                child: Container(
                  width: 112,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF151C28),
                    border: Border.all(color: const Color(0xFF2A3547)),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      color: Color(0xFFB5C0D0),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Bottom Lighting Status Banner
          const SizedBox(height: 30),
          Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: isLightOk
                  ? const Color(0xFF0D2821)
                  : const Color(0xFF2C1215),
              border: Border.all(
                color: isLightOk
                    ? const Color(0xFF185A47)
                    : const Color(0xFF7F1D1D),
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isLightOk
                        ? const Color(0xFF66D8AD)
                        : const Color(0xFFF87171),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: isLightOk
                            ? const Color(0xFF66D8AD)
                            : const Color(0xFFF87171),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    bannerText,
                    style: TextStyle(
                      color: isLightOk
                          ? const Color(0xFF66D8AD)
                          : const Color(0xFFF87171),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String status;
  final IconData icon;
  final Color primaryColor;
  final Color statusColor;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.status,
    required this.icon,
    required this.primaryColor,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 13, 11, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF18202D),
            Color(0xFF121923),
          ],
        ),
        border: Border.all(color: const Color(0xFF222C3C)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF8A99AD),
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                icon,
                size: 17,
                color: primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 13),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: primaryColor,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
              ),
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor,
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimerRingPainter extends CustomPainter {
  final double progress;

  _TimerRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8) / 2;

    final glowPaint = Paint()
      ..color = const Color(0xFF2E8BFF).withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(center, radius, glowPaint);

    final trackPaint = Paint()
      ..color = const Color(0xFF1D2B3F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius, trackPaint);

    final sweepAngle = 2 * math.pi * progress;
    final progressPaint = Paint()
      ..color = const Color(0xFF2E8BFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );

    final dotAngle = -math.pi / 2 + sweepAngle;
    final dotCenter = Offset(
      center.dx + radius * math.cos(dotAngle),
      center.dy + radius * math.sin(dotAngle),
    );

    final dotGlowPaint = Paint()
      ..color = const Color(0xFF2E8BFF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    canvas.drawCircle(dotCenter, 6, dotGlowPaint);

    final dotPaint = Paint()..color = const Color(0xFF72B6FF);
    canvas.drawCircle(dotCenter, 6, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}