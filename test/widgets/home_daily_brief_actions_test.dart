import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:kongo/config/ai_config_store.dart';
import 'package:kongo/config/app_theme.dart';
import 'package:kongo/models/home_daily_brief.dart';
import 'package:kongo/providers/calendar_time_node_settings_provider.dart';
import 'package:kongo/providers/contact_detail_provider.dart';
import 'package:kongo/providers/contact_provider.dart';
import 'package:kongo/providers/event_detail_provider.dart';
import 'package:kongo/providers/event_provider.dart';
import 'package:kongo/providers/events_list_provider.dart';
import 'package:kongo/providers/files_provider.dart';
import 'package:kongo/providers/summary_provider.dart';
import 'package:kongo/providers/tag_provider.dart';
import 'package:kongo/providers/theme_notifier.dart';
import 'package:kongo/providers/todo_board_provider.dart';
import 'package:kongo/screens/home/home_daily_brief_actions.dart';
import 'package:kongo/services/contact_milestone_service.dart';
import 'package:kongo/services/contact_service.dart';
import 'package:kongo/services/event_service.dart';
import 'package:kongo/services/read/contact_read_service.dart';
import 'package:kongo/services/read/event_read_service.dart';
import 'package:kongo/services/read/summary_read_service.dart';
import 'package:kongo/services/read/notes_read_service.dart';
import 'package:kongo/services/read/todo_read_service.dart';
import 'package:kongo/services/settings_preferences_store.dart';
import 'package:kongo/services/summary_service.dart';

import '../test_helpers/test_app_harness.dart';

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxAttempts = 100,
}) async {
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }

  fail('Timed out waiting for expected widget');
}

Future<void> popCurrentRoute(WidgetTester tester) async {
  final navigatorState = tester.state<NavigatorState>(find.byType(Navigator).first);
  navigatorState.pop();
  await tester.pumpAndSettle();
}

Future<void> waitUntil(
  WidgetTester tester,
  bool Function() predicate, {
  int maxAttempts = 100,
}) async {
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    if (predicate()) {
      await tester.pump();
      return;
    }

    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });
    await tester.pump();
  }

  fail('Timed out waiting for expected state');
}

Future<void> waitForContactDetailReady(WidgetTester tester) async {
  final titleFinder = find.text('联系人详情');
  await pumpUntilFound(tester, titleFinder);
  final context = tester.element(titleFinder);
  final provider = Provider.of<ContactDetailProvider>(context, listen: false);
  await waitUntil(tester, () => !provider.loading && provider.data != null);
}

Future<void> waitForEventDetailReady(WidgetTester tester) async {
  final titleFinder = find.text('事件详情');
  await pumpUntilFound(tester, titleFinder);
  final context = tester.element(titleFinder);
  final provider = Provider.of<EventDetailProvider>(context, listen: false);
  await waitUntil(tester, () => !provider.loading && provider.data != null);
}

Future<void> waitForEventsListReady(WidgetTester tester) async {
  final titleFinder = find.byKey(const Key('eventsPageHeaderTitle'));
  await pumpUntilFound(tester, titleFinder);
  final context = tester.element(titleFinder);
  final provider = Provider.of<EventsListProvider>(context, listen: false);
  await waitUntil(tester, () => !provider.loading && provider.data != null);
}

Future<void> waitForEventFormReady(WidgetTester tester) async {
  final titleFinder = find.text('新建事件');
  await pumpUntilFound(tester, titleFinder);
  final context = tester.element(titleFinder);
  final provider = Provider.of<EventProvider>(context, listen: false);
  await waitUntil(tester, () => !provider.loading);
}

void main() {
  late TestAppHarness harness;
  late String contactId;
  late String eventId;

  setUp(() async {
    harness = await createTestAppHarness();
    await harness.dependencies.contactProvider.loadContacts();
    await harness.dependencies.tagProvider.loadTags();
    await harness.dependencies.summaryProvider.loadSummaries();
    await harness.dependencies.filesProvider.loadFiles();
    await harness.dependencies.todoBoardProvider.load();

    final contacts = await harness.dependencies.contactService.getContacts();
    contactId = contacts.firstWhere((contact) => contact.name == '张三').id;

    final events = await harness.dependencies.eventReadService.getEventsList();
    eventId = events.items.first.event.id;
  });

  tearDown(() async {
    await harness.dispose();
  });

  testWidgets('Home daily brief actions open detail screens and modules', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildActionTestApp(harness, contactId, eventId));

    await tester.tap(find.byKey(const Key('briefAction_openContact')));
    await tester.pump();
    await waitForContactDetailReady(tester);
    expect(find.text('联系人详情'), findsOneWidget);

    await popCurrentRoute(tester);

    await tester.tap(find.byKey(const Key('briefAction_openEvent')));
    await tester.pump();
    await waitForEventDetailReady(tester);
    expect(find.text('事件详情'), findsOneWidget);

    await popCurrentRoute(tester);

    await tester.tap(find.byKey(const Key('briefAction_openTodos')));
    await tester.pump();
    await pumpUntilFound(tester, find.byKey(const Key('todoPageHeaderTitle')));
    expect(find.byKey(const Key('todoPageHeaderTitle')), findsOneWidget);

    await popCurrentRoute(tester);

    await tester.tap(find.byKey(const Key('briefAction_openSummaries')));
    await tester.pump();
    await pumpUntilFound(tester, find.byKey(const Key('summaryPageHeaderTitle')));
    expect(find.byKey(const Key('summaryPageHeaderTitle')), findsOneWidget);
  });

  testWidgets('Home daily brief actions open today events and follow-up form', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildActionTestApp(harness, contactId, eventId));

    await tester.tap(find.byKey(const Key('briefAction_openEventsToday')));
    await tester.pump();
    await waitForEventsListReady(tester);
    expect(find.byKey(const Key('eventsPageHeaderTitle')), findsOneWidget);

    await popCurrentRoute(tester);

    await tester.tap(find.byKey(const Key('briefAction_createFollowUpEvent')));
    await tester.pump();
    await waitForEventFormReady(tester);
    expect(find.text('新建事件'), findsOneWidget);
  });
}

Widget buildActionTestApp(
  TestAppHarness harness,
  String contactId,
  String eventId,
) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => ThemeNotifier(harness.dependencies.settingsPreferencesStore),
      ),
      ChangeNotifierProvider(
        create: (_) => CalendarTimeNodeSettingsProvider(
          harness.dependencies.calendarTimeNodeSettingsService,
        ),
      ),
      ChangeNotifierProvider<ContactProvider>.value(
        value: harness.dependencies.contactProvider,
      ),
      ChangeNotifierProvider<EventProvider>.value(
        value: harness.dependencies.eventProvider,
      ),
      ChangeNotifierProvider<SummaryProvider>.value(
        value: harness.dependencies.summaryProvider,
      ),
      ChangeNotifierProvider<TagProvider>.value(
        value: harness.dependencies.tagProvider,
      ),
      ChangeNotifierProvider<TodoBoardProvider>.value(
        value: harness.dependencies.todoBoardProvider,
      ),
      ChangeNotifierProvider<FilesProvider>.value(
        value: harness.dependencies.filesProvider,
      ),
      Provider<AiConfigStore>.value(value: harness.dependencies.aiConfigStore),
      Provider<SettingsPreferencesStore>.value(
        value: harness.dependencies.settingsPreferencesStore,
      ),
      Provider<ContactService>.value(value: harness.dependencies.contactService),
      Provider<EventService>.value(value: harness.dependencies.eventService),
      Provider<SummaryService>.value(value: harness.dependencies.summaryService),
      Provider<ContactMilestoneService>.value(
        value: harness.dependencies.contactMilestoneService,
      ),
      Provider<ContactReadService>.value(
        value: harness.dependencies.contactReadService,
      ),
      Provider<EventReadService>.value(value: harness.dependencies.eventReadService),
      Provider<SummaryReadService>.value(
        value: harness.dependencies.summaryReadService,
      ),
      Provider<TodoReadService>.value(value: harness.dependencies.todoReadService),
      Provider<NotesReadService>.value(value: harness.dependencies.notesReadService),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: _ActionTestScreen(
          contactId: contactId,
          eventId: eventId,
        ),
      ),
    ),
  );
}

class _ActionTestScreen extends StatelessWidget {
  final String contactId;
  final String eventId;

  const _ActionTestScreen({
    required this.contactId,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ElevatedButton(
          key: const Key('briefAction_openContact'),
          onPressed: () => handleHomeDailyBriefAction(
            context,
            HomeDailyBriefActionType.openContact,
            contactId,
          ),
          child: const Text('openContact'),
        ),
        ElevatedButton(
          key: const Key('briefAction_openEvent'),
          onPressed: () => handleHomeDailyBriefAction(
            context,
            HomeDailyBriefActionType.openEvent,
            eventId,
          ),
          child: const Text('openEvent'),
        ),
        ElevatedButton(
          key: const Key('briefAction_openTodos'),
          onPressed: () => handleHomeDailyBriefAction(
            context,
            HomeDailyBriefActionType.openTodos,
            null,
          ),
          child: const Text('openTodos'),
        ),
        ElevatedButton(
          key: const Key('briefAction_openEventsToday'),
          onPressed: () => handleHomeDailyBriefAction(
            context,
            HomeDailyBriefActionType.openEventsToday,
            null,
          ),
          child: const Text('openEventsToday'),
        ),
        ElevatedButton(
          key: const Key('briefAction_openSummaries'),
          onPressed: () => handleHomeDailyBriefAction(
            context,
            HomeDailyBriefActionType.openSummaries,
            null,
          ),
          child: const Text('openSummaries'),
        ),
        ElevatedButton(
          key: const Key('briefAction_createFollowUpEvent'),
          onPressed: () => handleHomeDailyBriefAction(
            context,
            HomeDailyBriefActionType.createFollowUpEvent,
            null,
          ),
          child: const Text('createFollowUpEvent'),
        ),
      ],
    );
  }
}