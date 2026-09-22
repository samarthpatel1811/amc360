import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/status_badge.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final int invoiceId;

  const InvoiceDetailScreen({
    super.key,
    required this.invoiceId,
  });

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _invoice;

  @override
  void initState() {
    super.initState();
    _fetchInvoice();
  }

  Future<void> _fetchInvoice() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await _api.get('/invoices/${widget.invoiceId}');
      if (res.statusCode == 200 && res.data['data'] != null) {
        setState(() {
          _invoice = res.data['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load invoice';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invoice Details')),
        body: const LoadingState(message: 'Loading invoice...'),
      );
    }

    if (_error != null || _invoice == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invoice Details')),
        body: ErrorState(message: _error ?? 'Invoice not found', onRetry: _fetchInvoice),
      );
    }

    final inv = _invoice!;
    final invNumber = inv['invoice_number'] ?? 'INV-${widget.invoiceId}';
    final status = inv['status'] ?? 'issued';
    final customer = inv['customer'] ?? {};
    final contract = inv['contract'];
    final items = List<dynamic>.from(inv['items'] ?? []);
    final payments = List<dynamic>.from(inv['payments'] ?? []);

    final subtotal = double.tryParse(inv['subtotal']?.toString() ?? '0') ?? 0.0;
    final discount = double.tryParse(inv['discount_amount']?.toString() ?? '0') ?? 0.0;
    final taxRate = double.tryParse(inv['tax_rate']?.toString() ?? '0') ?? 0.0;
    final taxAmount = double.tryParse(inv['tax_amount']?.toString() ?? '0') ?? 0.0;
    final totalAmount = double.tryParse(inv['total_amount']?.toString() ?? '0') ?? 0.0;
    final paidAmount = double.tryParse(inv['paid_amount']?.toString() ?? '0') ?? 0.0;
    final balanceDue = double.tryParse(inv['balance_due']?.toString() ?? '0') ?? 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(invNumber),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: StatusBadge(status: status)),
          ),
        ],
      ),
      bottomNavigationBar: balanceDue > 0
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: AppButton(
                  label: 'Record Payment (₹${balanceDue.toStringAsFixed(2)} Due)',
                  icon: Icons.payments_outlined,
                  onPressed: () async {
                    final recorded = await context.push('/invoices/${widget.invoiceId}/payment', extra: inv);
                    if (recorded == true) _fetchInvoice();
                  },
                ),
              ),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Billed To', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    if (contract != null)
                      Text(
                        'AMC: ${contract['contract_number']}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  customer['name'] ?? 'Customer',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (customer['company_name'] != null)
                  Text(
                    customer['company_name'],
                    style: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                  ),
                const SizedBox(height: 4),
                Text(
                  customer['phone'] ?? '',
                  style: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary, fontSize: 13),
                ),
                Text(
                  '${customer['address'] ?? ''}, ${customer['city'] ?? ''}',
                  style: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary, fontSize: 13),
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Issue Date',
                          style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                        ),
                        Text(
                          inv['issue_date'] ?? 'N/A',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Due Date',
                          style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                        ),
                        Text(
                          inv['due_date'] ?? 'N/A',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: balanceDue > 0
                                ? AppTheme.error
                                : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Invoice Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 12),
                ...items.map((item) {
                  final desc = item['description'] ?? 'Item';
                  final qty = item['quantity'] ?? 1;
                  final price = item['unit_price'] ?? 0;
                  final total = item['total_price'] ?? (qty * price);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(desc, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              Text(
                                'Qty: $qty × ₹$price',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹${total.toString()}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(height: 24),
                _buildSummaryRow('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
                if (discount > 0)
                  _buildSummaryRow('Discount', '-₹${discount.toStringAsFixed(2)}', color: AppTheme.success),
                _buildSummaryRow('Tax (${taxRate.toStringAsFixed(1)}%)', '₹${taxAmount.toStringAsFixed(2)}'),
                const Divider(height: 16),
                _buildSummaryRow('Grand Total', '₹${totalAmount.toStringAsFixed(2)}', isBold: true, fontSize: 16),
                _buildSummaryRow('Paid Amount', '₹${paidAmount.toStringAsFixed(2)}', color: AppTheme.success),
                _buildSummaryRow(
                  'Balance Due',
                  '₹${balanceDue.toStringAsFixed(2)}',
                  isBold: true,
                  fontSize: 16,
                  color: balanceDue > 0 ? AppTheme.error : AppTheme.success,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment History (${payments.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 12),
                if (payments.isEmpty)
                  Text(
                    'No payments recorded yet for this invoice.',
                    style: TextStyle(
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  ...payments.map((p) {
                    final payNumber = p['payment_number'] ?? 'PAY';
                    final amount = p['amount'] ?? 0;
                    final method = p['payment_method']?.toString().toUpperCase() ?? 'CASH';
                    final date = p['payment_date'] ?? '';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$payNumber • $method', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(
                                date,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '+₹${amount.toString()}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.success),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, double fontSize = 14, Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final secondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? primary : secondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? (isBold ? primary : secondary),
            ),
          ),
        ],
      ),
    );
  }
}
