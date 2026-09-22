import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/configuration/app_config.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/theme_provider.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/indian_location_picker.dart';
import '../../core/widgets/loading_state.dart';
import '../auth/auth_provider.dart';

class CompanySettingsScreen extends ConsumerStatefulWidget {
  const CompanySettingsScreen({super.key});

  @override
  ConsumerState<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends ConsumerState<CompanySettingsScreen> {
  final ApiClient _api = ApiClient();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  Map<String, dynamic>? _company;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _taxNumberCtrl = TextEditingController();
  final TextEditingController _taxRateCtrl = TextEditingController();
  final TextEditingController _currencyCtrl = TextEditingController();

  String? _selectedState = 'Gujarat';
  String? _selectedCity = 'Ahmedabad';

  @override
  void initState() {
    super.initState();
    _fetchCompany();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _taxNumberCtrl.dispose();
    _taxRateCtrl.dispose();
    _currencyCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchCompany() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await _api.get('/company');
      if (res.statusCode == 200 && res.data['data'] != null) {
        final data = res.data['data'] as Map<String, dynamic>;
        setState(() {
          _company = data;
          _nameCtrl.text = data['name'] ?? '';
          _phoneCtrl.text = data['phone'] ?? '';
          _emailCtrl.text = data['email'] ?? '';
          _addressCtrl.text = data['address_line_1'] ?? '';
          _selectedState = data['state'] ?? 'Gujarat';
          _selectedCity = data['city'] ?? 'Ahmedabad';
          _cityCtrl.text = _selectedCity ?? '';
          _taxNumberCtrl.text = data['tax_number'] ?? '';
          _taxRateCtrl.text = (data['default_tax_rate'] ?? 18).toString();
          _currencyCtrl.text = data['currency_symbol'] ?? '₹';
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load company details';
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

  Future<void> _saveCompany() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final newEmail = _emailCtrl.text.trim();
      final payload = {
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': newEmail,
        'address_line_1': _addressCtrl.text.trim(),
        'state': _selectedState ?? 'Gujarat',
        'city': _selectedCity ?? _cityCtrl.text.trim(),
        'tax_number': _taxNumberCtrl.text.trim(),
        'default_tax_rate': double.tryParse(_taxRateCtrl.text) ?? 18.0,
        'currency_symbol': _currencyCtrl.text.trim(),
      };

      final res = await _api.put('/company', data: payload);
      if (res.statusCode == 200) {
        // Save updated email to persistent local storage so login & forgot password use it automatically
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('last_admin_email', newEmail);
          await prefs.setString('company_email', newEmail);
        } catch (_) {}

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Company profile updated & credentials synced!')),
          );
        }
        _fetchCompany();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to log out of AMC360?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentThemeMode = ref.watch(themeModeProvider);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Company & Settings')),
        body: const LoadingState(message: 'Loading company profile...'),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Company & Settings')),
        body: ErrorState(message: _error!, onRetry: _fetchCompany),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Company & Settings'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // Theme Mode Selector Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: Icon(Icons.palette_outlined, size: 20, color: theme.primaryColor),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Appearance & Theme', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          Text('Choose your preferred visual mode', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      _buildThemeOption(
                        label: 'System',
                        icon: Icons.brightness_auto,
                        mode: ThemeMode.system,
                        currentMode: currentThemeMode,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      _buildThemeOption(
                        label: 'Light',
                        icon: Icons.light_mode_outlined,
                        mode: ThemeMode.light,
                        currentMode: currentThemeMode,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      _buildThemeOption(
                        label: 'Dark',
                        icon: Icons.dark_mode_outlined,
                        mode: ThemeMode.dark,
                        currentMode: currentThemeMode,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Company Profile', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Business Name *',
                    hint: 'e.g. CoolTech Air Conditioning Services',
                    controller: _nameCtrl,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Support Phone',
                          hint: '+91 9876543210',
                          controller: _phoneCtrl,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          label: 'Official Email',
                          hint: 'info@company.com',
                          controller: _emailCtrl,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Business Address',
                    hint: 'Street, Building, Suite',
                    controller: _addressCtrl,
                  ),
                  const SizedBox(height: 12),
                  StateCitySelector(
                    initialValueState: _selectedState,
                    initialValueCity: _selectedCity,
                    isRequired: true,
                    onChanged: (state, city) {
                      setState(() {
                        _selectedState = state;
                        _selectedCity = city;
                        _cityCtrl.text = city;
                      });
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
                  Text('Taxation & Financial Configuration', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'GSTIN / Tax ID',
                    hint: '27AABCU9603R1ZM',
                    controller: _taxNumberCtrl,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Default Tax %',
                          hint: '18.0',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          controller: _taxRateCtrl,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          label: 'Currency Symbol',
                          hint: '₹',
                          controller: _currencyCtrl,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Save Changes',
              icon: Icons.save_outlined,
              isLoading: _isSaving,
              onPressed: _saveCompany,
            ),
            const SizedBox(height: 24),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Application Information', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildAppInfoRow('Application', AppConfig.appName),
                  _buildAppInfoRow('Tagline', AppConfig.appTagline),
                  _buildAppInfoRow('Release Version', AppConfig.appVersion),
                  _buildAppInfoRow('Industry Domain', (_company?['business_type'] ?? 'HVAC / Multi-Industry').toString().toUpperCase()),
                  _buildAppInfoRow('Multi-Tenant Mode', 'Enabled (Tenant Data Isolated)'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Sign Out Account',
              icon: Icons.logout,
              type: AppButtonType.danger,
              onPressed: _confirmLogout,
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfoRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required String label,
    required IconData icon,
    required ThemeMode mode,
    required ThemeMode currentMode,
  }) {
    final isSelected = currentMode == mode;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(mode),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.primaryColor.withAlpha(isDark ? 50 : 25)
                : (isDark ? AppTheme.darkCard : AppTheme.lightSurface),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: isSelected
                  ? theme.primaryColor
                  : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? theme.primaryColor
                    : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? theme.primaryColor
                      : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

