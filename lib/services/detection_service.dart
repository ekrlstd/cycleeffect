import 'dart:async';
import 'dart:math';
import '../models/narration_models.dart';

class DetectionService {
  final StreamController<DeepTrafficUpdate> _updateController =
      StreamController<DeepTrafficUpdate>.broadcast();

  Stream<DeepTrafficUpdate> get updateStream => _updateController.stream;

  bool _isPlaying = false;
  Timer? _timer;

  // Burst configuration
  final int _burstCount = 5;
  final Duration _burstInterval = Duration(seconds: 2);
  final Duration _pauseDuration = Duration(seconds: 10);
  
  int _currentBurstIndex = 0;
  bool _inPause = false;

  void start() {
    if (_isPlaying) return;
    _isPlaying = true;
    _scheduleNextUpdate();
  }

  void stop() {
    _isPlaying = false;
    _timer?.cancel();
    _inPause = false;
    _currentBurstIndex = 0;
  }

  void _scheduleNextUpdate() {
    if (!_isPlaying) return;

    if (_inPause) {
       _timer = Timer(_pauseDuration, () {
         _inPause = false;
         _currentBurstIndex = 0;
         _scheduleNextUpdate();
       });
    } else {
      // We are in a burst
      if (_currentBurstIndex < _burstCount) {
        _emitMockUpdate();
        _currentBurstIndex++;
        
         // Schedule next item in burst
        _timer = Timer(_burstInterval, _scheduleNextUpdate);
      } else {
        // Burst finished, start pause
        _inPause = true;
        _scheduleNextUpdate(); // Will hit the _inPause block immediately
      }
    }
  }

  void _emitMockUpdate() {
    // Generate a fresh timestamp
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Create a copy of the mock data with updated timestamp and slight random variations if needed
    final update = _generateMockUpdate(now);
    
    _updateController.add(update);
  }

  DeepTrafficUpdate _generateMockUpdate(int timestamp) {
    // Determine if we want slightly different scenarios based on the burst index?
    // For now, use the provided example with slight coordinate jitter to simulate movement.
    
    final random = Random();
    double jitter() => (random.nextDouble() - 0.5) * 0.001; // Small movement

    return DeepTrafficUpdate(
      type: "update",
      timestamp: timestamp,
      events: [
        TrafficEvent(
          type: "detection",
          objectType: "car",
          objectId: "obj_57b011fe",
          x: 0.17496432722366162 + jitter(),
          y: 0.55 + jitter(),
          vx: -0.012692856504251384,
          vy: 0,
          heading: 270,
          lane: "W1",
          confidence: 0.8139745755828608,
          timestamp: timestamp,
        ),
        TrafficEvent(
          type: "detection",
          objectType: "bus",
          objectId: "obj_4ba3439e",
          x: 0.4028451091542982 + jitter(),
          y: 0.45 + jitter(),
          vx: 0.013428170305143278,
          vy: 0,
          heading: 90,
          lane: "E1",
          confidence: 0.9801739188783993,
          timestamp: timestamp,
        ),
        TrafficEvent(
            type: "detection",
            objectType: "car",
            objectId: "obj_999d8ffb",
            x: 0.461784774482869 + jitter(),
            y: 0.45 + jitter(),
            vx: 0.020990217021948594,
            vy: 0,
            heading: 90,
            lane: "E1",
            confidence: 0.8213889399922507,
            timestamp: timestamp),
        TrafficEvent(
            type: "detection",
            objectType: "car",
            objectId: "obj_34053019",
            x: 0.3182290888803416 + jitter(),
            y: 0.45 + jitter(),
            vx: 0.021215272592022775,
            vy: 0,
            heading: 90,
            lane: "E1",
            confidence: 0.9705485879457576,
            timestamp: timestamp)
      ],
      state: TrafficState(
        objects: [
          TrafficObject(
            id: "obj_57b011fe",
            type: "car",
            x: 0.17496432722366162 + jitter(),
            y: 0.55 + jitter(),
            vx: -0.012692856504251384,
            vy: 0,
            baseVx: -0.012692856504251384,
            baseVy: 0,
            heading: 270,
            lane: "W1",
            confidence: 0.8139745755828608,
            stopped: false,
          ),
          TrafficObject(
            id: "obj_4ba3439e",
            type: "bus",
            x: 0.4028451091542982 + jitter(),
            y: 0.45 + jitter(),
            vx: 0.013428170305143278,
            vy: 0,
            baseVx: 0.013428170305143278,
            baseVy: 0,
            heading: 90,
            lane: "E1",
            confidence: 0.9801739188783993,
            stopped: false,
          ),
          TrafficObject(
            id: "obj_999d8ffb",
            type: "car",
            x: 0.461784774482869 + jitter(),
            y: 0.45 + jitter(),
            vx: 0.020990217021948594,
            vy: 0,
            baseVx: 0.020990217021948594,
            baseVy: 0,
            heading: 90,
            lane: "E1",
            confidence: 0.8213889399922507,
            stopped: false,
          ),
          TrafficObject(
            id: "obj_34053019",
            type: "car",
            x: 0.3182290888803416 + jitter(),
            y: 0.45 + jitter(),
            vx: 0.021215272592022775,
            vy: 0,
            baseVx: 0.021215272592022775,
            baseVy: 0,
            heading: 90,
            lane: "E1",
            confidence: 0.9705485879457576,
            stopped: false,
          )
        ],
        signalState: "EW_GREEN",
        congestionLevel: 4,
      ),
    );
  }
}
