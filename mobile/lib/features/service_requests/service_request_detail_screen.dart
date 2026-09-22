import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/status_badge.dart';

class ServiceRequestDetailScreen extends StatefulWidget {
  final int requestId;

  const ServiceRequestDetailScreen({
    super.key,
    required this.requestId,
  });

  @override
  State<ServiceRequestDetailScreen> createState() => _ServiceRequestDetailScreenState();
}

class _ServiceRequestDetailScreenState extends State<ServiceRequestDetailScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _request;

  List<dynamic> _technicians = [];
  bool _isLoadingTechs = false;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await _api.get('/service-requests/${widget.requestId}');
      if (res.statusCode == 200 && res.data['data'] != null) {
        setState(() {
          _request = res.data['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load service request';
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

  Future<void> _fetchTechnicians() async {
    setState(() => _isLoadingTechs = true);
    try {
      final res = await _api.get('/technicians');
      if (res.statusCode == 200 && res.data['data'] != null) {
        setState(() {
          _technicians = res.data['data'];
          _isLoadingTechs = false;
        });
      }
    } catch (_) {
      setState(() => _isLoadingTechs = false);
    }
  }

  Future<void> _showAssignDialog() async {
    await _fetchTechnicians();
    if (!mounted) return;

    int? selectedTechId = _request?['assigned_technician_id'];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Assign Technician'),
          content: _isLoadingTechs
              ? const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()))
              : DropdownButtonFormField<int>(
                  value: selectedTechId,
                  decoration: const InputDecoration(labelText: 'Select Field Technician'),
                  items: _technicians.map<DropdownMenuItem<int>>((t) {
                    return DropdownMenuItem<int>(
                      value: t['id'],
                      child: Text('${t['name']} (${t['phone'] ?? 'No phone'})'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setDialogState(() => selectedTechId = val);
                  },
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedTechId == null) return;
                Navigator.pop(ctx);
                try {
                  final res = await _api.post(
                    '/service-requests/${widget.requestId}/assign',
                    data: {'technician_id': selectedTechId},
                  );
                  if (res.statusCode == 200) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Technician assigned successfully!')),
                    );
                    _fetchDetail();
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to assign: $e'), backgroundColor: AppTheme.error),
                  );
                }
              },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showUpdateStatusDialog() async {
    String selectedStatus = _request?['status'] ?? 'new';
    final resolutionCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Ticket Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: 'new', child: Text('New / Unassigned')),
                DropdownMenuItem(value: 'assigned', child: Text('Assigned to Tech')),
                DropdownMenuItem(value: 'in_progress', child: Text('In Progress / Troubleshooting')),
                DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                DropdownMenuItem(value: 'closed', child: Text('Closed')),
              ],
              onChanged: (val) {
                if (val != null) selectedStatus = val;
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: resolutionCtrl,
              decoration: const InputDecoration(
                labelText: 'Resolution / Progress Notes',
                hintText: 'Work done or status remarks...',
              ),
              maxLines: 2,
            ),
          ],
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
                final res = await _api.put(
                  '/service-requests/${widget.requestId}/status',
                  data: {
                    'status': selectedStatus,
                    'resolution_notes': resolutionCtrl.text.trim(),
                  },
                );
                if (res.statusCode == 200) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Status updated successfully!')),
                  );
                  _fetchDetail();
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Update failed: $e'), backgroundColor: AppTheme.error),
                );
              }
            },
            child: const Text('Update Status'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ticket Details')),
        body: const LoadingState(message: 'Loading complaint details...'),
      );
    }

    if (_error != null || _request == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ticket Details')),
        body: ErrorState(message: _error ?? 'Ticket not found', onRetry: _fetchDetail),
      );
    }

    final req = _request!;
    final reqNumber = req['request_number'] ?? 'SR-${widget.requestId}';
    final title = req['title'] ?? 'Complaint';
    final description = req['description'] ?? 'No details';
    final status = req['status'] ?? 'new';
    final priority = req['priority'] ?? 'normal';
    final customer = req['customer'] ?? {};
    final asset = req['asset'] ?? {};
    final contract = req['contract'];
    final tech = req['assigned_technician'];
    final isCovered = req['is_covered_under_amc'] == true;
    final slaDueAt = req['sla_due_at'];

    String slaFormatted = 'Standard SLA';
    bool isOverdue = false;
    if (slaDueAt != null) {
      final due = DateTime.tryParse(slaDueAt);
      if (due != null) {
        isOverdue = due.isBefore(DateTime.now()) && status != 'resolved' && status != 'closed';
        slaFormatted = DateFormat('dd MMM yyyy, hh:mm a').format(due);
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final secondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: Text(reqNumber),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: StatusBadge(status: status)),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Assign Tech',
                  icon: Icons.person_add_outlined,
                  type: AppButtonType.outline,
                  onPressed: _showAssignDialog,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  label: 'Update Status',
                  icon: Icons.edit_note,
                  onPressed: _showUpdateStatusDialog,
                ),
              ),
            ],
          ),
        ),
      ),
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
                    Text(
                      '${req['issue_type'] ?? 'Issue'} • ${priority.toUpperCase()}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: secondary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isCovered ? AppTheme.success.withAlpha(20) : (isDark ? Colors.white12 : Colors.grey.withAlpha(20)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isCovered ? 'AMC CONTRACT ACTIVE' : 'OUT OF CONTRACT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isCovered ? AppTheme.success : secondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: primary),
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, height: 1.4, color: primary),
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 18, color: isOverdue ? AppTheme.error : secondary),
                    const SizedBox(width: 8),
                    Text(
                      'SLA Due: $slaFormatted',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                        color: isOverdue ? AppTheme.error : secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Equipment & Customer Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                _buildRow('Customer', customer['name'] ?? 'N/A'),
                _buildRow('Phone', customer['phone'] ?? 'N/A'),
                _buildRow('Equipment', asset['name'] ?? 'N/A'),
                _buildRow('Serial No.', asset['serial_number'] ?? 'N/A'),
                if (contract != null)
                  _buildRow('Contract No.', contract['contract_number'] ?? 'N/A'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Assigned Technician', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                if (tech != null) ...[
                  _buildRow('Technician', tech['name'] ?? 'Assigned'),
                  _buildRow('Email', tech['email'] ?? 'N/A'),
                  _buildRow('Phone', tech['phone'] ?? 'N/A'),
                ] else ...[
                  const Text(
                    'No technician currently assigned to this ticket.',
                    style: TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
