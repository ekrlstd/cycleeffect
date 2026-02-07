import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/route_model.dart';

/// Service for communicating with the real route/traffic backend.
class RouteService {
  final http.Client _client = http.Client();

  Map<String, String> get _headers => {
        'X-API-Key': AppConfig.apiKey,
        'Content-Type': 'application/json',
      };

  /// Create a route by destination name. Returns real route + traffic data.
  Future<RouteResult?> createRoute(
    String destinationName, {
    double? originLat,
    double? originLon,
  }) async {
    try {
      final body = {
        'destination_name': destinationName,
        if (originLat != null) 'origin_lat': originLat,
        if (originLon != null) 'origin_lon': originLon,
      };
      print('RouteService: POST ${AppConfig.baseUrl}/api/route');
      print('RouteService: body=$body');
      final resp = await _client.post(
        Uri.parse('${AppConfig.baseUrl}/api/route'),
        headers: _headers,
        body: jsonEncode(body),
      );
      print('RouteService: status=${resp.statusCode}');
      print('RouteService: response length=${resp.body.length}');

      if (resp.statusCode != 200) {
        print('RouteService: createRoute failed: ${resp.statusCode} ${resp.body}');
        return null;
      }

      // Debug: print raw JSON keys
      final jsonData = jsonDecode(resp.body) as Map<String, dynamic>;
      print('RouteService: JSON keys=${jsonData.keys.toList()}');
      print('RouteService: traffic_sites type=${jsonData["traffic_sites"]?.runtimeType}');
      print('RouteService: traffic_sites length=${(jsonData["traffic_sites"] as List?)?.length}');
      print('RouteService: cameras type=${jsonData["cameras"]?.runtimeType}');
      print('RouteService: cameras length=${(jsonData["cameras"] as List?)?.length}');

      return RouteResult.fromJson(jsonData);
    } catch (e, stack) {
      print('RouteService: createRoute error: $e');
      print('RouteService: stack: $stack');
      return null;
    }
  }

  /// Get fresh traffic data for an existing route.
  Future<Map<String, dynamic>?> getTrafficForRoute(String routeId) async {
    try {
      final resp = await _client.get(
        Uri.parse('${AppConfig.baseUrl}/api/route/$routeId/traffic'),
        headers: _headers,
      );
      if (resp.statusCode != 200) return null;
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } catch (e) {
      print('RouteService: getTrafficForRoute error: $e');
      return null;
    }
  }

  /// Send a voice query and get a real contextual response.
  Future<String> sendVoiceQuery(
    String text, {
    String? routeId,
    double? lat,
    double? lon,
  }) async {
    try {
      final body = {
        'text': text,
        if (routeId != null) 'route_id': routeId,
        if (lat != null) 'lat': lat,
        if (lon != null) 'lon': lon,
      };
      final resp = await _client.post(
        Uri.parse('${AppConfig.baseUrl}/api/voice'),
        headers: _headers,
        body: jsonEncode(body),
      );
      if (resp.statusCode != 200) return 'Unable to get traffic information right now.';
      final data = jsonDecode(resp.body);
      return data['response'] ?? 'No response available.';
    } catch (e) {
      print('RouteService: sendVoiceQuery error: $e');
      return 'Connection error. Please try again.';
    }
  }

  /// Create a route from coordinates (tap-to-destination).
  Future<RouteResult?> createRouteFromCoords(
    double destLat,
    double destLon, {
    double? originLat,
    double? originLon,
  }) async {
    try {
      final body = {
        'dest_lat': destLat,
        'dest_lon': destLon,
        if (originLat != null) 'origin_lat': originLat,
        if (originLon != null) 'origin_lon': originLon,
      };
      final resp = await _client.post(
        Uri.parse('${AppConfig.baseUrl}/api/route/coords'),
        headers: _headers,
        body: jsonEncode(body),
      );
      if (resp.statusCode != 200) {
        print('RouteService: createRouteFromCoords failed: ${resp.statusCode} ${resp.body}');
        return null;
      }
      return RouteResult.fromJson(jsonDecode(resp.body));
    } catch (e) {
      print('RouteService: createRouteFromCoords error: $e');
      return null;
    }
  }

  /// Check if a reroute is needed due to severe incidents.
  Future<RerouteInfo?> checkReroute(String routeId) async {
    try {
      final resp = await _client.get(
        Uri.parse('${AppConfig.baseUrl}/api/route/$routeId/reroute'),
        headers: _headers,
      );
      if (resp.statusCode != 200) return null;
      return RerouteInfo.fromJson(jsonDecode(resp.body));
    } catch (e) {
      print('RouteService: checkReroute error: $e');
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}
