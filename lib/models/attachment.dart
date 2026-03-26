enum AttachmentStorageMode { managed, linked }

extension AttachmentStorageModeValue on AttachmentStorageMode {
  String get value {
    switch (this) {
      case AttachmentStorageMode.managed:
        return 'managed';
      case AttachmentStorageMode.linked:
        return 'linked';
    }
  }

  static AttachmentStorageMode fromValue(String? value) {
    return AttachmentStorageMode.values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => AttachmentStorageMode.managed,
    );
  }
}

enum AttachmentSourceStatus { available, missing, inaccessible }

extension AttachmentSourceStatusValue on AttachmentSourceStatus {
  String get value {
    switch (this) {
      case AttachmentSourceStatus.available:
        return 'available';
      case AttachmentSourceStatus.missing:
        return 'missing';
      case AttachmentSourceStatus.inaccessible:
        return 'inaccessible';
    }
  }

  static AttachmentSourceStatus fromValue(String? value) {
    return AttachmentSourceStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => AttachmentSourceStatus.available,
    );
  }
}

enum AttachmentImportPolicy { auto, forceManaged, forceLinked }

extension AttachmentImportPolicyValue on AttachmentImportPolicy {
  String get value {
    switch (this) {
      case AttachmentImportPolicy.auto:
        return 'auto';
      case AttachmentImportPolicy.forceManaged:
        return 'forceManaged';
      case AttachmentImportPolicy.forceLinked:
        return 'forceLinked';
    }
  }

  static AttachmentImportPolicy? fromValue(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    return AttachmentImportPolicy.values.firstWhere(
      (policy) => policy.value == value,
      orElse: () => AttachmentImportPolicy.auto,
    );
  }
}

enum AttachmentPreviewStatus { none, pending, ready, failed }

extension AttachmentPreviewStatusValue on AttachmentPreviewStatus {
  String get value {
    switch (this) {
      case AttachmentPreviewStatus.none:
        return 'none';
      case AttachmentPreviewStatus.pending:
        return 'pending';
      case AttachmentPreviewStatus.ready:
        return 'ready';
      case AttachmentPreviewStatus.failed:
        return 'failed';
    }
  }

  static AttachmentPreviewStatus fromValue(String? value, {bool hasSnapshot = false}) {
    if (value == null || value.isEmpty) {
      return hasSnapshot ? AttachmentPreviewStatus.ready : AttachmentPreviewStatus.none;
    }

    return AttachmentPreviewStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => hasSnapshot ? AttachmentPreviewStatus.ready : AttachmentPreviewStatus.none,
    );
  }
}

/// 附件模型
class Attachment {
  final String id;
  final String fileName;
  final String? originalFileName;
  final String storagePath;
  final AttachmentStorageMode storageMode;
  final String? sourcePath;
  final String? managedPath;
  final String? snapshotPath;
  final String? mimeType;
  final String? extension;
  final int sizeBytes;
  final int? originalSizeBytes;
  final int? managedSizeBytes;
  final String? checksum;
  final String? previewText;
  final AttachmentPreviewStatus previewStatus;
  final DateTime? previewUpdatedAt;
  final String? previewError;
  final AttachmentSourceStatus sourceStatus;
  final DateTime? sourceLastVerifiedAt;
  final AttachmentImportPolicy? importPolicy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Attachment({
    required this.id,
    required this.fileName,
    this.originalFileName,
    required this.storagePath,
    this.storageMode = AttachmentStorageMode.managed,
    this.sourcePath,
    this.managedPath,
    this.snapshotPath,
    this.mimeType,
    this.extension,
    required this.sizeBytes,
    this.originalSizeBytes,
    this.managedSizeBytes,
    this.checksum,
    this.previewText,
    this.previewStatus = AttachmentPreviewStatus.none,
    this.previewUpdatedAt,
    this.previewError,
    this.sourceStatus = AttachmentSourceStatus.available,
    this.sourceLastVerifiedAt,
    this.importPolicy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Attachment.fromMap(Map<String, dynamic> map) {
    final storageMode = AttachmentStorageModeValue.fromValue(map['storageMode'] as String?);
    final fallbackStoragePath =
        map['storagePath'] as String? ?? map['managedPath'] as String? ?? map['sourcePath'] as String? ?? '';
    final sourcePath = map['sourcePath'] as String?;
    final snapshotPath = map['snapshotPath'] as String?;
    final managedPath = (map['managedPath'] as String?) ??
        (storageMode == AttachmentStorageMode.managed ? fallbackStoragePath : null);

    return Attachment(
      id: map['id'] as String,
      fileName: map['fileName'] as String,
      originalFileName: map['originalFileName'] as String?,
      storagePath: fallbackStoragePath,
      storageMode: storageMode,
      sourcePath: sourcePath ??
          (storageMode == AttachmentStorageMode.linked ? fallbackStoragePath : null),
      managedPath: managedPath,
        snapshotPath: snapshotPath,
      mimeType: map['mimeType'] as String?,
      extension: map['extension'] as String?,
      sizeBytes: (map['sizeBytes'] as num).toInt(),
      originalSizeBytes: (map['originalSizeBytes'] as num?)?.toInt() ??
          (map['sizeBytes'] as num?)?.toInt(),
      managedSizeBytes: (map['managedSizeBytes'] as num?)?.toInt() ??
          (storageMode == AttachmentStorageMode.managed ? (map['sizeBytes'] as num?)?.toInt() : null),
      checksum: map['checksum'] as String?,
      previewText: map['previewText'] as String?,
      previewStatus: AttachmentPreviewStatusValue.fromValue(
        map['previewStatus'] as String?,
        hasSnapshot: snapshotPath != null && snapshotPath.isNotEmpty,
      ),
      previewUpdatedAt: (map['previewUpdatedAt'] as num?) == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch((map['previewUpdatedAt'] as num).toInt()),
      previewError: map['previewError'] as String?,
      sourceStatus: AttachmentSourceStatusValue.fromValue(map['sourceStatus'] as String?),
      sourceLastVerifiedAt: (map['sourceLastVerifiedAt'] as num?) == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch((map['sourceLastVerifiedAt'] as num).toInt()),
      importPolicy: AttachmentImportPolicyValue.fromValue(map['importPolicy'] as String?),
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
      'storageMode': storageMode.value,
      'sourcePath': sourcePath,
      'managedPath': managedPath,
      'snapshotPath': snapshotPath,
      'mimeType': mimeType,
      'extension': extension,
      'sizeBytes': sizeBytes,
      'originalSizeBytes': originalSizeBytes,
      'managedSizeBytes': managedSizeBytes,
      'checksum': checksum,
      'previewText': previewText,
      'previewStatus': previewStatus.value,
      'previewUpdatedAt': previewUpdatedAt?.millisecondsSinceEpoch,
      'previewError': previewError,
      'sourceStatus': sourceStatus.value,
      'sourceLastVerifiedAt': sourceLastVerifiedAt?.millisecondsSinceEpoch,
      'importPolicy': importPolicy?.value,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  Attachment copyWith({
    String? id,
    String? fileName,
    String? originalFileName,
    String? storagePath,
    AttachmentStorageMode? storageMode,
    String? sourcePath,
    String? managedPath,
    String? snapshotPath,
    String? mimeType,
    String? extension,
    int? sizeBytes,
    int? originalSizeBytes,
    int? managedSizeBytes,
    String? checksum,
    String? previewText,
    AttachmentPreviewStatus? previewStatus,
    DateTime? previewUpdatedAt,
    String? previewError,
    AttachmentSourceStatus? sourceStatus,
    DateTime? sourceLastVerifiedAt,
    AttachmentImportPolicy? importPolicy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Attachment(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      originalFileName: originalFileName ?? this.originalFileName,
      storagePath: storagePath ?? this.storagePath,
      storageMode: storageMode ?? this.storageMode,
      sourcePath: sourcePath ?? this.sourcePath,
      managedPath: managedPath ?? this.managedPath,
      snapshotPath: snapshotPath ?? this.snapshotPath,
      mimeType: mimeType ?? this.mimeType,
      extension: extension ?? this.extension,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      originalSizeBytes: originalSizeBytes ?? this.originalSizeBytes,
      managedSizeBytes: managedSizeBytes ?? this.managedSizeBytes,
      checksum: checksum ?? this.checksum,
      previewText: previewText ?? this.previewText,
      previewStatus: previewStatus ?? this.previewStatus,
      previewUpdatedAt: previewUpdatedAt ?? this.previewUpdatedAt,
      previewError: previewError ?? this.previewError,
      sourceStatus: sourceStatus ?? this.sourceStatus,
      sourceLastVerifiedAt: sourceLastVerifiedAt ?? this.sourceLastVerifiedAt,
      importPolicy: importPolicy ?? this.importPolicy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get effectivePath => managedPath ?? sourcePath ?? storagePath;

  String get normalizedExtension {
    final value = extension?.trim().toLowerCase();
    if (value == null || value.isEmpty) {
      final segments = fileName.split('.');
      if (segments.length <= 1) {
        return '';
      }
      return '.${segments.last.toLowerCase()}';
    }
    return value.startsWith('.') ? value : '.$value';
  }

  bool get isImageFile {
    final normalizedMimeType = mimeType?.toLowerCase();
    if (normalizedMimeType != null && normalizedMimeType.startsWith('image/')) {
      return true;
    }

    const imageExtensions = {
      '.png',
      '.jpg',
      '.jpeg',
      '.gif',
      '.webp',
      '.bmp',
      '.heic',
      '.heif',
      '.tif',
      '.tiff',
    };
    return imageExtensions.contains(normalizedExtension);
  }

  bool get isPdfFile {
    final normalizedMimeType = mimeType?.toLowerCase();
    if (normalizedMimeType == 'application/pdf') {
      return true;
    }

    return normalizedExtension == '.pdf';
  }

  bool get supportsPreview => isImageFile || isPdfFile;

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