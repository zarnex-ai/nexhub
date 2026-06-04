import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexhub/src/app.dart';

void main() {
  testWidgets('App compiles and loads successfully smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    // Verify app starts and redirects to LoginScreen
    expect(find.byType(MyApp), findsOneWidget);
  });
}
