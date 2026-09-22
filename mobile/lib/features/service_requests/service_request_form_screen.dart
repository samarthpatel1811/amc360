import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/loading_state.dart';

class ServiceRequestFormScreen extends StatefulWidget {
  final int? preselectedAssetId;

  const ServiceRequestFormScreen({
    super.key,
    this.preselectedAssetId,
  });

  @override
  State<ServiceRequestFormScreen> createState() => _ServiceRequestFormScreenState();
}

class _ServiceRequestFormScreenState extends State<ServiceRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiClient _api = ApiClient();

  bool _isLoadingAssets = true;
  bool _isSubmitting = false;
  List<dynamic> _assets = [];

  int? _selectedAssetId;
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  String _issueType = 'Breakdown / Not Working';
  String _priority = 'normal';
  DateTime? _preferredDate;

  final List<String> _issueTypes = [
    'Breakdown / Not Working',
    'Abnormal Noise / Vibration',
    'Cooling / Heating Issue',
    'Water / Oil Leakage',
    'Electrical Tripping',
    'Routine Check Required',
    'Other Issue',
  ];

  @override
  void initState() {
    super.initState();
    _selectedAssetId = widget.preselectedAssetId;
    _fetchAssets();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchAssets() async {
    try {
      final res = await _api.get('/assets?per_page=100');
      if (res.statusCode == 200 && res.data['data'] != null) {
        setState(() {
          _assets = res.data['data'];
          _isLoadingAssets = false;
          if (_selectedAssetId == null && _assets.isNotEmpty) {
            _selectedAssetId = _assets.first['id'];
          }
        });
      }
    } catch (e) {
      setState(() => _isLoadingAssets = false);
    }
  }

  Future<void> _pickPreferredDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _preferredDate = picked);
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate() || _selectedAssetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields and select an asset.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final payload = {
        'asset_id': _selectedAssetId,
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'issue_type': _issueType,
        'priority': _priority,
        'preferred_date': _preferredDate != null ? DateFormat('yyyy-MM-dd').format(_preferredDate!) : null,
      };

      final res = await _api.post('/service-requests', data: payload);
      if (res.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Complaint ticket submitted successfully! SLA countdown started.')),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Service Complaint'),
      ),
      body: _isLoadingAssets
          ? const LoadingState(message: 'Loading assets catalog...')
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Asset Selection *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<int>(
                          value: _selectedAssetId,
                          decoration: const InputDecoration(
                            labelText: 'Select Equipment / Asset',
                          ),
                          items: _assets.map<DropdownMenuItem<int>>((a) {
                            return DropdownMenuItem<int>(
                              value: a['id'],
                              child: Text(
                                '${a['name']} (${a['serial_number'] ?? 'No S/N'})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _selectedAssetId = val);
                          },
                          validator: (val) => val == null ? 'Asset is required' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Issue & Priority Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _issueType,
                          decoration: const InputDecoration(labelText: 'Issue Category *'),
                          items: _issueTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _issueType = val);
                          },
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Short Summary / Title *',
                          hint: 'e.g. AC cooling not functioning in Server Room',
                          controller: _titleCtrl,
                          validator: (val) => (val == null || val.trim().isEmpty) ? 'Title is required' : null,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Detailed Description *',
                          hint: 'Provide exact symptoms, error codes, previous occurrences...',
                          controller: _descCtrl,
                          maxLines: 4,
                          validator: (val) => (val == null || val.trim().isEmpty) ? 'Description is required' : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _priority,
                          decoration: const InputDecoration(labelText: 'Severity / Priority'),
                          items: const [
                            DropdownMenuItem(value: 'low', child: Text('Low (Routine enquiry / non-blocking)')),
                            DropdownMenuItem(value: 'normal', child: Text('Normal (24-hour response SLA)')),
                            DropdownMenuItem(value: 'high', child: Text('High (8-hour urgent response SLA)')),
                            DropdownMenuItem(value: 'urgent', child: Text('Urgent (4-hour emergency SLA)')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _priority = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Preferred Visit Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 8),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            _preferredDate == null
                                ? 'As soon as possible (Standard SLA)'
                                : DateFormat('dd MMMM yyyy').format(_preferredDate!),
                            style: TextStyle(
                              color: _preferredDate == null
                                  ? (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)
                                  : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                              fontWeight: _preferredDate != null ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          trailing: const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                          onTap: _pickPreferredDate,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'Submit Complaint Ticket',
                    icon: Icons.send,
                    isLoading: _isSubmitting,
                    onPressed: _submitRequest,
                  ),
                ],
              ),
            ),
    );
  }
}
