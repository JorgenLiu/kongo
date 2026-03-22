import 'package:uuid/uuid.dart';

import '../exceptions/app_exception.dart';
import '../models/tag.dart';
import '../models/tag_draft.dart';
import '../repositories/contact_repository.dart';
import '../repositories/tag_repository.dart';

abstract class TagService {
  Future<List<Tag>> getTags();
  Future<Tag> getTag(String id);
  Future<Tag> createTag(TagDraft draft);
  Future<Tag> updateTag(Tag tag);
  Future<void> deleteTag(String id);
  Future<void> addTagToContact(String contactId, String tagId);
  Future<void> removeTagFromContact(String contactId, String tagId);
  Future<List<Tag>> getContactTags(String contactId);
  Future<int> getContactCountByTag(String tagId);
}

class DefaultTagService implements TagService {
  final TagRepository _tagRepository;
  final ContactRepository _contactRepository;
  final Uuid _uuid;

  DefaultTagService(
    this._tagRepository,
    this._contactRepository, {
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  @override
  Future<List<Tag>> getTags() {
    return _tagRepository.getAll();
  }

  @override
  Future<Tag> getTag(String id) {
    return _tagRepository.getById(id);
  }

  @override
  Future<Tag> createTag(TagDraft draft) async {
    final normalizedName = draft.name.trim();
    if (normalizedName.isEmpty) {
      throw const ValidationException(message: '标签名称不能为空', code: 'tag_name_required');
    }

    final now = DateTime.now();
    final tag = Tag(
      id: _uuid.v4(),
      name: normalizedName,
      color: _normalizeOptionalText(draft.color),
      createdAt: now,
      updatedAt: now,
    );

    return _tagRepository.insert(tag);
  }

  @override
  Future<Tag> updateTag(Tag tag) async {
    final normalizedName = tag.name.trim();
    if (normalizedName.isEmpty) {
      throw const ValidationException(message: '标签名称不能为空', code: 'tag_name_required');
    }

    await _tagRepository.getById(tag.id);
    return _tagRepository.update(
      tag.copyWith(
        name: normalizedName,
        color: _normalizeOptionalText(tag.color),
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> deleteTag(String id) async {
    await _tagRepository.getById(id);
    await _tagRepository.delete(id);
  }

  @override
  Future<void> addTagToContact(String contactId, String tagId) async {
    await _contactRepository.getById(contactId);
    await _tagRepository.getById(tagId);
    await _tagRepository.addToContact(contactId, tagId);
  }

  @override
  Future<void> removeTagFromContact(String contactId, String tagId) async {
    await _contactRepository.getById(contactId);
    await _tagRepository.getById(tagId);
    await _tagRepository.removeFromContact(contactId, tagId);
  }

  @override
  Future<List<Tag>> getContactTags(String contactId) async {
    await _contactRepository.getById(contactId);
    return _tagRepository.getTagsForContact(contactId);
  }

  @override
  Future<int> getContactCountByTag(String tagId) async {
    await _tagRepository.getById(tagId);
    return _tagRepository.getContactCountByTag(tagId);
  }

  String? _normalizeOptionalText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}