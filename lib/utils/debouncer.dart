import 'dart:async';
import 'package:flutter/foundation.dart';

class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 300)});

  void call(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void flush() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
