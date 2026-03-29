import 'package:flutter/material.dart';

import '../../models/home_daily_brief.dart';
import 'home_overview_actions.dart';

Future<void> handleHomeDailyBriefAction(
  BuildContext context,
  HomeDailyBriefActionType action,
  String? targetId,
) async {
  switch (action) {
    case HomeDailyBriefActionType.openContact:
      if (targetId == null || targetId.isEmpty) {
        await openContactsFromHome(context);
        return;
      }
      await openContactDetailFromHome(context, targetId);
    case HomeDailyBriefActionType.openEvent:
      if (targetId == null || targetId.isEmpty) {
        await openEventsFromHome(context);
        return;
      }
      await openEventDetailFromHome(context, targetId);
    case HomeDailyBriefActionType.openTodos:
      await openTodosFromHome(context);
    case HomeDailyBriefActionType.openEventsToday:
      await openEventsFromHome(context, initialSelectedDate: DateTime.now());
    case HomeDailyBriefActionType.openSummaries:
      await openSummariesFromHome(context);
    case HomeDailyBriefActionType.createFollowUpEvent:
      await createEventFromHomeWithInitialStart(
        context,
        initialStartAt: DateTime.now(),
      );
  }
}