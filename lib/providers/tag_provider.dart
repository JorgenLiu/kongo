import '../models/tag.dart';
import '../models/tag_draft.dart';
import '../services/tag_service.dart';
import 'base_provider.dart';

class TagProvider extends BaseProvider {
  final TagService _tagService;

  TagProvider(this._tagService);

  List<Tag> _tags = const [];
  String _keyword = '';

  List<Tag> get tags => _tags;
  String get keyword => _keyword;

  Future<void> loadTags() async {
    await execute(() async {
      _keyword = '';
      _tags = await _tagService.getTags();
      markInitialized();
    });
  }

  Future<void> searchByKeyword(String keyword) async {
    await execute(() async {
      _keyword = keyword;
      final allTags = await _tagService.getTags();
      final normalizedKeyword = keyword.trim().toLowerCase();
      _tags = normalizedKeyword.isEmpty
          ? allTags
          : allTags.where((tag) => tag.name.toLowerCase().contains(normalizedKeyword)).toList();
      markInitialized();
    });
  }

  Future<void> createTag(TagDraft draft) async {
    await execute(() async {
      await _tagService.createTag(draft);
      await _reloadCurrentView();
    });
  }

  Future<void> updateTag(Tag tag) async {
    await execute(() async {
      await _tagService.updateTag(tag);
      await _reloadCurrentView();
    });
  }

  Future<void> deleteTag(String id) async {
    await execute(() async {
      await _tagService.deleteTag(id);
      await _reloadCurrentView();
    });
  }

  Future<List<Tag>> getContactTags(String contactId) {
    return _tagService.getContactTags(contactId);
  }

  Future<void> _reloadCurrentView() async {
    final allTags = await _tagService.getTags();
    if (_keyword.trim().isEmpty) {
      _tags = allTags;
      return;
    }

    final normalizedKeyword = _keyword.trim().toLowerCase();
    _tags = allTags.where((tag) => tag.name.toLowerCase().contains(normalizedKeyword)).toList();
  }
}