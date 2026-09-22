import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _items = const [
    OnboardingItem(
      title: 'Manage Every Contract',
      subtitle: 'Track AMC agreements, warranties, equipment coverage, and renewal alerts in one unified place.',
      icon: Icons.shield_outlined,
      badgeText: 'Contract Engine',
      accentColor: Color(0xFF1E40AF),
    ),
    OnboardingItem(
      title: 'Never Miss a Service',
      subtitle: 'Automated visit date scheduling, field technician dispatches, and real-time inspection checklists.',
      icon: Icons.calendar_month_outlined,
      badgeText: 'Field Operations',
      accentColor: Color(0xFF0D9488),
    ),
    OnboardingItem(
      title: 'Everything Connected',
      subtitle: 'Customers, technicians, equipment, digital signatures, signed PDF reports, and billing all in one touch.',
      icon: Icons.hub_outlined,
      badgeText: 'Unified Platform',
      accentColor: Color(0xFF7C3AED),
    ),
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _completeOnboarding,
            child: Text(
              'Skip',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (context, idx) {
                  final item = _items[idx];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: AppSpacing.lg),
                        // Abstract Visual Card
                        _buildAbstractGraphic(item, isDark),
                        const SizedBox(height: AppSpacing.xl),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: item.accentColor.withAlpha(isDark ? 35 : 20),
                            borderRadius: BorderRadius.circular(AppRadius.xs),
                          ),
                          child: Text(
                            item.badgeText.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: item.accentColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          item.subtitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Bottom Controls
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  // Animated Page Indicator Pills
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_items.length, (idx) {
                      final isSelected = idx == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isSelected ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.primaryColor
                              : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: _currentPage == _items.length - 1 ? 'Get Started' : 'Continue',
                    icon: _currentPage == _items.length - 1 ? Icons.arrow_forward : null,
                    onPressed: () {
                      if (_currentPage < _items.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                        );
                      } else {
                        _completeOnboarding();
                      }
                    },
                    height: 52,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAbstractGraphic(OnboardingItem item, bool isDark) {
    return Container(
      width: 240,
      height: 240,
      decoration: BoxDecoration(
        color: item.accentColor.withAlpha(isDark ? 25 : 12),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 170,
          height: 170,
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              width: 1.5,
            ),
            boxShadow: AppShadows.floating(isDark: isDark),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: item.accentColor.withAlpha(isDark ? 40 : 25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.icon,
                  size: 48,
                  color: item.accentColor,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: 60,
                height: 6,
                decoration: BoxDecoration(
                  color: item.accentColor.withAlpha(80),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String badgeText;
  final Color accentColor;

  const OnboardingItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badgeText,
    required this.accentColor,
  });
}
