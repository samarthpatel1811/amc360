import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../app/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';

class ContractFormScreen extends StatefulWidget {
  final Map<String, dynamic>? prefillContract;
  final int? prefillCustomerId;

  const ContractFormScreen({super.key, this.prefillContract, this.prefillCustomerId});

  @override
  State<ContractFormScreen> createState() => _ContractFormScreenState();
}

class _ContractFormScreenState extends State<ContractFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController(text: 'Comprehensive HVAC Annual Contract');
  final _priceController = TextEditingController(text: '50000');
  final _exclusionsController = TextEditingController(text: 'Compressor physical damage and gas leak repairs excluded.');
  final _notesController = TextEditingController();

  int? _selectedCustomerId;
  List<int> _selectedAssetIds = [];
  List<dynamic> _customers = [];
  List<dynamic> _availableAssets = [];

  DateTime _startDate = DateTime.now();
  DateTime? _customEndDate;
  String _durationType = '12_months';
  String _frequency = 'quarterly';
  String _firstVisitRule = 'start_date';
  String _visitCountType = 'automatic';
  final _fixedVisitCountController = TextEditingController(text: '4');

  // Preview state
  String? _calculatedEndDate;
  List<dynamic> _previewDates = [];
  bool _isLoading = false;

  final _df = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _selectedCustomerId = widget.prefillCustomerId;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final custRes = await ApiClient().get('/customers');
      setState(() {
        _customers = custRes.data['data']['data'] ?? [];
        if (widget.prefillCustomerId != null) {
          _selectedCustomerId = widget.prefillCustomerId;
        } else if (_selectedCustomerId == null && _customers.isNotEmpty) {
          _selectedCustomerId = _customers.first['id'];
        }
        if (_selectedCustomerId != null) {
          _loadCustomerAssets(_selectedCustomerId!);
        }
      });
      _previewContractDates();
    } catch (_) {}
  }

  Future<void> _loadCustomerAssets(int customerId) async {
    try {
      final res = await ApiClient().get('/customers/$customerId/assets');
      setState(() {
        _availableAssets = res.data['data'] ?? [];
        _selectedAssetIds = _availableAssets.map<int>((a) => a['id'] as int).toList();
      });
    } catch (_) {}
  }

  Future<void> _previewContractDates() async {
    try {
      final res = await ApiClient().post('/contracts/preview-dates', data: {
        'start_date': _df.format(_startDate),
        'duration_type': _durationType,
        'custom_end_date': _customEndDate != null ? _df.format(_customEndDate!) : null,
        'service_frequency': _frequency,
        'first_visit_rule': _firstVisitRule,
        'visit_count_type': _visitCountType,
        'included_visit_count': int.tryParse(_fixedVisitCountController.text),
      });

      if (res.data['success'] == true) {
        setState(() {
          _calculatedEndDate = res.data['data']['end_date'];
          _previewDates = res.data['data']['scheduled_dates'] ?? [];
        });
      }
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedCustomerId == null) return;

    setState(() => _isLoading = true);

    try {
      final payload = {
        'customer_id': _selectedCustomerId,
        'title': _titleController.text.trim(),
        'start_date': _df.format(_startDate),
        'duration_type': _durationType,
        'custom_end_date': _customEndDate != null ? _df.format(_customEndDate!) : null,
        'service_frequency': _frequency,
        'first_visit_rule': _firstVisitRule,
        'visit_count_type': _visitCountType,
        'included_visit_count': int.tryParse(_fixedVisitCountController.text),
        'total_price': double.parse(_priceController.text),
        'billing_type': 'fixed',
        'coverage_parts': 'included',
        'coverage_emergency_visits': 'included',
        'exclusions': _exclusionsController.text.trim(),
        'notes': _notesController.text.trim(),
      };

      if (_selectedAssetIds.isNotEmpty) {
        payload['asset_ids'] = _selectedAssetIds;
      }

      final res = await ApiClient().post('/contracts', data: payload);

      if (res.data['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AMC Contract created! Payment request sent to client.')),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _exclusionsController.dispose();
    _notesController.dispose();
    _fixedVisitCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Create AMC Contract')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Customer Selector
            const Text('Select Customer *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            DropdownButtonFormField<int>(
              value: _customers.any((c) => c['id'] == _selectedCustomerId) ? _selectedCustomerId : null,
              decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
              items: _customers.map<DropdownMenuItem<int>>((c) {
                return DropdownMenuItem<int>(
                  value: c['id'],
                  child: Text('${c['name']} (${c['company_name'] ?? c['customer_code']})', style: const TextStyle(fontSize: 13)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedCustomerId = val);
                  _loadCustomerAssets(val);
                }
              },
            ),
            const SizedBox(height: 14),

            // Covered Assets Multi-Selector
            if (_availableAssets.isNotEmpty) ...[
              const Text('Covered Assets in Contract (Multi-Select) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: _availableAssets.map((a) {
                    final isChecked = _selectedAssetIds.contains(a['id']);
                    return CheckboxListTile(
                      dense: true,
                      title: Text('${a['asset_code']} — ${a['brand']} ${a['model']}', style: const TextStyle(fontSize: 13)),
                      subtitle: Text('SN: ${a['serial_number']}', style: const TextStyle(fontSize: 11)),
                      value: isChecked,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedAssetIds.add(a['id']);
                          } else {
                            _selectedAssetIds.remove(a['id']);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),
            ],

            AppTextField(
              label: 'Contract Title *',
              controller: _titleController,
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),

            // Start Date Picker
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Start Date *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            setState(() => _startDate = picked);
                            _previewContractDates();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.borderColor),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: AppTheme.primaryColor),
                              const SizedBox(width: 8),
                              Text(_df.format(_startDate), style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Duration Preset *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _durationType,
                        decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                        items: const [
                          DropdownMenuItem(value: '1_month', child: Text('1 Month', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: '3_months', child: Text('3 Months', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: '6_months', child: Text('6 Months', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: '12_months', child: Text('12 Months (1 Yr)', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: '24_months', child: Text('24 Months (2 Yrs)', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'custom', child: Text('Custom Dates', style: TextStyle(fontSize: 13))),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _durationType = val);
                            _previewContractDates();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Service Frequency Selector
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Service Frequency *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _frequency,
                        decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                        items: const [
                          DropdownMenuItem(value: 'monthly', child: Text('Monthly', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'bimonthly', child: Text('Every 2 Months', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'quarterly', child: Text('Quarterly (Every 3 Mo)', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'four_monthly', child: Text('Every 4 Months', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'half_yearly', child: Text('Half-Yearly (Every 6 Mo)', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'yearly', child: Text('Yearly', style: TextStyle(fontSize: 13))),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _frequency = val);
                            _previewContractDates();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('First Visit Rule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _firstVisitRule,
                        decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                        items: const [
                          DropdownMenuItem(value: 'start_date', child: Text('On Start Date', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'after_interval', child: Text('After 1st Interval', style: TextStyle(fontSize: 13))),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _firstVisitRule = val);
                            _previewContractDates();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Live Calculated Schedule Preview Box
            AppCard(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, size: 16, color: AppTheme.primaryColor),
                      const SizedBox(width: 6),
                      const Text('Engine Schedule Calculation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryColor)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Contract Validity: ${_df.format(_startDate)} to ${_calculatedEndDate ?? '...'}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                  ),
                  Text(
                    'Generated Visits: ${_previewDates.length} preventive scheduled appointments',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: _previewDates.map((d) => Chip(
                      label: Text(d.toString(), style: const TextStyle(fontSize: 11)),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            AppTextField(
              label: 'Total Contract Price (₹) *',
              hint: '60000',
              controller: _priceController,
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.trim().isEmpty ? 'Price is required' : null,
            ),
            const SizedBox(height: 14),

            AppTextField(
              label: 'Specific Exclusions',
              controller: _exclusionsController,
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            AppButton(
              label: 'Generate Contract & Schedules',
              isLoading: _isLoading,
              onPressed: _submit,
              height: 50,
            ),
          ],
        ),
      ),
    );
  }
}
