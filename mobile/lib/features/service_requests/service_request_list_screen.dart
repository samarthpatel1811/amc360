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

class ServiceRequestListScreen extends StatefulWidget {
  const ServiceRequestListScreen({super.key});

  @override
  State<ServiceRequestListScreen> createState() => _ServiceRequestListScreenState();
}

class _ServiceRequestListScreenState extends State<ServiceRequestListScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  String? _error;
  List<dynamic> _requests = [];
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await _api.get('/service-requests');
      if (res.statusCode == 200 && res.data['data'] != null) {
        setState(() {
          _requests = res.data['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load service requests';
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

  List<dynamic> get _filteredRequests {
    return _requests.where((r) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          (r['request_number']?.toString().toLowerCase().contains(query) ?? false) ||
          (r['title']?.toString().toLowerCase().contains(query) ?? false) ||
          (r['customer']?['name']?.toString().toLowerCase().contains(query) ?? false) ||
          (r['asset']?['name']?.toString().toLowerCase().contains(query) ?? false);

      final matchesStatus = _statusFilter == 'all' ||
          (r['status']?.toString().toLowerCase() == _statusFilter.toLowerCase());

      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Complaints & Tickets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRequests,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await context.push('/service-requests/create');
          if (created == true) _fetchRequests();
        },
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('New Complaint'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppSearchBar(
              hintText: 'Search tickets, assets, customers...',
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('all', 'All Tickets'),
                const SizedBox(width: 8),
                _buildFilterChip('new', 'New / Open'),
                const SizedBox(width: 8),
                _buildFilterChip('assigned', 'Assigned'),
                const SizedBox(width: 8),
                _buildFilterChip('in_progress', 'In Progress'),
                const SizedBox(width: 8),
                _buildFilterChip('resolved', 'Resolved'),
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
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _statusFilter = key);
      },
      selectedColor: AppTheme.primaryColor.withAlpha(30),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingState(message: 'Loading complaints & tickets...');
    }

    if (_error != null) {
      return ErrorState(
        message: _error!,
        onRetry: _fetchRequests,
      );
    }

    final list = _filteredRequests;

    if (list.isEmpty) {
      return const EmptyState(
        title: 'No Service Requests',
        message: 'No breakdown or repair tickets found.',
        icon: Icons.confirmation_number_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchRequests,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final req = list[index];
          final id = req['id'];
          final reqNumber = req['request_number'] ?? 'SR-$id';
          final title = req['title'] ?? 'Complaint';
          final status = req['status'] ?? 'new';
          final priority = req['priority'] ?? 'normal';
          final customerName = req['customer']?['name'] ?? 'N/A';
          final assetName = req['asset']?['name'] ?? 'N/A';
          final isCovered = req['is_covered_under_amc'] == true;
          final slaDueAt = req['sla_due_at'];

          String slaText = '';
          bool isOverdue = false;
          if (slaDueAt != null) {
            final due = DateTime.tryParse(slaDueAt);
            if (due != null) {
              final now = DateTime.now();
              isOverdue = due.isBefore(now) && status != 'resolved' && status != 'closed';
              slaText = DateFormat('dd MMM, hh:mm a').format(due);
            }
          }

          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AppCard(
            margin: const EdgeInsets.only(bottom: 12),
            onTap: () {
              context.push('/service-requests/$id');
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      reqNumber,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        _buildPriorityBadge(priority),
                        const SizedBox(width: 6),
                        StatusBadge(status: status),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.business, size: 15, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '$customerName • Asset: $assetName',
                        style: TextStyle(fontSize: 13, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isCovered ? AppTheme.success.withAlpha(25) : AppTheme.textSecondary.withAlpha(25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isCovered ? 'AMC COVERED' : 'NON-AMC / CHARGEABLE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isCovered ? AppTheme.success : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (slaText.isNotEmpty) ...[
                      Icon(Icons.timer_outlined, size: 14, color: isOverdue ? AppTheme.error : AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'SLA: $slaText',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                          color: isOverdue ? AppTheme.error : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    final p = priority.toLowerCase();
    final (Color bg, Color fg, String label) = switch (p) {
      'urgent' => (const Color(0xFFFEE2E2), const Color(0xFFB91C1C), 'URGENT'),
      'high' => (const Color(0xFFFEF3C7), const Color(0xFFB45309), 'HIGH'),
      'low' => (const Color(0xFFF1F5F9), const Color(0xFF64748B), 'LOW'),
      _ => (const Color(0xFFDBEAFE), const Color(0xFF1D4ED8), 'NORMAL'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
