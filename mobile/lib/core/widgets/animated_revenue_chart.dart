import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../app/theme/app_theme.dart';
import 'animated_counter.dart';

class AnimatedRevenueChart extends StatefulWidget {
  final double currentMonthRevenue;

  const AnimatedRevenueChart({
    super.key,
    required this.currentMonthRevenue,
  });

  @override
  State<AnimatedRevenueChart> createState() => _AnimatedRevenueChartState();
}

class _AnimatedRevenueChartState extends State<AnimatedRevenueChart> {
  String _selectedPeriod = '30D';
  int? _selectedPointIndex;

  final Map<String, List<double>> _periodData = {
    '7D': [12500, 18200, 15400, 28000, 24300, 31000, 38500],
    '30D': [45000, 62000, 58000, 89000, 94000, 120000, 145000, 184500],
    '3M': [110000, 145000, 195000, 240000, 310000, 385000],
    '6M': [210000, 290000, 380000, 490000, 620000, 780000],
    '1Y': [450000, 680000, 920000, 1250000, 1680000, 2240000],
  };

  final Map<String, List<String>> _periodLabels = {
    '7D': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    '30D': ['W1', 'W2', 'W3', 'W4', 'W5', 'W6', 'W7', 'Now'],
    '3M': ['Month 1', 'Month 2', 'Month 3', 'Month 4', 'Month 5', 'Current'],
    '6M': ['Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep'],
    '1Y': ['Q1 25', 'Q2 25', 'Q3 25', 'Q4 25', 'Q1 26', 'Q2 26'],
  };

  List<double> _previousData = [];
  List<double> _currentData = [];

  @override
  void initState() {
    super.initState();
    _currentData = _periodData['30D']!;
    _previousData = List.filled(_currentData.length, 0.0);
  }

  void _onPeriodChanged(String period) {
    if (_selectedPeriod == period) return;
    setState(() {
      _selectedPeriod = period;
      _selectedPointIndex = null;
      _previousData = _currentData;
      _currentData = _periodData[period]!;
    });
  }

  double get _periodTotal => _currentData.last;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final periods = ['7D', '30D', '3M', '6M', '1Y'];

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
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2563EB),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'REVENUE PERFORMANCE',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  AnimatedCounter(
                    value: _periodTotal,
                    isCurrency: true,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withAlpha(isDark ? 40 : 20),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up, size: 14, color: Color(0xFF10B981)),
                    const SizedBox(width: 4),
                    Text(
                      '+14.8%',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Period Filter Pills
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withAlpha(10) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: periods.map((p) {
                final isSelected = _selectedPeriod == p;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onPeriodChanged(p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? const Color(0xFF2563EB) : Colors.white)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.black.withAlpha(isDark ? 50 : 15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          p,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? (isDark ? Colors.white : const Color(0xFF1E40AF))
                                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Interactive Chart Canvas
          SizedBox(
            height: 170,
            child: TweenAnimationBuilder<double>(
              key: ValueKey(_selectedPeriod),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, animVal, child) {
                return GestureDetector(
                  onTapDown: (details) {
                    final width = context.size?.width ?? 300;
                    final step = width / (_currentData.length - 1);
                    final tappedIndex = (details.localPosition.dx / step).round().clamp(0, _currentData.length - 1);
                    setState(() {
                      _selectedPointIndex = tappedIndex;
                    });
                  },
                  child: CustomPaint(
                    size: const Size(double.infinity, 170),
                    painter: _BezierChartPainter(
                      data: _currentData,
                      animProgress: animVal,
                      isDark: isDark,
                      selectedIndex: _selectedPointIndex,
                      labels: _periodLabels[_selectedPeriod]!,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BezierChartPainter extends CustomPainter {
  final List<double> data;
  final double animProgress;
  final bool isDark;
  final int? selectedIndex;
  final List<String> labels;

  _BezierChartPainter({
    required this.data,
    required this.animProgress,
    required this.isDark,
    required this.selectedIndex,
    required this.labels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final bottomPadding = 24.0;
    final chartHeight = size.height - bottomPadding;
    final maxVal = data.reduce((a, b) => a > b ? a : b) * 1.15;
    final minVal = 0.0;
    final range = maxVal - minVal;

    final points = <Offset>[];
    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final yProgress = (data[i] / range) * animProgress;
      final y = chartHeight - (yProgress * chartHeight);
      points.add(Offset(x, y));
    }

    // Draw grid horizontal subtle guidelines
    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withAlpha(12) : const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 3; i++) {
      final y = chartHeight * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Build smooth cubic bezier path
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    // Gradient Area Fill under path
    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, chartHeight)
      ..lineTo(points.first.dx, chartHeight)
      ..close();

    final areaGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0x502563EB),
        Color(0x002563EB),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight));

    final areaPaint = Paint()
      ..shader = areaGradient
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, areaPaint);

    // Spline Line Stroke
    final linePaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // Data points & X-Axis Labels
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final isSelected = selectedIndex == i;

      if (isSelected || i == points.length - 1) {
        // Glowing halo
        final haloPaint = Paint()
          ..color = const Color(0xFF2563EB).withAlpha(isSelected ? 160 : 70)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawCircle(p, isSelected ? 10 : 7, haloPaint);

        // Outer circle
        final outerPaint = Paint()..color = const Color(0xFF2563EB);
        canvas.drawCircle(p, isSelected ? 6 : 4, outerPaint);

        // Center white dot
        final innerPaint = Paint()..color = Colors.white;
        canvas.drawCircle(p, isSelected ? 3 : 2, innerPaint);
      }

      // X Labels
      if (i < labels.length) {
        final textSpan = TextSpan(
          text: labels[i],
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (isDark ? Colors.white : const Color(0xFF1E40AF))
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();
        final labelX = (p.dx - textPainter.width / 2).clamp(0.0, size.width - textPainter.width);
        textPainter.paint(canvas, Offset(labelX, size.height - textPainter.height));
      }
    }

    // Selected Tooltip
    if (selectedIndex != null && selectedIndex! < points.length) {
      final p = points[selectedIndex!];
      final formatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
      final tipText = formatter.format(data[selectedIndex!]);

      final textSpan = TextSpan(
        text: tipText,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final tipRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(p.dx.clamp(45.0, size.width - 45.0), p.dy - 24),
          width: textPainter.width + 16,
          height: textPainter.height + 10,
        ),
        const Radius.circular(8),
      );

      final tipPaint = Paint()
        ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(tipRect, tipPaint);

      if (isDark) {
        final borderPaint = Paint()
          ..color = const Color(0xFF334155)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawRRect(tipRect, borderPaint);
      }

      textPainter.paint(
        canvas,
        Offset(
          tipRect.center.dx - textPainter.width / 2,
          tipRect.center.dy - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BezierChartPainter oldDelegate) {
    return oldDelegate.animProgress != animProgress ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.data != data ||
        oldDelegate.isDark != isDark;
  }
}
