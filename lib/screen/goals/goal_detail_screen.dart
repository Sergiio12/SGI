import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:second_brain/l10n/app_localizations.dart';

import '../../config/theme.dart';
import '../../models/goal.dart';
import '../../models/project.dart';
import '../../models/tag.dart';
import '../../utils/notification_service_v2.dart';
import '../../providers/goals_provider.dart';
import '../../providers/projects_provider.dart';
import '../../providers/tags_provider.dart';

class GoalDetailScreen extends StatefulWidget {
  final String? goalId;

  const GoalDetailScreen({super.key, this.goalId});

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _isEditing = false;
  late TabController _tabController;

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _metricController;
  late TextEditingController _targetController;
  late TextEditingController _currentController;

  GoalHorizon _horizon = GoalHorizon.quarterly;
  int _colorValue = BrainTheme.accentPurple.toARGB32();
  List<String> _projectIds = [];
  List<String> _tagIds = [];

  bool get _isNew => widget.goalId == null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _metricController = TextEditingController(text: 'Progreso');
    _targetController = TextEditingController(text: '100');
    _currentController = TextEditingController(text: '0');

    if (!_isNew) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadGoal();
      });
    } else {
      _isEditing = true;
    }
  }

  void _loadGoal() {
    final goal = context.read<GoalsProvider>().getGoalById(widget.goalId!);
    if (goal == null) return;
    setState(() {
      _titleController.text = goal.title;
      _descriptionController.text = goal.description;
      _metricController.text = goal.metricLabel;
      _targetController.text = _formatNumber(goal.targetValue);
      _currentController.text = _formatNumber(goal.currentValue);
      _horizon = goal.horizon;
      _colorValue = goal.colorValue;
      _projectIds = List.from(goal.projectIds);
      _tagIds = List.from(goal.tags);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _metricController.dispose();
    _targetController.dispose();
    _currentController.dispose();
    super.dispose();
  }

  double get _progress {
    final target = _readDouble(_targetController.text, 100);
    final current = _readDouble(_currentController.text, 0);
    if (target <= 0) return 0;
    return (current / target).clamp(0, 1);
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      showWarningNotification(AppLocalizations.of(context).goalNeedsName);
      return;
    }

    final goalsProvider = context.read<GoalsProvider>();
    final projectsProvider = context.read<ProjectsProvider>();
    final target = _readDouble(_targetController.text, 100);
    final current = _readDouble(_currentController.text, 0);

    late final String savedGoalId;
    if (_isNew) {
      final result = await goalsProvider.addGoal(
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
        tags: _tagIds,
      );
      if (result.isFailure) return;
      final goal = result.unwrap();
      savedGoalId = goal.id;
    } else {
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
        tags: _tagIds,
      ));
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

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BrainTheme.cardDark,
        title: Text(l10n.editGoal,
            style: TextStyle(color: BrainTheme.textPrimary)),
        content: Text(
          l10n.moveToTrashContent,
          style: TextStyle(color: BrainTheme.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: BrainTheme.accentRed,
                foregroundColor: Colors.white),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await context.read<GoalsProvider>().deleteGoal(widget.goalId!);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(_colorValue);

    return Scaffold(
      body: _isEditing ? _buildFormView(color) : _buildDetailView(color),
      bottomNavigationBar: _isEditing ? null : _buildViewBottomBar(),
    );
  }

  Widget _buildDetailView(Color color) {
    return Consumer2<GoalsProvider, ProjectsProvider>(
      builder: (context, goalsProvider, projectsProvider, _) {
        final goal = goalsProvider.getGoalById(widget.goalId!);
        if (goal == null) {
          return Center(child: Text(AppLocalizations.of(context).noData));
        }

        final linkedProjects = projectsProvider.getProjectsByGoal(goal.id);

        return CustomScrollView(
          slivers: [
            _HeaderSliver(
              goal: goal,
              color: color,
              onEdit: () => setState(() => _isEditing = true),
              onDelete: _delete,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProgressCard(goal, color),
                    const SizedBox(height: 16),
                    _buildQuickActions(goal, color, goalsProvider),
                    const SizedBox(height: 16),
                    TabBar(
                      controller: _tabController,
                      labelColor: color,
                      unselectedLabelColor: BrainTheme.textTertiary,
                      indicatorColor: color,
                      tabs: [
                        Tab(text: AppLocalizations.of(context).details),
                        Tab(text: AppLocalizations.of(context).projects),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _InfoTab(goal: goal, color: color),
                  _ProjectsTab(projects: linkedProjects, color: color),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProgressCard(Goal goal, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BrainTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.metricLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: BrainTheme.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_compact(goal.currentValue)} / ${_compact(goal.targetValue)}',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: BrainTheme.textPrimary,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: goal.progress,
                        strokeWidth: 6,
                        backgroundColor: BrainTheme.borderDark,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    Text(
                      '${(goal.progress * 100).round()}%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 6,
              backgroundColor: BrainTheme.borderDark,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildQuickActions(Goal goal, Color color, GoalsProvider provider) {
    return Row(
      children: [
        _ActionChip(
          icon: Icons.add,
          label: AppLocalizations.of(context).goalAddProgress,
          color: color,
          onTap: () => _showAddProgressDialog(goal, provider),
        ),
        const SizedBox(width: 8),
        _ActionChip(
          icon: Icons.edit_outlined,
          label: AppLocalizations.of(context).editGoal,
          color: BrainTheme.accentBlue,
          onTap: () => setState(() => _isEditing = true),
        ),
      ],
    );
  }

  void _showAddProgressDialog(Goal goal, GoalsProvider provider) {
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BrainTheme.cardDark,
        title: Text(l10n.goalAddProgress,
            style: TextStyle(color: BrainTheme.textPrimary)),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.goalAmountToAdd,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final amount = double.tryParse(
                      controller.text.trim().replaceAll(',', '.')) ??
                  0;
              if (amount > 0) {
                final updated = goal.copyWith(
                  currentValue: goal.currentValue + amount,
                );
                provider.updateGoal(updated);
              }
              Navigator.pop(ctx);
            },
            child: Text(l10n.goalAdd),
          ),
        ],
      ),
    );
  }

  Widget _buildViewBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: BrainTheme.primaryDark,
        border: Border(
          top: BorderSide(color: BrainTheme.borderDark, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: () => _saveProgress(),
            icon: const Icon(Icons.trending_up_rounded, size: 18),
            label: Text(AppLocalizations.of(context).goalUpdateProgress,
                style: TextStyle(fontWeight: FontWeight.w600)),
            style: FilledButton.styleFrom(
              backgroundColor: Color(_colorValue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveProgress() async {
    final goalsProvider = context.read<GoalsProvider>();
    final goal = goalsProvider.getGoalById(widget.goalId!);
    if (goal == null) return;

    _showAddProgressDialog(goal, goalsProvider);
  }

  Widget _buildFormView(Color color) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew
            ? AppLocalizations.of(context).createGoal
            : AppLocalizations.of(context).editGoal),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (_isNew) {
              Navigator.pop(context);
            } else {
              setState(() => _isEditing = false);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              AppLocalizations.of(context).save,
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
                GestureDetector(
                  onTap: () => _showColorPicker(),
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.track_changes_rounded,
                      color: color,
                    ),
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
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context).goalNameHint,
                      border: InputBorder.none,
                      filled: false,
                    ),
                    autofocus: _isNew,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              style: TextStyle(
                fontSize: 14,
                color: BrainTheme.textSecondary,
              ),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).description,
                border: InputBorder.none,
                filled: false,
              ),
              maxLines: null,
            ),
            const SizedBox(height: 20),
            _buildSectionLabel(AppLocalizations.of(context).horizon),
            const SizedBox(height: 10),
            SegmentedButton<GoalHorizon>(
              segments: [
                ButtonSegment(
                  value: GoalHorizon.monthly,
                  icon: const Icon(Icons.calendar_view_month),
                  label: Text(AppLocalizations.of(context).goalMonthly),
                ),
                ButtonSegment(
                  value: GoalHorizon.quarterly,
                  icon: const Icon(Icons.view_week_outlined),
                  label: Text(AppLocalizations.of(context).goalQuarterly),
                ),
                ButtonSegment(
                  value: GoalHorizon.yearly,
                  icon: const Icon(Icons.event_available_outlined),
                  label: Text(AppLocalizations.of(context).goalYearly),
                ),
              ],
              selected: {_horizon},
              onSelectionChanged: (value) =>
                  setState(() => _horizon = value.first),
            ),
            const SizedBox(height: 20),
            _buildSectionLabel(AppLocalizations.of(context).color),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: BrainTheme.projectColors.map((c) {
                final isSelected = c == _colorValue;
                return GestureDetector(
                  onTap: () => setState(() => _colorValue = c),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(c),
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
            const SizedBox(height: 24),
            _buildSectionLabel(AppLocalizations.of(context).tags),
            const SizedBox(height: 10),
            Consumer<TagsProvider>(
              builder: (context, tagsProvider, _) {
                final allTags = tagsProvider.tags;
                if (allTags.isEmpty) {
                  return Text(
                    AppLocalizations.of(context).goalNoTagsAvailable,
                    style:
                        TextStyle(color: BrainTheme.textTertiary, fontSize: 13),
                  );
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: allTags.map((tag) {
                    final selected = _tagIds.contains(tag.id);
                    return FilterChip(
                      label: Text(tag.name),
                      selected: selected,
                      avatar: CircleAvatar(
                        backgroundColor: tag.color,
                        radius: 6,
                      ),
                      onSelected: (s) {
                        setState(() {
                          if (s) {
                            _tagIds.add(tag.id);
                          } else {
                            _tagIds.remove(tag.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).goalProgressMetric,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: BrainTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _metricController,
                      decoration: InputDecoration(
                          labelText: AppLocalizations.of(context).metric),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _currentController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                                labelText:
                                    AppLocalizations.of(context).goalCurrent),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _targetController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                                labelText:
                                    AppLocalizations.of(context).goalTarget),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 8,
                        backgroundColor: BrainTheme.borderDark,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${(_progress * 100).round()}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionLabel(AppLocalizations.of(context).goalLinkedProjects),
            const SizedBox(height: 10),
            Consumer<ProjectsProvider>(
              builder: (context, projectsProvider, _) {
                final allProjects = projectsProvider.projects;
                final selectedProjects =
                    allProjects.where((p) => _projectIds.contains(p.id)).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (selectedProjects.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: selectedProjects.map((project) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Color(project.colorValue)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Color(project.colorValue)
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(project.emoji, style: const TextStyle(fontSize: 14)),
                                  const SizedBox(width: 6),
                                  Text(
                                    project.title,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: BrainTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() => _projectIds.remove(project.id));
                                    },
                                    child: Icon(Icons.close, size: 14,
                                        color: BrainTheme.textTertiary),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    GestureDetector(
                      onTap: () => _showProjectPicker(allProjects,
                          selectedProjects.map((p) => p.id).toList()),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: BrainTheme.cardDark,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: BrainTheme.borderDark),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.add, size: 18,
                                color: BrainTheme.textTertiary),
                            const SizedBox(width: 8),
                            Text(
                              selectedProjects.isEmpty
                                  ? AppLocalizations.of(context).goalLinkedProjects
                                  : '${AppLocalizations.of(context).goalLinkedProjects} (${selectedProjects.length})',
                              style: TextStyle(
                                fontSize: 13,
                                color: BrainTheme.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: BrainTheme.textTertiary,
        letterSpacing: 0.3,
      ),
    );
  }

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: BrainTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16, left: 0),
              decoration: BoxDecoration(
                color: BrainTheme.textTertiary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              AppLocalizations.of(context).goalChooseColor,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: BrainTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: BrainTheme.projectColors.map((c) {
                final isSelected = c == _colorValue;
                return GestureDetector(
                  onTap: () {
                    setState(() => _colorValue = c);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Color(c).withValues(alpha: 0.4),
                                blurRadius: 12,
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 22, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showProjectPicker(List<Project> allProjects, List<String> currentIds) {
    final searchController = TextEditingController();
    var searchQuery = '';
    var selectedIds = currentIds.toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: BrainTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = searchQuery.isEmpty
                ? allProjects
                : allProjects.where((p) {
                    final q = searchQuery.toLowerCase();
                    return p.title.toLowerCase().contains(q);
                  }).toList();

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 16,
                  right: 16,
                  top: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: BrainTheme.textTertiary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    TextField(
                      controller: searchController,
                      autofocus: true,
                      onChanged: (v) =>
                          setModalState(() => searchQuery = v),
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context).searchInProjects,
                        prefixIcon:
                            const Icon(Icons.search, size: 20),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  searchController.clear();
                                  setModalState(() => searchQuery = '');
                                },
                              )
                            : null,
                        isDense: true,
                        filled: true,
                        fillColor: BrainTheme.cardDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              BorderSide(color: BrainTheme.borderDark),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          AppLocalizations.of(context).noResults,
                          style: TextStyle(
                            color: BrainTheme.textTertiary,
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final project = filtered[index];
                            final isSelected =
                                selectedIds.contains(project.id);
                            final pColor = Color(project.colorValue);
                            return ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color:
                                      pColor.withValues(alpha: 0.15),
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(project.emoji,
                                      style:
                                          const TextStyle(fontSize: 18)),
                                ),
                              ),
                              title: Text(
                                project.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: BrainTheme.textPrimary,
                                ),
                              ),
                              trailing: isSelected
                                  ? Icon(Icons.check_circle,
                                      color: pColor)
                                  : Icon(Icons.circle_outlined,
                                      color: BrainTheme.textTertiary),
                              onTap: () {
                                setModalState(() {
                                  if (isSelected) {
                                    selectedIds.remove(project.id);
                                  } else {
                                    selectedIds.add(project.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                                AppLocalizations.of(context).cancel),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() => _projectIds = selectedIds);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: BrainTheme.accentPurple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(AppLocalizations.of(context).save),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  double _readDouble(String value, double fallback) {
    return double.tryParse(value.trim().replaceAll(',', '.')) ?? fallback;
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  String _compact(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }
}

class _HeaderSliver extends StatelessWidget {
  final Goal goal;
  final Color color;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HeaderSliver({
    required this.goal,
    required this.color,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: BrainTheme.primaryDark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.edit_outlined, color: BrainTheme.textSecondary),
          onPressed: onEdit,
        ),
        IconButton(
          icon: Icon(Icons.delete_outline, color: BrainTheme.accentRed),
          onPressed: onDelete,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.25),
                BrainTheme.primaryDark,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: color.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.track_changes_rounded,
                          color: color,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        goal.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: BrainTheme.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _Badge(
                              label: _horizonLabel(context, goal.horizon),
                              color: color,
                            ),
                            const SizedBox(width: 8),
                            _Badge(
                              label: '${(goal.progress * 100).round()}%',
                              color: color,
                            ),
                            if (goal.tags.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Consumer<TagsProvider>(builder: (context, tp, _) {
                                final tag = goal.tags
                                    .map((id) => tp.getById(id))
                                    .whereType<Tag>()
                                    .firstOrNull;
                                if (tag == null) {
                                  return const SizedBox.shrink();
                                }
                                return _Badge(
                                  label: tag.name,
                                  color: tag.color,
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _horizonLabel(BuildContext context, GoalHorizon horizon) {
    final l10n = AppLocalizations.of(context);
    switch (horizon) {
      case GoalHorizon.monthly:
        return l10n.goalMonthly;
      case GoalHorizon.quarterly:
        return l10n.goalQuarterly;
      case GoalHorizon.yearly:
        return l10n.goalYearly;
    }
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _InfoTab extends StatelessWidget {
  final Goal goal;
  final Color color;

  const _InfoTab({required this.goal, required this.color});

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        if (goal.description.isNotEmpty) ...[
          _InfoCard(
            icon: Icons.description_outlined,
            title: AppLocalizations.of(context).description,
            child: Text(
              goal.description,
              style: TextStyle(
                fontSize: 14,
                color: BrainTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        _InfoCard(
          icon: Icons.track_changes_rounded,
          title: AppLocalizations.of(context).details,
          child: Column(
            children: [
              _InfoRow(
                label: AppLocalizations.of(context).metric,
                value: goal.metricLabel,
              ),
              Divider(height: 1, color: BrainTheme.borderDark),
              _InfoRow(
                label: AppLocalizations.of(context).goalCurrent,
                value: _compact(goal.currentValue),
              ),
              Divider(height: 1, color: BrainTheme.borderDark),
              _InfoRow(
                label: AppLocalizations.of(context).goalTarget,
                value: _compact(goal.targetValue),
              ),
              Divider(height: 1, color: BrainTheme.borderDark),
              _InfoRow(
                label: AppLocalizations.of(context).goalsProgress,
                value: '${(goal.progress * 100).round()}%',
                valueColor: color,
              ),
              Divider(height: 1, color: BrainTheme.borderDark),
              _InfoRow(
                label: AppLocalizations.of(context).itemCreated,
                value: _formatDate(goal.createdAt),
              ),
              Divider(height: 1, color: BrainTheme.borderDark),
              _InfoRow(
                label: AppLocalizations.of(context).itemUpdated,
                value: _formatDate(goal.updatedAt),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _compact(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  String _formatDate(DateTime date) {
    final months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _ProjectsTab extends StatelessWidget {
  final List<Project> projects;
  final Color color;

  const _ProjectsTab({required this.projects, required this.color});

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open,
                size: 48,
                color: BrainTheme.textTertiary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).goalNoLinkedProjects,
              style: TextStyle(
                fontSize: 15,
                color: BrainTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final l10n = AppLocalizations.of(context);
        final project = projects[index];
        final pColor = Color(project.colorValue);
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          color: BrainTheme.cardDark,
          child: ListTile(
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: pColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child:
                    Text(project.emoji, style: const TextStyle(fontSize: 20)),
              ),
            ),
            title: Text(
              project.title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: BrainTheme.textPrimary,
              ),
            ),
            subtitle: Text(
              project.status == ProjectStatus.active
                  ? l10n.active
                  : project.status == ProjectStatus.paused
                      ? l10n.goalPaused
                      : project.status == ProjectStatus.completed
                          ? l10n.statusCompleted
                          : l10n.goalAbandoned,
              style: TextStyle(
                fontSize: 12,
                color: BrainTheme.textTertiary,
              ),
            ),
            trailing: Icon(Icons.chevron_right, color: BrainTheme.textTertiary),
            onTap: () => Navigator.pushNamed(
              context,
              '/project',
              arguments: project.id,
            ),
          ),
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: BrainTheme.cardDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: BrainTheme.textTertiary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: BrainTheme.textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: BrainTheme.textTertiary,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? BrainTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
