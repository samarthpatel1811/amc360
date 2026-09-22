import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/theme/app_theme.dart';
import '../auth/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _glowSweep;
  late Animation<double> _taglineFade;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // 1. Logo softly fades in
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.40, curve: Curves.easeOut),
      ),
    );

    // 2. Logo slightly scales from 96% -> 100%
    _logoScale = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
      ),
    );

    // 3. Subtle light/glow passes behind the logo
    _glowSweep = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.30, 0.75, curve: Curves.easeInOut),
      ),
    );

    // 4. Tagline fades in
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.50, 0.85, curve: Curves.easeOut),
      ),
    );

    _animController.forward();
    _initializeApp();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    final stopwatch = Stopwatch()..start();
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool isOnboarded = prefs.getBool('onboarding_completed') ?? false;

      await ref.read(authProvider.notifier).checkSession();
      final auth = ref.read(authProvider);

      // Ensure a crisp, graceful minimum display time of 350ms so the brand logo fades in smoothly
      final elapsed = stopwatch.elapsedMilliseconds;
      if (elapsed < 350) {
        await Future.delayed(Duration(milliseconds: 350 - elapsed));
      }

      if (!mounted) return;

      if (!isOnboarded) {
        context.go('/onboarding');
      } else if (auth.isAuthenticated) {
        if (auth.isAdmin) {
          context.go('/dashboard/admin');
        } else if (auth.isTechnician) {
          context.go('/dashboard/technician');
        } else {
          context.go('/dashboard/customer');
        }
      } else {
        context.go('/login');
      }
    } catch (e) {
      debugPrint('Splash init fallback: $e');
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : const Color(0xFFFAFAFC),
      body: Center(
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with Glow Sweep Behind
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Dynamic ambient radiant glow behind logo
                    Transform.translate(
                      offset: Offset(_glowSweep.value * 30, 0),
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF3B82F6).withAlpha((40 * _logoFade.value).toInt()),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Logo Emblem
                    Opacity(
                      opacity: _logoFade.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withAlpha(isDark ? 90 : 50),
                                blurRadius: 28,
                                spreadRadius: 0,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.shield_outlined,
                              size: 44,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xl),

                // Brand Name
                Opacity(
                  opacity: _logoFade.value,
                  child: Text(
                    'AMC360',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xs),

                // Tagline
                Opacity(
                  opacity: _taglineFade.value,
                  child: Text(
                    'AMC, Asset & Service Management',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.4,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.huge),

                // Subtle glowing progress pill instead of a spinner
                Opacity(
                  opacity: _taglineFade.value,
                  child: Container(
                    width: 48,
                    height: 3,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withAlpha(20) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Align(
                      alignment: Alignment(_glowSweep.value, 0),
                      child: Container(
                        width: 20,
                        height: 3,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withAlpha(150),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
