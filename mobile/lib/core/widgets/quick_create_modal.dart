import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';

class QuickCreateModal extends StatelessWidget {
  const QuickCreateModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const QuickCreateModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xxl),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0F172A).withAlpha(240)
                : Colors.white.withAlpha(245),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark ? Colors.white.withAlpha(20) : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pill handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withAlpha(50) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Command Center',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Quick Create Operation',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Action list
              _buildActionTile(
                context,
                title: 'Add Customer',
                subtitle: 'Register commercial client, contact & site details',
                icon: Icons.person_add_alt_1_outlined,
                color: const Color(0xFF2563EB),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/customers/create');
                },
                isDark: isDark,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildActionTile(
                context,
                title: 'Create AMC Contract',
                subtitle: 'Generate maintenance agreement, visits & coverage',
                icon: Icons.description_outlined,
                color: const Color(0xFF0D9488),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/contracts/create');
                },
                isDark: isDark,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildActionTile(
                context,
                title: 'Schedule Service Visit',
                subtitle: 'Dispatch certified technician for field execution',
                icon: Icons.calendar_month_outlined,
                color: const Color(0xFF8B5CF6),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/schedules');
                },
                isDark: isDark,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildActionTile(
                context,
                title: 'Log Service Request',
                subtitle: 'Record breakdown ticket or client complaint',
                icon: Icons.report_problem_outlined,
                color: const Color(0xFFF59E0B),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/service-requests/create');
                },
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return _PressableCard(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withAlpha(8) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withAlpha(15) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withAlpha(isDark ? 45 : 20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }
}

class _PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PressableCard({required this.child, required this.onTap});

  @override
  State<_PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<_PressableCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
