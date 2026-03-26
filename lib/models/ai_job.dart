/// AI 作业状态。
enum AiJobStatus { pending, running, completed, failed }

extension AiJobStatusValue on AiJobStatus {
  String get value {
    switch (this) {
      case AiJobStatus.pending:
        return 'pending';
      case AiJobStatus.running:
        return 'running';
      case AiJobStatus.completed:
        return 'completed';
      case AiJobStatus.failed:
        return 'failed';
    }
  }

  static AiJobStatus fromValue(String value) {
    return AiJobStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => AiJobStatus.pending,
    );
  }
}

/// AI 作业记录。
class AiJob {
  final String id;
  final String feature;
  final String provider;
  final String? model;
  final String targetType;
  final String targetId;
  final AiJobStatus status;
  final String? promptDigest;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? completedAt;

  const AiJob({
    required this.id,
    required this.feature,
    required this.provider,
    this.model,
    required this.targetType,
    required this.targetId,
    this.status = AiJobStatus.pending,
    this.promptDigest,
    this.errorMessage,
    required this.createdAt,
    this.completedAt,
  });

  factory AiJob.fromMap(Map<String, dynamic> map) {
    return AiJob(
      id: map['id'] as String,
      feature: map['feature'] as String,
      provider: map['provider'] as String,
      model: map['model'] as String?,
      targetType: map['targetType'] as String,
      targetId: map['targetId'] as String,
      status: AiJobStatusValue.fromValue(map['status'] as String? ?? 'pending'),
      promptDigest: map['promptDigest'] as String?,
      errorMessage: map['errorMessage'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch((map['createdAt'] as num).toInt()),
      completedAt: map['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['completedAt'] as num).toInt())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'feature': feature,
      'provider': provider,
      'model': model,
      'targetType': targetType,
      'targetId': targetId,
      'status': status.value,
      'promptDigest': promptDigest,
      'errorMessage': errorMessage,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
    };
  }

  AiJob copyWith({
    String? id,
    String? feature,
    String? provider,
    String? model,
    String? targetType,
    String? targetId,
    AiJobStatus? status,
    String? promptDigest,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return AiJob(
      id: id ?? this.id,
      feature: feature ?? this.feature,
      provider: provider ?? this.provider,
      model: model ?? this.model,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      status: status ?? this.status,
      promptDigest: promptDigest ?? this.promptDigest,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  String toString() => 'AiJob(id: $id, feature: $feature, status: $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiJob && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
