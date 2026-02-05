import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_tts/flutter_tts.dart';

// For non-web platforms
import 'tts_service_native.dart' if (dart.library.html) 'tts_service_web_stub.dart';

/// TTS service that works on all platforms.
///
/// On mobile/desktop: Uses sherpa-onnx neural TTS with flutter_tts fallback.
/// On web: Uses flutter_tts only.
class TtsService {
  final StreamController<TtsState> _stateController =
      StreamController<TtsState>.broadcast();

  Stream<TtsState> get stateStream => _stateController.stream;

  TtsState _currentState = TtsState.stopped;
  TtsState get currentState => _currentState;

  final List<String> _messageQueue = [];

  bool _isInitialized = false;
  bool get isAvailable => _isInitialized;

  bool _isNeuralReady = false;
  bool get isNeuralReady => _isNeuralReady;

  bool _isDownloading = false;
  bool get isDownloading => _isDownloading;

  double _downloadProgress = 0.0;
  double get downloadProgress => _downloadProgress;

  // Platform-specific implementation
  NativeTtsEngine? _nativeEngine;
  FlutterTts? _fallbackTts;

  double _speed = 1.0;

  /// Initializes TTS with fallback support.
  Future<void> initialize({bool autoDownload = true}) async {
    if (_isInitialized) return;

    try {
      // Initialize fallback TTS first (works on all platforms)
      await _initFallbackTts();
      _isInitialized = true;

      // On non-web platforms, try to initialize neural TTS
      if (!kIsWeb) {
        _nativeEngine = NativeTtsEngine();
        _isNeuralReady = await _nativeEngine!.isModelReady();

        if (_isNeuralReady) {
          await _nativeEngine!.initialize();
          _nativeEngine!.onComplete = () {
            _setState(TtsState.stopped);
            _processQueue();
          };
        } else if (autoDownload) {
          _downloadModelInBackground();
        }
      }

      print('TTS: Initialized (neural: $_isNeuralReady, web: $kIsWeb)');
    } catch (e) {
      print('TTS initialization error: $e');
      _isInitialized = false;
    }
  }

  Future<void> _initFallbackTts() async {
    _fallbackTts = FlutterTts();

    try {
      await _fallbackTts!.setLanguage('en-US');
      await _fallbackTts!.setSpeechRate(0.5);
      await _fallbackTts!.setVolume(1.0);
      await _fallbackTts!.setPitch(1.0);

      _fallbackTts!.setCompletionHandler(() {
        _setState(TtsState.stopped);
        _processQueue();
      });

      print('TTS: Fallback TTS ready');
    } catch (e) {
      print('TTS: Fallback init error: $e');
    }
  }

  void _downloadModelInBackground() {
    if (_nativeEngine == null) return;

    _isDownloading = true;
    _nativeEngine!.downloadModel().listen(
      (progress) {
        _downloadProgress = progress;
      },
      onDone: () async {
        _isDownloading = false;
        _isNeuralReady = await _nativeEngine!.isModelReady();
        if (_isNeuralReady) {
          await _nativeEngine!.initialize();
          _nativeEngine!.onComplete = () {
            _setState(TtsState.stopped);
            _processQueue();
          };
        }
      },
      onError: (e) {
        print('TTS: Background download error: $e');
        _isDownloading = false;
      },
    );
  }

  /// Downloads the neural model manually.
  Stream<double> downloadModel() async* {
    if (kIsWeb || _nativeEngine == null) {
      yield 1.0;
      return;
    }
    yield* _nativeEngine!.downloadModel();
  }

  /// Speaks the given text.
  Future<void> speak(String text, {bool interrupt = false}) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_isInitialized) {
      print('TTS: Cannot speak - not initialized');
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

  Future<void> _speak(String text) async {
    if (_isNeuralReady && _nativeEngine != null) {
      await _speakNeural(text);
    } else {
      await _speakFallback(text);
    }
  }

  Future<void> _speakNeural(String text) async {
    try {
      _setState(TtsState.speaking);
      await _nativeEngine!.speak(text, speed: _speed);
    } catch (e) {
      print('TTS neural error: $e');
      await _speakFallback(text);
    }
  }

  Future<void> _speakFallback(String text) async {
    if (_fallbackTts == null) return;

    try {
      _setState(TtsState.speaking);
      await _fallbackTts!.speak(text);
    } catch (e) {
      print('TTS fallback error: $e');
      _setState(TtsState.stopped);
      _processQueue();
    }
  }

  void _processQueue() {
    if (_messageQueue.isNotEmpty && _currentState == TtsState.stopped) {
      final nextMessage = _messageQueue.removeAt(0);
      _speak(nextMessage);
    }
  }

  Future<void> stop() async {
    try {
      await _nativeEngine?.stop();
      await _fallbackTts?.stop();
    } catch (e) {
      print('TTS stop error: $e');
    }
    _setState(TtsState.stopped);
  }

  Future<void> pause() async {
    try {
      await _nativeEngine?.pause();
      await _fallbackTts?.pause();
      _setState(TtsState.paused);
    } catch (e) {
      print('TTS pause error: $e');
    }
  }

  Future<void> resume() async {
    try {
      await _nativeEngine?.resume();
      _setState(TtsState.speaking);
    } catch (e) {
      print('TTS resume error: $e');
    }
  }

  Future<void> setSpeechRate(double rate) async {
    _speed = rate.clamp(0.5, 2.0);
    await _fallbackTts?.setSpeechRate(rate.clamp(0.0, 1.0));
  }

  Future<void> setVolume(double volume) async {
    final vol = volume.clamp(0.0, 1.0);
    await _nativeEngine?.setVolume(vol);
    await _fallbackTts?.setVolume(vol);
  }

  void _setState(TtsState state) {
    _currentState = state;
    _stateController.add(state);
  }

  void dispose() {
    stop();
    _nativeEngine?.dispose();
    _fallbackTts?.stop();
    _stateController.close();
  }
}

enum TtsState {
  stopped,
  speaking,
  paused,
}
