import 'dart:async';

import '../exceptions/app_exception.dart';
import '../models/attachment.dart';
import '../services/attachment_service.dart';
import 'base_provider.dart';

enum FilesLibraryStorageFilter { all, managed, linked }

enum FilesLibrarySort {
  updatedAtDesc,
  fileNameAsc,
  fileSizeDesc,
}

class FilesProvider extends BaseProvider {
  final AttachmentService _attachmentService;
  final bool _enableBackgroundPreviewWarmup;

  FilesProvider(this._attachmentService, {bool enableBackgroundPreviewWarmup = true})
      : _enableBackgroundPreviewWarmup = enableBackgroundPreviewWarmup;

  List<Attachment> _allFiles = const [];
  List<Attachment> _files = const [];
  String _keyword = '';
  FilesLibraryStorageFilter _activeStorageFilter = FilesLibraryStorageFilter.all;
  FilesLibrarySort _activeSort = FilesLibrarySort.updatedAtDesc;
  bool _missingSourceOnly = false;
  Map<String, int> _linkCounts = const {};
  bool _isGeneratingPreviews = false;
    bool _selectionMode = false;
    Set<String> _selectedAttachmentIds = <String>{};
    Set<String> _refreshingPreviewIds = <String>{};

  List<Attachment> get files => _files;
  String get keyword => _keyword;
  FilesLibraryStorageFilter get activeStorageFilter => _activeStorageFilter;
  FilesLibrarySort get activeSort => _activeSort;
  bool get missingSourceOnly => _missingSourceOnly;
    bool get selectionMode => _selectionMode;
    int get selectedCount => _selectedAttachmentIds.length;
    int get selectedLinkedCount =>
      _selectedAttachmentIds.where((id) => linkCountFor(id) > 0).length;
    int get selectedOrphanCount =>
      _selectedAttachmentIds.where((id) => linkCountFor(id) == 0).length;
    bool get allVisibleSelected =>
      files.isNotEmpty && files.every((attachment) => _selectedAttachmentIds.contains(attachment.id));
  int get orphanFileCount => _allFiles.where((attachment) => linkCountFor(attachment.id) == 0).length;

  Future<void> loadFiles() async {
    await execute(() async {
      _keyword = '';
      _activeStorageFilter = FilesLibraryStorageFilter.all;
      _activeSort = FilesLibrarySort.updatedAtDesc;
      _missingSourceOnly = false;
      _selectionMode = false;
      _selectedAttachmentIds = <String>{};
      _refreshingPreviewIds = <String>{};
      _allFiles = await _attachmentService.getAllAttachments();
      _linkCounts = await _loadLinkCounts(_allFiles);
      _applyFilters(notify: false);
      markInitialized();
      if (_enableBackgroundPreviewWarmup) {
        unawaited(_warmUpPreviewsInBackground());
      }
    });
  }

  int linkCountFor(String attachmentId) {
    return _linkCounts[attachmentId] ?? 0;
  }

  void searchByKeyword(String keyword) {
    _keyword = keyword;
    _applyFilters();
  }

  void updateStorageFilter(FilesLibraryStorageFilter filter) {
    if (_activeStorageFilter == filter) {
      return;
    }

    _activeStorageFilter = filter;
    _applyFilters();
  }

  void updateSort(FilesLibrarySort sort) {
    if (_activeSort == sort) {
      return;
    }

    _activeSort = sort;
    _applyFilters();
  }

  void setMissingSourceOnly(bool enabled) {
    if (_missingSourceOnly == enabled) {
      return;
    }

    _missingSourceOnly = enabled;
    _applyFilters();
  }

  Attachment? fileById(String attachmentId) {
    for (final attachment in _allFiles) {
      if (attachment.id == attachmentId) {
        return attachment;
      }
    }
    return null;
  }

  bool isSelected(String attachmentId) => _selectedAttachmentIds.contains(attachmentId);

  bool isRefreshingPreview(String attachmentId) => _refreshingPreviewIds.contains(attachmentId);

  void enterSelectionMode() {
    if (_selectionMode) {
      return;
    }

    _selectionMode = true;
    notifyListeners();
  }

  void exitSelectionMode() {
    if (!_selectionMode && _selectedAttachmentIds.isEmpty) {
      return;
    }

    _selectionMode = false;
    _selectedAttachmentIds = <String>{};
    notifyListeners();
  }

  void toggleSelection(String attachmentId) {
    final nextSelectedIds = Set<String>.from(_selectedAttachmentIds);
    if (nextSelectedIds.contains(attachmentId)) {
      nextSelectedIds.remove(attachmentId);
    } else {
      nextSelectedIds.add(attachmentId);
    }

    _selectedAttachmentIds = nextSelectedIds;
    _selectionMode = _selectedAttachmentIds.isNotEmpty;
    notifyListeners();
  }

  void toggleSelectAllVisible() {
    if (files.isEmpty) {
      return;
    }

    final nextSelectedIds = Set<String>.from(_selectedAttachmentIds);
    if (allVisibleSelected) {
      for (final attachment in files) {
        nextSelectedIds.remove(attachment.id);
      }
    } else {
      for (final attachment in files) {
        nextSelectedIds.add(attachment.id);
      }
    }

    _selectedAttachmentIds = nextSelectedIds;
    _selectionMode = _selectedAttachmentIds.isNotEmpty;
    notifyListeners();
  }

  Future<void> openFile(Attachment attachment) async {
    await execute(() async {
      await _attachmentService.openAttachment(attachment);
    });
  }

  Future<void> revealFile(Attachment attachment) async {
    await execute(() async {
      await _attachmentService.revealAttachment(attachment);
    });
  }

  Future<void> relinkFile(Attachment attachment, String newSourcePath) async {
    await execute(() async {
      await _attachmentService.relinkAttachmentSource(attachment.id, newSourcePath);
      await _reloadFiles();
    });
  }

  Future<void> convertToManaged(Attachment attachment) async {
    await execute(() async {
      await _attachmentService.convertAttachmentToManaged(attachment.id);
      await _reloadFiles();
    });
  }

  Future<void> deleteFile(Attachment attachment) async {
    await execute(() async {
      final linkCount = await _attachmentService.getAttachmentLinkCount(attachment.id);
      if (linkCount > 0) {
        throw BusinessException(
          message: '附件仍关联 $linkCount 条记录，请先移除关联后再删除',
          code: 'attachment_still_linked',
        );
      }

      await _attachmentService.deleteAttachment(attachment.id);
      await _reloadFiles();
    });
  }

  Future<int> cleanupOrphanFiles() async {
    var deletedCount = 0;
    await execute(() async {
      final orphanAttachments = _allFiles.where((attachment) => linkCountFor(attachment.id) == 0).toList();
      for (final attachment in orphanAttachments) {
        await _attachmentService.deleteAttachment(attachment.id);
        deletedCount += 1;
      }
      await _reloadFiles();
    });
    return deletedCount;
  }

  Future<int> deleteSelectedFiles() async {
    var deletedCount = 0;
    await execute(() async {
      if (_selectedAttachmentIds.isEmpty) {
        return;
      }

      final selectedAttachments = _allFiles
          .where((attachment) => _selectedAttachmentIds.contains(attachment.id))
          .toList();
      final blockedAttachments = selectedAttachments.where((attachment) => linkCountFor(attachment.id) > 0).toList();
      if (blockedAttachments.isNotEmpty) {
        throw BusinessException(
          message: '所选附件中有 ${blockedAttachments.length} 项仍有关联，请先移除关联后再删除',
          code: 'selected_attachments_still_linked',
        );
      }

      for (final attachment in selectedAttachments) {
        await _attachmentService.deleteAttachment(attachment.id);
        deletedCount += 1;
      }

      await _reloadFiles();
      _selectionMode = false;
      _selectedAttachmentIds = <String>{};
    });
    return deletedCount;
  }

  Future<void> refreshPreview(String attachmentId, {bool force = true}) async {
    final nextRefreshingIds = Set<String>.from(_refreshingPreviewIds)..add(attachmentId);
    _refreshingPreviewIds = nextRefreshingIds;
    notifyListeners();

    try {
      await execute(() async {
        await _attachmentService.refreshAttachmentPreview(attachmentId, force: force);
        await _reloadFiles();
      });
    } finally {
      final updatedRefreshingIds = Set<String>.from(_refreshingPreviewIds)..remove(attachmentId);
      _refreshingPreviewIds = updatedRefreshingIds;
      notifyListeners();
    }
  }

  Future<void> _reloadFiles() async {
    _allFiles = await _attachmentService.getAllAttachments();
    _linkCounts = await _loadLinkCounts(_allFiles);
    final validIds = _allFiles.map((attachment) => attachment.id).toSet();
    _selectedAttachmentIds = _selectedAttachmentIds.where(validIds.contains).toSet();
    if (_selectedAttachmentIds.isEmpty) {
      _selectionMode = false;
    }
    _applyFilters(notify: false);
    markInitialized();
  }

  Future<Map<String, int>> _loadLinkCounts(List<Attachment> attachments) async {
    final linkCounts = <String, int>{};
    for (final attachment in attachments) {
      linkCounts[attachment.id] = await _attachmentService.getAttachmentLinkCount(attachment.id);
    }
    return linkCounts;
  }

  Future<void> _warmUpPreviewsInBackground() async {
    if (_isGeneratingPreviews) {
      return;
    }

    final pendingPreviewIds = _allFiles
        .where(
          (attachment) =>
              attachment.supportsPreview &&
              (attachment.previewStatus != AttachmentPreviewStatus.ready ||
                  attachment.snapshotPath == null ||
                  attachment.snapshotPath!.isEmpty),
        )
        .map((attachment) => attachment.id)
        .toList();
    if (pendingPreviewIds.isEmpty) {
      return;
    }

    _isGeneratingPreviews = true;
    try {
      for (final attachmentId in pendingPreviewIds) {
        await _attachmentService.refreshAttachmentPreview(attachmentId);
      }
      await _reloadFiles();
      notifyListeners();
    } catch (_) {
      // 预览生成失败不会阻断文件库主流程。
    } finally {
      _isGeneratingPreviews = false;
    }
  }

  void _applyFilters({bool notify = true}) {
    final normalizedKeyword = _keyword.trim().toLowerCase();
    _files = _allFiles.where((attachment) {
      if (!_matchesFilter(attachment)) {
        return false;
      }

      if (normalizedKeyword.isEmpty) {
        return true;
      }

      final fileName = attachment.fileName.toLowerCase();
      final originalFileName = attachment.originalFileName?.toLowerCase() ?? '';
      final previewText = attachment.previewText?.toLowerCase() ?? '';
      return fileName.contains(normalizedKeyword) ||
          originalFileName.contains(normalizedKeyword) ||
          previewText.contains(normalizedKeyword);
    }).toList()
      ..sort(_compareAttachments);

    if (notify) {
      notifyListeners();
    }
  }

  bool _matchesFilter(Attachment attachment) {
    if (_missingSourceOnly) {
      if (attachment.storageMode != AttachmentStorageMode.linked ||
          attachment.sourceStatus != AttachmentSourceStatus.missing) {
        return false;
      }
    }

    switch (_activeStorageFilter) {
      case FilesLibraryStorageFilter.all:
        return true;
      case FilesLibraryStorageFilter.managed:
        return attachment.storageMode == AttachmentStorageMode.managed;
      case FilesLibraryStorageFilter.linked:
        return attachment.storageMode == AttachmentStorageMode.linked;
    }
  }

  int _compareAttachments(Attachment left, Attachment right) {
    switch (_activeSort) {
      case FilesLibrarySort.updatedAtDesc:
        final updatedAtCompare = right.updatedAt.compareTo(left.updatedAt);
        if (updatedAtCompare != 0) {
          return updatedAtCompare;
        }
        return left.fileName.toLowerCase().compareTo(right.fileName.toLowerCase());
      case FilesLibrarySort.fileNameAsc:
        final fileNameCompare = left.fileName.toLowerCase().compareTo(right.fileName.toLowerCase());
        if (fileNameCompare != 0) {
          return fileNameCompare;
        }
        return right.updatedAt.compareTo(left.updatedAt);
      case FilesLibrarySort.fileSizeDesc:
        final sizeCompare = right.sizeBytes.compareTo(left.sizeBytes);
        if (sizeCompare != 0) {
          return sizeCompare;
        }
        return left.fileName.toLowerCase().compareTo(right.fileName.toLowerCase());
    }
  }
}