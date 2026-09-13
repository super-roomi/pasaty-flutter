import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

/// Tagged logging that compiles away in release builds.
///
/// The services that trace their own lifecycle — location streaming, position
/// reporting, push delivery — each had their own private copy of this line.
/// Keeping the `kDebugMode` guard in one place means a release build cannot
/// start leaking traces because one copy was written without it.
void debugLog(String tag, String message) {
  if (kDebugMode) debugPrint('[$tag] $message');
}
