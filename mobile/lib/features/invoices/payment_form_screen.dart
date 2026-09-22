import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';

class PaymentFormScreen extends StatefulWidget {
  final int invoiceId;
  final Map<String, dynamic>? invoiceData;

  const PaymentFormScreen({
    super.key,
    required this.invoiceId,
    this.invoiceData,
  });

  @override
  State<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiClient _api = ApiClient();

  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _refCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  String _paymentMethod = 'bank_transfer';
  DateTime _paymentDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.invoiceData != null) {
      final balance = widget.invoiceData!['balance_due']?.toString() ?? '0';
      _amountCtrl.text = balance;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _refCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (picked != null) {
      setState(() => _paymentDate = picked);
    }
  }

  Future<void> _recordPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
      final payload = {
        'invoice_id': widget.invoiceId,
        'amount': amount,
        'payment_method': _paymentMethod,
        'payment_date': DateFormat('yyyy-MM-dd').format(_paymentDate),
        'transaction_reference': _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
        'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      };

      final res = await _api.post('/payments', data: payload);
      if (res.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment recorded and invoice balance updated!')),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to record payment: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final invNumber = widget.invoiceData?['invoice_number'] ?? 'INV-${widget.invoiceId}';
    final balance = widget.invoiceData?['balance_due']?.toString() ?? '0.00';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Payment'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invoice: $invNumber',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Outstanding Balance: ₹$balance',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.error),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payment Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Payment Amount (₹) *',
                    hint: '0.00',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    controller: _amountCtrl,
                    validator: (val) {
                      final parsed = double.tryParse(val ?? '');
                      if (parsed == null || parsed <= 0) return 'Valid amount required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _paymentMethod,
                    decoration: const InputDecoration(labelText: 'Payment Method *'),
                    items: const [
                      DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer (NEFT/RTGS/IMPS)')),
                      DropdownMenuItem(value: 'upi', child: Text('UPI / QR Payment')),
                      DropdownMenuItem(value: 'cheque', child: Text('Cheque / DD')),
                      DropdownMenuItem(value: 'card', child: Text('Credit / Debit Card')),
                      DropdownMenuItem(value: 'cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _paymentMethod = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Transaction Reference / Cheque No.',
                    hint: 'e.g. UTR4928193821',
                    controller: _refCtrl,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Payment Date', style: TextStyle(fontSize: 13, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
                    subtitle: Text(
                      DateFormat('dd MMMM yyyy').format(_paymentDate),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    trailing: const Icon(Icons.calendar_month, color: AppTheme.primaryColor),
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Remarks / Notes (Optional)',
                    hint: 'Payment received by cashier / bank note',
                    controller: _notesCtrl,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Confirm & Post Payment',
              icon: Icons.check_circle_outline,
              isLoading: _isSubmitting,
              onPressed: _recordPayment,
            ),
          ],
        ),
      ),
    );
  }
}
