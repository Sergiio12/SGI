import 'package:flutter/material.dart';

import '../config/theme.dart';
import 'navigation.dart';
import 'result.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget? fallback;
  final void Function(AppException error)? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallback,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  @override
  void initState() {
    super.initState();
    ErrorWidget.builder = (details) => const SizedBox.shrink();
    FlutterError.onError = (details) {
      widget.onError?.call(
        AppException(
          message: details.exceptionAsString(),
          code: 'FLUTTER_ERROR',
          stackTrace: details.stack,
        ),
      );
      if (mounted) _showErrorDialog(details.exceptionAsString());
    };
  }

  void _showErrorDialog(String message) {
    final navigatorContext = appNavigatorKey.currentState?.context;
    if (navigatorContext == null || !mounted) {
      return;
    }

    showDialog(
      context: navigatorContext,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: BrainTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: BrainTheme.accentRed.withValues(alpha: 0.3),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: BrainTheme.accentRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 28,
                color: BrainTheme.accentRed,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Algo salió mal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: BrainTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: BrainTheme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Reintentar'),
            style: FilledButton.styleFrom(
              backgroundColor: BrainTheme.accentPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
