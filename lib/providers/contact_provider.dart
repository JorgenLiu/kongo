import '../models/contact.dart';
import '../models/contact_draft.dart';
import 'base_provider.dart';
import '../services/contact_service.dart';

class ContactProvider extends BaseProvider {
  final ContactService _contactService;

  ContactProvider(this._contactService);

  List<Contact> _contacts = const [];
  Contact? _currentContact;
  String _keyword = '';
  List<String> _selectedTagIds = const [];

  List<Contact> get contacts => _contacts;
  Contact? get currentContact => _currentContact;
  String get keyword => _keyword;
  List<String> get selectedTagIds => _selectedTagIds;

  Future<void> loadContacts() async {
    await execute(() async {
      _keyword = '';
      _selectedTagIds = const [];
      _contacts = await _contactService.getContacts();
      markInitialized();
    });
  }

  Future<void> searchByKeyword(String keyword) async {
    await execute(() async {
      _keyword = keyword;
      _selectedTagIds = const [];
      _contacts = await _contactService.searchByKeyword(keyword);
      markInitialized();
    });
  }

  Future<void> searchByTags(List<String> tagIds) async {
    await execute(() async {
      _keyword = '';
      _selectedTagIds = tagIds.where((tagId) => tagId.trim().isNotEmpty).toSet().toList();
      _contacts = await _contactService.searchByTags(tagIds);
      markInitialized();
    });
  }

  Future<void> clearFilters() async {
    await loadContacts();
  }

  Future<void> createContact(ContactDraft draft) async {
    await execute(() async {
      _currentContact = await _contactService.createContact(draft);
      await _reloadCurrentView();
    });
  }

  Future<void> updateContact(Contact contact, {List<String>? tagIds}) async {
    await execute(() async {
      _currentContact = await _contactService.updateContact(contact, tagIds: tagIds);
      await _reloadCurrentView();
    });
  }

  Future<void> deleteContact(String id) async {
    await execute(() async {
      await _contactService.deleteContact(id);
      if (_currentContact?.id == id) {
        _currentContact = null;
      }
      await _reloadCurrentView();
    });
  }

  void setCurrentContact(Contact contact) {
    _currentContact = contact;
    notifyListeners();
  }

  Future<void> _reloadCurrentView() async {
    if (_selectedTagIds.isNotEmpty) {
      _contacts = await _contactService.searchByTags(_selectedTagIds);
      return;
    }

    if (_keyword.trim().isEmpty) {
      _contacts = await _contactService.getContacts();
      return;
    }

    _contacts = await _contactService.searchByKeyword(_keyword);
  }
}