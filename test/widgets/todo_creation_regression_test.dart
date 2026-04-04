import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:kongo/main.dart';
import 'package:kongo/models/contact.dart';
import 'package:kongo/models/contact_draft.dart';
import 'package:kongo/models/event.dart';
import 'package:kongo/models/tag.dart';
import 'package:kongo/models/tag_draft.dart';
import 'package:kongo/models/todo_item_draft.dart';
import 'package:kongo/providers/todo_board_provider.dart';
import 'package:kongo/screens/contacts/contact_detail_screen.dart';
import 'package:kongo/screens/events/event_detail_screen.dart';
import 'package:kongo/screens/todos/todo_board_screen.dart';
import 'package:kongo/services/read/contact_read_service.dart';
import 'package:kongo/services/read/event_read_service.dart';
import 'package:kongo/services/read/notes_read_service.dart';
import 'package:kongo/services/read/todo_read_service.dart';
import 'package:kongo/models/todo_group_draft.dart';
import 'package:kongo/widgets/todo/todo_item_form_dialog.dart';

import '../test_helpers/test_app_harness.dart';

Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() predicate, {
  int maxAttempts = 100,
}) async {
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (predicate()) {
      return;
    }
  }

  fail('Timed out waiting for expected state');
}

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

Future<void> pumpShortTransitions(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
}

Future<void> waitForAsyncCondition(
  WidgetTester tester,
  Future<bool> Function() predicate, {
  int maxAttempts = 100,
}) async {
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    final matched = await tester.runAsync(predicate) ?? false;
    if (matched) {
      await tester.pump();
      return;
    }
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });
    await tester.pump(const Duration(milliseconds: 100));
  }

  fail('Timed out waiting for async state');
}

void main() {
  late TestAppHarness harness;
  late String contactId;
  late String eventId;
  late String contactName;
  late String eventTitle;
  late Tag filterTag;
  late String taggedContactId;
  late String plainContactId;

  setUp(() async {
    harness = await createTestAppHarness();
    await harness.dependencies.contactProvider.loadContacts();
    await harness.dependencies.tagProvider.loadTags();
    final contacts = await harness.dependencies.contactService.getContacts();
    contactId = contacts.first.id;
    contactName = contacts.first.name;
    final events = await harness.dependencies.eventService.getEvents();
    eventId = events.first.id;
    eventTitle = events.first.title;
    await harness.dependencies.tagProvider.createTag(
      const TagDraft(name: '待办筛选组'),
    );
    filterTag = harness.dependencies.tagProvider.tags.firstWhere(
      (tag) => tag.name == '待办筛选组',
    );
    final taggedContact = await harness.dependencies.contactService.createContact(
      ContactDraft(
        name: '待办筛选联系人',
        tagIds: [filterTag.id],
      ),
    );
    final plainContact = await harness.dependencies.contactService.createContact(
      const ContactDraft(name: '待办普通联系人'),
    );
    taggedContactId = taggedContact.id;
    plainContactId = plainContact.id;
    await harness.dependencies.todoService.createGroup(
      const TodoGroupDraft(title: '待办创建回归组'),
    );
    await harness.dependencies.todoBoardProvider.load();
    await harness.dependencies.tagProvider.loadTags();
  });

  tearDown(() async {
    await harness.dispose();
  });

  testWidgets('Creating first item in an empty todo group does not throw', (
    WidgetTester tester,
  ) async {
    final provider = harness.dependencies.todoBoardProvider;
    await tester.binding.setSurfaceSize(const Size(1280, 900));

    await tester.pumpWidget(
      ChangeNotifierProvider<TodoBoardProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: TodoBoardScreen(showAppBar: true),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );

    await pumpUntil(
      tester,
      () => find.text('「待办创建回归组」中还没有待办项').evaluate().isNotEmpty,
    );

    await tester.tap(find.widgetWithText(FilledButton, '新增待办项').first);
    await pumpUntil(
      tester,
      () => find.widgetWithText(TextFormField, '待办项标题').evaluate().isNotEmpty,
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, '待办项标题'),
      '首条待办项',
    );
    await tester.tap(find.text('保存'));
    await pumpShortTransitions(tester);
    await waitForAsyncCondition(
      tester,
      () async => provider.data?.selectedGroup?.rootItems.length == 1,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('首条待办项'), findsOneWidget);
    expect(provider.data?.selectedGroup?.rootItems, hasLength(1));

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('Creating first linked todo from contact detail refreshes current page', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<TodoBoardProvider>.value(
            value: harness.dependencies.todoBoardProvider,
          ),
          Provider<ContactReadService>.value(
            value: harness.dependencies.contactReadService,
          ),
          Provider<TodoReadService>.value(
            value: harness.dependencies.todoReadService,
          ),
          Provider<NotesReadService>.value(
            value: harness.dependencies.notesReadService,
          ),
        ],
        child: MaterialApp(
          home: ContactDetailScreen(contactId: contactId),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );

    await waitForAsyncCondition(
      tester,
      () async => find.text('相关待办').evaluate().isNotEmpty,
    );
    await waitForAsyncCondition(
      tester,
      () async =>
          find.text('当前还没有关联到这个联系人的待办项。').evaluate().isNotEmpty,
    );

    await tester.tap(find.text('新建关联待办'));
    await pumpUntil(
      tester,
      () => find.text('选择待办组').evaluate().isNotEmpty,
    );

    await tester.tap(find.text('下一步'));
    await pumpUntil(
      tester,
      () => find.widgetWithText(TextFormField, '待办项标题').evaluate().isNotEmpty,
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, '待办项标题'),
      '联系人详情首条关联待办',
    );
    await tester.tap(find.text('保存'));
    await pumpShortTransitions(tester);
    await waitForAsyncCondition(
      tester,
      () async => find.text('联系人详情首条关联待办').evaluate().isNotEmpty,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('联系人详情首条关联待办'), findsOneWidget);
    expect(find.text('当前还没有关联到这个联系人的待办项。'), findsNothing);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('Creating first linked todo from event detail refreshes current page', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<TodoBoardProvider>.value(
            value: harness.dependencies.todoBoardProvider,
          ),
          Provider<EventReadService>.value(
            value: harness.dependencies.eventReadService,
          ),
          Provider<TodoReadService>.value(
            value: harness.dependencies.todoReadService,
          ),
          Provider<NotesReadService>.value(
            value: harness.dependencies.notesReadService,
          ),
        ],
        child: MaterialApp(
          home: EventDetailScreen(eventId: eventId),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );

    await waitForAsyncCondition(
      tester,
      () async => find.text('相关待办').evaluate().isNotEmpty,
    );
    await waitForAsyncCondition(
      tester,
      () async => find.text('当前还没有关联到这个事件的待办项。').evaluate().isNotEmpty,
    );

    await tester.tap(find.text('新建关联待办'));
    await pumpUntil(
      tester,
      () => find.text('选择待办组').evaluate().isNotEmpty,
    );

    await tester.tap(find.text('下一步'));
    await pumpUntil(
      tester,
      () => find.widgetWithText(TextFormField, '待办项标题').evaluate().isNotEmpty,
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, '待办项标题'),
      '事件详情首条关联待办',
    );
    await tester.tap(find.text('保存'));
    await pumpShortTransitions(tester);
    await waitForAsyncCondition(
      tester,
      () async => find.text('事件详情首条关联待办').evaluate().isNotEmpty,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('事件详情首条关联待办'), findsOneWidget);
    expect(find.text('当前还没有关联到这个事件的待办项。'), findsNothing);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('Creating todo item can search and select linked contact and event', (
    WidgetTester tester,
  ) async {
    final provider = harness.dependencies.todoBoardProvider;
    await tester.binding.setSurfaceSize(const Size(1280, 900));

    await tester.pumpWidget(
      ChangeNotifierProvider<TodoBoardProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: TodoBoardScreen(showAppBar: true),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );

    await pumpUntilFound(
      tester,
      find.text('「待办创建回归组」中还没有待办项'),
    );

    await tester.tap(find.widgetWithText(FilledButton, '新增待办项').first);
    await pumpUntilFound(
      tester,
      find.widgetWithText(TextFormField, '待办项标题'),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, '待办项标题'),
      '带关联信息的首条待办',
    );
    await tester.enterText(
      find.byKey(const Key('todoContact_searchField')),
      contactName,
    );
    await pumpShortTransitions(tester);
    await tester.tap(find.byKey(Key('todoContact_option_$contactId')));
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('todoEvent_searchField')),
      eventTitle,
    );
    await pumpShortTransitions(tester);
    final eventOptionFinder = find.byKey(Key('todoEvent_option_$eventId'));
    await tester.ensureVisible(eventOptionFinder);
    await tester.pump();
    await tester.tap(eventOptionFinder);
    await tester.pump();

    await tester.tap(find.text('保存'));
    await pumpShortTransitions(tester);
    await waitForAsyncCondition(
      tester,
      () async => provider.data?.selectedGroup?.rootItems.length == 1,
    );

    final createdNode = provider.data!.selectedGroup!.rootItems.first;
    expect(createdNode.item.title, '带关联信息的首条待办');
    expect(createdNode.contacts.map((item) => item.id), contains(contactId));
    expect(createdNode.events.map((item) => item.id), contains(eventId));
    expect(find.byKey(Key('todoContact_selected_$contactId')), findsNothing);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('Creating todo item supports quick create and tag-based contact filtering', (
    WidgetTester tester,
  ) async {
    TodoItemDraft? submittedDraft;
    String? quickCreatedContactId;
    String? quickCreatedEventId;
    await tester.binding.setSurfaceSize(const Size(1280, 900));

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  submittedDraft = await showTodoItemFormDialog(
                    context,
                    availableContacts:
                        harness.dependencies.todoBoardProvider.data?.availableContacts ??
                        const [],
                    availableEvents:
                        harness.dependencies.todoBoardProvider.data?.availableEvents ??
                        const [],
                    availableTags: harness.dependencies.tagProvider.tags,
                    onCreateContact: (keyword) async {
                      final now = DateTime.now();
                      final contact = Contact(
                        id: 'quick_contact_${now.microsecondsSinceEpoch}',
                        name: keyword,
                        createdAt: now,
                        updatedAt: now,
                      );
                      quickCreatedContactId = contact.id;
                      return contact;
                    },
                    onCreateEvent: (keyword, selectedContactIds) async {
                      final now = DateTime.now();
                      final participantIds = selectedContactIds.isNotEmpty
                          ? selectedContactIds
                          : [
                              if (quickCreatedContactId != null)
                                quickCreatedContactId!
                              else
                                taggedContactId,
                            ];
                      final event = Event(
                        id: 'quick_event_${now.microsecondsSinceEpoch}',
                        title: keyword,
                        createdByContactId: participantIds.first,
                        createdAt: now,
                        updatedAt: now,
                      );
                      quickCreatedEventId = event.id;
                      return event;
                    },
                  );
                },
                child: const Text('打开待办弹窗'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开待办弹窗'));
    await pumpUntilFound(
      tester,
      find.widgetWithText(TextFormField, '待办项标题'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Key('todoContact_filter_${filterTag.id}')));
    await tester.pump();
    expect(find.byKey(const Key('todoContact_activeFilterBar')), findsOneWidget);
    expect(find.text('当前分组：待办筛选组'), findsOneWidget);
    expect(find.byKey(Key('todoContact_option_$taggedContactId')), findsOneWidget);
    expect(find.byKey(Key('todoContact_option_$plainContactId')), findsNothing);

    await tester.tap(find.byKey(const Key('todoContact_filter_all')));
    await tester.pump();
    expect(find.byKey(const Key('todoContact_activeFilterBar')), findsNothing);

    await tester.enterText(
      find.byKey(const Key('todoContact_searchField')),
      '待办快速联系人',
    );
    await tester.tap(find.byKey(const Key('todoContact_quickCreateButton')));
    await pumpShortTransitions(tester);
    await pumpUntilFound(
      tester,
      find.byKey(Key('todoContact_selected_$quickCreatedContactId')),
    );

    expect(quickCreatedContactId, isNotNull);

    await tester.enterText(
      find.byKey(const Key('todoEvent_searchField')),
      '待办快速事件',
    );
    await tester.ensureVisible(find.byKey(const Key('todoEvent_quickCreateButton')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('todoEvent_quickCreateButton')));
    await pumpShortTransitions(tester);
    await pumpUntilFound(
      tester,
      find.byKey(Key('todoEvent_selected_$quickCreatedEventId')),
    );

    expect(quickCreatedEventId, isNotNull);

    await tester.enterText(
      find.widgetWithText(TextFormField, '待办项标题'),
      '带快速新建的待办项',
    );
    await tester.tap(find.text('保存'));
    await pumpShortTransitions(tester);
    expect(submittedDraft, isNotNull);
    expect(submittedDraft!.title, '带快速新建的待办项');
    expect(submittedDraft!.contactIds, contains(quickCreatedContactId));
    expect(submittedDraft!.eventIds, contains(quickCreatedEventId));

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('Creating first linked todo from contact detail works inside desktop shell', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    await tester.binding.setSurfaceSize(const Size(1280, 900));

    try {
      await tester.pumpWidget(MyApp(dependencies: harness.dependencies));
      await pumpUntilFound(tester, find.text('Kongo'));

      await tester.tap(find.byIcon(Icons.contacts_outlined).last);
      await pumpUntilFound(tester, find.byKey(const Key('contactsPageHeaderTitle')));
      await pumpUntilFound(tester, find.byType(InkWell));

      await tester.tap(find.text('张三').first);
      await waitForAsyncCondition(
        tester,
        () async => find.text('联系信息').evaluate().isNotEmpty,
      );
      await waitForAsyncCondition(
        tester,
        () async => find.text('当前还没有关联到这个联系人的待办项。').evaluate().isNotEmpty,
      );

      await tester.tap(find.text('新建关联待办'));
      await pumpUntilFound(tester, find.text('选择待办组'));

      await tester.tap(find.text('下一步'));
      await pumpUntilFound(
        tester,
        find.widgetWithText(TextFormField, '待办项标题'),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, '待办项标题'),
        '桌面壳层联系人首条关联待办',
      );
      await tester.tap(find.text('保存'));
      await pumpShortTransitions(tester);
      await waitForAsyncCondition(
        tester,
        () async => find.text('桌面壳层联系人首条关联待办').evaluate().isNotEmpty,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('桌面壳层联系人首条关联待办'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      await tester.binding.setSurfaceSize(null);
    }
  });

  testWidgets('Creating first item in an empty todo group works inside desktop shell', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    await tester.binding.setSurfaceSize(const Size(1280, 900));

    try {
      await tester.pumpWidget(MyApp(dependencies: harness.dependencies));
      await pumpUntilFound(tester, find.text('Kongo'));

      await tester.tap(find.byIcon(Icons.checklist_rtl_outlined).last);
      await pumpUntilFound(tester, find.byKey(const Key('todoPageHeaderTitle')));
      await pumpUntilFound(
        tester,
        find.text('「待办创建回归组」中还没有待办项'),
      );

      await tester.tap(find.widgetWithText(FilledButton, '新增待办项').first);
      await pumpUntilFound(
        tester,
        find.widgetWithText(TextFormField, '待办项标题'),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, '待办项标题'),
        '桌面壳层空组首条待办',
      );
      await tester.tap(find.text('保存'));
      await pumpShortTransitions(tester);
      await waitForAsyncCondition(
        tester,
        () async => find.text('桌面壳层空组首条待办').evaluate().isNotEmpty,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('桌面壳层空组首条待办'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      await tester.binding.setSurfaceSize(null);
    }
  });
}