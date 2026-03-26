import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:kongo/config/app_colors.dart';
import 'package:kongo/main.dart';
import 'package:kongo/models/attachment.dart';
import 'package:kongo/models/event.dart';
import 'package:kongo/providers/contact_detail_provider.dart';
import 'package:kongo/providers/calendar_time_node_settings_provider.dart';
import 'package:kongo/providers/home_provider.dart';
import 'package:kongo/providers/theme_notifier.dart';
import 'package:kongo/screens/app_shell_screen.dart';
import 'package:kongo/screens/settings/settings_overview_screen.dart';
import 'package:kongo/widgets/contact/contact_card.dart';
import 'package:kongo/widgets/event/attachment_list.dart';
import 'package:kongo/widgets/event/monthly_event_calendar.dart';

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

Future<void> pumpUntilGone(
  WidgetTester tester,
  Finder finder, {
  int maxAttempts = 100,
}) async {
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isEmpty) {
      return;
    }
  }

  fail('Timed out waiting for widget to disappear');
}

Future<void> drainPendingDatabaseTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

Future<void> waitForHomeOverviewReady(WidgetTester tester) async {
  final headerFinder = find.byKey(const Key('homePageHeaderTitle'));
  await pumpUntilFound(tester, headerFinder);
  final context = tester.element(headerFinder);
  final provider = Provider.of<HomeProvider>(context, listen: false);
  for (var attempt = 0; attempt < 100; attempt++) {
    if (!provider.loading) {
      await tester.pump();
      return;
    }

    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });
    await tester.pump();
  }

  fail('Timed out waiting for home provider to settle');
}

Future<void> waitForContactDetailReady(WidgetTester tester) async {
  final titleFinder = find.text('联系人详情');
  await pumpUntilFound(tester, titleFinder);
  final context = tester.element(titleFinder);
  final provider = Provider.of<ContactDetailProvider>(context, listen: false);
  for (var attempt = 0; attempt < 100; attempt++) {
    if (!provider.loading && provider.data != null) {
      await tester.pump();
      return;
    }

    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });
    await tester.pump();
  }

  fail('Timed out waiting for contact detail provider to settle');
}

void main() {
  late TestAppHarness harness;

  setUp(() async {
    harness = await createTestAppHarness();
    await harness.dependencies.contactProvider.loadContacts();
    await harness.dependencies.tagProvider.loadTags();
    await harness.dependencies.summaryProvider.loadSummaries();
    await harness.dependencies.filesProvider.loadFiles();
  });

  tearDown(() async {
    await harness.dispose();
  });

  testWidgets('App shell defaults to workbench and switches to summary module', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(dependencies: harness.dependencies));
    await waitForHomeOverviewReady(tester);
    final settingsProvider = Provider.of<CalendarTimeNodeSettingsProvider>(
      tester.element(find.byType(AppShellScreen)),
      listen: false,
    );
    expect(settingsProvider.loading, isA<bool>());

    expect(find.byKey(const Key('homePageHeaderTitle')), findsOneWidget);
  expect(find.text('本周概况'), findsOneWidget);
  expect(find.text('今日日程'), findsOneWidget);
  expect(find.text('今天暂无安排'), findsOneWidget);
  expect(find.text('新建事件'), findsOneWidget);
  expect(find.text('新建联系人'), findsOneWidget);
  expect(find.text('新总结'), findsNothing);
    expect(find.text('主页'), findsNothing);
    expect(find.text('标签'), findsNothing);

    await tester.tap(find.text('总结').last);
    await pumpUntilFound(tester, find.byKey(const Key('summaryPageHeaderTitle')));

    expect(find.byKey(const Key('summaryPageHeaderTitle')), findsOneWidget);
    expect(find.text('新建总结'), findsOneWidget);

    await drainPendingDatabaseTimers(tester);

  });

  testWidgets('App shell exposes global search entry', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(dependencies: harness.dependencies));
    await waitForHomeOverviewReady(tester);

    await tester.tap(find.text('检索').last);
    await pumpUntilFound(tester, find.byKey(const Key('globalSearchPageHeaderTitle')));

    expect(find.byKey(const Key('globalSearchPageHeaderTitle')), findsOneWidget);
    expect(find.text('输入关键词开始检索'), findsOneWidget);

    await drainPendingDatabaseTimers(tester);
  });

  testWidgets('Settings screen exposes tag management after tags leave bottom navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp(dependencies: harness.dependencies));
    await waitForHomeOverviewReady(tester);

    expect(find.text('标签').evaluate(), isEmpty);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => ThemeNotifier(harness.dependencies.settingsPreferencesStore),
          ),
          ChangeNotifierProvider(
            create: (_) => CalendarTimeNodeSettingsProvider(
              harness.dependencies.calendarTimeNodeSettingsService,
            ),
          ),
          ChangeNotifierProvider.value(value: harness.dependencies.contactProvider),
          ChangeNotifierProvider.value(value: harness.dependencies.tagProvider),
        ],
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: const SettingsOverviewScreen(),
        ),
      ),
    );
    await pumpUntilFound(tester, find.byKey(const Key('settingsPageHeaderTitle')));
    await tester.scrollUntilVisible(
      find.text('分组管理'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(find.text('分组管理'), findsOneWidget);

    await drainPendingDatabaseTimers(tester);
  });

  testWidgets('Desktop shell keeps left navigation when opening contact detail', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    await tester.binding.setSurfaceSize(const Size(1280, 800));

    try {
      await tester.pumpWidget(MyApp(dependencies: harness.dependencies));
      await pumpUntilFound(tester, find.text('Kongo'));
      await waitForHomeOverviewReady(tester);

      await tester.tap(find.byIcon(Icons.contacts_outlined).last);
      await pumpUntilFound(tester, find.byKey(const Key('contactsPageHeaderTitle')));

      await tester.tap(find.byType(ContactCard).first);
      await tester.pump();
      await pumpUntilFound(tester, find.text('联系人详情'));
      await waitForContactDetailReady(tester);

      expect(find.text('Kongo'), findsOneWidget);
      expect(find.text('联系人详情'), findsOneWidget);

      await drainPendingDatabaseTimers(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      await tester.binding.setSurfaceSize(null);
    }
  });

  testWidgets('Desktop shell keeps left navigation when opening tag management from contact form', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    await tester.binding.setSurfaceSize(const Size(1280, 800));

    try {
      await tester.pumpWidget(MyApp(dependencies: harness.dependencies));
      await pumpUntilFound(tester, find.text('Kongo'));
      await waitForHomeOverviewReady(tester);

      await tester.tap(find.byIcon(Icons.contacts_outlined).last);
      await pumpUntilFound(tester, find.byKey(const Key('contactsPageHeaderTitle')));

      await tester.tap(find.text('新建联系人').last);
      await tester.pump();
      await pumpUntilFound(tester, find.text('新建联系人'));

      await tester.tap(find.text('管理分组').last);
      await tester.pump();
      await pumpUntilFound(tester, find.text('分组管理'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Kongo'), findsOneWidget);
      expect(find.text('分组管理'), findsOneWidget);

      await drainPendingDatabaseTimers(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      await tester.binding.setSurfaceSize(null);
    }
  });

  testWidgets('Desktop shell prompts about unsaved contact form changes and returns modules to root', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    await tester.binding.setSurfaceSize(const Size(1280, 800));

    try {
      await tester.pumpWidget(MyApp(dependencies: harness.dependencies));
      await pumpUntilFound(tester, find.text('Kongo'));
      await waitForHomeOverviewReady(tester);

      await tester.tap(find.byIcon(Icons.contacts_outlined).last);
      await pumpUntilFound(tester, find.byKey(const Key('contactsPageHeaderTitle')));

      await tester.tap(find.text('新建联系人').last);
      await tester.pump();
      await pumpUntilFound(tester, find.text('新建联系人'));

      await tester.enterText(find.byKey(const Key('contactForm_nameField')), '未保存联系人');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.summarize_outlined).last, warnIfMissed: false);
      await tester.pump();
      await pumpUntilFound(tester, find.text('放弃未保存内容？'));

      expect(find.text('离开当前页面后，未保存的内容将会丢失。'), findsOneWidget);

      await tester.tap(find.byKey(const Key('discardChanges_continueEditingButton')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('新建联系人'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.summarize_outlined).last, warnIfMissed: false);
      await tester.pump();
      await pumpUntilFound(tester, find.text('放弃未保存内容？'));

      await tester.tap(find.byKey(const Key('discardChanges_discardButton')).last);
      await tester.pump();
      await pumpUntilFound(tester, find.byKey(const Key('summaryPageHeaderTitle')));

      await tester.tap(find.byIcon(Icons.contacts_outlined).last, warnIfMissed: false);
      await tester.pump();
      await pumpUntilFound(tester, find.byKey(const Key('contactsPageHeaderTitle')));

      expect(find.byKey(const Key('contactsPageHeaderTitle')), findsOneWidget);
      expect(find.byKey(const Key('contactForm_nameField')), findsNothing);

      await drainPendingDatabaseTimers(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      await tester.binding.setSurfaceSize(null);
    }
  });

  testWidgets('Desktop shell sidebar collapses and expands without exceptions', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    await tester.binding.setSurfaceSize(const Size(1280, 800));

    try {
      await tester.pumpWidget(MyApp(dependencies: harness.dependencies));
      await pumpUntilFound(tester, find.text('Kongo'));
      await waitForHomeOverviewReady(tester);

      await tester.tap(find.byTooltip('收起侧栏'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 260));

      expect(find.text('Kongo'), findsNothing);
      expect(find.text('K'), findsOneWidget);
      expect(find.byTooltip('展开侧栏'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('展开侧栏'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 260));

      expect(find.text('Kongo'), findsOneWidget);
      expect(find.byTooltip('收起侧栏'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await drainPendingDatabaseTimers(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      await tester.binding.setSurfaceSize(null);
    }
  });

  testWidgets('Monthly event calendar renders for seeded events', (WidgetTester tester) async {
    final now = DateTime.now();
    final events = [
      Event(
        id: 'event-1',
        title: '项目启动会',
        startAt: DateTime(now.year, now.month, 3, 9),
        createdAt: now,
        updatedAt: now,
      ),
      Event(
        id: 'event-2',
        title: '投资沟通',
        startAt: DateTime(now.year, now.month, 3, 14),
        createdAt: now,
        updatedAt: now,
      ),
      Event(
        id: 'event-3',
        title: '复盘会',
        startAt: DateTime(now.year, now.month, 18, 10),
        createdAt: now,
        updatedAt: now,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MonthlyEventCalendar(events: events),
        ),
      ),
    );

    expect(find.byKey(const Key('eventsMonthlyCalendar')), findsOneWidget);
    expect(find.textContaining('年'), findsWidgets);
    final eventDay = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('eventsMonthlyCalendar_day_3')),
        matching: find.text('3'),
      ),
    );
    expect(eventDay.style?.color, AppColors.warning);
  });

  testWidgets('Attachment list forwards open unlink and delete callbacks', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();
    final attachment = Attachment(
      id: 'attachment-test-id',
      fileName: 'demo.pdf',
      storagePath: '/tmp/demo.pdf',
      sizeBytes: 2048,
      createdAt: now,
      updatedAt: now,
    );

    Attachment? openedAttachment;
    Attachment? unlinkedAttachment;
    Attachment? deletedAttachment;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AttachmentList(
            attachments: [attachment],
            emptyText: 'empty',
            onTap: (value) => openedAttachment = value,
            onUnlink: (value) => unlinkedAttachment = value,
            onDelete: (value) => deletedAttachment = value,
          ),
        ),
      ),
    );

    await tester.tap(find.text('demo.pdf'));
    await tester.pump();
    expect(openedAttachment, attachment);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('移除关联'));
    await tester.pump();
    expect(unlinkedAttachment, attachment);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除附件'));
    await tester.pump();
    expect(deletedAttachment, attachment);
  });
}