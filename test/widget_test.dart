import 'package:flutter_test/flutter_test.dart';
import 'package:cycleeffect/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TrafficVisionApp());

    // Verify that the app title is present
    expect(find.text('TrafficVision AI'), findsOneWidget);
  });
}
