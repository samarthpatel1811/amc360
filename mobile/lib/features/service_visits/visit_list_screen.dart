import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../app/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_search_bar.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/status_badge.dart';

class VisitListScreen extends StatefulWidget {
  const VisitListScreen({super.key});

  @override
  State<VisitListScreen> createState() => _VisitListScreenState();
}

class _VisitListScreenState extends State<VisitListScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  String? _error;
  List<dynamic> _visits = [];
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _fetchVisits();
  }

  Future<void> _fetchVisits() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _api.get('/service-visits');
      if (response.statusCode == 200 && response.data['data'] != null) {
        setState(() {
          _visits = response.data['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load service visits';
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

  List<dynamic> get _filteredVisits {
    return _visits.where((v) {
      final matchesSearch = _searchQuery.isEmpty ||
          (v['visit_number']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (v['customer']?['name']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (v['technician']?['name']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

      final matchesStatus = _statusFilter == 'all' ||
          (v['status']?.toString().toLowerCase() == _statusFilter.toLowerCase());

      return matchesSearch && matchesStatus;
    }).toList();
  }

  Future<void> _viewPdfReport(int visitId, String visitNumber) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading service report PDF...')),
      );
      final response = await _api.get('/service-visits/$visitId/pdf');
      if (response.statusCode == 200) {
        final pdfBytes = response.data as List<int>;
        await Printing.layoutPdf(
          onLayout: (_) => Uint8List.fromList(pdfBytes),
          name: 'Service_Report_$visitNumber.pdf',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading PDF: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Visits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchVisits,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppSearchBar(
              hintText: 'Search visits, customers, technicians...',
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('all', 'All Visits'),
                const SizedBox(width: 8),
                _buildFilterChip('in_progress', 'In Progress'),
                const SizedBox(width: 8),
                _buildFilterChip('completed', 'Completed'),
                const SizedBox(width: 8),
                _buildFilterChip('cancelled', 'Cancelled'),
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
      return const LoadingState(message: 'Loading service visits...');
    }

    if (_error != null) {
      return ErrorState(
        message: _error!,
        onRetry: _fetchVisits,
      );
    }

    final list = _filteredVisits;

    if (list.isEmpty) {
      return const EmptyState(
        title: 'No Service Visits Found',
        message: 'No service visits match your current filter.',
        icon: Icons.assignment_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchVisits,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final visit = list[index];
          final visitId = visit['id'];
          final visitNumber = visit['visit_number'] ?? 'VISIT-$visitId';
          final status = visit['status'] ?? 'pending';
          final customerName = visit['customer']?['name'] ?? 'N/A';
          final techName = visit['technician']?['name'] ?? 'Unassigned';
          final startedAt = visit['started_at'];
          final completedAt = visit['completed_at'];
          final hasReport = visit['report_document_id'] != null;

          String dateText = 'Not started';
          if (completedAt != null) {
            final dt = DateTime.tryParse(completedAt);
            if (dt != null) dateText = 'Completed on ${DateFormat('dd MMM yyyy, hh:mm a').format(dt)}';
          } else if (startedAt != null) {
            final dt = DateTime.tryParse(startedAt);
            if (dt != null) dateText = 'Started on ${DateFormat('dd MMM yyyy, hh:mm a').format(dt)}';
          }

          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AppCard(
            margin: const EdgeInsets.only(bottom: 12),
            onTap: () {
              context.push('/visits/$visitId');
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      visitNumber,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      ),
                    ),
                    StatusBadge(status: status),
                  ],
                ),
                const SizedBox(height: 10),
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
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 16, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'Technician: $techName',
                      style: TextStyle(fontSize: 13, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                    const SizedBox(width: 6),
                    Text(
                      dateText,
                      style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                    ),
                  ],
                ),
                if (hasReport) ...[
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _viewPdfReport(visitId, visitNumber),
                        icon: const Icon(Icons.picture_as_pdf, size: 16, color: AppTheme.primaryColor),
                        label: const Text('View Report PDF'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                      ),
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
