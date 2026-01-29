import 'dart:async';
import 'package:flutter/foundation.dart';
import '../config.dart';
import '../models/traffic_update.dart';
import '../models/user_location.dart';
import '../services/location_service.dart';
import '../services/traffic_service.dart';
import '../services/tts_service.dart';

/// Main application state provider.
///
/// Manages the app's state including location, traffic data, and TTS.
/// Uses ChangeNotifier for reactive UI updates.
class AppProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  final TrafficService _trafficService = TrafficService();
  final TtsService _ttsService = TtsService();

  // Subscriptions
  StreamSubscription<UserLocation>? _locationSubscription;
  StreamSubscription<TrafficUpdate>? _trafficSubscription;
  StreamSubscription<ConnectionState>? _connectionSubscription;
  StreamSubscription<TtsState>? _ttsSubscription;

  // State
  UserLocation? _userLocation;
  List<TrafficUpdate> _trafficUpdates = [];
  ConnectionState _connectionState = ConnectionState.disconnected;
  TtsState _ttsState = TtsState.stopped;
  bool _isInitialized = false;
  String? _error;
  String _username = 'John';

  // Getters
  UserLocation? get userLocation => _userLocation;
  List<TrafficUpdate> get trafficUpdates => _trafficUpdates;
  ConnectionState get connectionState => _connectionState;
  TtsState get ttsState => _ttsState;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  bool get isConnected => _connectionState == ConnectionState.connected;
  bool get isSpeaking => _ttsState == TtsState.speaking;
  String get username => _username;

  /// Sets the user's name.
  void setUsername(String name) {
    _username = name;
    notifyListeners();
  }

  /// Initializes all services and starts tracking.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize TTS
      await _ttsService.initialize();

      // Set up location stream
      _locationSubscription = _locationService.locationStream.listen(
        (location) {
          _userLocation = location;
          notifyListeners();
        },
        onError: (e) {
          _error = 'Location error: $e';
          notifyListeners();
        },
      );

      // Set up traffic stream
      _trafficSubscription = _trafficService.trafficStream.listen(
        (update) {
          _trafficUpdates = _trafficService.recentUpdates;
          notifyListeners();
        },
        onError: (e) {
          _error = 'Traffic error: $e';
          notifyListeners();
        },
      );

      // Set up connection stream
      _connectionSubscription = _trafficService.connectionStream.listen(
        (state) {
          _connectionState = state;
          notifyListeners();
        },
      );

      // Set up TTS stream
      _ttsSubscription = _ttsService.stateStream.listen(
        (state) {
          _ttsState = state;
          notifyListeners();
        },
      );

      // Get initial location
      _userLocation = await _locationService.getCurrentLocation();

      // Start location tracking
      await _locationService.startTracking();

      // Connect to traffic backend
      await _trafficService.connect();

      // If backend connection fails, add mock data for demo
      if (AppConfig.useMockDataFallback) {
        Future.delayed(AppConfig.mockDataDelay, () {
          if (_trafficUpdates.isEmpty) {
            _trafficService.addMockData();
            _trafficUpdates = _trafficService.recentUpdates;
            notifyListeners();
          }
        });
      }

      _isInitialized = true;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Initialization error: $e';
      notifyListeners();
    }
  }

  /// Sets the WebSocket URL for the traffic service.
  void setWebSocketUrl(String url) {
    _trafficService.setWebSocketUrl(url);
  }

  /// Speaks a traffic alert.
  Future<void> speakAlert(String message, {bool interrupt = true}) async {
    await _ttsService.speak(message, interrupt: interrupt);
  }

  /// Stops TTS playback.
  Future<void> stopSpeaking() async {
    await _ttsService.stop();
  }

  /// Requests location permissions.
  Future<bool> requestLocationPermission() async {
    return await _locationService.requestPermissions();
  }

  /// Opens location settings.
  Future<void> openLocationSettings() async {
    await _locationService.openLocationSettings();
  }

  /// Reconnects to the traffic service.
  Future<void> reconnect() async {
    await _trafficService.disconnect();
    await _trafficService.connect();
  }

  /// Adds mock data for testing.
  void loadMockData() {
    _trafficService.addMockData();
    _trafficUpdates = _trafficService.recentUpdates;
    notifyListeners();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _trafficSubscription?.cancel();
    _connectionSubscription?.cancel();
    _ttsSubscription?.cancel();
    _locationService.dispose();
    _trafficService.dispose();
    _ttsService.dispose();
    super.dispose();
  }
}
