// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:provider/provider.dart';
// import '../models/traffic_update.dart';
// import '../providers/app_provider.dart';
// import '../theme/app_theme.dart';
// 
// /// Map card showing user location and traffic markers.
// class MapCard extends StatelessWidget {
//   const MapCard({super.key});
// 
//   @override
//   Widget build(BuildContext context) {
//     return Consumer<AppProvider>(
//       builder: (context, provider, child) {
//         // Default to Gothenburg, Sweden if no location
//         final defaultLocation = LatLng(57.7089, 11.9746);
//         final userLocation = provider.userLocation;
//         final center = userLocation != null
//             ? LatLng(userLocation.latitude, userLocation.longitude)
//             : defaultLocation;
// 
//         return GradientBorderCard(
//           margin: const EdgeInsets.symmetric(horizontal: 16),
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(15),
//             child: SizedBox(
//               height: MediaQuery.of(context).size.height * 0.22,
//               child: Stack(
//                 children: [
//                   // Map
//                   FlutterMap(
//                     options: MapOptions(
//                       initialCenter: center,
//                       initialZoom: 14.0,
//                       interactionOptions: const InteractionOptions(
//                         flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
//                       ),
//                     ),
//                     children: [
//                       // Light mode map tiles
//                       TileLayer(
//                         urlTemplate:
//                             'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
//                         subdomains: const ['a', 'b', 'c', 'd'],
//                         userAgentPackageName: 'com.example.cycleeffect',
//                         retinaMode: true,
//                       ),
//                       // Traffic area circles
//                       CircleLayer(
//                         circles: _buildTrafficCircles(provider.trafficUpdates),
//                       ),
//                       // Markers layer
//                       MarkerLayer(
//                         markers: [
//                           // User location marker
//                           if (userLocation != null)
//                             Marker(
//                               point: LatLng(
//                                 userLocation.latitude,
//                                 userLocation.longitude,
//                               ),
//                               width: 24,
//                               height: 24,
//                               child: _buildUserMarker(),
//                             ),
//                           // Traffic camera markers
//                           ...provider.trafficUpdates.map(
//                             (update) => Marker(
//                               point: LatLng(update.latitude, update.longitude),
//                               width: 28,
//                               height: 28,
//                               child: _buildTrafficMarker(update),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// 
//   Widget _buildUserMarker() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.blue.withOpacity(0.2),
//         shape: BoxShape.circle,
//         border: Border.all(color: Colors.blue.withOpacity(0.6), width: 2),
//       ),
//       child: Center(
//         child: Container(
//           width: 8,
//           height: 8,
//           decoration: BoxDecoration(
//             color: Colors.blue,
//             shape: BoxShape.circle,
//           ),
//         ),
//       ),
//     );
//   }
// 
//   Widget _buildTrafficMarker(TrafficUpdate update) {
//     final color = _colorForSeverity(update.severity);
//     final hasIncident = update.incident != null;
// 
//     return Container(
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.15),
//         shape: BoxShape.circle,
//         border: Border.all(color: color.withOpacity(0.5), width: 1.5),
//       ),
//       child: Icon(
//         hasIncident ? Icons.priority_high_rounded : Icons.speed_rounded,
//         color: color.withOpacity(0.8),
//         size: 16,
//       ),
//     );
//   }
// 
//   List<CircleMarker> _buildTrafficCircles(List<TrafficUpdate> updates) {
//     return updates.map((update) {
//       final color = _colorForSeverity(update.severity);
//       final hasIncident = update.incident != null;
// 
//       return CircleMarker(
//         point: LatLng(update.latitude, update.longitude),
//         radius: hasIncident ? 120 : 80,
//         color: color.withOpacity(0.1),
//         borderColor: color.withOpacity(0.3),
//         borderStrokeWidth: 1,
//         useRadiusInMeter: true,
//       );
//     }).toList();
//   }
// 
//   Color _colorForSeverity(TrafficSeverity severity) {
//     switch (severity) {
//       case TrafficSeverity.low:
//         return AppTheme.trafficLow;
//       case TrafficSeverity.medium:
//         return AppTheme.trafficMedium;
//       case TrafficSeverity.high:
//         return AppTheme.trafficHigh;
//     }
//   }
// }
// 

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/traffic_update.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

/// Map card widget with animated car driving along real roads.
class MapCard extends StatefulWidget {
  const MapCard({super.key});

  @override
  State<MapCard> createState() => _MapCardState();
}

class _MapCardState extends State<MapCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Sequential road path:
  // A (Start) -> B (Int 2) -> C (New Point) -> D (Int 4) -> E (Int 5)
  static final List<LatLng> _roadPath = [
    // A: Start
    LatLng(57.698404, 11.896335),
    // A -> B segments
    LatLng(57.698743, 11.896048),
    LatLng(57.699017, 11.895898),
    LatLng(57.69905, 11.895885),
    LatLng(57.699352, 11.895756),
    LatLng(57.699461, 11.895724),
    LatLng(57.699569, 11.895717),
    LatLng(57.699753, 11.895737),
    LatLng(57.699844, 11.89577),
    LatLng(57.699912, 11.895823),
    
    // B: Intersection 2
    LatLng(57.69992, 11.89583),
    
    // B -> C Geometry (Restored)
    LatLng(57.700016, 11.895977),
    LatLng(57.700045, 11.896049),
    LatLng(57.700066, 11.896139),
    LatLng(57.70009, 11.896297),
    LatLng(57.700099, 11.896459),
    LatLng(57.700096, 11.896544),
    LatLng(57.700091, 11.896592),
    LatLng(57.700077, 11.896657),
    LatLng(57.70006, 11.896717),
    LatLng(57.700033, 11.896788),
    LatLng(57.700008, 11.896842),
    LatLng(57.699981, 11.896879),
    LatLng(57.699914, 11.896952),
    LatLng(57.699892, 11.896964),

    // C: New Stop Point (Corrected)
    LatLng(57.699788, 11.897004), 

    // C -> D Geometry (Restored)
    LatLng(57.699768, 11.897019),
    LatLng(57.699711, 11.897045),
    LatLng(57.699644, 11.897084),
    LatLng(57.699624, 11.897096),
    LatLng(57.699603, 11.897131),
    LatLng(57.699576, 11.897181),
    LatLng(57.699553, 11.897274),
    LatLng(57.699496, 11.897696),
    LatLng(57.699495, 11.897698),
    LatLng(57.699482, 11.897936),
    LatLng(57.699437, 11.898128),
    LatLng(57.69942, 11.89819),
    LatLng(57.699396, 11.898255),
    LatLng(57.699374, 11.898293),
    LatLng(57.699327, 11.898364),
    LatLng(57.699147, 11.898616),
    LatLng(57.699094, 11.898688),
    
    // D: Old C / Intersection 4
    LatLng(57.69909, 11.89868),
    
    // D -> E segments (Original Segment 4->5)
    LatLng(57.699041, 11.898809),
    LatLng(57.699031, 11.898912),
    LatLng(57.69904, 11.89901),
    LatLng(57.699056, 11.899142),
    LatLng(57.699086, 11.899278),
    LatLng(57.699126, 11.899416),
    LatLng(57.699174, 11.899535),
    LatLng(57.69926, 11.899745),
    LatLng(57.699302, 11.899869),
    LatLng(57.699337, 11.899995),
    LatLng(57.699359, 11.900083),
    LatLng(57.699452, 11.900467),
    LatLng(57.699567, 11.900957),
    LatLng(57.699626, 11.901217),
    LatLng(57.699697, 11.90156),
    LatLng(57.699732, 11.901741),
    LatLng(57.699755, 11.901844),
    
    // E: End (Intersection 5)
    LatLng(57.699769, 11.901906),

    // Final Destination Extension
    LatLng(57.7005, 11.9050), 
    LatLng(57.7010, 11.9080),
    LatLng(57.701999, 11.911721), // Target
  ];

  // Original intersection points for marking
  static const List<LatLng> _intersections = [
    LatLng(57.69841, 11.89636),
    LatLng(57.69991, 11.89583),
    LatLng(57.699788, 11.897004), // New C (Corrected)
    LatLng(57.69909, 11.89868),
    LatLng(57.699750, 11.901921),
  ];

  late final List<double> _cumDist;
  late final double _totalDist; // Fixed: Restored this variable
  
  // Stop logic
  final List<Map<String, dynamic>> _stops = [];
  static const double _driveDuration = 45.0; // Slower animation
  static const double _stopDuration = 2.0;

  @override
  void initState() {
    super.initState();
    _cumDist = _buildCumulativeDistances();
    _totalDist = _cumDist.last;

    // Define stops: At New C and D
    // Find index for C
    final indexC = _roadPath.indexWhere((p) => 
        (p.latitude - 57.699788).abs() < 0.00001
    );
    // Find index for D
    final indexD = _roadPath.indexWhere((p) => 
        (p.latitude - 57.69909).abs() < 0.00001
    );

    _stops.clear();
    if (indexC != -1) {
      _stops.add({
        'dist': _cumDist[indexC],
        'duration': _stopDuration,
      });
    }
    if (indexD != -1) {
      _stops.add({
        'dist': _cumDist[indexD],
        'duration': _stopDuration,
      });
    }

    final totalStopDuration = _stops.length * _stopDuration;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: ((_driveDuration + totalStopDuration) * 1000).toInt()),
    );
  }

  List<double> _buildCumulativeDistances() {
    final d = <double>[0.0];
    for (int i = 1; i < _roadPath.length; i++) {
      d.add(d.last + _haversine(_roadPath[i - 1], _roadPath[i]));
    }
    return d;
  }

  double _haversine(LatLng a, LatLng b) {
    const r = 6371000.0;
    final dLat = _rad(b.latitude - a.latitude);
    final dLon = _rad(b.longitude - a.longitude);
    final h = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(a.latitude)) * cos(_rad(b.latitude)) *
        sin(dLon / 2) * sin(dLon / 2);
    return 2 * r * asin(sqrt(h));
  }

  double _rad(double deg) => deg * pi / 180;

  LatLng _positionAt(double t) {
    final target = t * _totalDist;
    int seg = 0;
    for (int i = 1; i < _cumDist.length; i++) {
      if (_cumDist[i] >= target) { seg = i - 1; break; }
    }
    if (seg + 1 >= _roadPath.length) return _roadPath.last;
    final segLen = _cumDist[seg + 1] - _cumDist[seg];
    final f = segLen > 0 ? (target - _cumDist[seg]) / segLen : 0.0;
    final from = _roadPath[seg];
    final to = _roadPath[seg + 1];
    return LatLng(
      from.latitude + (to.latitude - from.latitude) * f,
      from.longitude + (to.longitude - from.longitude) * f,
    );
  }

  double _headingAt(LatLng from, LatLng to) {
    final dLon = _rad(to.longitude - from.longitude);
    final y = sin(dLon) * cos(_rad(to.latitude));
    final x = cos(_rad(from.latitude)) * sin(_rad(to.latitude)) -
        sin(_rad(from.latitude)) * cos(_rad(to.latitude)) * cos(dLon);
    return atan2(y, x);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
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
                    // Adjust center to fit new point
                    initialCenter: LatLng(57.700, 11.905),
                    initialZoom: 14.5,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.example.cycleeffect',
                      retinaMode: true,
                    ),
                    // Traffic circles
                    CircleLayer(
                      circles: _buildTrafficCircles(provider.trafficUpdates),
                    ),
                    // Animated car AND Dynamic Polyline
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        final totalSeconds = _controller.duration!.inMilliseconds / 1000.0;
                        final currentTime = _controller.value * totalSeconds;
                        final speed = _totalDist / _driveDuration;

                        // Calculate effective distance
                        double targetDist = 0.0;
                        double timeConsumed = 0.0;
                        bool isStopped = false;
                        
                        // We track "phases": Drive -> Stop -> Drive -> Stop ...
                        double lastDist = 0.0;
                        
                        // Sort stops by distance to be safe
                        _stops.sort((a, b) => (a['dist'] as double).compareTo(b['dist'] as double));

                        for (final stop in _stops) {
                          final stopDist = stop['dist'] as double;
                          final driveDist = stopDist - lastDist;
                          final driveTime = driveDist / speed;
                          
                          // Check if in this drive segment
                          if (currentTime < timeConsumed + driveTime) {
                            targetDist = lastDist + (currentTime - timeConsumed) * speed;
                            isStopped = false;
                            timeConsumed += 999999; // Break loop
                            break;
                          }
                          timeConsumed += driveTime;
                          lastDist = stopDist;

                          // Check if in this stop segment
                          final stopDuration = stop['duration'] as double;
                          if (currentTime < timeConsumed + stopDuration) {
                            targetDist = stopDist;
                            isStopped = true;
                            timeConsumed += 999999; // Break loop
                            break;
                          }
                          timeConsumed += stopDuration;
                        }

                        // Use > check because loop might finish if we are in final segment
                        if (timeConsumed < 900000) {
                           // Final segment
                           targetDist = lastDist + (currentTime - timeConsumed) * speed;
                        }

                        // Map back to 0..1
                        final tMapped = (targetDist / _totalDist).clamp(0.0, 1.0);
                        
                        // Calculate Position and current segment index
                        // We duplicate _positionAt logic slightly to get the segment index
                        // for the dynamic polyline
                        int currentSeg = 0;
                        for (int i = 1; i < _cumDist.length; i++) {
                          if (_cumDist[i] >= targetDist) { currentSeg = i - 1; break; }
                        }
                        if (targetDist >= _totalDist) currentSeg = _roadPath.length - 2;

                        final segLen = _cumDist[currentSeg + 1] - _cumDist[currentSeg];
                        final f = segLen > 0 ? (targetDist - _cumDist[currentSeg]) / segLen : 0.0;
                        final from = _roadPath[currentSeg];
                        final to = _roadPath[currentSeg + 1];
                        final carPos = LatLng(
                          from.latitude + (to.latitude - from.latitude) * f,
                          from.longitude + (to.longitude - from.longitude) * f,
                        );

                        // Build Remaining Path for Polyline
                        final List<LatLng> remainingPath = [carPos];
                        if (currentSeg + 1 < _roadPath.length) {
                          remainingPath.addAll(_roadPath.sublist(currentSeg + 1));
                        }

                        // Calculate Heading
                        double lookAheadT = tMapped + 0.005;
                        if (isStopped) {
                           // Look slightly ahead of current pos to maintain heading
                           // (Since tMapped is constant)
                           lookAheadT = tMapped + 0.001;
                        }
                        
                        final ahead = _positionAt(lookAheadT.clamp(0.0, 1.0));
                        final heading = _headingAt(carPos, ahead);

                        return Stack(
                          children: [
                            // 1. Dynamic Route (Active Path)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: remainingPath,
                                  strokeWidth: 4,
                                  color: Colors.blue.withOpacity(0.8),
                                ),
                              ],
                            ),
                            // 2. Car Marker (Smaller)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: carPos,
                                  width: 28,  // Reduced
                                  height: 28, // Reduced
                                  child: Transform.rotate(
                                    angle: heading,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 1.5),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.blue.withOpacity(0.4),
                                            blurRadius: 6,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.navigation_rounded,
                                        color: Colors.white,
                                        size: 18, // Reduced
                                      ),
                                    ),
                                  ),
                                ),
                                if (provider.userLocation != null)
                                  Marker(
                                    point: LatLng(
                                      provider.userLocation!.latitude,
                                      provider.userLocation!.longitude,
                                    ),
                                    width: 40,
                                    height: 40,
                                    child: _buildUserMarker(
                                        provider.userLocation!.heading),
                                  ),
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
                        );
                      },
                    ),
                  ],
                ),
                // Play/Replay Button
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: FloatingActionButton.extended(
                    heroTag: 'map_play_button',
                    onPressed: () {
                      if (_controller.isAnimating) {
                        _controller.stop();
                      } else {
                        // Restart if completed, otherwise continue
                        if (_controller.value == 1.0) {
                          _controller.forward(from: 0);
                        } else {
                          _controller.forward();
                        }
                      }
                    },
                    backgroundColor: Colors.white,
                    label: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        if (_controller.isAnimating) return const Text('Pause', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600));
                        if (_controller.value == 1.0) return const Text('Replay', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600));
                        return const Text('Start', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600));
                      },
                    ),
                    icon: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) => Icon(
                        _controller.isAnimating
                            ? Icons.pause_rounded
                            : (_controller.value == 1.0 ? Icons.replay_rounded : Icons.play_arrow_rounded),
                        color: AppTheme.accentGreen,
                      ),
                    ),
                  ),
                ),
                // Label
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.navigation_rounded, size: 16, color: Colors.blue),
                        SizedBox(width: 6),
                        Text(
                          'Driving simulation',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
              angle: heading * (pi / 180),
              child: const Icon(Icons.navigation, color: Colors.white, size: 20),
            )
          : const Icon(Icons.my_location, color: Colors.white, size: 20),
    );
  }

  Widget _buildTrafficMarker(TrafficUpdate update) {
    final color = _colorForSeverity(update.severity);
    final hasIncident = update.incident != null;
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.4), blurRadius: 6, spreadRadius: 1),
        ],
      ),
      child: Icon(
        hasIncident ? Icons.warning_rounded : Icons.videocam_rounded,
        color: Colors.white,
        size: 14,
      ),
    );
  }

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