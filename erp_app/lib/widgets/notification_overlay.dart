import 'dart:async';
import 'package:flutter/material.dart';

// ============================================================
// ⭐ LiveNotificationOverlay — Toast ที่มุมขวาบน
//
// การใช้งาน (ใน State ของหน้าที่ต้องการแสดง toast):
//   _notificationOverlay.show(context, notification);
//
// ใช้ static method เพื่อเรียกได้จากทุกที่:
//   LiveNotificationService.show(context, notification);
// ============================================================

enum NotificationType { newOrder, stockUpdated, warning, info }

class LiveNotification {
  final String title;
  final String message;
  final NotificationType type;
  final String? subMessage;
  final DateTime timestamp;

  LiveNotification({
    required this.title,
    required this.message,
    this.type = NotificationType.info,
    this.subMessage,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

// ============================================================
// Static service — เรียกใช้ได้จากทุกที่ใน app
// ============================================================
class LiveNotificationService {
  static OverlayEntry? _currentEntry;
  static final List<LiveNotification> _queue = [];
  static bool _isShowing = false;

  /// แสดง Toast notification
  static void show(BuildContext context, LiveNotification notification) {
    _queue.add(notification);
    if (!_isShowing) {
      _showNext(context);
    }
  }

  static void _showNext(BuildContext context) {
    if (_queue.isEmpty) {
      _isShowing = false;
      return;
    }
    _isShowing = true;
    final notification = _queue.removeAt(0);
    _currentEntry?.remove();

    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastWidget(
        notification: notification,
        onDismiss: () {
          entry.remove();
          // แสดง notification ถัดไปใน queue หลัง 300ms
          Timer(const Duration(milliseconds: 300), () {
            _showNext(context);
          });
        },
      ),
    );
    _currentEntry = entry;
    overlay.insert(entry);
  }
}

// ============================================================
// Internal Toast Widget
// ============================================================
class _ToastWidget extends StatefulWidget {
  final LiveNotification notification;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.notification,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.2, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    // Auto dismiss หลัง 5 วินาที
    _autoTimer = Timer(const Duration(seconds: 5), _dismiss);
  }

  void _dismiss() {
    if (!mounted) return;
    _autoTimer?.cancel();
    _controller.reverse().then((_) => widget.onDismiss());
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 24,
      right: 24,
      width: 360,
      child: Material(
        color: Colors.transparent,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: _buildCard(),
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    final colors = _getColors();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.accent.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: colors.accent.withValues(alpha: 0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Colored top strip
            Container(
              height: 4,
              color: colors.accent,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        colors.emoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // LIVE badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.accent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _PulsingDot(),
                                  SizedBox(width: 4),
                                  Text(
                                    'LIVE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.notification.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF0F172A),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          widget.notification.message,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF334155),
                            height: 1.4,
                          ),
                        ),
                        if (widget.notification.subMessage != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            widget.notification.subMessage!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        // Progress bar ที่หดลงตามเวลา
                        _ProgressBar(duration: const Duration(seconds: 5), color: colors.accent),
                      ],
                    ),
                  ),
                  // Close button
                  GestureDetector(
                    onTap: _dismiss,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _ToastColors _getColors() {
    switch (widget.notification.type) {
      case NotificationType.newOrder:
        return _ToastColors(
          accent: const Color(0xFF22C55E),
          emoji: '💰',
        );
      case NotificationType.stockUpdated:
        return _ToastColors(
          accent: const Color(0xFF3B82F6),
          emoji: '📦',
        );
      case NotificationType.warning:
        return _ToastColors(
          accent: const Color(0xFFF59E0B),
          emoji: '⚠️',
        );
      case NotificationType.info:
        return _ToastColors(
          accent: const Color(0xFF6366F1),
          emoji: 'ℹ️',
        );
    }
  }
}

class _ToastColors {
  final Color accent;
  final String emoji;
  _ToastColors({required this.accent, required this.emoji});
}

// ── Pulsing dot animation ──
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ── Progress bar ที่หดลงตามเวลา ──
class _ProgressBar extends StatefulWidget {
  final Duration duration;
  final Color color;

  const _ProgressBar({required this.duration, required this.color});

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => LinearProgressIndicator(
        value: 1 - _ctrl.value,
        backgroundColor: widget.color.withValues(alpha: 0.1),
        valueColor: AlwaysStoppedAnimation<Color>(
          widget.color.withValues(alpha: 0.5),
        ),
        minHeight: 3,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
