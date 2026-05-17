import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'utils/notification_service_v2.dart';

class SecondBrainApp extends StatelessWidget {
  const SecondBrainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SGI',
      debugShowCheckedModeBanner: false,
      theme: BrainTheme.darkTheme,
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
