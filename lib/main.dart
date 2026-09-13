import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mockup/Pages/Common/cm_login_page.dart';
import 'package:mockup/Widgets/Common%20Widgets/cm_push_banner.dart';
import 'package:mockup/services/push_service.dart';
import 'package:mockup/Pages/Driver%20Pages/dv_main_shell.dart';
import 'package:mockup/Pages/Parent%20Pages/pr_main_shell.dart';
import 'package:mockup/services/auth_session.dart';
import 'package:mockup/services/locale_prefs.dart';
import 'package:flutter/services.dart';
import 'l10n/app_localizations.dart';
import 'l10n/l10n.dart';

import 'Colors/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final savedLocale = await LocalePrefs.load();
  // Rehydrate any saved session before the first frame, so a user whose app
  // was killed in the background comes back to their own screen rather than
  // the login page.
  final restored = await AuthSession.instance.restore();

  // Before runApp because the background-message handler has to be registered
  // during startup — after the first frame it is too late for a launch caused
  // by tapping a notification. Never throws: a device with no Firebase config
  // simply runs without push.
  await PushService.instance.init(
    language: savedLocale?.languageCode == 'ar' ? 'ar' : 'en',
  );
  // A restored session never passes through the login page, so this is the
  // only place its device token gets registered.
  if (restored) unawaited(PushService.instance.onSignedIn());

  runApp(MyApp(initialLocale: savedLocale, restoredSession: restored));
}

class MyApp extends StatefulWidget {
  final Locale? initialLocale;
  final bool restoredSession;
  const MyApp({super.key, this.initialLocale, this.restoredSession = false});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // This widget is the root of your application.
  late Locale _locale =
      widget.initialLocale ?? const Locale('en'); // saved or default

  /// Lets a failed token refresh — which happens deep inside the service
  /// layer, with no BuildContext — return the user to login.
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    AuthSession.instance.onSessionExpired = _returnToLogin;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    if (AuthSession.instance.onSessionExpired == _returnToLogin) {
      AuthSession.instance.onSessionExpired = null;
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Notifications that arrived while the app was away were written by a
    // separate isolate that cannot touch this one's inbox. Fold them in on
    // the way back, before anything here writes and clobbers them.
    if (state == AppLifecycleState.resumed) {
      unawaited(PushService.instance.refreshFromBackground());
    }
  }

  void _returnToLogin() {
    // A session that expires never passes through AuthService.logout(), so
    // this is the only place the inbox gets cleared on that path. Without it
    // the next person to sign in on a shared phone opens the bell onto the
    // previous family's notifications.
    unawaited(PushService.instance.onSignedOut());
    _navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => CmLoginPage(onLocaleChange: _changeLocale),
      ),
      (route) => false,
    );
  }

  void _changeLocale(Locale newLocale) {
    setState(() => _locale = newLocale);
    LocalePrefs.save(newLocale); // persist across restarts
    // The server composes notification text, so it has to be told which
    // language to compose in; the locale itself lives only on the device.
    unawaited(
      PushService.instance.onLanguageChanged(
        newLocale.languageCode == 'ar' ? 'ar' : 'en',
      ),
    );
  }

  /// Where a launch lands: the role's shell when a stored session was
  /// restored, otherwise login. An expired refresh token still ends up at
  /// login — [ApiClient] clears the session on a failed refresh and the
  /// shell's first request bounces the user out.
  Widget get _home {
    if (!widget.restoredSession) {
      return CmLoginPage(onLocaleChange: _changeLocale);
    }
    return switch (AuthSession.instance.user?.role) {
      UserRole.driver => DvMainShell(onLocaleChange: _changeLocale),
      UserRole.parent => PrMainShell(onLocaleChange: _changeLocale),
      _ => CmLoginPage(onLocaleChange: _changeLocale),
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      locale: _locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: L10n.all,

      // Several screens (status chips, stat tiles, the driver's action card)
      // use fixed heights, so an OS font scale above ~1.3 overflows them.
      // Clamp rather than ignore: large-print users still get bigger text.
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: 1.0,
        maxScaleFactor: 1.3,
        // Inside the builder so the banner sits above every route: a
        // notification can arrive on any screen, including a pushed one.
        child: CmPushBannerHost(
          // Routed through the same notifier as a tray tap, so both paths
          // land in one handler in the shell.
          onTap: (message) => PushService.instance.tapped.value = message,
          child: child!,
        ),
      ),
      home: _home,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'NotoSansArabic',
        colorScheme: ColorScheme.light(
          primary: AppColors.deepNavy,
          secondary: AppColors.safetyYellow,
          surface: AppColors.surface,
          error: AppColors.dangerRed,
          onPrimary: Colors.white, // text/icons on deepNavy
          onSecondary: AppColors.deepNavy, // text/icons on safetyYellow
          onSurface: AppColors.deepNavy, // default text color
        ),

        scaffoldBackgroundColor: AppColors.background,

        // Text
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: AppColors.deepNavy),
          bodySmall: TextStyle(color: AppColors.mutedText),
          labelSmall: TextStyle(color: AppColors.mutedText),
        ),

        // Icons
        iconTheme: IconThemeData(color: AppColors.deepNavy),

        // Buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.safetyYellow,
            foregroundColor: AppColors.deepNavy,
          ),
        ),

        // Input fields
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          labelStyle: TextStyle(color: AppColors.mutedText),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.borderGray),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.borderGray),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.deepNavy, width: 2),
          ),
        ),

        // Dividers
        dividerColor: AppColors.borderGray,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}