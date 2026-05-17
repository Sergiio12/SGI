import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/projects_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/pagination_bar.dart';
import '../../widgets/project_card.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentPage = 0;
  static const int _pageSize = 10;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectsProvider>(
      builder: (context, provider, _) {
        var allProjects = provider.projects.where((project) {
          if (_searchQuery.isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          return project.title.toLowerCase().contains(q) ||
              project.description.toLowerCase().contains(q) ||
              project.objective.toLowerCase().contains(q);
        }).toList();

        if (provider.projects.isEmpty) {
          return EmptyState(
            emoji: '🚀',
            title: 'Sin proyectos aun',
            subtitle:
                'Crea un proyecto para agrupar tareas, notas y objetivos.',
            actionLabel: 'Crear proyecto',
            onAction: () => Navigator.pushNamed(context, '/project'),
          );
        }

        if (allProjects.isEmpty) {
          return Column(
            children: [
              _SearchBar(
                controller: _searchController,
                onChanged: (v) => setState(() {
                  _searchQuery = v;
                  _currentPage = 0;
                }),
                onClear: () => setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                }),
              ),
              Expanded(
                child: EmptyState(
                  emoji: '🔍',
                  title: 'Sin resultados',
                  subtitle:
                      'No hay proyectos que coincidan con "$_searchQuery"',
                ),
              ),
            ],
          );
        }

        final totalPages = (allProjects.length / _pageSize).ceil();
        final start = _currentPage * _pageSize;
        final end = (start + _pageSize).clamp(0, allProjects.length);
        final pageProjects = allProjects.sublist(start, end);

        final active = pageProjects
            .where((p) => p.status.name == 'active')
            .toList();
        final paused = pageProjects
            .where((p) => p.status.name == 'paused')
            .toList();
        final completed = pageProjects
            .where((p) => p.status.name == 'completed')
            .toList();
        final abandoned = pageProjects
            .where((p) => p.status.name == 'abandoned')
            .toList();

        return Column(
          children: [
            _SearchBar(
              controller: _searchController,
              onChanged: (v) => setState(() {
                _searchQuery = v;
                _currentPage = 0;
              }),
              onClear: () => setState(() {
                _searchController.clear();
                _searchQuery = '';
              }),
            ),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      children: [
                        if (active.isNotEmpty) ...[
                          _SectionLabel(
                              texto: 'Activos', count: active.length),
                          ...active.map(
                            (project) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: ProjectCard(
                                project: project,
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/project',
                                  arguments: project.id,
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (paused.isNotEmpty) ...[
                          _SectionLabel(
                              texto: 'Pausados', count: paused.length),
                          ...paused.map(
                            (project) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: ProjectCard(
                                project: project,
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/project',
                                  arguments: project.id,
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (completed.isNotEmpty) ...[
                          _SectionLabel(
                              texto: 'Finalizados', count: completed.length),
                          ...completed.map(
                            (project) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: ProjectCard(
                                project: project,
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/project',
                                  arguments: project.id,
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (abandoned.isNotEmpty) ...[
                          _SectionLabel(
                              texto: 'Abandonados',
                              count: abandoned.length),
                          ...abandoned.map(
                            (project) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: ProjectCard(
                                project: project,
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/project',
                                  arguments: project.id,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  PaginationBar(
                    currentPage: _currentPage,
                    totalPages: totalPages,
                    onPageChanged: (p) =>
                        setState(() => _currentPage = p),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Buscar proyectos...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: onClear,
                )
              : null,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String texto;
  final int count;

  const _SectionLabel({required this.texto, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: BrainTheme.accentPurple,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            texto,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: BrainTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: BrainTheme.accentPurple.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: BrainTheme.accentPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
