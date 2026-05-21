import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';

void showUndoSnackBar(
  BuildContext context, {
  required String message,
  required VoidCallback onUndo,
}) {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(Icons.check_circle, color: BrainTheme.accentGreen, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF2D2D30),
      duration: const Duration(seconds: 4),
      action: SnackBarAction(
        label: l10n.undo,
        textColor: BrainTheme.accentPurple,
        onPressed: onUndo,
      ),
    ),
  );
}
