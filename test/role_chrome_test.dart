import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mockup/Pages/Driver%20Pages/dv_main_shell.dart';
import 'package:mockup/Pages/Parent%20Pages/pr_main_shell.dart';
import 'package:mockup/Pages/Driver%20Pages/dv_profile_page.dart';
import 'package:mockup/Pages/Parent%20Pages/pr_profile_page.dart';
import 'package:mockup/l10n/app_localizations.dart';
import 'package:mockup/l10n/l10n.dart';

Widget host(Widget child) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: L10n.all,
  home: child,
);

void main() {
  testWidgets('parent shell renders 2 tabs, home title, bell', (t) async {
    await t.pumpWidget(host(PrMainShell(onLocaleChange: (_) {})));
    await t.pump();
    expect(find.text('Masar Alburhan'), findsOneWidget); // home keeps app name
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('History'), findsNothing);
  });

  testWidgets('driver shell renders 3 tabs and switches title', (t) async {
    await t.pumpWidget(host(DvMainShell(onLocaleChange: (_) {})));
    await t.pump();
    expect(find.text('Masar Alburhan'), findsOneWidget);
    expect(find.text('History'), findsOneWidget); // nav label only

    await t.tap(find.text('History'));
    await t.pumpAndSettle();
    // now app bar title + nav label both read History
    expect(find.text('History'), findsNWidgets(2));
    expect(find.text('Masar Alburhan'), findsNothing);
  });

  testWidgets('both profile pages render the shared chrome', (t) async {
    for (final page in [
      PrProfilePage(onLocaleChange: (_) {}),
      DvProfilePage(onLocaleChange: (_) {}),
    ]) {
      await t.pumpWidget(host(page));
      await t.pump();
      expect(find.text('ACCOUNT'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Log Out'), findsOneWidget);
      expect(find.text('Not assigned'), findsWidgets);
    }
  });

  testWidgets('parent profile keeps the support card, driver does not', (t) async {
    await t.pumpWidget(host(PrProfilePage(onLocaleChange: (_) {})));
    await t.pump();
    expect(find.text('SUPPORT'), findsOneWidget);

    await t.pumpWidget(host(DvProfilePage(onLocaleChange: (_) {})));
    await t.pump();
    expect(find.text('SUPPORT'), findsNothing);
  });
}
