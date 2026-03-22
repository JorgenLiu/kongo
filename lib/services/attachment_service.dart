import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../exceptions/app_exception.dart';
import '../models/attachment.dart';
import '../models/attachment_draft.dart';
import '../models/attachment_link.dart';
import '../repositories/attachment_repository.dart';
import '../repositories/event_repository.dart';
import '../repositories/summary_repository.dart';

abstract class AttachmentService {
  Future<List<Attachment>> getAllAttachments();
  Future<Attachment> saveAttachment(AttachmentDraft draft);
  Future<Attachment> getAttachment(String id);
  Future<Attachment> updateAttachment(Attachment attachment);
  Future<void> deleteAttachment(String id);
  Future<void> openAttachment(Attachment attachment);
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
}

class DefaultAttachmentService implements AttachmentService {
  final AttachmentRepository _attachmentRepository;
  final EventRepository _eventRepository;
  final SummaryRepository _summaryRepository;
  final Uuid _uuid;

  DefaultAttachmentService(
    this._attachmentRepository,
    this._eventRepository,
    this._summaryRepository, {
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

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
    final displayFileName = _normalizeOptionalText(draft.fileName) ?? originalFileName;
    final extension = path.extension(displayFileName).isNotEmpty
        ? path.extension(displayFileName)
        : path.extension(originalFileName);
    final attachmentId = _uuid.v4();
    final attachmentsDirectory = await _getAttachmentsDirectory();
    final storedPath = path.join(attachmentsDirectory.path, '$attachmentId$extension');
    File? copiedFile;

    try {
      copiedFile = await sourceFile.copy(storedPath);
      final stat = await copiedFile.stat();
      final now = DateTime.now();
      final attachment = Attachment(
        id: attachmentId,
        fileName: displayFileName,
        originalFileName: originalFileName,
        storagePath: storedPath,
        mimeType: _normalizeOptionalText(draft.mimeType),
        extension: extension.isEmpty ? null : extension,
        sizeBytes: stat.size,
        previewText: _normalizeOptionalText(draft.previewText),
        createdAt: now,
        updatedAt: now,
      );

      final created = await _attachmentRepository.insert(attachment);

      if (draft.ownerType != null && draft.ownerId != null) {
        await _linkToOwner(
          created.id,
          draft.ownerType!,
          draft.ownerId!,
          label: draft.label,
        );
      }

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
  Future<Attachment> updateAttachment(Attachment attachment) async {
    final existing = await _attachmentRepository.getById(attachment.id);
    if (existing.storagePath != attachment.storagePath) {
      throw const ValidationException(message: '暂不支持直接修改附件存储路径', code: 'attachment_storage_path_readonly');
    }

    return _attachmentRepository.update(
      attachment.copyWith(
        fileName: attachment.fileName.trim(),
        originalFileName: _normalizeOptionalText(attachment.originalFileName),
        mimeType: _normalizeOptionalText(attachment.mimeType),
        extension: _normalizeOptionalText(attachment.extension),
        previewText: _normalizeOptionalText(attachment.previewText),
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
    final file = File(attachment.storagePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<void> openAttachment(Attachment attachment) async {
    final file = File(attachment.storagePath);
    if (!await file.exists()) {
      throw const FileStorageException(
        message: '附件文件不存在，无法打开',
        code: 'attachment_file_missing',
      );
    }

    late ProcessResult result;
    if (Platform.isMacOS) {
      result = await Process.run('open', [attachment.storagePath]);
    } else if (Platform.isWindows) {
      result = await Process.run('cmd', ['/c', 'start', '', attachment.storagePath]);
    } else {
      result = await Process.run('xdg-open', [attachment.storagePath]);
    }

    if (result.exitCode != 0) {
      throw FileStorageException(
        message: '打开附件失败',
        code: 'attachment_open_failed',
        originalException: result.stderr,
      );
    }
  }

  @override
  Future<void> removeAttachmentFromOwner(
    String attachmentId,
    AttachmentOwnerType ownerType,
    String ownerId, {
    bool deleteIfOrphan = false,
  }) async {
    final attachment = await _attachmentRepository.getById(attachmentId);
    final linkCount = await _attachmentRepository.getLinkCount(attachmentId);

    if (deleteIfOrphan && linkCount > 1) {
      throw const BusinessException(
        message: '附件仍关联到其他记录，无法直接删除本地文件',
        code: 'attachment_has_other_links',
      );
    }

    await _attachmentRepository.unlink(attachmentId, ownerType, ownerId);
    if (!deleteIfOrphan) {
      return;
    }

    await _attachmentRepository.delete(attachmentId);
    final file = File(attachment.storagePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<void> linkAttachmentToEvent(String attachmentId, String eventId, {String? label}) async {
    await _linkToOwner(
      attachmentId,
      AttachmentOwnerType.event,
      eventId,
      label: label,
    );
  }

  @override
  Future<void> linkAttachmentToSummary(String attachmentId, String summaryId, {String? label}) async {
    await _linkToOwner(
      attachmentId,
      AttachmentOwnerType.summary,
      summaryId,
      label: label,
    );
  }

  @override
  Future<void> unlinkAttachment(
    String attachmentId,
    AttachmentOwnerType ownerType,
    String ownerId,
  ) async {
    await _attachmentRepository.getById(attachmentId);
    await _attachmentRepository.unlink(attachmentId, ownerType, ownerId);
  }

  @override
  Future<List<Attachment>> getEventAttachments(String eventId) async {
    await _eventRepository.getById(eventId);
    return _attachmentRepository.getByOwner(AttachmentOwnerType.event, eventId);
  }

  @override
  Future<Map<String, List<Attachment>>> getEventAttachmentsByEventIds(List<String> eventIds) {
    if (eventIds.isEmpty) {
      return Future.value(const {});
    }
    return _attachmentRepository.getByOwners(AttachmentOwnerType.event, eventIds);
  }

  @override
  Future<List<Attachment>> getSummaryAttachments(String summaryId) async {
    await _summaryRepository.getById(summaryId);
    return _attachmentRepository.getByOwner(AttachmentOwnerType.summary, summaryId);
  }

  @override
  Future<Map<String, List<Attachment>>> getSummaryAttachmentsBySummaryIds(List<String> summaryIds) {
    if (summaryIds.isEmpty) {
      return Future.value(const {});
    }
    return _attachmentRepository.getByOwners(AttachmentOwnerType.summary, summaryIds);
  }

  Future<void> _linkToOwner(
    String attachmentId,
    AttachmentOwnerType ownerType,
    String ownerId, {
    String? label,
  }) async {
    await _attachmentRepository.getById(attachmentId);

    switch (ownerType) {
      case AttachmentOwnerType.event:
        await _eventRepository.getById(ownerId);
      case AttachmentOwnerType.summary:
        await _summaryRepository.getById(ownerId);
    }

    await _attachmentRepository.link(
      attachmentId,
      ownerType,
      ownerId,
      label: _normalizeOptionalText(label),
    );
  }

  Future<Directory> _getAttachmentsDirectory() async {
    final baseDirectory = await getApplicationDocumentsDirectory();
    final attachmentsDirectory = Directory(path.join(baseDirectory.path, 'attachments'));
    if (!await attachmentsDirectory.exists()) {
      await attachmentsDirectory.create(recursive: true);
    }
    return attachmentsDirectory;
  }

  String? _normalizeOptionalText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}