import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/configuration/app_config.dart';
import '../../app/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import 'auth_provider.dart';
import 'widgets/forgot_password_sheet.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  String _adminEmail = 'samarthpanara12345@gmail.com';
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _rememberMe = true;
  bool _obscurePassword = true;
  String _activeRole = 'admin';

  late AnimationController _ambientController;
  late Animation<double> _ambientMotion;

  @override
  void initState() {
    super.initState();

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);

    _ambientMotion = CurvedAnimation(
      parent: _ambientController,
      curve: Curves.easeInOutSine,
    );

    _emailController.text = _adminEmail;
    _passwordController.text = 'Secret@123';

    _loadAdminCredentials();
  }

  Future<void> _loadAdminCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('last_admin_email') ?? prefs.getString('company_email');
      if (savedEmail != null && savedEmail.isNotEmpty && mounted) {
        setState(() {
          _adminEmail = savedEmail;
          if (_activeRole == 'admin') {
            _emailController.text = savedEmail;
          }
        });
      }

      // Fetch public company and admin info from server
      final res = await ApiClient().get('/auth/public-info');
      if (res.statusCode == 200 && res.data['data'] != null) {
        final email = res.data['data']['admin_email']?.toString();
        if (email != null && email.isNotEmpty) {
          await prefs.setString('last_admin_email', email);
          if (mounted) {
            setState(() {
              _adminEmail = email;
              if (_activeRole == 'admin') {
                _emailController.text = email;
              }
            });
          }
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final input = _emailController.text.trim();
    final success = await ref.read(authProvider.notifier).login(
      input,
      _passwordController.text,
    );

    if (success && mounted) {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (_activeRole == 'admin' && input.contains('@')) {
          await prefs.setString('last_admin_email', input);
        }
      } catch (_) {}
      if (!mounted) return;

      final role = ref.read(authProvider).role;
      if (role == 'technician') {
        context.go('/dashboard/technician');
      } else if (role == 'customer') {
        context.go('/dashboard/customer');
      } else {
        context.go('/dashboard/admin');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Subtle moving ambient blurred gradient orbs
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _ambientMotion,
              builder: (context, child) {
                return Stack(
                  children: [
                    Positioned(
                      top: -60 + (_ambientMotion.value * 30),
                      right: -40 + (_ambientMotion.value * -20),
                      child: Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF2563EB).withAlpha(isDark ? 35 : 20),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -50 + (_ambientMotion.value * -25),
                      left: -30 + (_ambientMotion.value * 20),
                      child: Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF0D9488).withAlpha(isDark ? 30 : 18),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top: Brand Emblem
                        Center(
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2563EB).withAlpha(isDark ? 80 : 40),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.shield_outlined,
                                size: 36,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        Center(
                          child: Text(
                            'AMC360',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // Middle: Large Greeting
                        Center(
                          child: Text(
                            'Manage your service business beautifully.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            'Command center for contracts, visits & billing',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Main Login Card
                        ClipRRect(
                          borderRadius: AppRadius.cardRadius,
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF131C2E).withAlpha(220)
                                    : Colors.white.withAlpha(240),
                                borderRadius: AppRadius.cardRadius,
                                border: Border.all(
                                  color: isDark ? Colors.white.withAlpha(25) : const Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                                boxShadow: AppShadows.card(isDark: isDark),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (authState.errorMessage != null) ...[
                                    Container(
                                      padding: const EdgeInsets.all(AppSpacing.md),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444).withAlpha(isDark ? 30 : 15),
                                        borderRadius: BorderRadius.circular(AppRadius.sm),
                                        border: Border.all(
                                          color: const Color(0xFFEF4444).withAlpha(isDark ? 80 : 40),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.error_outline_rounded,
                                            color: Color(0xFFEF4444),
                                            size: 18,
                                          ),
                                          const SizedBox(width: AppSpacing.xs),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  authState.errorMessage!,
                                                  style: GoogleFonts.inter(
                                                    color: const Color(0xFFEF4444),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                if (authState.errorMessage!.contains('Cannot connect') ||
                                                    authState.errorMessage!.contains('Unable to connect')) ...[
                                                  const SizedBox(height: 6),
                                                  InkWell(
                                                    onTap: _showServerConfigDialog,
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFEF4444).withAlpha(30),
                                                        borderRadius: BorderRadius.circular(4),
                                                        border: Border.all(color: const Color(0xFFEF4444).withAlpha(70)),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          const Icon(Icons.settings_ethernet_rounded, size: 13, color: Color(0xFFEF4444)),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            'Change Server URL / Test Ping',
                                                            style: GoogleFonts.inter(
                                                              color: const Color(0xFFEF4444),
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.w700,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                  ],

                                   // Animated Segmented Role Controller
                                   Container(
                                     margin: const EdgeInsets.only(bottom: AppSpacing.md),
                                     padding: const EdgeInsets.all(4),
                                     decoration: BoxDecoration(
                                       color: isDark ? Colors.black.withAlpha(90) : const Color(0xFFF1F5F9),
                                       borderRadius: BorderRadius.circular(14),
                                       border: Border.all(
                                         color: isDark ? Colors.white.withAlpha(15) : const Color(0xFFE2E8F0),
                                       ),
                                     ),
                                     child: Row(
                                       children: [
                                         _buildRoleSegment('admin', 'Admin', Icons.admin_panel_settings_rounded, const Color(0xFF2563EB), isDark),
                                         const SizedBox(width: 4),
                                         _buildRoleSegment('technician', 'Technician', Icons.engineering_rounded, const Color(0xFF0D9488), isDark),
                                         const SizedBox(width: 4),
                                         _buildRoleSegment('customer', 'Customer', Icons.apartment_rounded, const Color(0xFF7C3AED), isDark),
                                       ],
                                     ),
                                   ),

                                   // Dynamic Role Context Banner with Fluid Animation
                                   AnimatedSwitcher(
                                     duration: const Duration(milliseconds: 280),
                                     switchInCurve: Curves.easeOutCubic,
                                     switchOutCurve: Curves.easeInCubic,
                                     transitionBuilder: (child, animation) {
                                       return FadeTransition(
                                         opacity: animation,
                                         child: SlideTransition(
                                           position: Tween<Offset>(
                                             begin: const Offset(0.0, 0.05),
                                             end: Offset.zero,
                                           ).animate(animation),
                                           child: child,
                                         ),
                                       );
                                     },
                                     child: KeyedSubtree(
                                       key: ValueKey<String>(_activeRole),
                                       child: Container(
                                         margin: const EdgeInsets.only(bottom: AppSpacing.md),
                                         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                         decoration: BoxDecoration(
                                           color: (_activeRole == 'admin'
                                                   ? const Color(0xFF2563EB)
                                                   : _activeRole == 'technician'
                                                       ? const Color(0xFF0D9488)
                                                       : const Color(0xFF7C3AED))
                                               .withAlpha(isDark ? 35 : 18),
                                           borderRadius: BorderRadius.circular(12),
                                           border: Border.all(
                                             color: (_activeRole == 'admin'
                                                     ? const Color(0xFF2563EB)
                                                     : _activeRole == 'technician'
                                                         ? const Color(0xFF0D9488)
                                                         : const Color(0xFF7C3AED))
                                                 .withAlpha(isDark ? 80 : 40),
                                           ),
                                         ),
                                         child: Row(
                                           children: [
                                             Icon(
                                               _activeRole == 'admin'
                                                   ? Icons.admin_panel_settings_rounded
                                                   : _activeRole == 'technician'
                                                       ? Icons.engineering_rounded
                                                       : Icons.apartment_rounded,
                                               color: _activeRole == 'admin'
                                                   ? const Color(0xFF2563EB)
                                                   : _activeRole == 'technician'
                                                       ? const Color(0xFF0D9488)
                                                       : const Color(0xFF7C3AED),
                                               size: 22,
                                             ),
                                             const SizedBox(width: 10),
                                             Expanded(
                                               child: Column(
                                                 crossAxisAlignment: CrossAxisAlignment.start,
                                                 children: [
                                                   Text(
                                                     _activeRole == 'admin'
                                                         ? 'Admin Command Center'
                                                         : _activeRole == 'technician'
                                                             ? 'Technician Field Portal'
                                                             : 'Customer Client Portal',
                                                     style: TextStyle(
                                                       fontSize: 13,
                                                       fontWeight: FontWeight.w700,
                                                       color: _activeRole == 'admin'
                                                           ? const Color(0xFF2563EB)
                                                           : _activeRole == 'technician'
                                                               ? const Color(0xFF0D9488)
                                                               : const Color(0xFF7C3AED),
                                                     ),
                                                   ),
                                                   const SizedBox(height: 2),
                                                   Text(
                                                     _activeRole == 'admin'
                                                         ? 'Full control over contracts, dispatches & billing'
                                                         : _activeRole == 'technician'
                                                             ? 'View assigned service visits & checklist'
                                                             : 'Review contracts, requests & pay renewals',
                                                     style: TextStyle(
                                                       fontSize: 11,
                                                       color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                                     ),
                                                   ),
                                                 ],
                                               ),
                                             ),
                                           ],
                                         ),
                                       ),
                                     ),
                                   ),


                                   AppTextField(
                                     label: 'Email or Mobile Number',
                                     hint: 'e.g. samarthpanara12345@gmail.com or 9876500001',
                                     controller: _emailController,
                                     keyboardType: TextInputType.emailAddress,
                                     prefixIcon: const Icon(Icons.person_outline_rounded),
                                     validator: (val) {
                                       if (val == null || val.trim().isEmpty) {
                                         return 'Please enter your email or 10-digit mobile number';
                                       }
                                       final text = val.trim();
                                       if (text.contains('@')) {
                                         final emailRegex = RegExp(r'^[\w\.-]+@[\w-]+\.\w{2,}$');
                                         if (!emailRegex.hasMatch(text)) {
                                           return 'Please enter a valid email address';
                                         }
                                       } else {
                                         String digits = text.replaceAll(RegExp(r'\D'), '');
                                         if (digits.length == 12 && digits.startsWith('91')) {
                                           digits = digits.substring(2);
                                         } else if (digits.length == 11 && digits.startsWith('0')) {
                                           digits = digits.substring(1);
                                         }

                                         if (digits.length != 10) {
                                           return 'Mobile number must be exactly 10 digits (e.g. 9876500001)';
                                         }
                                         if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) {
                                           return 'Indian mobile numbers must start with 6, 7, 8, or 9';
                                         }
                                       }
                                       return null;
                                     },
                                   ),
                                   const SizedBox(height: AppSpacing.md),

                                   AppTextField(
                                     label: 'Password',
                                     controller: _passwordController,
                                     obscureText: _obscurePassword,
                                     prefixIcon: const Icon(Icons.lock_outline_rounded),
                                     suffixIcon: IconButton(
                                       icon: Icon(
                                         _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                         color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                         size: 20,
                                       ),
                                       onPressed: () {
                                         setState(() {
                                           _obscurePassword = !_obscurePassword;
                                         });
                                       },
                                     ),
                                     validator: (val) {
                                       if (val == null || val.isEmpty) {
                                         return 'Please enter your password';
                                       }
                                       return null;
                                     },
                                   ),
                                   const SizedBox(height: AppSpacing.xs),

                                   Row(
                                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                     children: [
                                       Row(
                                         children: [
                                           SizedBox(
                                             height: 24,
                                             width: 24,
                                             child: Checkbox(
                                               value: _rememberMe,
                                               activeColor: const Color(0xFF2563EB),
                                               shape: RoundedRectangleBorder(
                                                 borderRadius: BorderRadius.circular(4),
                                               ),
                                               onChanged: (val) {
                                                 setState(() {
                                                   _rememberMe = val ?? true;
                                                 });
                                               },
                                             ),
                                           ),
                                           const SizedBox(width: 8),
                                           Text(
                                             'Remember me',
                                             style: GoogleFonts.inter(
                                               fontSize: 12,
                                               fontWeight: FontWeight.w500,
                                               color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                             ),
                                           ),
                                         ],
                                       ),
                                       TextButton(
                                         onPressed: () {
                                           showModalBottomSheet(
                                             context: context,
                                             isScrollControlled: true,
                                             backgroundColor: Colors.transparent,
                                             builder: (ctx) => ForgotPasswordSheet(
                                               initialEmail: _emailController.text.contains('@')
                                                   ? _emailController.text.trim()
                                                   : _adminEmail,
                                               onPasswordResetSuccess: (email, pass) {
                                                 setState(() {
                                                   _emailController.text = email;
                                                   _passwordController.text = pass;
                                                 });
                                                 _handleLogin();
                                               },
                                             ),
                                           );
                                         },
                                         style: TextButton.styleFrom(
                                           padding: EdgeInsets.zero,
                                           minimumSize: Size.zero,
                                           tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                         ),
                                         child: Text(
                                           'Forgot password?',
                                           style: GoogleFonts.inter(
                                             fontSize: 12,
                                             fontWeight: FontWeight.w600,
                                             color: const Color(0xFF2563EB),
                                           ),
                                         ),
                                       ),
                                     ],
                                   ),
                                   const SizedBox(height: AppSpacing.lg),

                                  AppButton(
                                    label: _activeRole == 'admin'
                                        ? 'Sign In as Admin'
                                        : _activeRole == 'technician'
                                            ? 'Sign In as Technician'
                                            : 'Sign In as Customer',
                                    icon: Icons.login_rounded,
                                    onPressed: _handleLogin,
                                    isLoading: authState.isLoading,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  _buildQuickCredentialsBar(isDark),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Bottom: Version Info
                        Center(
                          child: Text(
                            'AMC360 • v1.0.0 • Command Center Edition',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // Server Tunnel Status Badge (Constrained, Never Overflows)
                        Center(
                          child: InkWell(
                            onTap: _showServerConfigDialog,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 320),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withAlpha(10) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark ? Colors.white.withAlpha(15) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0xFF10B981),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      AppConfig.apiBaseUrl.contains('trycloudflare.com')
                                          ? 'Public Cloud Tunnel (Online)'
                                          : 'Server: ${AppConfig.apiBaseUrl.replaceAll('/api/v1', '')}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(Icons.edit_outlined, size: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showServerConfigDialog() {
    final controller = TextEditingController(text: AppConfig.apiBaseUrl);
    bool isTesting = false;
    String? testResult;
    bool? testSuccess;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.dns_rounded, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Backend Server URL',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select a preset or enter the active server host. For real iPhone testing, use the Mac Wi-Fi IP or Cloudflare tunnel.',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),

                // Quick preset chips
                Text('Quick Presets:', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.cloud_done_rounded, size: 14, color: AppTheme.primaryColor),
                      label: const Text('☁️ Cloud 24/7 (Render)'),
                      labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      onPressed: () {
                        controller.text = AppConfig.cloudApiUrl;
                        setDialogState(() {
                          testResult = null;
                        });
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.wifi_rounded, size: 14),
                      label: const Text('Wi-Fi (10.20.57.32)'),
                      labelStyle: const TextStyle(fontSize: 11),
                      onPressed: () {
                        controller.text = AppConfig.currentWifiUrl;
                        setDialogState(() {
                          testResult = null;
                        });
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.laptop_mac_rounded, size: 14),
                      label: const Text('Localhost (127.0.0.1)'),
                      labelStyle: const TextStyle(fontSize: 11),
                      onPressed: () {
                        controller.text = AppConfig.localhostUrl;
                        setDialogState(() {
                          testResult = null;
                        });
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.phone_android_rounded, size: 14),
                      label: const Text('Emulator (10.0.2.2)'),
                      labelStyle: const TextStyle(fontSize: 11),
                      onPressed: () {
                        controller.text = AppConfig.androidEmulatorUrl;
                        setDialogState(() {
                          testResult = null;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: controller,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'API URL',
                    hintText: 'http://10.20.57.32:8000/api/v1',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => controller.clear(),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Test Connection Ping Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: isTesting
                        ? null
                        : () async {
                            setDialogState(() {
                              isTesting = true;
                              testResult = 'Pinging server...';
                              testSuccess = null;
                            });
                            final res = await ApiClient.checkConnection(controller.text.trim());
                            setDialogState(() {
                              isTesting = false;
                              testSuccess = res['success'] == true;
                              if (testSuccess == true) {
                                testResult = 'Connected (${res['latencyMs']}ms): ${res['companyName']}';
                              } else {
                                testResult = 'Failed: ${res['error']}';
                              }
                            });
                          },
                    icon: isTesting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.network_check_rounded, size: 16),
                    label: Text(
                      isTesting ? 'Testing Connection...' : 'Test Connection / Ping',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

                if (testResult != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: testSuccess == true
                          ? const Color(0xFF10B981).withAlpha(25)
                          : const Color(0xFFEF4444).withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: testSuccess == true
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          testSuccess == true ? Icons.check_circle_rounded : Icons.error_rounded,
                          size: 16,
                          color: testSuccess == true ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            testResult!,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: testSuccess == true ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await AppConfig.resetToDefault();
                controller.text = AppConfig.apiBaseUrl;
                setDialogState(() {
                  testResult = 'Reset to default Wi-Fi: ${AppConfig.apiBaseUrl}';
                  testSuccess = null;
                });
              },
              child: const Text('Reset', style: TextStyle(fontSize: 12)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final newUrl = controller.text.trim();
                await AppConfig.setApiUrl(newUrl);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (mounted) {
                  setState(() {});
                  _loadAdminCredentials();
                  messenger.showSnackBar(
                    SnackBar(content: Text('Server URL set to: ${AppConfig.apiBaseUrl}')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSegment(String role, String label, IconData icon, Color themeColor, bool isDark) {
    final isSelected = _activeRole == role;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _activeRole = role.toLowerCase();
            if (_activeRole == 'technician') {
              _emailController.text = 'tech@cooltech.com';
              _passwordController.text = 'Secret@123';
            } else if (_activeRole == 'customer') {
              _emailController.text = 'customer@apex.com';
              _passwordController.text = 'Secret@123';
            } else {
              _emailController.text = _adminEmail;
              _passwordController.text = 'Secret@123';
            }
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? themeColor.withAlpha(220) : themeColor)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: themeColor.withAlpha(isDark ? 90 : 70),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected
                    ? Colors.white
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickCredentialsBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withAlpha(120) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(12) : const Color(0xFFCBD5E1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.key_rounded,
                size: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              const SizedBox(width: 5),
              Text(
                '1-Tap Demo Switcher (Pass: Secret@123)',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildQuickFillChip('Admin', _adminEmail, 'admin', const Color(0xFF2563EB), isDark),
              const SizedBox(width: 6),
              _buildQuickFillChip('Technician', 'tech@cooltech.com', 'technician', const Color(0xFF0D9488), isDark),
              const SizedBox(width: 6),
              _buildQuickFillChip('Customer', 'customer@apex.com', 'customer', const Color(0xFF7C3AED), isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFillChip(String label, String email, String role, Color color, bool isDark) {
    final isSelected = _activeRole == role;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _activeRole = role;
            _emailController.text = email;
            _passwordController.text = 'Secret@123';
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withAlpha(isDark ? 30 : 20),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : color.withAlpha(isDark ? 80 : 60),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : color),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
