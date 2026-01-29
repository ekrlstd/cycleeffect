import '../models/narration_models.dart';

class SlmService {
  /// generateNarration takes the latest traffic update and creates a succinct summary for the driver.
  Future<String> generateNarration(DeepTrafficUpdate update) async {
    // Simulate SLM processing time
    await Future.delayed(Duration(milliseconds: 500));

    final state = update.state;
    final objectCount = state.objects.length;
    final busCount = state.objects.where((o) => o.type == 'bus').length;
    final carCount = state.objects.where((o) => o.type == 'car').length;
    
    // Logic to vary the narration slightly so it doesn't sound robotic every time
    // In a real SLM, we'd pass the JSON to the model prompt.
    
    final buffer = StringBuffer();

    if (state.congestionLevel >= 4) {
      buffer.write("Heavy traffic detected. ");
    } else if (state.congestionLevel >= 2) {
      buffer.write("Moderate traffic ahead. ");
    } else {
      buffer.write("The road is clear. ");
    }

    buffer.write("Signal is ${state.signalState.replaceAll('_', ' ')}. ");

    if (busCount > 0) {
      buffer.write("Watch out for the bus. ");
    }
    
    return buffer.toString();
  }

  /// answerQuestion allows the driver to ask specific things about the current scene.
  Future<String> answerQuestion(String question, DeepTrafficUpdate? lastUpdate) async {
    // Simulate SLM thinking time
    await Future.delayed(Duration(milliseconds: 800));

    if (lastUpdate == null) {
      return "I haven't received any traffic data yet.";
    }

    final lowerQ = question.toLowerCase();
    final state = lastUpdate.state;

    if (lowerQ.contains("how many") || lowerQ.contains("count")) {
      if (lowerQ.contains("car")) {
         final count = state.objects.where((o) => o.type == 'car').length;
         return "I see $count cars.";
      }
      return "There are ${state.objects.length} objects currently tracked.";
    }

    if (lowerQ.contains("signal") || lowerQ.contains("light")) {
      return "The light is currently ${state.signalState}.";
    }

    if (lowerQ.contains("congestion") || lowerQ.contains("traffic")) {
      return "The congestion level is ${state.congestionLevel}.";
    }

    return "I am monitoring the traffic. Congestion level is ${state.congestionLevel}.";
  }
}
