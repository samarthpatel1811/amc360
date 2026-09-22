import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../app/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/empty_state.dart';

class AssetDetailScreen extends StatefulWidget {
  final int assetId;

  const AssetDetailScreen({super.key, required this.assetId});

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _asset;
  Map<String, dynamic>? _activeAmc;
  List<dynamic> _pastAmcs = [];
  List<dynamic> _visits = [];
  List<dynamic> _complaints = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiClient().get('/assets/${widget.assetId}/history');
      if (res.data['success'] == true) {
        final data = res.data['data'];
        setState(() {
          _asset = data['asset'];
          _activeAmc = data['active_amc'];
          _pastAmcs = data['past_amcs'] ?? [];
          _visits = data['visits_history'] ?? [];
          _complaints = data['complaints_history'] ?? [];
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

  void _showQrDialog() {
    final token = _asset?['qr_token'] ?? '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Asset QR: ${_asset?['asset_code']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: QrImageView(
                data: token,
                version: QrVersions.auto,
                size: 200,
              ),
            ),
            const SizedBox(height: 12),
            Builder(
              builder: (c) {
                final isDark = Theme.of(c).brightness == Brightness.dark;
                return Text(
                  'Secure Asset Token:\n$token',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cust = _asset?['customer'] ?? {};
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_asset?['asset_code'] ?? 'Equipment Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_2),
            tooltip: 'View Asset QR',
            onPressed: _asset != null ? _showQrDialog : null,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingState(message: 'Loading machine history...')
          : _errorMessage != null
              ? ErrorState(message: _errorMessage!, onRetry: _fetchHistory)
              : Column(
                  children: [
                    // Asset Info Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _asset?['asset_code'] ?? '',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                                ),
                                StatusBadge(status: _asset?['status'] ?? 'active'),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${_asset?['brand'] ?? ''} ${_asset?['model'] ?? ''} — ${_asset?['asset_type'] ?? ''}',
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text('Serial Number: ${_asset?['serial_number'] ?? 'N/A'}', style: TextStyle(fontSize: 13, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
                            Text('Location: ${_asset?['location'] ?? 'On Site'}', style: TextStyle(fontSize: 13, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
                            Text('Customer: ${cust['name'] ?? ''} (${cust['company_name'] ?? ''})', style: TextStyle(fontSize: 13, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
                          ],
                        ),
                      ),
                    ),

                    // Tabs
                    TabBar(
                      controller: _tabController,
                      labelColor: AppTheme.primaryColor,
                      unselectedLabelColor: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      indicatorColor: AppTheme.primaryColor,
                      tabs: const [
                        Tab(text: 'Overview'),
                        Tab(text: 'AMC Cover'),
                        Tab(text: 'Visits'),
                        Tab(text: 'Tickets'),
                      ],
                    ),

                    // Tab views
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverview(),
                          _buildAmcCover(),
                          _buildVisits(),
                          _buildTickets(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildOverview() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoRow('Brand', _asset?['brand'] ?? ''),
        _buildInfoRow('Model', _asset?['model'] ?? 'N/A'),
        _buildInfoRow('Equipment Type', _asset?['asset_type'] ?? ''),
        _buildInfoRow('Capacity / Spec', _asset?['capacity'] ?? 'N/A'),
        _buildInfoRow('Serial Number', _asset?['serial_number'] ?? ''),
        _buildInfoRow('Installation Date', _asset?['installation_date'] ?? 'N/A'),
        _buildInfoRow('Purchase Date', _asset?['purchase_date'] ?? 'N/A'),
        _buildInfoRow('Warranty Period', '${_asset?['warranty_start'] ?? 'N/A'} to ${_asset?['warranty_end'] ?? 'N/A'}'),
        _buildInfoRow('Site Location', _asset?['location'] ?? 'On Site'),
        _buildInfoRow('Notes', _asset?['notes'] ?? 'No special notes recorded.'),
      ],
    );
  }

  Widget _buildAmcCover() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_activeAmc != null) ...[
          const Text('Active AMC Agreement', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          AppCard(
            onTap: () => context.push('/contracts/${_activeAmc!['id']}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_activeAmc!['contract_number'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                    const StatusBadge(status: 'active'),
                  ],
                ),
                const SizedBox(height: 4),
                Text(_activeAmc!['title'] ?? 'AMC Contract', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                Builder(
                  builder: (c) {
                    final isDark = Theme.of(c).brightness == Brightness.dark;
                    final sec = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Coverage: ${_activeAmc!['start_date']} to ${_activeAmc!['end_date']}', style: TextStyle(fontSize: 12, color: sec)),
                        Text('Frequency: ${_activeAmc!['service_frequency']}', style: TextStyle(fontSize: 12, color: sec)),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ] else ...[
          const EmptyState(
            title: 'No active AMC',
            message: 'This machine currently does not have active AMC coverage.',
            icon: Icons.shield_outlined,
          ),
        ],
        if (_pastAmcs.isNotEmpty) ...[
          const Text('Historical AMC Agreements', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._pastAmcs.map((c) => AppCard(
                onTap: () => context.push('/contracts/${c['id']}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c['contract_number'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Builder(
                      builder: (ctx) {
                        final isDark = Theme.of(ctx).brightness == Brightness.dark;
                        return Text('Validity: ${c['start_date']} to ${c['end_date']} • Status: ${c['status']}', style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary));
                      },
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildVisits() {
    if (_visits.isEmpty) {
      return const EmptyState(
        title: 'No maintenance visits',
        message: 'No service visits completed for this asset.',
        icon: Icons.history,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _visits.length,
      itemBuilder: (ctx, idx) {
        final v = _visits[idx];
        return AppCard(
          onTap: () => context.push('/service-visits/${v['id']}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(v['visit_number'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                  StatusBadge(status: v['status'] ?? 'completed'),
                ],
              ),
              const SizedBox(height: 4),
              Text('Report #: ${v['report_number'] ?? 'N/A'}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              Builder(
                builder: (ctx) {
                  final isDark = Theme.of(ctx).brightness == Brightness.dark;
                  return Text('Completed on: ${v['completed_at'] ?? ''} by ${v['technician']?['name'] ?? 'Technician'}',
                      style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary));
                },
              ),
              if (v['work_performed'] != null)
                Text(v['work_performed'], style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTickets() {
    if (_complaints.isEmpty) {
      return const EmptyState(
        title: 'No complaints / tickets',
        message: 'No breakdown tickets recorded for this machine.',
        icon: Icons.check_circle_outline,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _complaints.length,
      itemBuilder: (ctx, idx) {
        final req = _complaints[idx];
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(req['request_number'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                  StatusBadge(status: req['status'] ?? 'new'),
                ],
              ),
              const SizedBox(height: 4),
              Text(req['title'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              Builder(
                builder: (ctx) {
                  final isDark = Theme.of(ctx).brightness == Brightness.dark;
                  return Text('Issue: ${req['issue_type'] ?? ''} • Priority: ${req['priority'] ?? ''}',
                      style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary));
                },
              ),
              Text(req['description'] ?? '', style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
