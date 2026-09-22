import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/empty_state.dart';

class CustomerDetailScreen extends StatefulWidget {
  final int customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _customer;
  List<dynamic> _assets = [];
  List<dynamic> _contracts = [];
  List<dynamic> _visits = [];
  List<dynamic> _invoices = [];

  @override
  void initState() {
    super.initState();
    // 5 tabs: Contracts (primary first), Equipment, Service History, Invoices, Profile Overview
    _tabController = TabController(length: 5, vsync: this);
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiClient().get('/customers/${widget.customerId}');
      final assetsRes = await ApiClient().get('/customers/${widget.customerId}/assets');
      final contractsRes = await ApiClient().get('/customers/${widget.customerId}/contracts');
      final visitsRes = await ApiClient().get('/customers/${widget.customerId}/visits');
      final invoicesRes = await ApiClient().get('/customers/${widget.customerId}/invoices');

      if (mounted) {
        setState(() {
          _customer = res.data['data'];
          _assets = assetsRes.data['data'] ?? [];
          _contracts = contractsRes.data['data'] ?? [];
          _visits = visitsRes.data['data'] ?? [];
          _invoices = invoicesRes.data['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        title: Text(
          _customer?['name'] ?? 'Client Profile',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchDetails,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingState(message: 'Loading client records...')
          : _errorMessage != null
              ? ErrorState(message: _errorMessage!, onRetry: _fetchDetails)
              : Column(
                  children: [
                    // Header Card (Client Info & Code)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(isDark ? 50 : 10),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB).withAlpha(isDark ? 40 : 20),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _customer?['customer_code'] ?? 'ID #${widget.customerId}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: Color(0xFF3B82F6),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                StatusBadge(status: _customer?['status'] ?? 'active'),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _customer?['name'] ?? '',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            if (_customer?['company_name'] != null && _customer!['company_name'].toString().isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                _customer!['company_name'],
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.phone_outlined, size: 14, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                const SizedBox(width: 4),
                                Text(
                                  _customer?['phone'] ?? 'N/A',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Icon(Icons.mail_outline_rounded, size: 14, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _customer?['email'] ?? 'N/A',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined, size: 14, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${_customer?['address_line_1'] ?? ''}, ${_customer?['city'] ?? ''}${_customer?['state'] != null ? ', ${_customer!['state']}' : ''}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Active AMC Contract Summary Hero
                    _buildActiveContractHero(isDark),

                    // Navigation Tabs: Contracts first!
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        border: Border(
                          bottom: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        labelColor: const Color(0xFF2563EB),
                        unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        indicatorColor: const Color(0xFF2563EB),
                        indicatorWeight: 3,
                        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500),
                        tabs: [
                          Tab(text: 'AMCs & Contracts (${_contracts.length})'),
                          Tab(text: 'Equipment (${_assets.length})'),
                          Tab(text: 'Service Visits (${_visits.length})'),
                          Tab(text: 'Invoices (${_invoices.length})'),
                          const Tab(text: 'Client Profile'),
                        ],
                      ),
                    ),

                    // Tab views: Contracts is child 0
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildContractList(isDark),
                          _buildAssetList(isDark),
                          _buildVisitList(isDark),
                          _buildInvoiceList(isDark),
                          _buildOverview(isDark),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildActiveContractHero(bool isDark) {
    final activeContract = _contracts.firstWhere(
      (c) => c['status'] == 'active',
      orElse: () => _contracts.isNotEmpty ? _contracts.first : null,
    );

    if (activeContract == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withAlpha(isDark ? 25 : 12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2563EB).withAlpha(40)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.shield_outlined, size: 18, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Text(
                    'No Active AMC on this Client ID',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () async {
                  await context.push('/contracts/create?customer_id=${widget.customerId}');
                  if (mounted) _fetchDetails();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '+ Add AMC',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final contractNumber = activeContract['contract_number'] ?? 'AMC';
    final title = activeContract['title'] ?? 'Comprehensive Maintenance Contract';
    final endDate = activeContract['end_date'] ?? '';
    final status = activeContract['status'] ?? 'active';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1E3A8A).withAlpha(120), const Color(0xFF0F172A)]
                : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF2563EB).withAlpha(80) : const Color(0xFFBFDBFE),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withAlpha(isDark ? 50 : 25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.verified_outlined, size: 20, color: Color(0xFF2563EB)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        contractNumber,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
                        ),
                      ),
                      const SizedBox(width: 6),
                      StatusBadge(status: status),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (endDate.isNotEmpty)
                    Text(
                      'Valid till: $endDate',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF065F46),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              color: isDark ? Colors.white70 : const Color(0xFF475569),
              onPressed: () => context.push('/contracts/${activeContract['id']}'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContractList(bool isDark) {
    if (_contracts.isEmpty) {
      return EmptyState(
        title: 'No maintenance contracts',
        message: 'No AMC contracts found for this customer.',
        icon: Icons.description_outlined,
        actionLabel: 'Create AMC Contract',
        onAction: () async {
          await context.push('/contracts/create?customer_id=${widget.customerId}');
          if (mounted) _fetchDetails();
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _contracts.length,
      itemBuilder: (context, idx) {
        final c = _contracts[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 40 : 8),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => context.push('/contracts/${c['id']}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      c['contract_number'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF3B82F6)),
                    ),
                    StatusBadge(status: c['status'] ?? 'active'),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  c['title'] ?? 'Maintenance Contract',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Duration: ${c['start_date']} to ${c['end_date']}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Frequency: ${c['service_frequency'] ?? 'Quarterly'}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '₹${c['total_price'] ?? '0.00'}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAssetList(bool isDark) {
    if (_assets.isEmpty) {
      return const EmptyState(
        title: 'No equipment recorded',
        message: 'No assets linked to this customer yet.',
        icon: Icons.precision_manufacturing_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _assets.length,
      itemBuilder: (context, idx) {
        final a = _assets[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: InkWell(
            onTap: () => context.push('/assets/${a['id']}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      a['asset_code'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF3B82F6)),
                    ),
                    StatusBadge(status: a['status'] ?? 'active'),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${a['brand'] ?? ''} • ${a['model'] ?? ''} (${a['asset_type'] ?? ''})',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'SN: ${a['serial_number'] ?? 'N/A'} • Location: ${a['location'] ?? 'On Site'}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVisitList(bool isDark) {
    if (_visits.isEmpty) {
      return const EmptyState(
        title: 'No completed visits',
        message: 'No service history records yet.',
        icon: Icons.history_toggle_off,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _visits.length,
      itemBuilder: (context, idx) {
        final v = _visits[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: InkWell(
            onTap: () => context.push('/service-visits/${v['id']}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      v['visit_number'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF3B82F6)),
                    ),
                    StatusBadge(status: v['status'] ?? 'completed'),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Report #: ${v['report_number'] ?? 'N/A'}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Technician: ${v['technician']?['name'] ?? 'N/A'} • Completed: ${v['completed_at'] ?? ''}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                  ),
                ),
                if (v['work_performed'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    v['work_performed'],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInvoiceList(bool isDark) {
    if (_invoices.isEmpty) {
      return const EmptyState(
        title: 'No invoices found',
        message: 'No invoices have been billed to this customer.',
        icon: Icons.receipt_long_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _invoices.length,
      itemBuilder: (context, idx) {
        final inv = _invoices[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: InkWell(
            onTap: () => context.push('/invoices/${inv['id']}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      inv['invoice_number'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF3B82F6)),
                    ),
                    StatusBadge(status: inv['status'] ?? 'issued'),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: ₹${inv['total_amount']}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Balance: ₹${inv['balance_due']}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: (num.tryParse(inv['balance_due'].toString()) ?? 0) > 0
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Issue: ${inv['issue_date']} • Due: ${inv['due_date']}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverview(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoTile('Client Name', _customer?['name'] ?? '', isDark),
        _buildInfoTile('Company / Entity', _customer?['company_name'] ?? 'N/A', isDark),
        _buildInfoTile('Customer Code', _customer?['customer_code'] ?? '', isDark),
        _buildInfoTile('Customer Type', _customer?['customer_type']?.toString().toUpperCase() ?? 'COMMERCIAL', isDark),
        _buildInfoTile('Primary Phone', _customer?['phone'] ?? '', isDark),
        _buildInfoTile('Alternate Phone', _customer?['alternate_phone'] ?? 'N/A', isDark),
        _buildInfoTile('Email Address', _customer?['email'] ?? 'N/A', isDark),
        _buildInfoTile('GST / Tax ID', _customer?['gst_number'] ?? 'N/A', isDark),
        _buildInfoTile('Address Line 1', _customer?['address_line_1'] ?? '', isDark),
        _buildInfoTile('City, State, Zip', '${_customer?['city'] ?? ''}, ${_customer?['state'] ?? ''} ${_customer?['postal_code'] ?? ''}', isDark),
        _buildInfoTile('Notes', _customer?['notes'] ?? 'No notes recorded.', isDark),
      ],
    );
  }

  Widget _buildInfoTile(String label, String value, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
