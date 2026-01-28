/// App configuration settings.
///
/// Update these values based on your environment:
/// - For Android emulator: use 10.0.2.2 (maps to host localhost)
/// - For physical device: use your PC's local IP (e.g., 192.168.1.100)
/// - For production: use your server's public URL
class AppConfig {
  AppConfig._();

  /// WebSocket URL for the traffic backend.
  ///
  /// To find your PC's IP on Linux/Mac: `ip addr` or `ifconfig`
  /// To find your PC's IP on Windows: `ipconfig`
  ///
  /// Make sure your phone and PC are on the same WiFi network!
  static const String backendHost = '10.30.2.184'; // Your PC's local IP on wlan0
  static const int backendPort = 8000;

  static String get webSocketUrl => 'ws://$backendHost:$backendPort/ws/traffic';

  /// Whether to load mock data if backend connection fails.
  static const bool useMockDataFallback = true;

  /// Delay before loading mock data (gives backend time to connect).
  static const Duration mockDataDelay = Duration(seconds: 3);
}
