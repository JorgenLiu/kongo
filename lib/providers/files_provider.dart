import '../models/attachment.dart';
import '../services/attachment_service.dart';
import 'base_provider.dart';

class FilesProvider extends BaseProvider {
  final AttachmentService _attachmentService;

  FilesProvider(this._attachmentService);

  List<Attachment> _allFiles = const [];
  List<Attachment> _files = const [];
  String _keyword = '';

  List<Attachment> get files => _files;
  String get keyword => _keyword;

  Future<void> loadFiles() async {
    await execute(() async {
      _keyword = '';
      _allFiles = await _attachmentService.getAllAttachments();
      _files = _allFiles;
      markInitialized();
    });
  }

  void searchByKeyword(String keyword) {
    _keyword = keyword;
    final normalizedKeyword = keyword.trim().toLowerCase();
    if (normalizedKeyword.isEmpty) {
      _files = _allFiles;
      notifyListeners();
      return;
    }

    _files = _allFiles.where((attachment) {
      final fileName = attachment.fileName.toLowerCase();
      final originalFileName = attachment.originalFileName?.toLowerCase() ?? '';
      final previewText = attachment.previewText?.toLowerCase() ?? '';
      return fileName.contains(normalizedKeyword) ||
          originalFileName.contains(normalizedKeyword) ||
          previewText.contains(normalizedKeyword);
    }).toList();
    notifyListeners();
  }

  Future<void> openFile(Attachment attachment) async {
    await execute(() async {
      await _attachmentService.openAttachment(attachment);
    });
  }
}