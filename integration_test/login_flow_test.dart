import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:mockup/main.dart' as app;

/// Drives the real app against the live backend. Requires the Node
/// server running on http://127.0.0.1:3000. Run with:
///   flutter test integration_test/login_flow_test.dart -d macos
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> waitForText(WidgetTester tester, String text) async {
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (find.text(text).evaluate().isNotEmpty) return;
    }
  }

  testWidgets('wrong credentials get the backend 401, shown as an error',
      (tester) async {
    app.main();
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '07700000000');
    await tester.enterText(fields.at(1), 'definitely-wrong-password');
    await tester.tap(find.text('Login'));

    await waitForText(tester, 'Invalid phone number or password');
    expect(find.text('Invalid phone number or password'), findsOneWidget);
  });

  testWidgets('too-short phone gets the backend validation message verbatim',
      (tester) async {
    app.main();
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '123');
    await tester.enterText(fields.at(1), 'whatever-password');
    await tester.tap(find.text('Login'));

    // This exact string is produced by express-validator on the server,
    // so seeing it rendered proves the response crossed the wire.
    await waitForText(tester, 'phone must be 11 - 14 character');
    expect(find.text('phone must be 11 - 14 character'), findsOneWidget);
  });
}
