import 'package:flutter/material.dart';
import 'package:mockup/Pages/Parent%20Pages/pr_settings_page.dart';
import 'package:mockup/services/auth_session.dart';
import 'package:mockup/services/protected_service.dart';

import '../../l10n/app_localizations.dart';

class PrProfilePage extends StatefulWidget {
  const PrProfilePage({super.key, required this.onLocaleChange});
  final void Function(Locale) onLocaleChange;

  @override
  State<PrProfilePage> createState() => _PrProfilePageState();
}

class _PrProfilePageState extends State<PrProfilePage> {
  String studentName = "Jasim Jaffar";
  String schoolName = "Smart Private School";
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
                          "https://imgs.search.brave.com/HiAbQIWATLXc9I17G3jIBEBa4vLRbngtomuRhM4k1qg/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly90My5m/dGNkbi5uZXQvanBn/LzE4LzQ3LzIxLzI0/LzM2MF9GXzE4NDcy/MTI0MTFfMlFwVFUx/Ynh2MFhlV1BkUTdw/bkFwSk9waEhjSWE0/bHkuanBn",
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _profile?.name ??
                              AuthSession.instance.user?.name ??
                              studentName,
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
                              child: Icon(Icons.school_outlined),
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
                          l10n.busRoute.toUpperCase(),
                          style: TextStyle(fontSize: 15),
                        ),
                        Text(
                          "#22",
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
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 20.0,
                  ),
                  child: Row(
                    // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 14.0),
                        child: Icon(Icons.settings_outlined, size: 26),
                      ),

                      Column(
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

                      Expanded(
                        child: Container(
                          alignment: Alignment.centerRight,
                          child: Icon(Icons.arrow_forward_ios_sharp),
                        ),
                      ),
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
