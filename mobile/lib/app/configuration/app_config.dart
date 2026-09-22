import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';

class AppConfig {
  static const String appName = 'AMC360';
  static const String appTagline = 'AMC, Asset & Service Management';
  static const String appVersion = 'v1.0.0';

  // Network environment presets
  static const String currentWifiUrl = 'http://10.20.57.32:8000/api/v1';
  static const String localhostUrl = 'http://127.0.0.1:8000/api/v1';
  static const String androidEmulatorUrl = 'http://10.0.2.2:8000/api/v1';
  static const String localWifiUrl = currentWifiUrl;

  // Active API base URL (defaults to current host Wi-Fi IP)
  static String apiBaseUrl = currentWifiUrl;

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString('api_base_url');
      if (savedUrl != null && savedUrl.isNotEmpty) {
        // Guard: If saved URL is an expired trycloudflare.com tunnel, reset to active Wi-Fi
        if (savedUrl.contains('est-studios-roads-investigator.trycloudflare.com')) {
          apiBaseUrl = currentWifiUrl;
          await prefs.setString('api_base_url', currentWifiUrl);
        } else {
          apiBaseUrl = savedUrl;
        }
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
