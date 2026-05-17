# SGI — Sistema de Gestión Integral / Second Brain

> **Tu segundo cerebro digital.** Una aplicación Flutter para gestionar tareas, proyectos, objetivos y notas en un solo lugar, con respaldo local completo y notificaciones inteligentes.

---

## 📋 Tabla de contenidos

- [Descripción general](#-descripción-general)
- [Capturas de pantalla](#-capturas-de-pantalla)
- [Arquitectura](#-arquitectura)
- [Funcionalidades](#-funcionalidades)
  - [Dashboard](#dashboard)
  - [Tareas](#tareas)
  - [Proyectos](#proyectos)
  - [Objetivos](#objetivos)
  - [Notas](#notas)
  - [Calendario](#calendario)
  - [Hoy — Vista consolidada](#hoy--vista-consolidada)
  - [Modo foco](#modo-foco)
  - [Progreso y estadísticas](#progreso-y-estadísticas)
  - [Búsqueda global](#búsqueda-global)
  - [Papelera](#papelera)
- [Gestión de datos](#-gestión-de-datos)
  - [Exportación e importación JSON](#exportación-e-importación-json)
  - [Almacenamiento local](#almacenamiento-local)
- [Notificaciones](#-notificaciones)
- [Personalización](#-personalización)
  - [Tema claro / oscuro](#tema-claro--oscuro)
  - [Ajustes de notificaciones](#ajustes-de-notificaciones)
- [Estructura del proyecto](#-estructura-del-proyecto)
- [Tecnologías utilizadas](#-tecnologías-utilizadas)
- [Cómo empezar](#-cómo-empezar)
- [Roadmap](#-roadmap)
- [Licencia](#-licencia)

---

## 🧠 Descripción general

**SGI** (Sistema de Gestión Integral) es una aplicación de tipo *Second Brain* diseñada para ayudarte a organizar tu vida personal y profesional. Inspirada en metodologías de productividad como GTD (Getting Things Done) y PARA (Projects, Areas, Resources, Archives), SGI unifica en un solo espacio:

- **Tareas** con prioridades, estados, subtareas y fechas de vencimiento.
- **Proyectos** multicapa que agrupan tareas y notas.
- **Objetivos** medibles con horizontes mensual, trimestral y anual.
- **Notas** con soporte para libretas, tipos y anclaje.

Todo ello con persistencia local completa, respaldo en JSON, notificaciones programadas y una interfaz oscura premium con soporte de tema claro.

---

## 🖼️ Capturas de pantalla

> *(Añade aquí capturas de pantalla de la aplicación)*

| Dashboard | Tareas | Proyectos |
|-----------|--------|-----------|
|           |        |           |
| Objetivos | Notas  | Calendario |
|           |        |           |

---

## 🏗️ Arquitectura

### Patrón de estado

SGI utiliza **Provider** (`ChangeNotifierProvider`) para la gestión de estado, con proveedores independientes para cada dominio:

```
MultiProvider
├── SettingsProvider        → Tema, notificaciones, preferencias
├── TasksProvider           → CRUD + listas computadas
├── ProjectsProvider        → CRUD + estados de proyecto
├── NotesProvider           → CRUD + libretas + anclaje
├── GoalsProvider           → CRUD + horizontes
├── TrashProvider           → Elementos eliminados
├── NotificationController  → Toast en pantalla (snackbar propio)
├── SearchProvider          → Búsqueda con debounce
└── DashboardProvider       → Proxy: combina Tasks + Projects
```

### Flujo de navegación

```
/ (LoadingScreen)
  → Inicializa Hive + plugins + carga datos
  → /home (HomeScreen)
       ├── BottomNavigation (5 tabs)
       │   ├── Dashboard
       │   ├── Tareas
       │   ├── Proyectos
       │   ├── Objetivos
       │   └── Notas
       └── Drawer lateral
           ├── Búsqueda global
           ├── VISTAS
           │   ├── Hoy → /today
           │   ├── En foco → /focus
           │   ├── Calendario → /calendar
           │   └── Progreso → /progress
           └── Ajustes, Papelera, Datos
```

### Persistencia

Los datos se almacenan localmente mediante **Hive** (caja `second_brain_store`) con serialización JSON. Cada entidad se persiste individualmente (tareas, proyectos, notas, objetivos y sus respectivas papeleras). Un `Debouncer` de 500ms optimiza las escrituras para evitar sobrecarga en mutaciones frecuentes.

---

## ✨ Funcionalidades

### Dashboard

El Dashboard es la pantalla principal que ofrece una visión general del estado del sistema:

- **Total de elementos**: tareas activas, proyectos en curso, notas totales, objetivos.
- **Alertas inteligentes**: tareas vencidas, urgencias, proyectos sin actividad reciente.
- **Acceso rápido a todo**: tarjetas resumen de cada categoría.
- **Progreso del día**: tareas completadas hoy vs. total del día.

### Tareas

Gestión completa de tareas con las siguientes capacidades:

- **Estados**: Pendiente, En progreso, En revisión, Completada, Cancelada.
- **Prioridades**: Baja, Normal, Alta, Urgente (codificadas por colores).
- **Subtareas**: Lista de verificación anidada con progreso visual.
- **Fechas**: Fecha de vencimiento con recordatorios programados.
- **Horas estimadas y reales**: Seguimiento de tiempo por tarea.
- **Tags**: Etiquetado libre para categorización transversal.
- **Asignación a proyectos**: Vinculación con proyectos.
- **Deslizar para eliminar**: Interacción táctil con Slidable.

### Proyectos

Organización de trabajo en unidades mayores:

- **Estados**: Activo, En pausa, Completado, Abandonado.
- **Metadatos**: Emoji representativo, color personalizable, descripción, objetivo.
- **Fechas**: Fecha de inicio, fecha límite (deadline).
- **Prioridad**: Al igual que las tareas, con codificación por color.
- **Vinculación**: Asociación a objetivos (Goals) y agrupación de tareas/notas.
- **Progreso visual**: Barra de progreso calculada a partir de tareas completadas.

### Objetivos

Metas medibles con seguimiento temporal:

- **Horizontes**: Mensual, Trimestral, Anual.
- **Métrica personalizable**: Etiqueta de medición y valor objetivo.
- **Progreso**: Valor actual vs. valor objetivo con indicador circular.
- **Proyectos asociados**: Los proyectos vinculados contribuyen al objetivo.

### Notas

Captura de conocimiento con flexibilidad total:

- **Tipos de nota**: Libre, Lista de verificación, Diario, Referencia, Notas de reunión.
- **Libretas**: Organización por libretas (notebooks) con filtrado.
- **Anclaje**: Notas importantes fijadas al inicio.
- **Emoji**: Icono representativo por nota.
- **Búsqueda**: Búsqueda de texto completo por título, contenido, libreta y tags.

### Calendario

Visualización temporal de todas las tareas con fecha de vencimiento:

- **Agrupación por día**: Tareas ordenadas por fecha en los próximos 30 días.
- **Etiquetas contextuales**: "Hoy", "Mañana" para fechas próximas.
- **Código de color**: Naranja para hoy, azul para próximos 3 días, púrpura para el resto.
- **Interacción**: Toque para ver detalle, toggle para completar.

### Hoy — Vista consolidada

Pantalla que unifica todo lo que requiere atención hoy:

- **Cabecera dinámica**: Fecha actual con saludo y contadores.
- **Sección Vencidas**: Tareas cuya fecha ya pasó (rojo).
- **Sección Hoy**: Tareas que vencen hoy (naranja).
- **Sección En progreso**: Tareas actualmente en desarrollo (azul).
- **Estado vacío**: Animación celebración cuando no hay nada pendiente.

### Modo foco

Filtro inteligente que muestra solo las tareas que requieren atención inmediata:

- **Criterios**: Tareas en progreso + urgentes + alta prioridad con vencimiento próximo (7 días).
- **Ordenación**: Por prioridad descendente y fecha de vencimiento ascendente.
- **Propósito**: Ayudar a concentrarse en lo verdaderamente importante.

### Progreso y estadísticas

Panel de análisis con métricas clave:

- **Tareas activas vs. completadas**.
- **Proyectos activos vs. cerrados**.
- **Total de notas y ancladas**.
- **Horas estimadas vs. reales**.
- **Objetivos**: Tarjetas de progreso con valor actual/objetivo.

### Búsqueda global

Búsqueda instantánea en toda la aplicación con debounce:

- **Búsqueda transversal**: Tareas + Proyectos + Notas + Objetivos.
- **Debounce**: 300ms para evitar búsquedas excesivas.
- **Resultados agrupados**: Por categoría con iconos distintivos.
- **Navegación directa**: Toque para abrir el detalle del elemento.

### Papelera

Sistema de eliminación seguro con recuperación:

- **Separada por tipo**: Tareas, proyectos, notas y objetivos en papeleras independientes.
- **Restauración**: Recupera cualquier elemento eliminado.
- **Eliminación permanente**: Borrado definitivo cuando sea necesario.
- **Contador**: Badge en la barra lateral con el total de elementos.

---

## 💾 Gestión de datos

### Exportación e importación JSON

SGI permite exportar e importar todos los datos como archivo JSON:

- **Exportación**: Genera un archivo JSON completo con todas las entidades y sus relaciones.
- **Restauración**: Importa un archivo JSON exportado previamente, sustituyendo los datos actuales.
- **Seguridad**: Diálogo de confirmación antes de restaurar.
- **Ubicación**: El archivo se guarda en una ubicación elegida por el usuario.

### Almacenamiento local

- **Motor**: Hive (base de datos local NoSQL para Flutter).
- **Caja única**: `second_brain_store` almacena todos los datos como JSON strings.
- **Migración automática**: Migración desde SharedPreferences heredado en primera ejecución.
- **Persistencia**: Todos los datos permanenecen en el dispositivo sin necesidad de conexión.

---

## 🔔 Notificaciones

SGI cuenta con un sistema de notificaciones local completo:

- **Notificaciones programadas**: Recordatorios automáticos para tareas con fecha de vencimiento.
- **3 tipos de recordatorio por tarea**:
  - **Personalizado**: Tiempo configurable antes del vencimiento.
  - **24 horas antes**: Aviso con un día de antelación.
  - **1 hora antes**: Aviso urgente de vencimiento inminente.
- **Cancelación automática**: Al completar o eliminar una tarea.
- **Notificaciones instantáneas**: Alertas al completar tareas o cuando vencen.
- **Reschedule al inicio**: Al abrir la app, se reprograman todas las notificaciones activas.
- **Canales Android**: Canal dedicado `brain_task_reminders` con prioridad alta.
- **Permisos**: Solicitud automática de permisos de notificación y alarmas exactas.

### Ajustes de notificaciones

Configurables desde A pantalla de Ajustes > Notificaciones:

| Ajuste | Descripción |
|--------|-------------|
| Notificaciones (master) | Activar/desactivar todas |
| 24 horas antes | Recordatorio diario |
| 1 hora antes | Recordatorio horario |
| Recordatorio por defecto | Tiempo predeterminado para nuevas tareas |
| Horario silencioso | Intervalo sin notificaciones |
| Notificar al completar | Toast al finalizar tarea |
| Notificar vencidas | Alerta cuando una tarea vence |

---

## 🎨 Personalización

### Tema claro / oscuro

SGI ofrece tres modos de visualización:

- **Oscuro** (predeterminado): Fondo negro OLED con acentos neón vibrantes. Diseñado para reducir la fatiga visual.
- **Claro**: Fondo blanco con texto negro de alto contraste. Aspecto profesional y limpio.
- **Sistema**: Sigue automáticamente la configuración de tema del dispositivo.

Los acentos de color (púrpura, azul, verde, naranja, rojo) se mantienen en ambos modos, preservando la identidad visual.

### Ajustes de notificaciones

Pantalla completa de configuración con las siguientes secciones:

- **Recordatorios de tareas**: Activar/desactivar cada tipo de recordatorio.
- **Horario silencioso**: Define un intervalo diario sin notificaciones.
- **Preferencias**: Notificaciones al completar tareas o detectar vencidas.
- Los cambios se persisten en SharedPreferences y se sincronizan en tiempo real con el motor de notificaciones.

---

## 📁 Estructura del proyecto

```
lib/
├── main.dart                          # Punto de entrada + providers
├── app.dart                           # Widget raíz (MaterialApp)
├── config/
│   ├── theme.dart                     # Temas claro/oscuro + colores BrainTheme
│   └── routes.dart                    # Definición de rutas y navegación
├── models/
│   ├── task.dart                      # Modelo de tarea
│   ├── project.dart                   # Modelo de proyecto
│   ├── note.dart                      # Modelo de nota
│   ├── goal.dart                      # Modelo de objetivo
│   └── brain_item.dart                # Clase base (id, tags, timestamps)
├── providers/
│   ├── settings_provider.dart         # Tema, notificaciones, preferencias
│   ├── tasks_provider.dart            # CRUD + listas computadas de tareas
│   ├── projects_provider.dart         # CRUD + estados de proyecto
│   ├── notes_provider.dart            # CRUD + libretas + búsqueda
│   ├── goals_provider.dart            # CRUD + horizontes
│   ├── trash_provider.dart            # Gestión de papelera
│   ├── search_provider.dart           # Búsqueda global con debounce
│   └── dashboard_provider.dart        # Alertas y resúmenes (proxy)
├── screen/
│   ├── loading/loading_screen.dart    # Pantalla de carga inicial
│   ├── home_screen.dart               # Scaffold principal + bottom nav
│   ├── dashboard/dashboard_screen.dart
│   ├── tasks/
│   │   ├── tasks_screen.dart
│   │   └── task_detail_screen.dart
│   ├── projects/
│   │   ├── projects_screen.dart
│   │   └── project_detail_screen.dart
│   ├── notes/
│   │   ├── notes_screen.dart
│   │   └── note_editor_screen.dart
│   ├── goals/
│   │   ├── goals_screen.dart
│   │   └── goal_detail_screen.dart
│   ├── calendar/calendar_screen.dart
│   ├── today/today_screen.dart        # Vista consolidada del día
│   ├── focus/focus_screen.dart        # Modo foco de tareas
│   ├── progress/progress_screen.dart  # Estadísticas y métricas
│   ├── search/search_screen.dart      # Búsqueda global
│   ├── trash/trash_screen.dart        # Papelera
│   ├── data/data_screen.dart          # Export/import JSON + borrar datos
│   └── settings/
│       ├── settings_screen.dart       # Ajustes principales
│       ├── appearance_screen.dart     # Configuración de tema
│       ├── notifications_screen.dart  # Configuración de notificaciones
│       └── debug_screen.dart          # Herramientas de depuración
├── services/
│   ├── storage_service.dart           # Persistencia Hive (CRUD genérico)
│   ├── backup_service.dart            # Exportación/importación JSON
│   └── notification_service.dart      # Notificaciones locales programadas
├── utils/
│   ├── debouncer.dart                 # Utilidad de debounce
│   └── notification_service_v2.dart   # Toast en pantalla (overlay animado)
└── widgets/
    ├── brain_drawer.dart              # Barra lateral (navegación + vistas)
    ├── task_card.dart                 # Tarjeta de tarea (Slidable)
    ├── project_card.dart              # Tarjeta de proyecto
    ├── goal_card.dart                 # Tarjeta de objetivo
    ├── note_card.dart                 # Tarjeta de nota
    ├── empty_state.dart               # Estado vacío animado
    ├── stats_card.dart                # Tarjeta de estadística
    ├── quick_capture_fab.dart         # FAB de captura rápida
    └── ...
```

---

## 🛠️ Tecnologías utilizadas

| Tecnología | Versión | Propósito |
|-----------|---------|-----------|
| **Flutter** | 3.41+ | Framework de UI multiplataforma |
| **Dart** | 3.11+ | Lenguaje de programación |
| **Provider** | ^6.1.1 | Gestión de estado (ChangeNotifier) |
| **Hive** | ^1.1.0 | Base de datos local NoSQL |
| **SharedPreferences** | ^2.2.2 | Almacenamiento de preferencias |
| **flutter_local_notifications** | ^21.0.0 | Notificaciones locales programadas |
| **timezone** | ^0.11.0 | Zonas horarias para notificaciones |
| **Google Fonts** | ^6.1.0 | Tipografía Inter |
| **intl** | ^0.19.0 | Formateo de fechas |
| **flutter_slidable** | ^4.0.3 | Interacción deslizable en tarjetas |
| **flutter_animate** | ^4.5.2 | Animaciones declarativas |
| **file_picker** | ^11.0.2 | Selección de archivos para importación |
| **path_provider** | ^2.1.5 | Rutas del sistema de archivos |
| **uuid** | ^4.2.1 | Generación de identificadores únicos |

---

## 🚀 Cómo empezar

### Requisitos

- Flutter SDK 3.0.0 o superior
- Dart SDK 3.0.0 o superior
- Android Studio / VS Code (opcional)

### Instalación

```bash
# Clonar el repositorio
git clone https://github.com/tu-usuario/sgi.git
cd sgi

# Instalar dependencias
flutter pub get

# Ejecutar en modo debug
flutter run

# Generar APK de producción
flutter build apk --release
```

### Configuración de notificaciones (Android)

SGI solicitará automáticamente los permisos necesarios para notificaciones y alarmas exactas en la primera ejecución. Asegúrate de aceptarlos para que los recordatorios funcionen correctamente.

---

## 🧭 Roadmap

- [x] CRUD completo de tareas, proyectos, notas y objetivos
- [x] Notificaciones programadas con horario silencioso
- [x] Tema claro/oscuro/sistema
- [x] Exportación e importación JSON
- [x] Búsqueda global con debounce
- [x] Vista consolidada "Hoy"
- [x] Configuración de notificaciones
- [ ] Sincronización en la nube (Firebase)
- [ ] Widgets de Android/iOS
- [ ] Estadísticas avanzadas (gráficos)
- [ ] Soporte para recordatorios recurrentes
- [ ] Integración con calendario del sistema
- [ ] Temas personalizables (colores de acento)
- [ ] Modo offline multidispositivo

---

## 📄 Licencia

Este proyecto está bajo la licencia MIT. Consulta el archivo `LICENSE` para más información.

---

**Hecho con ❤️ usando Flutter**
