import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';

class RenewalQuoteDialog extends StatefulWidget {
  final Map<String, dynamic> contract;

  const RenewalQuoteDialog({super.key, required this.contract});

  @override
  State<RenewalQuoteDialog> createState() => _RenewalQuoteDialogState();
}

class _RenewalQuoteDialogState extends State<RenewalQuoteDialog> {
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Suggest current contract price as default
    _priceController.text = (widget.contract['total_price'] ?? '').toString();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitQuote() async {
    final priceText = _priceController.text.trim();
    final price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      setState(() => _errorMessage = 'Please enter a valid renewal quote price');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final contractId = widget.contract['id'];
      final res = await ApiClient().post('/contracts/$contractId/quote-renewal', data: {
        'quoted_price': price,
        'quoted_notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      });

      if (res.data['success'] == true) {
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Renewal quote sent to customer! They can now pay directly.'),
              backgroundColor: AppTheme.success,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } else {
        setState(() {
          _isSubmitting = false;
          _errorMessage = res.data['message'] ?? 'Failed to submit quote.';
        });
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cust = widget.contract['customer'] ?? {};
    final renewalNotes = widget.contract['renewal_notes']?.toString();

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withAlpha(isDark ? 40 : 20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.request_quote_rounded, color: Color(0xFF10B981), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prepare Renewal Quote',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  '${cust['name'] ?? ''} • ${widget.contract['contract_number'] ?? ''}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withAlpha(isDark ? 30 : 15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEF4444).withAlpha(50)),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
                ),
              ),
            ],

            if (renewalNotes != null && renewalNotes.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withAlpha(isDark ? 25 : 12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF3B82F6).withAlpha(40)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Color(0xFF2563EB)),
                        SizedBox(width: 6),
                        Text(
                          'Customer Request Notes:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      renewalNotes,
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
                    ),
                  ],
                ),
              ),
            ],

            AppTextField(
              label: 'Final Renewal Price (₹)',
              hint: 'e.g. 45000',
              controller: _priceController,
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(Icons.currency_rupee_rounded),
            ),
            const SizedBox(height: 14),

            AppTextField(
              label: 'Message / Terms for Customer (Optional)',
              hint: 'e.g. Includes 4 quarterly visits + 10% loyalty discount',
              controller: _notesController,
              maxLines: 2,
            ),
            const SizedBox(height: 18),

            AppButton(
              label: 'Send Quote to Customer',
              icon: Icons.send_rounded,
              isLoading: _isSubmitting,
              onPressed: _submitQuote,
            ),
          ],
        ),
      ),
    );
  }
}
