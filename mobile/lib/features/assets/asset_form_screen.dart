import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';

class AssetFormScreen extends StatefulWidget {
  final int? assetId;
  const AssetFormScreen({super.key, this.assetId});

  @override
  State<AssetFormScreen> createState() => _AssetFormScreenState();
}

class _AssetFormScreenState extends State<AssetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _assetCodeController = TextEditingController(text: 'AC-');
  final _assetTypeController = TextEditingController(text: 'Split AC 2.0 TR');
  final _brandController = TextEditingController(text: 'Daikin');
  final _modelController = TextEditingController(text: 'FTKF50');
  final _serialNumberController = TextEditingController();
  final _capacityController = TextEditingController(text: '2.0 Ton');
  final _locationController = TextEditingController(text: 'Server Room');
  final _notesController = TextEditingController();

  int? _selectedCustomerId;
  int? _selectedCategoryId;
  List<dynamic> _customers = [];
  List<dynamic> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDependencies();
  }

  Future<void> _loadDependencies() async {
    try {
      final custRes = await ApiClient().get('/customers');
      final catRes = await ApiClient().get('/catalogs/asset-categories');

      setState(() {
        _customers = custRes.data['data']['data'] ?? [];
        _categories = catRes.data['data'] ?? [];
        if (_customers.isNotEmpty) {
          _selectedCustomerId = _customers.first['id'];
        }
        if (_categories.isNotEmpty) {
          _selectedCategoryId = _categories.first['id'];
        }
      });
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedCustomerId == null) return;

    setState(() => _isLoading = true);

    try {
      final res = await ApiClient().post('/assets', data: {
        'customer_id': _selectedCustomerId,
        'category_id': _selectedCategoryId,
        'asset_code': _assetCodeController.text.trim(),
        'asset_type': _assetTypeController.text.trim(),
        'brand': _brandController.text.trim(),
        'model': _modelController.text.trim(),
        'serial_number': _serialNumberController.text.trim(),
        'capacity': _capacityController.text.trim(),
        'location': _locationController.text.trim(),
        'status': 'active',
        'notes': _notesController.text.trim(),
      });

      if (res.data['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Equipment added successfully with QR token.')),
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
    _assetCodeController.dispose();
    _assetTypeController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _serialNumberController.dispose();
    _capacityController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Equipment / Asset')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Customer Selector
            const Text('Belongs to Customer *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            DropdownButtonFormField<int>(
              value: _selectedCustomerId,
              decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
              items: _customers.map<DropdownMenuItem<int>>((c) {
                return DropdownMenuItem<int>(
                  value: c['id'],
                  child: Text('${c['name']} (${c['customer_code']})', style: const TextStyle(fontSize: 13)),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedCustomerId = val),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Asset Code *',
                    hint: 'e.g. AC-004',
                    controller: _assetCodeController,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppTextField(
                    label: 'Serial Number *',
                    hint: 'SN: DAIK-99201',
                    controller: _serialNumberController,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            AppTextField(
              label: 'Equipment Description / Type *',
              hint: 'e.g. Inverter Split AC 2.0 TR',
              controller: _assetTypeController,
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Brand / Make *',
                    hint: 'e.g. Daikin',
                    controller: _brandController,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppTextField(
                    label: 'Model Number',
                    hint: 'e.g. FTKF50TV16U',
                    controller: _modelController,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Capacity / Rating',
                    hint: 'e.g. 2.0 Ton / 125 kVA',
                    controller: _capacityController,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppTextField(
                    label: 'Installation Location',
                    hint: 'e.g. 2nd Floor Server Room',
                    controller: _locationController,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            AppTextField(
              label: 'Equipment Technical Notes',
              hint: 'e.g. Filter size, refrigerant type, piping length',
              controller: _notesController,
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            AppButton(
              label: 'Save Equipment Record',
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
