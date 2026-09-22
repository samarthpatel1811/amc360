import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';

class RenewalRequestDialog extends StatefulWidget {
  final Map<String, dynamic> contract;

  const RenewalRequestDialog({super.key, required this.contract});

  @override
  State<RenewalRequestDialog> createState() => _RenewalRequestDialogState();
}

class _RenewalRequestDialogState extends State<RenewalRequestDialog> {
  String _selectedDuration = '12_months';
  late DateTime _preferredStartDate;
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final endDateStr = widget.contract['end_date']?.toString();
    if (endDateStr != null && endDateStr.isNotEmpty) {
      final parsed = DateTime.tryParse(endDateStr);
      _preferredStartDate = (parsed != null) ? parsed.add(const Duration(days: 1)) : DateTime.now();
    } else {
      _preferredStartDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final contractId = widget.contract['id'];
      final res = await ApiClient().post('/contracts/$contractId/request-renewal', data: {
        'duration_type': _selectedDuration,
        'preferred_start_date': DateFormat('yyyy-MM-dd').format(_preferredStartDate),
        'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      });

      if (res.data['success'] == true) {
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Renewal request submitted! Admin will provide your price quote.'),
              backgroundColor: AppTheme.success,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } else {
        setState(() {
          _isSubmitting = false;
          _errorMessage = res.data['message'] ?? 'Failed to submit renewal request.';
        });
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final df = DateFormat('dd MMM yyyy');

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withAlpha(isDark ? 40 : 20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.autorenew_rounded, color: Color(0xFF2563EB), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Renew AMC Contract',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  widget.contract['contract_number'] ?? 'AMC Contract',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withAlpha(isDark ? 30 : 15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEF4444).withAlpha(50)),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
                ),
              ),
            ],

            Text(
              'Select Renewal Duration',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildDurationChip('12_months', '1 Year (12 Mo)', isDark),
                _buildDurationChip('24_months', '2 Years (24 Mo)', isDark),
                _buildDurationChip('6_months', '6 Months', isDark),
              ],
            ),
            const SizedBox(height: 16),

            // Start Date Picker Tile
            Text(
              'Preferred Start Date',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _preferredStartDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() => _preferredStartDate = picked);
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withAlpha(8) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? Colors.white.withAlpha(15) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_outlined, size: 18, color: Color(0xFF2563EB)),
                    const SizedBox(width: 10),
                    Text(
                      df.format(_preferredStartDate),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    const Text('Change', style: TextStyle(fontSize: 12, color: Color(0xFF2563EB))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes / Special requirements
            AppTextField(
              label: 'Equipment Updates or Notes (Optional)',
              hint: 'e.g. Added 2 ACs in meeting rooms, need weekend visits...',
              controller: _notesController,
              maxLines: 3,
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withAlpha(isDark ? 20 : 10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Once submitted, the administrator will review your details and prepare your customized renewal price. You will see the final quote to pay directly.',
                style: TextStyle(fontSize: 11, color: Color(0xFF2563EB), height: 1.4),
              ),
            ),
            const SizedBox(height: 16),

            AppButton(
              label: 'Submit Renewal Request',
              icon: Icons.send_rounded,
              isLoading: _isSubmitting,
              onPressed: _submitRequest,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationChip(String value, String label, bool isDark) {
    final isSelected = _selectedDuration == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedDuration = value),
      selectedColor: const Color(0xFF2563EB),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: isDark ? Colors.white.withAlpha(10) : const Color(0xFFE2E8F0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
