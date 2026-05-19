import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:ui';

import 'package:provider/provider.dart';
import '../config/theme.dart';

enum NotificationType { success, error, info, warning }

class InAppNotification {
  final String message;
  final NotificationType type;
  final Duration duration;

  InAppNotification({
    required this.message,
    required this.type,
    this.duration = const Duration(seconds: 3),
  });

  Color get backgroundColor {
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
        return Icons.error_rounded;
      case NotificationType.info:
        return Icons.info_rounded;
      case NotificationType.warning:
        return Icons.warning_rounded;
    }
  }
}

class NotificationController extends ChangeNotifier {
  InAppNotification? _currentNotification;
  Timer? _timer;

  InAppNotification? get currentNotification => _currentNotification;

  void show(InAppNotification notification) {
    _timer?.cancel();

    _currentNotification = notification;
    notifyListeners();

    _timer = Timer(notification.duration, () {
      _currentNotification = null;
      notifyListeners();
    });
  }

  void showSuccess(String message) {
    show(
      InAppNotification(
        message: message,
        type: NotificationType.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void showError(String message) {
    show(
      InAppNotification(
        message: message,
        type: NotificationType.error,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void showInfo(String message) {
    show(
      InAppNotification(
        message: message,
        type: NotificationType.info,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void showWarning(String message) {
    show(
      InAppNotification(
        message: message,
        type: NotificationType.warning,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void dismiss() {
    _timer?.cancel();
    _currentNotification = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// Global reference para acceso desde providers
NotificationController? _globalNotificationController;

void setGlobalNotificationController(NotificationController controller) {
  _globalNotificationController = controller;
}

NotificationController? getGlobalNotificationController() {
  return _globalNotificationController;
}

// Helper methods que pueden ser llamadas desde cualquier lugar
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

class NotificationWrapper extends StatelessWidget {
  final Widget child;

  const NotificationWrapper({
    required this.child,
    super.key,
  });

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
                final notification = controller.currentNotification;
                if (notification == null) {
                  return const SizedBox.shrink();
                }
                return NotificationWidget(
                  key: ValueKey(notification.hashCode),
                  notification: notification,
                  onDismiss: () => controller.dismiss(),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class NotificationWidget extends StatefulWidget {
  final InAppNotification notification;
  final VoidCallback onDismiss;

  const NotificationWidget({
    required this.notification,
    required this.onDismiss,
    super.key,
  });

  @override
  State<NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<NotificationWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _progressController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: widget.notification.duration,
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _animationController.forward();
    _progressController.forward();
  }

  @override
  void didUpdateWidget(NotificationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.notification != oldWidget.notification) {
      _animationController.reset();
      _progressController.reset();
      _progressController.duration = widget.notification.duration;
      _animationController.forward();
      _progressController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    final screenWidth = mediaQuery?.size.width ?? 400;
    final isSmallScreen = screenWidth < 400;
    final notificationColor = widget.notification.backgroundColor;

    final surfaceColor = Theme.of(context).colorScheme.surface;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 20,
        vertical: 12,
      ),
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: GestureDetector(
              onTap: widget.onDismiss,
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: notificationColor.withValues(alpha: 0.15),
                      blurRadius: 30,
                      spreadRadius: -5,
                    ),
                  ],
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: surfaceColor.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: notificationColor.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            notificationColor.withValues(alpha: 0.15),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 14 : 18,
                              vertical: isSmallScreen ? 12 : 16,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: notificationColor.withValues(
                                        alpha: 0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: notificationColor.withValues(
                                          alpha: 0.4),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    widget.notification.icon,
                                    color: notificationColor,
                                    size: isSmallScreen ? 18 : 22,
                                  ),
                                ),
                                SizedBox(width: isSmallScreen ? 12 : 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _getTypeLabel(widget.notification.type),
                                        style: TextStyle(
                                          color: notificationColor,
                                          fontWeight: FontWeight.w800,
                                          fontSize: isSmallScreen ? 11 : 12,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        widget.notification.message,
                                        style: TextStyle(
                                          color: onSurfaceColor,
                                          fontWeight: FontWeight.w500,
                                          fontSize: isSmallScreen ? 14 : 15,
                                          letterSpacing: -0.2,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: isSmallScreen ? 8 : 12),
                                GestureDetector(
                                  onTap: widget.onDismiss,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.05),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close_rounded,
                                      color: BrainTheme.textTertiary,
                                      size: isSmallScreen ? 16 : 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Barra de progreso
                          AnimatedBuilder(
                            animation: _progressController,
                            builder: (context, child) {
                              return Container(
                                height: 3,
                                width: double.infinity,
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: 1.0 - _progressController.value,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: notificationColor,
                                      borderRadius:
                                          const BorderRadius.horizontal(
                                        right: Radius.circular(2),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: notificationColor.withValues(
                                              alpha: 0.5),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getTypeLabel(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return 'EXITO';
      case NotificationType.error:
        return 'ERROR';
      case NotificationType.info:
        return 'INFORMACIÓN';
      case NotificationType.warning:
        return 'ADVERTENCIA';
    }
  }
}
