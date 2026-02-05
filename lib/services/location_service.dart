import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import '../models/user_location.dart';

/// Service for managing GPS location tracking.
///
/// Provides real-time location updates including position, heading, and speed.
/// Handles permission requests and location settings.
class LocationService {
  StreamSubscription<Position>? _positionSubscription;
  final StreamController<UserLocation> _locationController =
      StreamController<UserLocation>.broadcast();

  /// Stream of location updates.
  Stream<UserLocation> get locationStream => _locationController.stream;

  /// Current location (cached from last update).
  UserLocation? _currentLocation;
  UserLocation? get currentLocation => _currentLocation;

  /// Checks and requests location permissions.
  ///
  /// Returns true if permissions are granted, false otherwise.
  Future<bool> requestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Gets the current location once.
  Future<UserLocation?> getCurrentLocation() async {
    try {
      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        if (kIsWeb) {
          // On web, return default location (Gothenburg)
          _currentLocation = UserLocation(
            latitude: 57.7089,
            longitude: 11.9746,
            heading: 0,
            speed: 0,
            accuracy: 100,
            timestamp: DateTime.now(),
          );
          return _currentLocation;
        }
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      _currentLocation = _positionToUserLocation(position);
      return _currentLocation;
    } catch (e) {
      print('Error getting current location: $e');
      if (kIsWeb) {
        // On web, return default location
        _currentLocation = UserLocation(
          latitude: 57.7089,
          longitude: 11.9746,
          heading: 0,
          speed: 0,
          accuracy: 100,
          timestamp: DateTime.now(),
        );
        return _currentLocation;
      }
      return null;
    }
  }

  /// Starts continuous location tracking.
  ///
  /// Updates are emitted to [locationStream] at the specified interval.
  Future<void> startTracking({
    Duration interval = const Duration(seconds: 2),
  }) async {
    try {
      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        if (kIsWeb) {
          print('Location: Web geolocation denied - using default location');
          // On web, provide a default location (Gothenburg) so the app still works
          _currentLocation = UserLocation(
            latitude: 57.7089,
            longitude: 11.9746,
            heading: 0,
            speed: 0,
            accuracy: 100,
            timestamp: DateTime.now(),
          );
          _locationController.add(_currentLocation!);
        } else {
          _locationController.addError('Location permission denied');
        }
        return;
      }

      // Cancel any existing subscription
      await stopTracking();

      final locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Minimum distance (meters) before update
      );

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          _currentLocation = _positionToUserLocation(position);
          _locationController.add(_currentLocation!);
        },
        onError: (error) {
          print('Location stream error: $error');
          if (kIsWeb) {
            // On web, fall back to default location
            _currentLocation = UserLocation(
              latitude: 57.7089,
              longitude: 11.9746,
              heading: 0,
              speed: 0,
              accuracy: 100,
              timestamp: DateTime.now(),
            );
            _locationController.add(_currentLocation!);
          } else {
            _locationController.addError(error);
          }
        },
      );
    } catch (e) {
      print('Location tracking error: $e');
      if (kIsWeb) {
        // On web, fall back to default location
        _currentLocation = UserLocation(
          latitude: 57.7089,
          longitude: 11.9746,
          heading: 0,
          speed: 0,
          accuracy: 100,
          timestamp: DateTime.now(),
        );
        _locationController.add(_currentLocation!);
      }
    }
  }

  /// Stops location tracking.
  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  /// Converts a Geolocator Position to our UserLocation model.
  UserLocation _positionToUserLocation(Position position) {
    return UserLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      heading: position.heading,
      speed: position.speed,
      accuracy: position.accuracy,
      timestamp: position.timestamp,
    );
  }

  /// Calculates the distance between two locations in meters.
  double distanceBetween(UserLocation loc1, UserLocation loc2) {
    return Geolocator.distanceBetween(
      loc1.latitude,
      loc1.longitude,
      loc2.latitude,
      loc2.longitude,
    );
  }

  /// Opens device location settings.
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Opens app settings for permission management.
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Disposes of resources.
  void dispose() {
    stopTracking();
    _locationController.close();
  }
}
