import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_search_bar.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/error_state.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final _searchController = TextEditingController();
  String _selectedStatus = 'all';
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _customers = [];

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
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

      final res = await ApiClient().get('/customers', queryParameters: query);
      if (res.data['success'] == true) {
        setState(() {
          _customers = res.data['data']['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = res.data['message'] ?? 'Failed to load customers';
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
      backgroundColor: isDark ? AppTheme.darkBg : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Client Directory',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            onPressed: () async {
              final created = await context.push<bool>('/customers/create');
              if (created == true) _fetchCustomers();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter & Search Controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            color: isDark ? AppTheme.darkBg : Colors.white,
            child: Column(
              children: [
                AppSearchBar(
                  controller: _searchController,
                  hintText: 'Search organization, phone, or city...',
                  onChanged: (val) {
                    Future.delayed(const Duration(milliseconds: 350), _fetchCustomers);
                  },
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All Statuses', 'all', isDark),
                      const SizedBox(width: 6),
                      _buildFilterChip('Active', 'active', isDark),
                      const SizedBox(width: 6),
                      _buildFilterChip('Inactive', 'inactive', isDark),
                      const SizedBox(width: 6),
                      _buildFilterChip('Archived', 'archived', isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Customer List
          Expanded(
            child: _isLoading
                ? const LoadingState(message: 'Loading clients...')
                : _errorMessage != null
                    ? ErrorState(message: _errorMessage!, onRetry: _fetchCustomers)
                    : _customers.isEmpty
                        ? EmptyState(
                            title: 'No customers found',
                            message: 'Add your first enterprise or residential customer profile.',
                            icon: Icons.people_outline,
                            actionLabel: 'Add Customer',
                            onAction: () async {
                              final created = await context.push<bool>('/customers/create');
                              if (created == true) _fetchCustomers();
                            },
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchCustomers,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 100),
                              itemCount: _customers.length,
                              itemBuilder: (context, idx) {
                                final cust = _customers[idx];
                                return _buildCustomerCard(context, cust, isDark);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, dynamic cust, bool isDark) {
    final name = cust['name']?.toString() ?? 'Client';
    final company = cust['company_name']?.toString() ?? name;
    final initial = company.isNotEmpty ? company[0].toUpperCase() : 'C';
    final assetsCount = cust['assets_count'] ?? 0;
    final contractsCount = cust['contracts_count'] ?? 0;
    final status = cust['status']?.toString() ?? 'active';

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => context.push('/customers/${cust['id']}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name, Status
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cust['customer_code'] ?? 'ID #${cust['id']}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: status),
            ],
          ),

          // Active AMC Badge
          const SizedBox(height: 8),
          if (contractsCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withAlpha(isDark ? 35 : 15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF2563EB).withAlpha(isDark ? 70 : 35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_outlined, size: 13, color: Color(0xFF3B82F6)),
                  const SizedBox(width: 5),
                  Text(
                    '$contractsCount Active AMC Plan${contractsCount > 1 ? 's' : ''} Linked',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withAlpha(8) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_outlined, size: 13, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  const SizedBox(width: 5),
                  Text(
                    'No Active AMC',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: AppSpacing.sm),

          // Metrics row: Assets, Contracts, Outstanding
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCardMetric(Icons.precision_manufacturing_outlined, '$assetsCount Assets', isDark),
                Container(width: 1, height: 16, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                _buildCardMetric(Icons.shield_outlined, '$contractsCount AMCs', isDark),
                Container(width: 1, height: 16, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                _buildCardMetric(Icons.account_balance_wallet_outlined, '₹72,000 Due', isDark, color: const Color(0xFFF59E0B)),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Footer: Next Service Date & Location
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.event_available_outlined, size: 14, color: Color(0xFF10B981)),
                  const SizedBox(width: 5),
                  Text(
                    'Next Service • 24 Sep',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 13,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        '${cust['city'] ?? 'Central'}${cust['state'] != null && cust['state'].toString().isNotEmpty ? ', ${cust['state']}' : ''}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardMetric(IconData icon, String label, bool isDark, {Color? color}) {
    final effectiveColor = color ?? (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: effectiveColor),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: effectiveColor,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDark) {
    final isSelected = _selectedStatus == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedStatus = value);
        _fetchCustomers();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2563EB)
              : (isDark ? Colors.white.withAlpha(10) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : (isDark ? Colors.white.withAlpha(15) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }
}
