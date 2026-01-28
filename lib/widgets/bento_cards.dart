import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
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

/// Upcoming Intersections card showing real traffic data.
class UpcomingIntersectionsCard extends StatelessWidget {
  const UpcomingIntersectionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final updates = provider.trafficUpdates.take(5).toList();

        return GradientBorderCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _EyebrowText('Upcoming Intersections'),
              const SizedBox(height: 12),
              Expanded(
                child: updates.isEmpty
                    ? Center(
                        child: Text(
                          'No intersections nearby',
                          style: GoogleFonts.inter(
                            color: AppTheme.textPrimary.withOpacity(0.5),
                            fontSize: 13,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: updates.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final update = updates[index];
                          return _IntersectionItem(
                            name: update.location,
                            distance: '${((index + 1) * 0.3).toStringAsFixed(1)} km',
                            severity: update.severity.name,
                          );
                        },
                      ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap an intersection for more details',
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
  final String distance;
  final String severity;

  const _IntersectionItem({
    required this.name,
    required this.distance,
    required this.severity,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (severity) {
      case 'high':
        statusColor = AppTheme.trafficHigh;
        break;
      case 'medium':
        statusColor = AppTheme.trafficMedium;
        break;
      default:
        statusColor = AppTheme.trafficLow;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.borderSides,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.inter(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            distance,
            style: GoogleFonts.inter(
              color: AppTheme.textPrimary.withOpacity(0.5),
              fontSize: 12,
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
class SpeedDistanceCard extends StatelessWidget {
  const SpeedDistanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        // Get real speed from GPS if available
        final speedKmh = provider.userLocation?.speedKmh?.round() ?? 0;
        final speedDisplay = speedKmh > 0 ? '$speedKmh' : '0';

        return GradientBorderCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Current Speed section
              Expanded(
                child: Center(
                  child: _InlineDisplay(
                    value: speedDisplay,
                    unit: 'KM/H',
                    label: 'Current Speed',
                  ),
                ),
              ),
              // Divider
              Container(
                width: 0,
                height: 80,
                color: AppTheme.textPrimary.withOpacity(0.1),
              ),
              // Until Next Camera section
              Expanded(
                child: Center (
                  child: _InlineDisplay(
                    value: '4',
                    unit: 'KM',
                    label: 'Until Camera',
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

class _InlineDisplay extends StatelessWidget {
  final String value;
  final String unit;
  final String label;

  const _InlineDisplay({
    required this.value,
    required this.unit,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                color: AppTheme.textPrimary,
                fontSize: 46,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              unit,
              style: GoogleFonts.inter(
                color: AppTheme.textPrimary.withOpacity(0.5),
                fontSize: 36,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            color: AppTheme.textPrimary.withOpacity(0.5),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
