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
  final VoidCallback? onDelete;
  final VoidCallback? onTogglePin;
  final VoidCallback? onCopyContent;
  final VoidCallback? onShare;
  final VoidCallback? onMoveToNotebook;
  final String? searchQuery;
  final bool isSelected;
  final ValueChanged<bool>? onSelect;

  const NoteCard({
    super.key,
    required this.note,
    this.onTap,
    this.onLongPress,
    this.onDelete,
    this.onTogglePin,
    this.onCopyContent,
    this.onShare,
    this.onMoveToNotebook,
    this.searchQuery,
    this.isSelected = false,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final typeLabel = note.type == NoteType.freeform ? 'Nota libre' : note.type == NoteType.checklist ? 'Checklist' : 'Lista';
    final inSelectionMode = onSelect != null;

    Widget card = Semantics(
      label: '${note.title}, $typeLabel',
      child: Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? BrainTheme.accentOf(context)
              : BrainTheme.borderDark.withValues(alpha: 0.5),
          width: isSelected ? 2 : 1,
        ),
      ),
      color: isSelected ? BrainTheme.accentOf(context).withValues(alpha: 0.05) : BrainTheme.cardDark,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: inSelectionMode ? () => onSelect!(!isSelected) : onTap,
        onLongPress: inSelectionMode ? null : () => _showContextMenu(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(inSelectionMode),
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
    );

    if (!inSelectionMode) {
      card = card.animate().fadeIn(duration: 400.ms).slideY(
          begin: 0.1, end: 0, curve: Curves.easeOut);
    }

    if (onDelete != null && !inSelectionMode) {
      card = Dismissible(
        key: ValueKey('note_${note.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: BrainTheme.accentRed,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
        ),
        confirmDismiss: (_) async {
          onDelete?.call();
          return false;
        },
        child: card,
      );
    }

    return card;
  }

  Widget _highlightedText(String text, double fontSize, Color color, {FontWeight? fontWeight, int? maxLines}) {
    if (searchQuery == null || searchQuery!.isEmpty || !text.toLowerCase().contains(searchQuery!)) {
      return Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: fontSize, color: color, fontWeight: fontWeight),
      );
    }
    final query = searchQuery!;
    final lower = text.toLowerCase();
    final queryLower = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    int index;
    while ((index = lower.indexOf(queryLower, start)) != -1) {
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: TextStyle(
          backgroundColor: Colors.yellowAccent.withValues(alpha: 0.3),
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ));
      start = index + query.length;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    return RichText(
      maxLines: maxLines ?? 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(style: TextStyle(fontSize: fontSize, color: color, fontWeight: fontWeight), children: spans),
    );
  }

  void _showContextMenu(BuildContext context) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(100, 100, 100, 100),
      color: BrainTheme.cardDark,
      items: [
        if (onTogglePin != null)
          PopupMenuItem(
            value: 'pin',
            child: Row(
              children: [
                Icon(note.isPinned ? Icons.push_pin : Icons.push_pin_outlined, size: 18, color: BrainTheme.textSecondary),
                const SizedBox(width: 10),
                Text(note.isPinned ? 'Desanclar' : 'Anclar'),
              ],
            ),
          ),
        if (onCopyContent != null)
          PopupMenuItem(
            value: 'copy',
            child: Row(
              children: [
                Icon(Icons.copy, size: 18, color: BrainTheme.textSecondary),
                const SizedBox(width: 10),
                const Text('Copiar contenido'),
              ],
            ),
          ),
        if (onShare != null)
          PopupMenuItem(
            value: 'share',
            child: Row(
              children: [
                Icon(Icons.share, size: 18, color: BrainTheme.textSecondary),
                const SizedBox(width: 10),
                const Text('Compartir'),
              ],
            ),
          ),
        if (onMoveToNotebook != null)
          PopupMenuItem(
            value: 'move',
            child: Row(
              children: [
                Icon(Icons.drive_file_move_outlined, size: 18, color: BrainTheme.textSecondary),
                const SizedBox(width: 10),
                const Text('Mover a cuaderno'),
              ],
            ),
          ),
        if (onDelete != null)
          const PopupMenuDivider(),
        if (onDelete != null)
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 18, color: BrainTheme.accentRed),
                const SizedBox(width: 10),
                Text('Eliminar', style: TextStyle(color: BrainTheme.accentRed)),
              ],
            ),
          ),
      ],
    ).then((value) {
      switch (value) {
        case 'pin': onTogglePin?.call();
        case 'copy': onCopyContent?.call();
        case 'share': onShare?.call();
        case 'move': onMoveToNotebook?.call();
        case 'delete': onDelete?.call();
      }
    });
  }

  Widget _buildHeader([bool inSelectionMode = false]) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (inSelectionMode)
          Padding(
            padding: const EdgeInsets.only(right: 8, top: 2),
            child: GestureDetector(
              onTap: () => onSelect!(!isSelected),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? BrainTheme.accentPurple : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? BrainTheme.accentPurple : BrainTheme.textTertiary,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
          ),
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
              _highlightedText(
                note.title,
                16,
                BrainTheme.textPrimary,
                fontWeight: FontWeight.w600,
                maxLines: 1,
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
        if (!inSelectionMode && note.isPinned)
          Icon(Icons.push_pin,
              size: 16, color: BrainTheme.accentOrange),
      ],
    );
  }

  Widget _buildContentPreview() {
    return _highlightedText(
      note.content,
      13,
      BrainTheme.textSecondary,
      maxLines: 3,
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
        color = BrainTheme.accentOf(context);
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
