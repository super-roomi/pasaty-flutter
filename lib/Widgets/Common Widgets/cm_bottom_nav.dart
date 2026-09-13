import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:mockup/Colors/app_colors.dart';

class CmNavItem {
  final IconData icon;
  final String label;

  const CmNavItem({required this.icon, required this.label});
}

/// Bottom navigation shared by the driver and parent shells.
///
/// Replaces Material's [BottomNavigationBar] because the two behaviours we
/// want are awkward there: suppressing the ink ripple, and animating the
/// selected icon's colour and scale independently of the label.
class CmBottomNav extends StatelessWidget {
  const CmBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;

  /// Only fired when the index actually changes.
  final ValueChanged<int> onTap;

  final List<CmNavItem> items;

  static const _duration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    // Users who ask for reduced motion get the same states, instantly.
    final animate = !MediaQuery.of(context).disableAnimations;
    final duration = animate ? _duration : Duration.zero;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        // Just enough lift to separate the bar from scrolling content.
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      // top: false so the bar's background and shadow still paint behind the
      // Android navigation bar / iOS home indicator, while the icons are
      // inset clear of them.
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 6),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavButton(
                    item: items[i],
                    selected: i == currentIndex,
                    duration: duration,
                    onTap: () {
                      if (i == currentIndex) return;
                      HapticFeedback.selectionClick();
                      onTap(i);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.duration,
    required this.onTap,
  });

  final CmNavItem item;
  final bool selected;
  final Duration duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.deepNavy : AppColors.mutedText;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        // No ripple, no highlight: the icon's own colour and scale change is
        // the feedback. Kept as an InkWell rather than a GestureDetector so
        // the target still reports as a button to assistive tech.
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: selected ? 1.15 : 1.0,
                duration: duration,
                curve: Curves.easeOut,
                child: TweenAnimationBuilder<Color?>(
                  duration: duration,
                  tween: ColorTween(end: color),
                  builder: (context, animatedColour, _) =>
                      Icon(item.icon, size: 26, color: animatedColour),
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: duration,
                curve: Curves.easeOut,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
