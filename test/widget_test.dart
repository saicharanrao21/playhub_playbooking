import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playhub_playbooking/app/app.dart';

void main() {
  testWidgets('PlayHub app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Note: In real tests we would use Bootstrap.createContainer()
    // but for a simple smoke test ProviderScope is enough if we don't
    // hit providers that throw UnimplementedError.
    await tester.pumpWidget(const ProviderScope(child: PlayHubApp()));

    // Basic check to see if the app starts at /login
    expect(find.text('Welcome to PlayHub'), findsOneWidget);
  });
}
