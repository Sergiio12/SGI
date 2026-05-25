import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/sync_provider.dart';
import '../providers/tasks_provider.dart';
import '../providers/projects_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/goals_provider.dart';
import '../utils/notification_service_v2.dart';
import '../utils/haptic_helper.dart';
import '../widgets/navigation_sidebar.dart';
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
                  colors: [BrainTheme.accentOf(context), BrainTheme.accentBlue],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child:
                  const Icon(Icons.psychology, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context).appTitle,
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
                color: BrainTheme.accentOf(context),
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

  late final List<({String title, IconData icon, Widget screen})> Function(
    BuildContext,
  ) _tabsBuilder = (context) => [
        (
          title: AppLocalizations.of(context).navDashboard,
          icon: Icons.dashboard_outlined,
          screen: const DashboardScreen()
        ),
        (
          title: AppLocalizations.of(context).navTasks,
          icon: Icons.checklist_rounded,
          screen: const TasksScreen()
        ),
        (
          title: AppLocalizations.of(context).navProjects,
          icon: Icons.folder_open_outlined,
          screen: const ProjectsScreen()
        ),
        (
          title: AppLocalizations.of(context).navGoals,
          icon: Icons.track_changes_outlined,
          screen: const GoalsScreen()
        ),
        (
          title: AppLocalizations.of(context).navNotes,
          icon: Icons.sticky_note_2_outlined,
          screen: const NotesScreen()
        ),
      ];

  void _onTabChanged(int index) {
    HapticHelper.selection();
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
                color: BrainTheme.accentOf(context).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.flash_on,
                size: 22,
                color: BrainTheme.accentOf(context),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              AppLocalizations.of(context).quickCapture,
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
                color: BrainTheme.accentOf(context),
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
              AppLocalizations.of(context).cancel,
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
              backgroundColor: BrainTheme.accentOf(context),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              AppLocalizations.of(context).save,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showSyncStatus(BuildContext context, SyncProvider sync) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: BrainTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: sync.status == SyncStatus.synced
                          ? BrainTheme.accentGreen.withValues(alpha: 0.1)
                          : sync.status == SyncStatus.error
                              ? BrainTheme.accentRed.withValues(alpha: 0.1)
                              : BrainTheme.accentOf(context).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      sync.status == SyncStatus.synced
                          ? Icons.cloud_done
                          : sync.status == SyncStatus.error
                              ? Icons.cloud_off
                              : Icons.cloud_sync,
                      color: sync.status == SyncStatus.synced
                          ? BrainTheme.accentGreen
                          : sync.status == SyncStatus.error
                              ? BrainTheme.accentRed
                              : BrainTheme.accentOf(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Estado de sincronización',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: BrainTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _syncInfoRow('Estado', sync.statusLabel),
              if (sync.lastSync != null)
                _syncInfoRow(
                  'Última sincronización',
                  _formatTimeAgo(sync.lastSync!),
                ),
              if (sync.hasConflicts) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: BrainTheme.accentRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: BrainTheme.accentRed.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: BrainTheme.accentRed, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${sync.conflicts.length} conflicto(s) detectado(s)',
                          style: TextStyle(
                            color: BrainTheme.accentRed,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: sync.status == SyncStatus.syncing
                      ? null
                      : () {
                          sync.triggerSync();
                          Navigator.pop(ctx);
                        },
                  icon: sync.status == SyncStatus.syncing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.sync, size: 18),
                  label: Text('Sincronizar ahora'),
                  style: FilledButton.styleFrom(
                    backgroundColor: BrainTheme.accentOf(context),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    return 'Hace ${diff.inDays}d';
  }

  Widget _syncInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: BrainTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: BrainTheme.textPrimary,
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
    final tasksLoaded = context.select<TasksProvider, bool>((p) => p.isLoaded);
    final projectsLoaded =
        context.select<ProjectsProvider, bool>((p) => p.isLoaded);
    final notesLoaded = context.select<NotesProvider, bool>((p) => p.isLoaded);
    final goalsLoaded = context.select<GoalsProvider, bool>((p) => p.isLoaded);

    if (!tasksLoaded || !projectsLoaded || !notesLoaded || !goalsLoaded) {
      return const _LoadingScreen();
    }

    final tabs = _tabsBuilder(context);
    final currentTab = tabs[_currentIndex];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;

        if (isWide) {
          // ── WIDE: Sidebar + Body (no bottom nav, no hamburger) ──
          return CallbackShortcuts(
            bindings: _shortcuts(context),
            child: Focus(
              autofocus: true,
              child: Scaffold(
                backgroundColor: BrainTheme.primaryDark,
                body: Row(
                  children: [
                    NavigationSidebar(
                      currentIndex: _currentIndex,
                      onItemSelected: _onTabChanged,
                    ),
                    Expanded(
                      child: Scaffold(
                        backgroundColor: BrainTheme.primaryDark,
                        appBar:
                            _buildAppBar(context, currentTab, hasSidebar: true),
                        body: _buildBody(context, tabs),
                        floatingActionButton: QuickCaptureFAB(
                          onCapture: _handleQuickCapture,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // ── NARROW: Drawer + Bottom Nav ──
        return CallbackShortcuts(
          bindings: _shortcuts(context),
          child: Focus(
            autofocus: true,
            child: Scaffold(
              key: _scaffoldKey,
              appBar: _buildAppBar(context, currentTab, hasSidebar: false),
              drawer: Drawer(
                backgroundColor: BrainTheme.surfaceDark,
                child: SafeArea(
                  bottom: true,
                  child: NavigationSidebar(
                    currentIndex: _currentIndex,
                    onItemSelected: (index) {
                      _onTabChanged(index);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
              body: _buildBody(context, tabs),
              floatingActionButton: QuickCaptureFAB(
                onCapture: _handleQuickCapture,
              ),
              bottomNavigationBar: _buildBottomNav(tabs),
            ),
          ),
        );
      },
    );
  }

  Map<ShortcutActivator, VoidCallback> _shortcuts(BuildContext context) {
    return {
      const SingleActivator(LogicalKeyboardKey.keyN): () =>
          _showQuickTaskDialog(),
      const SingleActivator(LogicalKeyboardKey.keyP): () =>
          Navigator.pushNamed(context, '/project'),
      const SingleActivator(LogicalKeyboardKey.keyG): () =>
          Navigator.pushNamed(context, '/goal'),
      const SingleActivator(LogicalKeyboardKey.keyM): () =>
          Navigator.pushNamed(context, '/note'),
      const SingleActivator(LogicalKeyboardKey.slash): () =>
          Navigator.pushNamed(context, '/search'),
      const SingleActivator(LogicalKeyboardKey.digit1): () => _onTabChanged(0),
      const SingleActivator(LogicalKeyboardKey.digit2): () => _onTabChanged(1),
      const SingleActivator(LogicalKeyboardKey.digit3): () => _onTabChanged(2),
      const SingleActivator(LogicalKeyboardKey.digit4): () => _onTabChanged(3),
      const SingleActivator(LogicalKeyboardKey.digit5): () => _onTabChanged(4),
    };
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ({String title, IconData icon, Widget screen}) currentTab, {
    required bool hasSidebar,
  }) {
    return AppBar(
      elevation: 0,
      backgroundColor: BrainTheme.primaryDark.withValues(alpha: 0.8),
      leading: hasSidebar
          ? null
          : IconButton(
              icon: Icon(Icons.menu_rounded, color: BrainTheme.textPrimary),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
      title: Row(
        children: [
          Hero(
            tag: 'app_logo',
            flightShuttleBuilder: (
              flightContext,
              animation,
              flightDirection,
              fromHeroContext,
              toHeroContext,
            ) {
              return Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      BrainTheme.accentOf(context),
                      BrainTheme.accentOf(context).withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(currentTab.icon, size: 18, color: Colors.white),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    BrainTheme.accentOf(context),
                    BrainTheme.accentOf(context).withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(currentTab.icon, size: 18, color: Colors.white),
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
        Consumer<SyncProvider>(
          builder: (context, sync, _) {
            Color syncColor;
            IconData syncIcon;
            switch (sync.status) {
              case SyncStatus.disconnected:
                syncColor = BrainTheme.textTertiary;
                syncIcon = Icons.cloud_off_outlined;
                break;
              case SyncStatus.syncing:
                syncColor = BrainTheme.accentOrange;
                syncIcon = Icons.sync;
                break;
              case SyncStatus.synced:
                syncColor = BrainTheme.accentGreen;
                syncIcon = Icons.cloud_done_outlined;
                break;
              case SyncStatus.error:
                syncColor = BrainTheme.accentRed;
                syncIcon = Icons.cloud_off;
                break;
            }
            return Container(
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: syncColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: syncColor.withValues(alpha: 0.2),
                ),
              ),
              child: IconButton(
                icon: sync.status == SyncStatus.syncing
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: syncColor,
                        ),
                      )
                    : Icon(syncIcon, size: 18, color: syncColor),
                onPressed: () => _showSyncStatus(context, sync),
                tooltip: sync.statusLabel,
              ),
            );
          },
        ),
        Container(
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: BrainTheme.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: BrainTheme.borderDark),
          ),
          child: IconButton(
            icon: const Icon(Icons.search_rounded, size: 20),
            onPressed: () => Navigator.pushNamed(context, '/search'),
            tooltip: AppLocalizations.of(context).search,
          ),
        ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<({String title, IconData icon, Widget screen})> tabs,
  ) {
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
        child: tabs[_currentIndex].screen,
      ),
    );
  }

  Widget _buildBottomNav(
    List<({String title, IconData icon, Widget screen})> tabs,
  ) {
    return SafeArea(
      top: false,
      child: Container(
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
          selectedItemColor: BrainTheme.accentOf(context),
          unselectedItemColor: BrainTheme.textTertiary,
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          items: tabs
              .map(
                (tab) => BottomNavigationBarItem(
                  icon: Icon(tab.icon, size: 22),
                  activeIcon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          BrainTheme.accentOf(context).withValues(alpha: 0.2),
                          BrainTheme.accentOf(context).withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(tab.icon,
                        size: 22, color: BrainTheme.accentOf(context)),
                  ),
                  label: tab.title,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
