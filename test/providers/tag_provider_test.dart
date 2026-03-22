import 'package:flutter_test/flutter_test.dart';

import 'package:kongo/models/tag_draft.dart';

import '../test_helpers/test_app_harness.dart';

void main() {
  late TestAppHarness harness;

  setUp(() async {
    harness = await createTestAppHarness();
  });

  tearDown(() async {
    await harness.dispose();
  });

  test('TagProvider loads tags from sqlite', () async {
    final provider = harness.dependencies.tagProvider;
    await harness.dependencies.tagService.createTag(const TagDraft(name: '客户'));
    await harness.dependencies.tagService.createTag(const TagDraft(name: '合作'));

    await provider.loadTags();

    expect(provider.tags.map((tag) => tag.name), containsAll(['客户', '合作']));
    expect(provider.error, isNull);
  });

  test('TagProvider creates and searches tags', () async {
    final provider = harness.dependencies.tagProvider;

    await provider.createTag(const TagDraft(name: '重要联系人'));
    await provider.createTag(const TagDraft(name: '普通联系人'));
    await provider.searchByKeyword('重要');

    expect(provider.tags.length, 1);
    expect(provider.tags.single.name, '重要联系人');
    expect(provider.error, isNull);
  });

  test('TagProvider updates and deletes tags', () async {
    final provider = harness.dependencies.tagProvider;
    await provider.createTag(const TagDraft(name: '旧标签'));
    final tag = provider.tags.singleWhere((item) => item.name == '旧标签');

    await provider.updateTag(tag.copyWith(name: '新标签'));
    expect(provider.tags.any((item) => item.name == '新标签'), isTrue);

    final updated = provider.tags.singleWhere((item) => item.name == '新标签');
    await provider.deleteTag(updated.id);

    expect(provider.tags.any((item) => item.id == updated.id), isFalse);
    expect(provider.error, isNull);
  });

  test('TagProvider returns contact tags for editing forms', () async {
    final contact = (await harness.dependencies.contactService.getContacts()).first;
    final vipTag = await harness.dependencies.tagService.createTag(const TagDraft(name: 'VIP'));
    await harness.dependencies.tagService.addTagToContact(contact.id, vipTag.id);

    final tags = await harness.dependencies.tagProvider.getContactTags(contact.id);

    expect(tags.map((tag) => tag.id), contains(vipTag.id));
  });
}