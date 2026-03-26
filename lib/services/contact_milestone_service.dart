import 'package:uuid/uuid.dart';

import '../exceptions/app_exception.dart';
import '../models/contact_milestone.dart';
import '../models/contact_milestone_draft.dart';
import '../repositories/contact_milestone_repository.dart';
import '../repositories/contact_repository.dart';
import '../utils/text_normalize.dart';

abstract class ContactMilestoneService {
  Future<List<ContactMilestone>> getAllMilestones();
  Future<List<ContactMilestone>> getMilestones(String contactId);
  Future<ContactMilestone> getMilestone(String id);
  Future<ContactMilestone> createMilestone(String contactId, ContactMilestoneDraft draft);
  Future<ContactMilestone> updateMilestone(ContactMilestone milestone);
  Future<void> deleteMilestone(String id);
  Future<List<ContactMilestone>> getUpcomingMilestones({int days = 30});
}

class DefaultContactMilestoneService implements ContactMilestoneService {
  final ContactMilestoneRepository _milestoneRepository;
  final ContactRepository _contactRepository;
  final Uuid _uuid;

  DefaultContactMilestoneService(
    this._milestoneRepository,
    this._contactRepository, {
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  @override
  Future<List<ContactMilestone>> getAllMilestones() {
    return _milestoneRepository.getAll();
  }

  @override
  Future<List<ContactMilestone>> getMilestones(String contactId) async {
    await _contactRepository.getById(contactId);
    return _milestoneRepository.getByContactId(contactId);
  }

  @override
  Future<ContactMilestone> getMilestone(String id) {
    return _milestoneRepository.getById(id);
  }

  @override
  Future<ContactMilestone> createMilestone(
    String contactId,
    ContactMilestoneDraft draft,
  ) async {
    await _contactRepository.getById(contactId);

        if (draft.type == ContactMilestoneType.custom) {
      final label = draft.label?.trim();
      if (label == null || label.isEmpty) {
            throw const ValidationException(
              message: '自定义重要日期必须填写名称',
          code: 'milestone_label_required',
        );
      }
    }

    final now = DateTime.now();
    final milestone = ContactMilestone(
      id: _uuid.v4(),
      contactId: contactId,
      type: draft.type,
      label: normalizeOptionalText(draft.label),
      milestoneDate: draft.milestoneDate,
      isLunar: draft.isLunar,
      isRecurring: draft.isRecurring,
      reminderEnabled: draft.reminderEnabled,
      reminderDaysBefore: draft.reminderDaysBefore,
      notes: normalizeOptionalText(draft.notes),
      createdAt: now,
      updatedAt: now,
    );

    return _milestoneRepository.insert(milestone);
  }

  @override
  Future<ContactMilestone> updateMilestone(ContactMilestone milestone) async {
    await _milestoneRepository.getById(milestone.id);

    if (milestone.type == ContactMilestoneType.custom) {
      final label = milestone.label?.trim();
      if (label == null || label.isEmpty) {
            throw const ValidationException(
              message: '自定义重要日期必须填写名称',
          code: 'milestone_label_required',
        );
      }
    }

    final updated = milestone.copyWith(updatedAt: DateTime.now());
    return _milestoneRepository.update(updated);
  }

  @override
  Future<void> deleteMilestone(String id) async {
    await _milestoneRepository.getById(id);
    await _milestoneRepository.delete(id);
  }

  @override
  Future<List<ContactMilestone>> getUpcomingMilestones({int days = 30}) {
    return _milestoneRepository.getUpcoming(days: days);
  }

}
