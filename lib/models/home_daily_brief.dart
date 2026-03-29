import 'dart:convert';

enum HomeDailyBriefStatus {
  ready,
  empty,
  unavailable,
  failed,
}

enum HomeDailyBriefItemType {
  followUp('follow_up'),
  milestone('milestone'),
  pendingAction('pending_action'),
  scheduleFocus('schedule_focus');

  const HomeDailyBriefItemType(this.value);

  final String value;

  static HomeDailyBriefItemType fromValue(String value) {
    return HomeDailyBriefItemType.values.firstWhere(
      (item) => item.value == value,
      orElse: () => throw FormatException('Unsupported brief item type: $value'),
    );
  }
}

enum HomeDailyBriefActionType {
  openContact('open_contact'),
  openEvent('open_event'),
  openTodos('open_todos'),
  openEventsToday('open_events_today'),
  openSummaries('open_summaries'),
  createFollowUpEvent('create_follow_up_event');

  const HomeDailyBriefActionType(this.value);

  final String value;

  static HomeDailyBriefActionType fromValue(String value) {
    return HomeDailyBriefActionType.values.firstWhere(
      (item) => item.value == value,
      orElse: () => throw FormatException('Unsupported brief action type: $value'),
    );
  }
}

class HomeDailyBriefItem {
  final HomeDailyBriefItemType type;
  final String title;
  final String reason;
  final HomeDailyBriefActionType primaryAction;
  final String? primaryTargetId;
  final HomeDailyBriefActionType? secondaryAction;
  final String? secondaryTargetId;

  const HomeDailyBriefItem({
    required this.type,
    required this.title,
    required this.reason,
    required this.primaryAction,
    this.primaryTargetId,
    this.secondaryAction,
    this.secondaryTargetId,
  });

  factory HomeDailyBriefItem.fromJson(Map<String, dynamic> json) {
    final title = (json['title'] as String?)?.trim();
    final reason = (json['reason'] as String?)?.trim();
    final primaryActionValue = (json['primaryAction'] as String?)?.trim();
    final typeValue = (json['type'] as String?)?.trim();

    if (title == null || title.isEmpty) {
      throw const FormatException('Brief item title is required');
    }
    if (reason == null || reason.isEmpty) {
      throw const FormatException('Brief item reason is required');
    }
    if (typeValue == null || typeValue.isEmpty) {
      throw const FormatException('Brief item type is required');
    }
    if (primaryActionValue == null || primaryActionValue.isEmpty) {
      throw const FormatException('Brief item primary action is required');
    }

    final secondaryActionValue = (json['secondaryAction'] as String?)?.trim();

    return HomeDailyBriefItem(
      type: HomeDailyBriefItemType.fromValue(typeValue),
      title: title,
      reason: reason,
      primaryAction: HomeDailyBriefActionType.fromValue(primaryActionValue),
      primaryTargetId: (json['primaryTargetId'] as String?)?.trim(),
      secondaryAction: secondaryActionValue == null || secondaryActionValue.isEmpty
          ? null
          : HomeDailyBriefActionType.fromValue(secondaryActionValue),
      secondaryTargetId: (json['secondaryTargetId'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      'title': title,
      'reason': reason,
      'primaryAction': primaryAction.value,
      'primaryTargetId': primaryTargetId,
      'secondaryAction': secondaryAction?.value,
      'secondaryTargetId': secondaryTargetId,
    };
  }
}

class HomeDailyBrief {
  final HomeDailyBriefStatus status;
  final String? summary;
  final List<HomeDailyBriefItem> items;
  final DateTime? generatedAt;
  final String? aiJobId;
  final String? errorMessage;
  final bool fromCache;

  const HomeDailyBrief({
    required this.status,
    this.summary,
    this.items = const [],
    this.generatedAt,
    this.aiJobId,
    this.errorMessage,
    this.fromCache = false,
  });

  factory HomeDailyBrief.fromJson(
    Map<String, dynamic> json, {
    DateTime? generatedAt,
    String? aiJobId,
    bool fromCache = false,
  }) {
    final rawItems = json['items'];
    if (rawItems is! List) {
      throw const FormatException('Brief items must be a list');
    }

    final summary = (json['summary'] as String?)?.trim();
    final items = rawItems
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException('Brief item must be an object');
          }
          return HomeDailyBriefItem.fromJson(item);
        })
        .toList(growable: false);

    return HomeDailyBrief(
      status: items.isEmpty
          ? HomeDailyBriefStatus.empty
          : HomeDailyBriefStatus.ready,
      summary: summary,
      items: items,
      generatedAt: generatedAt,
      aiJobId: aiJobId,
      fromCache: fromCache,
    );
  }

  factory HomeDailyBrief.fromJsonString(
    String rawJson, {
    DateTime? generatedAt,
    String? aiJobId,
    bool fromCache = false,
  }) {
    final normalized = rawJson.trim();
    final decoded = jsonDecode(
      normalized.startsWith('```') ? _unwrapCodeFence(normalized) : normalized,
    );
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Brief payload must be a JSON object');
    }

    return HomeDailyBrief.fromJson(
      decoded,
      generatedAt: generatedAt,
      aiJobId: aiJobId,
      fromCache: fromCache,
    );
  }

  factory HomeDailyBrief.unavailable({String? summary}) {
    return HomeDailyBrief(
      status: HomeDailyBriefStatus.unavailable,
      summary: summary,
    );
  }

  factory HomeDailyBrief.failed(String message) {
    return HomeDailyBrief(
      status: HomeDailyBriefStatus.failed,
      errorMessage: message,
    );
  }

  factory HomeDailyBrief.empty({
    String? summary,
    DateTime? generatedAt,
    String? aiJobId,
    bool fromCache = false,
  }) {
    return HomeDailyBrief(
      status: HomeDailyBriefStatus.empty,
      summary: summary,
      generatedAt: generatedAt,
      aiJobId: aiJobId,
      fromCache: fromCache,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      'items': items.map((item) => item.toJson()).toList(growable: false),
    };
  }

  HomeDailyBrief copyWith({
    HomeDailyBriefStatus? status,
    String? summary,
    List<HomeDailyBriefItem>? items,
    DateTime? generatedAt,
    String? aiJobId,
    String? errorMessage,
    bool? fromCache,
  }) {
    return HomeDailyBrief(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      items: items ?? this.items,
      generatedAt: generatedAt ?? this.generatedAt,
      aiJobId: aiJobId ?? this.aiJobId,
      errorMessage: errorMessage ?? this.errorMessage,
      fromCache: fromCache ?? this.fromCache,
    );
  }

  static String _unwrapCodeFence(String value) {
    final lines = value.split('\n');
    if (lines.isEmpty) {
      return value;
    }

    final filtered = List<String>.from(lines);
    if (filtered.first.trim().startsWith('```')) {
      filtered.removeAt(0);
    }
    if (filtered.isNotEmpty && filtered.last.trim() == '```') {
      filtered.removeLast();
    }
    return filtered.join('\n');
  }
}