/// 附件模型
class Attachment {
  final String id;
  final String fileName;
  final String? originalFileName;
  final String storagePath;
  final String? mimeType;
  final String? extension;
  final int sizeBytes;
  final String? checksum;
  final String? previewText;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Attachment({
    required this.id,
    required this.fileName,
    this.originalFileName,
    required this.storagePath,
    this.mimeType,
    this.extension,
    required this.sizeBytes,
    this.checksum,
    this.previewText,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Attachment.fromMap(Map<String, dynamic> map) {
    return Attachment(
      id: map['id'] as String,
      fileName: map['fileName'] as String,
      originalFileName: map['originalFileName'] as String?,
      storagePath: map['storagePath'] as String,
      mimeType: map['mimeType'] as String?,
      extension: map['extension'] as String?,
      sizeBytes: (map['sizeBytes'] as num).toInt(),
      checksum: map['checksum'] as String?,
      previewText: map['previewText'] as String?,
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
      'fileName': fileName,
      'originalFileName': originalFileName,
      'storagePath': storagePath,
      'mimeType': mimeType,
      'extension': extension,
      'sizeBytes': sizeBytes,
      'checksum': checksum,
      'previewText': previewText,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  Attachment copyWith({
    String? id,
    String? fileName,
    String? originalFileName,
    String? storagePath,
    String? mimeType,
    String? extension,
    int? sizeBytes,
    String? checksum,
    String? previewText,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Attachment(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      originalFileName: originalFileName ?? this.originalFileName,
      storagePath: storagePath ?? this.storagePath,
      mimeType: mimeType ?? this.mimeType,
      extension: extension ?? this.extension,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      checksum: checksum ?? this.checksum,
      previewText: previewText ?? this.previewText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Attachment(id: $id, fileName: $fileName, sizeBytes: $sizeBytes)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Attachment &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          storagePath == other.storagePath;

  @override
  int get hashCode => id.hashCode ^ storagePath.hashCode;
}