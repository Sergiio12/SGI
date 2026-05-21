import 'dart:math';

import '../models/project.dart';
import '../models/tag.dart';
import '../models/task.dart';

class LocalAiService {
  static final _priorityKeywords = <TaskPriority, List<String>>{
    TaskPriority.low: [
      'cuando pueda', 'sin prisa', 'algún día', 'maybe', 'opcional',
      'si tengo tiempo', 'no urgente', 'low', 'baja',
    ],
    TaskPriority.high: [
      'importante', 'urgente', 'critico', 'crítico', 'pronto', 'soon',
      'fecha límite', 'deadline', 'vencimiento', 'vencer', 'vencido',
      'mañana', 'antes de', 'prioritario',
    ],
    TaskPriority.urgent: [
      'ya', 'ahora', 'inmediato', 'asap', 'lo antes posible',
      'hoy mismo', 'urgentísimo', 'máxima prioridad',
    ],
  };

  static final _shortTaskIndicators = [
    'rápido', 'breve', 'corto', 'quick', 'fast', 'minutos',
    'llamar', 'enviar', 'avisar', 'comprar', 'check',
    'revisar', 'confirmar', 'preguntar', 'recordar',
  ];

  static final _mediumTaskIndicators = [
    'reunión', 'meeting', 'escribir', 'redactar', 'preparar',
    'organizar', 'limpiar', 'ordenar', 'diseñar', 'crear',
    'analizar', 'investigar', 'leer', 'estudiar',
  ];

  static final _longTaskIndicators = [
    'proyecto', 'desarrollar', 'implementar', 'crear sistema',
    'documentar', 'migrar', 'configurar', 'integrate',
    'desplegar', 'release', 'lanzamiento', 'campaña',
    'curso', 'formación', 'capítulo',
  ];

  TaskPriority suggestPriority(String title, String description) {
    final text = '$title $description'.toLowerCase();

    for (final entry in _priorityKeywords.entries) {
      for (final keyword in entry.value) {
        if (text.contains(keyword.toLowerCase())) {
          return entry.key;
        }
      }
    }

    return TaskPriority.medium;
  }

  double suggestEstimatedHours(String title, String description) {
    final text = '$title $description'.toLowerCase();

    for (final word in _longTaskIndicators) {
      if (text.contains(word)) return 8.0;
    }

    for (final word in _mediumTaskIndicators) {
      if (text.contains(word)) return 2.0;
    }

    for (final word in _shortTaskIndicators) {
      if (text.contains(word)) return 0.5;
    }

    final wordCount = text.split(RegExp(r'\s+')).length;
    if (wordCount > 15) return 3.0;
    if (wordCount > 8) return 1.5;

    return 1.0;
  }

  List<String> suggestTags(
    String title,
    String description,
    List<Tag> existingTags,
  ) {
    if (existingTags.isEmpty) return [];
    final text = '$title $description'.toLowerCase();
    final words = text.split(RegExp(r'[\s,.;:!?]+')).where((w) => w.length > 2).toSet();

    final scored = <String, double>{};

    for (final tag in existingTags) {
      final tagLower = tag.name.toLowerCase();
      final tagWords = tagLower.split(RegExp(r'[\s_\-]+'));

      double score = 0;

      for (final word in words) {
        if (tagLower == word) {
          score += 3.0;
        } else if (tagLower.contains(word)) {
          score += 1.5;
        } else if (tagWords.any((tw) => tw == word)) {
          score += 2.0;
        } else if (tagWords.any((tw) => _levenshteinSimilarity(tw, word) > 0.7)) {
          score += 1.0;
        }
      }

      if (score > 0) {
        scored[tag.name] = score;
      }
    }

    final sorted = scored.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(3).map((e) => e.key).toList();
  }

  String? suggestProject(String title, List<Project> projects) {
    if (projects.isEmpty) return null;
    if (title.trim().isEmpty) return null;

    final text = title.toLowerCase();
    final words = text.split(RegExp(r'[\s,.;:!?]+')).where((w) => w.length > 2).toSet();

    final scored = <String, double>{};

    for (final project in projects) {
      final projectText =
          '${project.title} ${project.description} ${project.objective}'.toLowerCase();
      final projectWords =
          projectText.split(RegExp(r'[\s,.;:!?]+')).where((w) => w.length > 2).toSet();

      final intersection = words.intersection(projectWords).length;
      if (intersection > 0) {
        scored[project.id] = intersection.toDouble();
      }

      final titleWords =
          project.title.toLowerCase().split(RegExp(r'[\s_\-]+')).where((w) => w.length > 2).toSet();
      for (final word in words) {
        for (final pw in titleWords) {
          if (_levenshteinSimilarity(word, pw) > 0.6) {
            scored[project.id] = (scored[project.id] ?? 0) + 0.5;
          }
        }
      }
    }

    if (scored.isEmpty) return null;

    final best = scored.entries.reduce((a, b) => a.value > b.value ? a : b);
    return best.value >= 1.0 ? best.key : null;
  }

  String generateDailyIntention(List<Task> todayTasks) {
    if (todayTasks.isEmpty) {
      final intentions = [
        'Hoy me tomo un momento para planificar lo que viene',
        'Un día sin tareas es una oportunidad para crear nuevas',
        'Hoy me enfoco en lo que realmente importa',
      ];
      return intentions[Random().nextInt(intentions.length)];
    }

    final priorities = todayTasks.map((t) => t.priority).toSet();
    final hasUrgent = priorities.contains(TaskPriority.urgent);
    final hasHigh = priorities.contains(TaskPriority.high);

    final text = todayTasks.map((t) => t.title).join(' ').toLowerCase();

    if (hasUrgent) {
      final urgents = todayTasks.where((t) => t.priority == TaskPriority.urgent).toList();
      return 'Resolver asuntos urgentes: ${urgents.first.title}';
    }

    if (hasHigh) {
      final highCount = todayTasks.where((t) => t.priority == TaskPriority.high).length;
      return _randomItem([
        'Enfrentar $highCount tarea${highCount > 1 ? 's' : ''} importante${highCount > 1 ? 's' : ''} con determinación',
        'Hoy me concentro en lo prioritario',
        'Dar el máximo en las tareas clave del día',
      ]);
    }

    if (text.contains('reunión') || text.contains('meeting')) {
      return 'Prepararme bien para las reuniones y participar activamente';
    }

    if (text.contains('crear') || text.contains('diseñar') || text.contains('escribir')) {
      return 'Dejar fluir la creatividad y dar lo mejor de mí';
    }

    if (text.contains('aprender') || text.contains('estudiar') || text.contains('curso')) {
      return 'Hoy aprendo algo nuevo y crezco un poco más';
    }

    return _randomItem([
      'Avanzar con foco en las tareas planificadas',
      'Hoy priorizo el progreso sobre la perfección',
      'Un paso a la vez, con intención y claridad',
    ]);
  }

  double semanticSimilarity(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0;

    final wordsA = a.toLowerCase().split(RegExp(r'[\s,.;:!?]+')).where((w) => w.length > 1).toSet();
    final wordsB = b.toLowerCase().split(RegExp(r'[\s,.;:!?]+')).where((w) => w.length > 1).toSet();

    if (wordsA.isEmpty || wordsB.isEmpty) return 0;

    final intersection = wordsA.intersection(wordsB).length;
    final union = wordsA.union(wordsB).length;

    final jaccard = union > 0 ? intersection / union : 0.0;

    double fuzzyScore = 0;
    for (final wa in wordsA) {
      for (final wb in wordsB) {
        final sim = _levenshteinSimilarity(wa, wb);
        if (sim > 0.7) fuzzyScore += sim * 0.5;
      }
    }

    return (jaccard * 0.7 + fuzzyScore * 0.3).clamp(0.0, 1.0);
  }

  double _levenshteinSimilarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty) return 0.0;
    if (b.isEmpty) return 0.0;

    final maxLen = max(a.length, b.length);
    if (maxLen == 0) return 1.0;

    final distance = _levenshteinDistance(a, b);
    return 1.0 - (distance / maxLen);
  }

  int _levenshteinDistance(String a, String b) {
    final m = a.length;
    final n = b.length;

    final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));

    for (int i = 0; i <= m; i++) dp[i][0] = i;
    for (int j = 0; j <= n; j++) dp[0][j] = j;

    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        dp[i][j] = [
          dp[i - 1][j] + 1,
          dp[i][j - 1] + 1,
          dp[i - 1][j - 1] + cost,
        ].reduce(min);
      }
    }

    return dp[m][n];
  }

  static T _randomItem<T>(List<T> items) {
    return items[Random().nextInt(items.length)];
  }
}
