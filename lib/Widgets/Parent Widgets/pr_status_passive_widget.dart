import 'package:flutter/material.dart';
//import 'package:mockup/Widgets/Parent%20Widgets/pr_status_active_widget.dart';
import '../../l10n/app_localizations.dart';

class PrStatusPagePassive extends StatelessWidget {
  const PrStatusPagePassive({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        SizedBox(child: Image.asset("assets/images/logo.png")),
        Center(
          child: Column(
            children: [
              Text(
                l10n.noActiveTrips,
                style: TextStyle(
                  fontSize: 32,
                  fontFamily: 'NotoSansArabic',
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(
                width: 300,
                child: Text(
                  l10n.noActiveTripsMessage,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                    fontFamily: 'NotoSansArabic',
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // ElevatedButton(
              //   onPressed: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(builder: (context) => const PrStatusActiveWidget()),
              //     );
              //   },
              //   child: const Text('Go to Page 2'),
              // )
            ],
          ),
        ),
      ],
    );
  }
}
