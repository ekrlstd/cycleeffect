import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/route_provider.dart';
import '../theme/app_theme.dart';

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

/// Traffic info card showing real data from the active route.
class UpcomingIntersectionsCard extends StatelessWidget {
  const UpcomingIntersectionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<RouteProvider, NavigationProvider>(
      builder: (context, routeProvider, navProvider, child) {
        final route = routeProvider.activeRoute;
        final sites = routeProvider.trafficSites;
        final situations = routeProvider.situations;

        return GradientBorderCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _EyebrowText('Route Traffic'),
                  const Spacer(),
                  if (navProvider.isNavigating)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'LIVE',
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
                child: route == null
                    ? Center(
                        child: Text(
                          'Use the mic to set a destination',
                          style: GoogleFonts.inter(
                            color: AppTheme.textPrimary.withOpacity(0.4),
                            fontSize: 13,
                          ),
                        ),
                      )
                    : ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          // Destination summary
                          _InfoTile(
                            icon: Icons.flag_rounded,
                            color: Colors.orange,
                            title: route.destination.displayName.split(',').first,
                            subtitle:
                                '${(route.distanceM / 1000).toStringAsFixed(1)} km • ${(route.durationS / 60).toStringAsFixed(0)} min',
                          ),
                          const SizedBox(height: 8),
                          // Traffic summary - always show to debug
                          _InfoTile(
                            icon: Icons.speed_rounded,
                            color: Colors.blue,
                            title: '${sites.length} traffic sensors',
                            subtitle: sites.isNotEmpty ? _speedSummary(sites) : 'No sensor data',
                          ),
                          const SizedBox(height: 8),
                          // Cameras - always show to debug
                          _InfoTile(
                            icon: Icons.videocam_rounded,
                            color: Colors.cyan,
                            title: '${route.cameras.length} live cameras',
                            subtitle: route.cameras.isNotEmpty
                                ? route.cameras.take(2).map((c) => c.name).join(', ')
                                : 'No cameras',
                          ),
                          const SizedBox(height: 8),
                          // Incidents
                          ...situations.take(2).map((sit) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _InfoTile(
                                  icon: Icons.warning_rounded,
                                  color: Colors.red,
                                  title: sit.message.length > 60
                                      ? '${sit.message.substring(0, 60)}...'
                                      : sit.message,
                                  subtitle: sit.road != null
                                      ? 'Road ${sit.road}'
                                      : sit.severity,
                                ),
                              )),
                          if (situations.isEmpty && sites.isEmpty && route.cameras.isEmpty)
                            _InfoTile(
                              icon: Icons.check_circle_outline,
                              color: Colors.greenAccent,
                              title: 'No incidents reported',
                              subtitle: 'Route looks clear',
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 8),
              Text(
                route != null
                    ? 'Real-time data from Trafikverket'
                    : 'Tap mic to search for a destination',
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

  String _speedSummary(List sites) {
    final speeds = sites
        .where((s) => s.speed != null)
        .map<double>((s) => s.speed as double)
        .toList();
    if (speeds.isEmpty) return 'No speed data';
    final avg = speeds.reduce((a, b) => a + b) / speeds.length;
    return 'Avg ${avg.toStringAsFixed(0)} km/h';
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _InfoTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderSides, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: AppTheme.textPrimary.withOpacity(0.5),
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
                Icon(Icons.warning_rounded, color: AppTheme.accentAmber, size: 32),
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
