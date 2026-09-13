import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/driver_location_reporter.dart';
import '../../services/socket_service.dart';

/// On-screen readout of the location pipeline, for builds made with
/// `--dart-define=DIAG=true`.
///
/// This exists because on-device logging has repeatedly been unreachable —
/// the VM service refuses to attach, mDNS is blocked by Personal Hotspot, and
/// `log stream --device` is gone on current macOS. Rather than keep fighting
/// the cable, the app reports its own state and the driver reads it off the
/// screen.
///
/// [kLocationDiagnostics] is a `const bool.fromEnvironment`, so in a normal
/// release build the whole widget is dead code and the tree-shaker removes it.
/// It can never appear in a store build.
const bool kLocationDiagnostics = bool.fromEnvironment('DIAG');

class DvLocationDiagnostics extends StatefulWidget {
  const DvLocationDiagnostics({super.key});

  @override
  State<DvLocationDiagnostics> createState() => _DvLocationDiagnosticsState();
}

class _DvLocationDiagnosticsState extends State<DvLocationDiagnostics> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // The counters change on their own schedule, but "seconds since last fix"
    // has to advance even when nothing arrives — which is precisely the
    // failure being diagnosed.
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  static String _ago(DateTime? t) {
    if (t == null) return 'never';
    return '${DateTime.now().difference(t).inSeconds}s ago';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ReporterDiagnostics>(
      valueListenable: DriverLocationReporter.instance.diagnostics,
      builder: (context, d, _) {
        final rows = <(String, String, bool)>[
          ('subscribed', d.subscribed ? 'yes' : 'NO', d.subscribed),
          (
            'services',
            d.serviceEnabled == null
                ? '?'
                : (d.serviceEnabled! ? 'on' : 'OFF'),
            d.serviceEnabled ?? false,
          ),
          ('permission', d.permission ?? '?', d.permission != null),
          (
            'socket',
            SocketService.instance.connected.value ? 'up' : 'DOWN',
            SocketService.instance.connected.value,
          ),
          (
            'socket error',
            SocketService.instance.lastError.value ?? '-',
            SocketService.instance.lastError.value == null,
          ),
          ('fixes', '${d.fixes}', d.fixes > 0),
          ('last fix', _ago(d.lastFixAt), d.lastFixAt != null),
          (
            'accuracy',
            d.lastAccuracy == null
                ? '-'
                : '${d.lastAccuracy!.toStringAsFixed(0)}m',
            true,
          ),
          ('dropped/throttled', '${d.dropped}/${d.throttled}', true),
          ('sent', '${d.sent}', d.sent > 0),
          ('acked', '${d.acked}', d.acked > 0),
          ('last sent', _ago(d.lastSentAt), d.lastSentAt != null),
        ];

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF11161F),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2C3646)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'LOCATION DIAGNOSTICS',
                style: TextStyle(
                  color: Color(0xFF7FE0A8),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              for (final (label, value, ok) in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 132,
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Color(0xFF8A94A6),
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      Text(
                        value,
                        style: TextStyle(
                          color: ok
                              ? const Color(0xFFDCE3EC)
                              : const Color(0xFFFF6B6B),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              if (d.lastError != null) ...[
                const SizedBox(height: 6),
                Text(
                  'error: ${d.lastError}',
                  style: const TextStyle(
                    color: Color(0xFFFF6B6B),
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
