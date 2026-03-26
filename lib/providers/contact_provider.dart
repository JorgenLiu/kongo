import '../models/contact.dart';
import '../models/contact_draft.dart';
import '../models/contact_upcoming_milestone.dart';
import 'base_provider.dart';
import '../services/contact_milestone_service.dart';
import '../services/contact_service.dart';

class ContactProvider extends BaseProvider {
  final ContactService _contactService;
  final ContactMilestoneService _contactMilestoneService;

  ContactProvider(this._contactService, this._contactMilestoneService);

  List<Contact> _contacts = const [];
  Contact? _currentContact;
  String _keyword = '';
  List<String> _selectedTagIds = const [];
  List<ContactUpcomingMilestone> _upcomingMilestones = const [];

  List<Contact> get contacts => _contacts;
  Contact? get currentContact => _currentContact;
  String get keyword => _keyword;
  List<String> get selectedTagIds => _selectedTagIds;
  List<ContactUpcomingMilestone> get upcomingMilestones => _upcomingMilestones;

  Future<void> loadContacts() async {
    await execute(() async {
      _keyword = '';
      _selectedTagIds = const [];
      _contacts = await _contactService.getContacts();
      await _refreshUpcomingMilestones();
      markInitialized();
    });
  }

  Future<void> searchByKeyword(String keyword) async {
    await execute(() async {
      _keyword = keyword;
      _selectedTagIds = const [];
      _contacts = await _contactService.searchByKeyword(keyword);
      await _refreshUpcomingMilestones();
      markInitialized();
    });
  }

  Future<void> searchByTags(List<String> tagIds) async {
    await execute(() async {
      _keyword = '';
      _selectedTagIds = tagIds.where((tagId) => tagId.trim().isNotEmpty).toSet().toList();
      _contacts = await _contactService.searchByTags(tagIds);
      await _refreshUpcomingMilestones();
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
      await _refreshUpcomingMilestones();
      return;
    }

    if (_keyword.trim().isEmpty) {
      _contacts = await _contactService.getContacts();
      await _refreshUpcomingMilestones();
      return;
    }

    _contacts = await _contactService.searchByKeyword(_keyword);
    await _refreshUpcomingMilestones();
  }

  Future<void> _refreshUpcomingMilestones() async {
    try {
      if (_contacts.isEmpty) {
        _upcomingMilestones = const [];
        return;
      }

      final visibleContacts = {
        for (final contact in _contacts) contact.id: contact,
      };
      final upcomingMilestones = await _contactMilestoneService.getUpcomingMilestones();
      final today = DateTime.now();

      _upcomingMilestones = upcomingMilestones
          .where((milestone) => visibleContacts.containsKey(milestone.contactId))
          .map((milestone) {
            final nextOccurrence = ContactUpcomingMilestone.resolveNextOccurrence(
              milestone,
              today,
            );
            if (nextOccurrence == null) {
              return null;
            }

            return ContactUpcomingMilestone(
              contact: visibleContacts[milestone.contactId]!,
              milestone: milestone,
              nextOccurrence: nextOccurrence,
              daysUntil: nextOccurrence
                  .difference(DateTime(today.year, today.month, today.day))
                  .inDays,
            );
          })
          .whereType<ContactUpcomingMilestone>()
          .toList(growable: false)
        ..sort((a, b) {
          final dayComparison = a.daysUntil.compareTo(b.daysUntil);
          if (dayComparison != 0) {
            return dayComparison;
          }

          final nameComparison = a.contact.name.compareTo(b.contact.name);
          if (nameComparison != 0) {
            return nameComparison;
          }

          return a.milestone.displayName.compareTo(b.milestone.displayName);
        });
    } catch (_) {
      _upcomingMilestones = const [];
    }
  }
}