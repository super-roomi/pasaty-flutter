import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:mockup/Colors/app_colors.dart';

/// The app's primary call to action.
///
/// Full-bleed and 56dp tall: on a phone the single most important action
/// should be the widest target on screen and sit inside the thumb arc, not
/// float as a 180dp pill in the middle of the panel.
///
/// The yellow fill carries a navy outline because `safetyYellow` against the
/// app background is only 1.76:1 — below the 3:1 WCAG 1.4.11 floor for the
/// boundary of an interactive control. The outline, not the fill, is what
/// makes the button's extent perceivable.
class CmPrimaryButton extends StatelessWidget {
  const CmPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.loadingLabel,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  /// Announced while [loading] so a screen-reader user hears that something
  /// is happening rather than a button that has silently stopped responding.
  final String? loadingLabel;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;

    return Semantics(
      button: true,
      enabled: enabled,
      label: loading ? (loadingLabel ?? label) : label,
      excludeSemantics: true,
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: enabled
              ? () {
                  HapticFeedback.lightImpact();
                  onPressed!();
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.safetyYellow,
            foregroundColor: AppColors.deepNavy,
            disabledBackgroundColor: AppColors.neutralTint,
            disabledForegroundColor: AppColors.mutedText,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.control),
              side: BorderSide(
                color: enabled ? AppColors.deepNavy : AppColors.borderGray,
                width: 1.5,
              ),
            ),
          ),
          // Cross-fades label -> spinner instead of swapping instantly, so a
          // fast response does not read as a flicker.
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: loading
                ? const SizedBox(
                    key: ValueKey('loading'),
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(AppColors.deepNavy),
                    ),
                  )
                : Row(
                    key: const ValueKey('label'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (icon != null) ...[
                        const SizedBox(width: 8),
                        Icon(icon, size: 20),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
