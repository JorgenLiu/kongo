import 'package:uuid/uuid.dart';

import '../exceptions/app_exception.dart';
import '../models/contact.dart';
import '../models/contact_draft.dart';
import '../models/event.dart';
import '../models/tag.dart';
import '../repositories/contact_repository.dart';
import '../repositories/event_repository.dart';
import '../repositories/tag_repository.dart';

abstract class ContactService {
  Future<List<Contact>> getContacts();
  Future<Contact> getContact(String id);
  Future<Contact> createContact(ContactDraft draft);
  Future<Contact> updateContact(Contact contact, {List<String>? tagIds});
  Future<void> deleteContact(String id);
  Future<List<Contact>> searchByKeyword(String keyword);
  Future<List<Contact>> searchByTags(List<String> tagIds);
  Future<List<Event>> getContactEvents(String contactId);
  Future<List<Tag>> getContactTags(String contactId);
}

class DefaultContactService implements ContactService {
  final ContactRepository _contactRepository;
  final TagRepository _tagRepository;
  final EventRepository _eventRepository;
  final Uuid _uuid;

  DefaultContactService(
    this._contactRepository,
    this._tagRepository,
    this._eventRepository, {
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  @override
  Future<List<Contact>> getContacts() {
    return _contactRepository.getAll();
  }

  @override
  Future<Contact> getContact(String id) {
    return _contactRepository.getById(id);
  }

  @override
  Future<Contact> createContact(ContactDraft draft) async {
    final normalizedName = draft.name.trim();
    if (normalizedName.isEmpty) {
      throw const ValidationException(message: '联系人名称不能为空', code: 'contact_name_required');
    }

    final uniqueTagIds = draft.tagIds.toSet().toList();
    for (final tagId in uniqueTagIds) {
      await _tagRepository.getById(tagId);
    }

    final now = DateTime.now();
    final contact = Contact(
      id: _uuid.v4(),
      name: normalizedName,
      phone: _normalizeOptionalText(draft.phone),
      email: _normalizeOptionalText(draft.email),
      address: _normalizeOptionalText(draft.address),
      avatar: _normalizeOptionalText(draft.avatar),
      notes: _normalizeOptionalText(draft.notes),
      createdAt: now,
      updatedAt: now,
    );

    final created = await _contactRepository.insert(contact);
    for (final tagId in uniqueTagIds) {
      await _tagRepository.addToContact(created.id, tagId);
    }

    return _contactRepository.getById(created.id);
  }

  @override
  Future<Contact> updateContact(Contact contact, {List<String>? tagIds}) async {
    final normalizedName = contact.name.trim();
    if (normalizedName.isEmpty) {
      throw const ValidationException(message: '联系人名称不能为空', code: 'contact_name_required');
    }

    await _contactRepository.getById(contact.id);

    final normalizedTagIds = tagIds?.where((tagId) => tagId.trim().isNotEmpty).toSet().toList();
    if (normalizedTagIds != null) {
      for (final tagId in normalizedTagIds) {
        await _tagRepository.getById(tagId);
      }
    }

    final updated = contact.copyWith(
      name: normalizedName,
      phone: _normalizeOptionalText(contact.phone),
      email: _normalizeOptionalText(contact.email),
      address: _normalizeOptionalText(contact.address),
      avatar: _normalizeOptionalText(contact.avatar),
      notes: _normalizeOptionalText(contact.notes),
      updatedAt: DateTime.now(),
    );

    final saved = await _contactRepository.update(updated);

    if (normalizedTagIds != null) {
      await _syncContactTags(contact.id, normalizedTagIds);
      return _contactRepository.getById(contact.id);
    }

    return saved;
  }

  @override
  Future<void> deleteContact(String id) async {
    await _contactRepository.getById(id);
    await _contactRepository.delete(id);
  }

  @override
  Future<List<Contact>> searchByKeyword(String keyword) {
    return _contactRepository.searchByKeyword(keyword);
  }

  @override
  Future<List<Contact>> searchByTags(List<String> tagIds) async {
    final uniqueTagIds = tagIds.where((tagId) => tagId.trim().isNotEmpty).toSet().toList();
    if (uniqueTagIds.isEmpty) {
      return getContacts();
    }

    for (final tagId in uniqueTagIds) {
      await _tagRepository.getById(tagId);
    }

    return _contactRepository.searchByTagIds(uniqueTagIds);
  }

  @override
  Future<List<Event>> getContactEvents(String contactId) async {
    await _contactRepository.getById(contactId);
    return _eventRepository.getByContactId(contactId);
  }

  @override
  Future<List<Tag>> getContactTags(String contactId) async {
    await _contactRepository.getById(contactId);
    return _tagRepository.getTagsForContact(contactId);
  }

  String? _normalizeOptionalText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  Future<void> _syncContactTags(String contactId, List<String> targetTagIds) async {
    final currentTags = await _tagRepository.getTagsForContact(contactId);
    final currentTagIds = currentTags.map((tag) => tag.id).toSet();
    final targetTagIdSet = targetTagIds.toSet();

    for (final tagId in currentTagIds.difference(targetTagIdSet)) {
      await _tagRepository.removeFromContact(contactId, tagId);
    }

    for (final tagId in targetTagIdSet.difference(currentTagIds)) {
      await _tagRepository.addToContact(contactId, tagId);
    }
  }
}