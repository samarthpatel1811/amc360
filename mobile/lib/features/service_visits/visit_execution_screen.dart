import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:signature/signature.dart';
import '../../app/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/status_badge.dart';

class VisitExecutionScreen extends StatefulWidget {
  final int visitId;

  const VisitExecutionScreen({
    super.key,
    required this.visitId,
  });

  @override
  State<VisitExecutionScreen> createState() => _VisitExecutionScreenState();
}

class _VisitExecutionScreenState extends State<VisitExecutionScreen> with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  late TabController _tabController;

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _visit;

  // Sign-off controllers
  late SignatureController _sigController;
  final TextEditingController _signerNameCtrl = TextEditingController();
  final TextEditingController _workPerformedCtrl = TextEditingController();
  final TextEditingController _findingsCtrl = TextEditingController();
  final TextEditingController _recommendationsCtrl = TextEditingController();
  final TextEditingController _customerRemarksCtrl = TextEditingController();
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _sigController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
    _fetchVisitDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _sigController.dispose();
    _signerNameCtrl.dispose();
    _workPerformedCtrl.dispose();
    _findingsCtrl.dispose();
    _recommendationsCtrl.dispose();
    _customerRemarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchVisitDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await _api.get('/service-visits/${widget.visitId}');
      if (res.statusCode == 200 && res.data['data'] != null) {
        final data = res.data['data'] as Map<String, dynamic>;
        setState(() {
          _visit = data;
          _isLoading = false;
          _workPerformedCtrl.text = data['work_performed'] ?? '';
          _findingsCtrl.text = data['findings'] ?? '';
          _recommendationsCtrl.text = data['recommendations'] ?? '';
          _customerRemarksCtrl.text = data['customer_remarks'] ?? '';
        });
      } else {
        setState(() {
          _error = 'Failed to load visit details';
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

  Future<void> _saveChecklist(List<Map<String, dynamic>> items) async {
    try {
      final payload = {
        'items': items.map((it) => {
          'id': it['id'],
          'value': it['value'],
          'is_passed': it['is_passed'],
        }).toList(),
      };

      final res = await _api.post('/service-visits/${widget.visitId}/checklist', data: payload);
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Checklist saved successfully!')),
        );
        _fetchVisitDetails();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save checklist: $e'), backgroundColor: AppTheme.error),
      );
    }
  }

  Future<void> _addPartDialog() async {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final priceCtrl = TextEditingController(text: '0');
    final notesCtrl = TextEditingController();
    String coverageType = 'included';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Replacement Part'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  label: 'Part Name / Description',
                  hint: 'e.g. Compressor Capacitor 45uF',
                  controller: nameCtrl,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Quantity',
                        hint: '1',
                        keyboardType: TextInputType.number,
                        controller: qtyCtrl,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: 'Unit Price',
                        hint: '0.00',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        controller: priceCtrl,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: coverageType,
                  decoration: const InputDecoration(labelText: 'Coverage Type'),
                  items: const [
                    DropdownMenuItem(value: 'included', child: Text('Included in AMC (Free)')),
                    DropdownMenuItem(value: 'chargeable', child: Text('Chargeable to Customer')),
                    DropdownMenuItem(value: 'warranty', child: Text('Warranty Replacement')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => coverageType = val);
                  },
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Notes (Optional)',
                  hint: 'Serial number, manufacturer, reason',
                  controller: notesCtrl,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);

                try {
                  final payload = {
                    'part_name': nameCtrl.text.trim(),
                    'quantity': double.tryParse(qtyCtrl.text) ?? 1.0,
                    'unit_price': double.tryParse(priceCtrl.text) ?? 0.0,
                    'coverage_type': coverageType,
                    'notes': notesCtrl.text.trim(),
                  };

                  final res = await _api.post('/service-visits/${widget.visitId}/parts', data: payload);
                  if (res.statusCode == 201) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Part added successfully!')),
                    );
                    _fetchVisitDetails();
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add part: $e'), backgroundColor: AppTheme.error),
                  );
                }
              },
              child: const Text('Add Part'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadPhoto(String photoType) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (pickedFile == null) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading photo...')),
      );

      final bytes = await pickedFile.readAsBytes();
      final formData = FormData.fromMap({
        'photo': MultipartFile.fromBytes(bytes, filename: pickedFile.name),
        'photo_type': photoType,
        'caption': '$photoType service photo',
      });

      final res = await _api.post('/service-visits/${widget.visitId}/photos', data: formData);
      if (res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo uploaded successfully!')),
        );
        _fetchVisitDetails();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload photo: $e'), backgroundColor: AppTheme.error),
      );
    }
  }

  Future<void> _completeServiceVisit() async {
    final status = _visit?['status'];
    if (status == 'completed') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visit is already completed.')),
      );
      return;
    }

    if (_workPerformedCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the work performed before completing.')),
      );
      return;
    }

    setState(() => _isCompleting = true);

    try {
      // 1. If signature drawn, save it
      if (_sigController.isNotEmpty) {
        final sigBytes = await _sigController.toPngBytes();
        if (sigBytes != null) {
          final base64Sig = 'data:image/png;base64,${base64Encode(sigBytes)}';
          await _api.post('/service-visits/${widget.visitId}/signature', data: {
            'signature_image': base64Sig,
            'signed_by_name': _signerNameCtrl.text.trim().isEmpty ? 'Customer Representative' : _signerNameCtrl.text.trim(),
          });
        }
      }

      // 2. Submit completion
      final completePayload = {
        'work_performed': _workPerformedCtrl.text.trim(),
        'findings': _findingsCtrl.text.trim(),
        'recommendations': _recommendationsCtrl.text.trim(),
        'customer_remarks': _customerRemarksCtrl.text.trim(),
      };

      final res = await _api.post('/service-visits/${widget.visitId}/complete', data: completePayload);
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service visit marked as COMPLETED and official report generated!')),
        );
        await _fetchVisitDetails();
        _tabController.animateTo(4); // Switch to report tab
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error completing visit: $e'), backgroundColor: AppTheme.error),
      );
    } finally {
      setState(() => _isCompleting = false);
    }
  }

  Future<void> _printOrDownloadPdf() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading service report PDF...')),
      );

      final res = await _api.get('/service-visits/${widget.visitId}/pdf');
      if (res.statusCode == 200) {
        final pdfBytes = res.data as List<int>;
        await Printing.layoutPdf(
          onLayout: (_) => Uint8List.fromList(pdfBytes),
          name: 'Service_Report_${_visit?['visit_number'] ?? widget.visitId}.pdf',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch PDF: $e'), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Service Visit Execution')),
        body: const LoadingState(message: 'Loading visit data...'),
      );
    }

    if (_error != null || _visit == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Service Visit Execution')),
        body: ErrorState(
          message: _error ?? 'Visit not found',
          onRetry: _fetchVisitDetails,
        ),
      );
    }

    final visit = _visit!;
    final visitNumber = visit['visit_number'] ?? 'VISIT-${widget.visitId}';
    final status = visit['status'] ?? 'pending';
    final isCompleted = status == 'completed';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(visitNumber, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text(
              visit['customer']?['name'] ?? 'Customer',
              style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: StatusBadge(status: status)),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(icon: Icon(Icons.info_outline, size: 20), text: 'Overview'),
            Tab(icon: Icon(Icons.checklist, size: 20), text: 'Checklist'),
            Tab(icon: Icon(Icons.build_circle_outlined, size: 20), text: 'Parts'),
            Tab(icon: Icon(Icons.camera_alt_outlined, size: 20), text: 'Photos'),
            Tab(icon: Icon(Icons.assignment_turned_in_outlined, size: 20), text: 'Sign-off'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(visit),
          _buildChecklistTab(visit, isCompleted),
          _buildPartsTab(visit, isCompleted),
          _buildPhotosTab(visit, isCompleted),
          _buildSignoffTab(visit, isCompleted),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(Map<String, dynamic> visit) {
    final customer = visit['customer'] ?? {};
    final asset = visit['asset'] ?? {};
    final contract = visit['contract'] ?? {};
    final technician = visit['technician'] ?? {};
    final startedAt = visit['started_at'];
    final completedAt = visit['completed_at'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Customer Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                _buildInfoRow('Name', customer['name'] ?? 'N/A'),
                _buildInfoRow('Contact Person', customer['contact_person'] ?? 'N/A'),
                _buildInfoRow('Phone', customer['phone'] ?? 'N/A'),
                _buildInfoRow('Address', '${customer['address'] ?? ''}, ${customer['city'] ?? ''}'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Equipment & Asset', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                _buildInfoRow('Asset Name', asset['name'] ?? 'N/A'),
                _buildInfoRow('Serial No.', asset['serial_number'] ?? 'N/A'),
                _buildInfoRow('Model', asset['model_number'] ?? 'N/A'),
                _buildInfoRow('Location', asset['location_in_facility'] ?? 'Main Facility'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Contract & Assignment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                _buildInfoRow('AMC Contract', contract['contract_number'] ?? 'N/A'),
                _buildInfoRow('Plan Type', contract['type']?.toString().toUpperCase() ?? 'COMPREHENSIVE'),
                _buildInfoRow('Technician', technician['name'] ?? 'Unassigned'),
                if (startedAt != null)
                  _buildInfoRow('Started At', DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(startedAt))),
                if (completedAt != null)
                  _buildInfoRow('Completed At', DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(completedAt))),
              ],
            ),
          ),
          if (visit['status'] == 'completed') ...[
            const SizedBox(height: 20),
            AppButton(
              label: 'View Signed Report PDF',
              icon: Icons.picture_as_pdf,
              onPressed: _printOrDownloadPdf,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChecklistTab(Map<String, dynamic> visit, bool isCompleted) {
    final items = List<Map<String, dynamic>>.from(visit['checklistItems'] ?? []);

    if (items.isEmpty) {
      return const EmptyState(
        title: 'No Checklist Configured',
        message: 'No service checklist items are attached to this visit category.',
        icon: Icons.checklist_outlined,
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final title = item['title'] ?? 'Task #${index + 1}';
              final required = item['required'] == true;
              final isPassed = item['is_passed'];
              final value = item['value'] ?? '';

              return AppCard(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                        ),
                        if (required)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.error.withAlpha(25),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Required', style: TextStyle(fontSize: 10, color: AppTheme.error, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('PASS'),
                          selected: isPassed == true,
                          selectedColor: AppTheme.success.withAlpha(50),
                          onSelected: isCompleted
                              ? null
                              : (selected) {
                                  setState(() {
                                    item['is_passed'] = selected ? true : null;
                                  });
                                },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('FAIL'),
                          selected: isPassed == false,
                          selectedColor: AppTheme.error.withAlpha(50),
                          onSelected: isCompleted
                              ? null
                              : (selected) {
                                  setState(() {
                                    item['is_passed'] = selected ? false : null;
                                  });
                                },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('N/A'),
                          selected: isPassed == null && value == 'N/A',
                          onSelected: isCompleted
                              ? null
                              : (selected) {
                                  setState(() {
                                    item['is_passed'] = null;
                                    item['value'] = selected ? 'N/A' : null;
                                  });
                                },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: value,
                      enabled: !isCompleted,
                      decoration: const InputDecoration(
                        labelText: 'Reading / Observation Notes',
                        hintText: 'e.g. 230V, 4.2A, Cleaned & Tested',
                        isDense: true,
                      ),
                      onChanged: (val) {
                        item['value'] = val;
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (!isCompleted)
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppButton(
              label: 'Save Checklist Changes',
              icon: Icons.save,
              onPressed: () => _saveChecklist(items),
            ),
          ),
      ],
    );
  }

  Widget _buildPartsTab(Map<String, dynamic> visit, bool isCompleted) {
    final parts = List<dynamic>.from(visit['parts'] ?? []);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Used Parts & Materials (${parts.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (!isCompleted)
                ElevatedButton.icon(
                  onPressed: _addPartDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Part'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: parts.isEmpty
              ? const EmptyState(
                  title: 'No Parts Recorded',
                  message: 'If replacement parts or consumables were used, record them here.',
                  icon: Icons.inventory_2_outlined,
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: parts.length,
                  itemBuilder: (context, index) {
                    final part = parts[index];
                    final partName = part['part_name'] ?? 'Part';
                    final qty = part['quantity'] ?? 1;
                    final unitPrice = part['unit_price'] ?? 0;
                    final totalPrice = part['total_price'] ?? (qty * unitPrice);
                    final coverage = part['coverage_type'] ?? 'included';

                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  partName,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                ),
                                const SizedBox(height: 4),
                                Builder(
                                  builder: (context) {
                                    final isDark = Theme.of(context).brightness == Brightness.dark;
                                    return Text(
                                      'Qty: $qty × ₹$unitPrice = ₹$totalPrice',
                                      style: TextStyle(fontSize: 13, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: coverage == 'included'
                                  ? AppTheme.success.withAlpha(25)
                                  : AppTheme.warning.withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              coverage.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: coverage == 'included' ? AppTheme.success : AppTheme.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPhotosTab(Map<String, dynamic> visit, bool isCompleted) {
    final photos = List<dynamic>.from(visit['photos'] ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isCompleted)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _uploadPhoto('before'),
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('Add "Before" Photo'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _uploadPhoto('after'),
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('Add "After" Photo'),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          if (photos.isEmpty)
            const EmptyState(
              title: 'No Photos Uploaded',
              message: 'Capture before and after photos to document maintenance quality.',
              icon: Icons.photo_camera_outlined,
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.9,
              ),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                final photo = photos[index];
                final photoType = photo['photo_type'] ?? 'equipment';
                final url = '${ApiClient.baseAssetUrl}/${photo['file_path']}';

                return AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (context, __, ___) {
                              final isDark = Theme.of(context).brightness == Brightness.dark;
                              return Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 40,
                                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          photoType.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.primaryColor),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSignoffTab(Map<String, dynamic> visit, bool isCompleted) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sig = visit['signature'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Work Completion Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Work Performed *',
            hint: 'Describe technical maintenance performed on asset...',
            controller: _workPerformedCtrl,
            maxLines: 3,
            enabled: !isCompleted,
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Findings & Diagnostics',
            hint: 'Component wear, dust level, voltage stability...',
            controller: _findingsCtrl,
            maxLines: 2,
            enabled: !isCompleted,
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Recommendations for Next Visit',
            hint: 'Parts to be replaced soon, preventive actions...',
            controller: _recommendationsCtrl,
            maxLines: 2,
            enabled: !isCompleted,
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Customer Remarks / Feedback',
            hint: 'Satisfactory service, equipment working properly...',
            controller: _customerRemarksCtrl,
            maxLines: 2,
            enabled: !isCompleted,
          ),
          const SizedBox(height: 20),
          const Text('Customer Digital Sign-Off', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          if (sig != null && sig['signature_image_path'] != null) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Signed by: ${sig['signed_by_name'] ?? 'Authorized Signer'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.network(
                      '${ApiClient.baseAssetUrl}/${sig['signature_image_path']}',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(child: Text('Signature on file')),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (!isCompleted) ...[
            AppTextField(
              label: 'Signer Full Name',
              hint: 'e.g. John Doe (Facility Manager)',
              controller: _signerNameCtrl,
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.borderColor),
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              child: Column(
                children: [
                  Signature(
                    controller: _sigController,
                    height: 150,
                    backgroundColor: Colors.white,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _sigController.clear(),
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text('Clear Signature'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (!isCompleted)
            AppButton(
              label: 'Complete Visit & Generate Report',
              icon: Icons.check_circle,
              isLoading: _isCompleting,
              onPressed: _completeServiceVisit,
            )
          else
            AppButton(
              label: 'Print / Download Official PDF Report',
              icon: Icons.picture_as_pdf,
              onPressed: _printOrDownloadPdf,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
