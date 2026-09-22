import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mockup/Colors/app_colors.dart';
import 'package:mockup/Util/error_text.dart';
import 'package:mockup/services/location_stream.dart';
import 'package:mockup/services/route_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mockup/services/map_config.dart';

import '../../l10n/app_localizations.dart';

/// Collapsible route map for an in-progress run.
///
/// Shows the generated driving line, every stop in pickup order, and the
/// driver's live position. Collapsed by default on purpose: the primary
/// action (BOARD / DROP OFF) must stay reachable without scrolling, so the
/// map is opt-in and remembers its state for the rest of the run.
///
/// Tiles come from Mapbox, configured via MAPBOX_TOKEN at build time (see
/// [MapConfig]). OpenStreetMap's public servers remain the debug-only
/// fallback; their usage policy does not cover a distributed app.
class DvRouteMap extends StatefulWidget {
  const DvRouteMap({
    super.key,
    required this.routeId,
    this.servedStudentIds = const {},
    this.afternoon = false,
  });

  final int routeId;

  /// Whether the bus is running the line backwards.
  ///
  /// Waypoints are stored once, in morning order. The afternoon drives the
  /// same line from the far end, so the stop the driver reaches first is the
  /// last one by sort number — without this the pin they are heading for
  /// reads "5" while the one behind them reads "1".
  final bool afternoon;

  /// Students whose stop is already dealt with for the current leg — picked
  /// up, dropped off, or marked absent.
  ///
  /// Their pins switch to a tick and drop out of the numbering, so the
  /// remaining stops always read 1, 2, 3… from the driver's next stop. The
  /// caller decides what "served" means, because it differs by phase.
  final Set<int> servedStudentIds;

  @override
  State<DvRouteMap> createState() => _DvRouteMapState();
}

class _DvRouteMapState extends State<DvRouteMap> {
  final MapController _map = MapController();

  bool _expanded = false;
  bool _loading = false;
  String? _error;
  DriverRouteMap? _route;

  LatLng? _me;
  String? _locationError;
  StreamSubscription<Position>? _positionSub;

  /// Set once the camera has been fitted to the route, so later position
  /// updates do not keep yanking the view back.
  bool _fitted = false;

  /// Whether the camera rides along with the bus.
  ///
  /// On by default: opening the map is almost always "where am I on the route
  /// right now", so it centres on the bus and keeps following as it drives. A
  /// manual pan drops this — the driver wants to look ahead — and the
  /// my-location button re-arms it.
  bool _follow = true;

  /// The map is only attached after its first frame; [MapController.camera]
  /// throws before that, so position updates must wait for this.
  bool _mapReady = false;

  /// Close enough to read the road while following; a whole-route fit sits
  /// around 12–14 and is too far out to drive by.
  static const double _followZoom = 16;

  /// Recentre on the bus while follow is armed.
  void _followMe() {
    final me = _me;
    if (_follow && me != null && _mapReady) _map.move(me, _followZoom);
  }

  @override
  void dispose() {
    unawaited(_stopLocation());
    super.dispose();
  }

  /// Route and GPS are only started when the driver first opens the map:
  /// a run spends most of its time with the map closed, and a GPS stream is
  /// expensive on battery.
  Future<void> _open() async {
    setState(() => _expanded = true);
    if (!MapConfig.isConfigured) return;
    if (_route == null && !_loading) await _loadRoute();
    await _startLocation();
  }

  Future<void> _loadRoute() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final route = await RouteService.getDriverRoute(widget.routeId);
      if (!mounted) return;
      setState(() {
        _route = route;
        _fitted = false;
      });
      _fitCamera();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = errorText(context, e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startLocation() async {
    if (_positionSub != null) return;
    final l10n = AppLocalizations.of(context)!;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        setState(() => _locationError = l10n.locationDisabled);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _locationError = l10n.locationDenied);
        return;
      }

      if (!mounted) return;
      setState(() => _locationError = null);

      // Seed the marker before the stream produces anything. Without this the
      // driver sees no position at all until the first stream event, which on
      // a stationary bus may never arrive.
      unawaited(_seedPosition());

      // Shared with the run reporter — see [LocationStream]. The map must not
      // open its own stream: the plugin hands the second caller the first
      // caller's location manager and throws the second one's settings away,
      // so a map-owned stream would silently reconfigure an active run.
      _positionSub = LocationStream.instance.attach(this).listen((pos) {
        if (!mounted) return;
        setState(() => _me = LatLng(pos.latitude, pos.longitude));
        _followMe();
      }, onError: (_) {});
    } catch (_) {
      if (mounted) setState(() => _locationError = l10n.locationUnavailable);
    }
  }

  /// Drops this widget's claim on the shared stream.
  ///
  /// Cancelling the subscription alone is not enough — [LocationStream] keeps
  /// the OS receiver running until every consumer has detached.
  Future<void> _stopLocation() async {
    final sub = _positionSub;
    _positionSub = null;
    await sub?.cancel();
    await LocationStream.instance.detach(this);
  }

  /// One immediate fix so the marker appears as soon as the map opens.
  ///
  /// Failure is silent on purpose: the stream is the real source, and a
  /// refused or slow first fix must not surface an error over the map.
  Future<void> _seedPosition() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted || _me != null) return;
      setState(() => _me = LatLng(pos.latitude, pos.longitude));
      _followMe();
    } catch (_) {
      // The stream will supply one when it can.
    }
  }

  void _fitCamera() {
    // Following the bus takes precedence over the route overview: on open the
    // driver wants themselves centred, and only falls back to the whole-route
    // fit while there is no fix yet.
    if (_follow && _me != null) {
      _followMe();
      return;
    }
    final points = _route?.pointsFor(afternoon: widget.afternoon);
    if (points == null || points.isEmpty || _fitted) return;
    // Deferred: the map is not laid out until after this frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _map.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.all(36),
        ),
      );
      _fitted = true;
    });
  }

  /// Re-arm follow and snap back to the bus.
  void _centreOnMe() {
    final me = _me;
    if (me == null) return;
    setState(() => _follow = true);
    _map.move(me, _followZoom);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderGray),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _header(l10n),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: _expanded
                ? SizedBox(height: 300, child: _body(l10n))
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _header(AppLocalizations l10n) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (_expanded) {
            setState(() => _expanded = false);
            // A collapsed map is not looking at anything. Releasing the claim
            // here is what makes the "GPS only while the map is open" promise
            // above true; without it one glance at the map kept the receiver
            // running for the rest of the session.
            unawaited(_stopLocation());
          } else {
            _open();
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            spacing: 10,
            children: [
              const Icon(Icons.map_outlined, size: 22),
              Expanded(
                child: Text(
                  l10n.routeMap,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(_expanded ? Icons.expand_less : Icons.expand_more),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(AppLocalizations l10n) {
    // Checked before anything else so an unconfigured release build does not
    // fetch the route or spin up a GPS stream for a map it cannot draw.
    if (!MapConfig.isConfigured) {
      return _message(icon: Icons.map_outlined, text: l10n.mapNotConfigured);
    }

    if (_error != null) {
      return _message(
        icon: Icons.error_outline,
        text: _error!,
        action: OutlinedButton(onPressed: _loadRoute, child: Text(l10n.retry)),
      );
    }

    final route = _route;
    if (route == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // The afternoon drives its own road path where the server has drawn one,
    // so which line to show depends on the phase, not just on the route.
    final line = route.lineFor(afternoon: widget.afternoon);
    final points = route.pointsFor(afternoon: widget.afternoon);

    if (route.waypoints.isEmpty && line.length < 2) {
      return _message(icon: Icons.map_outlined, text: l10n.noRouteGeometry);
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: points.isNotEmpty ? points.first : const LatLng(0, 0),
            initialZoom: 14,
            onMapReady: () {
              _mapReady = true;
              // The stream may have produced a fix before the map was ready to
              // move; centre now that it can.
              _followMe();
            },
            // Any hands-on pan or pinch means the driver is looking around, so
            // stop chasing the bus until they ask for it again.
            onPositionChanged: (_, hasGesture) {
              if (hasGesture && _follow) setState(() => _follow = false);
            },
            interactionOptions: const InteractionOptions(
              // No rotation: a driver glancing down needs north-up.
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
          ),
          children: [
            _tileLayer(),
            if (line.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: line,
                    strokeWidth: 5,
                    color: AppColors.deepNavy.withValues(alpha: 0.85),
                  ),
                ],
              ),
            MarkerLayer(markers: _waypointMarkers(route)),
            _attribution(),
            if (_me != null) MarkerLayer(markers: [_meMarker(_me!)]),
          ],
        ),
        if (_locationError != null)
          Positioned(
            left: 8,
            right: 8,
            top: 8,
            child: _banner(_locationError!),
          ),
        Positioned(
          right: 8,
          bottom: 8,
          child: Column(
            spacing: 8,
            children: [
              _mapButton(
                // Filled while following, hollow once the driver has panned
                // away — a glance tells them whether the map is still tracking.
                icon: _follow ? Icons.my_location : Icons.location_searching,
                tooltip: l10n.centreOnMe,
                active: _follow,
                onTap: _me == null ? null : _centreOnMe,
              ),
              _mapButton(
                icon: Icons.fit_screen_outlined,
                tooltip: l10n.fitRoute,
                onTap: () {
                  setState(() => _follow = false);
                  _fitted = false;
                  _fitCamera();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  TileLayer _tileLayer() {
    return TileLayer(
      urlTemplate: MapConfig.urlTemplate,
      // OSMF's tile policy requires a real identifying user agent; Mapbox
      // does not mind one either way.
      userAgentPackageName: 'iq.masaralburhan.app',
      maxZoom: MapConfig.maxZoom.toDouble(),
    );
  }

  /// Attribution is a licence obligation, not decoration: Mapbox requires
  /// its own credit, and the underlying data is OpenStreetMap's under ODbL
  /// whichever provider serves the tiles.
  Widget _attribution() {
    return RichAttributionWidget(
      alignment: AttributionAlignment.bottomLeft,
      showFlutterMapAttribution: false,
      attributions: [
        if (MapConfig.hasMapbox)
          TextSourceAttribution(
            'Mapbox',
            onTap: () => launchUrl(
              Uri.parse('https://www.mapbox.com/about/maps/'),
              mode: LaunchMode.externalApplication,
            ),
          ),
        TextSourceAttribution(
          'OpenStreetMap',
          onTap: () => launchUrl(
            Uri.parse('https://www.openstreetmap.org/copyright'),
            mode: LaunchMode.externalApplication,
          ),
        ),
      ],
    );
  }

  /// Is this stop already handled? Only student stops can be — the school is
  /// a fixed endpoint, not something the driver ticks off.
  bool _isServed(RouteWaypoint w) =>
      !w.isSchool &&
      w.studentId != null &&
      widget.servedStudentIds.contains(w.studentId);

  List<Marker> _waypointMarkers(DriverRouteMap route) {
    // Numbers count only the stops still to come, so the pin the driver is
    // heading for always reads "1". `waypoints` is pre-sorted by sort_number,
    // which is travel order in the morning and its reverse in the afternoon.
    var remaining = 0;
    final labels = <int, int>{}; // waypoint id -> displayed number
    final inTravelOrder = widget.afternoon
        ? route.waypoints.reversed
        : route.waypoints;
    for (final w in inTravelOrder) {
      if (w.isSchool || _isServed(w)) continue;
      labels[w.id] = ++remaining;
    }

    return [
      for (final w in route.waypoints)
        Marker(
          point: w.position,
          width: 34,
          height: 34,
          child: Tooltip(message: w.name ?? '', child: _pin(w, labels[w.id])),
        ),
    ];
  }

  Widget _pin(RouteWaypoint w, int? label) {
    final served = _isServed(w);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: served
            ? AppColors.successGreen
            : w.isSchool
            ? AppColors.safetyYellow
            : AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: served ? AppColors.successGreen : AppColors.deepNavy,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: served
          ? const Icon(Icons.check, size: 18, color: Colors.white)
          : w.isSchool
          ? const Icon(Icons.school, size: 17)
          : Text(
              '${label ?? w.sortNumber}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
    );
  }

  Marker _meMarker(LatLng me) {
    return Marker(
      point: me,
      width: 30,
      height: 30,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.successGreen,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _mapButton({
    required IconData icon,
    required String tooltip,
    VoidCallback? onTap,
    bool active = false,
  }) {
    return Material(
      color: active ? AppColors.deepNavy : AppColors.surface,
      shape: const CircleBorder(),
      elevation: 2,
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(
          icon,
          size: 20,
          color: active ? Colors.white : null,
        ),
        onPressed: onTap,
      ),
    );
  }

  Widget _banner(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warningTint,
        border: Border.all(color: AppColors.borderGray),
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _message({
    required IconData icon,
    required String text,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 10,
          children: [
            Icon(icon, size: 34, color: AppColors.mutedText),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mutedText),
            ),
            ?action,
          ],
        ),
      ),
    );
  }
}
