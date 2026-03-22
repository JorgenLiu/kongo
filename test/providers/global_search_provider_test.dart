import 'package:flutter_test/flutter_test.dart';

import 'package:kongo/models/event_draft.dart';
import 'package:kongo/providers/global_search_provider.dart';

import '../test_helpers/test_app_harness.dart';

void main() {
  late TestAppHarness harness;

  setUp(() async {
    harness = await createTestAppHarness();
  });

  tearDown(() async {
    await harness.dispose();
  });

  test('GlobalSearchProvider searches across contacts events and summaries', () async {
    final provider = GlobalSearchProvider(
      harness.dependencies.contactService,
      harness.dependencies.eventReadService,
      harness.dependencies.summaryService,
    );

    await provider.search('报价');

    expect(provider.error, isNull);
    expect(provider.keyword, '报价');
    expect(provider.contacts, isEmpty);
    expect(provider.events.length, 1);
    expect(provider.events.first.event.title, '年度合作复盘');
    expect(provider.summaries.length, 1);
    expect(provider.summaries.first.tomorrowPlan, contains('报价方案'));
    expect(provider.totalResults, 2);
  });

  test('GlobalSearchProvider ranks title hits ahead of description hits', () async {
    final contacts = await harness.dependencies.contactService.getContacts();
    await harness.dependencies.eventService.createEvent(
      EventDraft(
        title: '报价讨论',
        eventTypeId: 'evt-meeting',
        createdByContactId: contacts.first.id,
        participantIds: [contacts.first.id, contacts[1].id],
      ),
    );

    final provider = GlobalSearchProvider(
      harness.dependencies.contactService,
      harness.dependencies.eventReadService,
      harness.dependencies.summaryService,
    );

    await provider.search('报价');

    expect(provider.error, isNull);
    expect(provider.events, isNotEmpty);
    expect(provider.events.first.event.title, '报价讨论');
  });
}