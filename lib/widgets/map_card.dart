import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/traffic_update.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

/// Map card widget showing user location and traffic markers.
///
/// Uses OpenStreetMap via flutter_map for easy setup without API keys.
/// Shows user's current position and traffic camera locations with
/// color-coded severity indicators.
class MapCard extends StatelessWidget {
  const MapCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        // Default to Gothenburg, Sweden if no location
        final defaultLocation = LatLng(57.7089, 11.9746);
        final userLocation = provider.userLocation;
        final center = userLocation != null
            ? LatLng(userLocation.latitude, userLocation.longitude)
            : defaultLocation;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          height: 220,
          decoration: BoxDecoration(
            color: AppTheme.mapCardBackground,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Map
                FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 13.0,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    // Clean, minimal map tiles (CartoDB Positron - similar to Google Maps)
                    TileLayer(
                      urlTemplate:
                          'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.example.cycleeffect',
                      retinaMode: true,
                    ),
                    // Traffic area circles
                    CircleLayer(
                      circles: _buildTrafficCircles(provider.trafficUpdates),
                    ),
                    // Markers layer
                    MarkerLayer(
                      markers: [
                        // User location marker
                        if (userLocation != null)
                          Marker(
                            point: LatLng(
                              userLocation.latitude,
                              userLocation.longitude,
                            ),
                            width: 40,
                            height: 40,
                            child: _buildUserMarker(userLocation.heading),
                          ),
                        // Traffic camera markers
                        ...provider.trafficUpdates.map(
                          (update) => Marker(
                            point: LatLng(update.latitude, update.longitude),
                            width: 30,
                            height: 30,
                            child: _buildTrafficMarker(update),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Location info overlay
                if (userLocation != null)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.navigation_rounded,
                            size: 16,
                            color: AppTheme.primaryGreen,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            userLocation.cardinalDirection ?? 'Locating...',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          if (userLocation.formattedSpeed != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              userLocation.formattedSpeed!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                // Connection status indicator
                Positioned(
                  top: 12,
                  right: 12,
                  child: _buildConnectionIndicator(provider.connectionState),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds the user's location marker with heading indicator.
  Widget _buildUserMarker(double? heading) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 3,
          ),
        ],
      ),
      child: heading != null
          ? Transform.rotate(
              angle: heading * (3.14159 / 180),
              child: const Icon(
                Icons.navigation,
                color: Colors.white,
                size: 20,
              ),
            )
          : const Icon(
              Icons.my_location,
              color: Colors.white,
              size: 20,
            ),
    );
  }

  /// Builds a traffic camera marker with severity coloring.
  Widget _buildTrafficMarker(TrafficUpdate update) {
    final color = _colorForSeverity(update.severity);
    final hasIncident = update.incident != null;

    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(
        hasIncident ? Icons.warning_rounded : Icons.videocam_rounded,
        color: Colors.white,
        size: 14,
      ),
    );
  }

  /// Builds traffic area circles for the map.
  List<CircleMarker> _buildTrafficCircles(List<TrafficUpdate> updates) {
    return updates.map((update) {
      final color = _colorForSeverity(update.severity);
      final hasIncident = update.incident != null;

      return CircleMarker(
        point: LatLng(update.latitude, update.longitude),
        radius: hasIncident ? 150 : 100,
        color: color.withOpacity(0.15),
        borderColor: color.withOpacity(0.3),
        borderStrokeWidth: 2,
        useRadiusInMeter: true,
      );
    }).toList();
  }

  /// Builds the connection status indicator.
  Widget _buildConnectionIndicator(connectionState) {
    Color color;
    IconData icon;
    String tooltip;

    switch (connectionState.toString()) {
      case 'ConnectionState.connected':
        color = AppTheme.trafficLow;
        icon = Icons.wifi;
        tooltip = 'Connected';
        break;
      case 'ConnectionState.connecting':
        color = AppTheme.trafficMedium;
        icon = Icons.wifi_find;
        tooltip = 'Connecting...';
        break;
      default:
        color = AppTheme.trafficHigh;
        icon = Icons.wifi_off;
        tooltip = 'Offline';
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  /// Returns the color for a traffic severity level.
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
}
