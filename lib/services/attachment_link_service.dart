import '../exceptions/app_exception.dart';
import '../models/attachment.dart';
import '../models/attachment_link.dart';
import '../repositories/attachment_repository.dart';
import '../repositories/event_repository.dart';
import '../repositories/summary_repository.dart';
import '../utils/text_normalize.dart';

/// 附件关联/解关联/查询服务。
class AttachmentLinkService {
  final AttachmentRepository _attachmentRepository;
  final EventRepository _eventRepository;
  final SummaryRepository _summaryRepository;

  AttachmentLinkService(
    this._attachmentRepository,
    this._eventRepository,
    this._summaryRepository,
  );

  Future<void> linkToOwner(
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
      label: normalizeOptionalText(label),
    );
  }

  Future<void> unlinkAttachment(
    String attachmentId,
    AttachmentOwnerType ownerType,
    String ownerId,
  ) async {
    await _attachmentRepository.getById(attachmentId);
    await _attachmentRepository.unlink(attachmentId, ownerType, ownerId);
  }

  Future<List<Attachment>> getEventAttachments(String eventId) async {
    await _eventRepository.getById(eventId);
    return _attachmentRepository.getByOwner(AttachmentOwnerType.event, eventId);
  }

  Future<Map<String, List<Attachment>>> getEventAttachmentsByEventIds(List<String> eventIds) {
    if (eventIds.isEmpty) {
      return Future.value(const {});
    }
    return _attachmentRepository.getByOwners(AttachmentOwnerType.event, eventIds);
  }

  Future<List<Attachment>> getSummaryAttachments(String summaryId) async {
    await _summaryRepository.getById(summaryId);
    return _attachmentRepository.getByOwner(AttachmentOwnerType.summary, summaryId);
  }

  Future<Map<String, List<Attachment>>> getSummaryAttachmentsBySummaryIds(List<String> summaryIds) {
    if (summaryIds.isEmpty) {
      return Future.value(const {});
    }
    return _attachmentRepository.getByOwners(AttachmentOwnerType.summary, summaryIds);
  }

  Future<void> removeAttachmentFromOwner(
    String attachmentId,
    AttachmentOwnerType ownerType,
    String ownerId, {
    bool deleteIfOrphan = false,
  }) async {
    final linkCount = await _attachmentRepository.getLinkCount(attachmentId);

    if (deleteIfOrphan && linkCount > 1) {
      throw const BusinessException(
        message: '附件仍关联到其他记录，无法直接删除本地文件',
        code: 'attachment_has_other_links',
      );
    }

    await _attachmentRepository.unlink(attachmentId, ownerType, ownerId);
  }
}
