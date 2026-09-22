import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../app/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_search_bar.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/error_state.dart';

class ContractListScreen extends StatefulWidget {
  const ContractListScreen({super.key});

  @override
  State<ContractListScreen> createState() => _ContractListScreenState();
}

class _ContractListScreenState extends State<ContractListScreen> {
  final _searchController = TextEditingController();
  String _selectedStatus = 'all';
  String? _selectedCohort;
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _contracts = [];

  String _formatDate(dynamic rawDate) {
    if (rawDate == null) return '';
    final str = rawDate.toString().split('T').first;
    try {
      final dt = DateTime.parse(str);
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return str;
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchContracts();
  }

  Future<void> _fetchContracts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final query = <String, dynamic>{};
      if (_searchController.text.isNotEmpty) {
        query['search'] = _searchController.text;
      }
      if (_selectedStatus != 'all') {
        query['status'] = _selectedStatus;
      }
      if (_selectedCohort != null) {
        query['expiry_cohort'] = _selectedCohort;
      }

      final res = await ApiClient().get('/contracts', queryParameters: query);
      if (res.data['success'] == true) {
        setState(() {
          _contracts = res.data['data']['data'] ?? [];
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AMC Contracts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New AMC Contract',
            onPressed: () async {
              final created = await context.push<bool>('/contracts/new');
              if (created == true) _fetchContracts();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                AppSearchBar(
                  controller: _searchController,
                  hint: 'Search contract # or customer name...',
                  onChanged: (val) {
                    Future.delayed(const Duration(milliseconds: 400), _fetchContracts);
                  },
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildChip('All Contracts', 'all', isCohort: false),
                      const SizedBox(width: 6),
                      _buildChip('Active', 'active', isCohort: false),
                      const SizedBox(width: 6),
                      _buildChip('Expiring in 30 Days', '8-30', isCohort: true),
                      const SizedBox(width: 6),
                      _buildChip('Expiring in 7 Days', '0-7', isCohort: true),
                      const SizedBox(width: 6),
                      _buildChip('Expired', 'expired', isCohort: false),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const LoadingState(message: 'Loading maintenance agreements...')
                : _errorMessage != null
                    ? ErrorState(message: _errorMessage!, onRetry: _fetchContracts)
                    : _contracts.isEmpty
                        ? EmptyState(
                            title: 'No AMC contracts found',
                            message: 'Create contracts to generate service schedules and billing.',
                            icon: Icons.description_outlined,
                            actionLabel: 'New Contract',
                            onAction: () async {
                              final created = await context.push<bool>('/contracts/new');
                              if (created == true) _fetchContracts();
                            },
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchContracts,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                              itemCount: _contracts.length,
                              itemBuilder: (context, idx) {
                                final c = _contracts[idx];
                                final cust = c['customer'] ?? {};
                                final assets = c['assets'] as List? ?? [];

                                return AppCard(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  onTap: () => context.push('/contracts/${c['id']}'),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              c['contract_number'] ?? '',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primaryColor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          StatusBadge(status: c['status'] ?? 'active'),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        c['title'] ?? 'Annual Maintenance Contract',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                        ),
                                      ),
                                      Text(
                                        'Client: ${cust['name'] ?? ''} (${cust['company_name'] ?? ''})',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                        ),
                                      ),
                                      const Divider(height: 16),
                                      Row(
                                        children: [
                                          Icon(Icons.date_range, size: 14, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              '${_formatDate(c['start_date'])} to ${_formatDate(c['end_date'])}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '₹${c['total_price']}',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF2563EB).withAlpha(15),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Freq: ${c['service_frequency'] ?? 'Annual'}',
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '${assets.length} Covered Asset(s)',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                              ),
                                            ),
                                          ),
                                          Icon(Icons.chevron_right, size: 18, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String value, {required bool isCohort}) {
    final isSelected = isCohort ? _selectedCohort == value : (_selectedStatus == value && _selectedCohort == null);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
        ),
      ),
      selected: isSelected,
      selectedColor: AppTheme.primaryColor,
      backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
      showCheckmark: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
        ),
      ),
      onSelected: (_) {
        setState(() {
          if (isCohort) {
            _selectedCohort = value;
            _selectedStatus = 'active';
          } else {
            _selectedStatus = value;
            _selectedCohort = null;
          }
        });
        _fetchContracts();
      },
    );
  }
}
