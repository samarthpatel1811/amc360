import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_theme.dart';
import 'animated_counter.dart';

class ContractHealthRing extends StatelessWidget {
  final int activeCount;
  final int expiringCount;
  final int expiredCount;
  final double percentage; // e.g. 0.84 for 84%

  const ContractHealthRing({
    super.key,
    required this.activeCount,
    required this.expiringCount,
    required this.expiredCount,
    this.percentage = 0.84,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(20) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: AppShadows.card(isDark: isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withAlpha(isDark ? 50 : 25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.health_and_safety_outlined,
                      size: 18,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'CONTRACT HEALTH',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withAlpha(isDark ? 40 : 20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF10B981).withAlpha(isDark ? 80 : 40),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Optimal',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              // Custom Circular Progress Ring
              SizedBox(
                width: 112,
                height: 112,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: percentage.clamp(0.0, 1.0)),
                  duration: const Duration(milliseconds: 1400),
                  curve: Curves.easeOutCubic,
                  builder: (context, val, child) {
                    return CustomPaint(
                      painter: _RingPainter(
                        progress: val,
                        isDark: isDark,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(val * 100).toInt()}%',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'ACTIVE RATIO',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              // Breakdown stats
              Expanded(
                child: Column(
                  children: [
                    _buildStatRow(
                      context,
                      label: 'Active Contracts',
                      count: activeCount,
                      dotColor: const Color(0xFF10B981),
                      isDark: isDark,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildStatRow(
                      context,
                      label: 'Expiring Soon',
                      count: expiringCount,
                      dotColor: const Color(0xFFF59E0B),
                      isDark: isDark,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildStatRow(
                      context,
                      label: 'Expired / Lapsed',
                      count: expiredCount,
                      dotColor: const Color(0xFFEF4444),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context, {
    required String label,
    required int count,
    required Color dotColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(8) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(12) : const Color(0xFFF1F5F9),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: dotColor.withAlpha(120),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                ),
              ),
            ],
          ),
          AnimatedCounter(
            value: count,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  _RingPainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;
    const strokeWidth = 9.0;

    // Background track
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = isDark ? Colors.white.withAlpha(20) : const Color(0xFFE2E8F0);
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0.001) return;

    // Gradient progress arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: 3 * math.pi / 2,
      colors: const [
        Color(0xFF2563EB),
        Color(0xFF0D9488),
        Color(0xFF10B981),
      ],
      stops: const [0.0, 0.5, 1.0],
      transform: const GradientRotation(-math.pi / 2),
    );

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..shader = gradient.createShader(rect);

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);

    // Glowing tip dot
    final tipAngle = startAngle + sweepAngle;
    final tipX = center.dx + radius * math.cos(tipAngle);
    final tipY = center.dy + radius * math.sin(tipAngle);

    final glowPaint = Paint()
      ..color = const Color(0xFF10B981).withAlpha(180)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(Offset(tipX, tipY), strokeWidth / 1.5, glowPaint);

    final dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(tipX, tipY), strokeWidth / 3, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}
