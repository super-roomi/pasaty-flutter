import 'package:flutter/material.dart';
import 'package:mockup/Pages/Common/cm_login_page.dart';
import 'package:flutter/services.dart';

import 'Colors/AppColors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CmLoginPage(),
      theme: ThemeData(
      useMaterial3: true,

      colorScheme: ColorScheme.light(
        primary: AppColors.deepNavy,
        secondary: AppColors.safetyYellow,
        surface: AppColors.surface,
        error: AppColors.dangerRed,
        onPrimary: Colors.white,          // text/icons on deepNavy
        onSecondary: AppColors.deepNavy,  // text/icons on safetyYellow
        onSurface: AppColors.deepNavy,    // default text color
      ),

      scaffoldBackgroundColor: AppColors.background,

      // Text
      textTheme: TextTheme(
        bodyMedium: TextStyle(color: AppColors.deepNavy),
        bodySmall: TextStyle(color: AppColors.mutedText),
        labelSmall: TextStyle(color: AppColors.mutedText),
      ),

      // Icons
      iconTheme: IconThemeData(
        color: AppColors.deepNavy,
      ),

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
