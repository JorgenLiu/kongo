import '../models/attachment.dart';
import '../models/attachment_draft.dart';
import '../models/attachment_link.dart';
import '../services/attachment_service.dart';
import 'base_provider.dart';

class AttachmentProvider extends BaseProvider {
  final AttachmentService _attachmentService;

  AttachmentProvider(this._attachmentService);

  List<Attachment> _attachments = const [];
  AttachmentOwnerType? _currentOwnerType;
  String? _currentOwnerId;

  List<Attachment> get attachments => _attachments;

  void resetDetailState() {
    final shouldNotify = _attachments.isNotEmpty || initialized;
    _attachments = const [];
    _currentOwnerType = null;
    _currentOwnerId = null;
    markInitialized(false);
    if (error != null) {
      clearError();
      return;
    }

    if (shouldNotify) {
      notifyListeners();
    }
  }

  Future<void> loadEventAttachments(String eventId) {
    return _loadAttachments(AttachmentOwnerType.event, eventId);
  }

  Future<void> loadSummaryAttachments(String summaryId) {
    return _loadAttachments(AttachmentOwnerType.summary, summaryId);
  }

  Future<void> addAttachmentFromPath(
    String sourcePath, {
    required AttachmentOwnerType ownerType,
    required String ownerId,
    String? label,
  }) async {
    await execute(() async {
      await _attachmentService.saveAttachment(
        AttachmentDraft(
          sourcePath: sourcePath,
          ownerType: ownerType,
          ownerId: ownerId,
          label: label,
        ),
      );

      if (_isCurrentOwner(ownerType, ownerId)) {
        _attachments = await _fetchOwnerAttachments(ownerType, ownerId);
        markInitialized(true);
      }
    });
  }

  Future<void> unlinkAttachment(
    String attachmentId, {
    required AttachmentOwnerType ownerType,
    required String ownerId,
  }) async {
    await execute(() async {
      await _attachmentService.removeAttachmentFromOwner(
        attachmentId,
        ownerType,
        ownerId,
      );

      if (_isCurrentOwner(ownerType, ownerId)) {
        _attachments = await _fetchOwnerAttachments(ownerType, ownerId);
        markInitialized(true);
      }
    });
  }

  Future<void> deleteAttachment(
    String attachmentId, {
    required AttachmentOwnerType ownerType,
    required String ownerId,
  }) async {
    await execute(() async {
      await _attachmentService.removeAttachmentFromOwner(
        attachmentId,
        ownerType,
        ownerId,
        deleteIfOrphan: true,
      );

      if (_isCurrentOwner(ownerType, ownerId)) {
        _attachments = await _fetchOwnerAttachments(ownerType, ownerId);
        markInitialized(true);
      }
    });
  }

  Future<void> openAttachment(Attachment attachment) async {
    await execute(() async {
      await _attachmentService.openAttachment(attachment);
    });
  }

  Future<void> _loadAttachments(AttachmentOwnerType ownerType, String ownerId) async {
    _currentOwnerType = ownerType;
    _currentOwnerId = ownerId;

    await execute(() async {
      _attachments = await _fetchOwnerAttachments(ownerType, ownerId);
      markInitialized(true);
    });
  }

  Future<List<Attachment>> _fetchOwnerAttachments(
    AttachmentOwnerType ownerType,
    String ownerId,
  ) {
    switch (ownerType) {
      case AttachmentOwnerType.event:
        return _attachmentService.getEventAttachments(ownerId);
      case AttachmentOwnerType.summary:
        return _attachmentService.getSummaryAttachments(ownerId);
    }
  }

  bool _isCurrentOwner(AttachmentOwnerType ownerType, String ownerId) {
    return _currentOwnerType == ownerType && _currentOwnerId == ownerId;
  }
}