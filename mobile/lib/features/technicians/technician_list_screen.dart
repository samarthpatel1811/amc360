import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';

class TechnicianListScreen extends StatefulWidget {
  const TechnicianListScreen({super.key});

  @override
  State<TechnicianListScreen> createState() => _TechnicianListScreenState();
}

class _TechnicianListScreenState extends State<TechnicianListScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  String? _error;
  List<dynamic> _technicians = [];

  @override
  void initState() {
    super.initState();
    _fetchTechnicians();
  }

  Future<void> _fetchTechnicians() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await _api.get('/technicians');
      if (res.statusCode == 200 && res.data['data'] != null) {
        setState(() {
          _technicians = res.data['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load technicians';
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

  Future<void> _showAddTechnicianDialog() async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passwordCtrl = TextEditingController(text: 'Tech@123');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Field Technician'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'Technician Full Name *',
                hint: 'e.g. Ramesh Kumar',
                controller: nameCtrl,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Email Address *',
                hint: 'tech@company.com',
                keyboardType: TextInputType.emailAddress,
                controller: emailCtrl,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Phone Number *',
                hint: '+91 9876543210',
                keyboardType: TextInputType.phone,
                controller: phoneCtrl,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Initial Login Password *',
                hint: 'Min 8 characters',
                controller: passwordCtrl,
                obscureText: true,
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
              if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(ctx);
              try {
                final payload = {
                  'name': nameCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'password': passwordCtrl.text.trim(),
                };
                final res = await _api.post('/technicians', data: payload);
                if (res.statusCode == 201) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Technician account created successfully!')),
                  );
                  _fetchTechnicians();
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to add technician: $e'), backgroundColor: AppTheme.error),
                );
              }
            },
            child: const Text('Create Account'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Technician Team'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchTechnicians,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTechnicianDialog,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Tech'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingState(message: 'Loading technician roster...');
    }

    if (_error != null) {
      return ErrorState(message: _error!, onRetry: _fetchTechnicians);
    }

    if (_technicians.isEmpty) {
      return const EmptyState(
        title: 'No Technicians Registered',
        message: 'Add technicians to start assigning service visits and AMC jobs.',
        icon: Icons.engineering_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchTechnicians,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _technicians.length,
        itemBuilder: (context, index) {
          final tech = _technicians[index];
          final name = tech['name'] ?? 'Technician';
          final email = tech['email'] ?? '';
          final phone = tech['phone'] ?? 'No phone';
          final activeJobs = tech['active_jobs_count'] ?? 0;
          final todayJobs = tech['today_jobs_count'] ?? 0;

          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AppCard(
            margin: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primaryColor.withAlpha(25),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'T',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(phone, style: TextStyle(fontSize: 13, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
                      Text(email, style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withAlpha(20),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$todayJobs Today',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryColor.withAlpha(20),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$activeJobs Active Jobs',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
