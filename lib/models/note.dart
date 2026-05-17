import 'brain_item.dart';

enum NoteType { freeform, checklist, journal, reference, meetingNotes }

class Note extends BrainItem {
  final String title;
  final String content;
  final List<NoteAttachment> attachments;
  final NoteType type;
  final String notebook;
  final String? projectId;
  final List<String> linkedTaskIds;
  final List<String> linkedNoteIds;
  final bool isPinned;
  final int colorValue;
  final String emoji;

  Note({
    required super.id,
    required this.title,
    this.content = '',
    this.attachments = const [],
    this.type = NoteType.freeform,
    this.notebook = 'General',
    this.projectId,
    this.linkedTaskIds = const [],
    this.linkedNoteIds = const [],
    this.isPinned = false,
    this.colorValue = 0xFF1E1E2E,
    this.emoji = '📝',
    super.tags = const [],
    required super.createdAt,
    required super.updatedAt,
  });

  Note copyWith({
    String? title,
    String? content,
    List<NoteAttachment>? attachments,
    NoteType? type,
    String? notebook,
    String? projectId,
    List<String>? linkedTaskIds,
    List<String>? linkedNoteIds,
    bool? isPinned,
    int? colorValue,
    String? emoji,
    List<String>? tags,
    bool clearProjectId = false,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      attachments: attachments ?? this.attachments,
      type: type ?? this.type,
      notebook: notebook ?? this.notebook,
      projectId: clearProjectId ? null : (projectId ?? this.projectId),
      linkedTaskIds: linkedTaskIds ?? this.linkedTaskIds,
      linkedNoteIds: linkedNoteIds ?? this.linkedNoteIds,
      isPinned: isPinned ?? this.isPinned,
      colorValue: colorValue ?? this.colorValue,
      emoji: emoji ?? this.emoji,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'attachments': attachments.map((a) => a.toJson()).toList(),
        'type': type.index,
        'notebook': notebook,
        'projectId': projectId,
        'linkedTaskIds': linkedTaskIds,
        'linkedNoteIds': linkedNoteIds,
        'isPinned': isPinned,
        'colorValue': colorValue,
        'emoji': emoji,
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'],
        title: json['title'],
        content: json['content'] ?? '',
        attachments: (json['attachments'] as List<dynamic>?)
                ?.map((a) =>
                    NoteAttachment.fromJson(Map<String, dynamic>.from(a)))
                .toList() ??
            [],
        type: NoteType.values[json['type'] ?? 0],
        notebook: json['notebook'] ?? 'General',
        projectId: json['projectId'],
        linkedTaskIds: List<String>.from(json['linkedTaskIds'] ?? []),
        linkedNoteIds: List<String>.from(json['linkedNoteIds'] ?? []),
        isPinned: json['isPinned'] ?? false,
        colorValue: json['colorValue'] ?? 0xFF1E1E2E,
        emoji: json['emoji'] ?? '📝',
        tags: List<String>.from(json['tags'] ?? []),
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );
}

class NoteAttachment {
  final String id;
  final String fileName;
  final String path;
  final int size;

  NoteAttachment({
    required this.id,
    required this.fileName,
    required this.path,
    required this.size,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'path': path,
        'size': size,
      };

  factory NoteAttachment.fromJson(Map<String, dynamic> json) => NoteAttachment(
        id: json['id'],
        fileName: json['fileName'],
        path: json['path'],
        size: json['size'] ?? 0,
      );
}
