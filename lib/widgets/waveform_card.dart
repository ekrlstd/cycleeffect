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

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final isSpeaking = provider.isSpeaking;

        // Start/stop animation based on TTS state
        if (isSpeaking && !_animationController.isAnimating) {
          _animationController.repeat();
        } else if (!isSpeaking && _animationController.isAnimating) {
          _animationController.stop();
          // Reset to idle state
          setState(() {
            _barHeights = List.generate(barCount, (_) => 0.1);
          });
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.waveformCardBackground,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
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
                          ? AppTheme.primaryGreen.withOpacity(0.2)
                          : AppTheme.lightGreen.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isSpeaking
                          ? Icons.record_voice_over_rounded
                          : Icons.voice_over_off_rounded,
                      size: 24,
                      color: isSpeaking
                          ? AppTheme.primaryGreen
                          : AppTheme.textMuted,
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
                                    color: AppTheme.textPrimary,
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

  const _WaveformBar({
    required this.height,
    required this.isActive,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate color based on position for gradient effect
    final hue = 120.0 + (index / 32) * 40; // Green to light green
    final color = isActive
        ? HSLColor.fromAHSL(1.0, hue, 0.6, 0.45).toColor()
        : AppTheme.lightGreen.withOpacity(0.4);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      width: 6,
      height: isActive ? 80 * height : 8,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }
}
