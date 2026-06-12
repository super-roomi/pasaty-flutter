import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:mockup/Pages/Driver%20Pages/dv_main_shell.dart';
import 'package:mockup/Pages/Parent%20Pages/pr_main_shell.dart';
import 'package:mockup/main.dart' as app;

/// Drives the real app against the live backend. Requires the Node
/// server running on http://127.0.0.1:3000 and the seeded test users
/// (Test Parent 07712345678 / Test Driver 07787654321, password123).
/// Run with:
///   flutter test integration_test/login_flow_test.dart -d macos
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> waitFor(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (finder.evaluate().isNotEmpty) return;
    }
  }

  Future<void> login(WidgetTester tester, String phone, String pass) async {
    app.main();
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), phone);
    await tester.enterText(fields.at(1), pass);
    await tester.tap(find.text('Login'));
  }

  testWidgets('wrong credentials get the backend 401, shown as an error',
      (tester) async {
    await login(tester, '07700000000', 'definitely-wrong-password');

    await waitFor(tester, find.text('Invalid phone number or password'));
    expect(find.text('Invalid phone number or password'), findsOneWidget);
  });

  testWidgets('too-short phone gets the backend validation message verbatim',
      (tester) async {
    await login(tester, '123', 'whatever-password');

    // This exact string is produced by express-validator on the server,
    // so seeing it rendered proves the response crossed the wire.
    await waitFor(tester, find.text('phone must be 11 - 14 character'));
    expect(find.text('phone must be 11 - 14 character'), findsOneWidget);
  });

  testWidgets('parent account lands on the parent shell', (tester) async {
    await login(tester, '07712345678', 'password123');

    await waitFor(tester, find.byType(PrMainShell));
    expect(find.byType(PrMainShell), findsOneWidget);
  });

  testWidgets('driver account lands on the driver shell', (tester) async {
    await login(tester, '07787654321', 'password123');

    await waitFor(tester, find.byType(DvMainShell));
    expect(find.byType(DvMainShell), findsOneWidget);
  });
}
