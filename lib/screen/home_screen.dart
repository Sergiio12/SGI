import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/tasks_provider.dart';
import '../providers/projects_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/goals_provider.dart';
import '../utils/notification_service_v2.dart';
import '../widgets/brain_drawer.dart';
import '../widgets/quick_capture_fab.dart';
import 'dashboard/dashboard_screen.dart';
import 'tasks/tasks_screen.dart';
import 'projects/projects_screen.dart';
import 'goals/goals_screen.dart';
import 'notes/notes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrainTheme.primaryDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [BrainTheme.accentPurple, BrainTheme.accentBlue],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.psychology, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 24),
            Text(
              'SGI',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: BrainTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: BrainTheme.accentPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<({String title, IconData icon, Widget screen})> _tabs = const [
    (
      title: 'Dashboard',
      icon: Icons.dashboard_outlined,
      screen: DashboardScreen()
    ),
    (title: 'Tareas', icon: Icons.checklist_rounded, screen: TasksScreen()),
    (
      title: 'Proyectos',
      icon: Icons.folder_open_outlined,
      screen: ProjectsScreen()
    ),
    (
      title: 'Objetivos',
      icon: Icons.track_changes_outlined,
      screen: GoalsScreen()
    ),
    (title: 'Notas', icon: Icons.sticky_note_2_outlined, screen: NotesScreen()),
  ];

  void _onTabChanged(int index) {
    setState(() => _currentIndex = index);
  }

  void _handleQuickCapture(String type) {
    switch (type) {
      case 'task':
        _showQuickTaskDialog();
        break;
      case 'project':
        Navigator.pushNamed(context, '/project');
        break;
      case 'goal':
        Navigator.pushNamed(context, '/goal');
        break;
      case 'note':
        Navigator.pushNamed(context, '/note');
        break;
    }
  }

  void _showQuickTaskDialog() {
    final controller = TextEditingController();
    final notificationController = context.read<NotificationController>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: BrainTheme.cardDark,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: BrainTheme.accentPurple.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.flash_on,
                size: 22,
                color: BrainTheme.accentPurple,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Captura rápida',
              style: TextStyle(
                color: BrainTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: BrainTheme.textPrimary),
          decoration: InputDecoration(
            hintText: '¿Qué tienes en mente?',
            hintStyle: TextStyle(color: BrainTheme.textTertiary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: BrainTheme.borderDark),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: BrainTheme.borderDark),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: BrainTheme.accentPurple,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: BrainTheme.surfaceDark,
          ),
          onSubmitted: (value) {
            _submitTask(
                value, dialogContext, controller, notificationController);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: BrainTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              _submitTask(controller.text, dialogContext, controller,
                  notificationController);
            },
            style: FilledButton.styleFrom(
              backgroundColor: BrainTheme.accentPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Capturar',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitTask(
    String text,
    BuildContext dialogContext,
    TextEditingController controller,
    NotificationController notificationController,
  ) async {
    if (text.trim().isEmpty) {
      notificationController.showWarning('Por favor, escribe una tarea');
      return;
    }

    try {
      await context.read<TasksProvider>().addTask(title: text.trim());
      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
      }
    } catch (e) {
      notificationController.showError('Error: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksLoaded = context.watch<TasksProvider>().isLoaded;
    final projectsLoaded = context.watch<ProjectsProvider>().isLoaded;
    final notesLoaded = context.watch<NotesProvider>().isLoaded;
    final goalsLoaded = context.watch<GoalsProvider>().isLoaded;

    if (!tasksLoaded || !projectsLoaded || !notesLoaded || !goalsLoaded) {
      return const _LoadingScreen();
    }

    final currentTab = _tabs[_currentIndex];

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: BrainTheme.primaryDark.withValues(alpha: 0.95),
        leading: IconButton(
          icon: Icon(Icons.menu_rounded, color: BrainTheme.textPrimary),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: BrainTheme.accentPurple.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                currentTab.icon,
                size: 20,
                color: BrainTheme.accentPurple,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              currentTab.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: BrainTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => Navigator.pushNamed(context, '/search'),
            tooltip: 'Buscar',
          ),
        ],
      ),
      drawer: const BrainDrawer(),
      body: _buildBody(),
      floatingActionButton: QuickCaptureFAB(onCapture: _handleQuickCapture),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(_currentIndex),
        child: _tabs[_currentIndex].screen,
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: BrainTheme.borderDark.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabChanged,
        type: BottomNavigationBarType.fixed,
        backgroundColor: BrainTheme.primaryDark,
        selectedItemColor: BrainTheme.accentPurple,
        unselectedItemColor: BrainTheme.textTertiary,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        items: _tabs
            .map(
              (tab) => BottomNavigationBarItem(
                icon: Icon(tab.icon),
                activeIcon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: BrainTheme.accentPurple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(tab.icon, size: 24),
                ),
                label: tab.title,
              ),
            )
            .toList(),
      ),
    );
  }
}
