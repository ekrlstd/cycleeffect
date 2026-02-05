import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../providers/narration_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/route_provider.dart';
import '../theme/app_theme.dart';

/// Voice interface pill with real speech-to-text and route/traffic queries.
class VoicePill extends StatefulWidget {
  const VoicePill({super.key});

  @override
  State<VoicePill> createState() => _VoicePillState();
}

class _VoicePillState extends State<VoicePill>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final Random _random = Random();
  List<double> _barHeights = List.generate(14, (_) => 0.3);

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isProcessing = false;
  String _recognizedText = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(_updateWaveform);
    _animationController.repeat();
  }

  void _updateWaveform() {
    setState(() {
      for (int i = 0; i < _barHeights.length; i++) {
        final target = 0.2 + _random.nextDouble() * 0.8;
        _barHeights[i] = _barHeights[i] * 0.6 + target * 0.4;
      }
    });
  }

  Future<void> _startListening() async {
    if (_isListening || _isProcessing) return;

    bool available = await _speech.initialize(
      onError: (error) {
        print('Speech error: $error');
        setState(() {
          _isListening = false;
        });
      },
    );

    if (!available) {
      // Fallback: show text input
      _showTextInputDialog();
      return;
    }

    setState(() {
      _isListening = true;
      _recognizedText = '';
    });

    _speech.listen(
      onResult: (result) {
        setState(() {
          _recognizedText = result.recognizedWords;
        });
        if (result.finalResult) {
          _speech.stop();
          setState(() {
            _isListening = false;
          });
          if (_recognizedText.isNotEmpty) {
            _handleVoiceInput(_recognizedText);
          }
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      localeId: 'sv_SE',
    );
  }

  /// Show text input dialog for typing destination
  Future<void> _showTextInputDialog() async {
    if (!mounted) return;
    final routeProvider = Provider.of<RouteProvider>(context, listen: false);
    final hasRoute = routeProvider.activeRoute != null;

    final text = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: Text(
            hasRoute ? 'Ask about traffic' : 'Where are you going?',
            style: const TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hasRoute ? 'e.g. Is there traffic ahead?' : 'e.g. Liseberg, nearest ICA',
              hintStyle: const TextStyle(color: Colors.grey),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.orange),
              ),
            ),
            onSubmitted: (v) => Navigator.pop(ctx, v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Go', style: TextStyle(color: Colors.orange)),
            ),
          ],
        );
      },
    );
    if (text != null && text.isNotEmpty) {
      _handleVoiceInput(text);
    }
  }

  /// Stop/cancel the current search
  void _stopSearch() {
    if (_isListening) {
      _speech.stop();
      setState(() {
        _isListening = false;
        _recognizedText = '';
      });
    }
    if (_isProcessing) {
      // Cancel route loading
      final routeProvider = Provider.of<RouteProvider>(context, listen: false);
      routeProvider.cancelLoading();
      setState(() {
        _isProcessing = false;
      });
    }
  }

  /// Extract the destination name from natural language input.
  /// "Find me a route to Liseberg" → "Liseberg"
  /// "Take me to Kungsportsplatsen" → "Kungsportsplatsen"
  /// "Liseberg" → "Liseberg"
  String _extractDestination(String text) {
    final lower = text.toLowerCase();
    // Common preamble patterns (Swedish + English)
    final patterns = [
      RegExp(r'^(ta mig till|kör mig till|navigera till|hitta vägen till|vägen till|jag vill till|åk till)\s+', caseSensitive: false),
      RegExp(r'^(find me a route to|take me to|drive me to|navigate to|go to|route to|get me to|directions to|head to)\s+', caseSensitive: false),
      RegExp(r'^(jag vill åka till|kan du ta mig till|hur kommer jag till)\s+', caseSensitive: false),
      RegExp(r'^(find me the |find me a |find the |find a |find )', caseSensitive: false),
      RegExp(r'^(hitta |sök efter |sök )', caseSensitive: false),
    ];
    String result = text;
    for (final p in patterns) {
      final match = p.firstMatch(result);
      if (match != null) {
        result = result.substring(match.end).trim();
        break;
      }
    }
    // Strip "nearest/closest/närmaste" qualifiers
    result = result.replaceAll(RegExp(r'\b(nearest|closest|närmaste|närmsta)\b', caseSensitive: false), '').trim();
    // Remove trailing punctuation
    result = result.replaceAll(RegExp(r'[.?!]+$'), '').trim();
    return result.isEmpty ? text : result;
  }

  Future<void> _handleVoiceInput(String text) async {
    setState(() {
      _isProcessing = true;
    });

    final routeProvider = Provider.of<RouteProvider>(context, listen: false);
    final narrationProvider = Provider.of<NarrationProvider>(context, listen: false);
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);

    if (routeProvider.activeRoute == null) {
      // No route yet — extract destination from natural language
      final destination = _extractDestination(text);
      final success = await routeProvider.createRoute(destination);
      if (success && routeProvider.activeRoute != null) {
        final dest = routeProvider.activeRoute!.destination.displayName;
        final distKm = (routeProvider.activeRoute!.distanceM / 1000).toStringAsFixed(1);
        narrationProvider.setLastNarration(
          'Route set to $dest ($distKm km). Tap the map to start navigating.',
        );
        // Start navigation and connect narration SSE
        navProvider.startNavigation();
        narrationProvider.onNavigationStarted();
        narrationProvider.startNarration(
          routeId: routeProvider.activeRoute!.routeId,
        );
      } else {
        narrationProvider.setLastNarration(
          routeProvider.error ?? 'Could not find that destination.',
        );
      }
    } else {
      // Route exists — treat as a traffic query
      final response = await routeProvider.sendVoiceQuery(
        text,
        lat: navProvider.carPosition?.latitude,
        lon: navProvider.carPosition?.longitude,
      );
      narrationProvider.speakResponse(response);
    }

    setState(() {
      _isProcessing = false;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<NarrationProvider, NavigationProvider, RouteProvider>(
      builder: (context, narrationProvider, navProvider, routeProvider, child) {
        final isNavigating = navProvider.isNavigating;
        final hasRoute = routeProvider.activeRoute != null;

        return Column(
          children: [
            // Navigation Status Header
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0, left: 16, right: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isNavigating
                          ? Colors.greenAccent
                          : (hasRoute ? Colors.orange : Colors.grey),
                      shape: BoxShape.circle,
                      boxShadow: isNavigating
                          ? [
                              BoxShadow(
                                color: Colors.greenAccent.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : [],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      isNavigating
                          ? 'Navigating to ${routeProvider.activeRoute?.destination.displayName.split(',').first ?? "destination"}'
                          : (hasRoute
                              ? 'Route ready — tap map to start'
                              : 'Say or type your destination'),
                      style: AppTheme.bodySmall.copyWith(
                        color: isNavigating
                            ? Colors.greenAccent
                            : AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Connection / Loading Status with Stop button
            if (routeProvider.isLoading || _isProcessing || _isListening)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!_isListening) ...[
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      _isListening
                          ? 'Listening...'
                          : (_isProcessing ? 'Processing...' : 'Finding route...'),
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _stopSearch,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.5)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.close, color: Colors.red, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'Stop',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Recognized text while listening
            if (_isListening && _recognizedText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0, left: 16, right: 16),
                child: Text(
                  '"$_recognizedText"',
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.orange,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),

            // Last Narration Text
            if (narrationProvider.lastNarration.isNotEmpty && !_isListening)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0, left: 16, right: 16),
                child: Text(
                  narrationProvider.lastNarration,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),

            // Main Voice Pill
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9999),
                color: AppTheme.cardBackground.withOpacity(0.65),
                border: Border.all(
                  color: _isListening
                      ? Colors.orange.withOpacity(0.8)
                      : (isNavigating
                          ? Colors.greenAccent.withOpacity(0.5)
                          : AppTheme.borderTop.withOpacity(0.5)),
                  width: _isListening ? 2 : (isNavigating ? 2 : 1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isNavigating
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    color: isNavigating
                        ? Colors.greenAccent
                        : AppTheme.textPrimary.withOpacity(0.5),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  // Waveform
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: List.generate(14, (index) {
                        final normalizedPos = index / 13;
                        final taper = 0.2 + 0.8 * pow(1 - normalizedPos, 1.5);
                        final heightMultiplier =
                            (isNavigating || _isListening || _isProcessing) ? 1.5 : 0.5;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 4,
                            height: 32 * _barHeights[index] * taper * heightMultiplier,
                            decoration: BoxDecoration(
                              color: _isListening
                                  ? Colors.orange
                                  : (isNavigating
                                      ? Colors.greenAccent
                                      : AppTheme.textPrimary.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  // Keyboard/Type button
                  GestureDetector(
                    onTap: (_isListening || _isProcessing) ? null : _showTextInputDialog,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.borderSides,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.keyboard_rounded,
                        color: (_isListening || _isProcessing)
                            ? AppTheme.textSecondary.withOpacity(0.3)
                            : AppTheme.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Mic button
                  GestureDetector(
                    onTap: (_isListening || _isProcessing) ? _stopSearch : _startListening,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _isListening
                            ? Colors.orange
                            : (_isProcessing
                                ? Colors.red.withOpacity(0.8)
                                : (isNavigating
                                    ? Colors.greenAccent
                                    : AppTheme.cardBackground)),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isListening
                              ? Colors.orange.withOpacity(0.5)
                              : (_isProcessing
                                  ? Colors.red.withOpacity(0.5)
                                  : (isNavigating
                                      ? Colors.greenAccent.withOpacity(0.5)
                                      : AppTheme.borderSides)),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        _isListening
                            ? Icons.mic
                            : (_isProcessing
                                ? Icons.stop_rounded
                                : Icons.mic_none_rounded),
                        color: (_isListening || _isProcessing || isNavigating)
                            ? AppTheme.background
                            : AppTheme.textSecondary,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
