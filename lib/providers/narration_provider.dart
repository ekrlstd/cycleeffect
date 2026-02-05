import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../services/audio_manager.dart';

/// Provider that coordinates narration and TTS.
/// Connects to the new route-based SSE narration endpoint.
class NarrationProvider with ChangeNotifier {
  final AudioManager _audioManager = AudioManager();

  http.Client? _sseClient;
  StreamSubscription? _sseSubscription;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  bool _ttsEnabled = false;
  bool get ttsEnabled => _ttsEnabled;

  String _lastNarration = "";
  String get lastNarration => _lastNarration;

  String _connectionStatus = "Ready";
  String get connectionStatus => _connectionStatus;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  NarrationProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      await _audioManager.init();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print("NarrationProvider: Init error: $e");
      _isInitialized = true;
      notifyListeners();
    }
  }

  void onNavigationStarted() {
    _ttsEnabled = true;
    _connectionStatus = "Navigation active";
    notifyListeners();
  }

  void onNavigationStopped() {
    _ttsEnabled = false;
    _audioManager.stopSpeaking();
    _connectionStatus = "Navigation paused";
    stopNarration();
    notifyListeners();
  }

  /// Start SSE narration stream for a route.
  void startNarration({required String routeId, double lat = 57.7089, double lon = 11.9746}) {
    stopNarration();

    final url = '${AppConfig.baseUrl}/api/route/$routeId/narration?lat=$lat&lon=$lon';
    print("NarrationProvider: Connecting to $url");
    _connectSSE(url);
  }

  void stopNarration() {
    _sseSubscription?.cancel();
    _sseSubscription = null;
    _sseClient?.close();
    _sseClient = null;
    _isConnected = false;
  }

  Future<void> _connectSSE(String url) async {
    try {
      _sseClient = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';
      request.headers['X-API-Key'] = AppConfig.apiKey;

      final response = await _sseClient!.send(request);
      if (response.statusCode != 200) {
        print("NarrationProvider: SSE connection failed: ${response.statusCode}");
        return;
      }

      _isConnected = true;
      _connectionStatus = "Connected";
      notifyListeners();

      String buffer = '';
      String? currentEvent;
      String? currentData;

      _sseSubscription = response.stream.transform(utf8.decoder).listen(
        (chunk) {
          buffer += chunk;
          while (buffer.contains('\n')) {
            final lineEnd = buffer.indexOf('\n');
            String line = buffer.substring(0, lineEnd).replaceAll('\r', '');
            buffer = buffer.substring(lineEnd + 1);

            if (line.isEmpty) {
              if (currentEvent == 'narration' && currentData != null) {
                _handleNarration(currentData!);
              }
              currentEvent = null;
              currentData = null;
              continue;
            }

            if (line.startsWith('event:')) {
              currentEvent = line.substring(6).trim();
            } else if (line.startsWith('data:')) {
              currentData = line.substring(5).trim();
            }
          }
        },
        onError: (e) {
          print("NarrationProvider: SSE error: $e");
          _isConnected = false;
          notifyListeners();
        },
        onDone: () {
          print("NarrationProvider: SSE stream closed");
          _isConnected = false;
          notifyListeners();
        },
      );
    } catch (e) {
      print("NarrationProvider: SSE connect error: $e");
    }
  }

  void _handleNarration(String data) {
    try {
      final json = jsonDecode(data);
      final text = json['text'] as String?;
      if (text != null && text.isNotEmpty) {
        _lastNarration = text;
        notifyListeners();
        if (_ttsEnabled) {
          _audioManager.speak(text);
        }
      }
    } catch (e) {
      print("NarrationProvider: parse error: $e");
    }
  }

  /// Set narration text directly (used by voice pill).
  void setLastNarration(String text) {
    _lastNarration = text;
    notifyListeners();
  }

  /// Speak a response and show it.
  Future<void> speakResponse(String text) async {
    _lastNarration = text;
    notifyListeners();
    await _audioManager.speak(text);
  }

  @override
  void dispose() {
    stopNarration();
    super.dispose();
  }
}
