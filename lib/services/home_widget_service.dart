import 'package:home_widget/home_widget.dart';

class HomeWidgetService {
  static const _widgetName = 'SGITodayWidget';

  static bool _available = true;

  static bool get isAvailable => _available;

  static Future<void> init() async {
    try {
      await HomeWidget.registerInteractivityCallback(handleWidgetTap);
    } catch (_) {
      _available = false;
    }
  }

  static Future<void> updateTodayWidget({
    required int totalTasks,
    required int completedTasks,
    required int overdueTasks,
  }) async {
    if (!_available) return;
    try {
      await HomeWidget.saveWidgetData('totalTasks', totalTasks);
      await HomeWidget.saveWidgetData('completedTasks', completedTasks);
      await HomeWidget.saveWidgetData('overdueTasks', overdueTasks);
      await HomeWidget.updateWidget(
        androidName: _widgetName,
        iOSName: _widgetName,
      );
    } catch (_) {
      _available = false;
    }
  }

  static Future<void> handleWidgetTap(Uri? uri) async {
    if (uri != null) {
      try {
        await HomeWidget.saveWidgetData('action', uri);
        await HomeWidget.updateWidget(
          androidName: _widgetName,
          iOSName: _widgetName,
        );
      } catch (_) {}
    }
  }
}
