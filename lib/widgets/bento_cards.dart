import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/navigation_provider.dart';
import '../theme/app_theme.dart';

/// Eyebrow text style used across bento cards.
class _EyebrowText extends StatelessWidget {
  final String text;

  const _EyebrowText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.inter(
        color: AppTheme.textPrimary.withOpacity(0.5),
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

/// Upcoming Intersections card showing remaining checkpoints based on navigation.
class UpcomingIntersectionsCard extends StatelessWidget {
  const UpcomingIntersectionsCard({super.key});
  
  // Checkpoint names
  static const List<String> checkpointNames = [
    'Junction A (Main St)',
    'Junction B (Park Ave)',
    'Junction C (River Rd)',
    'Junction D (Oak Blvd)',
    'Destination',
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navProvider, child) {
        // Get remaining checkpoints (current and future, not passed)
        final currentCheckpoint = navProvider.currentCheckpoint; // 1-based
        final remainingCheckpoints = <Map<String, dynamic>>[];
        
        for (int i = currentCheckpoint - 1; i < checkpointNames.length; i++) {
          remainingCheckpoints.add({
            'index': i + 1,
            'name': checkpointNames[i],
            'isCurrent': i == currentCheckpoint - 1,
          });
        }

        return GradientBorderCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _EyebrowText('Upcoming Intersections'),
                  const Spacer(),
                  if (navProvider.isNavigating)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'NAVIGATING',
                        style: GoogleFonts.inter(
                          color: Colors.greenAccent,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: remainingCheckpoints.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: Colors.greenAccent,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'All checkpoints passed!',
                              style: GoogleFonts.inter(
                                color: AppTheme.textPrimary.withOpacity(0.5),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: remainingCheckpoints.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final checkpoint = remainingCheckpoints[index];
                          return _IntersectionItem(
                            name: checkpoint['name'] as String,
                            checkpointNumber: checkpoint['index'] as int,
                            isCurrent: checkpoint['isCurrent'] as bool,
                          );
                        },
                      ),
              ),
              const SizedBox(height: 8),
              Text(
                navProvider.isNavigating 
                    ? 'Heading to checkpoint ${navProvider.currentCheckpoint}'
                    : 'Press play on map to start navigation',
                style: GoogleFonts.inter(
                  color: AppTheme.textPrimary.withOpacity(0.3),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _IntersectionItem extends StatelessWidget {
  final String name;
  final int checkpointNumber;
  final bool isCurrent;

  const _IntersectionItem({
    required this.name,
    required this.checkpointNumber,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    // Current target gets a highlight color, others are grayed out
    final statusColor = isCurrent ? AppTheme.accentGreen : AppTheme.textPrimary.withOpacity(0.3);
    final textColor = isCurrent ? AppTheme.textPrimary : AppTheme.textPrimary.withOpacity(0.6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrent ? AppTheme.accentGreen.withOpacity(0.5) : AppTheme.borderSides,
          width: 1,
        ),
        boxShadow: isCurrent ? [
          BoxShadow(
            color: AppTheme.accentGreen.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 0,
          )
        ] : [],
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$checkpointNumber',
                style: GoogleFonts.inter(
                  color: isCurrent ? Colors.black : Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 13,
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'NEXT',
                style: GoogleFonts.inter(
                  color: AppTheme.accentGreen,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}


/// Alert card with warning message.
class AlertCard extends StatelessWidget {
  const AlertCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _EyebrowText('Alert'),
          const Spacer(),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_rounded,
                  color: AppTheme.accentAmber,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'Traffic incident detected in Gothenburg area',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textPrimary.withOpacity(0.8),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

/// Speed and Distance card with inline displays.
