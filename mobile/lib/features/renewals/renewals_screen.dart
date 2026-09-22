import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../app/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/status_badge.dart';

class RenewalsScreen extends StatefulWidget {
  const RenewalsScreen({super.key});

  @override
  State<RenewalsScreen> createState() => _RenewalsScreenState();
}

class _RenewalsScreenState extends State<RenewalsScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  String? _error;
  List<dynamic> _contracts = [];
  String _cohortFilter = 'all';

  @override
  void initState() {
    super.initState();
    _fetchContracts();
  }

  Future<void> _fetchContracts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await _api.get('/contracts?per_page=100');
      if (res.statusCode == 200 && res.data['data'] != null) {
        setState(() {
          _contracts = res.data['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load contracts';
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

  int _daysUntilExpiry(String? endDateStr) {
    if (endDateStr == null) return 999;
    final end = DateTime.tryParse(endDateStr);
    if (end == null) return 999;
    final now = DateTime.now();
    return end.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  List<dynamic> get _filteredContracts {
    return _contracts.where((c) {
      final days = _daysUntilExpiry(c['end_date']);
      return switch (_cohortFilter) {
        '0_7' => days >= 0 && days <= 7,
        '8_30' => days >= 8 && days <= 30,
        '31_60' => days >= 31 && days <= 60,
        '61_90' => days >= 61 && days <= 90,
        'expired' => days < 0,
        _ => days <= 90, // Upcoming renewals cohort
      };
    }).toList();
  }

  Future<void> _showRenewDialog(Map<String, dynamic> contract) async {
    final oldEndDate = DateTime.tryParse(contract['end_date'] ?? '') ?? DateTime.now();
    final newStartDate = oldEndDate.add(const Duration(days: 1));
    final priceCtrl = TextEditingController(text: (contract['total_price'] ?? '0').toString());
    String durationType = contract['duration_type'] ?? '12_months';
    String frequency = contract['service_frequency'] ?? 'monthly';
    final assets = List<dynamic>.from(contract['assets'] ?? []);
    final assetIds = assets.map((a) => a['id']).toList();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            title: Text('Renew Contract ${contract['contract_number']}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customer: ${contract['customer']?['name'] ?? 'N/A'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'New Period Starts: ${DateFormat('dd MMM yyyy').format(newStartDate)}',
                    style: TextStyle(
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: durationType,
                  decoration: const InputDecoration(labelText: 'Renewal Duration'),
                  items: const [
                    DropdownMenuItem(value: '1_month', child: Text('1 Month')),
                    DropdownMenuItem(value: '3_months', child: Text('3 Months (Quarterly)')),
                    DropdownMenuItem(value: '6_months', child: Text('6 Months (Half-Yearly)')),
                    DropdownMenuItem(value: '12_months', child: Text('12 Months (1 Year)')),
                    DropdownMenuItem(value: '24_months', child: Text('24 Months (2 Years)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => durationType = val);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: frequency,
                  decoration: const InputDecoration(labelText: 'Service Visit Frequency'),
                  items: const [
                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                    DropdownMenuItem(value: 'bi_monthly', child: Text('Bi-Monthly (Every 2 Months)')),
                    DropdownMenuItem(value: 'quarterly', child: Text('Quarterly')),
                    DropdownMenuItem(value: 'half_yearly', child: Text('Half-Yearly')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => frequency = val);
                  },
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Renewal Price (₹)',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  controller: priceCtrl,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  final payload = {
                    'start_date': DateFormat('yyyy-MM-dd').format(newStartDate),
                    'duration_type': durationType,
                    'service_frequency': frequency,
                    'total_price': double.tryParse(priceCtrl.text) ?? 0.0,
                    'asset_ids': assetIds.isEmpty ? [1] : assetIds,
                    'title': '${contract['title'] ?? 'AMC Contract'} (Renewed)',
                  };

                  final res = await _api.post('/contracts/${contract['id']}/renew', data: payload);
                  if (res.statusCode == 200 || res.statusCode == 201) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Contract renewed successfully! New schedule generated.')),
                    );
                    _fetchContracts();
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Renewal failed: $e'), backgroundColor: AppTheme.error),
                  );
                }
              },
              child: const Text('Confirm Renewal'),
            ),
          ],
        );
      },
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Renewals Cohorts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchContracts,
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildCohortChip('all', 'All (< 90d)'),
                const SizedBox(width: 8),
                _buildCohortChip('0_7', '0-7 Days (Urgent)'),
                const SizedBox(width: 8),
                _buildCohortChip('8_30', '8-30 Days'),
                const SizedBox(width: 8),
                _buildCohortChip('31_60', '31-60 Days'),
                const SizedBox(width: 8),
                _buildCohortChip('61_90', '61-90 Days'),
                const SizedBox(width: 8),
                _buildCohortChip('expired', 'Already Expired'),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildCohortChip(String key, String label) {
    final isSelected = _cohortFilter == key;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _cohortFilter = key);
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
      return const LoadingState(message: 'Loading renewals cohort...');
    }

    if (_error != null) {
      return ErrorState(message: _error!, onRetry: _fetchContracts);
    }

    final list = _filteredContracts;

    if (list.isEmpty) {
      return const EmptyState(
        title: 'No Contracts In This Cohort',
        message: 'No active contracts match this expiry window.',
        icon: Icons.autorenew_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchContracts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final c = list[index];
          final contractNumber = c['contract_number'] ?? 'AMC';
          final customerName = c['customer']?['name'] ?? 'Customer';
          final endDateStr = c['end_date'];
          final days = _daysUntilExpiry(endDateStr);
          final price = c['total_price'] ?? 0;
          final status = c['status'] ?? 'active';

          String badgeText;
          Color badgeColor;
          if (days < 0) {
            badgeText = 'Expired ${-days}d ago';
            badgeColor = AppTheme.error;
          } else if (days <= 7) {
            badgeText = 'Expires in $days days!';
            badgeColor = AppTheme.error;
          } else if (days <= 30) {
            badgeText = 'Expires in $days days';
            badgeColor = AppTheme.warning;
          } else {
            badgeText = 'Expires in $days days';
            badgeColor = AppTheme.info;
          }

          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AppCard(
            margin: const EdgeInsets.only(bottom: 12),
            onTap: () => context.push('/contracts/${c['id']}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      contractNumber,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      ),
                    ),
                    StatusBadge(status: status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  customerName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'End Date: ${endDateStr ?? 'N/A'} • Value: ₹$price',
                  style: TextStyle(fontSize: 13, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: badgeColor),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => _showRenewDialog(c),
                      icon: const Icon(Icons.autorenew, size: 16),
                      label: const Text('Renew'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
