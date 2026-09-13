import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockup/services/push_service.dart';

/// The payload contract with the backend, as documented in their README:
/// every `data` value is a string — FCM rejects anything else — and the app
/// parses the ids back out to route a tap.
void main() {
  group('PushMessage.fromRemote', () {
    test('reads an attendance update', () {
      final m = PushMessage.fromRemote(
        const RemoteMessage(
          notification: RemoteNotification(
            title: 'Ahmad',
            body: 'Boarded the bus',
          ),
          data: {
            'type': 'attendance_updated',
            'routeid': '7',
            'studentid': '12',
            'attendanceid': '99',
            'phase': 'morning',
            'new_status': 'BOARDED',
          },
        ),
      );

      expect(m.title, 'Ahmad');
      expect(m.body, 'Boarded the bus');
      expect(m.type, 'attendance_updated');
      expect(m.routeId, 7);
      expect(m.studentId, 12);
      expect(m.phase, 'morning');
      expect(m.newStatus, 'BOARDED');
    });

    test('a run event carries a route but no student', () {
      final m = PushMessage.fromRemote(
        const RemoteMessage(
          notification: RemoteNotification(title: 'Route 1', body: 'Started'),
          data: {'type': 'run_started', 'routeid': '7', 'phase': 'afternoon'},
        ),
      );

      expect(m.type, 'run_started');
      expect(m.routeId, 7);
      expect(m.studentId, isNull);
    });

    test('a malformed id costs the routing, not the isolate', () {
      // tryParse, not parse: a bad id from the server must not throw inside
      // the widget that is drawing the inbox.
      final m = PushMessage.fromRemote(
        const RemoteMessage(data: {'type': 'run_started', 'routeid': 'seven'}),
      );

      expect(m.routeId, isNull);
      expect(m.type, 'run_started');
    });

    test('a missing notification block does not throw', () {
      final m = PushMessage.fromRemote(const RemoteMessage(data: {}));
      expect(m.title, isEmpty);
      expect(m.body, isEmpty);
      expect(m.type, isEmpty);
    });
  });

  group('persistence', () {
    test('survives a JSON round trip', () {
      final original = PushMessage(
        title: 'Ahmad',
        body: 'Dropped off',
        data: const {
          'type': 'attendance_updated',
          'routeid': '7',
          'new_status': 'DROPPED_OFF',
        },
        receivedAt: DateTime.utc(2026, 8, 15, 14, 30),
        read: true,
      );

      final restored = PushMessage.fromJson(original.toJson());

      expect(restored.title, original.title);
      expect(restored.body, original.body);
      expect(restored.data, original.data);
      expect(restored.receivedAt, original.receivedAt);
      expect(restored.read, isTrue);
      expect(restored.routeId, 7);
    });

    test('a corrupt stored record decodes to something drawable', () {
      // Written by an older build, or truncated. It must not take the whole
      // inbox down with it.
      final m = PushMessage.fromJson(const {'title': 42, 'at': 'not-a-date'});
      expect(m.title, '42');
      expect(m.body, isEmpty);
      expect(m.read, isFalse);
      expect(m.receivedAt, isA<DateTime>());
    });
  });
}
