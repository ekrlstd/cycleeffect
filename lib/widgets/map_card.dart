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
import '../providers/navigation_provider.dart';
import '../theme/app_theme.dart';

/// Map card widget with animated car driving along real roads.
class MapCard extends StatefulWidget {
  const MapCard({super.key});

  @override
  State<MapCard> createState() => _MapCardState();
}

class _MapCardState extends State<MapCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Extended road path with checkpoint (intersection) markers spaced further apart
  // Navigation starts BEFORE checkpoint 1 and moves toward it
  static final List<LatLng> _roadPath = [
    // === STARTING ZONE (before checkpoint 1) ===
    // Extended start - heading towards checkpoint 1
    LatLng(57.6960, 11.8920),   // Far start point
    LatLng(57.6965, 11.8925),
    LatLng(57.6970, 11.8930),
    LatLng(57.6975, 11.8935),
    LatLng(57.6978, 11.8940),
    LatLng(57.6980, 11.8950),
    LatLng(57.6982, 11.8955),
    LatLng(57.6984, 11.8963),   // Approaching checkpoint 1

    // === CHECKPOINT 1 ===
    LatLng(57.69841, 11.89636),
    
    // Checkpoint 1 -> Checkpoint 2 (longer path)
    LatLng(57.6988, 11.8960),
    LatLng(57.6992, 11.8958),
    LatLng(57.6996, 11.8958),
    LatLng(57.6999, 11.8958),
    
    // === CHECKPOINT 2 ===
    LatLng(57.69992, 11.89583),
    
    // Checkpoint 2 -> Checkpoint 3 (extended curve path)
    LatLng(57.7001, 11.8962),
    LatLng(57.7002, 11.8968),
    LatLng(57.7001, 11.8975),
    LatLng(57.6999, 11.8982),
    LatLng(57.6996, 11.8990),
    LatLng(57.6993, 11.9000),
    LatLng(57.6990, 11.9015),
    
    // === CHECKPOINT 3 ===
    LatLng(57.6988, 11.9025),
    
    // Checkpoint 3 -> Checkpoint 4 (longer segment)
    LatLng(57.6986, 11.9040),
    LatLng(57.6985, 11.9055),
    LatLng(57.6986, 11.9070),
    LatLng(57.6988, 11.9085),
    LatLng(57.6992, 11.9100),
    LatLng(57.6995, 11.9115),
    LatLng(57.6998, 11.9130),
    
    // === CHECKPOINT 4 ===
    LatLng(57.7000, 11.9145),
    
    // Checkpoint 4 -> Checkpoint 5 (final stretch)
    LatLng(57.7002, 11.9160),
    LatLng(57.7005, 11.9180),
    LatLng(57.7008, 11.9200),
    LatLng(57.7010, 11.9220),
    LatLng(57.7012, 11.9240),
    LatLng(57.7014, 11.9260),
    
    // === CHECKPOINT 5 (Destination) ===
    LatLng(57.7015, 11.9280),
    
    // Continue past destination
    LatLng(57.7018, 11.9300),
    LatLng(57.7020, 11.9320),
  ];

  // Widely spaced checkpoint (intersection) positions
  static const List<LatLng> _intersections = [
    LatLng(57.69841, 11.89636), // Checkpoint 1
    LatLng(57.69992, 11.89583), // Checkpoint 2
    LatLng(57.6988, 11.9025),    // Checkpoint 3 (further out)
    LatLng(57.7000, 11.9145),    // Checkpoint 4 (further out)
    LatLng(57.7015, 11.9280),    // Checkpoint 5 (destination)
  ];

  late final List<double> _cumDist;
  late final double _totalDist;
  
  // Timing configuration
  final List<Map<String, dynamic>> _stops = [];
  static const double _driveDuration = 90.0; // 90 seconds total (~15-18 sec per segment)
  static const double _stopDuration = 3.0;   // 3 second pause at each checkpoint

  @override
  void initState() {
    super.initState();
    _cumDist = _buildCumulativeDistances();
    _totalDist = _cumDist.last;

    // Define stops at checkpoints 3 and 4 (brief pauses during navigation)
    // Find index for checkpoint 3
    final indexC3 = _roadPath.indexWhere((p) => 
        (p.latitude - 57.6988).abs() < 0.0001 && (p.longitude - 11.9025).abs() < 0.0001
    );
    // Find index for checkpoint 4
    final indexC4 = _roadPath.indexWhere((p) => 
        (p.latitude - 57.7000).abs() < 0.0001 && (p.longitude - 11.9145).abs() < 0.0001
    );

    _stops.clear();
    if (indexC3 != -1) {
      _stops.add({
        'dist': _cumDist[indexC3],
        'duration': _stopDuration,
      });
    }
    if (indexC4 != -1) {
      _stops.add({
        'dist': _cumDist[indexC4],
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
                    // Centered on route with extended path
                    initialCenter: LatLng(57.698, 11.910),
                    initialZoom: 13.5, // Zoomed out to fit wider area
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

                        // Update navigation provider with car position (scheduled to avoid setState during build)
                        if (_controller.isAnimating) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              final navProvider = Provider.of<NavigationProvider>(context, listen: false);
                              navProvider.updateCarPosition(carPos);
                            }
                          });
                        }
                        
                        // Get current checkpoint for display (read-only, no setState)
                        final navProvider = Provider.of<NavigationProvider>(context, listen: false);


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
                            // 2. Checkpoint Markers
                            MarkerLayer(
                              markers: [
                                // Checkpoint markers (numbered 1-5)
                                ...List.generate(_intersections.length, (index) {
                                  final checkpoint = _intersections[index];
                                  final isNext = index == navProvider.currentCheckpoint - 1;
                                  return Marker(
                                    point: checkpoint,
                                    width: 32,
                                    height: 32,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isNext ? Colors.orange : Colors.green,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (isNext ? Colors.orange : Colors.green).withOpacity(0.4),
                                            blurRadius: 6,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                                // Car Marker
                                Marker(
                                  point: carPos,
                                  width: 28,
                                  height: 28,
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
                                        size: 18,
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
                // Play/Replay Button - connected to NavigationProvider
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Consumer<NavigationProvider>(
                    builder: (context, navProvider, _) {
                      return FloatingActionButton.extended(
                        heroTag: 'map_play_button',
                        onPressed: () {
                          if (_controller.isAnimating) {
                            _controller.stop();
                            navProvider.pauseNavigation();
                          } else {
                            if (_controller.value == 1.0) {
                              _controller.forward(from: 0);
                              navProvider.resetNavigation();
                              navProvider.startNavigation();
                            } else if (_controller.value == 0.0) {
                              _controller.forward();
                              navProvider.startNavigation();
                            } else {
                              _controller.forward();
                              navProvider.resumeNavigation();
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
                      );
                    },
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