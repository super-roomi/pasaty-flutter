import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockup/services/api_config.dart';

/// Regression tests for store-submission blockers.
///
/// Each of these pins a defect that was found in a compliance audit and that
/// would otherwise silently come back — a debug default that ships, a
/// placeholder identifier, a missing Apple-required file. They read the real
/// project files rather than mirroring their contents.
void main() {
  group('P0-1 backend URL', () {
    test('production URL is HTTPS and never loopback', () {
      final url = ApiConfig.productionUrl;

      // Empty is the "not configured yet" state: baseUrl throws in release,
      // which is safe. Anything non-empty must be a real HTTPS host.
      if (url.isEmpty) {
        markTestSkipped(
          'ApiConfig._production is not set yet — release builds will throw. '
          'Set it to the production https:// host before submitting.',
        );
        return;
      }

      expect(url, startsWith('https://'));
      for (final loopback in const ['127.0.0.1', '10.0.2.2', 'localhost']) {
        expect(url, isNot(contains(loopback)));
      }
    });
  });

  group('P0-2 application identifiers', () {
    test('no com.example identifiers remain in build config', () {
      final files = [
        File('android/app/build.gradle.kts'),
        File('ios/Runner.xcodeproj/project.pbxproj'),
      ];

      for (final file in files) {
        expect(file.existsSync(), isTrue, reason: '${file.path} is missing');
        expect(
          file.readAsStringSync(),
          isNot(contains('com.example')),
          reason:
              '${file.path} still uses a placeholder application ID; '
              'Play rejects com.example.* at upload and the ID is permanent '
              'after the first upload.',
        );
      }
    });
  });

  group('P0-5 iOS privacy manifest', () {
    final manifest = File('ios/Runner/PrivacyInfo.xcprivacy');

    test('exists', () {
      expect(
        manifest.existsSync(),
        isTrue,
        reason: 'Missing PrivacyInfo.xcprivacy — uploads fail with ITMS-91053.',
      );
    });

    test('declares the NSUserDefaults required-reason API', () {
      final xml = manifest.readAsStringSync();
      expect(xml, contains('NSPrivacyAccessedAPICategoryUserDefaults'));
      expect(xml, contains('CA92.1'));
    });

    test('is wired into the Runner Copy Bundle Resources phase', () {
      // Easy to forget in Xcode, and it fails silently: the file sits in the
      // repo but never makes it into the built app.
      final pbxproj = File(
        'ios/Runner.xcodeproj/project.pbxproj',
      ).readAsStringSync();
      expect(pbxproj, contains('PrivacyInfo.xcprivacy in Resources'));
    });
  });

  group('P0-6 export compliance', () {
    test('ITSAppUsesNonExemptEncryption is declared', () {
      final plist = File('ios/Runner/Info.plist').readAsStringSync();
      expect(
        plist,
        contains('ITSAppUsesNonExemptEncryption'),
        reason:
            'Without this key every upload stops to ask the export '
            'compliance question interactively.',
      );
    });
  });

  group('transport security', () {
    test('Android forbids cleartext outside loopback', () {
      final config = File(
        'android/app/src/main/res/xml/network_security_config.xml',
      ).readAsStringSync();
      expect(
        config,
        contains('<base-config cleartextTrafficPermitted="false"'),
      );
    });

    test('no ATS escape hatch in Info.plist', () {
      final plist = File('ios/Runner/Info.plist').readAsStringSync();
      expect(plist, isNot(contains('NSAllowsArbitraryLoads')));
    });
  });
}
