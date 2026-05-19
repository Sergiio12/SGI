import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/note.dart';
import '../models/tag.dart';
import '../providers/tags_provider.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const NoteCard({
    super.key,
    required this.note,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final typeLabel = note.type == NoteType.freeform ? 'Nota libre' : note.type == NoteType.checklist ? 'Checklist' : 'Lista';

    return Semantics(
      label: '${note.title}, $typeLabel',
      child: Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: BrainTheme.borderDark.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      color: BrainTheme.cardDark,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              if (note.content.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildContentPreview(),
              ],
              const SizedBox(height: 12),
              _buildMetaRow(),
              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildTagRow(),
              ],
            ],
          ),
        ),
      ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(
        begin: 0.1, end: 0, curve: Curves.easeOut);
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: BrainTheme.surfaceDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child:
                Text(note.emoji, style: const TextStyle(fontSize: 20)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                  color: BrainTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              if (note.notebook.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.folder_outlined,
                        size: 11, color: BrainTheme.textTertiary),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        note.notebook,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: BrainTheme.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        if (note.isPinned)
          Icon(Icons.push_pin,
              size: 16, color: BrainTheme.accentOrange),
      ],
    );
  }

  Widget _buildContentPreview() {
    return Text(
      note.content,
      style: TextStyle(
        fontSize: 13,
        color: BrainTheme.textSecondary,
        height: 1.4,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMetaRow() {
    return Row(
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _NoteTypeBadge(type: note.type),
              if (note.attachments.isNotEmpty) ...[
                const SizedBox(width: 8),
                _MetaBadge(
                  icon: Icons.attach_file,
                  label: '${note.attachments.length}',
                  color: BrainTheme.accentCyan,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          DateFormat('d MMM, HH:mm').format(note.updatedAt),
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: BrainTheme.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildTagRow() {
    return Consumer<TagsProvider>(builder: (context, tp, _) {
      final tags = note.tags
          .map((id) => tp.getById(id))
          .whereType<Tag>()
          .take(3)
          .toList();
      final remaining = note.tags.length - tags.length;

      if (tags.isEmpty) return const SizedBox.shrink();

      return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          ...tags.map(
            (tag) => Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: tag.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: tag.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    tag.name,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: tag.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (remaining > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: BrainTheme.surfaceDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+$remaining',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: BrainTheme.textTertiary,
                ),
              ),
            ),
        ],
      );
    });
  }
}

class _NoteTypeBadge extends StatelessWidget {
  final NoteType type;

  const _NoteTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;
    switch (type) {
      case NoteType.freeform:
        label = 'Nota libre';
        color = BrainTheme.accentBlue;
      case NoteType.checklist:
        label = 'Checklist';
        color = BrainTheme.accentGreen;
      case NoteType.journal:
        label = 'Diario';
        color = BrainTheme.accentPurple;
      case NoteType.reference:
        label = 'Referencia';
        color = BrainTheme.accentOrange;
      case NoteType.meetingNotes:
        label = 'Reunion';
        color = BrainTheme.accentCyan;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
            fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 10, color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
