import 'package:flutter/material.dart';
import 'package:mockup/Colors/app_colors.dart';

/// Shows a transient message over the current screen.
///
/// Four screens each built their own SnackBar, which is why an error was red
/// and lingered on one screen and looked like an ordinary notice on another.
/// One place to decide what "this went wrong" looks like.
///
/// The previous snack is dismissed first: tapping twice in a row otherwise
/// queues the second message behind the first, so the reply to the second tap
/// arrives seconds after it.
///
/// Callers inside a [State] must still check `mounted` first — this cannot,
/// and a context from a disposed widget has no messenger to reach.
void showToast(BuildContext context, String message, {bool error = false}) =>
    showToastVia(ScaffoldMessenger.of(context), message, error: error);

/// As [showToast], for callers that captured the messenger before an `await`.
///
/// Reaching for the context again after an async gap is the bug this avoids;
/// the messenger survives the gap, the context may not.
void showToastVia(
  ScaffoldMessengerState messenger,
  String message, {
  bool error = false,
}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        // Errors are worth a couple more seconds: they usually ask the reader
        // to do something, not just confirm what they already did.
        duration: Duration(seconds: error ? 6 : 4),
        backgroundColor: error ? AppColors.dangerRed : null,
      ),
    );
}
