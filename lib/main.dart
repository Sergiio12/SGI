import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

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

  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://examplePublicKey@o0.ingest.sentry.io/0';
      options.tracesSampleRate = 0.1;
      options.enableAppLifecycleBreadcrumbs = true;
    },
    appRunner: _runApp,
  );
}

Future<void> _runApp() async {
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
      Sentry.captureException(error, stackTrace: stack);
      showErrorNotification('Error inesperado: ${error.runtimeType}');
    },
  );
}
