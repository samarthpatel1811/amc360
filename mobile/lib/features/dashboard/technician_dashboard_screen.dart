import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/error_state.dart';
import '../auth/auth_provider.dart';

class TechnicianDashboardScreen extends ConsumerStatefulWidget {
  const TechnicianDashboardScreen({super.key});

  @override
  ConsumerState<TechnicianDashboardScreen> createState() => _TechnicianDashboardScreenState();
}

class _TechnicianDashboardScreenState extends ConsumerState<TechnicianDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _jobsData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiClient().get('/technicians/jobs');
      if (res.data['success'] == true) {
        setState(() {
          _jobsData = res.data['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = res.data['message'] ?? 'Failed to load technician jobs';
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

  Future<void> _callCustomer(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openMap(String address) async {
    final query = Uri.encodeComponent(address);
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${authState.userName}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Field Technician Workspace',
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_outlined),
            tooltip: 'Scan Equipment QR',
            onPressed: () => context.push('/assets/scan'),
          ),
          IconButton(
            icon: const Icon(Icons.sync_outlined),
            tooltip: 'Offline Sync Queue',
            onPressed: () => context.push('/sync'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingState(message: 'Loading your assigned jobs...')
          : _errorMessage != null
              ? ErrorState(message: _errorMessage!, onRetry: _fetchJobs)
              : RefreshIndicator(
                  onRefresh: _fetchJobs,
                  child: Column(
                    children: [
                      // Header Stats Summary
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildJobStat(
                                "Today's Jobs",
                                '${_jobsData?['counts']?['today'] ?? 0}',
                                AppTheme.primaryColor,
                                Icons.calendar_today_outlined,
                                isDark,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: _buildJobStat(
                                'Pending',
                                '${_jobsData?['counts']?['pending'] ?? 0}',
                                AppTheme.warning,
                                Icons.hourglass_top_outlined,
                                isDark,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: _buildJobStat(
                                'Completed',
                                '${_jobsData?['counts']?['completed'] ?? 0}',
                                AppTheme.success,
                                Icons.check_circle_outline,
                                isDark,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Tabs
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                              width: 1,
                            ),
                          ),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          labelColor: theme.primaryColor,
                          unselectedLabelColor: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          indicatorColor: theme.primaryColor,
                          indicatorWeight: 2.5,
                          tabs: const [
                            Tab(text: "Today's"),
                            Tab(text: 'Upcoming'),
                            Tab(text: 'Pending'),
                            Tab(text: 'Completed'),
                          ],
                        ),
                      ),

                      // Tab Views
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildJobList(_jobsData?['today_jobs'] ?? [], isToday: true),
                            _buildJobList(_jobsData?['upcoming_jobs'] ?? []),
                            _buildJobList(_jobsData?['pending_jobs'] ?? []),
                            _buildJobList(_jobsData?['completed_jobs'] ?? [], isCompleted: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildJobStat(String label, String value, Color color, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
        boxShadow: AppShadows.subtle(isDark: isDark),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobList(List<dynamic> jobs, {bool isToday = false, bool isCompleted = false}) {
    if (jobs.isEmpty) {
      return const EmptyState(
        title: 'No service visits scheduled',
        message: 'You have no assigned jobs in this category right now.',
        icon: Icons.checklist_rtl_outlined,
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: jobs.length,
      itemBuilder: (context, idx) {
        final job = jobs[idx];
        final customer = job['customer'] ?? {};
        final asset = job['asset'] ?? {};
        final visit = job['service_visit'];
        final status = job['status'] ?? 'scheduled';
        final visitId = visit?['id'] ?? job['id'];

        return AppCard(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Status & Time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StatusBadge(status: status),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Text(
                      '${job['scheduled_date'] ?? ''} • ${job['scheduled_time_start'] ?? '10:00'}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Customer Info
              Text(
                customer['name'] ?? 'Client Name',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (customer['company_name'] != null) ...[
                Text(
                  customer['company_name'],
                  style: theme.textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 14, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${customer['address_line_1'] ?? ''}, ${customer['city'] ?? ''}',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Asset Specs
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withAlpha(isDark ? 40 : 20),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Icon(Icons.precision_manufacturing_outlined, size: 20, color: theme.primaryColor),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${asset['asset_code'] ?? 'Asset'} • ${asset['asset_type'] ?? 'Equipment'}',
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'SN: ${asset['serial_number'] ?? 'N/A'} • Location: ${asset['location'] ?? 'On Site'}',
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Action Buttons
              Row(
                children: [
                  if (customer['phone'] != null)
                    OutlinedButton.icon(
                      onPressed: () => _callCustomer(customer['phone']),
                      icon: const Icon(Icons.call_outlined, size: 15),
                      label: const Text('Call'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: const Size(60, 36),
                      ),
                    ),
                  const SizedBox(width: 6),
                  if (customer['address_line_1'] != null)
                    OutlinedButton.icon(
                      onPressed: () => _openMap('${customer['address_line_1']}, ${customer['city']}'),
                      icon: const Icon(Icons.directions_outlined, size: 15),
                      label: const Text('Map'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: const Size(60, 36),
                      ),
                    ),
                  const Spacer(),
                  if (!isCompleted)
                    AppButton(
                      label: status == 'in_progress' ? 'Resume' : 'Start Visit',
                      icon: Icons.play_arrow,
                      onPressed: () => context.push('/visits/$visitId'),
                      height: 38,
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () => context.push('/visits/$visitId'),
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text('View Report'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

