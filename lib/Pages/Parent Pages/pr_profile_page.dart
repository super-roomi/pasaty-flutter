import 'package:flutter/material.dart';
import 'package:mockup/Widgets/Common%20Widgets/cm_profile_page.dart';
import 'package:mockup/Widgets/Common%20Widgets/cm_section_header.dart';
import 'package:mockup/Widgets/Parent%20Widgets/pr_contact_widget.dart';
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
  Profile? _profile;
  Student? _student; // first linked child — source of the school/bus values

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await ProtectedService.getProfile();
      final students = await ProtectedService.getStudents();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _student = students.isNotEmpty ? students.first : null;
      });
    } catch (_) {
      // Keep showing the session name if the request fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final student = _student;

    return CmProfilePage(
      name: _profile?.name ?? AuthSession.instance.user?.name ?? '',
      avatarIcon: Icons.person,
      metaIcon: Icons.school_outlined,
      metaText: student?.schoolName ?? l10n.notAssigned,
      detailLabel: l10n.busRoute,
      detailValue: student?.routeId != null
          ? '#${student!.routeId}'
          : l10n.notAssigned,
      onLocaleChange: widget.onLocaleChange,
      // Support sits last, as the final thing on the page.
      trailing: [CmSectionHeader(l10n.support), const PrContactWidget()],
    );
  }
}
