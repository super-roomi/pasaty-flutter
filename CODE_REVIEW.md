# Pasaty / Masar Alburhan — Flutter code review

**Reviewed:** full repo at `main` (working tree, uncommitted changes included)
**Date:** 2026-08-09

---

## 0. Environment & reproduction

| Item | Value |
|---|---|
| Flutter | 3.44.8 stable (engine 13ffd72b2f9a) |
| Dart | 3.12.2 (`environment: sdk: ^3.11.5`) |
| Platforms in tree | Android, iOS, linux/macos/windows/web scaffolding (only Android + iOS configured) |
| Analyzer | `flutter analyze --fatal-infos` → **0 issues** |
| Tests | `flutter test` → **11 passed, 1 skipped** (the skip is `ApiConfig._production` being empty) |
| Deps | all current except `intl 0.20.2→0.20.3`; no known-vulnerable packages |

Build / run commands used:

```bash
flutter pub get && flutter analyze --fatal-infos && flutter test
```

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.31:3000
```

**General note.** This is a well-cared-for codebase. Native config (network security config, privacy manifest, export compliance, signing assertion), accessibility (`Semantics`, `MergeSemantics`, `semanticsLabel`, clamped text scaling, 48dp targets), and the design-token discipline in `AppColors`/`AppRadius` are all above average. The problems below are concentrated in **the service layer's concurrency and error handling**, and in **state that is keyed off the wrong variable**. There is no state-management framework at all — everything is `StatefulWidget` + `setState` + static service classes — which is workable at this size but is the root cause of several findings.

---

## 1. Prioritized findings

| # | Sev | Area | Issue | File | Effort |
|---|---|---|---|---|---|
| 1 | **Critical** | async | Concurrent 401s each fire their own token refresh → rotated refresh token invalidates the others → user logged out on cold start | `api_client.dart:47` | 2–3h |
| 2 | **Critical** | error handling | `jsonDecode` on unvalidated response bodies; any non-JSON error page crashes the call | `api_client.dart:58`, `auth_service.dart:40,82` | 1–2h |
| 3 | **Critical** | release | `ApiConfig._production` empty — every release build throws `StateError` at first request | `api_config.dart:32` | 5m + infra |
| 4 | **Major** | correctness | Run completes / maps render against `_selectedRoute` instead of the route the run started on | `dv_status_page.dart:225,586,655,867` | 1h |
| 5 | **Major** | async | No timeout on any HTTP call — a stalled connection hangs the UI indefinitely | `api_client.dart`, `auth_service.dart` | 1h |
| 6 | **Major** | lifecycle | `setState` after `await` with no `mounted` guard in `DvRouteMap._startLocation` | `dv_route_map.dart:104,113` | 15m |
| 7 | **Major** | correctness | Parent sees "All home" while children are shown "In school" between runs | `pr_boarding_widget.dart:63` | 1–2h |
| 8 | **Major** | type safety | Unchecked `as int` / `as String` casts across every `fromJson`; one schema drift = crash | `attendance_service.dart`, `protected_service.dart`, `route_service.dart` | 3–4h |
| 9 | **Major** | UX / dead code | Driver "Broadcast updates" card ships three buttons wired to `() => {}` | `dv_broadcast_status.dart:41,56,74` | 30m or 4h |
| 10 | Minor | memory/battery | GPS stream keeps running after the map is collapsed | `dv_route_map.dart:99` | 30m |
| 11 | Minor | socket | `joinRoute`/`leaveRoute` are not reference-counted | `socket_service.dart:187` | 1h |
| 12 | Minor | socket | `connected` / `lastError` notifiers exist but nothing renders them | `socket_service.dart:69,72` | 1h |
| 13 | Minor | l10n | App locale hardcoded to `en` on first launch; device locale never consulted | `main.dart:36`, `l10n.dart:4` | 30m |
| 14 | Minor | l10n / RTL | `TextAlign.left`, `EdgeInsets.only(right:)`, and a Saudi flag for an Iraqi app | `cm_login_page.dart:164,228`, `pr_settings_page.dart:31` | 30m |
| 15 | Minor | tests | Integration test asserts a string that no longer exists → guaranteed failure | `integration_test/login_flow_test.dart:79` | 5m |
| 16 | Minor | tests | Zero service-layer tests; the riskiest code has no coverage | `test/` | 1–2d |
| 17 | Minor | perf | `loadSessions` issues 14 HTTP requests per "load earlier" | `attendance_service.dart:300` | backend |
| 18 | Minor | hygiene | 4 dead widgets/pages still compiled; package still named `mockup`; `intl: any` | various | 1h |
| 19 | Minor | CI | No format check, no coverage gate, no Flutter version pin, no iOS build | `.github/workflows/ci.yaml` | 1h |

---

## 2. Critical

### 1. Refresh-token stampede logs the user out on cold start

**`lib/services/api_client.dart:47-56`**

```dart
if (response.statusCode == 401 || response.statusCode == 403) {
  try {
    await AuthService.refresh();
    response = await _raw(method, path, body);
  } on AuthException { /* ... */ }
}
```

Every in-flight request refreshes independently. Two callers fan out in parallel by design:

- `PrBoardingWidget._refreshStatuses` (`pr_boarding_widget.dart:118`) — `Future.wait` over *every* child.
- `AttendanceService.loadSessions` (`attendance_service.dart:316`) — batches of 5.

And `AuthSession.restore()` deliberately restores an **expired** access token (`auth_session.dart:99`), so the very first burst after launch is guaranteed to be N simultaneous 401s.

`AuthService.refresh` handles a rotated cookie (`auth_service.dart:97-100`), which means the server *does* rotate. The first refresh wins and invalidates the old cookie; refreshes 2..N replay the dead cookie, get 401, and hit this:

```dart
// auth_service.dart:87-91
if (response.statusCode == 401 || response.statusCode == 403) {
  await session.clear();
  SocketService.instance.disconnect();
  session.onSessionExpired?.call();   // ← bounces to login
}
```

**Repro:** parent account with ≥2 children, log in, force-quit, relaunch. The roster fires N parallel `GET /v1/protected/attendance/:id`, all 401, all refresh, and the app returns to the login screen despite a perfectly valid session.

**Fix — single-flight the refresh:**

```dart
// auth_service.dart
static Future<void>? _inFlight;

static Future<void> refresh() {
  return _inFlight ??= _refresh().whenComplete(() => _inFlight = null);
}

static Future<void> _refresh() async { /* existing body */ }
```

Callers that arrive while a refresh is running await the same future and then retry with the new token. `SocketService._recoverAuth` (`socket_service.dart:79`) already has an ad-hoc `_recovering` flag for exactly this reason — that flag becomes redundant once the lock lives in `AuthService`.

**Effort:** 2–3h with tests. **Trade-off:** none; strictly safer.

---

### 2. `jsonDecode` on unvalidated bodies

**`lib/services/api_client.dart:58`**, **`lib/services/auth_service.dart:40,82`**

```dart
final decoded = jsonDecode(response.body);            // api_client.dart:58
final body = jsonDecode(response.body) as Map<String, dynamic>;  // auth_service.dart:40
```

A 502 from a reverse proxy, a 204, a captive-portal interception, or a request that never reached the app server returns HTML or an empty string. `jsonDecode('')` throws `FormatException`; `jsonDecode('<html>…')` likewise. Neither is an `ApiException` or an `AuthException`, so:

- In `_send`, it escapes before the status check — the caller never learns the HTTP status.
- In `refresh`, it escapes past the `on AuthException` in `api_client.dart:53`, so the "refresh failed, fall through" path is skipped entirely.

**Fix:**

```dart
// api_client.dart
static Map<String, dynamic> _decode(http.Response r) {
  if (r.body.isEmpty) return const {};
  try {
    final d = jsonDecode(r.body);
    return d is Map<String, dynamic> ? d : <String, dynamic>{'data': d};
  } on FormatException {
    throw ApiException(
      'Unexpected response from server', statusCode: r.statusCode);
  }
}
```

Apply the same in `AuthService.login` / `refresh`, throwing `AuthException` there. **Effort:** 1–2h.

---

### 3. Release builds cannot reach any backend

**`lib/services/api_config.dart:32`** — `static const String _production = '';`

`baseUrl` throws `StateError` in release (`api_config.dart:43-49`). This is a deliberate fail-fast and `test/compliance_test.dart` skips rather than fails, which is the right call — but it must not be forgotten. The CI job runs `flutter build appbundle --release`, which **succeeds**: the throw is at runtime, so a shippable-looking AAB is produced that dies at login.

**Fix:** set `_production` to the real HTTPS host, or build with `--dart-define=API_BASE_URL=https://…`. Then make the compliance test fail (not skip) once a release channel exists — the current skip is correct only pre-launch.

**Effort:** 5 minutes once the host exists. **Trade-off:** none.

---

## 3. Major

### 4. Run state keyed off `_selectedRoute`, not the run's own route

**`lib/Pages/Driver Pages/dv_status_page.dart:225, 586, 655, 867`**

`RouteStart` carries `routeId` (`attendance_service.dart:123`), but it is never read. `_completeRun` and all three `DvRouteMap` instances use `_selectedRoute` instead, and the dropdown at `:421-430` stays enabled while a run is active.

**Repro** (driver with ≥2 assigned routes):
1. Start the morning run on Route A.
2. Tap Back (`_viewingPassive = true`, `_run` is deliberately kept — `:70-75`).
3. Change the dropdown to Route B.
4. Tap Resume → Route A's roster renders, but the map shows Route B.
5. Tap Complete Run → `completeMorning(routeB.id)`.

Step 5 either 409s (confusing error on a run the driver *did* finish) or, if Route B also has an open run, completes the wrong route.

**Fix:**

```dart
// dv_status_page.dart — _completeRun
-    final route = _selectedRoute;
-    if (route == null || _working) return;
+    final run = _run;
+    if (run == null || _working) return;
...
-      final summary = _isAfternoon
-          ? await AttendanceService.completeAfternoon(route.id)
-          : await AttendanceService.completeMorning(route.id);
+      final summary = _isAfternoon
+          ? await AttendanceService.completeAfternoon(run.routeId)
+          : await AttendanceService.completeMorning(run.routeId);
```

For the three map sites, replace `_selectedRoute!.id` with `_run!.routeId` (all three are only reachable when `_run != null`), and disable the dropdown while a run is live:

```dart
onChanged: _run != null ? null : (r) => setState(() => _selectedRoute = r),
```

**Effort:** 1h. **Trade-off:** none — this only removes a way to desynchronise.

---

### 5. No timeout on any HTTP call

`http.get/post/patch` are called bare in `api_client.dart:81-86` and `auth_service.dart:34,77,112`. Dart's default connection timeout is OS-level (minutes). On a bus with intermittent coverage, tapping **Board** spins forever: `_busyIds` never clears, and the driver cannot retry.

**Fix — centralise in `_raw`:**

```dart
static const _timeout = Duration(seconds: 15);

return switch (method) {
  'GET'   => http.get(uri, headers: headers),
  'POST'  => http.post(uri, headers: headers, body: encoded),
  'PATCH' => http.patch(uri, headers: headers, body: encoded),
  _ => throw ArgumentError('Unsupported method $method'),
}.timeout(_timeout, onTimeout: () => throw ApiException('Request timed out'));
```

Or, better, hold one `http.Client` for the app rather than the implicit per-call client the top-level functions create — that also gets you connection reuse for the parallel fan-outs in §1.

**Effort:** 1h. **Trade-off:** a 15s cap may cut off a genuinely slow-but-working 2G request; 20–30s is a defensible alternative for this user base.

---

### 6. `setState` after `await` without a `mounted` guard

**`lib/Widgets/Driver Widgets/dv_route_map.dart:99-115`**

```dart
if (!await Geolocator.isLocationServiceEnabled()) {
  setState(() => _locationError = l10n.locationDisabled);   // :104 — no guard
  return;
}
var permission = await Geolocator.checkPermission();
if (permission == LocationPermission.denied) {
  permission = await Geolocator.requestPermission();        // can take minutes
}
if (permission == …denied || …deniedForever) {
  setState(() => _locationError = l10n.locationDenied);     // :113 — no guard
  return;
}
if (!mounted) return;                                        // :117 — too late
```

The permission dialog is modal and user-paced. If the driver completes the run (or the socket-expiry handler in `main.dart:56` navigates away) while it is open, `setState` fires on a disposed `State` → `FlutterError: setState() called after dispose()`.

**Fix:** move `if (!mounted) return;` to immediately after each `await`, before each `setState`. **Effort:** 15 minutes.

---

### 7. Parent home contradicts itself between runs

**`lib/Widgets/Parent Widgets/pr_boarding_widget.dart:63-65`**

```dart
bool get _runInProgress => _statusByStudent.values.any(
  (s) => s == AttendanceStatus.waiting || s == AttendanceStatus.boarded);
```

After the morning run completes, every status is `ARRIVED`, so `_runInProgress` is false and `PrStatusPagePassive` renders (`:239`) with the headline **"All home"** and *"There is no trip running right now."* Directly beneath it, `_studentRow` maps `ARRIVED → ChildLocation.inSchool` (`child_location_ui.dart:38`) and shows a chip reading **"IN SCHOOL"**.

**Repro:** parent account, any weekday between ~09:00 and the afternoon run. Both statements are on screen simultaneously.

**Fix:** the passive card needs three states, not two. Derive it from the same location mapping the roster uses:

```dart
enum _Quiet { beforeSchool, atSchool, dayOver }

_Quiet get _quietState {
  final locs = _students!
      .map((s) => childLocationFor(
            phase: _phaseByStudent[s.id], status: _statusByStudent[s.id]))
      .toList();
  if (locs.any((l) => l == ChildLocation.inSchool)) return _Quiet.atSchool;
  return _phaseByStudent.values.any((p) => p == 'afternoon')
      ? _Quiet.dayOver
      : _Quiet.beforeSchool;
}
```

and give `PrStatusPagePassive` a parameter selecting the headline/icon ("All home" / "All at school" / "All home — day complete"). Three new ARB keys per locale.

**Effort:** 1–2h including strings. **Trade-off:** none.

---

### 8. Unchecked casts throughout the model layer

Every `fromJson` casts required fields directly:

```dart
attendanceId: json['attendanceid'] as int,   // attendance_service.dart:37
id: json['id'] as int,                        // protected_service.dart:23, :54, :73
routeId: route['id'] as int,                  // route_service.dart:? / :131
phone: json['phone'] as String,               // protected_service.dart:25
```

Two concrete hazards, both real rather than theoretical:

- **`num` vs `int`.** `route_service.dart:30-33` already documents that Postgres numerics "may arrive as int or double" and handles it with `(json['x'] as num).toDouble()`. Nothing else does. A `BIGINT` serialized as `1.0` by any middleware makes `as int` throw.
- **Socket payloads.** `socket_service.dart:159-161` casts `map['attendanceid'] as int?` inside a socket.io callback. A throw there is not caught by anything and does not go through `_controller`, so the live feed dies silently while the UI keeps showing stale state.

`AuthService.login:46-56` is the worst case: `body['accessToken'] as String` and `userJson['id'] as int` throw `TypeError`, which `cm_login_page.dart:91` catches as a generic `connectionError` — so a backend contract change presents to the user as "check your internet".

**Fix:** one shared coercion helper, applied to every `fromJson`:

```dart
// lib/services/json.dart
int reqInt(Map<String, dynamic> j, String k) {
  final v = j[k];
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) {
    final p = int.tryParse(v);
    if (p != null) return p;
  }
  throw ApiException('Malformed field "$k" in server response');
}
String reqStr(Map<String, dynamic> j, String k, {String? or}) { … }
int? optInt(Map<String, dynamic> j, String k) { … }
```

Wrap `_emitRoster` and the `SocketEvent.updated` handler in `try/catch` so a malformed frame is dropped, not fatal.

**Effort:** 3–4h. **Trade-off:** slightly more verbose models; consider `json_serializable` + `build_runner` instead if the schema is going to keep moving (bigger up-front cost, less hand-written cast code).

---

### 9. Dead buttons shipped to drivers

**`lib/Widgets/Driver Widgets/dv_broadcast_status.dart:41,56,74`** — `onPressed: () => {}` on all three broadcast buttons ("Major delay", "Minor delay", "On schedule"). This card is rendered on all three active driver screens (`dv_status_page.dart:630,698,915`).

Note `() => {}` is a Dart *set literal*, not an empty block — the analyzer will not flag it as an empty body.

`pr_payment_page.dart` documents having removed exactly this kind of fake affordance ("it looked like a working payment entry point but did nothing"). The same reasoning applies here.

**Fix:** either hide the card behind a feature flag until a backend broadcast endpoint exists (~30 min), or implement it (~4h + backend). **Trade-off:** hiding removes a visible feature; shipping it as-is teaches drivers the app ignores them, which is worse.

---

## 4. Minor

### 10. GPS stream survives map collapse
`dv_route_map.dart:99` — `_startLocation` returns early if `_positionSub != null`, and collapsing (`:191`) only sets `_expanded = false`. A high-accuracy stream with a 10m filter then runs for the rest of the 45-minute run behind a closed panel. Cancel `_positionSub` on collapse and null it out so `_open` can restart it. **30m.**

### 11. Socket room join/leave is not reference-counted
`socket_service.dart:187-196`. `_joinedRoutes` is a plain `Set<int>`; the first `leaveRoute` for a given id evicts the room for *all* listeners. Today only `PrBoardingWidget` joins, so it is latent — but `disconnect()` (`:199`) also clears `_joinedRoutes` wholesale, so any second consumer added later breaks the first. Replace with `Map<int, int>` refcounts. **1h.**

### 12. Connection-health notifiers are never rendered
`socket_service.dart:69,72` — `connected` and `lastError` are `ValueNotifier`s created and maintained, with a doc comment promising "UI can watch this to tell the user their status may be stale". Nothing reads them (verified by grep). A parent whose socket is down sees a confidently stale roster. Wire a `ValueListenableBuilder` banner into `PrBoardingWidget`. **1h.**

### 13. Device locale ignored on first launch
`main.dart:35-36` — `_locale = widget.initialLocale ?? const Locale('en')`, and `MaterialApp.locale` is therefore never null, so Flutter's locale resolution never runs. An Arabic-phone user gets English until they find the toggle. Separately, `l10n.dart:4` lists `[ar, en]`, so `supportedLocales.first` is Arabic — meaning if you *do* pass `null`, unmatched locales fall back to Arabic.

**Fix:** pass `widget.initialLocale` straight through (nullable) and reorder `L10n.all` to `[en, ar]`. **30m.** **Trade-off:** existing users who never touched the toggle may see the language change once.

### 14. RTL and locale-flag slips
- `cm_login_page.dart:228` — `textAlign: TextAlign.left` inside a `crossAxisAlignment: start` column; use `TextAlign.start` or drop it.
- `cm_login_page.dart:164` — `EdgeInsets.only(top: 8, right: 12)` on a widget aligned `centerEnd`; use `EdgeInsetsDirectional.only(end: 12)`. (`cm_logout_tile.dart:82-84` documents fixing this exact class of bug elsewhere.)
- `pr_settings_page.dart:31` uses 🇸🇦 for Arabic while `cm_login_page.dart:146` uses 🇮🇶 for the same language, in an app branded for Iraq.
- Also in the dead widgets: `dv_delivery_widget_active.dart:60`, `dv_delivery_widget_passive.dart:36`.

Add `lints: - use_decorated_box` style rules won't catch these; a directional-padding review is the practical control. **30m.**

### 15. Integration test asserts a dead string
`integration_test/login_flow_test.dart:79-80` expects `'Welcome to Pasaty!'`; `app_en.arb` now says `'Welcome to Masar Alburhan!'`. The test fails today. It is not caught because CI runs `flutter test` (which only picks up `test/`) and never `flutter test integration_test/`. Fix the string, and either wire the integration suite into CI behind a service container or mark it clearly as manual-only. **5m + CI decision.**

### 16. No service-layer tests
`test/` contains: 8 file-content compliance assertions, 3 pure-function assertions for `runWindowFor`, and 1 widget smoke test. The code most likely to break — token refresh, JSON coercion, the socket event fan-out, `loadSessions` windowing — has zero coverage. See §6 for a concrete list.

### 17. History does N requests per page
`attendance_service.dart:300-339` probes one `POST /v1/attendance/:id/attendance` per calendar day — 14 requests per "Load earlier" tap, 5 at a time. The comment is honest about why (no list endpoint). This is a **backend** change: add `GET /v1/attendance/:routeid/sessions?from=&to=`. Until then it is a battery and latency cost the driver pays on a mobile connection. **Client change is ~1h once the endpoint exists.**

### 18. Hygiene
- **Dead code** (compiled, zero references — verified by grep): `lib/Widgets/Parent Widgets/pr_status_active_widget.dart` (contains hardcoded "about six minutes till arrival" copy the parent page explicitly abandoned), `lib/Widgets/Driver Widgets/dv_delivery_widget_active.dart`, `dv_delivery_widget_passive.dart` (hardcoded bus "13", "15 stops", "47 minutes"), `lib/Pages/Parent Pages/pr_schedule_page.dart`, and `lib/Util/dv_timer_widget.dart` (a one-line comment file). Delete them — they carry the exact fake-data patterns the rest of the app has been cleaned of, and a future developer will copy from them.
- **Package name.** `pubspec.yaml` still says `name: mockup`, so every import reads `package:mockup/…` in an app called Masar Alburhan. Renaming is mechanical but touches ~35 files — worth doing once, before the codebase grows.
- **Directory names with spaces.** `lib/Pages/Driver Pages/` forces URL-encoded imports (`package:mockup/Pages/Driver%20Pages/…`), which is why the repo mixes `%20` package imports with relative `../../l10n/` imports in the same files. Effective Dart wants `lowercase_with_underscores` for directories: `lib/pages/driver/`, `lib/widgets/driver/`. Do it in the same commit as the package rename.
- **`intl: any`** in `pubspec.yaml` — unbounded constraints are a pub anti-pattern; pin `^0.20.2`.
- `pubspec.yaml` `description: "A new Flutter project."`.

### 19. CI gaps
`.github/workflows/ci.yaml` is good — the two grep guards for placeholder IDs and loopback URLs are genuinely clever belt-and-braces. Missing:

```yaml
- uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.44.8'   # pin: `channel: stable` floats and can break CI with no repo change
    cache: true

- run: dart format --output=none --set-exit-if-changed .

- run: flutter test --coverage
- uses: VeryGoodOpenSource/very_good_coverage@v3
  with:
    path: coverage/lcov.info
    min_coverage: 40    # start here, ratchet up

# iOS is never compiled today — an Info.plist or pbxproj mistake reaches a human first
- run: flutter build ios --release --no-codesign
  runs-on: macos-latest   # separate job
```

Also add a guard for `onPressed: () => {}` / `onPressed: () {}` so §9 cannot recur.

---

## 5. Architecture recommendations

The app is entirely `setState` + static singletons. That is a legitimate choice at ~4k LOC of app code, and I would **not** recommend a rewrite. Two targeted changes get most of the benefit:

**(a) Make the services injectable.** `AuthService`, `ApiClient`, `ProtectedService`, `AttendanceService` are all-static, so nothing can be tested without a live backend — which is exactly why `test_live/` and `integration_test/` exist and why unit coverage is zero. Convert to instance classes behind a constructor-injected `http.Client`:

```dart
class ApiClient {
  ApiClient({http.Client? client, AuthService? auth})
      : _client = client ?? http.Client(),
        _auth = auth ?? AuthService.instance;
}
```

With `package:http/testing.dart`'s `MockClient` you can then test refresh, timeouts, and JSON coercion in-process. This is the single highest-leverage refactor here.

**(b) Lift the parent's live state out of the widget.** `PrBoardingWidget` holds four maps, a socket subscription, and a join-set inside `State` (`pr_boarding_widget.dart:38-53`). That is why §7 exists — the "is a run happening" question is answered by scanning a map that also has to be right for the roster. Move it into a `ChangeNotifier` (`TripStateNotifier`) exposing `runInProgress`, `phase`, and `locationFor(studentId)`, and let the widget be a `ListenableBuilder`. No new dependency needed — `ChangeNotifier` is in Flutter. If you want a package, `provider` is the smallest step; Riverpod is more than this app needs.

**(c) Freeze the mutable model.** `AttendanceStudent.status` is non-final (`attendance_service.dart:26`) and mutated in place from the UI (`dv_status_page.dart:179`). It works only because one widget owns the list. Make it `final` with `copyWith`, and have `_transition` replace the element — this removes a whole class of "two screens disagree" bugs before the app grows a second consumer.

---

## 6. Tests to add

**Unit — services** (blocked on refactor (a) above; `MockClient` makes all of these fast and hermetic):

| Test | Guards |
|---|---|
| Two concurrent 401s trigger exactly **one** `POST /v1/auth/refresh` | §1 |
| HTML / empty / truncated body → `ApiException`, not `FormatException` | §2 |
| A stalled response surfaces as a timeout inside N seconds | §5 |
| `AttendanceStudent.fromJson` accepts `"attendanceid": 1.0` and `"1"` | §8 |
| `refresh` 401 clears the session **and** fires `onSessionExpired` exactly once | §1 |
| `loadSessions(days: 14)` requests 14 distinct dates, no overlap on page 2 | §17 |

**Unit — pure logic** (no refactor needed; write these today):

- `childLocationFor` — the full 2 phases × 5 statuses matrix, plus the null/unknown fallbacks. This is the function the parent-facing correctness of the whole app rests on and it has no tests.
- The new three-state `_quietState` from §7.
- `RunSummary._parseInterval` with partial Postgres intervals (`{"minutes":45}`).

**Widget:**

- `DvStudentCard` — swipe start→end boards, end→start marks absent, `busy` blocks both (`confirmDismiss` returns false in every case, which is subtle enough to deserve a test).
- `StatusPage` — start a run on route A, switch the dropdown, resume, complete → asserts `completeMorning` was called with **A** (§4).
- Golden tests for the parent roster in `ar` and `en` at `textScaleFactor: 1.3` — the app clamps scaling at `main.dart:97-101` specifically because fixed-height chips overflow above that, and nothing currently verifies the clamp is enough.

**Integration:** fix `login_flow_test.dart:79`, then run it against a seeded backend in a CI service container so it stops being a manual step.

---

## 7. Suggested sequencing

1. **Before any release:** §3 (production URL), §1 (refresh lock), §2 (JSON guards), §5 (timeouts), §4 (route id), §6 (`mounted`), §9 (dead buttons), §15 (broken test).
2. **Next sprint:** §8 (coercion helpers), §7 (parent quiet state), §12 (connection banner), §13/§14 (locale + RTL), §19 (CI gates).
3. **When there's slack:** refactor (a) then backfill the §6 test table; §18 hygiene (delete dead widgets, rename package + directories in one commit); §17 with the backend.

Items 1–2 are roughly **3–4 developer-days** together. The refactor in step 3 is another **2–3 days** including tests, and it is what makes items 1 and 2 stay fixed.
