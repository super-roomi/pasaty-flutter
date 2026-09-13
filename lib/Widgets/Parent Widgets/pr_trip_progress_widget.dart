import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:mockup/Colors/app_colors.dart';
import 'package:mockup/Util/child_location_ui.dart';

import '../../l10n/app_localizations.dart';

/// One child's position in the run, for [PrTripProgressWidget].
class TripProgressChild {
  final String name;

  /// Null before any status is known for the child.
  final ChildLocation? location;

  /// Marked absent for this phase: the child is not travelling at all, so a
  /// progress track would be misleading.
  final bool absent;

  /// Opens this child's bus-attendance sheet. Null leaves the card inert.
  ///
  /// Reachable during a run on purpose: "woke up ill and the bus is already
  /// out" is the case the whole feature exists for, and the roster that
  /// normally carries this action is hidden while a run is under way.
  final VoidCallback? onTap;

  const TripProgressChild({
    required this.name,
    required this.location,
    this.absent = false,
    this.onTap,
  });
}

/// One arrival estimate covering every child on the card.
///
/// A single figure, not per-child and not a range. Siblings ride the same bus
/// to the same school, so the one number that matters is the next arrival —
/// the earliest upcoming stop. That stop's remaining route distance rides
/// along so the parent can see how far off the bus is, not just when.
class TripEta {
  /// When the next upcoming stop is expected.
  final DateTime arrival;

  /// Route distance from the bus to that stop, in metres.
  final int metersAway;

  /// The server flagged the estimate as shaky — the bus is crawling relative
  /// to plan, or its fixes are landing off the known route. Shown with a "~"
  /// rather than hidden.
  final bool approximate;

  /// No fresh broadcast has arrived recently, so the figure can no longer be
  /// trusted to be shrinking.
  final bool stale;

  /// What the estimate said when it was last broadcast, in minutes. Used for
  /// the stale label: counting a dead estimate down against the live clock
  /// would keep promising a bus that may have stopped moving.
  final int staleMinutes;

  const TripEta({
    required this.arrival,
    required this.metersAway,
    this.approximate = false,
    this.stale = false,
    this.staleMinutes = 0,
  });
}

/// The headline card a parent sees while a run is under way: each child on a
/// three-stop track showing where they are right now.
///
/// The track is ordered by the direction of travel, so the same
/// [ChildLocation] sits at a different step depending on the phase:
///   morning    Home -> On the bus -> School
///   afternoon  School -> On the bus -> Home
class PrTripProgressWidget extends StatelessWidget {
  const PrTripProgressWidget({
    super.key,
    required this.afternoon,
    required this.children,
    this.awaitingFirstEstimate = false,
    this.eta,
  });

  final bool afternoon;
  final List<TripProgressChild> children;

  /// The one estimate for the whole card, or null when the server has sent
  /// none — every child boarded, dropped off, or absent.
  final TripEta? eta;

  /// The run is under way but no estimate has arrived yet.
  ///
  /// Estimates exist only as broadcasts, so a parent opening the app mid-run
  /// sees nothing until the driver's next position ping. That is worth saying
  /// out loud — a blank space reads as a broken feature.
  final bool awaitingFirstEstimate;

  /// Stops in travel order for the current phase.
  List<ChildLocation> get _track => afternoon
      ? const [
          ChildLocation.inSchool,
          ChildLocation.onBus,
          ChildLocation.atHome,
        ]
      : const [
          ChildLocation.atHome,
          ChildLocation.onBus,
          ChildLocation.inSchool,
        ];

  String _stepLabel(AppLocalizations l10n, ChildLocation stop) {
    return switch (stop) {
      ChildLocation.atHome => l10n.stepHome,
      ChildLocation.onBus => l10n.stepOnBus,
      ChildLocation.inSchool => l10n.stepSchool,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final runLabel = afternoon ? l10n.afternoonRun : l10n.morningRun;

    // Redrawn on every socket.io position/status update, which can arrive
    // several times a minute mid-run — isolate its repaints from the rest
    // of the scroll view (contact card, other widgets below it).
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.deepNavy,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 14,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$runLabel - ${l10n.tripProgress}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Icon(
                      afternoon
                          ? Icons.nights_stay_outlined
                          : Icons.wb_sunny_outlined,
                      color: Colors.white,
                      size: 26,
                    ),
                  ],
                ),
              ),
              // One estimate for the whole trip, directly under the title —
              // the first thing a parent looks for, and the reason the card
              // is open at all.
              ?_etaSection(context, l10n),
              for (final child in children) _childTrack(context, l10n, child),
            ],
          ),
        ),
      ),
    );
  }

  /// "2.3 km" when far, "350 m away" when under a kilometre. Whole metres
  /// below 1 km avoids a meaningless "0.3 km".
  static String _distanceLabel(AppLocalizations l10n, int meters) {
    if (meters >= 1000) return l10n.etaKm((meters / 1000).toStringAsFixed(1));
    return l10n.etaMeters(meters);
  }

  /// The prominent arrival section: a big minute figure with the distance to
  /// the next stop, or a dimmed line while waiting / stale.
  Widget? _etaSection(BuildContext context, AppLocalizations l10n) {
    final eta = this.eta;

    if (eta == null) {
      // Estimates exist only as broadcasts, so there is a gap between opening
      // the app mid-run and the driver's next position ping. Saying so beats
      // a blank space, which reads as a broken feature.
      if (!awaitingFirstEstimate) return null;
      return _line(l10n.etaWaiting, dimmed: true);
    }

    if (eta.stale) {
      return _line(l10n.etaStale(eta.staleMinutes), dimmed: true);
    }

    final seconds = eta.arrival.difference(clock.now()).inSeconds;

    // A number at all times, never an "arriving now" line: the figure is what
    // a parent is looking for, and swapping it for prose right as the bus
    // gets close takes it away at the moment it matters most.
    //
    // Floored at 1. ceil() on an overdue estimate returns a negative, so a bus
    // two minutes past its prediction would read "-2 min"; it holds at 1 until
    // a fresh broadcast moves the arrival, or the 90s staleness cutoff takes
    // the countdown away entirely.
    return _figure(
      context,
      l10n,
      minutes: (seconds / 60).ceil().clamp(1, 999),
      eta: eta,
    );
  }

  /// The headline: a large minute number with unit, the phase subtitle, the
  /// clock time it lands, and the remaining distance. Its own tinted section
  /// within the card.
  Widget _figure(
    BuildContext context,
    AppLocalizations l10n, {
    required int minutes,
    required TripEta eta,
  }) {
    // Native, locale- and 24h-aware: reads the wall-clock arrival straight off
    // the same instant the countdown is derived from.
    final arrivesBy = l10n.etaArrivesBy(
      MaterialLocalizations.of(
        context,
      ).formatTimeOfDay(TimeOfDay.fromDateTime(eta.arrival)),
    );
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  spacing: 6,
                  children: [
                    Text(
                      // The "~" carries the server's low-confidence flag now
                      // that there is no range to widen.
                      eta.approximate ? '~$minutes' : '$minutes',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      l10n.etaMinutesUnit,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  afternoon ? l10n.etaUntilHome : l10n.etaUntilPickup,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  arrivesBy,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
          Row(
            spacing: 6,
            children: [
              const Icon(
                Icons.near_me_outlined,
                size: 18,
                color: Colors.white70,
              ),
              Text(
                _distanceLabel(l10n, eta.metersAway),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// A single dimmable line — the waiting / stale / arriving states, which have
  /// no live number to show prominently.
  Widget _line(String label, {bool dimmed = false}) {
    final colour = dimmed ? Colors.white54 : Colors.white;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: dimmed ? 0.06 : 0.12),
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        spacing: 8,
        children: [
          Icon(
            dimmed ? Icons.schedule_outlined : Icons.schedule,
            size: 18,
            color: colour,
          ),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: colour,
                fontSize: 15,
                fontWeight: dimmed ? FontWeight.w500 : FontWeight.w600,
                fontStyle: dimmed ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _childTrack(
    BuildContext context,
    AppLocalizations l10n,
    TripProgressChild child,
  ) {
    final track = _track;
    // -1 keeps every stop pending when the child's position is unknown.
    final currentIndex = child.location == null
        ? -1
        : track.indexOf(child.location!);

    final card = Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  child.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (child.onTap != null && !child.absent)
                const Padding(
                  padding: EdgeInsetsDirectional.only(end: 4),
                  child: Icon(
                    Icons.more_horiz,
                    size: 20,
                    color: Colors.white70,
                  ),
                ),
              if (child.absent)
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.dangerTint,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: Text(
                    l10n.statusAbsent.toUpperCase(),
                    semanticsLabel: l10n.statusAbsent,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          // An absent child is not on the bus at all; a progress track would
          // imply travel that is not happening.
          if (!child.absent)
            Semantics(
              label: child.location == null
                  ? child.name
                  : '${child.name}, ${childLocationLabel(context, child.location!)}',
              excludeSemantics: true,
              child: _stepper(l10n, track, currentIndex),
            ),
        ],
      ),
    );

    final onTap = child.onTap;
    if (onTap == null) return card;

    return Semantics(
      button: true,
      hint: l10n.manageAbsence,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.control),
          onTap: onTap,
          child: card,
        ),
      ),
    );
  }

  /// "Bus arrives in 8 min" / "Home in 8 min", or null when there is no
  /// estimate for this child.
  ///
  /// The wording follows the phase because the same stop means different
  /// things: in the morning the bus is coming to them, in the afternoon they
  /// are being brought home.
  Widget _stepper(
    AppLocalizations l10n,
    List<ChildLocation> track,
    int currentIndex,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < track.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Padding(
                // Aligns the connector with the middle of the 44dp nodes.
                padding: const EdgeInsets.only(top: 21),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 2,
                  color: i <= currentIndex
                      ? AppColors.successTint
                      : Colors.white.withValues(alpha: 0.22),
                ),
              ),
            ),
          _node(l10n, track[i], i, currentIndex),
        ],
      ],
    );
  }

  Widget _node(
    AppLocalizations l10n,
    ChildLocation stop,
    int index,
    int currentIndex,
  ) {
    final reached = index <= currentIndex && currentIndex >= 0;
    final isCurrent = index == currentIndex;

    return SizedBox(
      width: 86,
      child: Column(
        spacing: 6,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: reached
                  ? AppColors.successTint
                  : Colors.white.withValues(alpha: 0.10),
              border: reached
                  ? null
                  : Border.all(color: Colors.white.withValues(alpha: 0.28)),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                reached ? Icons.check : childLocationIcon(stop),
                key: ValueKey(reached),
                size: 20,
                color: reached
                    ? AppColors.deepNavy
                    : Colors.white.withValues(alpha: 0.65),
              ),
            ),
          ),
          Text(
            _stepLabel(l10n, stop),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.15,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isCurrent
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.60),
            ),
          ),
        ],
      ),
    );
  }
}
