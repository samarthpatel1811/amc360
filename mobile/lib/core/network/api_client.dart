import 'dart:io';
import 'package:dio/dio.dart';
import '../../app/configuration/app_config.dart';
import '../storage/secure_storage_service.dart';

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final dynamic errors;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic)? transform) {
    return ApiResponse(
      success: json['success'] == true,
      message: json['message'] ?? '',
      data: json['data'] != null && transform != null ? transform(json['data']) : json['data'] as T?,
      errors: json['errors'],
    );
  }
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  static String get baseAssetUrl => AppConfig.apiBaseUrl.replaceAll('/api/v1', '');

  late final Dio dio;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 7),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    // Add interceptors
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          String userFriendlyMessage = 'Something went wrong. Please try again.';

          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.sendTimeout ||
              e.type == DioExceptionType.connectionError ||
              e.error is SocketException) {
            final host = AppConfig.apiBaseUrl.replaceAll('/api/v1', '');
            userFriendlyMessage = 'Unable to connect to $host. Please check server status and Wi-Fi connection.';
          } else if (e.response != null) {
            final data = e.response?.data;
            if (data is Map<String, dynamic> && data['message'] != null) {
              userFriendlyMessage = data['message'].toString();
            } else if (e.response?.statusCode == 401) {
              userFriendlyMessage = 'Session expired or invalid credentials.';
            } else if (e.response?.statusCode == 403) {
              userFriendlyMessage = 'You do not have permission to perform this action.';
            } else if (e.response?.statusCode == 404) {
              userFriendlyMessage = 'Requested record not found.';
            }
          }

          final customError = DioException(
            requestOptions: e.requestOptions,
            response: e.response,
            type: e.type,
            error: userFriendlyMessage,
            message: userFriendlyMessage,
          );

          return handler.next(customError);
        },
      ),
    );
  }

  static String formatError(dynamic error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.error is SocketException) {
        final host = AppConfig.apiBaseUrl.replaceAll('/api/v1', '');
        return 'Cannot connect to backend ($host).\n• Ensure the backend server is running (python3 server.py)\n• If using Wi-Fi, ensure your phone and Mac are on the same network.';
      }
      if (error.response?.data is Map<String, dynamic>) {
        final data = error.response!.data as Map<String, dynamic>;
        if (data['message'] != null) return data['message'].toString();
      }
      if (error.message != null && error.message!.isNotEmpty) {
        return error.message!;
      }
    }
    return error.toString().replaceAll('Exception: ', '');
  }

  /// Pings a candidate backend base URL to check reachability and return latency
  static Future<Map<String, dynamic>> checkConnection(String baseUrl) async {
    final cleanUrl = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final testDio = Dio(
      BaseOptions(
        baseUrl: cleanUrl,
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 3),
        headers: {
          'Accept': 'application/json',
        },
      ),
    );
    final sw = Stopwatch()..start();
    try {
      final res = await testDio.get('/auth/public-info');
      sw.stop();
      if (res.statusCode == 200) {
        final data = res.data is Map<String, dynamic> ? res.data['data'] : null;
        return {
          'success': true,
          'latencyMs': sw.elapsedMilliseconds,
          'companyName': data?['company_name'] ?? 'AMC360 Platform',
          'adminEmail': data?['admin_email'] ?? '',
        };
      }
      return {
        'success': false,
        'error': 'Server returned HTTP ${res.statusCode}',
      };
    } catch (e) {
      sw.stop();
      if (e is DioException) {
        return {
          'success': false,
          'error': 'Unreachable: ${e.type.name}',
        };
      }
      return {
        'success': false,
        'error': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  void updateBaseUrl(String url) {
    dio.options.baseUrl = url;
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return await dio.put(path, data: data);
  }

  Future<Response> delete(String path) async {
    return await dio.delete(path);
  }
}
