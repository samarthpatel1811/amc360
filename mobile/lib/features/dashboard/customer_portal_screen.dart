import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../app/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/error_state.dart';
import '../auth/auth_provider.dart';
import '../contracts/widgets/renewal_request_dialog.dart';
import '../contracts/widgets/contract_payment_modal.dart';

class CustomerPortalScreen extends ConsumerStatefulWidget {
  const CustomerPortalScreen({super.key});

  @override
  ConsumerState<CustomerPortalScreen> createState() => _CustomerPortalScreenState();
}

class _CustomerPortalScreenState extends ConsumerState<CustomerPortalScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _dashboardData;
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    _fetchPortalData();
  }

  Future<void> _fetchPortalData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiClient().get('/dashboard/summary');
      if (res.data['success'] == true) {
        setState(() {
          _dashboardData = res.data['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = res.data['message'] ?? 'Failed to load customer portal';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _openRenewalDialog(Map<String, dynamic> contract) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => RenewalRequestDialog(contract: contract),
    );
    if (result == true) {
      _fetchPortalData();
    }
  }

  Future<void> _confirmAndPayRenewal(Map<String, dynamic> contract) async {
    final contractId = contract['id'];
    final price = contract['renewal_quoted_price'] ?? contract['total_price'] ?? 0;
    final notes = contract['renewal_quoted_notes'] ?? '';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.payment_rounded, color: Color(0xFF10B981), size: 24),
            SizedBox(width: 8),
            Text('Confirm Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AMC Contract Renewal for ${contract['contract_number']}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withAlpha(15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981).withAlpha(40)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Amount to Pay:', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    '₹$price',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF047857),
                    ),
                  ),
                ],
              ),
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Includes: $notes',
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF64748B)),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'Your renewed contract and maintenance schedule will be activated immediately upon payment.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_rounded, size: 18),
            label: Text('Pay ₹$price Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessingPayment = true);
    try {
      final res = await ApiClient().post('/contracts/$contractId/accept-renewal', data: {});
      if (res.data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment successful! Your AMC contract is renewed and active.'),
              backgroundColor: AppTheme.success,
              duration: Duration(seconds: 4),
            ),
          );
          _fetchPortalData();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.data['message'] ?? 'Payment failed.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingPayment = false);
    }
  }

  Future<void> _declineContractPayment(Map<String, dynamic> contract) async {
    final contractId = contract['id'];
    final reasonController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 24),
            SizedBox(width: 8),
            Text('Decline AMC Contract?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to decline contract ${contract['contract_number']}? Both you and your service provider will see the payment declined status.',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (Optional)',
                hintText: 'e.g., pricing discussion, revised terms needed',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Decline Payment'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final res = await ApiClient().post('/contracts/$contractId/decline-payment', data: {
        'reason': reasonController.text.trim().isNotEmpty ? reasonController.text.trim() : 'Declined by client',
      });

      if (res.data['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment request declined. Admin has been notified.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        _fetchPortalData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      final dt = DateTime.parse(date.toString().split('T').first);
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return date.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final customerName = _dashboardData?['customer_name'] ?? authState.user?['name'] ?? 'Client';
    final companyName = _dashboardData?['company_name'] ?? 'AMC Client';
    final primaryContract = _dashboardData?['primary_contract'];
    final nextVisit = _dashboardData?['next_visit'];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    companyName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withAlpha(isDark ? 50 : 20),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF7C3AED).withAlpha(80)),
                  ),
                  child: const Text(
                    'CLIENT PORTAL',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7C3AED),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              customerName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (mounted && context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingState(message: 'Loading your equipment portal...')
          : _errorMessage != null
              ? ErrorState(message: _errorMessage!, onRetry: _fetchPortalData)
              : RefreshIndicator(
                  onRefresh: _fetchPortalData,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    children: [
                      // 1. ACTIVE CONTRACT & RENEWAL HUB
                      _buildContractRenewalCard(primaryContract, isDark),
                      const SizedBox(height: 16),

                      // 2. NEXT SERVICE VISIT
                      if (nextVisit != null) ...[
                        _buildNextVisitCard(nextVisit, isDark),
                        const SizedBox(height: 16),
                      ],

                      // 3. ESSENTIAL ACTIONS (2x2 Grid)
                      Text(
                        'Quick Services',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 10),

                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.10,
                        children: [
                          _buildSimpleActionCard(
                            icon: Icons.support_agent_rounded,
                            iconColor: const Color(0xFFEF4444),
                            title: 'Request Service',
                            subtitle: 'Report issue or repair',
                            badge: '${_dashboardData?['open_requests'] ?? 0} Open',
                            onTap: () => context.push('/service-requests/create'),
                            isDark: isDark,
                          ),
                          _buildSimpleActionCard(
                            icon: Icons.ac_unit_rounded,
                            iconColor: const Color(0xFF2563EB),
                            title: 'My Equipment',
                            subtitle: '${_dashboardData?['equipment_count'] ?? 0} Units Covered',
                            onTap: () => context.push('/assets'),
                            isDark: isDark,
                          ),
                          _buildSimpleActionCard(
                            icon: Icons.receipt_long_rounded,
                            iconColor: const Color(0xFF10B981),
                            title: 'Invoices & Pay',
                            subtitle: 'Pending: ₹${_dashboardData?['pending_amount'] ?? 0}',
                            onTap: () => context.push('/invoices'),
                            isDark: isDark,
                          ),
                          _buildSimpleActionCard(
                            icon: Icons.verified_outlined,
                            iconColor: const Color(0xFF8B5CF6),
                            title: 'Service History',
                            subtitle: 'View signed reports',
                            onTap: () => context.push('/visits'),
                            isDark: isDark,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildContractRenewalCard(Map<String, dynamic>? contract, bool isDark) {
    if (contract == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
        ),
        child: const Column(
          children: [
            Icon(Icons.shield_outlined, size: 36, color: Color(0xFF64748B)),
            SizedBox(height: 8),
            Text('No Active AMC Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            SizedBox(height: 4),
            Text(
              'Contact your service provider to activate annual maintenance.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    final contractStatus = contract['status']?.toString() ?? 'active';

    if (contractStatus == 'payment_requested') {
      return _buildPaymentRequestedCard(contract, isDark);
    }

    if (contractStatus == 'payment_declined') {
      return _buildPaymentDeclinedCard(contract, isDark);
    }

    final renewalStatus = contract['renewal_status']?.toString() ?? 'none';
    final quotedPrice = contract['renewal_quoted_price'];
    final quotedNotes = contract['renewal_quoted_notes'];
    final contractNum = contract['contract_number'] ?? '';
    final endDate = _formatDate(contract['end_date']);
    final assets = contract['assets'] as List? ?? [];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border.all(
          color: renewalStatus == 'quoted'
              ? const Color(0xFF10B981)
              : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          width: renewalStatus == 'quoted' ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withAlpha(isDark ? 30 : 12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield_rounded, color: Color(0xFF2563EB), size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          contractNum,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withAlpha(isDark ? 40 : 20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'ACTIVE AMC',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contract['title'] ?? 'Annual Maintenance Contract',
                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Valid until: $endDate • ${assets.length} Air Conditioners Covered',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),

                // SCENARIO 1: QUOTE READY TO PAY DIRECTLY
                if (renewalStatus == 'quoted') ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withAlpha(isDark ? 25 : 12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF10B981).withAlpha(60)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                                  SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Renewal Quote Ready',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF047857),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₹$quotedPrice',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF047857),
                              ),
                            ),
                          ],
                        ),
                        if (quotedNotes != null && quotedNotes.toString().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Admin note: $quotedNotes',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF065F46)),
                          ),
                        ],
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: _isProcessingPayment
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.payment_rounded, size: 18),
                            label: Text(
                              _isProcessingPayment ? 'Processing Payment...' : 'Pay ₹$quotedPrice & Renew Now',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            onPressed: _isProcessingPayment ? null : () => _confirmAndPayRenewal(contract),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]
                // SCENARIO 2: RENEWAL REQUESTED (WAITING FOR ADMIN)
                else if (renewalStatus == 'requested') ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withAlpha(isDark ? 25 : 12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF59E0B).withAlpha(50)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Renewal Quote Requested',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB45309),
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Admin is reviewing your details to prepare your final quote. You will see the price here once ready.',
                                style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ]
                // SCENARIO 3: NORMAL / RENEWAL BUTTON
                else ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.autorenew_rounded, size: 18, color: Color(0xFF2563EB)),
                      label: const Text(
                        'Request Contract Renewal',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF2563EB)),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF2563EB)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _openRenewalDialog(contract),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextVisitCard(Map<String, dynamic> visit, bool isDark) {
    final asset = visit['asset'] ?? {};
    final scheduledDate = _formatDate(visit['scheduled_date']);
    final time = visit['scheduled_time_start'] ?? '10:00 AM';

    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withAlpha(isDark ? 40 : 15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.event_available_rounded, color: Color(0xFF2563EB), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Next Scheduled Maintenance',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 2),
                Text(
                  '$scheduledDate • $time',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  'Unit: ${asset['asset_code'] ?? 'Covered Unit'} (${asset['location'] ?? 'On Site'})',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleActionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? badge,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 30 : 6),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withAlpha(isDark ? 35 : 18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: iconColor.withAlpha(isDark ? 35 : 15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: iconColor),
                    ),
                  )
                else
                  Icon(Icons.arrow_forward_ios_rounded, size: 12, color: isDark ? Colors.white30 : Colors.black26),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRequestedCard(Map<String, dynamic> contract, bool isDark) {
    final totalPrice = contract['total_price'] ?? 0;
    final formattedPrice = NumberFormat('#,##,###').format(totalPrice);
    final contractNum = contract['contract_number'] ?? '';
    final startDate = _formatDate(contract['start_date']);
    final endDate = _formatDate(contract['end_date']);
    final frequency = contract['service_frequency']?.toString().replaceAll('_', ' ').toUpperCase() ?? 'QUARTERLY';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border.all(
          color: const Color(0xFFF59E0B),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withAlpha(isDark ? 40 : 25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Amber Banner Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withAlpha(isDark ? 35 : 15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.payment_rounded, color: Color(0xFFD97706), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      contractNum,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withAlpha(isDark ? 50 : 25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD97706)),
                  ),
                  child: const Text(
                    'PAYMENT REQUESTED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFB45309),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contract['title'] ?? 'Annual Maintenance Contract',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Valid: $startDate to $endDate • $frequency Visits',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),

                // Highlighted Price Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AMOUNT PAYABLE',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                          ),
                          SizedBox(height: 2),
                          Text('Includes Maintenance & SLA', style: TextStyle(fontSize: 11, color: Color(0xFF92400E))),
                        ],
                      ),
                      Text(
                        '₹$formattedPrice',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Interactive Buttons: Accept & Pay / Decline
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_rounded, size: 18),
                        label: const Text('Accept & Pay', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          ContractPaymentModal.show(
                            context,
                            contract: contract,
                            onPaymentSuccess: _fetchPortalData,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _declineContractPayment(contract),
                        child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
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

  Widget _buildPaymentDeclinedCard(Map<String, dynamic> contract, bool isDark) {
    final contractNum = contract['contract_number'] ?? '';
    final totalPrice = contract['total_price'] ?? 0;
    final formattedPrice = NumberFormat('#,##,###').format(totalPrice);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border.all(
          color: const Color(0xFFEF4444),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withAlpha(isDark ? 40 : 20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Red Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withAlpha(isDark ? 35 : 15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.cancel_outlined, color: Color(0xFFEF4444), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      contractNum,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withAlpha(isDark ? 50 : 25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEF4444)),
                  ),
                  child: const Text(
                    'DECLINED PAYMENT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFEF4444),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contract['title'] ?? 'Annual Maintenance Contract',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'The payment request of ₹$formattedPrice was declined. Please contact your service provider if you need a revised agreement or wish to reconsider.',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Reconsider & Pay'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF10B981),
                    side: const BorderSide(color: Color(0xFF10B981)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    ContractPaymentModal.show(
                      context,
                      contract: contract,
                      onPaymentSuccess: _fetchPortalData,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
