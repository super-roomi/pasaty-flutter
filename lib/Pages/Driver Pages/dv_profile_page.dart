import 'package:flutter/material.dart';
import 'package:mockup/Widgets/Common%20Widgets/cm_profile_page.dart';
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
  DriverRoute? _route; // first assigned route — source of the school/bus values

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await ProtectedService.getProfile();
      final routes = await ProtectedService.getMyRoutes();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _route = routes.isNotEmpty ? routes.first : null;
      });
    } catch (_) {
      // Keep showing the session name if the request fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final route = _route;

    return CmProfilePage(
      name: _profile?.name ?? AuthSession.instance.user?.name ?? '',
      avatarIcon: Icons.directions_bus_filled,
      // The route carries the school's real name from the backend join; the
      // numeric id means nothing to a driver.
      metaIcon: Icons.business,
      metaText: route?.schoolName ?? l10n.notAssigned,
      detailLabel: l10n.busId,
      detailValue: route != null ? '#${route.id}' : l10n.notAssigned,
      onLocaleChange: widget.onLocaleChange,
    );
  }
}
