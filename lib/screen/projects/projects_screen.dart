import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/projects_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/project_card.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectsProvider>(
      builder: (context, provider, _) {
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

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (provider.activeProjects.isNotEmpty) ...[
              _SectionLabel('Activos (${provider.activeProjects.length})'),
              ...provider.activeProjects.map(
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
            if (provider.pausedProjects.isNotEmpty) ...[
              _SectionLabel('Pausados (${provider.pausedProjects.length})'),
              ...provider.pausedProjects.map(
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
            if (provider.completedProjects.isNotEmpty) ...[
              _SectionLabel(
                'Finalizados (${provider.completedProjects.length})',
              ),
              ...provider.completedProjects.map(
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
            if (provider.abandonedProjects.isNotEmpty) ...[
              _SectionLabel(
                'Abandonados (${provider.abandonedProjects.length})',
              ),
              ...provider.abandonedProjects.map(
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
            const SizedBox(height: 100),
          ],
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE6EDF3),
        ),
      ),
    );
  }
}
