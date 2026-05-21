import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_bootstrap.dart';
import 'core/result.dart';
import 'l10n/app_localizations.dart';
import 'screen/onboarding/onboarding_screen.dart';
import 'services/home_widget_service.dart';
import 'services/notification_service.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await NotificationService.init();
      await HomeWidgetService.init();

      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ));

      final needsOnboarding = await OnboardingScreen.isNeeded();

      if (needsOnboarding) {
        runApp(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: OnboardingScreen(
              onComplete: () {
                AppBootstrap.build().then((app) => runApp(app));
              },
            ),
          ),
        );
      } else {
        final app = await AppBootstrap.build();
        runApp(app);
      }
    },
    (error, stack) {
      AppException(
        message: error.toString(),
        code: 'UNHANDLED',
        stackTrace: stack,
      ).log();
    },
  );
}
