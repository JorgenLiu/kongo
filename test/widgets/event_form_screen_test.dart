import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:kongo/providers/event_provider.dart';
import 'package:kongo/providers/tag_provider.dart';
import 'package:kongo/screens/events/event_form_screen.dart';

import '../test_helpers/test_app_harness.dart';

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxAttempts = 60,
}) async {
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }

  fail('Timed out waiting for expected widget');
}

Widget buildEventFormScreen(TestAppHarness harness) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<EventProvider>.value(value: harness.dependencies.eventProvider),
      ChangeNotifierProvider<TagProvider>.value(value: harness.dependencies.tagProvider),
    ],
    child: const MaterialApp(
      home: EventFormScreen(),
      debugShowCheckedModeBanner: false,
    ),
  );
}

void main() {
  late TestAppHarness harness;

  setUp(() async {
    harness = await createTestAppHarness();
    await harness.dependencies.eventProvider.loadFormOptions();
    await harness.dependencies.tagProvider.loadTags();
  });

  tearDown(() async {
    await harness.dispose();
  });

  testWidgets('Event form participants use search results instead of rendering the full contact list', (
    WidgetTester tester,
  ) async {
    late String zhangSanId;
    await tester.runAsync(() async {
      final contacts = await harness.dependencies.contactService.getContacts();
      zhangSanId = contacts.firstWhere((contact) => contact.name == '张三').id;
    });

    await tester.pumpWidget(buildEventFormScreen(harness));
    await pumpUntilFound(tester, find.byKey(const Key('eventForm_participantSearchField')));

    expect(find.byType(CheckboxListTile), findsNothing);
    expect(find.text('输入关键词或选择分组后，再从结果里添加联系人。'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('eventForm_participantSearchField')),
      '张三',
    );
    await tester.pumpAndSettle();

    expect(find.byKey(Key('eventForm_addParticipant_$zhangSanId')), findsOneWidget);
  });

  testWidgets('Event form can add a participant from search results', (
    WidgetTester tester,
  ) async {
    late String zhangSanId;
    await tester.runAsync(() async {
      final contacts = await harness.dependencies.contactService.getContacts();
      zhangSanId = contacts.firstWhere((contact) => contact.name == '张三').id;
    });

    await tester.pumpWidget(buildEventFormScreen(harness));
    await pumpUntilFound(tester, find.byKey(const Key('eventForm_participantSearchField')));

    await tester.enterText(
      find.byKey(const Key('eventForm_participantSearchField')),
      '138 0000 0001',
    );
    await tester.pumpAndSettle();

    final candidateButton = find.byKey(Key('eventForm_addParticipant_$zhangSanId'));
    expect(candidateButton, findsOneWidget);
    await tester.ensureVisible(candidateButton);
    await tester.pumpAndSettle();
    await tester.tap(candidateButton);
    await tester.pumpAndSettle();

    expect(find.byKey(Key('eventForm_removeParticipant_$zhangSanId')), findsOneWidget);
    expect(find.byKey(Key('eventForm_selectedParticipant_$zhangSanId')), findsOneWidget);
  });
}