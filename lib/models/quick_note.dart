import 'dart:convert';

import 'package:kongo/services/quick_capture_parser.dart';

/// 一条 Quick Capture 笔记，对应 quick_notes 表。
class QuickNote {
  final String id;
  final String content;
  final QuickNoteType noteType;
  final String? linkedContactId;
  final String? linkedEventId;
  final String? sessionGroup;
  final Map<String, dynamic>? aiMetadata;
  final DateTime? enrichedAt;
  final DateTime captureDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const QuickNote({
    required this.id,
    required this.content,
    required this.noteType,
    this.linkedContactId,
    this.linkedEventId,
    this.sessionGroup,
    this.aiMetadata,
    this.enrichedAt,
    required this.captureDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory QuickNote.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? parsedAiMetadata;
    final rawMeta = map['aiMetadata'];
    if (rawMeta is String && rawMeta.isNotEmpty) {
      try {
        parsedAiMetadata = json.decode(rawMeta) as Map<String, dynamic>;
      } catch (_) {}
    }

    return QuickNote(
      id: map['id'] as String,
      content: map['content'] as String,
      noteType: map['noteType'] == 'structured'
          ? QuickNoteType.structured
          : QuickNoteType.knowledge,
      linkedContactId: map['linkedContactId'] as String?,
      linkedEventId: map['linkedEventId'] as String?,
      sessionGroup: map['sessionGroup'] as String?,
      aiMetadata: parsedAiMetadata,
      enrichedAt: map['enrichedAt'] != null
          ? DateTime.tryParse(map['enrichedAt'] as String)
          : null,
      captureDate: DateTime.parse(map['captureDate'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'noteType': noteType == QuickNoteType.structured ? 'structured' : 'knowledge',
      'linkedContactId': linkedContactId,
      'linkedEventId': linkedEventId,
      'sessionGroup': sessionGroup,
      'aiMetadata': aiMetadata != null ? json.encode(aiMetadata) : null,
      'enrichedAt': enrichedAt?.toIso8601String(),
      'captureDate':
          '${captureDate.year.toString().padLeft(4, '0')}-${captureDate.month.toString().padLeft(2, '0')}-${captureDate.day.toString().padLeft(2, '0')}',
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  QuickNote copyWith({
    String? linkedContactId,
    String? linkedEventId,
    Map<String, dynamic>? aiMetadata,
    DateTime? enrichedAt,
    DateTime? updatedAt,
  }) {
    return QuickNote(
      id: id,
      content: content,
      noteType: noteType,
      linkedContactId: linkedContactId ?? this.linkedContactId,
      linkedEventId: linkedEventId ?? this.linkedEventId,
      sessionGroup: sessionGroup,
      aiMetadata: aiMetadata ?? this.aiMetadata,
      enrichedAt: enrichedAt ?? this.enrichedAt,
      captureDate: captureDate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
