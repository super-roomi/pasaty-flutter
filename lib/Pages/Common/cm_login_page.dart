import 'package:flutter/material.dart';
import 'package:mockup/Pages/Parent%20Pages/pr_main_shell.dart';
import 'package:mockup/Pages/Driver%20Pages/dv_main_shell.dart';

import '../../l10n/app_localizations.dart';

class CmLoginPage extends StatefulWidget {
  final void Function(Locale) onLocaleChange;
  const CmLoginPage({super.key, required this.onLocaleChange});

  @override
  State<CmLoginPage> createState() => _CmLoginPageState();
}

class _CmLoginPageState extends State<CmLoginPage> {
  String roleSelected = "";
  static const String driverRole = 'driver';
  static const String parentRole = 'parent';
  static const String staffRole = 'staff';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final roles = {
      driverRole: l10n.driverRole,
      parentRole: l10n.parentRole,
      staffRole: l10n.staffRole,
    };

    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Image.asset('assets/images/logo.png'),
            //Container wrapping a Column Containing Text & Fields
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Color(0xFF1A2B48),
                  borderRadius: BorderRadiusGeometry.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  spacing: 10,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: Text(
                        l10n.welcomeToPasaty,
                        style: TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontFamily: 'NotoSansArabic',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.phoneNumber,
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'NotoSansArabic',
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.left,
                        ),
                        SizedBox(
                          width: 350,
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: l10n.phoneNumberHint,
                              prefixIcon: Icon(Icons.phone_android),
                              // border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.role,
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'NotoSansArabic',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(
                          width: 350,
                          child: DropdownButtonFormField<String>(
                            items: roles.entries
                                .map(
                                  (entry) => DropdownMenuItem(
                                    value: entry.key,
                                    child: Text(
                                      entry.value,
                                      style: TextStyle(
                                        fontFamily: 'NotoSansArabic',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              roleSelected = value!;
                            },
                            decoration: InputDecoration(
                              hintText: l10n.selectRole,
                              prefixIcon: Icon(Icons.person),
                              // border: OutlineInputBorder()
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(
                      width: 180,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          if (roleSelected == driverRole) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DvMainShell(
                                  onLocaleChange: widget.onLocaleChange,
                                ),
                              ),
                            );
                          } else if (roleSelected == parentRole) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PrMainShell(
                                  onLocaleChange: widget.onLocaleChange,
                                ),
                              ),
                            );
                          } else if (roleSelected == staffRole) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DvMainShell(
                                  onLocaleChange: widget.onLocaleChange,
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 8,
                          children: [
                            Text(
                              l10n.logIn,
                              style: TextStyle(
                                fontFamily: 'NotoSansArabic',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(Icons.arrow_forward),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
