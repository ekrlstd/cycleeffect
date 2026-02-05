import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/route_model.dart';
import '../services/route_service.dart';

/// Central state for the active route with real traffic data.
class RouteProvider extends ChangeNotifier {
  final RouteService _routeService = RouteService();

  RouteResult? _activeRoute;
  RouteResult? get activeRoute => _activeRoute;

  List<AlternativeRoute> _alternatives = [];
  List<AlternativeRoute> get alternatives => _alternatives;

  RerouteInfo? _pendingReroute;
  RerouteInfo? get pendingReroute => _pendingReroute;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  List<TrafficSite> _trafficSites = [];
  List<TrafficSite> get trafficSites => _trafficSites;

  List<Situation> _situations = [];
  List<Situation> get situations => _situations;

  Timer? _refreshTimer;

  void _applyResult(RouteResult result) {
    _activeRoute = result;
    _trafficSites = result.trafficSites;
    _situations = result.situations;
    _alternatives = result.alternatives;
    _isLoading = false;
    _error = null;
    _pendingReroute = null;
    notifyListeners();
    _startRefresh();
  }

  /// Create a route by destination name. Fetches real data from backend.
  Future<bool> createRoute(String destinationName, {double? originLat, double? originLon}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _routeService.createRoute(
      destinationName,
      originLat: originLat,
      originLon: originLon,
    );

    if (result == null) {
      _isLoading = false;
      _error = 'Could not find route to "$destinationName"';
      notifyListeners();
      return false;
    }

    _applyResult(result);
    return true;
  }

  /// Create a route from map tap coordinates.
  Future<bool> createRouteFromCoords(double destLat, double destLon, {double? originLat, double? originLon}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _routeService.createRouteFromCoords(
      destLat, destLon,
      originLat: originLat,
      originLon: originLon,
    );

    if (result == null) {
      _isLoading = false;
      _error = 'Could not find route to that location';
      notifyListeners();
      return false;
    }

    _applyResult(result);
    return true;
  }

  /// Switch to an alternative route by its route_id.
  void switchToAlternative(String altRouteId) {
    final altIdx = _alternatives.indexWhere((a) => a.routeId == altRouteId);
    if (altIdx == -1 || _activeRoute == null) return;

    final alt = _alternatives[altIdx];
    // Build a new alternatives list: old primary + remaining alts (without the selected one)
    final newAlts = <AlternativeRoute>[
      AlternativeRoute(
        routeId: _activeRoute!.routeId,
        geometry: _activeRoute!.geometry,
        distanceM: _activeRoute!.distanceM,
        durationS: _activeRoute!.durationS,
        trafficSites: _activeRoute!.trafficSites,
      ),
      ..._alternatives.where((a) => a.routeId != altRouteId),
    ];

    _activeRoute = RouteResult(
      routeId: alt.routeId,
      destination: _activeRoute!.destination,
      geometry: alt.geometry,
      distanceM: alt.distanceM,
      durationS: alt.durationS,
      trafficSites: alt.trafficSites,
      situations: _situations,
      alternatives: newAlts,
    );
    _trafficSites = alt.trafficSites;
    _alternatives = newAlts;
    notifyListeners();
  }

  /// Accept a pending reroute.
  void acceptReroute() {
    if (_pendingReroute?.alternative == null || _activeRoute == null) return;
    final alt = _pendingReroute!.alternative!;
    _activeRoute = RouteResult(
      routeId: alt.routeId,
      destination: _activeRoute!.destination,
      geometry: alt.geometry,
      distanceM: alt.distanceM,
      durationS: alt.durationS,
      trafficSites: alt.trafficSites,
      situations: _situations,
    );
    _trafficSites = alt.trafficSites;
    _alternatives = [];
    _pendingReroute = null;
    notifyListeners();
  }

  /// Dismiss a pending reroute.
  void dismissReroute() {
    _pendingReroute = null;
    notifyListeners();
  }

  /// Refresh traffic data for the active route.
  Future<void> refreshTraffic() async {
    if (_activeRoute == null) return;

    final data = await _routeService.getTrafficForRoute(_activeRoute!.routeId);
    if (data == null) return;

    _trafficSites = (data['traffic_flow'] as List? ?? [])
        .map<TrafficSite>((s) => TrafficSite.fromJson(s as Map<String, dynamic>))
        .toList();
    _situations = (data['situations'] as List? ?? [])
        .map<Situation>((s) => Situation.fromJson(s as Map<String, dynamic>))
        .toList();
    notifyListeners();

    // Check for reroute
    if (_pendingReroute == null) {
      final reroute = await _routeService.checkReroute(_activeRoute!.routeId);
      if (reroute != null && reroute.rerouteNeeded) {
        _pendingReroute = reroute;
        notifyListeners();
      }
    }
  }

  /// Send a voice query with route context.
  Future<String> sendVoiceQuery(String text, {double? lat, double? lon}) async {
    return _routeService.sendVoiceQuery(
      text,
      routeId: _activeRoute?.routeId,
      lat: lat,
      lon: lon,
    );
  }

  void _startRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      refreshTraffic();
    });
  }

  /// Cancel an in-progress loading operation.
  void cancelLoading() {
    if (_isLoading) {
      _isLoading = false;
      _error = 'Search cancelled';
      notifyListeners();
    }
  }

  void clearRoute() {
    _refreshTimer?.cancel();
    _activeRoute = null;
    _trafficSites = [];
    _situations = [];
    _alternatives = [];
    _error = null;
    _pendingReroute = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _routeService.dispose();
    super.dispose();
  }
}
