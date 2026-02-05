import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Provider that manages navigation state.
/// Works with real GPS tracking and dynamic routes from RouteProvider.
class NavigationProvider with ChangeNotifier {
  bool _isNavigating = false;
  bool get isNavigating => _isNavigating;

  LatLng? _carPosition;
  LatLng? get carPosition => _carPosition;

  String? _destinationName;
  String? get destinationName => _destinationName;

  StreamSubscription<Position>? _positionStream;

  // Callback for navigation state changes
  Function(bool isNavigating)? onNavigationStateChanged;

  void startNavigation() {
    if (_isNavigating) return;
    _isNavigating = true;
    print("NavigationProvider: Started navigation");
    onNavigationStateChanged?.call(true);
    _startGpsTracking();
    notifyListeners();
  }

  void pauseNavigation() {
    _isNavigating = false;
    print("NavigationProvider: Paused navigation");
    onNavigationStateChanged?.call(false);
    notifyListeners();
  }

  void resumeNavigation() {
    if (_isNavigating) return;
    _isNavigating = true;
    print("NavigationProvider: Resumed navigation");
    onNavigationStateChanged?.call(true);
    notifyListeners();
  }

  void resetNavigation() {
    _isNavigating = false;
    _carPosition = null;
    _destinationName = null;
    _stopGpsTracking();
    print("NavigationProvider: Reset navigation");
    onNavigationStateChanged?.call(false);
    notifyListeners();
  }

  Future<void> _startGpsTracking() async {
    _stopGpsTracking();
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print("NavigationProvider: GPS permission denied");
        return;
      }
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((position) {
        _carPosition = LatLng(position.latitude, position.longitude);
        notifyListeners();
      }, onError: (e) {
        print("NavigationProvider: GPS error: $e");
      });
    } catch (e) {
      print("NavigationProvider: GPS init error: $e");
    }
  }

  void _stopGpsTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  /// Update car position from real GPS.
  void updateCarPosition(LatLng position) {
    _carPosition = position;
    notifyListeners();
  }

  void setDestinationName(String name) {
    _destinationName = name;
    notifyListeners();
  }
}
