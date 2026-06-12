import 'package:flutter/material.dart';

import 'package:mockup/Pages/Parent%20Pages/pr_settings_page.dart';
import 'package:mockup/services/auth_session.dart';
import 'package:mockup/services/protected_service.dart';
import '../../l10n/app_localizations.dart';

class DvProfilePage extends StatefulWidget {
  const DvProfilePage({super.key, required this.onLocaleChange});
  final void Function(Locale) onLocaleChange;

  @override
  State<DvProfilePage> createState() => _DvProfilePageState();
}

class _DvProfilePageState extends State<DvProfilePage> {
  Profile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ProtectedService.getProfile();
      if (mounted) setState(() => _profile = profile);
    } catch (_) {
      // Keep showing the session/placeholder name if the request fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 30,
                  horizontal: 25,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(
                          "https://imgs.search.brave.com/6avPRHbDl6H1qSWxTg5InuxoBqqY2od-xpoRt_Bb1X8/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly9tZWRp/YS5nZXR0eWltYWdl/cy5jb20vaWQvMTM1/OTMzNjg2Ny9waG90/by9zbWlsaW5nLWJ1/cy1kcml2ZXIuanBn/P3M9NjEyeDYxMiZ3/PTAmaz0yMCZjPVpr/bW9VcXlKMnZlRzV2/Skl1ZjdpTDl0VWRF/OU83OE4tSmZYVm45/YVl1ckU9",
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _profile?.name ??
                              AuthSession.instance.user?.name ??
                              "Samy Abbas",
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A2B48),
                          ),
                        ),
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 2),
                              child: Icon(Icons.business),
                            ),
                            Text(
                              "Smart Private School",
                              textAlign: TextAlign.left,
                              style: TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 170,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(15),
                  ),

                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 30,
                    ),
                    child: Column(
                      children: [
                        Text(l10n.grade.toUpperCase()),
                        Text(
                          l10n.fourthGrade,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 170,
                  decoration: BoxDecoration(
                    // border: Border.all(),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 1,
                        spreadRadius: 0.5,
                        offset: Offset(0, 0),
                      ),
                    ],
                    color: Color(0xFFFFC107),
                  ),

                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 30,
                    ),
                    child: Column(
                      children: [
                        Text(
                          l10n.busId.toUpperCase(),
                          style: TextStyle(fontSize: 15),
                        ),
                        Text(
                          "SPS-7",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    PrSettingsPage(onLocaleChange: widget.onLocaleChange),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22.0,
                    vertical: 20.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 14.0),
                        child: Icon(Icons.settings_outlined, size: 26),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.settings,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              l10n.managePersonalInformation,
                              style: TextStyle(height: 0.8),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_sharp),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
