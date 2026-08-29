import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:playhub_playbooking/app/app.dart';
import 'package:playhub_playbooking/app/bootstrap/bootstrap.dart';
import 'package:playhub_playbooking/core/config/env_config.dart';

void main() {
  testWidgets('PlayHub app smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});

    // 1. Properly initialize the container for tests
    final container = await Bootstrap.createContainer(
      config: EnvConfig.local(),
    );

    // 2. Build our app and trigger a frame.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const PlayHubApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 3. Basic check to see if the app starts at /login
    // We expect 'Welcome to PlayHub' because initialLocation is /login
    expect(find.text('Welcome to PlayHub'), findsOneWidget);
  });
}
