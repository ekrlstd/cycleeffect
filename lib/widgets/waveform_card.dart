import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

/// Audio waveform visualizer card for AI voice narration.
///
/// Displays an animated waveform pattern that responds to TTS state.
/// Currently uses a hardcoded animation pattern.
class WaveformCard extends StatefulWidget {
  const WaveformCard({super.key});

  @override
  State<WaveformCard> createState() => _WaveformCardState();
}

class _WaveformCardState extends State<WaveformCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final Random _random = Random();

  // Number of bars in the waveform
  static const int barCount = 32;

  // Bar heights (normalized 0-1)
  List<double> _barHeights = [];

  @override
  void initState() {
    super.initState();
    _barHeights = List.generate(barCount, (_) => 0.1);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..addListener(_updateWaveform);
  }

  void _updateWaveform() {
    setState(() {
      for (int i = 0; i < barCount; i++) {
        // Smooth random animation
        final target = 0.2 + _random.nextDouble() * 0.8;
        _barHeights[i] = _barHeights[i] * 0.7 + target * 0.3;
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool _wasSpeaking = false;

  void _handleSpeakingStateChange(bool isSpeaking) {
    if (isSpeaking && !_animationController.isAnimating) {
      _animationController.repeat();
    } else if (!isSpeaking && _animationController.isAnimating) {
      _animationController.stop();
      // Reset to idle state
      setState(() {
        _barHeights = List.generate(barCount, (_) => 0.1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final isSpeaking = provider.isSpeaking;

        // Defer animation state changes to after build completes
        if (isSpeaking != _wasSpeaking) {
          _wasSpeaking = isSpeaking;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _handleSpeakingStateChange(isSpeaking);
            }
          });
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardBackgroundAlt,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.accentPurple.withAlpha(30),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSpeaking
                          ? AppTheme.accentPurple.withAlpha(60)
                          : AppTheme.accentPurple.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isSpeaking
                          ? Icons.record_voice_over_rounded
                          : Icons.assistant_rounded,
                      size: 24,
                      color: isSpeaking
                          ? AppTheme.textBright
                          : AppTheme.accentPurple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Voice Assistant',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textBright,
                                  ),
                        ),
                        Text(
                          isSpeaking ? 'Speaking...' : 'Tap an update to hear',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textMuted,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  // Stop button (visible when speaking)
                  if (isSpeaking)
                    IconButton(
                      onPressed: () => provider.stopSpeaking(),
                      icon: const Icon(Icons.stop_circle_rounded),
                      color: AppTheme.trafficHigh,
                      iconSize: 32,
                    ),
                ],
              ),
              const SizedBox(height: 20),
              // Waveform visualization
              SizedBox(
                height: 80,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(barCount, (index) {
                    return _WaveformBar(
                      height: _barHeights[index],
                      isActive: isSpeaking,
                      index: index,
                      totalBars: barCount,
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Individual waveform bar widget.
class _WaveformBar extends StatelessWidget {
  final double height;
  final bool isActive;
  final int index;
  final int totalBars;

  const _WaveformBar({
    required this.height,
    required this.isActive,
    required this.index,
    required this.totalBars,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate taper multiplier - bars at edges are shorter than middle
    // Using a sine curve for smooth tapering
    final normalizedPosition = index / (totalBars - 1); // 0 to 1
    final taperMultiplier = sin(normalizedPosition * 3.14159); // 0 at edges, 1 at middle
    final adjustedTaper = 0.3 + (taperMultiplier * 0.7); // Range from 0.3 to 1.0

    // Calculate color based on position for gradient effect (purple spectrum)
    final hue = 250.0 + (index / totalBars) * 30; // Purple spectrum
    final color = isActive
        ? HSLColor.fromAHSL(1.0, hue, 0.5, 0.6).toColor()
        : AppTheme.accentPurple.withAlpha(60);

    final double barHeight = isActive ? 80 * height * adjustedTaper : 6.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      width: 5,
      height: barHeight,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2.5),
      ),
    );
  }
}
