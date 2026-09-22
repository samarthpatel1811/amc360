import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/network/api_client.dart';

class ContractPaymentModal extends StatefulWidget {
  final Map<String, dynamic> contract;
  final VoidCallback? onPaymentSuccess;

  const ContractPaymentModal({
    super.key,
    required this.contract,
    this.onPaymentSuccess,
  });

  static Future<bool?> show(
    BuildContext context, {
    required Map<String, dynamic> contract,
    VoidCallback? onPaymentSuccess,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ContractPaymentModal(
        contract: contract,
        onPaymentSuccess: onPaymentSuccess,
      ),
    );
  }

  @override
  State<ContractPaymentModal> createState() => _ContractPaymentModalState();
}

class _ContractPaymentModalState extends State<ContractPaymentModal> {
  String _selectedMethod = 'upi';
  bool _isLoading = false;
  String? _errorMessage;

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'upi',
      'title': 'UPI / QR Code',
      'subtitle': 'Google Pay, PhonePe, Paytm, BHIM',
      'icon': Icons.qr_code_scanner_rounded,
      'color': Color(0xFF10B981),
    },
    {
      'id': 'net_banking',
      'title': 'Net Banking',
      'subtitle': 'All major Indian banks supported',
      'icon': Icons.account_balance_rounded,
      'color': Color(0xFF2563EB),
    },
    {
      'id': 'card',
      'title': 'Credit / Debit Card',
      'subtitle': 'Visa, MasterCard, RuPay',
      'icon': Icons.credit_card_rounded,
      'color': Color(0xFF8B5CF6),
    },
    {
      'id': 'cash',
      'title': 'Cash / Cheque / Bank Transfer',
      'subtitle': 'Direct offline payment to service provider',
      'icon': Icons.payments_rounded,
      'color': Color(0xFFF59E0B),
    },
  ];

  Future<void> _processPayment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final contractId = widget.contract['id'];
    try {
      final res = await ApiClient().post('/contracts/$contractId/pay-contract', data: {
        'payment_method': _selectedMethod,
      });

      if (res.data['success'] == true && mounted) {
        widget.onPaymentSuccess?.call();
        Navigator.pop(context, true);
      } else {
        setState(() {
          _errorMessage = res.data['message'] ?? 'Payment failed. Please try again.';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final totalPrice = widget.contract['total_price'] ?? 0;
    final formattedPrice = NumberFormat('#,##,###').format(totalPrice);
    final contractNum = widget.contract['contract_number'] ?? 'AMC';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AMC Payment Request',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Contract: $contractNum',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF3B82F6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.pop(context, false),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Price Highlight Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF064E3B), const Color(0xFF065F46)]
                    : [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF10B981).withAlpha(isDark ? 80 : 120),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL PAYABLE AMOUNT',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'All Taxes & Service Included',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF065F46),
                      ),
                    ),
                  ],
                ),
                Text(
                  '₹$formattedPrice',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          Text(
            'Select Payment Mode',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 10),

          // Payment mode options
          ..._paymentMethods.map((m) {
            final isSelected = _selectedMethod == m['id'];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? (m['color'] as Color).withAlpha(isDark ? 35 : 15)
                    : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? (m['color'] as Color)
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (m['color'] as Color).withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(m['icon'] as IconData, size: 20, color: m['color'] as Color),
                ),
                title: Text(
                  m['title'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                subtitle: Text(
                  m['subtitle'] as String,
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle_rounded, color: m['color'] as Color, size: 22)
                    : Icon(Icons.radio_button_off_rounded, color: isDark ? Colors.white24 : const Color(0xFFCBD5E1), size: 22),
                onTap: () => setState(() => _selectedMethod = m['id'] as String),
              ),
            );
          }),

          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Action Button
          ElevatedButton(
            onPressed: _isLoading ? null : _processPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Confirm & Pay ₹$formattedPrice',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'AMC and service visits will be scheduled instantly upon payment.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }
}
