import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool showDot;

  const StatusBadge({
    super.key,
    required this.status,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final s = status.toLowerCase().replaceAll(' ', '_');

    final (Color lightBg, Color lightFg, Color darkBg, Color darkFg, String label) = switch (s) {
      'active' => (
          const Color(0xFFDCFCE7),
          const Color(0xFF15803D),
          const Color(0xFF064E3B),
          const Color(0xFF6EE7B7),
          'Active'
        ),
      'completed' => (
          const Color(0xFFDCFCE7),
          const Color(0xFF15803D),
          const Color(0xFF064E3B),
          const Color(0xFF6EE7B7),
          'Completed'
        ),
      'paid' => (
          const Color(0xFFDCFCE7),
          const Color(0xFF15803D),
          const Color(0xFF064E3B),
          const Color(0xFF6EE7B7),
          'Paid'
        ),
      'passed' => (
          const Color(0xFFDCFCE7),
          const Color(0xFF15803D),
          const Color(0xFF064E3B),
          const Color(0xFF6EE7B7),
          'Passed'
        ),

      'in_progress' => (
          const Color(0xFFDBEAFE),
          const Color(0xFF1D4ED8),
          const Color(0xFF1E3A8A),
          const Color(0xFF93C5FD),
          'In Progress'
        ),
      'scheduled' => (
          const Color(0xFFE0E7FF),
          const Color(0xFF4338CA),
          const Color(0xFF312E81),
          const Color(0xFFA5B4FC),
          'Scheduled'
        ),
      'assigned' => (
          const Color(0xFFE0E7FF),
          const Color(0xFF4338CA),
          const Color(0xFF312E81),
          const Color(0xFFA5B4FC),
          'Assigned'
        ),
      'issued' => (
          const Color(0xFFDBEAFE),
          const Color(0xFF1D4ED8),
          const Color(0xFF1E3A8A),
          const Color(0xFF93C5FD),
          'Issued'
        ),

      'partially_paid' => (
          const Color(0xFFFEF3C7),
          const Color(0xFFB45309),
          const Color(0xFF78350F),
          const Color(0xFFFCD34D),
          'Partially Paid'
        ),
      'rescheduled' => (
          const Color(0xFFFEF3C7),
          const Color(0xFFB45309),
          const Color(0xFF78350F),
          const Color(0xFFFCD34D),
          'Rescheduled'
        ),
      'pending' => (
          const Color(0xFFFEF3C7),
          const Color(0xFFB45309),
          const Color(0xFF78350F),
          const Color(0xFFFCD34D),
          'Pending'
        ),
      'under_maintenance' => (
          const Color(0xFFFEF3C7),
          const Color(0xFFB45309),
          const Color(0xFF78350F),
          const Color(0xFFFCD34D),
          'Maintenance'
        ),
      'under_repair' => (
          const Color(0xFFFEF3C7),
          const Color(0xFFB45309),
          const Color(0xFF78350F),
          const Color(0xFFFCD34D),
          'Repair'
        ),
      'new' => (
          const Color(0xFFF3E8FF),
          const Color(0xFF7E22CE),
          const Color(0xFF581C87),
          const Color(0xFFD8B4FE),
          'New'
        ),

      'expired' => (
          const Color(0xFFFEE2E2),
          const Color(0xFFB91C1C),
          const Color(0xFF7F1D1D),
          const Color(0xFFFCA5A5),
          'Expired'
        ),
      'payment_requested' => (
          const Color(0xFFFEF3C7),
          const Color(0xFFB45309),
          const Color(0xFF78350F),
          const Color(0xFFFCD34D),
          'Payment Requested'
        ),
      'payment_declined' => (
          const Color(0xFFFEE2E2),
          const Color(0xFFB91C1C),
          const Color(0xFF7F1D1D),
          const Color(0xFFFCA5A5),
          'Declined Payment'
        ),
      'overdue' => (
          const Color(0xFFFEE2E2),
          const Color(0xFFB91C1C),
          const Color(0xFF7F1D1D),
          const Color(0xFFFCA5A5),
          'Overdue'
        ),
      'cancelled' => (
          const Color(0xFFF1F5F9),
          const Color(0xFF64748B),
          const Color(0xFF1E293B),
          const Color(0xFF94A3B8),
          'Cancelled'
        ),
      'inactive' => (
          const Color(0xFFF1F5F9),
          const Color(0xFF64748B),
          const Color(0xFF1E293B),
          const Color(0xFF94A3B8),
          'Inactive'
        ),
      'failed' => (
          const Color(0xFFFEE2E2),
          const Color(0xFFB91C1C),
          const Color(0xFF7F1D1D),
          const Color(0xFFFCA5A5),
          'Failed'
        ),
      'urgent' => (
          const Color(0xFFFEE2E2),
          const Color(0xFFB91C1C),
          const Color(0xFF7F1D1D),
          const Color(0xFFFCA5A5),
          'Urgent'
        ),
      'high' => (
          const Color(0xFFFEF3C7),
          const Color(0xFFB45309),
          const Color(0xFF78350F),
          const Color(0xFFFCD34D),
          'High'
        ),

      _ => (
          const Color(0xFFF1F5F9),
          const Color(0xFF64748B),
          const Color(0xFF1E293B),
          const Color(0xFF94A3B8),
          status.toUpperCase()
        ),
    };

    final bg = isDark ? darkBg : lightBg;
    final fg = isDark ? darkFg : lightFg;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fg,
              ),
            ),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
