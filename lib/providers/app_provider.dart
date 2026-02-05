import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_location.dart';
import '../services/location_service.dart';
import '../services/tts_service.dart';

/// Main application state provider.
/// Manages location, TTS, and user preferences.
class AppProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  final TtsService _ttsService = TtsService();

  StreamSubscription<UserLocation>? _locationSubscription;
  StreamSubscription<TtsState>? _ttsSubscription;

  UserLocation? _userLocation;
  TtsState _ttsState = TtsState.stopped;
  bool _isInitialized = false;
  String? _error;
  String? _username;

  static const String _usernameKey = 'username';

  UserLocation? get userLocation => _userLocation;
  TtsState get ttsState => _ttsState;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  bool get isSpeaking => _ttsState == TtsState.speaking;
  String get username => _username ?? 'Friend';
  bool get hasCompletedOnboarding => _username != null;

  Future<void> loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString(_usernameKey);
    notifyListeners();
  }

  Future<void> setUsername(String name) async {
    _username = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, name);
    notifyListeners();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _ttsService.initialize();

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

      _ttsSubscription = _ttsService.stateStream.listen(
        (state) {
          _ttsState = state;
          notifyListeners();
        },
      );

      _userLocation = await _locationService.getCurrentLocation();
      await _locationService.startTracking();

      _isInitialized = true;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Initialization error: $e';
      notifyListeners();
    }
  }

  Future<void> speakAlert(String message, {bool interrupt = true}) async {
    await _ttsService.speak(message, interrupt: interrupt);
  }

  Future<void> stopSpeaking() async {
    await _ttsService.stop();
  }

  Future<bool> requestLocationPermission() async {
    return await _locationService.requestPermissions();
  }

  Future<void> openLocationSettings() async {
    await _locationService.openLocationSettings();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _ttsSubscription?.cancel();
    _locationService.dispose();
    _ttsService.dispose();
    super.dispose();
  }
}
