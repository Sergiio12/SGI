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
      : id =
            '${DateTime.now().microsecondsSinceEpoch}_${notification.hashCode}';
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

  void showSuccess(String message,
      {String? title, String? actionLabel, VoidCallback? onAction}) {
    show(InAppNotification(
      message: message,
      title: title,
      type: NotificationType.success,
      actionLabel: actionLabel,
      onAction: onAction,
    ));
  }

  void showError(String message,
      {String? title, String? actionLabel, VoidCallback? onAction}) {
    show(InAppNotification(
      message: message,
      title: title,
      type: NotificationType.error,
      duration: const Duration(seconds: 5),
      actionLabel: actionLabel,
      onAction: onAction,
    ));
  }

  void showInfo(String message,
      {String? title, String? actionLabel, VoidCallback? onAction}) {
    show(InAppNotification(
      message: message,
      title: title,
      type: NotificationType.info,
      actionLabel: actionLabel,
      onAction: onAction,
    ));
  }

  void showWarning(String message,
      {String? title, String? actionLabel, VoidCallback? onAction}) {
    show(InAppNotification(
      message: message,
      title: title,
      type: NotificationType.warning,
      duration: const Duration(seconds: 5),
      actionLabel: actionLabel,
      onAction: onAction,
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

void showSuccessNotification(String message,
    {String? title, String? actionLabel, VoidCallback? onAction}) {
  _globalNotificationController?.showSuccess(
    message,
    title: title,
    actionLabel: actionLabel,
    onAction: onAction,
  );
}

void showErrorNotification(String message,
    {String? title, String? actionLabel, VoidCallback? onAction}) {
  _globalNotificationController?.showError(
    message,
    title: title,
    actionLabel: actionLabel,
    onAction: onAction,
  );
}

void showInfoNotification(String message,
    {String? title, String? actionLabel, VoidCallback? onAction}) {
  _globalNotificationController?.showInfo(
    message,
    title: title,
    actionLabel: actionLabel,
    onAction: onAction,
  );
}

void showWarningNotification(String message,
    {String? title, String? actionLabel, VoidCallback? onAction}) {
  _globalNotificationController?.showWarning(
    message,
    title: title,
    actionLabel: actionLabel,
    onAction: onAction,
  );
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
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
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

    final cardColor = const Color(0xFF1E1E1E);
    final onSurfaceColor = const Color(0xFFF5F5F5);
    final onSurfaceVariant = const Color(0xFFB8B8B8);

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
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0x33FFFFFF),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0x40000000),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            notif.title ?? notif.defaultTitle,
                            style: TextStyle(
                              color: onSurfaceColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              decoration: TextDecoration.none,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (notif.message.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              notif.message,
                              style: TextStyle(
                                color: onSurfaceVariant,
                                fontWeight: FontWeight.w400,
                                fontSize: 13,
                                height: 1.35,
                                decoration: TextDecoration.none,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (notif.actionLabel != null &&
                        notif.onAction != null) ...[
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: notif.onAction,
                        style: TextButton.styleFrom(
                          foregroundColor: BrainTheme.accentOf(context),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          backgroundColor:
                              BrainTheme.accentOf(context).withValues(alpha: 0.08),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          minimumSize: const Size(0, 0),
                        ),
                        child: Text(
                          notif.actionLabel!,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _handleDismiss,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0x14FFFFFF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
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
