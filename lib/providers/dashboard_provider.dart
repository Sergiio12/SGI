import 'dart:async';
import 'package:flutter/material.dart';

import '../core/result.dart';
import '../services/smart_alerts_service.dart';
import 'projects_provider.dart';
import 'tasks_provider.dart';

class DashboardProvider extends ChangeNotifier {
  TasksProvider _tasksProvider;
  ProjectsProvider _projectsProvider;
  
  List<SmartAlert> _alerts = [];
  bool _isLoadingAlerts = false;
  
  DashboardProvider({
    required TasksProvider tasksProvider,
    required ProjectsProvider projectsProvider,
  }) : _tasksProvider = tasksProvider,
       _projectsProvider = projectsProvider {
    tasksProvider.addListener(_onDataChanged);
    projectsProvider.addListener(_onDataChanged);
    _onDataChanged(); // Initial calculation
  }
  
  TasksProvider get tasksProvider => _tasksProvider;
  ProjectsProvider get projectsProvider => _projectsProvider;
  
  void updateProviders({
    required TasksProvider tasksProvider,
    required ProjectsProvider projectsProvider,
  }) {
    _tasksProvider.removeListener(_onDataChanged);
    _projectsProvider.removeListener(_onDataChanged);
    _tasksProvider = tasksProvider;
    _projectsProvider = projectsProvider;
    tasksProvider.addListener(_onDataChanged);
    projectsProvider.addListener(_onDataChanged);
    _onDataChanged();
  }
  
  List<SmartAlert> get alerts => _alerts;
  bool get isLoadingAlerts => _isLoadingAlerts;
  
  Timer? _debounceTimer;
  
  void _onDataChanged() {
    // Debounce to avoid multiple calculations during rapid updates
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), _calculateAlerts);
  }
  
  Future<void> _calculateAlerts() async {
    if (_isLoadingAlerts) return;
    
    _isLoadingAlerts = true;
    
    try {
      final newAlerts = await SmartAlertsService.buildAlerts(
        tasks: _tasksProvider.tasks,
        projects: _projectsProvider.projects,
      );
      
      _alerts = newAlerts;
    } catch (e, s) {
      AppException(
        message: 'Error al calcular alertas del dashboard',
        code: 'DASHBOARD_ALERTS',
        stackTrace: s,
      ).log();
    } finally {
      _isLoadingAlerts = false;
      notifyListeners();
    }
  }
  
  @override
  void dispose() {
    _tasksProvider.removeListener(_onDataChanged);
    _projectsProvider.removeListener(_onDataChanged);
    _debounceTimer?.cancel();
    super.dispose();
  }
}
