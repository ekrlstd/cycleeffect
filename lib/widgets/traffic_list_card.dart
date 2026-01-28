import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/traffic_update.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

/// Card displaying the most recent traffic updates in a list.
///
/// Shows up to 5 recent updates with location, vehicle count,
/// density level, and any incidents. Each item is tappable
/// for TTS narration.
class TrafficListCard extends StatelessWidget {
  const TrafficListCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final updates = provider.trafficUpdates.take(5).toList();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.lightGreen.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.traffic_rounded,
                        size: 20,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Recent Traffic Updates',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      '${updates.length} updates',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textMuted,
                          ),
                    ),
                  ],
                ),
              ),
              // Divider
              Divider(
                color: AppTheme.lightGreen.withOpacity(0.3),
                height: 1,
              ),
              // List
              if (updates.isEmpty)
                _buildEmptyState(context)
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: updates.length,
                  separatorBuilder: (context, index) => Divider(
                    color: AppTheme.lightGreen.withOpacity(0.2),
                    height: 1,
                    indent: 68,
                  ),
                  itemBuilder: (context, index) {
                    return _TrafficUpdateTile(
                      update: updates[index],
                      onTap: () => _speakUpdate(context, updates[index]),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: AppTheme.textMuted.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No traffic updates yet',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textMuted,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Updates will appear as you drive',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textMuted.withOpacity(0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _speakUpdate(BuildContext context, TrafficUpdate update) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final message = _buildSpokenMessage(update);
    provider.speakAlert(message);
  }

  String _buildSpokenMessage(TrafficUpdate update) {
    final buffer = StringBuffer();
    buffer.write('${update.location}. ');
    buffer.write('${update.vehicleCount} vehicles detected. ');
    buffer.write('${update.density.displayName}. ');

    if (update.incident != null) {
      buffer.write('Alert: ${update.incident!.type.displayName}. ');
      if (update.incident!.description != null) {
        buffer.write('${update.incident!.description}. ');
      }
    }

    if (update.direction != null) {
      buffer.write('Traffic heading ${update.direction}.');
    }

    return buffer.toString();
  }
}

/// Individual traffic update tile widget.
class _TrafficUpdateTile extends StatelessWidget {
  final TrafficUpdate update;
  final VoidCallback onTap;

  const _TrafficUpdateTile({
    required this.update,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final severityColor = _colorForSeverity(update.severity);
    final hasIncident = update.incident != null;
    final timeAgo = _formatTimeAgo(update.timestamp);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Severity indicator
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: severityColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    hasIncident
                        ? Icons.warning_amber_rounded
                        : Icons.location_on_rounded,
                    color: severityColor,
                    size: 24,
                  ),
                  // Vehicle count badge
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: severityColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${update.vehicleCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    update.location,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildChip(
                        update.density.displayName,
                        severityColor,
                      ),
                      if (hasIncident) ...[
                        const SizedBox(width: 8),
                        _buildChip(
                          update.incident!.type.displayName,
                          AppTheme.trafficHigh,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Time and play button
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeAgo,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.volume_up_rounded,
                  size: 20,
                  color: AppTheme.lightGreen,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Color _colorForSeverity(TrafficSeverity severity) {
    switch (severity) {
      case TrafficSeverity.low:
        return AppTheme.trafficLow;
      case TrafficSeverity.medium:
        return AppTheme.trafficMedium;
      case TrafficSeverity.high:
        return AppTheme.trafficHigh;
    }
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
