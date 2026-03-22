import 'package:flutter_test/flutter_test.dart';

import 'package:kongo/models/contact.dart';
import 'package:kongo/utils/contact_indexing.dart';

void main() {
  final now = DateTime(2026, 3, 22, 10);

  Contact buildContact(String id, String name) {
    return Contact(
      id: id,
      name: name,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('Contact indexing resolves pinyin initial for Chinese names', () {
    expect(resolveContactIndexLabel('陈硕'), 'C');
    expect(resolveContactIndexLabel('张三'), 'Z');
    expect(resolveContactIndexLabel('Chris Li'), 'C');
  });

  test('Contact grouping keeps English names before Chinese names in the same initial group', () {
    final groups = buildContactGroups([
      buildContact('1', '陈硕'),
      buildContact('2', 'Chris Li'),
      buildContact('3', 'Charles Wang'),
      buildContact('4', '赵六'),
    ]);

    expect(groups.map((group) => group.indexLabel), ['C', 'Z']);
    expect(groups.first.contacts.map((contact) => contact.name), ['Charles Wang', 'Chris Li', '陈硕']);
  });
}