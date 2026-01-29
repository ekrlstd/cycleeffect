import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Provider that manages checkpoint-based navigation and coordinates with narration.
/// 
/// Flow:
/// 1. User presses play on map → starts navigation
/// 2. As car moves, calculates which checkpoint is next
/// 3. When approaching checkpoint → triggers narration for that intersection
/// 4. When passing checkpoint → switches to next
class NavigationProvider with ChangeNotifier {
  // 4 Checkpoint locations (Synced with map_card.dart - Route now ends at D)
  static const List<LatLng> checkpoints = [
    LatLng(57.69841, 11.89636), // Checkpoint 1 (Junction A)
    LatLng(57.69992, 11.89583), // Checkpoint 2 (Junction B)
    LatLng(57.6988, 11.9025),   // Checkpoint 3 (Junction C)
    LatLng(57.7000, 11.9145),   // Checkpoint 4 (Destination - Junction D)
  ];
  
  // Threshold distance to trigger checkpoint narration (meters)
  // Increased thresholds for earlier detection
  static const double approachThreshold = 80.0;  // Trigger narration 80m before
  static const double passedThreshold = 30.0;    // Mark passed at 30m
  
  bool _isNavigating = false;
  bool get isNavigating => _isNavigating;
  
  int _currentCheckpointIndex = 0; // 0-based index
  int get currentCheckpoint => _currentCheckpointIndex + 1; // 1-based for display
  
  LatLng? _carPosition;
  LatLng? get carPosition => _carPosition;
  
  double _distanceToNextCheckpoint = 0.0;
  double get distanceToNextCheckpoint => _distanceToNextCheckpoint;
  
  // Set of checkpoints that have been passed (to avoid re-triggering)
  final Set<int> _passedCheckpoints = {};
  
  // Callback for when we should fetch narration for a checkpoint
  Function(int intersectionId)? onApproachingCheckpoint;
  
  // Callback for when navigation starts/stops
  Function(bool isNavigating)? onNavigationStateChanged;
  
  /// Start navigation - called when play button is pressed
  void startNavigation() {
    if (_isNavigating) return;
    
    _isNavigating = true;
    _currentCheckpointIndex = 0;
    _passedCheckpoints.clear();
    
    print("NavigationProvider: Started navigation");
    onNavigationStateChanged?.call(true);
    
    // Trigger narration for first checkpoint
    onApproachingCheckpoint?.call(1);
    
    notifyListeners();
  }
  
  /// Pause navigation
  void pauseNavigation() {
    _isNavigating = false;
    print("NavigationProvider: Paused navigation");
    onNavigationStateChanged?.call(false);
    notifyListeners();
  }
  
  /// Resume navigation
  void resumeNavigation() {
    if (_isNavigating) return;
    
    _isNavigating = true;
    print("NavigationProvider: Resumed navigation");
    onNavigationStateChanged?.call(true);
    
    // Re-trigger narration for current checkpoint
    onApproachingCheckpoint?.call(_currentCheckpointIndex + 1);
    
    notifyListeners();
  }
  
  /// Reset navigation to beginning
  void resetNavigation() {
    _isNavigating = false;
    _currentCheckpointIndex = 0;
    _passedCheckpoints.clear();
    _carPosition = null;
    _distanceToNextCheckpoint = 0.0;
    
    print("NavigationProvider: Reset navigation");
    onNavigationStateChanged?.call(false);
    notifyListeners();
  }
  
  /// Update car position - called by MapCard animation
  void updateCarPosition(LatLng position) {
    _carPosition = position;
    
    if (!_isNavigating) return;
    if (_currentCheckpointIndex >= checkpoints.length) return;
    
    final nextCheckpoint = checkpoints[_currentCheckpointIndex];
    _distanceToNextCheckpoint = _haversineDistance(position, nextCheckpoint);
    
    // Check if we've passed this checkpoint
    if (_distanceToNextCheckpoint < passedThreshold && 
        !_passedCheckpoints.contains(_currentCheckpointIndex)) {
      _passedCheckpoints.add(_currentCheckpointIndex);
      print("NavigationProvider: Passed checkpoint ${_currentCheckpointIndex + 1}");
      
      // Move to next checkpoint
      if (_currentCheckpointIndex < checkpoints.length - 1) {
        _currentCheckpointIndex++;
        print("NavigationProvider: Now heading to checkpoint ${_currentCheckpointIndex + 1}");
        
        // Trigger narration for new checkpoint
        onApproachingCheckpoint?.call(_currentCheckpointIndex + 1);
      } else {
        // Reached final checkpoint
        print("NavigationProvider: Reached final destination!");
        _isNavigating = false;
        onNavigationStateChanged?.call(false);
      }
    }
    
    notifyListeners();
  }
  
  /// Calculate distance between two points (Haversine formula)
  double _haversineDistance(LatLng a, LatLng b) {
    const r = 6371000.0; // Earth radius in meters
    final dLat = _rad(b.latitude - a.latitude);
    final dLon = _rad(b.longitude - a.longitude);
    final h = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(a.latitude)) * cos(_rad(b.latitude)) *
        sin(dLon / 2) * sin(dLon / 2);
    return 2 * r * asin(sqrt(h));
  }
  
  double _rad(double deg) => deg * pi / 180;
  
  /// Get checkpoint name for display
  String getCheckpointName(int index) {
    if (index < 0 || index >= checkpoints.length) return "Unknown";
    switch (index) {
      case 0: return "Start";
      case 1: return "Junction A";
      case 2: return "Junction B";
      case 3: return "Destination"; // Final point (Intersection 4)
      default: return "Checkpoint ${index + 1}";
    }
  }
}
