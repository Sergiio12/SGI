# SGI · Sistema de Gestión Integral

> **Tu segundo cerebro digital.** Una aplicación Flutter que unifica tareas, proyectos, metas y notas en un solo ecosistema offline-first. Diseñada para profesionales que buscan claridad mental, ejecución metódica y trazabilidad total de su trabajo.

<p align="center">
  <img src="assets/app_icon.png" width="96" height="96" alt="SGI Logo">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.41+-02569B?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.11+-0175C2?logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="License">
  <img src="https://img.shields.io/badge/status-production-brightgreen" alt="Status">
</p>

---

## Table of Contents

- [Philosophy](#-philosophy)
- [Features at a Glance](#-features-at-a-glance)
- [Screenshots](#-screenshots)
- [Architecture](#-architecture)
- [Data Models](#-data-models)
- [State Management](#-state-management)
- [Services Layer](#-services-layer)
- [Persistence & Backup](#-persistence--backup)
- [Notifications System](#-notifications-system)
- [Theming System](#-theming-system)
- [Internationalization](#-internationalization)
- [UI Component Library](#-ui-component-library)
- [Screens Walkthrough](#-screens-walkthrough)
- [Project Structure](#-project-structure)
- [Tech Stack](#-tech-stack)
- [Getting Started](#-getting-started)
- [Development](#-development)
- [Testing](#-testing)
- [Roadmap](#-roadmap)
- [License](#-license)

---

## Philosophy

SGI nace de la necesidad de unificar tres metodologías de productividad en una sola herramienta offline-first:

| Metodología | Aplicación en SGI |
|---|---|
| **GTD** (Getting Things Done) | Captura rápida vía FAB, bandejas por estado, revisión semanal implícita en dashboard |
| **PARA** (Projects, Areas, Resources, Archives) | Proyectos anidados con notas vinculadas, objetivos como áreas, papelera como archivo |
| **Pomodoro** | Temporizador integrado en vista Foco para bloques de trabajo profundo |

Cada decisión de diseño prioriza: **privacidad de datos** (todo en local), **velocidad** (sin latencia de red), **claridad visual** (interfaz limpia con jerarquía tipográfica).

---

## Features at a Glance

```text
OPERACIONES BÁSICAS
─────────────────────────────────────────────────────────────
☑ CRUD completo: Tareas · Proyectos · Notas · Metas · Tags
☑ Subtareas anidadas con progreso visual
☑ Prioridades y estados personalizables
☑ Asignación proyecto ↔ tarea · meta ↔ proyecto

VISTAS INTELIGENTES
─────────────────────────────────────────────────────────────
☑ Dashboard con smart alerts
☑ Vista Hoy (vencidas · hoy · en progreso)
☑ Modo Foco (tareas críticas próximos 7 días)
☑ Kanban board por estado
☑ Calendario (próximos 30 días)
☑ Progreso y estadísticas

PRODUCTIVIDAD AVANZADA
─────────────────────────────────────────────────────────────
☑ Pomodoro timer (25/5/15 min con ciclos)
☑ Operaciones batch (selección múltiple → completar/eliminar)
☑ Búsqueda global instantánea con debounce
☑ Captura rápida desde cualquier pantalla
☑ Modo selección con long-press

ALMACENAMIENTO Y SEGURIDAD
─────────────────────────────────────────────────────────────
☑ Persistencia local Hive + SharedPreferences
☑ Android Auto Backup (Google Drive)
☑ Export/import JSON completo
☑ Papelera por tipo con restauración
☑ Copia de seguridad automática persistente
☑ Migración automática de esquemas

PERSONALIZACIÓN
─────────────────────────────────────────────────────────────
☑ Tema oscuro/claro/sistema
☑ 7 colores de acento
☑ Sidebar colapsable con secciones
☑ Settings con búsqueda y categorías
☑ 5 idiomas vía l10n (ARB)

NOTIFICACIONES
─────────────────────────────────────────────────────────────
☑ Recordatorios programados (24h / 1h / personalizado)
☑ Horario silencioso configurable
☑ Notificaciones al completar / vencer
☑ Reschedule automático al iniciar app
☑ Home widget con resumen de tareas
```

---

## Screenshots

> *(Insert screenshots here — one per major screen)*

| Dashboard | Tasks | Projects |
|---|---|---|
| | | |
| **Notes** | **Focus** | **Today** |
| | | |
| **Calendar** | **Progress** | **Settings** |
| | | |

---

## Architecture

### Pattern

```
┌──────────────────────┐
│     UI Layer         │  Screens + Widgets (StatelessWidget/StatefulWidget)
│   (presentation)     │
├──────────────────────┤
│    State Layer       │  Providers (ChangeNotifier via Provider pkg)
│   (state management) │
├──────────────────────┤
│   Service Layer      │  StorageService · BackupService · NotificationService
│    (business logic)  │  SmartAlertsService · AIService · SyncService
├──────────────────────┤
│   Data Layer         │  Hive (NoSQL) · SharedPreferences · File I/O
│   (persistence)      │
└──────────────────────┘
```

SGI sigue una **Clean Architecture simplificada** con tres principios fundamentales:

1. **Unidirectional data flow**: UI → Provider → Service → Storage
2. **Provider as Mediator**: Los providers orquestan servicios y exponen estado reactivo a la UI
3. **Debounced persistence**: Cada escritura se debouncea 500ms para evitar thrashing en mutaciones frecuentes

### Navigation Flow

```
App Launch
  │
  ├── OnboardingScreen (si primera vez)
  │     └── Guarda nombre + tema + acento → SharedPreferences
  │
  └── LoadingScreen
        ├── init Hive + SharedPreferences
        ├── tryRestore (PersistentBackupService → busca backup JSON)
        ├── load Tasks (storage → TasksProvider)
        ├── load Projects (storage → ProjectsProvider)
        ├── load Notes · Goals · Trash · DailyPlanner (background)
        └── navigate → HomeScreen

HomeScreen
  └── Scaffold
        ├── NavigationSidebar (drawer, 220px, secciones colapsables)
        ├── AppBar (contextual)
        └── Body (varía según ruta activa)

BottomNavigation (5 tabs): Dashboard · Tasks · Projects · Goals · Notes
Sidebar views:     Today · Focus · Calendar · Progress · Trash · Settings
```

### Data Flow Example

```
User taps "Complete Task"
  │
  ▼
TasksScreen.onToggleComplete(taskId)
  │
  ▼
TasksProvider.toggleComplete(id)
  ├── _tasks.firstWhere(...).copyWith(status: completed)
  ├── _markDirty() (invalida computed lists)
  ├── notifyListeners() (UI se re-renderiza)
  └── _saveDebouncer.call(() => _storage.saveTasks(_tasks))
        │
        ▼
  HiveStorageService.saveTasks() → _store.put('brain_tasks', jsonEncode)
        │
        ▼
  Hive box 'second_brain_store' (disco local)
```

---

## Data Models

### Entity Relationship Diagram

```
Task ────► Project         (task.projectId → project.id)
Task ────► Tag              (task.tags → tag.name)
Task ────► RecurrenceRule   (task.recurrenceRule → recurrencia opcional)
Task ────► [Subtask]        (task.subtasks → lista embebida)

Project ──► Goal            (project.goalId → goal.id)
Project ──► [Task]          (via task.projectId)
Project ──► [Note]          (via note.projectId)

Note ─────► Project         (note.projectId → project.id opcional)
Note ─────► Notebook        (note.notebook → notebook name)
Note ─────► [Tag]           (note.tags → tag.name)

Goal ─────► [Project]       (via project.goalId)
```

### Model Specifications

| Model | File | Fields | Serialization |
|---|---|---|---|
| **Task** | `task.dart` | id, title, description, status, priority, dueDate, estimatedHours, actualHours, projectId, tags, subtasks, recurrenceRule, isPinned, isOverdue, calendarEventId, createdAt, updatedAt | `toJson()` / `Task.fromJson()` |
| **Project** | `project.dart` | id, title, description, objective, emoji, color, status, priority, startDate, deadline, goalId, createdAt, updatedAt | `toJson()` / `Project.fromJson()` |
| **Note** | `note.dart` | id, title, content, type, notebook, emoji, projectId, tags, isPinned, attachments, createdAt, updatedAt | `toJson()` / `Note.fromJson()` |
| **Goal** | `goal.dart` | id, title, description, horizon, metricLabel, currentValue, targetValue, tags, createdAt, updatedAt | `toJson()` / `Goal.fromJson()` |
| **Tag** | `tag.dart` | name, color | `toJson()` / `Tag.fromJson()` |
| **Subtask** | `task.dart` (inline) | id, title, isCompleted | `toJson()` / `Subtask.fromJson()` |
| **RecurrenceRule** | `recurrence_rule.dart` | frequency, interval, endDate | `toJson()` / `RecurrenceRule.fromJson()` |
| **NotebookInfo** | `notebook_info.dart` | name, colorHex | `toJson()` / `NotebookInfo.fromJson()` |
| **BrainItem** | `brain_item.dart` | **Base class**: id, tags, createdAt, updatedAt (extended by Task, Project, Note, Goal) | abstract |

**Enums:** `TaskStatus` (pending, inProgress, inReview, completed, cancelled), `TaskPriority` (low, medium, high, urgent), `ProjectStatus` (active, paused, completed, abandoned), `GoalHorizon` (monthly, quarterly, yearly)

---

## State Management

### Provider Tree

```dart
MultiProvider(
  // ── Core ──────────────────────────────────
  Provider<IStorageService>(HiveStorageService()),  // Inyectado
  ChangeNotifierProvider<SettingsProvider>(),
  ChangeNotifierProvider<NotificationController>(),

  // ── Data providers ─────────────────────────
  ChangeNotifierProvider<TasksProvider>(),
  ChangeNotifierProvider<ProjectsProvider>(),
  ChangeNotifierProvider<NotesProvider>(),
  ChangeNotifierProvider<GoalsProvider>(),
  ChangeNotifierProvider<TagsProvider>(),

  // ── Feature providers ──────────────────────
  ChangeNotifierProvider<TrashProvider>(),
  ChangeNotifierProvider<SearchProvider>(),
  ChangeNotifierProvider<DashboardProvider>(),
  ChangeNotifierProvider<DailyPlannerProvider>(),
  ChangeNotifierProvider<SyncProvider>(),
  ChangeNotifierProvider<AIProvider>(),
)
```

### Provider Details

| Provider | File | State | Key Methods | Computed Lists |
|---|---|---|---|---|
| **SettingsProvider** | `settings_provider.dart` | themeMode, accentColor, notification prefs, language | `setTheme()`, `setAccentColor()`, `resetToDefaults()` | — |
| **TasksProvider** | `tasks_provider.dart` | `_tasks: List<Task>`, `_isLoaded: bool` | `loadTasks()`, `addTask()`, `updateTask()`, `deleteTask()`, `toggleComplete()`, `togglePin()`, `batchDelete()`, `batchComplete()`, `batchMoveToStatus()` | `todoTasks`, `inProgressTasks`, `doneTasks`, `overdueTasks`, `urgentTasks`, `todayTasks`, `focusTasks`, `cancelledTasks` |
| **ProjectsProvider** | `projects_provider.dart` | `_projects: List<Project>`, `_isLoaded: bool` | `loadProjects()`, `addProject()`, `updateProject()`, `deleteProject()` | `activeProjects`, `pausedProjects`, `completedProjects`, `abandonedProjects` |
| **NotesProvider** | `notes_provider.dart` | `_notes: List<Note>`, `_isLoaded: bool`, `_displayCount` (paginación) | `loadNotes()`, `addNote()`, `updateNote()`, `deleteNote()`, `togglePin()`, `loadMore()`, `resetPagination()` | `pinnedNotes`, `unpinnedNotes`, `recentNotes`, filtered by notebook/type/query |
| **GoalsProvider** | `goals_provider.dart` | `_goals: List<Goal>`, `_isLoaded: bool` | `loadGoals()`, `addGoal()`, `updateGoal()`, `deleteGoal()` | `monthlyGoals`, `quarterlyGoals`, `yearlyGoals` |
| **TrashProvider** | `trash_provider.dart` | tasks, projects, notes, goals, each with trash list | `loadTrash()`, `restoreTask()`, `restoreAll()`, `permanentDelete()` | — |
| **SearchProvider** | `search_provider.dart` | `_query`, `_results` | `search()`, `clear()` | Debounced 300ms, agrega results por tipo |
| **DashboardProvider** | `dashboard_provider.dart` | Alertas combinadas de tareas + proyectos | — (proxy) | Smart alerts, total counts |

### Debouncing Strategy

Cada provider utiliza un `Debouncer` de 500ms para las escrituras a disco. Esto significa que 10 cambios rápidos en la UI (ej. arrastrar subtareas) solo generan 1 escritura real:

```dart
_notifyAndScheduleSave() {
  _markDirty();          // Invalida computed lists
  notifyListeners();     // Re-renderiza UI inmediatamente
  _saveDebouncer.call(() => _storage.saveTasks(_tasks));  // Persiste después de 500ms
}
```

---

## Services Layer

### Service Catalog

| Service | File | Role | Key Methods |
|---|---|---|---|
| **HiveStorageService** | `services/storage_service.dart` | Persistencia Hive, CRUD genérico, migración de esquemas | `init()`, `loadTasks()`, `saveTasks()`, `clearAll()`, migraciones V1→V2 |
| **IStorageService** | `services/interfaces/storage_service_interface.dart` | Interfaz abstracta del storage | (define contrato de 22 métodos) |
| **BackupService** | `services/backup_service.dart` | Export/import manual JSON | `buildPayload()`, `exportToJson()`, `pickAndReadImport()` |
| **PersistentBackupService** | `services/persistent_backup_service.dart` | Backup automático persistente + restore | `tryRestore()`, `saveSnapshot()` |
| **NotificationService** | `services/notification_service.dart` | Notificaciones locales programadas | `configure()`, `scheduleTask()`, `cancelTask()`, `rescheduleAll()` |
| **LocalAIService** | `services/local_ai_service.dart` | Asistente IA local (offline) | `suggestTasks()`, `classifyNote()` |
| **SmartAlertsService** | `services/smart_alerts_service.dart` | Generación de alertas inteligentes | `generateAlerts()` → retorna `List<SmartAlert>` |
| **SyncService / FirebaseSyncService** | `services/sync_service.dart`, `services/firebase_sync_service.dart` | Sincronización cloud (en desarrollo) | `sync()`, `push()`, `pull()` |
| **LocalFirstStorageService** | `services/local_first_storage_service.dart` | Wrapper local-first sobre storage | Prioriza escritura local, sync en background |
| **CalendarIntegrationService** | `services/calendar_integration_service.dart` | Integración con calendario del sistema | `createTaskEvent()`, `updateTaskEvent()`, `removeTaskEvent()` |
| **HomeWidgetService** | `services/home_widget_service.dart` | Widget de pantalla de inicio | `updateWidget()` |

### Storage Service Internals

```
Hive Box: 'second_brain_store' (Box<String>)
─────────────────────────────────────────────
Claves:
  brain_tasks           → JSON string → List<Task>
  brain_projects        → JSON string → List<Project>
  brain_notes           → JSON string → List<Note>
  brain_goals           → JSON string → List<Goal>
  brain_trash_tasks     → JSON string → List<Task> (en papelera)
  brain_trash_projects  → JSON string → List<Project> (en papelera)
  brain_trash_notes     → JSON string → List<Note> (en papelera)
  brain_trash_goals     → JSON string → List<Goal> (en papelera)
  brain_tags            → JSON string → List<Tag>
  brain_notebook_names  → JSON string → List<NotebookInfo>
  brain_daily_intentions → JSON string → Map<String, String>
  brain_daily_plans     → JSON string → Map<String, List<String>>
  brain_daily_time_blocks → JSON string → Map<String, String>
```

La serialización/deserialización JSON ocurre en un **Isolate separado** para no bloquear el hilo principal:

```dart
Future<void> _saveList(String key, List<Map<String, dynamic>> items) async {
  final encoded = await Isolate.run(() => jsonEncode(items));
  await _store.put(key, encoded);
}
```

---

## Persistence & Backup

SGI implementa una estrategia de persistencia en **3 capas** para garantizar que los datos sobrevivan incluso a la desinstalación de la app.

### Layer 1: Android Auto Backup (Cloud)

```
┌─────────────────────────────────────────────────────┐
│                  Google Drive                        │
│    (restaurado automáticamente al reinstalar)        │
└─────────────────┬───────────────────────────────────┘
                  │
        ┌─────────▼──────────┐
        │  Android System    │
        │  Backup Agent      │
        └─────────┬──────────┘
                  │
     ┌────────────▼────────────┐
     │  app_flutter/ (Hive)    │
     │  shared_prefs/          │
     │  (excluye cache, db)    │
     └─────────────────────────┘
```

- Configurado en `AndroidManifest.xml` con `android:allowBackup="true"`
- Reglas en `res/xml/backup_rules.xml`: incluye `app_flutter/` + `sharedpref/`, excluye `cache/`, `database/`
- Backup automático a Google Drive (aprox. cada 24h cuando el dispositivo está inactivo y cargando)
- Restauración automática al reinstalar la app (Android 6+)

### Layer 2: Persistent Local Snapshot (File I/O)

```
┌─────────────────────────────────────────────┐
│      getApplicationDocumentsDirectory()      │  ← Restaurado por Auto Backup
│  └── sgi_auto_backup.json                   │
├─────────────────────────────────────────────┤
│      getDownloadsDirectory() (best-effort)   │  ← Persiste tras desinstalación
│  └── sgi_auto_backup.json                   │
└─────────────────────────────────────────────┘
```

- **`PersistentBackupService.saveSnapshot()`** se ejecuta tras cada carga de datos
- Guarda un JSON completo (tasks, projects, notes, goals) en ambas ubicaciones
- **`PersistentBackupService.tryRestore()`** se ejecuta durante LoadingScreen si Hive está vacío
- Busca en: app documents (restaurado por Auto Backup) → Downloads (persiste tras desinstalación)

### Layer 3: Manual Export/Import (User-Initiated)

- Botón "Exportar" en Settings → genera `second_brain_backup_20260101_120000.json`
- Botón "Importar" → `file_picker` → lee JSON → reemplaza datos actuales (con confirmación)
- Usa **Isolate** para procesar JSON pesado sin bloquear la UI

### Data Protection Features

- **Automatic Schema Migration**: `_runSchemaMigrations()` migra datos entre versiones (actual: schema v2)
- **SharedPreferences Legacy Migration**: `_migrateSharedPreferences()` migra datos desde SharedPreferences heredados a Hive
- **Clear All**: `clearAll()` borra Hive + SharedPreferences + invalida cachés

---

## Notifications System

### Architecture

```dart
NotificationService (singleton lógico)
├── configure(prefs)        → Inicializa flutter_local_notifications plugin
├── scheduleTask(task)      → Programa hasta 3 notificaciones por tarea
│   ├── Recordatorio personalizado (defaultReminderMinutes antes)
│   ├── Recordatorio 24h antes (si activado)
│   └── Recordatorio 1h antes (si activado)
├── cancelTask(taskId)      → Cancela todas las notificaciones de una tarea
├── cancelAll()             → Cancela todas las notificaciones
└── rescheduleAll(tasks)    → Reprograma todas las tareas activas
```

### Notification Flow

```
Task created with dueDate
  │
  ▼
NotificationService.scheduleTask(task)
  ├── Calcula DateTime delivery = dueDate - defaultReminderMinutes
  ├── Si delivery > now → programa notificación
  ├── Si remind24h → programa notificación 24h antes
  └── Si remind1h → programa notificación 1h antes

Task completed / deleted
  │
  ▼
NotificationService.cancelTask(taskId)
  └── Cancela todas las notificaciones asociadas

App launched
  │
  ▼
NotificationService.rescheduleAll(tasks)
  └── Itera todas las tareas activas → scheduleTask() para cada una
```

### Configuration Options

| Setting | Type | Default | Storage |
|---|---|---|---|
| Master toggle | `bool` | true | SharedPreferences |
| Remind 24h | `bool` | true | SharedPreferences |
| Remind 1h | `bool` | true | SharedPreferences |
| Default reminder minutes | `int` (5-1440) | 30 | SharedPreferences |
| Quiet hours enabled | `bool` | false | SharedPreferences |
| Quiet start hour/min | `int`/`int` | 22:00 | SharedPreferences |
| Quiet end hour/min | `int`/`int` | 08:00 | SharedPreferences |
| Notify on complete | `bool` | false | SharedPreferences |
| Notify on overdue | `bool` | false | SharedPreferences |

### Android Permissions

- `POST_NOTIFICATIONS` (Android 13+)
- `SCHEDULE_EXACT_ALARM` (Android 12+)
- `USE_EXACT_ALARM` (Android 12+ calendar)
- `RECEIVE_BOOT_COMPLETED` (reprogramar tras reboot)
- `VIBRATE`

---

## Theming System

### Color Architecture

```dart
class BrainTheme {
  // Accent colors (7 variants)
  static const accentPurple   = Color(0xFFA855F7);  // default
  static const accentBlue     = Color(0xFF3B82F6);
  static const accentGreen    = Color(0xFF22C55E);
  static const accentAmber    = Color(0xFFF59E0B);
  static const accentRed      = Color(0xFFEF4444);
  static const accentPink     = Color(0xFFEC4899);
  static const accentCyan     = Color(0xFF06B6D4);

  // Light theme
  static ThemeData lightTheme(accent) → ...
  // Dark theme
  static ThemeData darkTheme(accent) → ...
}
```

### Theme Preview

| Mode | Background | Surface | Text Primary | Accent |
|---|---|---|---|---|
| **Dark** (default) | `#09090B` (near-black) | Card: `#18181B` | `#FAFAFA` | Purple `#A855F7` |
| **Light** | `#FAFAFA` (off-white) | Card: `#FFFFFF` | `#09090B` | Purple `#A855F7` |

### Accent Colors

```
████████████████████████████████████  Purple (default)
████████████████████████████████████  Blue
████████████████████████████████████  Green
████████████████████████████████████  Amber
████████████████████████████████████  Red
████████████████████████████████████  Pink
████████████████████████████████████  Cyan
```

The accent color is applied to: active tab indicator, FAB, progress bars, switches, sliders, selected chip, active filter, priority badge (urgent), plus all `Theme.of(context).colorScheme.primary` usages.

### Component-Specific Theming

- **Cards**: `BrainTheme.cardDark` / `BrainTheme.cardLight` — glass-morphism con borde sutil y sombra
- **Gradients**: Dashboard headers, project detail banners, goal cards
- **Status colors**: Task `pending` → accent, `inProgress` → blue, `inReview` → amber, `completed` → green, `cancelled` → gray
- **Priority indicators**: Urgent → red, High → amber, Medium → blue, Low → gray

---

## Internationalization

### Architecture

```
lib/l10n/
├── app_en.arb        (412 líneas, ~170+ claves)
└── app_es.arb        (412 líneas, ~170+ claves)
```

SGI usa **`flutter_localizations`** + **`intl`** con generación de código vía `flutter gen-l10n`:

```yaml
# l10n.yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
synthetic-package: false
```

### Usage Pattern

```dart
final l10n = AppLocalizations.of(context);

Text(l10n.taskCreated(title: 'Comprar leche'));
// → "Task created: Comprar leche" (en) / "Tarea creada: Comprar leche" (es)

// En widgets no BuildContext:
AppLocalizations.current.taskCreated('foo');
```

### Coverage Areas

| Area | Keys | Examples |
|---|---|---|
| Navigation | 10+ | `sidebarTasks`, `sidebarToday`, `sidebarFocus` |
| Tasks CRUD | 15+ | `taskCreated`, `taskDeleted`, `taskCompleted` |
| Projects CRUD | 10+ | `projectActive`, `projectPaused`, `projectProgress` |
| Notes CRUD | 10+ | `notePinned`, `noteUnpinned`, `noteTypeChecklist` |
| Goals CRUD | 8+ | `goalMonthly`, `goalQuarterly`, `goalTarget` |
| Loading | 9 | `loadingInitStorage`, `loadingRestore`, `loadingTasks` |
| Smart Alerts | 6+ | `alertOverdueTasks`, `alertUrgentTasks`, `alertInactiveProjects` |
| Settings | 12+ | `settingsAppearance`, `settingsNotifications`, `settingsCloudSync` |
| AI Assistant | 4+ | `aiSuggestTasks`, `aiClassifyNote` |
| Pomodoro | 6+ | `pomodoroStart`, `pomodoroBreak`, `pomodoroSession` |
| Onboarding | 8+ | `onboardingTitle1`–`onboardingTitle5`, `onboardingAccentColor` |
| General | 20+ | `search`, `cancel`, `save`, `delete`, `restore`, `emptyState` |

---

## UI Component Library

### Widget Catalog

| Widget | File | Lines | Description |
|---|---|---|---|
| **TaskCard** | `widgets/task_card.dart` | 341 | Priority strip, metadata, subtask progress, Hero animation, Slidable |
| **ProjectCard** | `widgets/project_card.dart` | 649 | Emoji avatar, status badge, progress bar, popup menu, status picker |
| **NoteCard** | `widgets/note_card.dart` | 499 | Emoji, notebook path, content preview, Dismissible, context menu, selection mode |
| **GoalCard** | `widgets/goal_card.dart` | 413 | Color avatar, horizon badge, metric display, Slidable, bottom sheet detail |
| **TaskBoardColumn** | `widgets/task_board_column.dart` | 239 | Kanban column, DragTarget, LongPressDraggable, WIP indicator |
| **NavigationSidebar** | `widgets/navigation_sidebar.dart` | 436 | Secciones colapsables, quick stats, progreso visual, active indicator, tooltips |
| **QuickCaptureFAB** | `widgets/quick_capture_fab.dart` | 190 | FAB expandible (Note/Task/Project/Goal), label tooltips |
| **EmptyState** | `widgets/empty_state.dart` | 103 | Emoji animado, título + subtítulo, acción opcional |
| **StatsCard** | `widgets/stats_card.dart` | 114 | Icono + valor grande + título + glow shadow |
| **TaskFilterBar** | `widgets/task_filter_bar.dart` | 112 | Search + clear + filter button |
| **PomodoroTimer** | `screen/focus/pomodoro_timer.dart` | — | Timer 25/5/15, estados idle/working/break/paused, progreso circular |
| **SmartAlertsSection** | `screen/dashboard/dashboard_alerts_widget.dart` | — | Alert cards con icono, mensaje, timestamp |
| **SkeletonCard** | `widgets/skeleton_card.dart` | 528 | Shimmer skeletons: task, project, goal, note, stats, list, grid |
| **LoadingAnimation** | `widgets/loading_animation.dart` | 185 | Orbiting dots + icono + glow |
| **PriorityIndicator** | `widgets/priority_indicator.dart` | 55 | Dot + label coloreados |
| **TagChip** | `widgets/tag_chip.dart` | 45 | Chip animado con selección |
| **NotebookPicker** | `widgets/notebook_picker.dart` | 318 | Bottom sheet con search + create |
| **TaskProjectSelector** | `widgets/task_project_selector.dart` | 236 | Project picker bottom sheet |
| **TaskTodaySummary** | `widgets/task_today_summary.dart` | 171 | Date summary + status chips |
| **PaginatedList** | `widgets/paginated_list.dart` | 64 | Infinite-scroll wrapper |
| **PaginationBar** | `widgets/pagination_bar.dart` | 113 | Navegación de páginas |

### Reusable Patterns

| Pattern | Location | Description |
|---|---|---|
| **Slidable delete** | TaskCard, ProjectCard, GoalCard | Deslizar izquierda → confirmar → eliminar con undo |
| **Dismissible delete** | NoteCard | Arrastrar → confirmar → eliminar |
| **Bottom sheet pickers** | NotebookPicker, TaskProjectSelector, TagPickerModal | Modal overlay con search |
| **Skeleton loading** | SkeletonCard (528 lines) | Shimmer para tarjetas, listas, grids |
| **Animated transitions** | LoadingScreen → HomeScreen | Fade + Scale, 600ms, Curves.easeOutCubic |
| **Glass-morphism** | Dashboard, Onboarding | BackdropFilter + blur |

---

## Screens Walkthrough

### LoadingScreen
- **File**: `screen/loading/loading_screen.dart` (522 lines)
- **States**: Animated progress 0→1, status text por paso, error handling
- **Sequence**: Init Hive → tryRestore → load Tasks → load Projects → Visual → Ready → (background) Notes + Goals + Trash + Notifications + DailyPlanner
- **UI**: 240x240 loading animation (orbiting dots), glow background orbs, gradient footer con progreso

### Dashboard (Home Tab)
- **File**: `screen/dashboard/dashboard_screen.dart`
- **Sections**: Header + date greeting, Smart Alerts, resumen stats (tasks/projects/notes/goals), acceso rápido
- **Smart Alerts**: Tareas vencidas, urgentes, proyectos sin actividad reciente — tarjetas con icono + acción

### TasksScreen
- **File**: `screen/tasks/tasks_screen.dart`
- **Views**: Kanban (4 columnas drag&drop) | Lista (filtrada por estado)
- **Batch mode**: Long-press activa selección → barra flotante con "Completar" + "Eliminar"
- **Filter**: Por estado + prioridad + proyecto + tag + búsqueda
- **Sort**: Prioridad, fecha, título, proyecto

### TaskDetailScreen
- **File**: `screen/tasks/task_detail_screen.dart`
- **Sections**: Header (status + priority badges), subtasks checklist, metadata (fechas, horas, tags, proyecto), notas vinculadas, timeline de actividad

### ProjectsScreen
- **File**: `screen/projects/projects_screen.dart` (691 lines)
- **Filters**: Por status (activo/pausado/completado/abandonado) + búsqueda + sort
- **StatsBar**: Total/active/paused/completed counts
- **Cards**: ProjectCard con emoji, progreso, task counts

### ProjectDetailScreen
- **File**: `screen/projects/project_detail_screen.dart` (2000 lines)
- **Tabs**: Info (stats + progress), Tasks (vinculadas), Notes (vinculadas)
- **Form**: Modo edición/detalle toggle, emoji picker, 8 color swatches

### NotesScreen
- **File**: `screen/notes/notes_screen.dart`
- **Filters**: Por libreta + tipo + búsqueda + tags
- **Pagination**: 50 items por carga, scroll infinito

### GoalsScreen
- **File**: `screen/goals/goals_screen.dart`
- **Sections**: Mensual / Trimestral / Anual con GoalCard
- **Progress**: Barra circular por meta

### TodayScreen
- **File**: `screen/today/today_screen.dart`
- **Sections**: Overdue (rojo) → Today (naranja) → In Progress (azul)
- **Empty state**: Animación celebración si no hay pendientes

### FocusScreen
- **File**: `screen/focus/focus_screen.dart`
- **Task list**: Urgentes + alta prioridad próximos 7 días + en progreso
- **Pomodoro**: Timer integrado con 4 estados (idle/working/break/paused), sesiones contadas, progreso circular

### CalendarScreen
- **File**: `screen/calendar/calendar_screen.dart`
- **Timeline**: Próximos 30 días, agrupados, con badges "Hoy"/"Mañana"
- **Color coding**: Naranja=Hoy, Azul=≤3 días, Púrpura=resto

### ProgressScreen
- **File**: `screen/progress/progress_screen.dart` (112 lines)
- **Stats grid**: 2×2 cards con métricas clave
- **Goals list**: GoalCard con progreso

### SearchScreen
- **File**: `screen/search/search_screen.dart`
- **Global search**: Tasks + Projects + Notes + Goals simultáneo
- **Debounce**: 300ms
- **Results**: Agrupados por categoría, navegación directa

### TrashScreen
- **File**: `screen/trash/trash_screen.dart`
- **Tabs**: Por tipo (Tasks/Projects/Notes/Goals)
- **Actions**: Restore individual, restore all, permanent delete

### SettingsScreen
- **File**: `screen/settings/settings_screen.dart` (441 lines)
- **Search**: Live filter over settings items
- **Sections**: Apariencia, Datos y Sync, Inteligencia, Sistema
- **Sub-screens**: Appearance, Notifications, Widgets, Debug

### DataScreen
- **File**: `screen/data/data_screen.dart`
- **Actions**: Export JSON, Import JSON (con confirmación), Clear all data (con confirmación)

### OnboardingScreen
- **File**: `screen/onboarding/onboarding_screen.dart` (729 lines)
- **Pages**: 5 slides animados con painter personalizado
- **Final page**: Name + accent color + theme → guarda en SharedPreferences
- **Background**: Partículas orbitantes animadas (`_OnboardingBgPainter`)

---

## Project Structure

```
lib/
├── main.dart                          # Entry point + MultiProvider
├── app.dart                           # MaterialApp.router + theme + l10n
├── app_bootstrap.dart                 # Onboarding check + app lifecycle
│
├── config/
│   ├── theme.dart                     # BrainTheme: dark/light + 7 accent colors
│   ├── routes.dart                    # Route definitions + navigation keys
│   └── navigation.dart                # AppNavigation: sidebar routes + helpers
│
├── core/
│   ├── result.dart                    # Result<T> monad (Success / Error)
│   └── error_boundary.dart            # Error boundary widget
│
├── models/
│   ├── brain_item.dart                # Base class (id, tags, timestamps)
│   ├── task.dart                      # Task + Subtask
│   ├── project.dart                   # Project
│   ├── note.dart                      # Note
│   ├── goal.dart                      # Goal
│   ├── tag.dart                       # Tag
│   ├── dashboard_data.dart            # DashboardSummary + SmartAlert
│   ├── recurrence_rule.dart           # RecurrenceRule
│   ├── notebook_info.dart             # NotebookInfo
│   └── time_block.dart                # TimeBlock
│
├── providers/
│   ├── tasks_provider.dart            # Task CRUD + computed lists + batch ops
│   ├── projects_provider.dart         # Project CRUD
│   ├── notes_provider.dart            # Note CRUD + pagination
│   ├── goals_provider.dart            # Goal CRUD
│   ├── tags_provider.dart             # Tag CRUD
│   ├── trash_provider.dart            # Trash management
│   ├── search_provider.dart           # Global search with debounce
│   ├── settings_provider.dart         # Theme, notifications, prefs
│   ├── dashboard_provider.dart        # Smart alerts + summaries
│   ├── daily_planner_provider.dart    # Daily intentions + plans
│   ├── sync_provider.dart             # Cloud sync state (future)
│   └── ai_provider.dart               # AI assistant state
│
├── services/
│   ├── interfaces/
│   │   └── storage_service_interface.dart   # IStorageService contract
│   ├── storage_service.dart                 # Hive implementation
│   ├── backup_service.dart                  # JSON export/import
│   ├── persistent_backup_service.dart       # Auto backup + restore
│   ├── notification_service.dart            # Local notifications
│   ├── smart_alerts_service.dart            # Alert generation
│   ├── local_ai_service.dart                # On-device AI
│   ├── sync_service.dart                    # Sync abstraction
│   ├── firebase_sync_service.dart           # Firebase sync impl
│   ├── local_first_storage_service.dart     # Local-first wrapper
│   ├── calendar_integration_service.dart    # System calendar
│   └── home_widget_service.dart             # Android home widget
│
├── screen/
│   ├── loading/loading_screen.dart          # Splash + init sequence
│   ├── onboarding/onboarding_screen.dart    # First-time setup
│   ├── home_screen.dart                     # Scaffold + sidebar + bottom nav
│   ├── dashboard/
│   │   ├── dashboard_screen.dart            # Main dashboard
│   │   └── dashboard_alerts_widget.dart     # Smart alerts UI
│   ├── tasks/
│   │   ├── tasks_screen.dart                # Kanban + List view
│   │   └── task_detail_screen.dart          # Task detail + edit
│   ├── projects/
│   │   ├── projects_screen.dart             # Project list
│   │   └── project_detail_screen.dart       # Project detail + tabs
│   ├── notes/
│   │   ├── notes_screen.dart                # Note list + filters
│   │   └── note_editor_screen.dart          # Markdown editor
│   ├── goals/
│   │   ├── goals_screen.dart                # Goals by horizon
│   │   └── goal_detail_screen.dart          # Goal detail + edit
│   ├── today/today_screen.dart              # Consolidated today view
│   ├── focus/
│   │   ├── focus_screen.dart                # Focus tasks
│   │   └── pomodoro_timer.dart              # Pomodoro widget
│   ├── calendar/calendar_screen.dart        # 30-day timeline
│   ├── progress/progress_screen.dart        # Stats dashboard
│   ├── search/search_screen.dart            # Global search
│   ├── trash/trash_screen.dart              # Trash by type
│   ├── data/data_screen.dart                # Export/Import/Clear
│   └── settings/
│       ├── settings_screen.dart             # Main settings
│       ├── appearance_screen.dart           # Theme + accent
│       ├── notifications_screen.dart        # Notification prefs
│       ├── widgets_screen.dart              # Home widget config
│       └── debug_screen.dart                # Debug tools
│
├── widgets/
│   ├── task_card.dart                      # Task card (Slidable)
│   ├── project_card.dart                   # Project card
│   ├── note_card.dart                      # Note card (Dismissible)
│   ├── goal_card.dart                      # Goal card
│   ├── navigation_sidebar.dart             # Collapsible sidebar
│   ├── quick_capture_fab.dart              # Expandable FAB
│   ├── empty_state.dart                    # Animated empty state
│   ├── stats_card.dart                     # Stats grid card
│   ├── task_filter_bar.dart                # Search + filter
│   ├── task_board_column.dart              # Kanban column
│   ├── task_today_summary.dart             # Date summary chips
│   ├── task_project_selector.dart          # Project picker
│   ├── priority_indicator.dart             # Priority dot + label
│   ├── tag_chip.dart                       # Tag chip
│   ├── tag_color_picker.dart               # 24-color grid
│   ├── notebook_picker.dart                # Notebook selector
│   ├── paginated_list.dart                 # Infinite scroll
│   ├── pagination_bar.dart                 # Page nav
│   ├── skeleton_card.dart                  # Shimmer skeletons
│   ├── loading_animation.dart              # Loading spinner
│   ├── loading_glow_orb.dart               # Glow background
│   ├── loading_progress_footer.dart        # Loading footer
│   └── note_editor/
│       └── modals/
│           ├── emoji_picker_modal.dart      # Emoji grid
│           ├── tag_picker_modal.dart        # Tag multi-select
│           └── tag_manager_modal.dart       # Tag CRUD
│
├── utils/
│   ├── debouncer.dart                      # Debounce utility
│   ├── haptic_helper.dart                  # Haptic feedback
│   ├── accessibility_helper.dart           # Accessibility labels
│   ├── notification_service_v2.dart        # In-app toast overlay
│   └── responsive_helper.dart              # Responsive breakpoints
│
└── l10n/
    ├── app_en.arb                          # English strings
    ├── app_es.arb                          # Spanish strings
    └── app_localizations.dart              # Generated code
```

---

## Tech Stack

### Core

| Technology | Version | Purpose |
|---|---|---|
| **Flutter** | `>=3.41.0` | Cross-platform UI framework |
| **Dart** | `>=3.11.0` | Programming language |
| **Provider** | `^6.1.1` | State management via `ChangeNotifier` |
| **Hive Flutter** | `^1.1.0` | Local NoSQL database (key-value, encrypted) |
| **SharedPreferences** | `^2.2.2` | Simple key-value storage for preferences |

### UI & Animations

| Package | Version | Purpose |
|---|---|---|
| **Google Fonts** | `^6.1.0` | Inter font family |
| **flutter_animate** | `^4.5.2` | Declarative animations (loading, transitions, cards) |
| **flutter_slidable** | `^4.0.3` | Swipe-to-delete on cards |

### Notifications & Calendar

| Package | Version | Purpose |
|---|---|---|
| **flutter_local_notifications** | `^21.0.0` | Local scheduled notifications |
| **timezone** | `^0.11.0` | IANA timezone database for notification scheduling |

### Data & Serialization

| Package | Version | Purpose |
|---|---|---|
| **intl** | `^0.19.0` | Date formatting, i18n |
| **uuid** | `^4.2.1` | UUID v4 generation for entity IDs |
| **path_provider** | `^2.1.5` | Filesystem paths (documents, downloads, temp) |
| **file_picker** | `^11.0.2` | Native file picker for import |
| **home_widget** | `^0.9.1` | Android home screen widget |

### Utilities

| Package | Version | Purpose |
|---|---|---|
| **collection** | `^1.18.0` | Enhanced list operations |
| **firebase_core** | `^3.12.1` | Firebase (future: cloud sync) |
| **firebase_auth** | `^5.5.1` | Firebase auth (future) |
| **cloud_firestore** | `^5.6.5` | Firestore (future) |
| **flutter_localizations** | SDK | Built-in localization support |

---

## Getting Started

### Prerequisites

```bash
# Flutter SDK 3.41+
flutter --version

# Dart SDK 3.11+
dart --version

# Android Studio / VS Code (optional)
```

### Installation

```bash
# Clone
git clone https://github.com/tu-usuario/sgi.git
cd sgi

# Install dependencies
flutter pub get

# Generate localization code
flutter gen-l10n

# Run in debug mode
flutter run

# Run on specific device
flutter run -d <device-id>
```

### Build

```bash
# Debug APK
flutter build apk --debug

# Release APK (split per ABI)
flutter build apk --split-per-abi --release

# App Bundle (Play Store)
flutter build appbundle --release

# iOS (macOS only)
flutter build ios --release
```

---

## Development

### Code Conventions

- **Imports**: dart: → package: → project: (separados por línea en blanco)
- **Naming**: `_private`, `camelCase` for vars/methods, `PascalCase` for classes
- **Models**: Implement `toJson()` / `factory fromJson()` para todos los modelos
- **Widgets**: Widget pages (screens) en `screen/`, widgets reutilizables en `widgets/`
- **Providers**: Lógica de negocio en providers, no en widgets

### Adding a New Feature

1. **Model**: Añadir/actualizar modelo en `lib/models/` con `toJson()`/`fromJson()`
2. **Storage**: Añadir método en `IStorageService` + implementar en `HiveStorageService`
3. **Provider**: Crear `ChangeNotifierProvider` con métodos CRUD + computed lists
4. **Service**: Si hay lógica compleja, encapsular en servicio separado
5. **UI**: Widget en `screen/` o `widgets/`
6. **l10n**: Añadir claves a `app_en.arb` y `app_es.arb` → `flutter gen-l10n`
7. **Navigation**: Registrar ruta en `routes.dart` si es pantalla nueva

### l10n Workflow

```bash
# 1. Editar app_en.arb (template)
# 2. Editar app_es.arb (traducción)
# 3. Regenerar código:
flutter gen-l10n
# 4. Usar en código:
final l10n = AppLocalizations.of(context);
Text(l10n.someKey);
```

### Provider Testing Pattern

```dart
// test/providers/tasks_provider_test.dart
void main() {
  late MockStorageService storage;
  late TasksProvider provider;

  setUp(() {
    storage = MockStorageService();
    provider = TasksProvider(storage: storage);
  });

  test('loadTasks loads from storage and marks loaded', () async {
    when(storage.loadTasks()).thenAnswer((_) async => [testTask]);
    await provider.loadTasks();
    expect(provider.isLoaded, true);
    expect(provider.tasks.length, 1);
  });
}
```

---

## Testing

### Test Structure

```
test/
├── helpers/
│   └── mock_storage_service.dart      # Mock IStorageService con fake Hive in Memory
├── models_test.dart                   # Model serialization roundtrip
├── integration/app_test.dart          # Full app smoke test
├── providers/
│   ├── tasks_provider_test.dart       # Task CRUD, computed lists, batch ops
│   ├── projects_provider_test.dart    # Project CRUD
│   ├── notes_provider_test.dart       # Note CRUD, pagination
│   ├── goals_provider_test.dart       # Goal CRUD
│   └── tags_provider_test.dart        # Tag CRUD
└── widgets/
    ├── task_card_test.dart            # TaskCard rendering + interactions
    ├── project_card_test.dart         # ProjectCard rendering
    ├── note_card_test.dart            # NoteCard rendering
    └── goal_card_test.dart            # GoalCard rendering
```

### Running Tests

```bash
# All tests
flutter test

# Specific file
flutter test test/providers/tasks_provider_test.dart

# With coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## Roadmap

### ✅ Done

- [x] CRUD completo: Tasks, Projects, Notes, Goals, Tags
- [x] Subtareas con progreso, prioridades, estados, fechas
- [x] Vinculación Task→Project, Note→Project, Project→Goal
- [x] Kanban board (drag & drop entre columnas)
- [x] Dashboard con Smart Alerts
- [x] Vista Hoy (overdue + today + in progress)
- [x] Modo Foco (tareas críticas próximos 7 días)
- [x] Calendario (30-day timeline con color coding)
- [x] Progreso y estadísticas (métricas + goals)
- [x] Búsqueda global con debounce (300ms)
- [x] Papelera por tipo con restore
- [x] Notificaciones programadas (24h / 1h / personalizado)
- [x] Horario silencioso configurable
- [x] Export/import JSON completo
- [x] Android Auto Backup (Google Drive)
- [x] Backup persistente automático + restore
- [x] Tema oscuro/claro/sistema con 7 colores de acento
- [x] Sidebar colapsable con secciones + quick stats
- [x] Settings con búsqueda y categorías
- [x] Pomodoro timer (25/5/15 min con ciclos)
- [x] Operaciones batch (selección múltiple → completar/eliminar)
- [x] Quick capture FAB (note, task, project, goal)
- [x] Onboarding animado (5 pantallas)
- [x] l10n (English + Spanish, ARB)
- [x] Skeleton loading shimmer
- [x] Home widget (Android)
- [x] Migración automática de esquemas (v1→v2)
- [x] Esquema de notificaciones optimizado (sin redundancias)

### 🔜 Next

- [ ] Sincronización cloud (Firebase Firestore)
  - Login con Google/email
  - Sync offline-first con resolución de conflictos
  - Compartir proyectos entre usuarios
- [ ] Estadísticas avanzadas (gráficos tipo chart)
  - Task completion rate over time
  - Project burndown charts
  - Goal progress trends
- [ ] Recordatorios recurrentes (diario, semanal, mensual)
- [ ] Integración completa con calendario del sistema (two-way sync)
- [ ] Widgets iOS
- [ ] Temas personalizables (modo claro avanzado)
- [ ] Drag & drop reordering en boards y listas
- [ ] Soporte offline-first multidispositivo
- [ ] IA local mejorada (sugerencias de tareas, clasificación automática)

---

## License

```
MIT License

Copyright (c) 2025 Sergio Asensio

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

<p align="center">
  <sub>Built with Flutter &middot; Designed with ❤️ &middot; Made in Spain</sub>
</p>
