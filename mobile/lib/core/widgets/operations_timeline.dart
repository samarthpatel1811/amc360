import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_theme.dart';

class TimelineOperationItem {
  final String time;
  final String customerName;
  final String serviceType;
  final String technicianName;
  final String status;
  final Color statusColor;

  const TimelineOperationItem({
    required this.time,
    required this.customerName,
    required this.serviceType,
    required this.technicianName,
    required this.status,
    required this.statusColor,
  });
}

class OperationsTimeline extends StatelessWidget {
  final List<TimelineOperationItem> items;
  final Function(TimelineOperationItem)? onItemTap;

  const OperationsTimeline({
    super.key,
    required this.items,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(
            color: isDark ? Colors.white.withAlpha(20) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Center(
          child: Text(
            'No scheduled operations for today.',
            style: GoogleFonts.inter(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 195,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final item = items[index];
          // Staggered animated entry
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 400 + (index * 120)),
            curve: Curves.easeOutCubic,
            builder: (context, val, child) {
              return Transform.translate(
                offset: Offset(20 * (1 - val), 0),
                child: Opacity(
                  opacity: val.clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: _buildTimelineCard(context, item, isDark),
          );
        },
      ),
    );
  }

  Widget _buildTimelineCard(BuildContext context, TimelineOperationItem item, bool isDark) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(AppSpacing.md),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Time header & status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withAlpha(isDark ? 40 : 15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.time,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: item.statusColor.withAlpha(isDark ? 35 : 20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: item.statusColor.withAlpha(isDark ? 70 : 40),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: item.statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.status,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: item.statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Customer & Service
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.customerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Icon(
                    Icons.build_circle_outlined,
                    size: 13,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.serviceType,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Technician Footer Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withAlpha(8) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? Colors.white.withAlpha(12) : const Color(0xFFF1F5F9),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 9,
                  backgroundColor: const Color(0xFF2563EB),
                  child: Text(
                    item.technicianName.isNotEmpty ? item.technicianName[0] : 'T',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.technicianName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                    ),
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
