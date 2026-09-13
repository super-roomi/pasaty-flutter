import 'package:flutter/material.dart';

import '../../Colors/app_colors.dart';
import '../../Widgets/Common Widgets/cm_state_view.dart';
import '../../l10n/app_localizations.dart';
import '../../services/push_service.dart';

/// What sits behind the bell.
///
/// The text is not localised here on purpose: the server composes each
/// notification in the language the device registered with, so translating it
/// again on the client would either duplicate that logic or contradict it.
/// Only the page's own chrome comes from the ARB files.
class CmNotificationsPage extends StatefulWidget {
  const CmNotificationsPage({super.key});

  @override
  State<CmNotificationsPage> createState() => _CmNotificationsPageState();
}

class _CmNotificationsPageState extends State<CmNotificationsPage> {
  @override
  void initState() {
    super.initState();
    // Opening the list is what marks it seen, so the badge clears on the way
    // in rather than needing a separate gesture.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => PushService.instance.markAllRead(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.notifications,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          ValueListenableBuilder<List<PushMessage>>(
            valueListenable: PushService.instance.inbox,
            builder: (context, messages, _) => messages.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: l10n.clearAll,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => PushService.instance.clear(),
                  ),
          ),
        ],
      ),
      body: ValueListenableBuilder<List<PushMessage>>(
        valueListenable: PushService.instance.inbox,
        builder: (context, messages, _) {
          if (messages.isEmpty) {
            return CmStateView.empty(
              message: l10n.noNotifications,
              icon: Icons.notifications_none,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: messages.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 68),
            itemBuilder: (context, i) => _NotificationTile(
              message: messages[i],
              l10n: l10n,
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final PushMessage message;
  final AppLocalizations l10n;

  const _NotificationTile({required this.message, required this.l10n});

  /// Icon by event, so the list is scannable without reading every line.
  (IconData, Color) get _badge => switch (message.newStatus) {
    'BOARDED' => (Icons.login, AppColors.successGreen),
    'ARRIVED' => (Icons.school_outlined, AppColors.deepNavy),
    'DROPPED_OFF' => (Icons.home_outlined, AppColors.successGreen),
    'ABSENT' => (Icons.person_off_outlined, AppColors.dangerRed),
    _ => switch (message.type) {
      'run_started' => (Icons.play_arrow_rounded, AppColors.deepNavy),
      'run_completed' => (Icons.flag_outlined, AppColors.mutedText),
      _ => (Icons.notifications_none, AppColors.mutedText),
    },
  };

  String _relative(BuildContext context) {
    final diff = DateTime.now().difference(message.receivedAt);
    if (diff.inMinutes < 1) return l10n.justNow;
    if (diff.inMinutes < 60) return l10n.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.hoursAgo(diff.inHours);
    return l10n.daysAgo(diff.inDays);
  }

  @override
  Widget build(BuildContext context) {
    final (icon, colour) = _badge;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colour.withValues(alpha: 0.12),
        child: Icon(icon, color: colour, size: 20),
      ),
      title: Text(
        message.title.isEmpty ? l10n.appTitle : message.title,
        style: TextStyle(
          fontWeight: message.read ? FontWeight.w500 : FontWeight.bold,
        ),
      ),
      subtitle: message.body.isEmpty ? null : Text(message.body),
      trailing: Text(
        _relative(context),
        style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
      ),
    );
  }
}
