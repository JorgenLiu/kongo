import 'attachment_link.dart';

/// 附件保存草稿。
class AttachmentDraft {
  final String sourcePath;
  final String? fileName;
  final String? mimeType;
  final String? previewText;
  final AttachmentOwnerType? ownerType;
  final String? ownerId;
  final String? label;

  const AttachmentDraft({
    required this.sourcePath,
    this.fileName,
    this.mimeType,
    this.previewText,
    this.ownerType,
    this.ownerId,
    this.label,
  });
}