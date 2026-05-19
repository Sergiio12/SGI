# SGI (Second Brain) - Contexto Técnico para IA

## 1. DESCRIPCIÓN GENERAL

App Flutter multiplataforma (Android, iOS, Web, Windows, Linux, macOS) de productividad personal y gestión de conocimiento. Inspirada en metodologías GTD y PARA. Permite gestionar tareas, proyectos, notas y objetivos con persistencia local vía Hive, backup/restore JSON y notificaciones programadas.

- **Nombre:** second_brain (título: SGI - Sistema de Gestión Integral)
- **Versión:** 1.0.1+2
- **Creador:** Sergio Asensio
- **SDK mínimo:** Flutter 3.29.0 (Dart 3.7.0)

---

## 2. ARQUITECTURA GENERAL

Provider + Service Layer sin generación de código, sin BLoC, sin Riverpod, sin API calls.

```
UI (Screens / Widgets)
    |  context.watch / context.read / Consumer
    v
Providers (ChangeNotifier)  ->  Lógica de negocio + listas computadas
    |  llaman a métodos estáticos
    v
StorageService (singleton estático)  ->  Cache en memoria + Hive persistente
    |  Isolate.run() para JSON pesado
    v
Hive (NoSQL, single box "second_brain_store")  ->  Strings JSON
```

- No hay UseCases, Repositories interfaces ni capa de dominio separada.
- Los providers se instancian en `main()` y se pasan con `ChangeNotifierProvider.value()`.
- `DashboardProvider` usa `ChangeNotifierProxyProvider2` porque depende de TasksProvider y ProjectsProvider.
- `SearchProvider` y `NotificationController` se crean inline en el MultiProvider.

---

## 3. ESTRUCTURA DE DIRECTORIOS

```
lib/
├── main.dart                  # Entry point + MultiProvider setup
├── app.dart                   # MaterialApp widget
├── config/
│   ├── routes.dart            # Named routes + onGenerateRoute
│   └── theme.dart             # BrainTheme (Material 3, light/dark, colores)
├── models/
│   ├── brain_item.dart        # Clase base abstracta (id, createdAt, updatedAt, tags, toJson)
│   ├── task.dart              # Task + SubTask
│   ├── project.dart           # Project
│   ├── note.dart              # Note + NoteAttachment
│   ├── goal.dart              # Goal
│   └── tag.dart               # Tag
├── providers/
│   ├── settings_provider.dart
│   ├── tasks_provider.dart
│   ├── projects_provider.dart
│   ├── notes_provider.dart
│   ├── goals_provider.dart
│   ├── tags_provider.dart
│   ├── tags_provider_new.dart  # No usado, borrar?
│   ├── trash_provider.dart
│   ├── search_provider.dart
│   └── dashboard_provider.dart
├── screen/
│   ├── home_screen.dart        # Scaffold + BottomNav (5 tabs)
│   ├── loading/
│   ├── dashboard/
│   ├── tasks/
│   ├── projects/
│   ├── notes/
│   ├── goals/
│   ├── calendar/
│   ├── today/
│   ├── focus/
│   ├── progress/
│   ├── search/
│   ├── trash/
│   ├── data/
│   └── settings/
├── services/
│   ├── storage_service.dart    # Capa Hive (carga/guarda todo)
│   ├── backup_service.dart     # Export/Import JSON
│   ├── notification_service.dart  # flutter_local_notifications
│   └── smart_alerts_service.dart  # Alertas inteligentes del dashboard
├── utils/
│   ├── debouncer.dart          # Debounce genérico (500ms saves)
│   ├── notification_service_v2.dart  # Toast in-app (ChangeNotifier)
│   └── responsive_helper.dart
└── widgets/
    ├── brain_drawer.dart
    ├── task_card.dart
    ├── project_card.dart
    ├── goal_card.dart
    ├── note_card.dart
    ├── empty_state.dart
    ├── stats_card.dart
    ├── quick_capture_fab.dart
    ├── priority_indicator.dart
    ├── tag_chip.dart
    ├── tag_color_picker.dart
    └── pagination_bar.dart
```

---

## 4. MODELOS DE DATOS

Todos extienden `BrainItem` (abstracto):
```dart
class BrainItem {
  String id;
  DateTime createdAt;
  DateTime updatedAt;
  List<String> tags;       // IDs de tags
  Map<String, dynamic> toJson();
}
```

### Task
- **id, title, description, priority** (enum: low/medium/high/urgent), **status** (enum: pending/inProgress/inReview/completed/cancelled)
- dueDate, estimatedHours, actualHours, reminderMinutesBefore, lastActivityAt
- projectId, subtasks (List<SubTask>), linkedNoteIds
- Computed: `progress`, `isOverdue`, `isActive`
- Serialización manual con toJson/fromJson + migración de legacy (status y priority solían ser Strings/ints)

### SubTask (inline en task.dart)
- id, title, isDone

### Project
- title, description, emoji, colorValue (int), status (enum: active/paused/completed/abandoned)
- startDate, deadline, priority, objective, goalId
- taskIds (List<String>), noteIds, areas (List<String>)
- Static: `taskProgress(List<Task>)` calcula progreso según tareas vinculadas

### Note
- title, content, attachments (List<NoteAttachment>)
- type (enum: freeform/checklist/journal/reference/meetingNotes)
- notebook, projectId, linkedTaskIds, linkedNoteIds
- isPinned, colorValue, emoji

### Goal
- title, description, horizon (enum: monthly/quarterly/yearly)
- projectIds, metricLabel, targetValue, currentValue, colorValue
- Computed: `progress` (clamped 0.0-1.0)

### Tag
- id, name, color (Color object, no int), type (enum: note/task/project/goal)
- Static: `defaultTagsForType()` genera 4 tags por defecto por tipo

**Serialización:** Todos los modelos tienen `toJson()` y `factory fromJson(Map)` escritos a mano. NO se usa json_serializable ni freezed.

---

## 5. PROVIDERS (ChangeNotifier)

Cada provider expone:
- Listas crudas (e.g. `List<Task> _tasks`)
- Listas computadas (getters que filtran/ordenan, e.g. `List<Task> get pendingTasks`)
- Métodos CRUD (add, update, delete, etc.)
- Cada mutación llama a `_debouncedSave()` (Debouncer 500ms) que persiste a Hive
- `notifyListeners()` después de cada mutación

### TasksProvider
Funciones clave:
- CRUD: `addTask`, `updateTask`, `deleteTask`, `getTaskById`
- Listas computadas: pendingTasks, inProgressTasks, inReviewTasks, completedTasks, cancelledTasks, overdueTasks, todaysTasks, urgentAndImportantTasks, focusTasks
- `toggleStatus(String taskId)`: avanza al siguiente estado
- `addSubTask`, `toggleSubTask`, `removeSubTask`
- `linkNoteToTask`, `unlinkNoteFromTask`
- `updateLastActivity`

### ProjectsProvider
- CRUD + getters: activeProjects, pausedProjects, completedProjects, abandonedProjects
- `getProjectsByGoalId`

### NotesProvider
- CRUD + pinnedNotes, recentNotes, notesByNotebook, notesByType
- `getNotesByIds`

### GoalsProvider
- CRUD + goalsByHorizon, goalsWithProgress

### TagsProvider
- CRUD + getTagsByType, getTagsByIds
- Tags por defecto para cada tipo

### TrashProvider
- Maneja 4 listas de papeleras (tasks, projects, notes, goals)
- `restoreItem`, `permanentlyDelete`, `clearAll`
- Se sincroniza con StorageService mediante callback `onTrashChanged`

### SearchProvider
- Búsqueda global con debounce de 300ms
- Cruza tasks, projects, notes, goals
- Usa `_performSearchSync()` (método sincrónico invocado desde async con isolate)

### DashboardProvider
- Proxy que computa smart alerts a partir de TasksProvider y ProjectsProvider
- Usa `SmartAlertsService.getAlerts(tasks, projects)`

### SettingsProvider
- Tema (light/dark/system), notificaciones (master toggle, 24h, 1h, quiet hours, reminder default, notify on complete/overdue)
- Persiste en SharedPreferences
- Notifica a NotificationService cuando cambian preferencias

---

## 6. NAVEGACIÓN (config/routes.dart)

**Named routes** con `MaterialApp.routes` + `onGenerateRoute` fallback.

| Ruta | Screen | Argumento |
|------|--------|-----------|
| `/` | LoadingScreen | - |
| `/home` | HomeScreen | - |
| `/task` | TaskDetailScreen | taskId (String?) |
| `/project` | ProjectDetailScreen | projectId (String?) |
| `/goal` | GoalDetailScreen | goalId (String?) |
| `/note` | NoteEditorScreen | noteId (String?) |
| `/search` | SearchScreen | - |
| `/focus` | FocusScreen | - |
| `/today` | TodayScreen | - |
| `/calendar` | CalendarScreen | - |
| `/progress` | ProgressScreen | - |
| `/data` | DataScreen | - |
| `/settings` | SettingsScreen | - |
| `/trash` | TrashScreen | - |

Las rutas de settings (Appearance, Notifications, Debug) usan `Navigator.push` con `MaterialPageRoute` directamente.

Transición loading -> home: `Navigator.pushReplacementNamed`.

HomeScreen tiene BottomNavigationBar con 5 tabs: Dashboard, Tasks, Calendar/Today, Focus/Progress, Settings. Usa `AnimatedSwitcher` con fade+slide.

---

## 7. SERVICIOS

### StorageService (services/storage_service.dart)
- Singleton estático (todos los métodos static)
- Hive box: `second_brain_store`
- Cache en memoria: `_cachedTasks`, `_cachedProjects`, etc.
- Métodos: `init()`, load/save para cada tipo, load/save trash, `clearAll()`
- Usa `Isolate.run()` para serialización/deserialización en segundo plano
- Migración automática desde SharedPreferences (formato antiguo)

### BackupService (services/backup_service.dart)
- `buildPayload()`: construye JSON completo con schemaVersion, exportedAt, app name
- `exportToJson()`: escribe a Downloads o app documents
- `pickAndReadImport()`: file_picker -> lee JSON -> devuelve BrainBackupImport
- Isolate.run() para operaciones pesadas

### NotificationService (services/notification_service.dart)
- flutter_local_notifications: programación de recordatorios
- Métodos: `init()`, `scheduleTaskReminder()`, `cancelTaskReminder()`, `rescheduleAll()`
- Soporta quiet hours, Android exact alarm permissions
- Recordatorios: custom, 24h antes, 1h antes

### SmartAlertsService (services/smart_alerts_service.dart)
- Lógica de alertas del dashboard (sin estado, función pura)
- `getAlerts()`: deadlines < 24h, urgent tasks not started, important tasks inactive > 3 días, projects past deadline

---

## 8. UTILIDADES

### Debouncer
- Constructor: `Debouncer({required Duration delay})`
- Método: `call(VoidCallback action)` - ejecuta después del delay, resetea si se llama otra vez
- Método: `dispose()`
- Usado en todos los providers para bachear saves a Hive

### NotificationController (notification_service_v2.dart)
- ChangeNotifier para notificaciones toast in-app
- Tipos: success/error/info/warning
- Animaciones: slide + fade + elastic, glassmorphism, progress bar

### ResponsiveHelper
- `isDesktop(context)`: ancho > 900
- `isTablet(context)`: ancho 600-900
- Adapta layouts (columnas, padding, grid)

---

## 9. DEPENDENCIAS PRINCIPALES

| Paquete | Versión | Propósito |
|---------|---------|-----------|
| provider | ^6.1.1 | State management |
| uuid | ^4.2.1 | IDs únicos |
| intl | ^0.20.2 | Formato fechas |
| shared_preferences | ^2.2.2 | Preferencias de usuario |
| flutter_staggered_grid_view | ^0.7.0 | Grid escalonado |
| google_fonts | ^8.1.0 | Fuente Inter |
| hive_flutter | ^1.1.0 | BD local NoSQL |
| path_provider | ^2.1.5 | Rutas del sistema |
| file_picker | ^11.0.2 | Seleccionar archivos JSON |
| flutter_animate | ^4.5.2 | Animaciones declarativas |
| flutter_slidable | ^4.0.3 | Swipe para borrar |
| flutter_local_notifications | ^21.0.0 | Notificaciones locales |
| timezone | ^0.11.0 | Zonas horarias |

**Dev**: flutter_test, flutter_lints ^6.0.0, flutter_launcher_icons ^0.14.4

---

## 10. PERSISTENCIA Y FLUJO DE DATOS

```
Acción usuario (UI)
    |
    v
Provider.addXxx()
    |  -> modifica _cachedList
    |  -> notifyListeners() -> UI se actualiza
    |  -> _debouncedSave() (500ms)
    |      -> StorageService.saveXxx(List)
    |          -> Isolate.run(() => jsonEncode(list.map(e => e.toJson()).toList()))
    |              -> Hive box.put('brain_xxx', jsonString)
    v
Persistido
```

**Carga inicial en main():**
1. `await Hive.initFlutter()`
2. `await StorageService.init()` (abre box, carga todo a caché)
3. Instanciar providers con datos cacheados
4. `runApp(MultiProvider(...))`

**Claves Hive:** `brain_tasks`, `brain_projects`, `brain_notes`, `brain_goals`, `brain_tags`, `brain_trash_tasks`, `brain_trash_projects`, `brain_trash_notes`, `brain_trash_goals`, `settings_provider_theme`, `settings_provider_notifications`, `settings_provider_quiet_hours`, `settings_provider_default_reminder`.

---

## 11. TEMAS Y ESTILOS (config/theme.dart)

Clase `BrainTheme` con métodos static:
- `lightTheme` / `darkTheme`: Material 3, color scheme morado con azul secondary
- `accentColors`: Map<AccentColor, MaterialColor> con 7 colores (red, orange, amber, green, blue, indigo, purple)
- Decoraciones: glassmorphism (translúcidas con blur), bordes redondeados 12-24px
- Google Fonts Inter para todo el texto

Estrategia de tema: `ThemeMode` en SettingsProvider (light/dark/system). El tema se aplica en `MaterialApp(themeMode: settingsProvider.themeMode)`.

---

## 12. NOTIFICACIONES (DUAL LAYER)

1. **Sistema** (flutter_local_notifications): Recordatorios programados según dueDate - reminderMinutesBefore. Se cancelan al completar tarea. Se reprograman al cambiar preferencias. Soporta quiet hours (no notificar entre X e Y horas).

2. **In-app toast** (NotificationController): Overlay animado para feedback visual inmediato (ej: "Tarea creada", "Error al guardar"). No requiere permisos.

---

## 13. PRUEBAS

Solo existe `test/models_test.dart` (~488 líneas) con:
- Task: defaults, progress, isOverdue, subtask progress, toJson/fromJson roundtrip, legacy migration (status string/int, priority string/int), copyWith
- SubTask: toJson/fromJson, copyWith
- Note: defaults, roundtrip, copyWith, missing fields
- Project: defaults, roundtrip, legacy status migration, copyWith
- Goal: defaults, progress clamping, zero target, roundtrip, horizon migration, copyWith
- SearchProvider._performSearchSync: search by title, tag, cross-entity
- Project.taskProgress: 0 with no tasks, 0.5 with half done
- Goal helpers

No hay widget tests, integration tests ni provider tests.

**Comando para ejecutar tests:** `flutter test`

---

## 14. CONVENCIONES Y PATRONES A SEGUIR

1. **Provider/ChangeNotifier** para toda la lógica de estado. No introducir BLoC, Riverpod, GetX.
2. **Named routes** para navegación. Usar `Navigator.pushNamed(context, '/ruta', arguments: id)`.
3. **Serialización manual** con `toJson()`/`fromJson()`. No usar code generation.
4. **Debouncer** para operaciones de guardado (ya implementado en providers).
5. **Isolate.run()** para JSON pesado (ya en StorageService y BackupService).
6. **Capturar errores** con try/catch y mostrar toast via `NotificationController`.
7. **context.read** para métodos/eventos, **context.watch** para rebuilds.
8. **Material 3** con colores del tema (`Theme.of(context).colorScheme`), no hardcodear colores.
9. **Enum classes** para estados fijos (TaskStatus, TaskPriority, NoteType, etc.).
10. **Modelos inmutables** con `copyWith()` (escrito a mano, no freezed).

---

## 15. REGLAS IMPORTANTES PARA DESARROLLO

- **NO** usar API calls externas. La app es 100% offline.
- **NO** añadir dependencias sin verificar compatibilidad con flutter 3.29+.
- **NO** modificar el esquema de Hive sin migración retrocompatible.
- **SIEMPRE** poner `notifyListeners()` después de mutar estado en providers.
- **USAR** `StorageService.methods` estáticos para persistencia, no acceder a Hive directamente desde screens.
- **MANTENER** la estructura de archivos existente al añadir nuevas features.
- **SEGUIR** el patrón de ficheros: si añades una pantalla, crea su provider si necesita lógica propia.
- **Las pantallas** NO deben instanciar ChangeNotifierProvider. Todo se provee desde main.dart.
- **Para nuevo feature**, primero preguntar qué provider/screen/model corresponde.

---

## 16. PIPELINE DE INICIO DE APP

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await StorageService.init();   // Carga todo a caché desde Hive

  final settingsProvider = SettingsProvider();
  await settingsProvider.init();
  // Configurar NotificationService según preferencias

  final tasksProvider = TasksProvider();
  final projectsProvider = ProjectsProvider();
  // ... otros providers

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: tasksProvider),
        // ... resto de providers
      ],
      child: const SecondBrainApp(),
    )
  );
}
```

---

## 17. TAGS Y RELACIONES ENTRE ENTIDADES

- **Tags**: Cada entidad tiene `List<String> tags` que almacena IDs de Tag. Los tags se gestionan desde TagsProvider y se asignan desde las pantallas de detalle.
- **Task <-> Project**: `task.projectId` apunta a un Project. `project.taskIds` contiene IDs de Task.
- **Project <-> Goal**: `project.goalId` apunta a un Goal. `goal.projectIds` contiene IDs de Project.
- **Note <-> Task**: `note.linkedTaskIds` apunta a Tasks. `task.linkedNoteIds` apunta a Notes.
- **Note <-> Project**: `note.projectId` apunta a un Project. `project.noteIds` apunta a Notes.

**NO hay relaciones de integridad referencial.** Si borras un Project, las Tasks vinculadas mantienen su `projectId` (quedan huérfanas). Si borras un Tag, las entidades mantienen su ID en la lista de tags.

---

## 18. COMPORTAMIENTO DEL KANBAN (TASKS SCREEN)

La pantalla de tareas usa un diseño Kanban con 5 columnas:
- **Pending** -> **In Progress** -> **In Review** -> **Completed** -> **Cancelled**

Características:
- Arrastrar y soltar entre columnas cambia el status
- Filtros: prioridad, fecha, proyecto, búsqueda por título/descripción
- Ordenación: manual (drag reorder), por prioridad, por fecha
- Slidable en cada tarjeta: marcar completada, borrar, editar

---

## 19. COPIA DE SEGURIDAD (DATA SCREEN)

Formato JSON exportado:
```json
{
  "schemaVersion": 2,
  "exportedAt": "ISO8601",
  "appName": "SGI",
  "data": {
    "tasks": [...],
    "projects": [...],
    "notes": [...],
    "goals": [...],
    "tags": [...]
  }
}
```

Import: file_picker -> leer JSON -> validar schemaVersion -> sobreescribir todo (reemplaza datos actuales).

---

## 20. TODO / MEJORAS DETECTADAS

- `tags_provider_new.dart` existe pero parece no usarse. Probablemente eliminable.
- No hay tests de providers, widgets ni integración.
- No hay manejo de errores centralizado.
- `tags_provider.dart` exporta `tagsProvider` (minúscula) como instancia global además del provider. Posible bad practice.
- Algunos providers (tags_provider_new) pueden tener código duplicado.
