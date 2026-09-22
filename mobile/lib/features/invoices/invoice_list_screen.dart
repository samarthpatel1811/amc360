import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../app/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_search_bar.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/status_badge.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  String? _error;
  List<dynamic> _invoices = [];
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
  }

  Future<void> _fetchInvoices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await _api.get('/invoices');
      if (res.statusCode == 200 && res.data['data'] != null) {
        setState(() {
          _invoices = res.data['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load invoices';
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

  List<dynamic> get _filteredInvoices {
    return _invoices.where((inv) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          (inv['invoice_number']?.toString().toLowerCase().contains(query) ?? false) ||
          (inv['customer']?['name']?.toString().toLowerCase().contains(query) ?? false);

      final matchesStatus = _statusFilter == 'all' ||
          (inv['status']?.toString().toLowerCase() == _statusFilter.toLowerCase());

      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices & Billing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchInvoices,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppSearchBar(
              hintText: 'Search invoices, customers...',
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('all', 'All Invoices'),
                const SizedBox(width: 8),
                _buildFilterChip('issued', 'Issued / Unpaid'),
                const SizedBox(width: 8),
                _buildFilterChip('partially_paid', 'Partially Paid'),
                const SizedBox(width: 8),
                _buildFilterChip('paid', 'Fully Paid'),
                const SizedBox(width: 8),
                _buildFilterChip('overdue', 'Overdue'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _statusFilter == key;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _statusFilter = key);
      },
      selectedColor: AppTheme.primaryColor.withAlpha(isDark ? 60 : 30),
      backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
      side: BorderSide(
        color: isSelected ? AppTheme.primaryColor : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
      labelStyle: TextStyle(
        color: isSelected ? (isDark ? Colors.white : AppTheme.primaryColor) : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingState(message: 'Loading invoices...');
    }

    if (_error != null) {
      return ErrorState(
        message: _error!,
        onRetry: _fetchInvoices,
      );
    }

    final list = _filteredInvoices;

    if (list.isEmpty) {
      return const EmptyState(
        title: 'No Invoices Found',
        message: 'No billing records match your current filter.',
        icon: Icons.receipt_long_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchInvoices,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final inv = list[index];
          final id = inv['id'];
          final invNumber = inv['invoice_number'] ?? 'INV-$id';
          final status = inv['status'] ?? 'issued';
          final customerName = inv['customer']?['name'] ?? 'N/A';
          final totalAmount = double.tryParse(inv['total_amount']?.toString() ?? '0') ?? 0.0;
          final balanceDue = double.tryParse(inv['balance_due']?.toString() ?? '0') ?? 0.0;
          final dueDate = inv['due_date'];

          String dueText = '';
          if (dueDate != null) {
            final dt = DateTime.tryParse(dueDate);
            if (dt != null) dueText = 'Due on ${DateFormat('dd MMM yyyy').format(dt)}';
          }

          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AppCard(
            margin: const EdgeInsets.only(bottom: 12),
            onTap: () {
              context.push('/invoices/$id');
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      invNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    StatusBadge(status: status),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.business_outlined, size: 16, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        customerName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Amount', style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
                        Text(
                          '₹${totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Balance Due', style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
                        Text(
                          '₹${balanceDue.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: balanceDue > 0 ? AppTheme.error : AppTheme.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (dueText.isNotEmpty) ...[
                  const Divider(height: 18),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 6),
                      Text(dueText, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
