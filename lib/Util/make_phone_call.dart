import 'package:url_launcher/url_launcher.dart';

Future<void> makePhoneCall() async {
  String phoneNumber = "07731660484";

  final uri = Uri(scheme: 'telprompt', path: phoneNumber);

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    throw 'Could not launch $uri';
  }
}