import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';

// ─── Enums & Data Model ──────────────────────────────────────────────────────

enum NotificationType { success, error, info, warning }

class InAppNotification {
  final String message;
  final NotificationType type;
  final Duration duration;
  final String? title;
  final VoidCallback? onAction;
  final String? actionLabel;

  const InAppNotification({
    required this.message,
    required this.type,
    this.duration = const Duration(seconds: 4),
    this.title,
    this.onAction,
    this.actionLabel,
  });

  Color get accentColor {
    switch (type) {
      case NotificationType.success:
        return BrainTheme.accentGreen;
      case NotificationType.error:
        return BrainTheme.accentRed;
      case NotificationType.info:
        return BrainTheme.accentBlue;
      case NotificationType.warning:
        return BrainTheme.accentOrange;
    }
  }

  IconData get icon {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle_rounded;
      case NotificationType.error:
        return Icons.cancel_rounded;
      case NotificationType.info:
        return Icons.info_rounded;
      case NotificationType.warning:
        return Icons.warning_amber_rounded;
    }
  }

  String get defaultTitle {
    switch (type) {
      case NotificationType.success:
        return 'Éxito';
      case NotificationType.error:
        return 'Error';
      case NotificationType.info:
        return 'Información';
      case NotificationType.warning:
        return 'Advertencia';
    }
  }
}

// ─── Internal model ──────────────────────────────────────────────────────────

class _ActiveNotification {
  final InAppNotification notification;
  final String id;
  Timer? timer;

  _ActiveNotification({required this.notification})
    : id = '${DateTime.now().microsecondsSinceEpoch}_${notification.hashCode}';
}

// ─── Controller ──────────────────────────────────────────────────────────────

class NotificationController extends ChangeNotifier {
  final List<_ActiveNotification> _stack = [];
  static const int _maxStack = 2;

  List<_ActiveNotification> get activeNotifications =>
      List.unmodifiable(_stack);

  void show(InAppNotification notification) {
    if (_stack.length >= _maxStack) {
      _stack.last.timer?.cancel();
      _stack.removeLast();
    }

    final entry = _ActiveNotification(notification: notification);
    entry.timer = Timer(notification.duration, () => _autoDismiss(entry.id));
    _stack.insert(0, entry);
    notifyListeners();
    HapticFeedback.lightImpact();
  }

  void showSuccess(String message, {String? title}) {
    show(InAppNotification(
      message: message,
      title: title,
      type: NotificationType.success,
    ));
  }

  void showError(String message, {String? title}) {
    show(InAppNotification(
      message: message,
      title: title,
      type: NotificationType.error,
      duration: const Duration(seconds: 5),
    ));
  }

  void showInfo(String message, {String? title}) {
    show(InAppNotification(
      message: message,
      title: title,
      type: NotificationType.info,
    ));
  }

  void showWarning(String message, {String? title}) {
    show(InAppNotification(
      message: message,
      title: title,
      type: NotificationType.warning,
      duration: const Duration(seconds: 5),
    ));
  }

  void dismiss(String id) {
    _stack.removeWhere((e) {
      if (e.id == id) {
        e.timer?.cancel();
        return true;
      }
      return false;
    });
    notifyListeners();
  }

  void _autoDismiss(String id) {
    if (_stack.any((e) => e.id == id)) {
      dismiss(id);
    }
  }

  void dismissAll() {
    for (final e in _stack) {
      e.timer?.cancel();
    }
    _stack.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    dismissAll();
    super.dispose();
  }
}

// ─── Global Helpers ──────────────────────────────────────────────────────────

NotificationController? _globalNotificationController;

void setGlobalNotificationController(NotificationController controller) {
  _globalNotificationController = controller;
}

NotificationController? getGlobalNotificationController() {
  return _globalNotificationController;
}

void showSuccessNotification(String message) {
  _globalNotificationController?.showSuccess(message);
}

void showErrorNotification(String message) {
  _globalNotificationController?.showError(message);
}

void showInfoNotification(String message) {
  _globalNotificationController?.showInfo(message);
}

void showWarningNotification(String message) {
  _globalNotificationController?.showWarning(message);
}

// ─── Wrapper Widget ──────────────────────────────────────────────────────────

class NotificationWrapper extends StatelessWidget {
  final Widget child;

  const NotificationWrapper({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Consumer<NotificationController>(
              builder: (context, controller, _) {
                final notifications = controller.activeNotifications;
                if (notifications.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < notifications.length; i++)
                      _NotificationCard(
                        key: ValueKey(notifications[i].id),
                        active: notifications[i],
                        stackIndex: i,
                        onDismiss: () => controller.dismiss(
                          notifications[i].id,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Notification Card ───────────────────────────────────────────────────────

class _NotificationCard extends StatefulWidget {
  final _ActiveNotification active;
  final int stackIndex;
  final VoidCallback onDismiss;

  const _NotificationCard({
    required this.active,
    required this.stackIndex,
    required this.onDismiss,
    super.key,
  });

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard>
    with TickerProviderStateMixin {
  late AnimationController _enterController;
  late AnimationController _progressController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: widget.active.notification.duration,
      vsync: this,
    );

    _slideAnimation = CurvedAnimation(
      parent: _enterController,
      curve: Curves.easeOutCubic,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _enterController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _enterController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    );

    _enterController.forward();
    _progressController.forward();
  }

  @override
  void didUpdateWidget(_NotificationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active.id != oldWidget.active.id) {
      _enterController.reset();
      _progressController.reset();
      _progressController.duration = widget.active.notification.duration;
      _enterController.forward();
      _progressController.forward();
    }
  }

  @override
  void dispose() {
    _enterController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _handleDismiss() {
    if (_dismissing) return;
    _dismissing = true;
    _progressController.stop();

    _enterController.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final notif = widget.active.notification;
    final accent = notif.accentColor;
    final isLight = Theme.of(context).brightness == Brightness.light;

    final cardColor = Theme.of(context).colorScheme.surface;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    final isTop = widget.stackIndex == 0;
    final topPadding = isTop ? 12.0 : 6.0;

    return AnimatedBuilder(
      animation: _enterController,
      builder: (context, child) {
        final slideOffset = (1.0 - _slideAnimation.value) * -80.0;
        return Opacity(
          opacity: _fadeAnimation.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, slideOffset),
            child: Transform.scale(
              scale: _scaleAnimation.value.clamp(0.85, 1.0),
              child: child,
            ),
          ),
        );
      },
      child: GestureDetector(
        onTap: _handleDismiss,
        child: Container(
          margin: EdgeInsets.fromLTRB(16, topPadding, 16, 0),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isLight
                  ? const Color(0xFFE4E4E7)
                  : const Color(0xFF27272A),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isLight
                    ? const Color(0x1A000000)
                    : const Color(0x4D000000),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: accent.withValues(alpha: isLight ? 0.12 : 0.2),
                blurRadius: 24,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(14),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 14, 4, 10),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(notif.icon, color: accent, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    notif.title ?? notif.defaultTitle,
                                    style: TextStyle(
                                      color: onSurfaceColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      height: 1.2,
                                      decoration: TextDecoration.none,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (notif.message.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      notif.message,
                                      style: TextStyle(
                                        color: onSurfaceVariant,
                                        fontWeight: FontWeight.w400,
                                        fontSize: 13,
                                        height: 1.3,
                                        decoration: TextDecoration.none,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: _handleDismiss,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isLight
                                      ? const Color(0x0A000000)
                                      : const Color(0x0AFFFFFF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildProgressBar(accent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(Color accent) {
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, child) {
        return Container(
          height: 2.5,
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: 1.0 - _progressController.value,
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      },
    );
  }
}
