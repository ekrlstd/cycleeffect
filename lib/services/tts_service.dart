import 'dart:async';
import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';

/// Service for text-to-speech functionality.
///
/// Handles AI narration of traffic alerts using the device's TTS engine.
class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  final StreamController<TtsState> _stateController =
      StreamController<TtsState>.broadcast();

  /// Stream of TTS state changes.
  Stream<TtsState> get stateStream => _stateController.stream;

  /// Current TTS state.
  TtsState _currentState = TtsState.stopped;
  TtsState get currentState => _currentState;

  /// Queue of messages to speak.
  final List<String> _messageQueue = [];

  /// Whether TTS is initialized successfully.
  bool _isInitialized = false;
  bool get isAvailable => _isInitialized;

  /// Initializes the TTS engine with default settings.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // On Android, try to find an available engine
      if (Platform.isAndroid) {
        final engines = await _flutterTts.getEngines;
        if (engines == null || engines.isEmpty) {
          print('TTS: No engines available on this device');
          return;
        }
        print('TTS: Available engines: $engines');

        // Try Google TTS first, otherwise use the first available
        if (engines.contains('com.google.android.tts')) {
          await _flutterTts.setEngine('com.google.android.tts');
        } else {
          // Use default engine (first available)
          await _flutterTts.setEngine(engines.first as String);
        }
      }

      // Set language - try common ones
      final languages = await _flutterTts.getLanguages;
      print('TTS: Available languages: $languages');

      if (languages != null) {
        if (languages.contains('en-US')) {
          await _flutterTts.setLanguage('en-US');
        } else if (languages.contains('en-GB')) {
          await _flutterTts.setLanguage('en-GB');
        } else if (languages.contains('en')) {
          await _flutterTts.setLanguage('en');
        }
      }

      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      // Set up callbacks
      _flutterTts.setStartHandler(() {
        _setState(TtsState.speaking);
      });

      _flutterTts.setCompletionHandler(() {
        _setState(TtsState.stopped);
        _processQueue();
      });

      _flutterTts.setCancelHandler(() {
        _setState(TtsState.stopped);
      });

      _flutterTts.setErrorHandler((message) {
        print('TTS Error: $message');
        _setState(TtsState.stopped);
        _processQueue();
      });

      _isInitialized = true;
      print('TTS: Initialized successfully');
    } catch (e) {
      print('TTS initialization error: $e');
      _isInitialized = false;
    }
  }

  /// Speaks the given text.
  ///
  /// If [interrupt] is true, stops any current speech first.
  /// Otherwise, adds to queue.
  Future<void> speak(String text, {bool interrupt = false}) async {
    if (!_isInitialized) {
      await initialize();
    }

    // If still not initialized, TTS is unavailable
    if (!_isInitialized) {
      print('TTS: Cannot speak - TTS not available');
      return;
    }

    if (interrupt) {
      await stop();
      _messageQueue.clear();
    }

    if (_currentState == TtsState.speaking) {
      _messageQueue.add(text);
    } else {
      await _speak(text);
    }
  }

  /// Internal speak method.
  Future<void> _speak(String text) async {
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      print('TTS speak error: $e');
    }
  }

  /// Processes the message queue.
  void _processQueue() {
    if (_messageQueue.isNotEmpty && _currentState == TtsState.stopped) {
      final nextMessage = _messageQueue.removeAt(0);
      _speak(nextMessage);
    }
  }

  /// Stops any current speech.
  Future<void> stop() async {
    if (!_isInitialized) return;
    try {
      await _flutterTts.stop();
    } catch (e) {
      print('TTS stop error: $e');
    }
    _setState(TtsState.stopped);
  }

  /// Pauses current speech (if supported).
  Future<void> pause() async {
    if (!_isInitialized) return;
    try {
      await _flutterTts.pause();
      _setState(TtsState.paused);
    } catch (e) {
      print('TTS pause error: $e');
    }
  }

  /// Sets the speech rate (0.0 to 1.0).
  Future<void> setSpeechRate(double rate) async {
    if (!_isInitialized) return;
    await _flutterTts.setSpeechRate(rate.clamp(0.0, 1.0));
  }

  /// Sets the volume (0.0 to 1.0).
  Future<void> setVolume(double volume) async {
    if (!_isInitialized) return;
    await _flutterTts.setVolume(volume.clamp(0.0, 1.0));
  }

  /// Updates the state and notifies listeners.
  void _setState(TtsState state) {
    _currentState = state;
    _stateController.add(state);
  }

  /// Disposes of resources.
  void dispose() {
    if (_isInitialized) {
      _flutterTts.stop();
    }
    _stateController.close();
  }
}

/// TTS engine states.
enum TtsState {
  stopped,
  speaking,
  paused,
}
