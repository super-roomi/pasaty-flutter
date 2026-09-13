import 'package:url_launcher/url_launcher.dart';

/// Support number, international format, digits only — this is what wa.me
/// expects (no '+', spaces or dashes). Displayed as +964 774 112 2332.
const String kSupportWhatsAppNumber = '9647741122332';

/// Opens a WhatsApp chat with support.
///
/// Uses the wa.me web link rather than the `whatsapp://` scheme so it still
/// works when WhatsApp is not installed: the browser then offers to install
/// it instead of the launch simply failing.
///
/// Returns false if nothing could handle the link, so the caller can tell the
/// user rather than appearing to do nothing.
Future<bool> openSupportWhatsApp() async {
  final uri = Uri.parse('https://wa.me/$kSupportWhatsAppNumber');
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
