import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/project.dart';

class TaskProjectSelector extends StatelessWidget {
  final List<Project> projects;
  final String? selectedProjectId;
  final String searchQuery;
  final ValueChanged<String?> onSelected;
  final ValueChanged<String> onSearchChanged;
  final String emptyLabel;
  final String searchHint;

  const TaskProjectSelector({
    required this.projects,
    required this.selectedProjectId,
    required this.searchQuery,
    required this.onSelected,
    required this.onSearchChanged,
    this.emptyLabel = 'Todos los proyectos',
    this.searchHint = 'Buscar proyecto...',
  });

  @override
  Widget build(BuildContext context) {
    Project? selectedProject;
    if (selectedProjectId != null) {
      try {
        selectedProject = projects.firstWhere((p) => p.id == selectedProjectId);
      } catch (_) {}
    }

    return GestureDetector(
      onTap: () => _showProjectPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: BrainTheme.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: BrainTheme.borderDark),
        ),
        child: Row(
          children: [
            Icon(Icons.folder_outlined,
                size: 16, color: BrainTheme.textTertiary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                selectedProject != null
                    ? '${selectedProject.emoji} ${selectedProject.title}'
                    : 'Todos los proyectos',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: selectedProject != null
                      ? Color(selectedProject.colorValue)
                      : BrainTheme.textSecondary,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down,
                size: 20, color: BrainTheme.textTertiary),
          ],
        ),
      ),
    );
  }

  void _showProjectPicker(BuildContext context) {
    FocusScope.of(context).unfocus();
    String localQuery = searchQuery;
      showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: BrainTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setS) {
            final filtered = localQuery.isEmpty
                ? projects
                : projects
                    .where((p) => p.title
                        .toLowerCase()
                        .contains(localQuery.toLowerCase()))
                    .toList();
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Seleccionar proyecto',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: BrainTheme.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close,
                                color: BrainTheme.textSecondary),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        onChanged: (v) => setS(() {
                          localQuery = v;
                          onSearchChanged(v);
                        }),
                        decoration: InputDecoration(
                          hintText: searchHint,
                          prefixIcon: const Icon(Icons.search, size: 18),
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                          filled: true,
                          fillColor: BrainTheme.cardDark,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: BrainTheme.borderDark),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          itemCount: filtered.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return ListTile(
                                dense: true,
                                leading: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: BrainTheme.accentOf(context)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.folder_off_outlined,
                                      size: 16, color: BrainTheme.accentOf(context)),
                                ),
                                title: Text(
                                  emptyLabel,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: selectedProjectId == null
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: BrainTheme.textPrimary,
                                  ),
                                ),
                                trailing: selectedProjectId == null
                                    ? Icon(Icons.check,
                                        size: 18, color: BrainTheme.accentGreen)
                                    : null,
                                onTap: () {
                                  onSelected(null);
                                  Navigator.pop(ctx);
                                },
                              );
                            }

                            final project = filtered[index - 1];
                            final isSelected = project.id == selectedProjectId;

                            return ListTile(
                              dense: true,
                              leading: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Color(project.colorValue)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(project.emoji,
                                      style: const TextStyle(fontSize: 16)),
                                ),
                              ),
                              title: Text(
                                project.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: BrainTheme.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                '${project.taskIds.length} tareas',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: BrainTheme.textTertiary,
                                ),
                              ),
                              trailing: isSelected
                                  ? Icon(Icons.check,
                                      size: 18, color: BrainTheme.accentGreen)
                                  : null,
                              onTap: () {
                                onSelected(project.id);
                                Navigator.pop(ctx);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
