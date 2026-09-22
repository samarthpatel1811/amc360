import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/assets/asset_detail_screen.dart';
import '../../features/assets/asset_form_screen.dart';
import '../../features/assets/asset_list_screen.dart';
import '../../features/assets/qr_scanner_screen.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/contracts/contract_detail_screen.dart';
import '../../features/contracts/contract_form_screen.dart';
import '../../features/contracts/contract_list_screen.dart';
import '../../features/customers/customer_detail_screen.dart';
import '../../features/customers/customer_form_screen.dart';
import '../../features/customers/customer_list_screen.dart';
import '../../features/dashboard/admin_dashboard_screen.dart';
import '../../features/dashboard/customer_portal_screen.dart';
import '../../features/dashboard/technician_dashboard_screen.dart';
import '../../features/invoices/invoice_detail_screen.dart';
import '../../features/invoices/invoice_list_screen.dart';
import '../../features/invoices/payment_form_screen.dart';
import '../../features/notifications/notification_center_screen.dart';
import '../../features/offline/sync_status_screen.dart';
import '../../features/renewals/renewals_screen.dart';
import '../../features/schedules/schedule_calendar_screen.dart';
import '../../features/service_requests/service_request_detail_screen.dart';
import '../../features/service_requests/service_request_form_screen.dart';
import '../../features/service_requests/service_request_list_screen.dart';
import '../../features/service_visits/visit_execution_screen.dart';
import '../../features/service_visits/visit_list_screen.dart';
import '../../features/settings/company_settings_screen.dart';
import '../../features/technicians/technician_list_screen.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, __) {
      notifyListeners();
    });
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoggedIn = authState.isAuthenticated;
      final loc = state.matchedLocation;
      final isLoggingIn = loc == '/login';
      final isSplash = loc == '/splash';
      final isOnboarding = loc == '/onboarding';

      if (isSplash || isOnboarding) {
        return null;
      }

      if (!isLoggedIn) {
        return isLoggingIn ? null : '/login';
      }

      if (isLoggingIn) {
        if (authState.isAdmin) return '/dashboard/admin';
        if (authState.isTechnician) return '/dashboard/technician';
        if (authState.isCustomer) return '/dashboard/customer';
        return '/dashboard/admin';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Dashboards
      GoRoute(
        path: '/dashboard/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/dashboard/technician',
        builder: (context, state) => const TechnicianDashboardScreen(),
      ),
      GoRoute(
        path: '/dashboard/customer',
        builder: (context, state) => const CustomerPortalScreen(),
      ),

      // Customers
      GoRoute(
        path: '/customers',
        builder: (context, state) => const CustomerListScreen(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (context, state) => const CustomerFormScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return CustomerDetailScreen(customerId: id);
            },
          ),
          GoRoute(
            path: ':id/edit',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return CustomerFormScreen(customerId: id);
            },
          ),
        ],
      ),

      // Assets
      GoRoute(
        path: '/assets',
        builder: (context, state) => const AssetListScreen(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (context, state) => const AssetFormScreen(),
          ),
          GoRoute(
            path: 'scan',
            builder: (context, state) => const QrScannerScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return AssetDetailScreen(assetId: id);
            },
          ),
          GoRoute(
            path: ':id/edit',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return AssetFormScreen(assetId: id);
            },
          ),
        ],
      ),

      // Contracts
      GoRoute(
        path: '/contracts',
        builder: (context, state) => const ContractListScreen(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (context, state) {
              final customerId = int.tryParse(state.uri.queryParameters['customer_id'] ?? '') ??
                  (state.extra is Map ? (state.extra as Map)['customer_id'] as int? : null);
              return ContractFormScreen(prefillCustomerId: customerId);
            },
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return ContractDetailScreen(contractId: id);
            },
          ),
        ],
      ),

      // Schedules
      GoRoute(
        path: '/schedules',
        builder: (context, state) => const ScheduleCalendarScreen(),
      ),

      // Service Visits
      GoRoute(
        path: '/visits',
        builder: (context, state) => const VisitListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return VisitExecutionScreen(visitId: id);
            },
          ),
        ],
      ),

      // Service Requests
      GoRoute(
        path: '/service-requests',
        builder: (context, state) => const ServiceRequestListScreen(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (context, state) => const ServiceRequestFormScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return ServiceRequestDetailScreen(requestId: id);
            },
          ),
        ],
      ),

      // Invoices
      GoRoute(
        path: '/invoices',
        builder: (context, state) => const InvoiceListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return InvoiceDetailScreen(invoiceId: id);
            },
          ),
          GoRoute(
            path: ':id/payment',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              final invoiceData = state.extra as Map<String, dynamic>?;
              return PaymentFormScreen(invoiceId: id, invoiceData: invoiceData);
            },
          ),
        ],
      ),

      // Technicians
      GoRoute(
        path: '/technicians',
        builder: (context, state) => const TechnicianListScreen(),
      ),

      // Renewals
      GoRoute(
        path: '/renewals',
        builder: (context, state) => const RenewalsScreen(),
      ),

      // Offline Sync
      GoRoute(
        path: '/sync',
        builder: (context, state) => const SyncStatusScreen(),
      ),

      // Settings
      GoRoute(
        path: '/settings',
        builder: (context, state) => const CompanySettingsScreen(),
      ),

      // Notifications
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationCenterScreen(),
      ),
    ],
  );
});
