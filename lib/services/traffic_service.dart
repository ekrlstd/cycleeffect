import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config.dart';
import '../models/traffic_update.dart';

/// Service for managing WebSocket connection to the traffic data backend.
///
/// Connects to the backend WebSocket server and streams real-time traffic
/// updates from Trafikverket via Supabase.
class TrafficService {
  WebSocketChannel? _channel;
  final StreamController<TrafficUpdate> _updateController =
      StreamController<TrafficUpdate>.broadcast();
  final StreamController<ConnectionState> _connectionController =
      StreamController<ConnectionState>.broadcast();

  /// Stream of traffic updates.
  Stream<TrafficUpdate> get trafficStream => _updateController.stream;

  /// Stream of connection state changes.
  Stream<ConnectionState> get connectionStream => _connectionController.stream;

  /// List of recent traffic updates (kept for UI display).
  final List<TrafficUpdate> _recentUpdates = [];
  List<TrafficUpdate> get recentUpdates => List.unmodifiable(_recentUpdates);

  /// Maximum number of recent updates to keep.
  static const int maxRecentUpdates = 20;

  /// Current connection state.
  ConnectionState _connectionState = ConnectionState.disconnected;
  ConnectionState get connectionState => _connectionState;

  /// WebSocket URL for the backend (configured in config.dart).
  String _wsUrl = AppConfig.webSocketUrl;

  /// Sets the WebSocket URL (for configuration).
  void setWebSocketUrl(String url) {
    _wsUrl = url;
  }

  /// Connects to the WebSocket server.
  Future<void> connect() async {
    if (_connectionState == ConnectionState.connected ||
        _connectionState == ConnectionState.connecting) {
      return;
    }

    _setConnectionState(ConnectionState.connecting);

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));

      // Wait for connection to be established
      await _channel!.ready;

      _setConnectionState(ConnectionState.connected);

      // Listen for messages
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
        cancelOnError: false,
      );
    } catch (e) {
      print('WebSocket connection error: $e');
      _setConnectionState(ConnectionState.error);
      _connectionController.addError(e);

      // Try to reconnect after delay
      _scheduleReconnect();
    }
  }

  /// Disconnects from the WebSocket server.
  Future<void> disconnect() async {
    _setConnectionState(ConnectionState.disconnected);
    await _channel?.sink.close();
    _channel = null;
  }

  /// Handles incoming WebSocket messages.
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String);

      // Handle different message types from the backend
      if (data is Map<String, dynamic>) {
        final update = TrafficUpdate.fromJson(data);
        _addUpdate(update);
      } else if (data is List) {
        // Handle batch updates
        for (final item in data) {
          if (item is Map<String, dynamic>) {
            final update = TrafficUpdate.fromJson(item);
            _addUpdate(update);
          }
        }
      }
    } catch (e) {
      print('Error parsing traffic message: $e');
      print('Raw message: $message');
    }
  }

  /// Adds an update to the stream and recent updates list.
  void _addUpdate(TrafficUpdate update) {
    _recentUpdates.insert(0, update);
    if (_recentUpdates.length > maxRecentUpdates) {
      _recentUpdates.removeLast();
    }
    _updateController.add(update);
  }

  /// Handles WebSocket errors.
  void _handleError(dynamic error) {
    print('WebSocket error: $error');
    _setConnectionState(ConnectionState.error);
    _connectionController.addError(error);
    _scheduleReconnect();
  }

  /// Handles WebSocket connection close.
  void _handleDone() {
    print('WebSocket connection closed');
    if (_connectionState != ConnectionState.disconnected) {
      _setConnectionState(ConnectionState.error);
      _scheduleReconnect();
    }
  }

  /// Schedules a reconnection attempt.
  void _scheduleReconnect() {
    if (_connectionState == ConnectionState.disconnected) return;

    Future.delayed(const Duration(seconds: 5), () {
      if (_connectionState != ConnectionState.connected &&
          _connectionState != ConnectionState.disconnected) {
        print('Attempting to reconnect...');
        connect();
      }
    });
  }

  /// Updates the connection state.
  void _setConnectionState(ConnectionState state) {
    _connectionState = state;
    _connectionController.add(state);
  }

  /// Adds mock data for testing when backend is unavailable.
  void addMockData() {
    final mockUpdates = [
      TrafficUpdate(
        id: '1',
        cameraId: 'cam_001',
        location: 'E6 Northbound - Gothenburg',
        latitude: 57.7089,
        longitude: 11.9746,
        vehicleCount: 12,
        density: TrafficDensity.moderate,
        timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
        direction: 'North',
      ),
      TrafficUpdate(
        id: '2',
        cameraId: 'cam_002',
        location: 'Kungsgatan - City Center',
        latitude: 57.7010,
        longitude: 11.9650,
        vehicleCount: 5,
        density: TrafficDensity.low,
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
        direction: 'East',
      ),
      TrafficUpdate(
        id: '3',
        cameraId: 'cam_003',
        location: 'E20 Junction - Heavy Traffic',
        latitude: 57.7150,
        longitude: 11.9800,
        vehicleCount: 23,
        density: TrafficDensity.high,
        incident: TrafficIncident(
          type: IncidentType.congestion,
          description: 'Rush hour congestion',
        ),
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
        direction: 'West',
      ),
      TrafficUpdate(
        id: '4',
        cameraId: 'cam_004',
        location: 'Avenyn - Roundabout',
        latitude: 57.6980,
        longitude: 11.9780,
        vehicleCount: 8,
        density: TrafficDensity.moderate,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        direction: 'South',
      ),
      TrafficUpdate(
        id: '5',
        cameraId: 'cam_005',
        location: 'Highway E45 - Accident Zone',
        latitude: 57.7200,
        longitude: 11.9500,
        vehicleCount: 3,
        density: TrafficDensity.low,
        incident: TrafficIncident(
          type: IncidentType.accident,
          description: 'Minor collision, right lane blocked',
        ),
        timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
        direction: 'North',
      ),
    ];

    for (final update in mockUpdates) {
      _addUpdate(update);
    }
  }

  /// Disposes of resources.
  void dispose() {
    disconnect();
    _updateController.close();
    _connectionController.close();
  }
}

/// WebSocket connection states.
enum ConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}
