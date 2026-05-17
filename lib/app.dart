import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'providers/settings_provider.dart';
import 'utils/notification_service_v2.dart';

class SecondBrainApp extends StatelessWidget {
  const SecondBrainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final brightness = settings.themeMode == ThemeMode.light
        ? Brightness.light
        : settings.themeMode == ThemeMode.system
            ? WidgetsBinding.instance.platformDispatcher.platformBrightness
            : Brightness.dark;
    BrainTheme.updateBrightness(brightness);

    return MaterialApp(
      key: ValueKey(settings.themeMode),
      title: 'SGI',
      debugShowCheckedModeBanner: false,
      theme: BrainTheme.lightTheme,
      darkTheme: BrainTheme.darkTheme,
      themeMode: settings.themeMode,
      initialRoute: AppRoutes.loading,
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      builder: (context, child) {
        return NotificationWrapper(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
