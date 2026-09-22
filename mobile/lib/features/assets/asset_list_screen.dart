import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_search_bar.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/error_state.dart';

class AssetListScreen extends StatefulWidget {
  const AssetListScreen({super.key});

  @override
  State<AssetListScreen> createState() => _AssetListScreenState();
}

class _AssetListScreenState extends State<AssetListScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _assets = [];

  @override
  void initState() {
    super.initState();
    _fetchAssets();
  }

  Future<void> _fetchAssets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final query = <String, dynamic>{};
      if (_searchController.text.isNotEmpty) {
        query['search'] = _searchController.text;
      }

      final res = await ApiClient().get('/assets', queryParameters: query);
      if (res.data['success'] == true) {
        setState(() {
          _assets = res.data['data']['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = res.data['message'] ?? 'Failed to load assets';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('ac') || lower.contains('hvac') || lower.contains('air')) {
      return Icons.ac_unit_rounded;
    } else if (lower.contains('gen') || lower.contains('dg') || lower.contains('power')) {
      return Icons.bolt_rounded;
    } else if (lower.contains('lift') || lower.contains('elevator')) {
      return Icons.elevator_outlined;
    } else if (lower.contains('solar')) {
      return Icons.solar_power_outlined;
    } else if (lower.contains('cctv') || lower.contains('camera')) {
      return Icons.videocam_outlined;
    } else if (lower.contains('water') || lower.contains('ro') || lower.contains('purifier')) {
      return Icons.water_drop_outlined;
    } else if (lower.contains('fire')) {
      return Icons.local_fire_department_outlined;
    }
    return Icons.precision_manufacturing_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Asset & Equipment Registry',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Scan QR Code',
            onPressed: () => context.push('/assets/scan-qr'),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Equipment',
            onPressed: () async {
              final created = await context.push<bool>('/assets/create');
              if (created == true) _fetchAssets();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            color: isDark ? AppTheme.darkBg : Colors.white,
            child: AppSearchBar(
              controller: _searchController,
              hintText: 'Search asset code, serial, brand or model...',
              onChanged: (val) {
                Future.delayed(const Duration(milliseconds: 350), _fetchAssets);
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const LoadingState(message: 'Loading equipment catalog...')
                : _errorMessage != null
                    ? ErrorState(message: _errorMessage!, onRetry: _fetchAssets)
                    : _assets.isEmpty
                        ? EmptyState(
                            title: 'No equipment recorded',
                            message: 'Add customer machinery to track maintenance visits and contract coverage.',
                            icon: Icons.precision_manufacturing_outlined,
                            actionLabel: 'Add Asset',
                            onAction: () async {
                              final created = await context.push<bool>('/assets/create');
                              if (created == true) _fetchAssets();
                            },
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchAssets,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 100),
                              cacheExtent: 500,
                              itemCount: _assets.length,
                              itemBuilder: (context, idx) {
                                final a = _assets[idx];
                                return _buildAssetCard(context, a, isDark);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetCard(BuildContext context, dynamic a, bool isDark) {
    final cust = a['customer'] ?? {};
    final assetType = a['asset_type']?.toString() ?? 'Equipment';
    final brand = a['brand']?.toString() ?? '';
    final model = a['model']?.toString() ?? '';
    final serial = a['serial_number']?.toString() ?? 'SN-UNKNOWN';
    final code = a['asset_code']?.toString() ?? 'EQ-000';
    final status = a['status']?.toString() ?? 'active';

    final categoryIcon = _getCategoryIcon(assetType);

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => context.push('/assets/${a['id']}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Category Icon, Asset Code Pill, Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withAlpha(isDark ? 40 : 18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(categoryIcon, color: const Color(0xFF2563EB), size: 20),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            code,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        assetType,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              StatusBadge(status: status),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Title & Serial Number
          Text(
            '$brand $model'.trim().isEmpty ? assetType : '$brand $model',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Client: ${cust['name'] ?? 'Corporate Client'}${cust['company_name'] != null ? ' (${cust['company_name']})' : ''}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Serial Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withAlpha(8) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.qr_code_2_rounded, size: 13, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(
                  'SN: $serial',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Section 26: Last Service & Next Service schedule box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withAlpha(6) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white.withAlpha(10) : const Color(0xFFF1F5F9),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LAST SERVICE',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '05 Sep 2026',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: isDark ? Colors.white.withAlpha(20) : const Color(0xFFE2E8F0),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'NEXT SERVICE',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '05 Dec 2026',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2563EB),
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
  }
}
