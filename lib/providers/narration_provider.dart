import 'dart:async';
import 'package:flutter/material.dart';
import '../services/narration_service.dart';
import '../services/audio_manager.dart';

/// Provider that coordinates between navigation and TTS.
///
/// Flow:
/// 1. NavigationProvider calls onApproachingCheckpoint(intersectionId)
/// 2. NarrationService connects to backend for that intersection
/// 3. SLM generates narration → TTS speaks it
/// 4. TTS enabled only when navigation is active
class NarrationProvider with ChangeNotifier {
  final NarrationService _narrationService = NarrationService();
  final AudioManager _audioManager = AudioManager();

  StreamSubscription<String>? _narrationSubscription;

  int _selectedIntersection = 1;
  int get selectedIntersection => _selectedIntersection;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // TTS enabled when navigation is active
  bool _ttsEnabled = false;
  bool get ttsEnabled => _ttsEnabled;

  String _lastNarration = "";
  String get lastNarration => _lastNarration;

  String _connectionStatus = "Ready";
  String get connectionStatus => _connectionStatus;

  NarrationProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      await _audioManager.init();
      _isInitialized = true;
      print("NarrationProvider: Initialized successfully");

      // Subscribe to narration updates from the service
      _narrationSubscription = _narrationService.narrationStream.listen(
        (narrationText) {
          _processNarration(narrationText);
        },
        onError: (e) {
          print("NarrationProvider: Narration stream error: $e");
          _connectionStatus = "Error: $e";
          notifyListeners();
        },
      );

      notifyListeners();
    } catch (e) {
      print("NarrationProvider: Init error: $e");
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Called when navigation starts - enables TTS
  void onNavigationStarted() {
    _ttsEnabled = true;
    _connectionStatus = "Navigation active";
    print("NarrationProvider: Navigation started, TTS enabled");
    notifyListeners();
  }

  /// Called when navigation stops - disables TTS
  void onNavigationStopped() {
    _ttsEnabled = false;
    _audioManager.stopSpeaking();
    _connectionStatus = "Navigation paused";
    print("NarrationProvider: Navigation stopped, TTS disabled");
    notifyListeners();
  }

  /// Called when approaching a checkpoint - switch to that intersection's narration
  void onApproachingCheckpoint(int intersectionId) {
    if (intersectionId < 1 || intersectionId > 5) return;

    print("NarrationProvider: Approaching checkpoint $intersectionId");
    _selectedIntersection = intersectionId;

    // Connect to backend for this intersection
    _narrationService.start(intersectionId: intersectionId);
    _isConnected = true;
    _connectionStatus = "Checkpoint $intersectionId";
    notifyListeners();
  }

  /// Stop monitoring (when navigation ends)
  void stopMonitoring() {
    _narrationService.stop();
    _audioManager.stopSpeaking();
    _isConnected = false;
    _ttsEnabled = false;
    _connectionStatus = "Ready";
    notifyListeners();
  }

  /// Process incoming narration text from the backend.
  Future<void> _processNarration(String narrationText) async {
    try {
      print("NarrationProvider: Received narration: $narrationText");
      _lastNarration = narrationText;
      notifyListeners();

      // Only speak if TTS is enabled (navigation active)
      if (_ttsEnabled) {
        print("NarrationProvider: Speaking narration via TTS...");
        await _audioManager.speak(narrationText);
        print("NarrationProvider: TTS completed");
      } else {
        print("NarrationProvider: TTS disabled, not speaking");
      }
    } catch (e) {
      print("NarrationProvider: Process narration error: $e");
    }
  }

  /// Mock an SLM response manually (for demo purposes)
  Future<void> mockSLMResponse(String message) async {
    print("NarrationProvider: Mocking SLM response: $message");
    // Force TTS enablement for this mock message if not already enabled
    bool originallyEnabled = _ttsEnabled;
    if (!_ttsEnabled) {
      _ttsEnabled = true;
    }

    await _processNarration(message);

    // Restore TTS state if it was disabled
    if (!originallyEnabled) {
      // Small delay to ensure speech starts before disabling (though processNarration awaits speak)
      // Actually _processNarration awaits _audioManager.speak, so it should be fine.
      // But if we want to leave it enabled for the duration of the speech, that's handled by await.
      _ttsEnabled = false;
    }
  }

  @override
  void dispose() {
    _narrationSubscription?.cancel();
    _narrationService.dispose();
    super.dispose();
  }
}
