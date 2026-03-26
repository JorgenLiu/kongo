import 'attachment.dart';
import 'attachment_link.dart';

/// 附件保存草稿。
class AttachmentDraft {
  final String sourcePath;
  final String? fileName;
  final String? mimeType;
  final String? previewText;
  final AttachmentStorageMode? preferredStorageMode;
  final AttachmentImportPolicy? importPolicy;
  final bool allowLargeFile;
  final AttachmentOwnerType? ownerType;
  final String? ownerId;
  final String? label;

  const AttachmentDraft({
    required this.sourcePath,
    this.fileName,
    this.mimeType,
    this.previewText,
    this.preferredStorageMode,
    this.importPolicy,
    this.allowLargeFile = false,
    this.ownerType,
    this.ownerId,
    this.label,
  });
}