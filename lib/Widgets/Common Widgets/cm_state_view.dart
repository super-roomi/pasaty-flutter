import 'package:flutter/material.dart';
import 'package:mockup/Colors/app_colors.dart';

enum CmStateKind { loading, empty, error }

/// One shared shape for "nothing to show yet" — loading, an empty roster, or
/// a failed fetch — so every page presents these the same way instead of
/// each screen inventing its own spinner/icon/copy (previously five+ pages
/// each had a slightly different one).
class CmStateView extends StatelessWidget {
  const CmStateView({
    super.key,
    required this.kind,
    required this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  const CmStateView.loading({super.key, required this.message})
    : kind = CmStateKind.loading,
      icon = null,
      actionLabel = null,
      onAction = null;

  const CmStateView.empty({
    super.key,
    required this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
  }) : kind = CmStateKind.empty;

  const CmStateView.error({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
  }) : kind = CmStateKind.error,
       icon = null;

  final CmStateKind kind;
  final String message;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final isError = kind == CmStateKind.error;
    final isLoading = kind == CmStateKind.loading;
    final tint = isError ? AppColors.dangerTint : AppColors.surfaceMuted;
    final iconColor = isError ? AppColors.dangerRed : AppColors.mutedText;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            if (isLoading)
              const SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(strokeWidth: 3),
              )
            else
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(shape: BoxShape.circle, color: tint),
                child: Icon(
                  icon ??
                      (isError ? Icons.wifi_off_rounded : Icons.inbox_outlined),
                  size: 32,
                  color: iconColor,
                ),
              ),
            // liveRegion: state text changes (loading -> error, or a retry
            // that succeeds) are announced without the user hunting for them.
            Semantics(
              liveRegion: true,
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: isLoading ? AppColors.mutedText : AppColors.deepNavy,
                  fontWeight: isLoading ? FontWeight.normal : FontWeight.w600,
                ),
              ),
            ),
            if (actionLabel != null && onAction != null)
              OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: Text(actionLabel!),
              ),
          ],
        ),
      ),
    );
  }
}

/// Wraps any subtree of grey placeholder boxes in one shared shimmer sweep.
///
/// Keeping the animation here rather than in each box means a screen's whole
/// skeleton pulses as a single surface, and there is only ever one ticker no
/// matter how many shapes are drawn.
class CmShimmer extends StatefulWidget {
  const CmShimmer({super.key, required this.child});

  final Widget child;

  @override
  State<CmShimmer> createState() => _CmShimmerState();
}

class _CmShimmerState extends State<CmShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Decorative only — a screen reader should stay silent rather than
    // announcing a placeholder for every shape.
    return Semantics(
      excludeSemantics: true,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value;
            return ShaderMask(
              blendMode: BlendMode.srcATop,
              // srcATop repaints every opaque pixel in the subtree, so these
              // colours — not the shapes' own fills — are what actually shows.
              // The base has to carry against AppColors.background (#FBF9FB);
              // surfaceMuted (#F2F0F3) sat nine values off it and the whole
              // skeleton washed out to near-invisible between sweeps.
              shaderCallback: (rect) => LinearGradient(
                begin: Alignment(-1 + 3 * t, 0),
                end: Alignment(3 * t, 0),
                colors: const [
                  AppColors.neutralTint,
                  AppColors.borderGray,
                  AppColors.neutralTint,
                ],
                stops: const [0.35, 0.5, 0.65],
              ).createShader(rect),
              child: child,
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}

/// A single grey placeholder shape.
class CmSkeletonBox extends StatelessWidget {
  const CmSkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 6,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Skeletons shaped like the screen they stand in for.
///
/// These trace the whole screen, not just its busiest card: same section
/// headers, same card margins and padding, same row structure. Anything less
/// and the content visibly jumps into place when it lands.
///
/// Two rules keep them honest:
///
///  * Every metric here is copied from the real widget, not eyeballed. The
///    comments name the widget each block stands for so the two can be kept
///    in step.
///  * Nothing inside [CmShimmer] gets an opaque background. The shimmer is a
///    `srcATop` [ShaderMask], so it repaints *every* opaque pixel with the
///    same gradient — a filled card swallows the bars inside it and the whole
///    thing reads as one grey slab. Cards are drawn as outlines; only the
///    placeholder bars are filled.
class CmSkeleton {
  const CmSkeleton._();

  /// Matches [CmSectionHeader]: same padding, a bar the width of its label.
  static Widget _sectionHeader(double width) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 18, 24, 8),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: CmSkeletonBox(width: width, height: 12, radius: 4),
      ),
    );
  }

  /// A card's outline at its real geometry. See the class note on why this is
  /// never filled.
  static Widget _card({
    required EdgeInsets margin,
    required EdgeInsets padding,
    required Widget child,
    double radius = AppRadius.card,
  }) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderGray),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
  }

  /// Driver status page, passive state: greeting, MY ROUTE + the route card,
  /// TODAY + the summary card, and the collapsed route-map row.
  ///
  /// Mirrors `DvStatusPage._buildPassive`.
  static Widget driverStatusPage() {
    return CmShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // Greeting — _greeting(), 22pt bold.
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: CmSkeletonBox(width: 210, height: 24),
            ),
          ),
          _sectionHeader(72), // MY ROUTE
          // _routeCard(): bus icon + name, run-window banner, phase
          // selector, start button.
          _card(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                Row(
                  children: [
                    CmSkeletonBox(width: 20, height: 20, radius: 4),
                    SizedBox(width: 8),
                    CmSkeletonBox(width: 160, height: 22),
                  ],
                ),
                // _buildRunWindowBanner(): 12pt padding around two lines.
                CmSkeletonBox(height: 66, radius: AppRadius.control),
                // SegmentedButton, morning / afternoon.
                CmSkeletonBox(height: 44, radius: AppRadius.pill),
                // Start session — minimumSize height 50.
                CmSkeletonBox(height: 50, radius: AppRadius.control),
              ],
            ),
          ),
          _sectionHeader(58), // TODAY
          // DvTodayCard: one line per leg.
          _card(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(14),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                CmSkeletonBox(width: 210, height: 20),
                CmSkeletonBox(width: 180, height: 20),
              ],
            ),
          ),
          // DvRouteMap collapsed: icon, label, chevron. No section header
          // above it, matching the real screen.
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: _card(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              child: const Row(
                children: [
                  CmSkeletonBox(width: 22, height: 22, radius: 4),
                  SizedBox(width: 10),
                  CmSkeletonBox(width: 110, height: 18),
                  Spacer(),
                  CmSkeletonBox(width: 22, height: 22, radius: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// History: a stack of trip cards (date line plus two phase lines).
  static Widget tripList({int itemCount = 3}) {
    return CmShimmer(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _card(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(14),
          radius: AppRadius.control,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              CmSkeletonBox(width: 150, height: 17),
              CmSkeletonBox(width: 210, height: 13),
              CmSkeletonBox(width: 190, height: 13),
            ],
          ),
        ),
      ),
    );
  }

  /// History page as a whole: the toolbar (title + date button) above the
  /// trip cards, for the initial load before the route list arrives.
  static Widget historyPage() {
    return CmShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                CmSkeletonBox(width: 130, height: 22),
                CmSkeletonBox(height: 42, radius: AppRadius.control),
              ],
            ),
          ),
          Expanded(child: tripList()),
        ],
      ),
    );
  }

  /// Parent status page: STATUS + the between-runs card, then the roster
  /// section with one row per child.
  ///
  /// Mirrors `PrBoardingWidget.build` in its passive state. The loading state
  /// cannot know yet whether a run is under way, and the quiet state is both
  /// the more common one and the shorter card — better to grow into the trip
  /// tracker than to collapse down from it.
  static Widget parentStatusPage({int itemCount = 2}) {
    return CmShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _sectionHeader(52), // STATUS
          // PrStatusPagePassive: 64px circle over a title and two text lines.
          _card(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
            child: const Column(
              spacing: 12,
              children: [
                CmSkeletonBox(width: 64, height: 64, radius: 32),
                CmSkeletonBox(width: 150, height: 24),
                CmSkeletonBox(height: 14),
                CmSkeletonBox(width: 220, height: 14),
              ],
            ),
          ),
          _sectionHeader(104), // STUDENT STATUS
          _card(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(12),
            child: Column(
              spacing: 10,
              children: [
                for (var i = 0; i < itemCount; i++) _studentRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// One roster row: avatar, name, and the location chip on the end.
  static Widget _studentRow() {
    return _card(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(12),
      radius: AppRadius.control,
      child: const Row(
        children: [
          CmSkeletonBox(width: 26, height: 26, radius: 13),
          SizedBox(width: 14),
          CmSkeletonBox(width: 96, height: 18),
          Spacer(),
          CmSkeletonBox(width: 92, height: 27, radius: AppRadius.pill),
        ],
      ),
    );
  }
}
