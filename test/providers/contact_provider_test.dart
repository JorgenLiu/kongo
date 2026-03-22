import 'package:flutter_test/flutter_test.dart';

import 'package:kongo/models/contact_draft.dart';
import 'package:kongo/models/tag_draft.dart';
import 'package:kongo/providers/provider_error.dart';

import '../test_helpers/test_app_harness.dart';

void main() {
  late TestAppHarness harness;

  setUp(() async {
    harness = await createTestAppHarness();
  });

  tearDown(() async {
    await harness.dispose();
  });

  test('ContactProvider loads seeded contacts from sqlite', () async {
    final provider = harness.dependencies.contactProvider;

    expect(provider.contacts.length, 7);
    expect(provider.contacts.any((contact) => contact.phone == '138 0000 0001'), isTrue);
    expect(provider.error, isNull);
  });

  test('ContactProvider filters contacts by keyword', () async {
    final provider = harness.dependencies.contactProvider;

    await provider.searchByKeyword('138 0000 0001');

    expect(provider.contacts.length, 1);
    expect(provider.contacts.single.phone, '138 0000 0001');
    expect(provider.error, isNull);
  });

  test('ContactProvider creates a contact and refreshes the current list', () async {
    final provider = harness.dependencies.contactProvider;

    await provider.createContact(
      const ContactDraft(
        name: 'Alice Chen',
        phone: '139 0000 1000',
        email: 'alice@example.com',
      ),
    );

    expect(provider.contacts.length, 8);
    expect(provider.contacts.any((contact) => contact.name == 'Alice Chen'), isTrue);
    expect(provider.error, isNull);
  });

  test('ContactProvider creates a contact with selected tags', () async {
    final provider = harness.dependencies.contactProvider;
    final vipTag = await harness.dependencies.tagService.createTag(
      const TagDraft(name: 'VIP'),
    );
    final followupTag = await harness.dependencies.tagService.createTag(
      const TagDraft(name: '待跟进'),
    );

    await provider.createContact(
      ContactDraft(
        name: 'Tagged Contact',
        phone: '139 0000 3000',
        tagIds: [vipTag.id, followupTag.id],
      ),
    );

    final created = provider.contacts.singleWhere((contact) => contact.name == 'Tagged Contact');
    expect(created.tags, containsAll(['VIP', '待跟进']));
    expect(provider.error, isNull);
  });

  test('ContactProvider updates an existing contact', () async {
    final provider = harness.dependencies.contactProvider;
    final contact = provider.contacts.first;

    await provider.updateContact(
      contact.copyWith(
        name: 'Updated Name',
        email: 'updated@example.com',
      ),
    );

    expect(provider.contacts.any((item) => item.name == 'Updated Name'), isTrue);
    expect(provider.contacts.any((item) => item.id == contact.id && item.email == 'updated@example.com'), isTrue);
    expect(provider.error, isNull);
  });

  test('ContactProvider updates contact tag relations', () async {
    final provider = harness.dependencies.contactProvider;
    final firstContact = provider.contacts.first;
    final vipTag = await harness.dependencies.tagService.createTag(
      const TagDraft(name: '重点客户'),
    );
    final partnerTag = await harness.dependencies.tagService.createTag(
      const TagDraft(name: '合作伙伴'),
    );

    await provider.updateContact(
      firstContact.copyWith(name: '张三-更新'),
      tagIds: [vipTag.id, partnerTag.id],
    );

    final tags = await harness.dependencies.contactService.getContactTags(firstContact.id);
    expect(tags.map((tag) => tag.name), containsAll(['重点客户', '合作伙伴']));
    expect(provider.contacts.any((item) => item.id == firstContact.id && item.tags.contains('重点客户')), isTrue);
    expect(provider.error, isNull);
  });

  test('ContactProvider filters contacts by tag ids and sorts by match count', () async {
    final provider = harness.dependencies.contactProvider;
    final vipTag = await harness.dependencies.tagService.createTag(
      const TagDraft(name: '高优先级'),
    );
    final followupTag = await harness.dependencies.tagService.createTag(
      const TagDraft(name: '待沟通'),
    );
    final contacts = await harness.dependencies.contactService.getContacts();
    await harness.dependencies.tagService.addTagToContact(contacts.first.id, vipTag.id);
    await harness.dependencies.tagService.addTagToContact(contacts.first.id, followupTag.id);
    await harness.dependencies.tagService.addTagToContact(contacts[1].id, vipTag.id);
    await provider.loadContacts();

    await provider.searchByTags([vipTag.id, followupTag.id]);

    expect(provider.contacts.length, 2);
    expect(provider.contacts.first.id, contacts.first.id);
    expect(provider.contacts[1].id, contacts[1].id);
    expect(provider.selectedTagIds, unorderedEquals([vipTag.id, followupTag.id]));
    expect(provider.error, isNull);
  });

  test('ContactProvider deletes an existing contact', () async {
    final provider = harness.dependencies.contactProvider;
    await provider.createContact(
      const ContactDraft(
        name: 'Delete Target',
        phone: '139 0000 2000',
        email: 'delete-target@example.com',
      ),
    );

    final contact = provider.contacts.singleWhere(
      (item) => item.phone == '139 0000 2000',
    );

    await provider.deleteContact(contact.id);

    expect(provider.contacts.length, 7);
    expect(provider.contacts.any((item) => item.id == contact.id), isFalse);
    expect(provider.error, isNull);
  });

  test('ContactProvider maps validation failures to structured errors', () async {
    final provider = harness.dependencies.contactProvider;

    await provider.createContact(
      const ContactDraft(name: '  '),
    );

    expect(provider.error, isNotNull);
    expect(provider.error?.type, ProviderErrorType.validation);
    expect(provider.error?.code, 'contact_name_required');
    expect(provider.error?.message, '联系人名称不能为空');
  });
}