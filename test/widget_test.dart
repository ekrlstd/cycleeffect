import 'package:flutter_test/flutter_test.dart';
import 'package:cycleeffect/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HeadsupApp());

    // Verify that the app loads
    expect(find.text('Drive safe, Driver'), findsOneWidget);
  });
}
