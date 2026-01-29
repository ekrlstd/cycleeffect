import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class AudioManager {
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isSpeechAvailable = false;
  bool _isTtsAvailable = false;

  Future<void> init() async {
    // Initialize TTS
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      _isTtsAvailable = true;
      print("AudioManager: TTS initialized");
    } catch (e) {
      print("AudioManager: TTS init error: $e");
      _isTtsAvailable = false;
    }

    // Initialize STT
    try {
      _isSpeechAvailable = await _speech.initialize(
        onStatus: (status) => print('STT Status: $status'),
        onError: (error) => print('STT Error: $error'),
      );
      print("AudioManager: STT available: $_isSpeechAvailable");
    } catch (e) {
      print("AudioManager: STT init error: $e");
      _isSpeechAvailable = false;
    }
  }

  Future<void> speak(String text) async {
    if (!_isTtsAvailable) {
      print("AudioManager: TTS not available, skipping speak");
      return;
    }
    
    try {
      if (text.isNotEmpty) {
        await _flutterTts.speak(text);
      }
    } catch (e) {
      print("AudioManager: Speak error: $e");
    }
  }

  Future<void> stopSpeaking() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      print("AudioManager: Stop speaking error: $e");
    }
  }

  /// Listens for a single command/question safely.
  /// Returns the recognized words.
  Future<String?> listenForDuration(Duration duration) async {
    if (!_isSpeechAvailable) {
      print("AudioManager: Speech recognition not available");
      return null;
    }

    try {
      Completer<String?> completer = Completer();
      String recognizedWords = "";

      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            recognizedWords = result.recognizedWords;
            if (!completer.isCompleted) {
               completer.complete(recognizedWords);
            }
          }
        },
        listenFor: duration,
        pauseFor: Duration(seconds: 3),
        localeId: "en_US",
        cancelOnError: true,
        partialResults: false,
      );

      return completer.future.timeout(duration + Duration(seconds: 2), onTimeout: () {
        print("AudioManager: Listen timeout");
        return null;
      });
    } catch (e) {
      print("AudioManager: Listen error: $e");
      return null;
    }
  }
}
