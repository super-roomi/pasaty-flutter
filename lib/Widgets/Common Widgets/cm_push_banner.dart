import 'dart:async';

import 'package:flutter/material.dart';

import '../../Colors/app_colors.dart';
import '../../services/push_service.dart';

/// Draws foreground notifications.
///
/// FCM deliberately suppresses the system tray entry while the app is open,
/// so without this a parent watching the live screen sees nothing at all when
/// their child boards. Wraps the whole app rather than living on a page: a
/// notification can arrive on any screen.
class CmPushBannerHost extends StatefulWidget {
  final Widget child;
  final void Function(PushMessage message)? onTap;

  const CmPushBannerHost({super.key, required this.child, this.onTap});

  @override
  State<CmPushBannerHost> createState() => _CmPushBannerHostState();
}

class _CmPushBannerHostState extends State<CmPushBannerHost>
    with SingleTickerProviderStateMixin {
  static const _visibleFor = Duration(seconds: 5);

  StreamSubscription<PushMessage>? _sub;

  /// Built in initState rather than as a lazy `late final`: on a run where no
  /// notification ever arrives, nothing else touches the controller, so the
  /// `_slide.dispose()` below would be what first constructs it — creating a
  /// Ticker against an element that is already deactivated.
  late final AnimationController _slide;

  PushMessage? _current;
  Timer? _dismiss;

  @override
  void initState() {
    super.initState();
    _slide = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _sub = PushService.instance.foregroundMessages.listen(_show);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _dismiss?.cancel();
    _slide.dispose();
    super.dispose();
  }

  void _show(PushMessage message) {
    // An empty notification block would draw a blank card. The server always
    // sends one, but a data-only message must not produce a ghost banner.
    if (message.title.isEmpty && message.body.isEmpty) return;
    _dismiss?.cancel();
    setState(() => _current = message);
    _slide.forward(from: 0);
    _dismiss = Timer(_visibleFor, _hide);
  }

  Future<void> _hide() async {
    _dismiss?.cancel();
    if (!mounted || _current == null) return;
    await _slide.reverse();
    if (mounted) setState(() => _current = null);
  }

  void _handleTap() {
    final message = _current;
    if (message == null) return;
    message.read = true;
    _hide();
    widget.onTap?.call(message);
  }

  @override
  Widget build(BuildContext context) {
    final message = _current;

    return Stack(
      children: [
        widget.child,
        if (message != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -1),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: _slide, curve: Curves.easeOutCubic),
              ),
              child: _Banner(
                message: message,
                onTap: _handleTap,
                onDismiss: _hide,
              ),
            ),
          ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  final PushMessage message;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _Banner({
    required this.message,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context).top;

    return Material(
      color: Colors.transparent,
      child: Padding(
        // Clears the status bar and the notch; a banner under either is
        // unreadable on exactly the phones most likely to be in use.
        padding: EdgeInsets.fromLTRB(12, padding + 8, 12, 0),
        child: Dismissible(
          key: ValueKey(message.receivedAt),
          direction: DismissDirection.up,
          onDismissed: (_) => onDismiss(),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              decoration: BoxDecoration(
                color: AppColors.deepNavy,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.directions_bus_filled,
                    color: AppColors.safetyYellow,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.title.isNotEmpty)
                          Text(
                            message.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        if (message.body.isNotEmpty)
                          Text(
                            message.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
