import 'dart:async';
import 'package:flutter/services.dart';
import '../providers/settings_provider.dart';

SettingsProvider? _hapticSettings;

void setHapticSettings(SettingsProvider settings) {
  _hapticSettings = settings;
}

class HapticHelper {
  static void light() {
    if (!(_hapticSettings?.hapticFeedback ?? true)) return;
    _safeHaptic(HapticFeedback.lightImpact);
  }

  static void medium() {
    if (!(_hapticSettings?.hapticFeedback ?? true)) return;
    _safeHaptic(HapticFeedback.mediumImpact);
  }

  static void heavy() {
    if (!(_hapticSettings?.hapticFeedback ?? true)) return;
    _safeHaptic(HapticFeedback.heavyImpact);
  }

  static void selection() {
    if (!(_hapticSettings?.hapticFeedback ?? true)) return;
    _safeHaptic(HapticFeedback.selectionClick);
  }

  static void _safeHaptic(Future<void> Function() fn) {
    try {
      unawaited(fn().catchError((_) {}));
    } catch (_) {}
  }
}
