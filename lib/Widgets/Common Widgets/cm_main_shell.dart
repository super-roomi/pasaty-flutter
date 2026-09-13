import 'package:flutter/material.dart';
import 'package:mockup/Widgets/Common%20Widgets/cm_bottom_nav.dart';
import 'package:mockup/Widgets/Common%20Widgets/cm_notification_bell.dart';
import 'package:mockup/services/push_service.dart';

import '../../l10n/app_localizations.dart';

/// One tab in a [CmMainShell].
class CmShellTab {
  const CmShellTab({
    required this.icon,
    required this.label,
    required this.builder,
    this.title,
  });

  final IconData icon;

  /// Shown under the icon in the bottom bar.
  final String label;

  /// App-bar title while this tab is open. Null keeps the app's own name,
  /// which is what the home tab wants.
  final String? title;

  /// Built lazily, the first time the tab is opened.
  final WidgetBuilder builder;
}

/// The signed-in chrome shared by the driver and parent shells: bottom nav,
/// app bar with the notification bell, lazily-built tabs in an [IndexedStack],
/// and the fade between them.
///
/// Both roles had their own copy of this, identical apart from the tab list —
/// so a fix to the tab-switch animation or the notification routing had to be
/// made twice, and once was missed. The roles now differ only in the [tabs]
/// they pass.
class CmMainShell extends StatefulWidget {
  const CmMainShell({super.key, required this.tabs});

  final List<CmShellTab> tabs;

  @override
  State<CmMainShell> createState() => _CmMainShellState();
}

class _CmMainShellState extends State<CmMainShell>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  // Tabs opened so far. IndexedStack builds every child eagerly, which would
  // make a tab fetch its data at login; a tab stays a placeholder until it is
  // first opened, then keeps its state for the rest of the session.
  final Set<int> _visited = {0};

  /// Drives the tab-change fade.
  ///
  /// The IndexedStack itself is never re-keyed — doing that would rebuild
  /// every tab and drop the status page's socket subscriptions. Only opacity
  /// animates, so the new tab is already laid out when it fades up.
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
    value: 1,
  );

  @override
  void initState() {
    super.initState();
    PushService.instance.tapped.addListener(_onNotificationTapped);
    // A notification that cold-started the app was recorded before this shell
    // existed, so the listener alone would miss it.
    _onNotificationTapped();
  }

  @override
  void dispose() {
    PushService.instance.tapped.removeListener(_onNotificationTapped);
    _fade.dispose();
    super.dispose();
  }

  /// Every notification is about the current run, and the home tab is where
  /// that lives — so routing is "show the run", not a per-type destination
  /// table.
  void _onNotificationTapped() {
    if (PushService.instance.tapped.value == null) return;
    PushService.instance.tapped.value = null;
    if (!mounted || _currentIndex == 0) return;
    setState(() {
      _currentIndex = 0;
      _visited.add(0);
    });
    _fade.forward(from: 0.35);
  }

  void _select(int index) {
    setState(() {
      _currentIndex = index;
      _visited.add(index);
    });
    // From 0.35 rather than 0: a full fade from black reads as a page load,
    // which a tab switch is not.
    _fade.forward(from: 0.35);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tabs = widget.tabs;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tabs[_currentIndex].title ?? l10n.appTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: const [CmNotificationBell()],
      ),
      bottomNavigationBar: CmBottomNav(
        currentIndex: _currentIndex,
        onTap: _select,
        items: [
          for (final tab in tabs) CmNavItem(icon: tab.icon, label: tab.label),
        ],
      ),
      // IndexedStack, not a keyed AnimatedSwitcher: re-keying on the tab index
      // tore down the status page on every switch, so leaving and coming back
      // re-fetched the children and re-joined the socket rooms, losing
      // whatever live state had arrived in the meantime.
      body: FadeTransition(
        opacity: _fade,
        child: IndexedStack(
          index: _currentIndex,
          children: [
            for (var i = 0; i < tabs.length; i++)
              _visited.contains(i)
                  ? tabs[i].builder(context)
                  : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
