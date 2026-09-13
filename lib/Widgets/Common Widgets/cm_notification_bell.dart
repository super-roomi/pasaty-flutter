import 'package:flutter/material.dart';

import '../../Colors/app_colors.dart';
import '../../Pages/Common/cm_notifications_page.dart';
import '../../l10n/app_localizations.dart';
import '../../services/push_service.dart';

/// The app-bar bell, with an unread badge.
///
/// It was removed from both shells while the app sent no notifications — an
/// icon that does nothing reads as a broken feature rather than a missing
/// one. It returns now that there is an inbox behind it.
class CmNotificationBell extends StatelessWidget {
  const CmNotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ValueListenableBuilder<List<PushMessage>>(
      valueListenable: PushService.instance.inbox,
      builder: (context, messages, _) {
        final unread = messages.where((m) => !m.read).length;

        return IconButton(
          tooltip: l10n.notifications,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CmNotificationsPage()),
          ),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_none),
              if (unread > 0)
                Positioned(
                  right: -3,
                  top: -3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.dangerRed,
                      borderRadius: BorderRadius.circular(8),
                      // Against the navy app bar the badge otherwise merges
                      // with the bell's own outline at small sizes.
                      border: Border.all(color: AppColors.deepNavy, width: 1.5),
                    ),
                    child: Text(
                      unread > 9 ? '9+' : '$unread',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
