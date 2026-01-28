/// Model representing the user's current location and movement state.
///
/// Combines GPS coordinates with heading (compass direction) and speed
/// for contextual traffic analysis.
class UserLocation {
  final double latitude;
  final double longitude;
  final double? heading;
  final double? speed;
  final double? accuracy;
  final DateTime timestamp;

  UserLocation({
    required this.latitude,
    required this.longitude,
    this.heading,
    this.speed,
    this.accuracy,
    required this.timestamp,
  });

  /// Returns a cardinal direction string based on heading.
  String? get cardinalDirection {
    if (heading == null) return null;
    final h = heading!;
    if (h >= 337.5 || h < 22.5) return 'North';
    if (h >= 22.5 && h < 67.5) return 'Northeast';
    if (h >= 67.5 && h < 112.5) return 'East';
    if (h >= 112.5 && h < 157.5) return 'Southeast';
    if (h >= 157.5 && h < 202.5) return 'South';
    if (h >= 202.5 && h < 247.5) return 'Southwest';
    if (h >= 247.5 && h < 292.5) return 'West';
    if (h >= 292.5 && h < 337.5) return 'Northwest';
    return null;
  }

  /// Returns speed in km/h.
  double? get speedKmh {
    if (speed == null) return null;
    return speed! * 3.6; // m/s to km/h
  }

  /// Returns a formatted speed string.
  String? get formattedSpeed {
    final kmh = speedKmh;
    if (kmh == null) return null;
    return '${kmh.round()} km/h';
  }

  @override
  String toString() {
    return 'UserLocation(lat: $latitude, lng: $longitude, heading: $cardinalDirection, speed: $formattedSpeed)';
  }
}
