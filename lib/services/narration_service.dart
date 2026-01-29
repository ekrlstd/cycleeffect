import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service that connects to the backend SSE endpoint for narration.
/// Receives pre-generated narration text from the SLM every ~10 seconds.
class NarrationService {
  // Backend URL - change to your server's IP for device testing
  static const String _baseUrl = 'http://localhost:8000';
  
  int _currentIntersectionId = 1;
  http.Client? _client;
  StreamSubscription? _subscription;
  bool _isRunning = false;
  
  final StreamController<String> _narrationController = StreamController<String>.broadcast();
  Stream<String> get narrationStream => _narrationController.stream;
  
  /// Start listening to narration stream for the given intersection.
  void start({int intersectionId = 1}) {
    if (_isRunning && intersectionId == _currentIntersectionId) {
      return; // Already running for this intersection
    }
    
    stop(); // Stop any existing connection
    
    _currentIntersectionId = intersectionId;
    _isRunning = true;
    _connectToSSE();
  }
  
  /// Stop the narration stream.
  void stop() {
    _isRunning = false;
    _subscription?.cancel();
    _subscription = null;
    _client?.close();
    _client = null;
  }
  
  /// Change to a different intersection (1-5).
  void switchIntersection(int intersectionId) {
    if (intersectionId < 1 || intersectionId > 5) {
      print("NarrationService: Invalid intersection ID $intersectionId");
      return;
    }
    start(intersectionId: intersectionId);
  }
  
  int get currentIntersectionId => _currentIntersectionId;
  
  Future<void> _connectToSSE() async {
    final url = '$_baseUrl/narration/$_currentIntersectionId';
    print("NarrationService: Connecting to $url");
    
    try {
      _client = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';
      
      final response = await _client!.send(request);
      
      if (response.statusCode != 200) {
        print("NarrationService: Connection failed with status ${response.statusCode}");
        _scheduleReconnect();
        return;
      }
      
      print("NarrationService: Connected successfully");
      
      // Listen to the SSE stream and process line by line
      String lineBuffer = '';
      String? currentEvent;
      String? currentData;
      
      _subscription = response.stream
          .transform(utf8.decoder)
          .listen(
            (chunk) {
              lineBuffer += chunk;
              
              // Process complete lines
              while (lineBuffer.contains('\n')) {
                final lineEnd = lineBuffer.indexOf('\n');
                String line = lineBuffer.substring(0, lineEnd);
                lineBuffer = lineBuffer.substring(lineEnd + 1);
                
                // Remove any carriage return
                line = line.replaceAll('\r', '');
                
                // Empty line marks end of event
                if (line.isEmpty) {
                  if (currentEvent != null && currentData != null) {
                    _handleEvent(currentEvent!, currentData!);
                  }
                  currentEvent = null;
                  currentData = null;
                  continue;
                }
                
                // Parse SSE fields
                if (line.startsWith('event:')) {
                  currentEvent = line.substring(6).trim();
                } else if (line.startsWith('data:')) {
                  currentData = line.substring(5).trim();
                } else if (line.startsWith(':')) {
                  // Comment/ping - ignore
                  print("NarrationService: Ping received");
                }
              }
            },
            onError: (e) {
              print("NarrationService: Stream error: $e");
              _scheduleReconnect();
            },
            onDone: () {
              print("NarrationService: Stream closed");
              _scheduleReconnect();
            },
            cancelOnError: false,
          );
          
    } catch (e) {
      print("NarrationService: Connection error: $e");
      _scheduleReconnect();
    }
  }
  
  void _handleEvent(String eventType, String data) {
    print("NarrationService: Event: $eventType");
    
    if (eventType == 'narration') {
      try {
        final json = jsonDecode(data);
        final text = json['text'] as String?;
        if (text != null && text.isNotEmpty) {
          print("NarrationService: Narration: $text");
          _narrationController.add(text);
        }
      } catch (e) {
        print("NarrationService: JSON parse error: $e");
      }
    } else if (eventType == 'error') {
      print("NarrationService: Server error: $data");
    }
  }
  
  void _scheduleReconnect() {
    if (!_isRunning) return;
    
    print("NarrationService: Scheduling reconnect in 5 seconds...");
    Future.delayed(Duration(seconds: 5), () {
      if (_isRunning) {
        _connectToSSE();
      }
    });
  }
  
  void dispose() {
    stop();
    _narrationController.close();
  }
}
