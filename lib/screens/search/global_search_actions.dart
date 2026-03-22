import 'package:flutter/material.dart';

import '../../models/contact.dart';
import '../../models/event_summary.dart';
import '../../services/read/event_read_service.dart';
import '../contacts/contacts_list_actions.dart';
import '../events/events_list_actions.dart';
import '../summaries/summary_overview_actions.dart';

Future<void> openGlobalSearchContact(BuildContext context, Contact contact) {
  return openContactDetailFromList(context, contact);
}

Future<void> openGlobalSearchEvent(BuildContext context, EventListItemReadModel item) {
  return openScheduleDetailFromList(context, item.event.id);
}

Future<void> openGlobalSearchSummary(BuildContext context, DailySummary summary) {
  return editDailySummary(context, summary: summary);
}