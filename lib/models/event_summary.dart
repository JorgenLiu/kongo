enum SummarySource { manual, ai, mixed }

extension SummarySourceValue on SummarySource {
  String get value {
    switch (this) {
      case SummarySource.manual:
        return 'manual';
      case SummarySource.ai:
        return 'ai';
      case SummarySource.mixed:
        return 'mixed';
    }
  }

  static SummarySource fromValue(String value) {
    return SummarySource.values.firstWhere(
      (source) => source.value == value,
      orElse: () => SummarySource.manual,
    );
  }
}

/// 每日总结摘要模型。
class DailySummary {
  final String id;
  final DateTime summaryDate;
  final String todaySummary;
  final String tomorrowPlan;
  final SummarySource source;
  final String? createdByContactId;
  final String? aiJobId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DailySummary({
    required this.id,
    required this.summaryDate,
    required this.todaySummary,
    required this.tomorrowPlan,
    this.source = SummarySource.manual,
    this.createdByContactId,
    this.aiJobId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DailySummary.fromMap(Map<String, dynamic> map) {
    return DailySummary(
      id: map['id'] as String,
      summaryDate: DateTime.fromMillisecondsSinceEpoch(
        (map['summaryDate'] as num).toInt(),
      ),
      todaySummary: map['todaySummary'] as String? ?? '',
      tomorrowPlan: map['tomorrowPlan'] as String? ?? '',
      source: SummarySourceValue.fromValue(
        map['source'] as String? ?? 'manual',
      ),
      createdByContactId: map['createdByContactId'] as String?,
      aiJobId: map['aiJobId'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['createdAt'] as num).toInt(),
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['updatedAt'] as num).toInt(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'summaryDate': summaryDate.millisecondsSinceEpoch,
      'todaySummary': todaySummary,
      'tomorrowPlan': tomorrowPlan,
      'source': source.value,
      'createdByContactId': createdByContactId,
      'aiJobId': aiJobId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  DailySummary copyWith({
    String? id,
    DateTime? summaryDate,
    String? todaySummary,
    String? tomorrowPlan,
    SummarySource? source,
    String? createdByContactId,
    String? aiJobId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailySummary(
      id: id ?? this.id,
      summaryDate: summaryDate ?? this.summaryDate,
      todaySummary: todaySummary ?? this.todaySummary,
      tomorrowPlan: tomorrowPlan ?? this.tomorrowPlan,
      source: source ?? this.source,
      createdByContactId: createdByContactId ?? this.createdByContactId,
      aiJobId: aiJobId ?? this.aiJobId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'DailySummary(id: $id, summaryDate: $summaryDate)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailySummary &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          summaryDate == other.summaryDate;

  @override
  int get hashCode => id.hashCode ^ summaryDate.hashCode;
}

typedef EventSummary = DailySummary;