import 'package:flutter/material.dart';
import 'package:mockup/Colors/app_colors.dart';

/// Small label that groups the cards beneath it into a section.
///
/// One implementation so the status, profile and settings screens categorise
/// their content identically instead of each inventing its own heading.
class CmSectionHeader extends StatelessWidget {
  const CmSectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 18, 24, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              // Spoken in normal case; all-caps is a visual treatment only.
              semanticsLabel: title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.mutedText,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Heading for a group *inside* a screen — "Up next", "Present (3)".
///
/// Louder than [CmSectionHeader], which labels a whole section of the page.
/// The driver's status and trip-detail pages each had their own private copy
/// of this, identical but for a few pixels of padding, so a heading meant the
/// same thing on one screen and looked different on the other.
class CmSubsectionHeader extends StatelessWidget {
  const CmSubsectionHeader(this.title, {super.key, this.color});

  final String title;

  /// Tints the heading where the group itself carries meaning, e.g. the
  /// absent list. Defaults to the normal text colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: 25,
        end: 25,
        top: 14,
        bottom: 6,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
