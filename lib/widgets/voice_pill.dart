import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/narration_provider.dart';
import '../providers/navigation_provider.dart';
import '../theme/app_theme.dart';

/// Voice interface pill with waveform and navigation status.
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
    return Consumer2<NarrationProvider, NavigationProvider>(
      builder: (context, narrationProvider, navProvider, child) {
        final isNavigating = navProvider.isNavigating;
        final currentCheckpoint = navProvider.currentCheckpoint;
        
        return Column(
          children: [
            // Navigation Status Header
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0, left: 16, right: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Status indicator
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isNavigating ? Colors.greenAccent : Colors.grey,
                      shape: BoxShape.circle,
                      boxShadow: isNavigating ? [
                        BoxShadow(
                          color: Colors.greenAccent.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ] : [],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isNavigating 
                        ? 'Navigating to Checkpoint $currentCheckpoint' 
                        : 'Tap play on map to start',
                    style: AppTheme.bodySmall.copyWith(
                      color: isNavigating ? Colors.greenAccent : AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            // Connection Status
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: narrationProvider.isConnected ? Colors.greenAccent : Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    narrationProvider.connectionStatus,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            
            // Last Narration Text
            if (narrationProvider.lastNarration.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0, left: 16, right: 16),
                child: Text(
                  narrationProvider.lastNarration,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),

            // Main Voice Pill (Visual indicator only)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9999),
                color: AppTheme.cardBackground.withOpacity(0.65),
                border: Border.all(
                  color: isNavigating 
                      ? Colors.greenAccent.withOpacity(0.5) 
                      : AppTheme.borderTop.withOpacity(0.5),
                  width: isNavigating ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  // AI sparkle icon
                  Icon(
                    isNavigating ? Icons.volume_up_rounded : Icons.volume_off_rounded,
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
                        final heightMultiplier = isNavigating ? 1.5 : 0.5;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 4,
                            height: 32 * _barHeights[index] * taper * heightMultiplier,
                            decoration: BoxDecoration(
                              color: isNavigating 
                                  ? Colors.greenAccent 
                                  : AppTheme.textPrimary.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  // TTS status icon
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isNavigating 
                          ? Colors.greenAccent 
                          : AppTheme.cardBackground,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isNavigating 
                            ? Colors.greenAccent.withOpacity(0.5)
                            : AppTheme.borderSides,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      isNavigating ? Icons.graphic_eq : Icons.mic_off_rounded,
                      color: isNavigating 
                          ? AppTheme.background 
                          : AppTheme.textSecondary,
                      size: 26,
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
