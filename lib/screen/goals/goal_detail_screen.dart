import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/goal.dart';
import '../../utils/notification_service_v2.dart';
import '../../providers/goals_provider.dart';
import '../../providers/projects_provider.dart';

class GoalDetailScreen extends StatefulWidget {
  final String? goalId;

  const GoalDetailScreen({super.key, this.goalId});

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _metricController = TextEditingController(text: 'Progreso');
  final _targetController = TextEditingController(text: '100');
  final _currentController = TextEditingController(text: '0');

  GoalHorizon _horizon = GoalHorizon.quarterly;
  int _colorValue = BrainTheme.accentPurple.toARGB32();
  List<String> _projectIds = [];

  bool get _isEditing => widget.goalId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final goal = context.read<GoalsProvider>().getGoalById(widget.goalId!);
        if (goal != null) {
          setState(() {
            _titleController.text = goal.title;
            _descriptionController.text = goal.description;
            _metricController.text = goal.metricLabel;
            _targetController.text = _formatNumber(goal.targetValue);
            _currentController.text = _formatNumber(goal.currentValue);
            _horizon = goal.horizon;
            _colorValue = goal.colorValue;
            _projectIds = List.from(goal.projectIds);
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _metricController.dispose();
    _targetController.dispose();
    _currentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      showWarningNotification('El objetivo necesita un nombre');
      return;
    }

    final goalsProvider = context.read<GoalsProvider>();
    final projectsProvider = context.read<ProjectsProvider>();
    final target = _readDouble(_targetController.text, 100);
    final current = _readDouble(_currentController.text, 0);

    late final String savedGoalId;
    if (_isEditing) {
      final goal = goalsProvider.getGoalById(widget.goalId!);
      if (goal == null) return;
      savedGoalId = goal.id;
      await goalsProvider.updateGoal(goal.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        horizon: _horizon,
        projectIds: _projectIds,
        metricLabel: _metricController.text.trim().isEmpty
            ? 'Progreso'
            : _metricController.text.trim(),
        targetValue: target,
        currentValue: current,
        colorValue: _colorValue,
      ));
    } else {
      final goal = await goalsProvider.addGoal(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        horizon: _horizon,
        projectIds: _projectIds,
        metricLabel: _metricController.text.trim().isEmpty
            ? 'Progreso'
            : _metricController.text.trim(),
        targetValue: target,
        currentValue: current,
        colorValue: _colorValue,
      );
      savedGoalId = goal.id;
    }

    for (final project in projectsProvider.projects) {
      final shouldBeLinked = _projectIds.contains(project.id);
      if (shouldBeLinked && project.goalId != savedGoalId) {
        await projectsProvider
            .updateProject(project.copyWith(goalId: savedGoalId));
      } else if (!shouldBeLinked && project.goalId == savedGoalId) {
        await projectsProvider
            .updateProject(project.copyWith(clearGoalId: true));
      }
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final progress = _readDouble(_currentController.text, 0) /
        _readDouble(_targetController.text, 100).clamp(1, double.infinity);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar objetivo' : 'Nuevo objetivo'),
        actions: [
          if (_isEditing)
            IconButton(
              icon:
                  const Icon(Icons.delete_outline, color: BrainTheme.accentRed),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: BrainTheme.cardDark,
                    title: const Text('Eliminar objetivo', style: TextStyle(color: BrainTheme.textPrimary)),
                    content: const Text('Se moverá a la papelera. ¿Deseas continuar?', style: TextStyle(color: BrainTheme.textSecondary)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(backgroundColor: BrainTheme.accentRed, foregroundColor: Colors.white),
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await context.read<GoalsProvider>().deleteGoal(widget.goalId!);
                  if (mounted) Navigator.pop(context);
                }
              },
            ),
          TextButton(
            onPressed: _save,
            child: const Text(
              'Guardar',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Color(_colorValue).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.track_changes_rounded,
                    color: Color(_colorValue),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Nombre del objetivo',
                      border: InputBorder.none,
                      filled: false,
                    ),
                    autofocus: !_isEditing,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              style: const TextStyle(
                fontSize: 14,
                color: BrainTheme.textSecondary,
              ),
              decoration: const InputDecoration(
                hintText: 'Descripcion...',
                border: InputBorder.none,
                filled: false,
              ),
              maxLines: null,
            ),
            const SizedBox(height: 16),
            const Text(
              'Horizonte',
              style: TextStyle(fontSize: 13, color: BrainTheme.textTertiary),
            ),
            const SizedBox(height: 8),
            SegmentedButton<GoalHorizon>(
              segments: const [
                ButtonSegment(
                  value: GoalHorizon.monthly,
                  icon: Icon(Icons.calendar_view_month),
                  label: Text('Mes'),
                ),
                ButtonSegment(
                  value: GoalHorizon.quarterly,
                  icon: Icon(Icons.view_week_outlined),
                  label: Text('Trim.'),
                ),
                ButtonSegment(
                  value: GoalHorizon.yearly,
                  icon: Icon(Icons.event_available_outlined),
                  label: Text('Ano'),
                ),
              ],
              selected: {_horizon},
              onSelectionChanged: (value) =>
                  setState(() => _horizon = value.first),
            ),
            const SizedBox(height: 18),
            const Text(
              'Color',
              style: TextStyle(fontSize: 13, color: BrainTheme.textTertiary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: BrainTheme.projectColors.map((color) {
                final isSelected = color == _colorValue;
                return GestureDetector(
                  onTap: () => setState(() => _colorValue = color),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(color),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 2.5)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Metrica de progreso',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: BrainTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _metricController,
                      decoration: const InputDecoration(labelText: 'Metrica'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _currentController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration:
                                const InputDecoration(labelText: 'Actual'),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _targetController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration:
                                const InputDecoration(labelText: 'Meta'),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0, 1).toDouble(),
                        minHeight: 8,
                        backgroundColor: BrainTheme.borderDark,
                        valueColor: AlwaysStoppedAnimation(Color(_colorValue)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Proyectos asociados',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: BrainTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Consumer<ProjectsProvider>(
              builder: (context, projectsProvider, _) {
                if (projectsProvider.projects.isEmpty) {
                  return const Text(
                    'No hay proyectos todavia.',
                    style: TextStyle(color: BrainTheme.textTertiary),
                  );
                }

                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: projectsProvider.projects.map((project) {
                    final isSelected = _projectIds.contains(project.id);
                    return FilterChip(
                      label: Text(project.title),
                      selected: isSelected,
                      avatar: Text(project.emoji),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _projectIds.add(project.id);
                          } else {
                            _projectIds.remove(project.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  double _readDouble(String value, double fallback) {
    return double.tryParse(value.trim().replaceAll(',', '.')) ?? fallback;
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}
