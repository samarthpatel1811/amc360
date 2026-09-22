import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/error_state.dart';
import '../auth/auth_provider.dart';
import 'widgets/renewal_request_dialog.dart';
import 'widgets/renewal_quote_dialog.dart';
import 'widgets/contract_payment_modal.dart';

class ContractDetailScreen extends ConsumerStatefulWidget {
  final int contractId;

  const ContractDetailScreen({super.key, required this.contractId});

  @override
  ConsumerState<ContractDetailScreen> createState() => _ContractDetailScreenState();
}

class _ContractDetailScreenState extends ConsumerState<ContractDetailScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _contract;
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    _fetchContract();
  }

  Future<void> _fetchContract() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiClient().get('/contracts/${widget.contractId}');
      if (res.data['success'] == true) {
        setState(() {
          _contract = res.data['data'];
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

  Future<void> _handleRenewalAction(bool isCustomer, bool isAdmin) async {
    final renewalStatus = _contract?['renewal_status'] ?? 'none';

    if (isCustomer) {
      if (renewalStatus == 'quoted') {
        _confirmAndPayRenewal();
      } else {
        final res = await showDialog<bool>(
          context: context,
          builder: (ctx) => RenewalRequestDialog(contract: _contract!),
        );
        if (res == true) _fetchContract();
      }
    } else if (isAdmin) {
      final res = await showDialog<bool>(
        context: context,
        builder: (ctx) => RenewalQuoteDialog(contract: _contract!),
      );
      if (res == true) _fetchContract();
    }
  }

  Future<void> _confirmAndPayRenewal() async {
    final price = _contract?['renewal_quoted_price'] ?? _contract?['total_price'] ?? 0;
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
              'AMC Contract Renewal for ${_contract?['contract_number']}',
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
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Pay ₹$price Now'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessingPayment = true);
    try {
      final res = await ApiClient().post('/contracts/${widget.contractId}/accept-renewal', data: {});
      if (res.data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment successful! Contract renewed and active.'),
              backgroundColor: AppTheme.success,
            ),
          );
          _fetchContract();
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Contract Details')),
        body: const LoadingState(message: 'Loading agreement details...'),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Contract Details')),
        body: ErrorState(message: _errorMessage!, onRetry: _fetchContract),
      );
    }

    final authState = ref.watch(authProvider);
    final isCustomer = authState.isCustomer;
    final isAdmin = authState.isAdmin;

    final cust = _contract?['customer'] ?? {};
    final assets = _contract?['assets'] as List? ?? [];
    final schedules = _contract?['service_schedules'] as List? ?? [];
    final status = _contract?['status'] ?? 'active';
    final renewalStatus = _contract?['renewal_status'] ?? 'none';
    final quotedPrice = _contract?['renewal_quoted_price'];
    final quotedNotes = _contract?['renewal_quoted_notes'];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final secondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AMC Agreement Details'),
        actions: [
          if (isCustomer && renewalStatus == 'none' && (status == 'active' || status == 'expired'))
            TextButton.icon(
              onPressed: () => _handleRenewalAction(isCustomer, isAdmin),
              icon: const Icon(Icons.autorenew, size: 18),
              label: const Text('Renew'),
            ),
          if (isAdmin && renewalStatus == 'requested')
            ElevatedButton.icon(
              onPressed: () => _handleRenewalAction(isCustomer, isAdmin),
              icon: const Icon(Icons.request_quote_rounded, size: 16),
              label: const Text('Set Quote'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Payment Request Banner
          if (status == 'payment_requested') ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withAlpha(isDark ? 30 : 15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF59E0B).withAlpha(70)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.payment_rounded, color: Color(0xFFD97706), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Payment Requested',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFB45309)),
                          ),
                        ],
                      ),
                      Text(
                        '₹${_contract?['total_price'] ?? 0}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFFB45309)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isCustomer
                        ? 'Please complete payment to activate this AMC contract and generate scheduled service visits.'
                        : 'Awaiting client approval & payment. You can also record payment directly if received offline.',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle_rounded, size: 16),
                          label: Text(isCustomer ? 'Pay & Activate' : 'Record Payment'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            ContractPaymentModal.show(
                              context,
                              contract: _contract!,
                              onPaymentSuccess: _fetchContract,
                            );
                          },
                        ),
                      ),
                      if (isCustomer) ...[
                        const SizedBox(width: 10),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                            side: const BorderSide(color: Color(0xFFEF4444)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Decline Contract?'),
                                content: const Text('Are you sure you want to decline this AMC payment request?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Decline'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await ApiClient().post('/contracts/${widget.contractId}/decline-payment', data: {});
                              _fetchContract();
                            }
                          },
                          child: const Text('Decline'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ] else if (status == 'payment_declined') ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withAlpha(isDark ? 30 : 15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEF4444).withAlpha(70)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.cancel_outlined, color: Color(0xFFEF4444), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Payment Declined',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFEF4444)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isCustomer
                        ? 'You have declined this AMC payment request. Contact admin to discuss revised terms.'
                        : 'Client has declined payment for this contract. Review terms or contact client.',
                    style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B)),
                  ),
                ],
              ),
            ),
          ],

          // Renewal Status Banner
          if (renewalStatus == 'quoted') ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withAlpha(isDark ? 30 : 15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF10B981).withAlpha(70)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Renewal Quote Ready',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF047857)),
                          ),
                        ],
                      ),
                      Text(
                        '₹$quotedPrice',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF047857)),
                      ),
                    ],
                  ),
                  if (quotedNotes != null && quotedNotes.toString().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('Note: $quotedNotes', style: const TextStyle(fontSize: 12, color: Color(0xFF065F46))),
                  ],
                  if (isCustomer) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: _isProcessingPayment
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.payment_rounded, size: 18),
                        label: Text('Pay ₹$quotedPrice & Activate Renewal'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isProcessingPayment ? null : _confirmAndPayRenewal,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else if (renewalStatus == 'requested') ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withAlpha(isDark ? 30 : 15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF59E0B).withAlpha(60)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Renewal Quote Requested',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFB45309)),
                        ),
                        Text(
                          isAdmin
                              ? 'Customer has submitted renewal requirements. Tap "Set Quote" to price this contract.'
                              : 'Admin is reviewing your renewal requirements. Your quote will be displayed here.',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Contract Summary Header
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _contract?['contract_number'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    ),
                    StatusBadge(status: status),
                  ],
                ),
                const SizedBox(height: 6),
                Text(_contract?['title'] ?? '', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primary)),
                Text('Client: ${cust['name'] ?? ''} (${cust['company_name'] ?? ''})', style: TextStyle(fontSize: 13, color: secondary)),
                const Divider(height: 18),
                Row(
                  children: [
                    Icon(Icons.date_range, size: 16, color: secondary),
                    const SizedBox(width: 6),
                    Text('${_contract?['start_date']} to ${_contract?['end_date']}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primary)),
                    const Spacer(),
                    Text('₹${_contract?['total_price']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Frequency: ${_contract?['service_frequency']} • SLA Response: ${_contract?['sla_response_time'] ?? '24 Hours'}',
                    style: TextStyle(fontSize: 12, color: secondary)),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Covered Equipment
          Text('Covered Equipment (${assets.length})', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primary)),
          const SizedBox(height: 8),
          ...assets.map((a) => AppCard(
                onTap: () => context.push('/assets/${a['id']}'),
                child: Row(
                  children: [
                    const Icon(Icons.precision_manufacturing, size: 24, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${a['asset_code']} — ${a['brand']} ${a['model']}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primary)),
                          Text('SN: ${a['serial_number']} • ${a['location'] ?? 'On Site'}', style: TextStyle(fontSize: 11, color: secondary)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 18, color: secondary),
                  ],
                ),
              )),
          const SizedBox(height: 16),

          // Scheduled Visits Timeline
          Text('Scheduled Maintenance Timeline', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primary)),
          const SizedBox(height: 8),
          ...schedules.map((s) {
            final tech = s['technician'];
            return AppCard(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.event, color: AppTheme.primaryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Visit Date: ${s['scheduled_date']}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primary)),
                        Text('Tech: ${tech?['name'] ?? 'Unassigned'} • Time: ${s['scheduled_time_start'] ?? '10:00'}',
                            style: TextStyle(fontSize: 11, color: secondary)),
                      ],
                    ),
                  ),
                  StatusBadge(status: s['status'] ?? 'scheduled'),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
