import 'package:flutter/foundation.dart' show kIsWeb;

/// App configuration settings.
class AppConfig {
  AppConfig._();

  static const String _backendHostOverride = String.fromEnvironment(
    'BACKEND_HOST',
    defaultValue: '',
  );

  static const int backendPort = int.fromEnvironment(
    'BACKEND_PORT',
    defaultValue: 8000,
  );

  static const String apiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: 'headsup-dev-key',
  );

  /// Backend host - auto-detects based on platform:
  /// - Web: localhost
  /// - Android emulator: 10.0.2.2
  /// - Override with --dart-define=BACKEND_HOST=<ip>
  static String get backendHost {
    if (_backendHostOverride.isNotEmpty) {
      return _backendHostOverride;
    }
    if (kIsWeb) {
      return 'localhost';
    }
    // Android emulator uses 10.0.2.2 to reach host machine
    return '10.0.2.2';
  }

  static String get baseUrl => 'http://$backendHost:$backendPort';
}
