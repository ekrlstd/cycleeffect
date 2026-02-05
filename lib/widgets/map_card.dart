import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/route_model.dart';
import '../providers/app_provider.dart';
import '../providers/narration_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/route_provider.dart';
import '../theme/app_theme.dart';

/// Map card showing real OSRM route, real traffic sites, and GPS position.
class MapCard extends StatelessWidget {
  const MapCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<AppProvider, RouteProvider, NavigationProvider>(
      builder: (context, appProvider, routeProvider, navProvider, child) {
        final route = routeProvider.activeRoute;
        final userLoc = appProvider.userLocation;

        // Map center: route midpoint, user location, or default Gothenburg
        LatLng center;
        double zoom = 13.5;
        if (route != null && route.geometry.isNotEmpty) {
          final midIdx = route.geometry.length ~/ 2;
          center = LatLng(route.geometry[midIdx][1], route.geometry[midIdx][0]);
          zoom = 13.0;
        } else if (userLoc != null) {
          center = LatLng(userLoc.latitude, userLoc.longitude);
          zoom = 14.0;
        } else {
          center = LatLng(57.7089, 11.9746);
        }

        // Build route polyline from real geometry
        final List<LatLng> routeLine = route?.geometry
                .map((c) => LatLng(c[1], c[0]))
                .toList() ??
            [];

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          height: 280,
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentGreen.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: zoom,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                    onTap: (tapPosition, point) {
                      if (route == null) {
                        _showDestinationConfirmation(context, point);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.example.cycleeffect',
                      retinaMode: true,
                    ),
                    // Alternative route polylines (gray, behind main route)
                    if (routeProvider.alternatives.isNotEmpty)
                      PolylineLayer(
                        polylines: routeProvider.alternatives.map((alt) {
                          final altLine = alt.geometry
                              .map((c) => LatLng(c[1], c[0]))
                              .toList();
                          return Polyline(
                            points: altLine,
                            strokeWidth: 3,
                            color: Colors.grey.withOpacity(0.6),
                          );
                        }).toList(),
                      ),
                    // Route polyline
                    if (routeLine.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: routeLine,
                            strokeWidth: 4,
                            color: Colors.blue.withOpacity(0.8),
                          ),
                        ],
                      ),
                    // Traffic site circles
                    CircleLayer(
                      circles: routeProvider.trafficSites
                          .map((site) => CircleMarker(
                                point: LatLng(site.lat, site.lon),
                                radius: 100,
                                color: _colorForSpeed(site.speed).withOpacity(0.15),
                                borderColor: _colorForSpeed(site.speed).withOpacity(0.4),
                                borderStrokeWidth: 2,
                                useRadiusInMeter: true,
                              ))
                          .toList(),
                    ),
                    // Markers
                    MarkerLayer(
                      markers: [
                        // Traffic site markers
                        ...routeProvider.trafficSites.map((site) => Marker(
                              point: LatLng(site.lat, site.lon),
                              width: 28,
                              height: 28,
                              child: _TrafficSiteMarker(site: site),
                            )),
                        // Situation markers
                        ...routeProvider.situations
                            .where((s) => s.lat != null && s.lon != null)
                            .map((sit) => Marker(
                                  point: LatLng(sit.lat!, sit.lon!),
                                  width: 30,
                                  height: 30,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(Icons.warning_rounded,
                                        color: Colors.white, size: 14),
                                  ),
                                )),
                        // Destination marker
                        if (route != null)
                          Marker(
                            point: LatLng(route.destination.lat,
                                route.destination.lon),
                            width: 32,
                            height: 32,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.4),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.flag_rounded,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        // User / car position
                        if (userLoc != null)
                          Marker(
                            point: LatLng(
                                userLoc.latitude, userLoc.longitude),
                            width: 36,
                            height: 36,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: userLoc.heading != null
                                  ? Transform.rotate(
                                      angle: userLoc.heading! * (pi / 180),
                                      child: const Icon(Icons.navigation,
                                          color: Colors.white, size: 18),
                                    )
                                  : const Icon(Icons.my_location,
                                      color: Colors.white, size: 18),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                // Label
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          navProvider.isNavigating
                              ? Icons.navigation_rounded
                              : Icons.map_rounded,
                          size: 16,
                          color: navProvider.isNavigating
                              ? Colors.blue
                              : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          route != null
                              ? '${(route.distanceM / 1000).toStringAsFixed(1)} km'
                              : 'Real traffic data',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Reroute alert banner
                if (routeProvider.pendingReroute != null &&
                    routeProvider.pendingReroute!.rerouteNeeded)
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade800,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_rounded,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Incident ahead — alternative available',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => routeProvider.acceptReroute(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('Accept',
                                  style: TextStyle(
                                      color: Colors.orange.shade800,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => routeProvider.dismissReroute(),
                            child: const Icon(Icons.close,
                                color: Colors.white70, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Alternative routes selector
                if (route != null && routeProvider.alternatives.isNotEmpty)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _showAlternativesSheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.alt_route,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '${routeProvider.alternatives.length} alt',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Start navigation button (visible when route exists but not navigating)
                if (route != null && !navProvider.isNavigating)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: FloatingActionButton.small(
                      heroTag: 'map_start_nav',
                      onPressed: () {
                        navProvider.startNavigation();
                      },
                      backgroundColor: Colors.greenAccent,
                      child: const Icon(Icons.play_arrow_rounded,
                          color: Colors.black),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void _showDestinationConfirmation(BuildContext context, LatLng point) {
    final routeProvider = Provider.of<RouteProvider>(context, listen: false);
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    final narrationProvider = Provider.of<NarrationProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Route to ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}?',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final success = await routeProvider.createRouteFromCoords(
                        point.latitude,
                        point.longitude,
                      );
                      if (success && routeProvider.activeRoute != null) {
                        final dest = routeProvider
                            .activeRoute!.destination.displayName
                            .split(',')
                            .first;
                        narrationProvider.setLastNarration(
                          'Route set to $dest.',
                        );
                        navProvider.startNavigation();
                        narrationProvider.onNavigationStarted();
                        narrationProvider.startNarration(
                          routeId: routeProvider.activeRoute!.routeId,
                        );
                      }
                    },
                    child: const Text('Route here'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static void _showAlternativesSheet(BuildContext context) {
    final routeProvider = Provider.of<RouteProvider>(context, listen: false);
    final route = routeProvider.activeRoute;
    if (route == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Route options',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            // Current route
            _routeOptionTile(
              label: 'Current',
              distanceKm: route.distanceM / 1000,
              durationMin: route.durationS / 60,
              isActive: true,
              onTap: () => Navigator.pop(ctx),
            ),
            ...routeProvider.alternatives.map((alt) => _routeOptionTile(
                  label: 'Alternative',
                  distanceKm: alt.distanceM / 1000,
                  durationMin: alt.durationS / 60,
                  isActive: false,
                  onTap: () {
                    Navigator.pop(ctx);
                    routeProvider.switchToAlternative(alt.routeId);
                  },
                )),
          ],
        ),
      ),
    );
  }

  static Widget _routeOptionTile({
    required String label,
    required double distanceKm,
    required double durationMin,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.blue.withOpacity(0.15)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? Colors.blue : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isActive ? Icons.route : Icons.alt_route,
              color: isActive ? Colors.blue : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.blue : Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${distanceKm.toStringAsFixed(1)} km · ${durationMin.toInt()} min',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  static Color _colorForSpeed(double? speed) {
    if (speed == null) return Colors.grey;
    if (speed < 20) return AppTheme.trafficHigh;
    if (speed < 50) return AppTheme.trafficMedium;
    return AppTheme.trafficLow;
  }
}

class _TrafficSiteMarker extends StatelessWidget {
  final TrafficSite site;

  const _TrafficSiteMarker({required this.site});

  @override
  Widget build(BuildContext context) {
    final color = MapCard._colorForSpeed(site.speed);
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Center(
        child: Text(
          site.speed != null ? '${site.speed!.toInt()}' : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
