import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/animated_counter.dart';
import '../../core/widgets/contract_health_ring.dart';
import '../../core/widgets/animated_revenue_chart.dart';
import '../../core/widgets/operations_timeline.dart';
import '../../core/widgets/floating_pill_nav_bar.dart';
import '../../core/widgets/quick_create_modal.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/error_state.dart';
import '../auth/auth_provider.dart';
import '../customers/customer_list_screen.dart';
import '../schedules/schedule_calendar_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _summary;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiClient().get('/dashboard/summary');
      if (res.data['success'] == true) {
        setState(() {
          _summary = res.data['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = res.data['message'] ?? 'Failed to load summary';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = [
      _buildDashboardHome(authState),
      const CustomerListScreen(),
      const ScheduleCalendarScreen(),
      _buildMoreMenu(authState),
    ];

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : const Color(0xFFF8FAFC),
      extendBody: true,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkBg : Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  authState.companyName,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            Text(
              authState.company?['business_type'] ?? 'Asset & Service Management',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => QuickCreateModal.show(context),
              backgroundColor: const Color(0xFF2563EB),
              elevation: 8,
              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
              label: Text(
                'Quick Create',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            )
          : null,
      bottomNavigationBar: FloatingPillNavBar(
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
        items: const [
          NavItem(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard_rounded,
            label: 'Command',
          ),
          NavItem(
            icon: Icons.people_outline_rounded,
            activeIcon: Icons.people_rounded,
            label: 'Clients & AMCs',
          ),
          NavItem(
            icon: Icons.calendar_month_outlined,
            activeIcon: Icons.calendar_month_rounded,
            label: 'Field',
          ),
          NavItem(
            icon: Icons.grid_view_outlined,
            activeIcon: Icons.grid_view_rounded,
            label: 'More',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardHome(AuthState authState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const LoadingState(message: 'Initializing Command Center...');
    }

    if (_errorMessage != null) {
      return ErrorState(message: _errorMessage!, onRetry: _fetchSummary);
    }

    final contracts = _summary?['contracts'] ?? {};
    final services = _summary?['services'] ?? {};
    final financials = _summary?['financials'] ?? {};
    final technicians = _summary?['technicians'] ?? {};

    final activeContractsCount = (contracts['active'] as num?)?.toInt() ?? 248;
    final expiringCount = (contracts['expiring_soon'] as num?)?.toInt() ?? 17;
    final expiredCount = (contracts['expired'] as num?)?.toInt() ?? 9;

    final todayVisitsCount = (services['today'] as num?)?.toInt() ?? 12;
    final overdueVisitsCount = (services['overdue'] as num?)?.toInt() ?? 3;

    final totalInvoiced = (financials['total_invoiced'] as num?)?.toDouble() ?? 184500.0;
    final activeTechs = (technicians['active'] as num?)?.toInt() ?? 6;
    final totalTechs = (technicians['total'] as num?)?.toInt() ?? 8;

    final timelineItems = [
      const TimelineOperationItem(
        time: '09:00 AM',
        customerName: 'ABC Industries Ltd',
        serviceType: 'Quarterly HVAC Comprehensive Service',
        technicianName: 'Rahul Verma',
        status: 'In Progress',
        statusColor: Color(0xFF2563EB),
      ),
      const TimelineOperationItem(
        time: '11:30 AM',
        customerName: 'Apex Health Systems',
        serviceType: 'Diesel Generator Preventive Inspection',
        technicianName: 'Arjun Nair',
        status: 'Scheduled',
        statusColor: Color(0xFF0D9488),
      ),
      const TimelineOperationItem(
        time: '02:15 PM',
        customerName: 'Metropolis Business Park',
        serviceType: 'Elevator Safety & Sensor Calibration',
        technicianName: 'Vikram Singh',
        status: 'Scheduled',
        statusColor: Color(0xFF8B5CF6),
      ),
      const TimelineOperationItem(
        time: '04:00 PM',
        customerName: 'Zenith Tech Hub',
        serviceType: 'Server Room Chiller Filter Check',
        technicianName: 'Rahul Verma',
        status: 'Scheduled',
        statusColor: Color(0xFF64748B),
      ),
    ];

    final userName = authState.user?['name']?.toString().split(' ').first ?? 'Alex';

    return RefreshIndicator(
      onRefresh: _fetchSummary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 100),
        children: [
          // Section 11: HERO COMMAND CARD
          _buildHeroSection(userName, activeContractsCount, isDark),

          const SizedBox(height: AppSpacing.lg),

          // Section 12: ANIMATED KPI GRID (2x2)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.12,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            children: [
              _buildAnimatedKpiCard(
                title: 'Active AMCs',
                value: activeContractsCount,
                subtitle: '$expiringCount expiring soon',
                icon: Icons.shield_outlined,
                color: const Color(0xFF2563EB),
                isDark: isDark,
                onTap: () => setState(() => _currentIndex = 1),
              ),
              _buildAnimatedKpiCard(
                title: "Today's Visits",
                value: todayVisitsCount,
                subtitle: '$overdueVisitsCount pending overdue',
                icon: Icons.calendar_month_outlined,
                color: const Color(0xFF0D9488),
                isDark: isDark,
                onTap: () => setState(() => _currentIndex = 2),
              ),
              _buildAnimatedKpiCard(
                title: 'Revenue Generated',
                value: totalInvoiced,
                isCurrency: true,
                subtitle: 'Collections on track',
                icon: Icons.account_balance_wallet_outlined,
                color: const Color(0xFF8B5CF6),
                isDark: isDark,
                onTap: () => context.push('/invoices'),
              ),
              _buildAnimatedKpiCard(
                title: 'Field Technicians',
                value: activeTechs,
                suffix: ' / $totalTechs',
                subtitle: 'Active dispatches',
                icon: Icons.engineering_outlined,
                color: const Color(0xFFF59E0B),
                isDark: isDark,
                onTap: () => context.push('/technicians'),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Section 13: CONTRACT HEALTH CARD
          ContractHealthRing(
            activeCount: activeContractsCount,
            expiringCount: expiringCount,
            expiredCount: expiredCount,
            percentage: 0.84,
          ),

          const SizedBox(height: AppSpacing.lg),

          // Section 14: TODAY'S OPERATIONS HORIZONTAL TIMELINE
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "TODAY'S OPERATIONS",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => setState(() => _currentIndex = 3),
                child: Text(
                  'View All (${timelineItems.length})',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          OperationsTimeline(items: timelineItems),

          const SizedBox(height: AppSpacing.lg),

          // Section 17: REVENUE PERFORMANCE CHART
          AnimatedRevenueChart(currentMonthRevenue: totalInvoiced),

          const SizedBox(height: AppSpacing.lg),

          // Section 16: EXPIRING CONTRACTS STACK
          _buildExpiringContractsCard(isDark),

          const SizedBox(height: AppSpacing.lg),

          // Section 18: QUICK ACTION CARDS
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'EXECUTIVE ACTIONS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _buildActionTileCard(
                  title: 'Add Client',
                  subtitle: 'Register organization',
                  icon: Icons.person_add_alt_1_outlined,
                  color: const Color(0xFF2563EB),
                  onTap: () => context.push('/customers/create'),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildActionTileCard(
                  title: 'Create AMC',
                  subtitle: 'Setup agreement terms',
                  icon: Icons.post_add_outlined,
                  color: const Color(0xFF0D9488),
                  onTap: () => context.push('/contracts/create'),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildActionTileCard(
                  title: 'Billing & Invoices',
                  subtitle: 'Financial ledger & PDFs',
                  icon: Icons.receipt_long_outlined,
                  color: const Color(0xFF8B5CF6),
                  onTap: () => context.push('/invoices'),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildActionTileCard(
                  title: 'Equipment Assets',
                  subtitle: 'Registry & QR codes',
                  icon: Icons.precision_manufacturing_outlined,
                  color: const Color(0xFFF59E0B),
                  onTap: () => context.push('/assets'),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(String userName, int activeCount, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: AppRadius.cardRadius,
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E3A8A),
            Color(0xFF2563EB),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withAlpha(isDark ? 80 : 50),
            blurRadius: 24,
            spreadRadius: -2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withAlpha(40)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF10B981),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'COMMAND CENTER ACTIVE',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.shield_outlined,
                color: Colors.white70,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          Text(
            '${_getGreeting()}, $userName',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your maintenance operation is running smoothly.',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withAlpha(210),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Big Metric Display & Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      AnimatedCounter(
                        value: activeCount,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Active Contracts',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.arrow_upward, size: 13, color: Color(0xFF34D399)),
                      const SizedBox(width: 4),
                      Text(
                        '12% this month',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF34D399),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () => setState(() => _currentIndex = 3),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0F172A),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'View Operations',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedKpiCard({
    required String title,
    required num value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
    bool isCurrency = false,
    String? suffix,
  }) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withAlpha(isDark ? 40 : 20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimatedCounter(
                    value: value,
                    isCurrency: isCurrency,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  if (suffix != null)
                    Text(
                      suffix,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpiringContractsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(20) : const Color(0xFFE2E8F0),
        ),
        boxShadow: AppShadows.card(isDark: isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withAlpha(isDark ? 45 : 20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.autorenew_outlined, size: 18, color: Color(0xFFF59E0B)),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'AMC EXPIRING SOON',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withAlpha(isDark ? 40 : 20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '12 Days Left',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'ABC Industries Ltd — Annual HVAC Agreement',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Contract #AMC-2025-0042 • 18 Assets covered • Due 30 Sep 2026',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.85,
              minHeight: 6,
              backgroundColor: isDark ? Colors.white.withAlpha(20) : const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Renewal Quote: ₹1,20,000',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                ),
              ),
              ElevatedButton(
                onPressed: () => context.push('/renewals'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Renew Now',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionTileCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(isDark ? 40 : 20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreMenu(AuthState authState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 100),
      children: [
        _buildMenuTile('Asset & Equipment Directory', Icons.precision_manufacturing_outlined, () => context.push('/assets')),
        _buildMenuTile('Technician Team & Skills', Icons.engineering_outlined, () => context.push('/technicians')),
        _buildMenuTile('Invoices & Billing', Icons.receipt_long_outlined, () => context.push('/invoices')),
        _buildMenuTile('Service Requests / Complaints', Icons.support_agent_outlined, () => context.push('/service-requests')),
        _buildMenuTile('Contract Renewals', Icons.autorenew_outlined, () => context.push('/renewals')),
        _buildMenuTile('Offline Sync Queue', Icons.sync_outlined, () => context.push('/sync')),
        _buildMenuTile('Company Settings & Theme', Icons.settings_outlined, () => context.push('/settings')),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          color: const Color(0xFFEF4444).withAlpha(isDark ? 25 : 15),
          border: Border.all(color: const Color(0xFFEF4444).withAlpha(isDark ? 60 : 30)),
          onTap: () async {
            await ref.read(authProvider.notifier).logout();
            if (mounted) context.go('/login');
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
              const SizedBox(width: 8),
              Text(
                'Sign Out of Command Center',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFEF4444),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuTile(String title, IconData icon, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withAlpha(isDark ? 40 : 18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF2563EB)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
        ],
      ),
    );
  }
}
