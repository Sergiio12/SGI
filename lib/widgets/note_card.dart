import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../models/note.dart';

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
    return Card(
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
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: BrainTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(note.emoji, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
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
                  ),
                  if (note.isPinned)
                    Icon(
                      Icons.push_pin,
                      size: 18,
                      color: BrainTheme.accentOrange,
                    ),
                ],
              ),
              if (note.content.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  note.content,
                  style: TextStyle(
                    fontSize: 13,
                    color: BrainTheme.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 14),
              if (note.notebook.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.folder_outlined, size: 12, color: BrainTheme.textTertiary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        note.notebook,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: BrainTheme.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _NoteTypeBadge(type: note.type),
                  Text(
                    DateFormat('dd MMM, HH:mm').format(note.updatedAt),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: BrainTheme.textTertiary,
                    ),
                  ),
                ],
              ),
              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: note.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: BrainTheme.accentPurple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: BrainTheme.accentPurple,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
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
        style:
            TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
