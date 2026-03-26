import 'contact.dart';
import 'contact_milestone.dart';

class ContactUpcomingMilestone {
  final Contact contact;
  final ContactMilestone milestone;
  final DateTime nextOccurrence;
  final int daysUntil;

  const ContactUpcomingMilestone({
    required this.contact,
    required this.milestone,
    required this.nextOccurrence,
    required this.daysUntil,
  });

  static DateTime? resolveNextOccurrence(ContactMilestone milestone, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);

    if (!milestone.isRecurring) {
      final oneTimeDate = DateTime(
        milestone.milestoneDate.year,
        milestone.milestoneDate.month,
        milestone.milestoneDate.day,
      );
      if (oneTimeDate.isBefore(today)) {
        return null;
      }
      return oneTimeDate;
    }

    final thisYear = DateTime(
      today.year,
      milestone.milestoneDate.month,
      milestone.milestoneDate.day,
    );

    if (!thisYear.isBefore(today)) {
      return thisYear;
    }

    return DateTime(
      today.year + 1,
      milestone.milestoneDate.month,
      milestone.milestoneDate.day,
    );
  }
}