/// Model representing a traffic update from the backend.
///
/// Contains information about traffic conditions at a specific location,
/// including vehicle counts, density levels, and any incidents.
class TrafficUpdate {
  final String id;
  final String cameraId;
  final String location;
  final double latitude;
  final double longitude;
  final int vehicleCount;
  final TrafficDensity density;
  final TrafficIncident? incident;
  final DateTime timestamp;
  final String? direction;

  TrafficUpdate({
    required this.id,
    required this.cameraId,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.vehicleCount,
    required this.density,
    this.incident,
    required this.timestamp,
    this.direction,
  });

  /// Creates a TrafficUpdate from JSON data received via WebSocket.
  factory TrafficUpdate.fromJson(Map<String, dynamic> json) {
    return TrafficUpdate(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      cameraId: json['camera_id']?.toString() ?? json['cameraId']?.toString() ?? 'unknown',
      location: json['location']?.toString() ?? json['name']?.toString() ?? 'Unknown Location',
      latitude: _parseDouble(json['latitude'] ?? json['lat']),
      longitude: _parseDouble(json['longitude'] ?? json['lng'] ?? json['lon']),
      vehicleCount: _parseInt(json['vehicle_count'] ?? json['vehicleCount'] ?? json['count']),
      density: TrafficDensity.fromString(json['density']?.toString()),
      incident: json['incident'] != null ? TrafficIncident.fromJson(json['incident']) : null,
      timestamp: _parseTimestamp(json['timestamp']),
      direction: json['direction']?.toString(),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  /// Returns a human-readable description of the traffic situation.
  String get description {
    final buffer = StringBuffer();
    buffer.write('${vehicleCount} vehicle${vehicleCount == 1 ? '' : 's'}');
    buffer.write(' • ${density.displayName}');
    if (incident != null) {
      buffer.write(' • ${incident!.type.displayName}');
    }
    return buffer.toString();
  }

  /// Returns the color associated with this traffic update's severity.
  TrafficSeverity get severity {
    if (incident != null) return TrafficSeverity.high;
    return density.severity;
  }
}

/// Traffic density levels.
enum TrafficDensity {
  low,
  moderate,
  high,
  unknown;

  static TrafficDensity fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'low':
        return TrafficDensity.low;
      case 'moderate':
      case 'medium':
        return TrafficDensity.moderate;
      case 'high':
      case 'heavy':
        return TrafficDensity.high;
      default:
        return TrafficDensity.unknown;
    }
  }

  String get displayName {
    switch (this) {
      case TrafficDensity.low:
        return 'Light traffic';
      case TrafficDensity.moderate:
        return 'Moderate traffic';
      case TrafficDensity.high:
        return 'Heavy traffic';
      case TrafficDensity.unknown:
        return 'Unknown';
    }
  }

  TrafficSeverity get severity {
    switch (this) {
      case TrafficDensity.low:
        return TrafficSeverity.low;
      case TrafficDensity.moderate:
        return TrafficSeverity.medium;
      case TrafficDensity.high:
        return TrafficSeverity.high;
      case TrafficDensity.unknown:
        return TrafficSeverity.low;
    }
  }
}

/// Traffic incident information.
class TrafficIncident {
  final IncidentType type;
  final String? description;
  final DateTime? reportedAt;

  TrafficIncident({
    required this.type,
    this.description,
    this.reportedAt,
  });

  factory TrafficIncident.fromJson(Map<String, dynamic> json) {
    return TrafficIncident(
      type: IncidentType.fromString(json['type']?.toString()),
      description: json['description']?.toString(),
      reportedAt: json['reported_at'] != null
          ? DateTime.tryParse(json['reported_at'].toString())
          : null,
    );
  }
}

/// Types of traffic incidents.
enum IncidentType {
  accident,
  roadwork,
  congestion,
  hazard,
  unknown;

  static IncidentType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'accident':
        return IncidentType.accident;
      case 'roadwork':
      case 'construction':
        return IncidentType.roadwork;
      case 'congestion':
        return IncidentType.congestion;
      case 'hazard':
        return IncidentType.hazard;
      default:
        return IncidentType.unknown;
    }
  }

  String get displayName {
    switch (this) {
      case IncidentType.accident:
        return 'Accident';
      case IncidentType.roadwork:
        return 'Roadwork';
      case IncidentType.congestion:
        return 'Congestion';
      case IncidentType.hazard:
        return 'Hazard';
      case IncidentType.unknown:
        return 'Incident';
    }
  }
}

/// Severity levels for traffic conditions.
enum TrafficSeverity {
  low,
  medium,
  high,
}
