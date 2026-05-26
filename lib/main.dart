import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_bootstrap.dart';
import 'config/theme.dart';
import 'core/result.dart';
import 'l10n/app_localizations.dart';
import 'screen/onboarding/onboarding_screen.dart';
import 'services/home_widget_service.dart';
import 'services/notification_service.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      await NotificationService.init();
      await HomeWidgetService.init();

      final needsOnboarding = await OnboardingScreen.isNeeded();

      if (needsOnboarding) {
        SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ));

        runApp(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: BrainTheme.lightTheme,
            darkTheme: BrainTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: OnboardingScreen(
              onComplete: () async {
                final app = await AppBootstrap.build();
                final brightness = WidgetsBinding
                    .instance.platformDispatcher.platformBrightness;
                SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: brightness == Brightness.light
                      ? Brightness.dark
                      : Brightness.light,
                ));
                runApp(app);
              },
            ),
          ),
        );
      } else {
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                      Brightness.light
                  ? Brightness.dark
                  : Brightness.light,
        ));

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
      if (FlutterError.onError != null) {
        FlutterError.onError!(FlutterErrorDetails(
          exception: error,
          stack: stack,
        ));
      }
    },
  );
}
