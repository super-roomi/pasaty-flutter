import 'package:url_launcher/url_launcher.dart';

/// Public privacy policy, also filed with Apple and Google as the app's policy
/// URL. Keep this in sync with the store listings if it ever moves.
const String kPrivacyPolicyUrl = 'https://masar-alburhan.netlify.app/privacy';
const String kPrivacyPolicyUrlAr =
    'https://masar-alburhan.netlify.app/ar/privacy';

/// Opens the privacy policy in the browser, in the app's current language.
///
/// The site serves each language at its own URL rather than behind a toggle,
/// so an Arabic-speaking parent lands on Arabic text instead of English with
/// a switch to find.
///
/// Returns false if nothing could handle the link, so the caller can say so
/// rather than appearing to do nothing.
Future<bool> openPrivacyPolicy(String languageCode) {
  final url = languageCode == 'ar' ? kPrivacyPolicyUrlAr : kPrivacyPolicyUrl;
  return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}
