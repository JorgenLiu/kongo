import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kongo/models/contact_draft.dart';
import 'package:kongo/models/contact_milestone.dart';
import 'package:kongo/models/contact_milestone_draft.dart';
import 'package:kongo/widgets/contact/contact_card.dart';
import 'package:kongo/widgets/contact/contact_alphabet_index_bar.dart';
import 'package:kongo/screens/contacts/contacts_list_screen.dart';
import 'package:kongo/services/read/contact_read_service.dart';
import 'package:kongo/services/read/notes_read_service.dart';
import 'package:kongo/services/read/todo_read_service.dart';

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
  await tester.pump(const Duration(seconds: 11));
}

Widget buildContactsScreen(TestAppHarness harness) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: harness.dependencies.contactProvider),
      ChangeNotifierProvider.value(value: harness.dependencies.tagProvider),
      Provider<ContactReadService>.value(value: harness.dependencies.contactReadService),
      Provider<TodoReadService>.value(value: harness.dependencies.todoReadService),
      Provider<NotesReadService>.value(value: harness.dependencies.notesReadService),
    ],
    child: const MaterialApp(
      home: ContactsListScreen(),
      debugShowCheckedModeBanner: false,
    ),
  );
}

void main() {
  late TestAppHarness harness;

  setUp(() async {
    harness = await createTestAppHarness();
    await harness.dependencies.contactProvider.loadContacts();
    await harness.dependencies.tagProvider.loadTags();
  });

  tearDown(() async {
    await harness.dispose();
  });

  Future<void> openContactsTab(WidgetTester tester) async {
    await pumpUntilFound(tester, find.byKey(const Key('contactsBodyCountLabel')));
    await pumpUntilFound(tester, find.text('搜索联系人...'));
  }

  testWidgets('Contacts screen renders database contacts', (WidgetTester tester) async {
    await tester.pumpWidget(buildContactsScreen(harness));
    await openContactsTab(tester);

    expect(find.byKey(const Key('contactsPageHeaderTitle')), findsOneWidget);
    expect(find.byKey(const Key('contactsBodyCountLabel')), findsOneWidget);
    expect(find.text('搜索联系人...'), findsOneWidget);
    expect(find.byType(ContactCard), findsWidgets);
    expect(find.byIcon(Icons.filter_list_outlined), findsNothing);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
  });

  testWidgets('Contacts screen searches through provider data', (WidgetTester tester) async {
    await tester.pumpWidget(buildContactsScreen(harness));
    await openContactsTab(tester);

    await tester.enterText(find.byType(TextField), '138 0000 0001');
    await tester.runAsync(() async {
      await harness.dependencies.contactProvider.searchByKeyword('138 0000 0001');
    });
    await pumpUntilFound(tester, find.text('1 人').last);

    expect(find.byType(ContactCard), findsOneWidget);
    expect(find.byKey(const Key('contactsBodyCountLabel')), findsOneWidget);
  });

  testWidgets('Contact detail screen opens from the contacts list', (
    WidgetTester tester,
  ) async {
    var targetName = '';

    await tester.runAsync(() async {
      final contacts = await harness.dependencies.contactService.getContacts();
      for (final contact in contacts) {
        final events = await harness.dependencies.contactService.getContactEvents(contact.id);
        if (events.isEmpty) {
          continue;
        }

        targetName = contact.name;
        break;
      }
    });

    expect(targetName, isNotEmpty);

    await tester.pumpWidget(buildContactsScreen(harness));
    await openContactsTab(tester);

    final targetCard = find.ancestor(
      of: find.text(targetName).first,
      matching: find.byType(ContactCard),
    );
    await tester.scrollUntilVisible(
      targetCard.first,
      200,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(targetCard.first);
    await tester.pump(const Duration(milliseconds: 300));
    await pumpUntilFound(tester, find.text('联系人详情'));

    expect(find.text('联系人详情'), findsOneWidget);
    expect(find.text(targetName), findsWidgets);

    await drainPendingDatabaseTimers(tester);

  });

  testWidgets('Alphabet index bar adapts to constrained height without overflow', (
    WidgetTester tester,
  ) async {
    final indices = List<String>.generate(26, (index) => String.fromCharCode(65 + index));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 32,
              height: 500,
              child: ContactAlphabetIndexBar(
                indices: indices,
                selectedIndex: null,
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('Z'), findsOneWidget);
  });

  testWidgets('Contacts screen groups English and Chinese names under the same initial and keeps English first', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(() async {
      await harness.dependencies.contactProvider.createContact(
        const ContactDraft(name: 'Chris Li', phone: '139 0000 0101'),
      );
      await harness.dependencies.contactProvider.createContact(
        const ContactDraft(name: '陈硕', phone: '139 0000 0102'),
      );
    });

    await tester.pumpWidget(buildContactsScreen(harness));
    await openContactsTab(tester);
    await pumpUntilFound(tester, find.byKey(const ValueKey('contactGroup_C')));

    expect(find.byKey(const ValueKey('contactGroup_C')), findsOneWidget);
    expect(find.text('Chris Li'), findsOneWidget);
    expect(find.text('陈硕'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Chris Li')).dy,
      lessThan(tester.getTopLeft(find.text('陈硕')).dy),
    );
  });

  testWidgets('Contacts screen quick index scrolls to the selected letter group', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.runAsync(() async {
      for (var index = 0; index < 18; index++) {
        final codePoint = 72 + index;
        final label = String.fromCharCode(codePoint);
        await harness.dependencies.contactProvider.createContact(
          ContactDraft(
            name: '$label 联系人',
            phone: '139 0000 ${2000 + index}',
          ),
        );
      }
    });

    await tester.pumpWidget(buildContactsScreen(harness));
    await openContactsTab(tester);
    await pumpUntilFound(tester, find.byType(ContactAlphabetIndexBar));
    await pumpUntilFound(tester, find.byKey(const ValueKey('contactGroup_Z')));

    final targetGroup = find.byKey(const ValueKey('contactGroup_Z'));
    expect(tester.getTopLeft(targetGroup).dy, greaterThan(700));

    await tester.tap(find.byKey(const ValueKey('contactAlphabetIndex_Z')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(targetGroup).dy, lessThan(520));
  });

  testWidgets('Contacts screen shows upcoming important dates in overview mode', (
    WidgetTester tester,
  ) async {
    final firstContact = harness.dependencies.contactProvider.contacts.first;
    final today = DateTime.now();

    await tester.runAsync(() async {
      await harness.dependencies.contactMilestoneService.createMilestone(
        firstContact.id,
        ContactMilestoneDraft(
          type: ContactMilestoneType.birthday,
          milestoneDate: DateTime(today.year - 20, today.month, today.day + 2),
          isRecurring: true,
        ),
      );
      await harness.dependencies.contactProvider.loadContacts();
    });

    await tester.pumpWidget(buildContactsScreen(harness));
    await openContactsTab(tester);
    await pumpUntilFound(tester, find.text('即将到来的重要日期'));

    expect(find.text('即将到来的重要日期'), findsOneWidget);
    expect(find.text(firstContact.name), findsWidgets);
    expect(find.textContaining('生日'), findsWidgets);
  });
}