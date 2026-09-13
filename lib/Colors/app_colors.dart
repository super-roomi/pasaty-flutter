import 'package:flutter/material.dart';

/// The app's colour tokens. Nothing outside this file should declare a raw
/// `Color(0xFF...)`: a status colour that means "present" must be the same
/// green everywhere, or drivers and parents learn two different palettes.
class AppColors {
  // ---- Brand ----
  static const deepNavy = Color(0xFF1A2B48);
  static const safetyYellow = Color(0xFFF4B400);

  // ---- Surfaces & neutrals ----
  static const background = Color(0xFFFBF9FB);
  static const surface = Color(0xFFFFFFFF);

  /// Filled rows and cards sitting on [background].
  static const surfaceMuted = Color(0xFFF2F0F3);

  /// Chips sitting on [surfaceMuted] — one step darker so the chip still
  /// reads as a distinct element on top of a filled row.
  static const neutralTint = Color(0xFFE9E7EC);

  /// Card and row hairline. #E9ECEF was too faint to read as a border on the
  /// off-white background — cards looked like they were floating rather than
  /// bounded. This is still soft but actually visible.
  static const borderGray = Color(0xFFD0D7DE);

  /// Secondary text. Darker than a typical muted grey on purpose: at the
  /// previous #6C757D this only reached 4.14:1 on [surfaceMuted], which is
  /// below AA and unreadable in direct sunlight from a driver's seat.
  static const mutedText = Color(0xFF5A6169);

  // ---- Semantic: solid (icons, borders, emphasis) ----
  static const successGreen = Color(0xFF28A745);
  static const warningYellow = Color(0xFFFFC107);
  static const dangerRed = Color(0xFFDC3545);

  // ---- Semantic: tints (chip and card fills) ----
  /// Boarded / present / arrived.
  static const successTint = Color(0xFFBEFFDC);

  /// Completed transport states (arrived at school, dropped off).
  static const infoTint = Color(0xFFBDE0FF);

  /// Absent.
  static const dangerTint = Color(0xFFFEF2F2);

  /// Delays and advisories.
  static const warningTint = Color(0xFFFFF9E6);
}

/// The one hairline used by every bordered card and row.
///
/// Cards on a single screen previously mixed [AppColors.borderGray],
/// `Colors.grey` and `Colors.grey.shade300`, which read as three different
/// weights side by side. Reference this instead of building a `Border.all`
/// by hand so they cannot drift apart again.
class AppBorders {
  static const side = BorderSide(color: AppColors.borderGray, width: 1);
  static const card = Border.fromBorderSide(side);
}

/// One corner-radius scale. Three steps, applied by role — mixing eight
/// different radii (as this app previously did) reads as unfinished.
class AppRadius {
  /// Buttons, inputs, list rows.
  static const control = 12.0;

  /// Cards, panels, sheets.
  static const card = 20.0;

  /// Status chips and pills.
  static const pill = 999.0;
}
