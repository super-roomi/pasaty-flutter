# Live driver location on iOS — root cause, fix, and validation

**Date:** 2026-08-21
**Scope:** `DriverLocationReporter`, `DvRouteMap`, iOS `Info.plist`, CI
**Status:** fixed in the working tree. Validated on an iPhone 16 Plus / iOS 27.0 —
including background delivery across a locked screen (§4). Not yet committed.

---

## 0. What I was and was not given

No logs, crash reports, device details, or reproduction steps were supplied with
the request, so nothing here is a reproduction of a *reported* symptom. What
follows is derived from the code and from the geolocator plugin's own iOS
source, and every claim marked **proved** is backed by a test that intercepts
the platform channel and asserts on what actually crossed it
(`test/ios_location_stream_test.dart`).

A physical iPhone was made available partway through, so §4 is real hardware
rather than inference. The console output from an *originally failing* run —
anything tagged `[location]` or `[location-stream]` — would still be the thing
that confirms which of the three defects below was the one you hit.

### Environment as found

| Item | Value |
|---|---|
| Flutter / Dart | 3.44.8 stable (engine `13ffd72b2f9a`) / 3.12.2 |
| geolocator | 14.0.3 → `geolocator_apple` 2.3.14, `geolocator_android` 5.0.3 |
| iOS deployment target | 15.0, iPhone only (`TARGETED_DEVICE_FAMILY = 1`) |
| iOS plugin integration | **Swift Package Manager**, not CocoaPods |
| CocoaPods | 1.17.0, but `Podfile.lock` legitimately contains only `Flutter` |
| Other native plugins | firebase_core/messaging, flutter_secure_storage, shared_preferences, url_launcher, package_info_plus |
| Background execution | `UIBackgroundModes: [location]`; no background-fetch, no BGTaskScheduler |
| Entitlements | `aps-environment: development` only |
| Analyzer | `flutter analyze` → 0 issues |

A note on the empty `Podfile.lock`, because it looks alarming and is not: this
project has migrated to Swift Package Manager. `flutter build ios` says so
directly —

```
All plugins found for ios are Swift Packages, but your project still has
CocoaPods integration.
```

`geolocator_apple` is linked through
`ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage`, which the
Xcode project references as an `XCLocalSwiftPackageReference`. Verified in the
built binary: it links `CLLocationManager` and contains the
`flutter.baseflow.com/geolocator_updates_apple` channel name. The stale-looking
lockfile is a leftover, not a break — see "Follow-ups" for the cleanup.

---

## 1. Root causes

All three share one origin: **`geolocator` caches the position stream and
silently discards the settings of every caller after the first.**

```dart
// geolocator_apple-2.3.14/lib/src/geolocator_apple.dart
Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
  if (_positionStream != null) {
    return _positionStream!;      // locationSettings ignored entirely
  }
  ...
}
```

The app had two callers: `DriverLocationReporter` (the run) and `DvRouteMap`
(the driver's map card). On iOS the settings passed here are the *only* place
`allowsBackgroundLocationUpdates`, `pausesLocationUpdatesAutomatically` and
`showsBackgroundLocationIndicator` are ever set on the `CLLocationManager` —
`PositionStreamHandler.onListenWithArguments:` reads them from the `listen`
arguments and hands them to `GeolocationHandler`. Whichever caller listened
first therefore configured CoreLocation for both.

### 1.1 The run tracked with the map's CoreLocation configuration — **proved**

Sequence: driver opens the route map, then starts the run.

1. `DvRouteMap._startLocation()` calls `getPositionStream` with its own
   `AppleSettings` — no `showBackgroundLocationIndicator`.
2. `DriverLocationReporter.start()` calls `getPositionStream` with the run's
   settings. It gets the map's cached stream. **Its settings never reach the
   platform.** Only one `listen` crosses the channel, not two.

The blue status-bar indicator was therefore off for the whole run. That matters
beyond cosmetics: the `Info.plist` purpose string promises the driver *"This
continues while the screen is locked"* and the indicator is the only signal that
it is happening, which is also what App Review looks for on a
`when-in-use` + background-location app.

What made this hard to catch: `AppleSettings.allowBackgroundLocationUpdates`
defaults to `true`, so background delivery kept working and the failure was
invisible at a desk. The reporter kept receiving fixes from a stream it had not
configured, and every counter on the diagnostics screen looked healthy.

### 1.2 The stale-stream watchdog was a no-op whenever the map was open — **proved**

`_checkAlive()` rebuilt the subscription by cancelling and re-listening:

```dart
_sub?.cancel();
_sub = Geolocator.getPositionStream(...).listen(...);
```

Cancelling one of two subscriptions is not the last cancel. The plugin's
`asBroadcastStream(onCancel: ...)` therefore never fires, `_positionStream`
stays cached, and **no `cancel`/`listen` pair is sent to the platform at all.**
The "rebuild" re-listened to a Dart broadcast stream while the native location
manager stayed exactly as dead as it was.

The watchdog exists precisely for a stream that has gone quiet without erroring.
It was disabled in the one situation where a driver would be looking at the
map — i.e. when they had noticed something was wrong.

The `cancel`-before-`listen` ordering was worth checking too, because iOS
answers a `listen` that arrives while a sink is still installed with
`LOCATION_SUBSCRIPTION_ACTIVE` and starts no location manager. Ordering turned
out to be correct, and there is now a test pinning it.

### 1.3 Precise Location off → the run reports nothing, silently — **proved**

iOS 14+ lets the user grant location while withholding *precise* location.
Nothing in the app ever looked:

- no call to `Geolocator.getLocationAccuracy()` anywhere in `lib/`
- no call to `requestTemporaryFullAccuracy`
- no `NSLocationTemporaryUsageDescriptionDictionary` in `Info.plist`, so the
  request would have thrown even if it had been made

With Precise Location off, `checkPermission()` still returns `whileInUse` and
CoreLocation still delivers fixes — at roughly 1–3 km accuracy. Every one of
them is then dropped by the reporter's own gate:

```dart
static const double _maxAccuracyMetres = 200;   // backend rejects above this
if (position.accuracy > _maxAccuracyMetres) { _dropped++; return; }
```

Nothing is ever emitted, so nothing ever times out, so `reporting` stays `true`
and the warning banner never appears. **The driver sees a completely normal
screen for a 45-minute run during which the school sees no bus at all.** This is
the failure mode most likely to look like "live location just doesn't work on
iOS", and it is entirely invisible from the client.

### 1.4 Also fixed, lower severity

| | Issue | File |
|---|---|---|
| a | Collapsing the map left its GPS subscription running for the rest of the session, contradicting the "GPS only while the map is open" comment directly above it | `dv_route_map.dart` |
| b | A malformed socket ack cancelled the timeout and then returned without calling any callback, freezing the unacknowledged counter so the socket could never be rebuilt and the driver was never told | `socket_service.dart` |
| c | `test/eta_socket_integration_test.dart` and `socket_ack_timeout_test.dart` need a hand-started helper server that is not in the repo, but were collected by a plain `flutter test`, so **CI was red on every PR** | `dart_test.yaml` (added) |

---

## 2. The fix

### 2.1 One owner for the OS location stream

New `lib/services/location_stream.dart`. It holds the app's only
`getPositionStream` subscription, with one settings object, and reference-counts
consumers:

```dart
LocationStream.instance.attach(this).listen(...);   // map and reporter both
await LocationStream.instance.detach(this);         // stops the receiver when
                                                    // the last one leaves
await LocationStream.instance.restart();            // a real platform restart
```

`restart()` awaits the cancel before re-listening, so the plugin genuinely drops
its cache and the native location manager is rebuilt — which is what makes the
watchdog work again regardless of who else is attached.

Consequences worth calling out:

- Settings can no longer diverge between callers, because there is only one set.
- `showBackgroundLocationIndicator` is now always `true`, not only during a run.
  The map opens the receiver too, and the driver should see that either way.
- The Android foreground-service notification is supplied by the reporter via
  `setForegroundNotification`, and the stream is restarted when a run starts so
  a map-started stream is promoted to a foreground service. It is restarted
  again when the run ends so the "run in progress" notification does not outlive
  the run.

A CI grep enforces the invariant — nothing outside `location_stream.dart` may
call `getPositionStream`.

### 2.2 Precise Location

`DriverLocationReporter.start()` now checks accuracy and asks for a temporary
upgrade, keyed to a new `Info.plist` entry:

```dart
var status = await Geolocator.getLocationAccuracy();
if (status == LocationAccuracyStatus.reduced) {
  status = await Geolocator.requestTemporaryFullAccuracy(purposeKey: 'RunTracking');
}
```

If the driver declines, `reducedAccuracy` goes true, `reporting` goes false, and
the run screen shows a specific message with an **Open Settings** button instead
of the generic connectivity warning. A second, independent trigger catches the
case where the grant lapses mid-run: five consecutive drops with nothing ever
sent raises the same flag, and the first usable fix clears it.

`NSLocationTemporaryUsageDescriptionDictionary` / `RunTracking` added to
`Info.plist`, with copy that says what the driver loses by refusing.

### 2.3 Files changed

| File | Change |
|---|---|
| `lib/services/location_stream.dart` | **new** — single owner, ref-counted, real restart |
| `lib/services/driver_location_reporter.dart` | attach/detach instead of its own stream; precise-accuracy handling; watchdog restarts the platform stream |
| `lib/Widgets/Driver Widgets/dv_route_map.dart` | attach/detach; releases on collapse; own settings deleted |
| `lib/Pages/Driver Pages/dv_status_page.dart` | banner distinguishes reduced accuracy from connectivity, offers Settings |
| `lib/services/socket_service.dart` | malformed ack reported instead of swallowed |
| `ios/Runner/Info.plist` | `NSLocationTemporaryUsageDescriptionDictionary` |
| `lib/l10n/app_{en,ar}.arb` | `locationReducedAccuracy` |
| `test/ios_location_stream_test.dart` | **new** — 11 channel-level tests |
| `dart_test.yaml` | **new** — skip `integration` by default |
| `.github/workflows/ci.yaml` | stream-ownership guard, plist guard, macOS iOS build job |
| `.gitignore` | ignore `test/failures/` |
| `pubspec.yaml` | `geolocator_apple` as a dev dependency (tests only) |

---

## 3. Tests

`test/ios_location_stream_test.dart` registers the real `GeolocatorApple`
implementation and mocks the platform channels, so it asserts on the arguments
that would reach `PositionStreamHandler.onListenWithArguments:`. Asserting on
the Dart settings objects would prove nothing — the plugin throws them away,
which is the whole bug.

| Group | Test |
|---|---|
| background settings | a run on its own configures the location manager |
| | **a run started while the map is open still configures it** ← 1.1 |
| | both consumers share one platform subscription |
| watchdog recovery | a restart cancels before it listens again |
| | **a restart still reaches the platform while the map listens** ← 1.2 |
| consumer lifecycle | the receiver stops when the last consumer detaches |
| | closing the map mid-run leaves the run reporting |
| reduced accuracy | a run asks for temporary full accuracy when precise is off |
| | **a driver who refuses full accuracy is told, not ignored** ← 1.3 |
| | wide fixes with nothing sent raise the flag mid-run |
| | the flag clears as soon as a usable fix arrives |

### On-device suites

| File | Covers |
|---|---|
| `integration_test/ios_location_device_test.dart` | permission/accuracy state, a real first fix, watchdog restart with a second consumer, consumer lifecycle, the reporter end to end minus the backend |
| `integration_test/ios_background_location_test.dart` | delivery across a hand-driven lock/unlock, judged against the app's own `AppLifecycleState` |

Both are tagged `device` and are not collected by a plain `flutter test`.

### Commands run

```bash
flutter analyze                                   # 0 issues
flutter test                                      # 79 passed, 3 skipped, 0 failed
flutter test test/ios_location_stream_test.dart   # 11 passed
flutter build ios --no-codesign --dart-define-from-file=dart_defines.json

# on the handset
flutter test integration_test/ios_location_device_test.dart \
  -d 00008140-001549581E93801C --dart-define-from-file=dart_defines.json
flutter test integration_test/ios_background_location_test.dart \
  -d 00008140-001549581E93801C --dart-define-from-file=dart_defines.json
```

Built-artifact checks:

```bash
/usr/libexec/PlistBuddy -c "Print :UIBackgroundModes" build/ios/iphoneos/Runner.app/Info.plist
# → Array { location }
/usr/libexec/PlistBuddy -c "Print :NSLocationTemporaryUsageDescriptionDictionary" build/ios/iphoneos/Runner.app/Info.plist
# → Dict { RunTracking = ... }
nm -u build/ios/iphoneos/Runner.app/Runner | grep CLLocationManager
# → _OBJC_CLASS_$_CLLocationManager
```

Before this change `flutter test` failed; it now passes because the two
integration-tagged tests are skipped by default. Run them deliberately with
`flutter test --tags integration --dart-define=API_BASE_URL=http://127.0.0.1:4599`,
after starting the helper server — **which is still missing from the repo**, see
Follow-ups.

---

## 4. On-device results

**iPhone 16 Plus (iPhone17,4), iOS 27.0 (24A5418b), debug build over USB.**
Two integration suites, both green. iOS 27 is well ahead of the 15.0 deployment
target, and this is also the first confirmation that the SPM plugin linkage and
the scene-based lifecycle (`FlutterSceneDelegate`) hold up there.

### `integration_test/ios_location_device_test.dart` — 5/5

```
DEVICE-STATE services=true permission=whileInUse accuracy=precise
FIRST-FIX    35.56330,45.48509 ±8m
GATE         pass — this fix would be reported
RESTART      recovered, ±8m
LIFECYCLE    receiver released
REPORTER     fixes=28 dropped=0 throttled=25 sent=3 accuracy=precise
             permission=whileInUse last=6m reduced=false
```

`RESTART recovered` is §1.2 proven fixed on real hardware: the watchdog rebuilt
the receiver *with a second consumer attached*, which is precisely the case that
previously issued no platform call at all.

`fixes=28 / throttled=25 / sent=3` over 40 s confirms the pacing arithmetic —
CoreLocation delivers at roughly 1 Hz and the 14 s throttle turns that into one
report per ~13 s against a 15 s target. It also quantifies the battery point in
§8: the receiver really does run at full navigation rate.

### `integration_test/ios_background_location_test.dart` — 1/1

The screen was locked by hand and the app's own lifecycle observer recorded the
transition, so the result is judged against what the OS actually reported rather
than against wall-clock guesswork.

```
transitions:  6s -> paused        88s -> hidden/inactive, 89s -> resumed
verdict:      backgrounded 3s..84s: fixes 6->89 (+83), sent 1->6 (+5)
```

81 seconds locked. **83 fixes and 5 reports arrived during it**, at a steady
~1 fix/s and one report per ~16 s, with no stall at either transition:

| t | 5s | 15s | 30s | 45s | 60s | 75s | 85s |
|---|---|---|---|---|---|---|---|
| fixes | 8 | 19 | 34 | 50 | 65 | 80 | 90 |
| sent | 1 | 2 | 3 | 4 | 6 | 6 | 6 |
| state | paused | paused | paused | paused | paused | paused | resumed |

That is `UIBackgroundModes: location` plus `allowsBackgroundLocationUpdates`
working end to end on this handset and this iOS version — the core of the
feature, confirmed rather than argued.

## 5. What is still NOT verified

- **The blue background-location indicator** has not been eyeballed. It is the
  user-visible half of §1.1 and the thing the Info.plist copy promises; the
  channel test proves the flag is sent, but nobody has yet confirmed iOS draws
  it.
- **The reduced-accuracy path (§1.3) has not run on device.** The handset
  reports `precise`, so the branch that matters was never taken. This is the
  single highest-value test left, because it is the failure mode most likely to
  be the original complaint. Toggle Settings → Masar Alburhan → Location →
  Precise Location **off** and re-run the first suite; expect
  `accuracy=reduced` and `reduced=true` instead of a silent run of drops.
- **No full run through the backend.** Both suites deliberately stop at the
  socket, so `driver:location` has never been accepted by the server on this
  build. The reporter's unacknowledged-report path did fire correctly during the
  test, which at least exercises that branch.
- **The map-opened-first ordering has not been walked in the real UI** — only in
  the channel test.
- **Nothing has moved.** A stationary handset on a desk is not a bus: no
  sustained drive, no tunnel, no cell handover, no 45-minute duration.
- **Battery draw is unmeasured**, though §4 now puts a number on the delivery
  rate that drives it.
- **`aps-environment` is `development`.** Out of scope, but a TestFlight or App
  Store build needs `production` or push silently stops working.
- **The originally reported symptom is still unconfirmed** — see §0.
- **Battery draw is unmeasured.** `distanceFilter: 0` means CoreLocation
  delivers at roughly 1 Hz while the app throttles to one report per 15 s, so
  the GPS chip runs at full navigation rate for the entire run. That is a
  deliberate trade (a non-zero filter stalls a stationary bus completely) but it
  has a real cost that nobody has put a number on.
- **`aps-environment` is `development`.** Not touched, not in scope, but a
  TestFlight or App Store build needs `production` or push silently stops
  working. Worth confirming your signing setup rewrites it.

---

## 6. Device matrix for on-device regression

Run each as a full morning-run cycle. "Reports" = the row reaching the backend
and the parent's ETA advancing, not just the app looking busy.

| # | Device / OS | Precise Location | Scenario | Expect |
|---|---|---|---|---|
| 1 | iPhone SE 2/3, iOS 15 | On | Start run, screen locked 10 min | Blue bar visible; reports every ~15 s |
| 2 | iPhone 13/14, iOS 17 | On | Start run, app backgrounded, drive 20 min | Continuous reports; no gap at background transition. **Partially covered** — 81 s stationary on iPhone 16 Plus / iOS 27, §4 |
| 3 | iPhone 15/16, iOS 18+ | On | **Open map, then start run** | Blue bar appears; regression 1.1 |
| 4 | any | **Off** | Start run | Prompt appears; on Allow → reports. On Don't Allow → red banner + Open Settings, no silent failure. Regression 1.3. **Not yet run on device — highest priority** |
| 5 | any | On | Mid-run: Settings → Precise Location off, then on | Banner appears then clears within one interval |
| 6 | any | On | Mid-run: airplane mode 2 min, then off | Banner appears; reporting resumes without restarting the run |
| 7 | any | On | Open map, collapse it, keep running | Reports continue; blue bar stays |
| 8 | any | On | Complete run | Reporting stops; blue bar clears; no lingering notification |
| 9 | Android (Xiaomi/MIUI) | n/a | Start run, background 30 min | Foreground notification present; watchdog recovers if MIUI stalls delivery. Regression 1.2 (the restart itself is confirmed on iOS, §4) |
| 10 | Android 14+ | n/a | Complete run with map open | "Run in progress" notification is dismissed |

Rows 3, 4 and 9 are the actual regressions; the rest are guard rails.

---

## 7. Rollout, risk and rollback

**Risk: medium.** The change is confined to how the location stream is owned,
but every run depends on it, and the highest-risk edit is one nothing here can
test — Android's foreground-service promotion, which now involves a stream
restart when a run begins.

| Risk | Likelihood | Mitigation |
|---|---|---|
| Android foreground service does not attach after the restart, and Android kills location on background | Medium | Matrix row 9 before release. The restart only happens when the map already opened the stream; if it misbehaves, have the reporter refuse to share and open its own stream for the run |
| Extra `cancel`/`listen` at run start drops a fix | Low | One fix at most, at the start of a run; the throttle would have discarded it anyway |
| Temporary-accuracy prompt confuses drivers | Medium | Copy names the consequence. Watch first-week support volume; the prompt only appears for drivers who already turned Precise Location off |
| Blue indicator now shows when only the map is open | Low, intended | The app is locating them; App Review prefers this direction |

**Rollout**

1. Ship to TestFlight. Confirm `aps-environment` before doing so.
2. Two drivers, both platforms, one full day, with the `DIAG=true` build so the
   diagnostics card is visible:
   `flutter run --dart-define-from-file=dart_defines.json --dart-define=DIAG=true`
3. Compare backend location rows per run against the same route last week.
   Expect ~180 rows for a 45-minute run at 15 s. Materially fewer means a stall;
   materially more means the throttle is being bypassed.
4. Full fleet.

**Rollback.** Revert the commit. There is no migration, no persisted state, and
no backend change, so a revert is complete and immediate — the only residue is
the `Info.plist` key, which is inert if unused. If a partial rollback is needed,
reverting just `dv_route_map.dart` to open its own stream restores the old
behaviour while keeping the accuracy fix.

---

## 8. Follow-ups (not done here)

1. **Finish the SPM migration.** Flutter prints the steps on every iOS build:
   `pod deintegrate` in `ios/`, then drop the two `#include?` lines from
   `ios/Flutter/{Debug,Release}.xcconfig`. Removes the confusing empty
   `Podfile.lock` and cuts build time.
2. **Commit the integration helper servers.** `eta_test_server.js` and the
   silent-ack server are referenced by name in test headers but are not in the
   repo, so those tests cannot be run by anyone who did not write them.
3. **Measure battery** over a real run and decide whether 1 Hz delivery is worth
   it, or whether a small `distanceFilter` plus a periodic forced fix is better.
4. **`aps-environment: development`** — confirm the release pipeline rewrites it.
5. `ApiConfig._production` is still `''`; release builds depend entirely on
   `--dart-define`. CI enforces this, but it is a sharp edge.
