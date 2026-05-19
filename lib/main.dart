import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_bootstrap.dart';
import 'core/result.dart';
import 'services/notification_service.dart';
import 'utils/notification_service_v2.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.init();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  final app = await AppBootstrap.build();

  runZonedGuarded(
    () => runApp(app),
    (Object error, StackTrace stack) {
      final exception = AppException(
        message: error.toString(),
        code: 'UNHANDLED',
        stackTrace: stack,
      );
      exception.log();
      showErrorNotification('Error inesperado: ${error.runtimeType}');
    },
  );
}
