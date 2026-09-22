import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/empty_state.dart';

class ScheduleCalendarScreen extends StatefulWidget {
  const ScheduleCalendarScreen({super.key});

  @override
  State<ScheduleCalendarScreen> createState() => _ScheduleCalendarScreenState();
}

class _ScheduleCalendarScreenState extends State<ScheduleCalendarScreen> {
  String _filter = 'today';
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _schedules = [];
  List<dynamic> _technicians = [];

  final _df = DateFormat('yyyy-MM-dd');

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

  String _formatTime(dynamic rawTime) {
    if (rawTime == null) return '10:00 AM';
    final str = rawTime.toString();
    if (str.length >= 5) {
      return str.substring(0, 5);
    }
    return str;
  }

  @override
  void initState() {
    super.initState();
    _fetchSchedules();
    _loadTechnicians();
  }

  Future<void> _loadTechnicians() async {
    try {
      final res = await ApiClient().get('/technicians');
      if (res.data['success'] == true) {
        setState(() => _technicians = res.data['data'] ?? []);
      }
    } catch (_) {}
  }

  Future<void> _fetchSchedules() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final query = <String, dynamic>{'quick_filter': _filter};
      final res = await ApiClient().get('/schedules', queryParameters: query);
      if (res.data['success'] == true) {
        setState(() {
          _schedules = res.data['data']['data'] ?? [];
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

  void _showRescheduleDialog(Map<String, dynamic> schedule) {
    DateTime newDate = DateTime.now().add(const Duration(days: 1));
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Reschedule Visit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Date: ${schedule['scheduled_date']}'),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: newDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) {
                    setDialogState(() => newDate = picked);
                  }
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text('New Date: ${_df.format(newDate)}'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Reschedule Reason *', hintText: 'e.g. Customer site closed'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (reasonCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await ApiClient().post('/schedules/${schedule['id']}/reschedule', data: {
                    'new_date': _df.format(newDate),
                    'reschedule_reason': reasonCtrl.text.trim(),
                  });
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Visit rescheduled.')));
                  _fetchSchedules();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignDialog(Map<String, dynamic> schedule) {
    int? selectedTechId = schedule['technician_id'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Assign Technician'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: selectedTechId,
                decoration: const InputDecoration(labelText: 'Choose Technician'),
                items: _technicians.map<DropdownMenuItem<int>>((t) {
                  return DropdownMenuItem<int>(
                    value: t['id'],
                    child: Text('${t['name']} (${t['availability_status']})', style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) => setDialogState(() => selectedTechId = val),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: selectedTechId == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      try {
                        await ApiClient().post('/schedules/${schedule['id']}/assign', data: {
                          'technician_id': selectedTechId,
                        });
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Technician assigned.')));
                        _fetchSchedules();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Service Schedule Calendar')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTabChip("Today's Visits", 'today'),
                  const SizedBox(width: 8),
                  _buildTabChip('Upcoming', 'upcoming'),
                  const SizedBox(width: 8),
                  _buildTabChip('Overdue', 'overdue'),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const LoadingState(message: 'Loading schedules...')
                : _errorMessage != null
                    ? ErrorState(message: _errorMessage!, onRetry: _fetchSchedules)
                    : _schedules.isEmpty
                        ? const EmptyState(
                            title: 'No visits in this view',
                            message: 'All scheduled preventive and breakdown visits are clear.',
                            icon: Icons.event_available,
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchSchedules,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                              itemCount: _schedules.length,
                              itemBuilder: (ctx, idx) {
                                final s = _schedules[idx];
                                final cust = s['customer'] ?? {};
                                final asset = s['asset'] ?? {};
                                final tech = s['technician'];
                                final status = s['status'] ?? 'scheduled';

                                return AppCard(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          StatusBadge(status: status),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '${_formatDate(s['scheduled_date'])} • ${_formatTime(s['scheduled_time_start'])}',
                                              textAlign: TextAlign.end,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        cust['name'] ?? '',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                        ),
                                      ),
                                      if (cust['company_name'] != null)
                                        Text(
                                          cust['company_name'],
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                          ),
                                        ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Asset: ${asset['asset_code'] ?? 'Equipment'} — ${asset['brand'] ?? ''} ${asset['model'] ?? ''}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                        ),
                                      ),
                                      Text(
                                        'Technician: ${tech?['name'] ?? 'Unassigned'}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: tech != null ? AppTheme.primaryColor : Colors.orange,
                                        ),
                                      ),
                                      if (s['rescheduled_from_date'] != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Rescheduled from: ${_formatDate(s['rescheduled_from_date'])} (${s['reschedule_reason'] ?? ''})',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 11, color: Colors.orange),
                                        ),
                                      ],
                                      const Divider(height: 16),
                                      Row(
                                        children: [
                                          if (status != 'completed') ...[
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () => _showAssignDialog(s),
                                                icon: const Icon(Icons.person_add, size: 15),
                                                label: Text(
                                                  tech == null ? 'Assign' : 'Reassign',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () => _showRescheduleDialog(s),
                                                icon: const Icon(Icons.edit_calendar, size: 15),
                                                label: const Text(
                                                  'Reschedule',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          ] else ...[
                                            const Spacer(),
                                            const Text('Service Completed', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                                          ],
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

  Widget _buildTabChip(String label, String value) {
    final isSelected = _filter == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
          fontSize: 13,
        ),
      ),
      selected: isSelected,
      selectedColor: AppTheme.primaryColor,
      backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
      side: BorderSide(
        color: isSelected ? AppTheme.primaryColor : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
      showCheckmark: false,
      onSelected: (_) {
        setState(() => _filter = value);
        _fetchSchedules();
      },
    );
  }
}
