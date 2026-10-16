import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int _defaultSeconds = 25 * 60;
  int _remainingSeconds = _defaultSeconds;
  bool _isRunning = false;
  Timer? _timer;

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          setState(() => _remainingSeconds--);
        } else {
          _timer?.cancel();
          setState(() => _isRunning = false);
        }
      });
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _defaultSeconds;
    });
  }

  String get _formattedTime {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  double get _progress {
    // Matches the 78% default visual ring when at 25:00, or live progress when running
    if (_remainingSeconds == _defaultSeconds && !_isRunning) {
      return 0.78;
    }
    return _remainingSeconds / _defaultSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 116),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
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
                  onPressed: () {},
                  tooltip: 'Settings',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 3-Column Sensor Metric Grid
          const Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Light',
                  value: '419 lx',
                  status: 'Optimal',
                  icon: Icons.wb_sunny_outlined,
                  primaryColor: Color(0xFF2E8BFF),
                  statusColor: Color(0xFF4AA8FF),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _MetricCard(
                  label: 'Temp',
                  value: '23.8 °C',
                  status: 'Good',
                  icon: Icons.thermostat_outlined,
                  primaryColor: Color(0xFF10B981),
                  statusColor: Color(0xFF34D399),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _MetricCard(
                  label: 'Humidity',
                  value: '52 %',
                  status: 'Normal',
                  icon: Icons.water_drop_outlined,
                  primaryColor: Color(0xFFF59E0B),
                  statusColor: Color(0xFFFBBF24),
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
                painter: _TimerRingPainter(progress: _progress),
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
                          _formattedTime,
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
                onTap: _toggleTimer,
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
                    _isRunning ? 'Pause' : 'Start',
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
                onTap: _resetTimer,
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
              color: const Color(0xFF0D2821),
              border: Border.all(color: const Color(0xFF185A47)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Color(0xFF66D8AD),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF66D8AD),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 9),
                const Text(
                  'Lighting optimal — 419 lx detected',
                  style: TextStyle(
                    color: Color(0xFF66D8AD),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
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
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF8A99AD),
                  fontSize: 11,
                ),
              ),
              Icon(
                icon,
                size: 17,
                color: primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            value,
            style: TextStyle(
              color: primaryColor,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
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
              Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 9,
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

    // Outer ambient glow
    final glowPaint = Paint()
      ..color = const Color(0xFF2E8BFF).withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(center, radius, glowPaint);

    // Background track ring (#1D2B3F)
    final trackPaint = Paint()
      ..color = const Color(0xFF1D2B3F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius, trackPaint);

    // Active progress arc (#2E8BFF)
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

    // Glowing indicator dot at the end of the progress arc
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