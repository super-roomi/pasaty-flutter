import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:mockup/Util/debug_log.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'auth_session.dart';

/// One notification as the app keeps it.
///
/// The server composes `title`/`body` in the language the device registered
/// with, so nothing here is localised on the client — the app only reports
/// *which* language to use, at registration time.
class PushMessage {
  final String title;
  final String body;
  final Map<String, String> data;
  final DateTime receivedAt;
  bool read;

  PushMessage({
    required this.title,
    required this.body,
    required this.data,
    required this.receivedAt,
    this.read = false,
  });

  String get type => data['type'] ?? '';

  /// Ids arrive as strings — FCM rejects anything else in `data`.
  ///
  /// `tryParse`, not `parse`: a malformed id from the server should cost the
  /// tap its routing, not crash the isolate that is drawing the inbox.
  int? get routeId => int.tryParse(data['routeid'] ?? '');
  int? get studentId => int.tryParse(data['studentid'] ?? '');
  String? get phase => data['phase'];
  String? get newStatus => data['new_status'];

  factory PushMessage.fromRemote(RemoteMessage m) => PushMessage(
    title: m.notification?.title ?? '',
    body: m.notification?.body ?? '',
    data: m.data.map((k, v) => MapEntry(k, '$v')),
    receivedAt: m.sentTime ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'body': body,
    'data': data,
    'at': receivedAt.toIso8601String(),
    'read': read,
  };

  factory PushMessage.fromJson(Map<String, dynamic> j) => PushMessage(
    title: (j['title'] ?? '').toString(),
    body: (j['body'] ?? '').toString(),
    data: (j['data'] as Map?)?.map((k, v) => MapEntry('$k', '$v')) ?? const {},
    receivedAt:
        DateTime.tryParse((j['at'] ?? '').toString()) ?? DateTime.now(),
    read: j['read'] == true,
  );
}

/// Messages that arrived while the app was backgrounded or killed are handled
/// in a separate isolate with no access to [PushService]'s state, so they are
/// appended to their own key and merged by the foreground on resume. Writing
/// to the main list from here would be clobbered by the next foreground save.
const _inboxKey = 'push_inbox';
const _pendingKey = 'push_inbox_pending';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // The tray entry is drawn by the OS because the server sends a
  // `notification` block. All this does is make sure the message is still
  // there in the bell when the user opens the app.
  try {
    await Firebase.initializeApp();
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList(_pendingKey) ?? <String>[];
    pending.add(jsonEncode(PushMessage.fromRemote(message).toJson()));
    await prefs.setStringList(_pendingKey, pending.take(50).toList());
  } catch (_) {
    // A background isolate that throws takes the notification down with it.
  }
}

/// Firebase Cloud Messaging: registration, delivery, and the inbox behind the
/// bell.
///
/// Push is best-effort by design — tokens rotate, phones go offline,
/// permission gets declined, and Android's battery optimiser defers delivery.
/// Nothing in the UI may assume a notification arrived; live state comes from
/// the socket layer while the app is open. Accordingly every failure path
/// here degrades to "no push" rather than to an error the user sees.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  static const int _maxInbox = 50;

  /// False when Firebase could not start — most often a missing
  /// `google-services.json` on Android. The app runs normally without it.
  bool _available = false;
  bool get available => _available;

  String? _token;

  /// The token the server currently knows about, with the language it was
  /// registered under. Lets a locale change re-register only when it would
  /// actually change something.
  String? _registeredToken;
  String? _registeredLanguage;

  /// A token that arrived from `onTokenRefresh` while nobody was signed in.
  /// `/v1/devices` is authenticated, so it is held until a session exists.
  bool _registrationPending = false;

  /// Language to register with, kept up to date by the app's locale.
  String _language = 'en';

  final ValueNotifier<List<PushMessage>> inbox = ValueNotifier(const []);

  /// Foreground arrivals. FCM draws nothing while the app is open, so
  /// something has to; the banner host in `main.dart` listens here.
  final _foreground = StreamController<PushMessage>.broadcast();
  Stream<PushMessage> get foregroundMessages => _foreground.stream;

  /// A notification the user tapped, waiting to be routed. Consumed by the
  /// shell, which clears it.
  final ValueNotifier<PushMessage?> tapped = ValueNotifier(null);

  int get unreadCount => inbox.value.where((m) => !m.read).length;

  void _log(String message) {
    debugLog('push', message);
  }

  /// Starts Firebase and wires the three delivery paths. Never throws.
  ///
  /// Called before `runApp`, so a failure here must not stop the app
  /// launching — a missing config file would otherwise be a crash on start.
  Future<void> init({required String language}) async {
    _language = language;
    await _loadInbox();

    try {
      await Firebase.initializeApp();
      _available = true;
    } catch (e) {
      _log('firebase unavailable: $e');
      return;
    }

    try {
      FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler,
      );

      FirebaseMessaging.onMessage.listen(_onForeground);
      FirebaseMessaging.onMessageOpenedApp.listen(_onTapped);

      // A tap that cold-started the app: without this the launch loses the
      // routing entirely.
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _onTapped(initial);

      FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        _log('token refreshed');
        _token = token;
        if (AuthSession.instance.accessToken != null) {
          unawaited(_register());
        } else {
          // Registering now would 401. Hold it until a session exists.
          _registrationPending = true;
        }
      });
    } catch (e) {
      _log('wiring failed: $e');
    }
  }

  /// Called once a session exists — after login, and on launch when a stored
  /// session was restored.
  ///
  /// Permission is requested here rather than at app start: a first-time user
  /// meeting a notification prompt on the login screen, before they know what
  /// the app is, declines it and Android never asks again.
  Future<void> onSignedIn({String? language}) async {
    if (language != null) _language = language;
    if (!_available) return;

    try {
      await FirebaseMessaging.instance.requestPermission();
    } catch (e) {
      _log('permission request failed: $e');
    }

    await _register();
  }

  /// The app's locale changed. The server composes notification text, so it
  /// has to be told.
  Future<void> onLanguageChanged(String language) async {
    if (_language == language) return;
    _language = language;
    if (!_available) return;
    if (AuthSession.instance.accessToken == null) return;
    await _register();
  }

  /// The token to hand to `POST /v1/auth/logout`, so the row is removed and
  /// the next person to use this phone does not get pushes about another
  /// family's children. Null when there is nothing to unregister.
  String? get tokenForLogout => _token;

  /// Local teardown after logout. The server-side row is removed by the
  /// `device_token` field in the logout body.
  Future<void> onSignedOut() async {
    _registeredToken = null;
    _registeredLanguage = null;
    _registrationPending = false;
    tapped.value = null;
    inbox.value = const [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_inboxKey);
    await prefs.remove(_pendingKey);
  }

  /// Fetches the token if needed and posts it. Idempotent — the endpoint
  /// upserts, so a repeat costs one harmless write.
  Future<void> _register() async {
    final token = _token ??= await _fetchToken();
    if (token == null) {
      _log('no token yet — nothing to register');
      return;
    }

    if (token == _registeredToken && _language == _registeredLanguage) {
      _registrationPending = false;
      return;
    }

    try {
      await ApiClient.post('/v1/devices', body: {
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'language': _language,
      });
      _registeredToken = token;
      _registeredLanguage = _language;
      _registrationPending = false;
      _log('registered ($_language)');
    } catch (e) {
      // Losing push is not worth interrupting the user for. The next login,
      // token refresh, or language change retries.
      _log('registration failed: $e');
    }
  }

  /// On iOS `getToken()` returns null until APNs registration completes,
  /// which is a network round trip after launch. Poll briefly rather than
  /// treating the first null as "no push on this device".
  Future<String?> _fetchToken() async {
    try {
      if (Platform.isIOS) {
        var apns = await FirebaseMessaging.instance.getAPNSToken();
        for (var i = 0; i < 5 && apns == null; i++) {
          await Future.delayed(const Duration(seconds: 1));
          apns = await FirebaseMessaging.instance.getAPNSToken();
        }
        if (apns == null) {
          _log('no APNs token — registration deferred');
          _registrationPending = true;
          return null;
        }
      }
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      _log('getToken failed: $e');
      return null;
    }
  }

  void _onForeground(RemoteMessage message) {
    final m = PushMessage.fromRemote(message);
    _log('foreground: ${m.type}');
    _add(m);
    _foreground.add(m);
  }

  void _onTapped(RemoteMessage message) {
    final m = PushMessage.fromRemote(message)..read = true;
    _log('opened: ${m.type}');
    _add(m);
    tapped.value = m;
  }

  void _add(PushMessage m) {
    inbox.value = [m, ...inbox.value].take(_maxInbox).toList();
    unawaited(_saveInbox());
  }

  void markAllRead() {
    for (final m in inbox.value) {
      m.read = true;
    }
    // The list identity has to change for ValueNotifier to fire.
    inbox.value = [...inbox.value];
    unawaited(_saveInbox());
  }

  Future<void> clear() async {
    inbox.value = const [];
    await _saveInbox();
  }

  /// Reloads from disk and folds in anything the background isolate appended.
  /// Called on resume, before any foreground write, so a save cannot clobber
  /// a notification that arrived while the app was away.
  Future<void> refreshFromBackground() async {
    await _loadInbox();
    if (_registrationPending && AuthSession.instance.accessToken != null) {
      await _register();
    }
  }

  Future<void> _loadInbox() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_inboxKey) ?? const <String>[];
      final pending = prefs.getStringList(_pendingKey) ?? const <String>[];

      List<PushMessage> decode(List<String> raw) => raw
          .map((s) {
            try {
              return PushMessage.fromJson(
                jsonDecode(s) as Map<String, dynamic>,
              );
            } catch (_) {
              return null;
            }
          })
          .whereType<PushMessage>()
          .toList();

      final merged = [...decode(pending), ...decode(stored)]
        ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
      inbox.value = merged.take(_maxInbox).toList();

      if (pending.isNotEmpty) {
        await prefs.remove(_pendingKey);
        await _saveInbox();
      }
    } catch (e) {
      _log('inbox load failed: $e');
    }
  }

  Future<void> _saveInbox() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _inboxKey,
        inbox.value.map((m) => jsonEncode(m.toJson())).toList(),
      );
    } catch (e) {
      _log('inbox save failed: $e');
    }
  }
}
