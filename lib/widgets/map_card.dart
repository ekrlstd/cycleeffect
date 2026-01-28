import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/traffic_update.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

/// Map card showing user location and traffic markers.
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

        return GradientBorderCard(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.22,
              child: Stack(
                children: [
                  // Map
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: 14.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                    ),
                    children: [
                      // Light mode map tiles
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
                              width: 24,
                              height: 24,
                              child: _buildUserMarker(),
                            ),
                          // Traffic camera markers
                          ...provider.trafficUpdates.map(
                            (update) => Marker(
                              point: LatLng(update.latitude, update.longitude),
                              width: 28,
                              height: 28,
                              child: _buildTrafficMarker(update),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserMarker() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.blue.withOpacity(0.6), width: 2),
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildTrafficMarker(TrafficUpdate update) {
    final color = _colorForSeverity(update.severity);
    final hasIncident = update.incident != null;

    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: Icon(
        hasIncident ? Icons.priority_high_rounded : Icons.speed_rounded,
        color: color.withOpacity(0.8),
        size: 16,
      ),
    );
  }

  List<CircleMarker> _buildTrafficCircles(List<TrafficUpdate> updates) {
    return updates.map((update) {
      final color = _colorForSeverity(update.severity);
      final hasIncident = update.incident != null;

      return CircleMarker(
        point: LatLng(update.latitude, update.longitude),
        radius: hasIncident ? 120 : 80,
        color: color.withOpacity(0.1),
        borderColor: color.withOpacity(0.3),
        borderStrokeWidth: 1,
        useRadiusInMeter: true,
      );
    }).toList();
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
}
