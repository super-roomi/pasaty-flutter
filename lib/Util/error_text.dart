import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:mockup/services/api_client.dart';
import 'package:mockup/services/auth_service.dart';

import '../l10n/app_localizations.dart';

/// Turns any thrown object into copy the user can actually read, in their own
/// language.
///
/// This exists because the backend is not localized and has no error codes: it
/// answers with free-form English prose (`"Invalid routeid"`,
/// `"No routes founded"`, `"Insuffecient Data"`). Passing `e.message` to the
/// UI — which several screens used to do — showed English to Arabic-speaking
/// parents and leaked backend wording, including its typos.
///
/// So the wording comes from the ARB files, keyed on [ApiErrorKind]. The
/// server's own text is appended only in debug builds, where it is genuinely
/// useful and no real user can see it.
///
/// The remaining gap is deliberate and cannot be closed on the client: a 409
/// means "not right now", but only the backend knows it was really "finish the
/// morning run first". Fixing that properly means having the API return stable
/// error codes; until then a 409 gets the generic phrasing.
String errorText(BuildContext context, Object error) {
  final l10n = AppLocalizations.of(context)!;

  final kind = switch (error) {
    ApiException e => e.kind,
    AuthException e => e.kind,
    // Anything else reaching here is a socket/DNS/TLS failure from the http
    // package, i.e. the request never made it to the server.
    _ => ApiErrorKind.network,
  };

  final message = switch (kind) {
    ApiErrorKind.network => l10n.connectionError,
    ApiErrorKind.badResponse => l10n.errorUnexpectedResponse,
    ApiErrorKind.unauthorized => l10n.errorSessionExpired,
    ApiErrorKind.forbidden => l10n.errorNotAllowed,
    ApiErrorKind.notFound => l10n.errorNotFound,
    ApiErrorKind.conflict => l10n.errorConflict,
    ApiErrorKind.server => l10n.errorServer,
    ApiErrorKind.unknown => l10n.errorUnknown,
  };

  // The server's own wording is worth seeing while developing — except for a
  // dropped connection, where the detail is a `ClientException: Failed host
  // lookup` wall that says nothing the message above has not already said,
  // and which testers reasonably read as the app breaking.
  if (kDebugMode && kind != ApiErrorKind.network) {
    final detail = error.toString();
    if (detail.isNotEmpty && detail != message) return '$message\n[$detail]';
  }
  return message;
}
