import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/indian_location_picker.dart';

class CustomerFormScreen extends StatefulWidget {
  final int? customerId;
  const CustomerFormScreen({super.key, this.customerId});

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _alternatePhoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _gstController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController(text: 'Ahmedabad');
  final _stateController = TextEditingController(text: 'Gujarat');
  final _postalCodeController = TextEditingController(text: '380015');
  final _notesController = TextEditingController();

  final String _customerType = 'commercial';
  bool _createUserAccount = true;
  final _userPasswordController = TextEditingController(text: 'Customer@123');
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final res = await ApiClient().post('/customers', data: {
        'name': _nameController.text.trim(),
        'company_name': _companyNameController.text.trim(),
        'customer_type': _customerType,
        'phone': _phoneController.text.trim(),
        'alternate_phone': _alternatePhoneController.text.trim(),
        'email': _emailController.text.trim(),
        'gst_number': _gstController.text.trim(),
        'address_line_1': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'postal_code': _postalCodeController.text.trim(),
        'notes': _notesController.text.trim(),
        'create_user_account': _createUserAccount,
        'user_password': _userPasswordController.text,
      });

      if (res.data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Customer profile created successfully.')),
          );
          context.pop(true);
        }
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
    _nameController.dispose();
    _companyNameController.dispose();
    _phoneController.dispose();
    _alternatePhoneController.dispose();
    _emailController.dispose();
    _gstController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _notesController.dispose();
    _userPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Customer')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppTextField(
              label: 'Contact Person Name *',
              hint: 'e.g. Vikram Singhania',
              controller: _nameController,
              validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Company / Commercial Entity Name',
              hint: 'e.g. Regency Grand Luxury Hotel',
              controller: _companyNameController,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Primary Phone *',
                    hint: '+91 98250 11223',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Phone is required' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppTextField(
                    label: 'Alternate Phone',
                    hint: '+91 98250 99887',
                    controller: _alternatePhoneController,
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Email Address',
              hint: 'manager@regency.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'GST / Tax Registration Number',
              hint: '24ABCDE1234F1Z5',
              controller: _gstController,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Premises Address *',
              hint: 'Plot / Building, Street, Area',
              controller: _addressController,
              validator: (v) => v == null || v.trim().isEmpty ? 'Address is required' : null,
            ),
            const SizedBox(height: 12),
            StateCitySelector(
              initialValueState: _stateController.text.isNotEmpty ? _stateController.text : 'Gujarat',
              initialValueCity: _cityController.text.isNotEmpty ? _cityController.text : 'Ahmedabad',
              isRequired: true,
              onChanged: (state, city) {
                setState(() {
                  _stateController.text = state;
                  _cityController.text = city;
                });
              },
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Postal Code',
              controller: _postalCodeController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Special Notes / Site Access Directions',
              hint: 'e.g. Service lift available at Gate 2',
              controller: _notesController,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            const Divider(),
            SwitchListTile(
              title: const Text('Create Customer Portal Login Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Enables client to view assets, raise tickets, and see invoices', style: TextStyle(fontSize: 12)),
              value: _createUserAccount,
              onChanged: (v) => setState(() => _createUserAccount = v),
            ),
            if (_createUserAccount) ...[
              const SizedBox(height: 8),
              AppTextField(
                label: 'Initial Password for Customer',
                controller: _userPasswordController,
              ),
            ],
            const SizedBox(height: 24),
            AppButton(
              label: 'Save Customer Profile',
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
