/// AI 输出记录。
class AiOutput {
  final String id;
  final String aiJobId;
  final String outputType;
  final String content;
  final DateTime createdAt;

  const AiOutput({
    required this.id,
    required this.aiJobId,
    required this.outputType,
    required this.content,
    required this.createdAt,
  });

  factory AiOutput.fromMap(Map<String, dynamic> map) {
    return AiOutput(
      id: map['id'] as String,
      aiJobId: map['aiJobId'] as String,
      outputType: map['outputType'] as String,
      content: map['content'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch((map['createdAt'] as num).toInt()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'aiJobId': aiJobId,
      'outputType': outputType,
      'content': content,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  @override
  String toString() => 'AiOutput(id: $id, aiJobId: $aiJobId, outputType: $outputType)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiOutput && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
