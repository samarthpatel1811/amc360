import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? company;
  final String? errorMessage;

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.company,
    this.errorMessage,
  });

  String get role => user?['role'] ?? 'admin';
  String get userName => user?['name'] ?? 'User';
  String get companyName => company?['name'] ?? 'Company';
  String get currencySymbol => company?['currency_symbol'] ?? '₹';

  bool get isAdmin => role == 'admin' || role == 'company_admin';
  bool get isTechnician => role == 'technician';
  bool get isCustomer => role == 'customer';

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    Map<String, dynamic>? user,
    Map<String, dynamic>? company,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      company: company ?? this.company,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  final ApiClient _api = ApiClient();

  @override
  AuthState build() {
    Future.microtask(() => checkSession());
    return AuthState(isLoading: true);
  }

  Future<void> checkSession() async {
    final token = await SecureStorageService.getToken();
    if (token == null) {
      state = AuthState(isAuthenticated: false, isLoading: false);
      return;
    }

    final user = await SecureStorageService.getUser();
    final company = await SecureStorageService.getCompany();

    if (user != null) {
      state = AuthState(
        isAuthenticated: true,
        isLoading: false,
        user: user,
        company: company,
      );
    } else {
      state = AuthState(isAuthenticated: false, isLoading: false);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _api.post('/auth/login', data: {
        'email': email.trim(),
        'password': password,
      });

      if (res.data['success'] == true) {
        final data = res.data['data'];
        final token = data['token'] as String;
        final user = data['user'] as Map<String, dynamic>;
        final company = data['company'] as Map<String, dynamic>?;

        await SecureStorageService.saveToken(token);
        await SecureStorageService.saveUser(user);
        if (company != null) {
          await SecureStorageService.saveCompany(company);
        }

        state = AuthState(
          isAuthenticated: true,
          isLoading: false,
          user: user,
          company: company,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: res.data['message'] ?? 'Login failed',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: ApiClient.formatError(e),
      );
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {}
    await SecureStorageService.clearSession();
    state = AuthState(isAuthenticated: false, isLoading: false);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
