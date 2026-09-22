import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';

class AppConfig {
  static const String appName = 'AMC360';
  static const String appTagline = 'AMC, Asset & Service Management';
  static const String appVersion = 'v1.0.0';

  // Network environment presets
  static const String cloudApiUrl = 'https://amc360.onrender.com/api/v1';
  static const String currentWifiUrl = 'http://10.20.57.32:8000/api/v1';
  static const String localhostUrl = 'http://127.0.0.1:8000/api/v1';
  static const String androidEmulatorUrl = 'http://10.0.2.2:8000/api/v1';
  static const String localWifiUrl = currentWifiUrl;

  // Active API base URL (defaults to 24/7 permanent Cloud URL)
  static String apiBaseUrl = cloudApiUrl;

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString('api_base_url');
      if (savedUrl != null && savedUrl.isNotEmpty) {
        // Guard: If saved URL is an expired tunnel, reset to cloud URL
        if (savedUrl.contains('trycloudflare.com')) {
          apiBaseUrl = cloudApiUrl;
          await prefs.setString('api_base_url', cloudApiUrl);
        } else {
          apiBaseUrl = savedUrl;
        }
      } else {
        apiBaseUrl = cloudApiUrl;
      }
    } catch (_) {}
  }

  static Future<void> setApiUrl(String url) async {
    if (url.isNotEmpty) {
      apiBaseUrl = url.trim();
      ApiClient().updateBaseUrl(apiBaseUrl);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('api_base_url', apiBaseUrl);
      } catch (_) {}
    }
  }

  static Future<void> resetToDefault() async {
    apiBaseUrl = currentWifiUrl;
    ApiClient().updateBaseUrl(apiBaseUrl);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('api_base_url');
    } catch (_) {}
  }
}
