import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

/// Voice interface pill with waveform and mic button.
class VoicePill extends StatefulWidget {
  const VoicePill({super.key});

  @override
  State<VoicePill> createState() => _VoicePillState();
}

class _VoicePillState extends State<VoicePill> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final Random _random = Random();
  List<double> _barHeights = List.generate(14, (_) => 0.3);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(_updateWaveform);

    // Start animation
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9999),
            color: AppTheme.cardBackground.withOpacity(0.65),
            border: Border.all(
              color: AppTheme.borderTop.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Row(
            children: [
                // AI sparkle icon
                Icon(
                  Icons.auto_awesome,
                  color: AppTheme.textPrimary.withOpacity(0.8),
                  size: 24,
                ),
                const SizedBox(width: 12),
                // Waveform
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: List.generate(14, (index) {
                      // Taper from left (loud) to right (quiet)
                      final normalizedPos = index / 13;
                      // Exponential decay: starts at 1.0, tapers to ~0.2
                      final taper = 0.2 + 0.8 * pow(1 - normalizedPos, 1.5);

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 4,
                          height: 32 * _barHeights[index] * taper,
                          decoration: BoxDecoration(
                            color: AppTheme.textPrimary.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                // Mic button
                GestureDetector(
                  onTap: () {
                    // Trigger voice action
                    if (provider.trafficUpdates.isNotEmpty) {
                      final update = provider.trafficUpdates.first;
                      final message =
                          '${update.location}. ${update.vehicleCount} vehicles detected. ${update.density.displayName}.';
                      provider.speakAlert(message);
                    }
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppTheme.textPrimary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.borderSides,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.mic_rounded,
                      color: AppTheme.background,
                      size: 26,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
