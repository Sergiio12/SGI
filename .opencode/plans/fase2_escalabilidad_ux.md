# Fase 2 - Escalabilidad y UX

> Contexto completo del proyecto en `AI_CONTEXT.md` y `README.md`
> Rama actual: `main` (último commit: refactor StorageService + tests)

## ¿Qué se hizo en la Fase 1?
- Interfaz `IStorageService` + `HiveStorageService implements IStorageService`
- Inyección de dependencias en todos los providers (constructor parameter)
- `AppBootstrap` para inicialización centralizada
- `MockStorageService` en `test/helpers/`
- 62 tests nuevos de providers (total: 97 tests)
- Eliminado `tags_provider_new.dart` (código muerto)

---

## Pendiente de la Fase 1 (no crítico, pero útil)

### 1.4 Tests de widgets
Crear tests para las tarjetas principales usando `WidgetTester`:
- `test/widgets/task_card_test.dart`
- `test/widgets/note_card_test.dart`  
- `test/widgets/goal_card_test.dart`
- `test/widgets/project_card_test.dart`

**Dependencias:** `flutter_test` (ya incluido), `MockStorageService` vía provider wrapping

### 1.5 Tests de integración
- Flujo completo: crear tarea → ver en dashboard → marcar completada → ver en papelera
- Usar `IntegrationTestWidgetsFlutterBinding`

---

## Fase 2 - Prioridad Alta: Escalabilidad + UX

### 2.1 Sistema de paginación virtual
**Archivos:** `lib/providers/tasks_provider.dart`, `lib/widgets/task_card.dart`
- Implementar lazy loading con `ScrollController` + `ScrollNotification`
- Limitar carga inicial a 50 items, cargar más al hacer scroll
- Añadir `_page` y `_hasMore` a providers
- Crear `PaginatedList` widget reutilizable

### 2.2 Índice de búsqueda invertido
**Archivos:** `lib/providers/search_provider.dart`
- Construir `Map<String, List<SearchResult>>` en memoria al cargar datos
- Tokenizar texto (separar por espacios, minúsculas)
- Búsqueda O(1) por token en lugar de O(n) lineal

### 2.3 Selector granular para rebuilds
**Archivos:** Todas las screens
- Reemplazar `context.watch<Provider>()` por `context.select<Provider, T>((p) => p.campoEspecifico)`
- Prioridad: `home_screen.dart` (rebuilds todo el BottomNav), `tasks_screen.dart` (tablero kanban)

### 2.4 i18n - Internacionalización
**Archivos nuevos:** `lib/l10n/` (carpeta con archivos ARB)
**Archivos afectados:** Todas las screens y widgets

Pasos:
1. Añadir `flutter_localizations` a `pubspec.yaml` (ya parte del SDK)
2. Crear `lib/l10n/app_es.arb` y `lib/l10n/app_en.arb`
3. Migrar strings hardcodeados españoles a `AppLocalizations.of(context)!.xxxx`
4. Configurar `localizationsDelegates` y `supportedLocales` en `app.dart`

**Strings clave a migrar** (aproximadamente 200+):
- Navegación: "Dashboard", "Tareas", "Proyectos", "Objetivos", "Notas"
- Estados: "Pendiente", "En progreso", "Completada", "Cancelada"
- Notificaciones toast: "Tarea creada", "Error al guardar", etc.
- Textos vacíos: "No hay tareas", "Todo al día", etc.

### 2.5 Manejo de errores centralizado
**Archivos nuevos:** `lib/core/result.dart`, `lib/core/app_exception.dart`
**Archivos afectados:** `main.dart`, `app.dart`, todos los providers

```dart
// lib/core/result.dart
sealed class Result<T> {
  const Result();
  factory Result.success(T value) = Success<T>;
  factory Result.failure(AppException error) = Failure<T>;
}

class AppException {
  final String message;
  final String? code;
  final StackTrace? stackTrace;
  const AppException({required this.message, this.code, this.stackTrace});
}
```

- Envolver métodos de providers en `Result<T>`
- Crear `ErrorBoundary` widget que capture errores y muestre UI amigable
- Usar `runZonedGuarded` en `main.dart` para errores no capturados

### 2.6 Skeleton loaders
**Archivos:** `lib/widgets/skeleton_card.dart` (nuevo)
- Reemplazar `CircularProgressIndicator` con shimmer animations
- Aplicar a: `task_card.dart`, `note_card.dart`, `goal_card.dart`, `project_card.dart`
- Estado `isLoading` en providers para mostrar skeletons

### 2.7 Haptic feedback
**Archivo:** `lib/utils/haptic_helper.dart` (nuevo)
- Usar `HapticFeedback.lightImpact()` en: completar tarea, eliminar, crear
- Usar `HapticFeedback.mediumImpact()` en: drag & drop, long press

---

## Fase 3 - Prioridad Media: Calidad Profesional

### 3.1 Accesibilidad (a11y)
- Añadir widgets `Semantics` en todas las tarjetas y botones
- Usar `ExcludeSemantics` en decoraciones
- Verificar contraste de color (WCAG AA mínimo)
- Soporte de `MediaQuery.boldText` y `accessibleNavigation`

### 3.2 Split de screens grandes
- `tasks_screen.dart` (1266 líneas) → dividir en:
  - `tasks_board.dart` (tablero kanban)
  - `tasks_filters.dart` (panel de filtros)
  - `tasks_list.dart` (lista de tareas)
- `loading_screen.dart` (766 líneas) → extraer animaciones a widgets

### 3.3 Crash reporting
- Firebase Crashlytics o Sentry
- Capturar errores en `runZonedGuarded` + providers

### 3.4 CI/CD pipeline
Crear `.github/workflows/ci.yml`:
```yaml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
      - run: flutter build apk --release
```

### 3.5 Migraciones de esquema Hive
- Añadir `schemaVersion` a cada método `loadXxx()`
- Crear `_migrateV1toV2()`, `_migrateV2toV3()` etc.
- Version tracking en `SharedPreferences`

---

## Fase 4 - Prioridad Baja: Nuevas Features (del Roadmap)

- Sincronización cloud (Firebase)
- Widgets Android/iOS
- Estadísticas con gráficos (fl_chart)
- Recordatorios recurrentes
- Integración con calendario del sistema
- Temas personalizables (colores de acento)

---

## Convenciones a mantener

| Regla | Descripción |
|---|---|
| Provider/ChangeNotifier | NO introducir BLoC, Riverpod, GetX |
| Serialización manual | `toJson()`/`fromJson()` - NO code generation |
| `Isolate.run()` | Para JSON pesado |
| `context.read` vs `context.watch` | read para eventos, watch para rebuilds |
| Material 3 | Usar `Theme.of(context).colorScheme` |
| Modelos inmutables | `copyWith()` para mutaciones |
| Sin API calls externas | App 100% offline |
