import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../config/app_constants.dart';
import '../exceptions/app_exception.dart';
import '../models/attachment.dart';
import '../models/attachment_draft.dart';
import '../models/attachment_link.dart';
import '../repositories/attachment_repository.dart';
import '../repositories/event_repository.dart';
import '../repositories/summary_repository.dart';
import '../utils/text_normalize.dart';
import 'attachment_file_service.dart';
import 'attachment_link_service.dart';
import 'attachment_preview_service.dart';
import 'platform_file_opener.dart';

abstract class AttachmentService {
  Future<List<Attachment>> getAllAttachments();
  Future<Attachment> saveAttachment(AttachmentDraft draft);
  Future<Attachment> getAttachment(String id);
  Future<int> getAttachmentLinkCount(String id);
  Future<Attachment> updateAttachment(Attachment attachment);
  Future<void> deleteAttachment(String id);
  Future<void> openAttachment(Attachment attachment);
  Future<void> revealAttachment(Attachment attachment);
  Future<Attachment> relinkAttachmentSource(String attachmentId, String newSourcePath);
  Future<Attachment> convertAttachmentToManaged(String attachmentId);
  Future<void> refreshAttachmentPreview(String attachmentId, {bool force = false});
  Future<void> removeAttachmentFromOwner(
    String attachmentId,
    AttachmentOwnerType ownerType,
    String ownerId, {
    bool deleteIfOrphan = false,
  });
  Future<void> linkAttachmentToEvent(String attachmentId, String eventId, {String? label});
  Future<void> linkAttachmentToSummary(String attachmentId, String summaryId, {String? label});
  Future<void> unlinkAttachment(String attachmentId, AttachmentOwnerType ownerType, String ownerId);
  Future<List<Attachment>> getEventAttachments(String eventId);
  Future<Map<String, List<Attachment>>> getEventAttachmentsByEventIds(List<String> eventIds);
  Future<List<Attachment>> getSummaryAttachments(String summaryId);
  Future<Map<String, List<Attachment>>> getSummaryAttachmentsBySummaryIds(List<String> summaryIds);
  Future<List<Attachment>> searchAttachments(String keyword);
}

class DefaultAttachmentService implements AttachmentService {
  final AttachmentRepository _attachmentRepository;
  final AttachmentFileService _fileService;
  final AttachmentLinkService _linkService;
  final AttachmentPreviewService? _attachmentPreviewService;
  final Uuid _uuid;

  DefaultAttachmentService(
    AttachmentRepository attachmentRepository,
    EventRepository eventRepository,
    SummaryRepository summaryRepository, {
    Uuid? uuid,
    Future<Directory> Function()? attachmentsDirectoryResolver,
    AttachmentPreviewService? attachmentPreviewService,
    PlatformFileOpener? fileOpener,
  })  : _attachmentRepository = attachmentRepository,
        _uuid = uuid ?? const Uuid(),
        _attachmentPreviewService = attachmentPreviewService,
        _fileService = AttachmentFileService(
          attachmentRepository,
          attachmentsDirectoryResolver: attachmentsDirectoryResolver,
          fileOpener: fileOpener,
        ),
        _linkService = AttachmentLinkService(
          attachmentRepository,
          eventRepository,
          summaryRepository,
        );

  @override
  Future<List<Attachment>> getAllAttachments() {
    return _attachmentRepository.getAll();
  }

  @override
  Future<Attachment> saveAttachment(AttachmentDraft draft) async {
    final sourceFile = File(draft.sourcePath);
    if (!await sourceFile.exists()) {
      throw const FileStorageException(message: '附件源文件不存在', code: 'attachment_source_missing');
    }

    if ((draft.ownerType == null) != (draft.ownerId == null)) {
      throw const ValidationException(message: '附件 ownerType 和 ownerId 需要同时提供', code: 'attachment_owner_invalid');
    }

    final originalFileName = path.basename(draft.sourcePath);
    final displayFileName = normalizeOptionalText(draft.fileName) ?? originalFileName;
    final extension = path.extension(displayFileName).isNotEmpty
        ? path.extension(displayFileName)
        : path.extension(originalFileName);
    final sourceStat = await sourceFile.stat();
    final sourceSizeBytes = sourceStat.size;
    if (sourceSizeBytes > AttachmentImportLimits.hardLimitBytes && !draft.allowLargeFile) {
      throw ValidationException(
        message: '附件过大，当前限制为 ${_fileService.formatLimit(AttachmentImportLimits.hardLimitBytes)}',
        code: 'attachment_size_exceeded',
      );
    }

    final attachmentId = _uuid.v4();
    final storageMode = _fileService.resolveStorageMode(draft, sourceSizeBytes);
    File? copiedFile;

    try {
      final now = DateTime.now();
      late final Attachment attachment;

      if (storageMode == AttachmentStorageMode.managed) {
        final attachmentsDirectory = await _fileService.getAttachmentsDirectory();
        final storedPath = path.join(attachmentsDirectory.path, '$attachmentId$extension');
        copiedFile = await sourceFile.copy(storedPath);
        final copiedStat = await copiedFile.stat();
        attachment = Attachment(
          id: attachmentId,
          fileName: displayFileName,
          originalFileName: originalFileName,
          storagePath: storedPath,
          storageMode: AttachmentStorageMode.managed,
          sourcePath: draft.sourcePath,
          managedPath: storedPath,
          mimeType: normalizeOptionalText(draft.mimeType),
          extension: extension.isEmpty ? null : extension,
          sizeBytes: copiedStat.size,
          originalSizeBytes: sourceSizeBytes,
          managedSizeBytes: copiedStat.size,
          previewText: normalizeOptionalText(draft.previewText),
          sourceStatus: AttachmentSourceStatus.available,
          importPolicy: draft.importPolicy,
          createdAt: now,
          updatedAt: now,
        );
      } else {
        attachment = Attachment(
          id: attachmentId,
          fileName: displayFileName,
          originalFileName: originalFileName,
          storagePath: draft.sourcePath,
          storageMode: AttachmentStorageMode.linked,
          sourcePath: draft.sourcePath,
          mimeType: normalizeOptionalText(draft.mimeType),
          extension: extension.isEmpty ? null : extension,
          sizeBytes: sourceSizeBytes,
          originalSizeBytes: sourceSizeBytes,
          previewText: normalizeOptionalText(draft.previewText),
          sourceStatus: AttachmentSourceStatus.available,
          sourceLastVerifiedAt: now,
          importPolicy: draft.importPolicy,
          createdAt: now,
          updatedAt: now,
        );
      }

      final created = await _attachmentRepository.insert(attachment);

      if (draft.ownerType != null && draft.ownerId != null) {
        await _linkService.linkToOwner(
          created.id,
          draft.ownerType!,
          draft.ownerId!,
          label: draft.label,
        );
      }

      _schedulePreviewRefresh(created);

      return _attachmentRepository.getById(created.id);
    } on AppException {
      if (copiedFile != null && await copiedFile.exists()) {
        await copiedFile.delete();
      }
      rethrow;
    } on IOException catch (error) {
      if (copiedFile != null && await copiedFile.exists()) {
        await copiedFile.delete();
      }
      throw FileStorageException(
        message: '保存附件文件失败',
        code: 'attachment_save_failed',
        originalException: error,
      );
    }
  }

  @override
  Future<Attachment> getAttachment(String id) {
    return _attachmentRepository.getById(id);
  }

  @override
  Future<int> getAttachmentLinkCount(String id) {
    return _attachmentRepository.getLinkCount(id);
  }

  @override
  Future<Attachment> updateAttachment(Attachment attachment) async {
    final existing = await _attachmentRepository.getById(attachment.id);
    if (existing.storagePath != attachment.storagePath ||
        existing.storageMode != attachment.storageMode ||
        existing.sourcePath != attachment.sourcePath ||
        existing.managedPath != attachment.managedPath) {
      throw const ValidationException(message: '暂不支持直接修改附件存储模式或路径', code: 'attachment_storage_path_readonly');
    }

    return _attachmentRepository.update(
      attachment.copyWith(
        fileName: attachment.fileName.trim(),
        originalFileName: normalizeOptionalText(attachment.originalFileName),
        mimeType: normalizeOptionalText(attachment.mimeType),
        extension: normalizeOptionalText(attachment.extension),
        previewText: normalizeOptionalText(attachment.previewText),
        snapshotPath: normalizeOptionalText(attachment.snapshotPath),
        sourceStatus: attachment.sourceStatus,
        sourceLastVerifiedAt: attachment.sourceLastVerifiedAt,
        importPolicy: attachment.importPolicy,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> deleteAttachment(String id) async {
    final attachment = await _attachmentRepository.getById(id);
    final linkCount = await _attachmentRepository.getLinkCount(id);
    if (linkCount > 0) {
      throw const BusinessException(message: '附件仍有关联记录，无法直接删除', code: 'attachment_still_linked');
    }

    await _attachmentRepository.delete(id);
    await _fileService.deleteManagedArtifacts(attachment);
  }

  @override
  Future<void> openAttachment(Attachment attachment) =>
      _fileService.openAttachment(attachment);

  @override
  Future<void> revealAttachment(Attachment attachment) =>
      _fileService.revealAttachment(attachment);

  @override
  Future<Attachment> relinkAttachmentSource(String attachmentId, String newSourcePath) async {
    final attachment = await _attachmentRepository.getById(attachmentId);
    if (attachment.storageMode != AttachmentStorageMode.linked) {
      throw const ValidationException(
        message: '只有外部引用附件支持重新定位原文件',
        code: 'attachment_relink_managed_unsupported',
      );
    }

    final sourceFile = File(newSourcePath);
    if (!await sourceFile.exists()) {
      throw const FileStorageException(
        message: '新的源文件不存在',
        code: 'attachment_source_missing',
      );
    }

    final sourceStat = await sourceFile.stat();
    final updated = attachment.copyWith(
      storagePath: newSourcePath,
      sourcePath: newSourcePath,
      originalFileName: path.basename(newSourcePath),
      sizeBytes: sourceStat.size,
      originalSizeBytes: sourceStat.size,
      sourceStatus: AttachmentSourceStatus.available,
      sourceLastVerifiedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final relinked = await _attachmentRepository.update(updated);
    _schedulePreviewRefresh(relinked, force: true);
    return relinked;
  }

  @override
  Future<Attachment> convertAttachmentToManaged(String attachmentId) async {
    final attachment = await _attachmentRepository.getById(attachmentId);
    if (attachment.storageMode == AttachmentStorageMode.managed) {
      return attachment;
    }

    final sourcePath = attachment.sourcePath ?? attachment.storagePath;
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      await _fileService.updateSourceStatus(attachment, AttachmentSourceStatus.missing);
      throw const FileStorageException(
        message: '原文件已丢失，无法转为托管附件',
        code: 'attachment_source_missing',
      );
    }

    final attachmentsDirectory = await _fileService.getAttachmentsDirectory();
    final extension = attachment.extension ?? path.extension(attachment.originalFileName ?? attachment.fileName);
    final storedPath = path.join(attachmentsDirectory.path, '${attachment.id}$extension');
    final copiedFile = await sourceFile.copy(storedPath);
    final copiedStat = await copiedFile.stat();

    final updated = attachment.copyWith(
      storagePath: storedPath,
      storageMode: AttachmentStorageMode.managed,
      managedPath: storedPath,
      managedSizeBytes: copiedStat.size,
      sizeBytes: copiedStat.size,
      sourceStatus: AttachmentSourceStatus.available,
      sourceLastVerifiedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final converted = await _attachmentRepository.update(updated);
    _schedulePreviewRefresh(converted, force: true);
    return converted;
  }

  @override
  Future<void> refreshAttachmentPreview(String attachmentId, {bool force = false}) async {
    final previewService = _attachmentPreviewService;
    if (previewService == null) {
      return;
    }

    final attachment = await _attachmentRepository.getById(attachmentId);
    await previewService.ensurePreview(attachment, force: force);
  }

  @override
  Future<void> removeAttachmentFromOwner(
    String attachmentId,
    AttachmentOwnerType ownerType,
    String ownerId, {
    bool deleteIfOrphan = false,
  }) async {
    final attachment = await _attachmentRepository.getById(attachmentId);

    await _linkService.removeAttachmentFromOwner(
      attachmentId,
      ownerType,
      ownerId,
      deleteIfOrphan: deleteIfOrphan,
    );

    if (!deleteIfOrphan) {
      return;
    }

    await _attachmentRepository.delete(attachmentId);
    await _fileService.deleteManagedArtifacts(attachment);
  }

  @override
  Future<void> linkAttachmentToEvent(String attachmentId, String eventId, {String? label}) =>
      _linkService.linkToOwner(attachmentId, AttachmentOwnerType.event, eventId, label: label);

  @override
  Future<void> linkAttachmentToSummary(String attachmentId, String summaryId, {String? label}) =>
      _linkService.linkToOwner(attachmentId, AttachmentOwnerType.summary, summaryId, label: label);

  @override
  Future<void> unlinkAttachment(String attachmentId, AttachmentOwnerType ownerType, String ownerId) =>
      _linkService.unlinkAttachment(attachmentId, ownerType, ownerId);

  @override
  Future<List<Attachment>> getEventAttachments(String eventId) =>
      _linkService.getEventAttachments(eventId);

  @override
  Future<Map<String, List<Attachment>>> getEventAttachmentsByEventIds(List<String> eventIds) =>
      _linkService.getEventAttachmentsByEventIds(eventIds);

  @override
  Future<List<Attachment>> getSummaryAttachments(String summaryId) =>
      _linkService.getSummaryAttachments(summaryId);

  @override
  Future<Map<String, List<Attachment>>> getSummaryAttachmentsBySummaryIds(List<String> summaryIds) =>
      _linkService.getSummaryAttachmentsBySummaryIds(summaryIds);

  @override
  Future<List<Attachment>> searchAttachments(String keyword) async {
    return _attachmentRepository.searchByKeyword(keyword);
  }

  void _schedulePreviewRefresh(Attachment attachment, {bool force = false}) {
    final previewService = _attachmentPreviewService;
    if (previewService == null || !attachment.supportsPreview) {
      return;
    }

    unawaited(previewService.ensurePreview(attachment, force: force));
  }
}