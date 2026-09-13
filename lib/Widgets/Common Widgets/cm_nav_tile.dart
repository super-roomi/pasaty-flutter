import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:mockup/Colors/app_colors.dart';

/// The bordered title/subtitle row used down the profile pages — Settings,
/// Privacy Policy, and so on.
///
/// Extracted because the driver and parent profiles render exactly the same
/// rows; keeping one copy is what stops the two pages drifting apart, which
/// they had already started to do.
///
/// [CmLogoutTile] stays separate: it owns the logout flow, not just a row.
class CmNavTile extends StatelessWidget {
  const CmNavTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
    this.trailing = const Icon(Icons.arrow_forward_ios, size: 16),
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// Tints the icon and title red, for actions that remove something.
  final bool destructive;

  /// The chevron by default; pass an open-in-new icon for links that leave
  /// the app, so the row does not promise an in-app screen.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final accent = destructive ? AppColors.dangerRed : null;

    // InkWell rather than GestureDetector: gives the press ripple, and reports
    // itself as a button to assistive tech.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Semantics(
            button: true,
            label: '$title. $subtitle',
            excludeSemantics: true,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: AppBorders.card,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              padding: const EdgeInsets.symmetric(
                vertical: 18,
                horizontal: 20,
              ),
              child: Row(
                spacing: 14,
                children: [
                  Icon(icon, size: 24, color: accent),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: accent,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
