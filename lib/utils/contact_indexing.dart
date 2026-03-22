import 'package:lpinyin/lpinyin.dart';

import '../models/contact.dart';

class ContactGroup {
  final String indexLabel;
  final List<Contact> contacts;

  const ContactGroup({
    required this.indexLabel,
    required this.contacts,
  });
}

List<ContactGroup> buildContactGroups(List<Contact> contacts) {
  final entries = contacts.map(_ContactIndexEntry.fromContact).toList()
    ..sort(_compareContactEntries);

  final groups = <ContactGroup>[];
  for (final entry in entries) {
    if (groups.isEmpty || groups.last.indexLabel != entry.indexLabel) {
      groups.add(ContactGroup(indexLabel: entry.indexLabel, contacts: [entry.contact]));
      continue;
    }

    groups.last.contacts.add(entry.contact);
  }

  return groups;
}

List<String> buildContactIndices(List<Contact> contacts) {
  return buildContactGroups(contacts).map((group) => group.indexLabel).toList();
}

String resolveContactIndexLabel(String name) {
  final leadingCharacter = _leadingCharacter(name);
  if (leadingCharacter.isEmpty) {
    return '#';
  }

  if (_latinInitialPattern.hasMatch(leadingCharacter)) {
    return leadingCharacter.toUpperCase();
  }

  final shortPinyin = PinyinHelper.getShortPinyin(leadingCharacter);
  if (shortPinyin.isNotEmpty) {
    final initial = shortPinyin.substring(0, 1).toUpperCase();
    if (_latinInitialPattern.hasMatch(initial)) {
      return initial;
    }
  }

  return '#';
}

bool isLatinLeadingName(String name) {
  return _latinInitialPattern.hasMatch(_leadingCharacter(name));
}

String resolveContactSortKey(String name) {
  final trimmedName = name.trim();
  if (trimmedName.isEmpty) {
    return '';
  }

  if (isLatinLeadingName(trimmedName)) {
    return trimmedName.toLowerCase();
  }

  return PinyinHelper.getPinyinE(
    trimmedName,
    separator: '',
    defPinyin: '#',
    format: PinyinFormat.WITHOUT_TONE,
  ).toLowerCase();
}

int compareContactIndexLabels(String left, String right) {
  if (left == right) {
    return 0;
  }
  if (left == '#') {
    return 1;
  }
  if (right == '#') {
    return -1;
  }
  return left.compareTo(right);
}

int _compareContactEntries(_ContactIndexEntry left, _ContactIndexEntry right) {
  final labelCompare = compareContactIndexLabels(left.indexLabel, right.indexLabel);
  if (labelCompare != 0) {
    return labelCompare;
  }

  if (left.isLatinLeadingName != right.isLatinLeadingName) {
    return left.isLatinLeadingName ? -1 : 1;
  }

  final sortKeyCompare = left.sortKey.compareTo(right.sortKey);
  if (sortKeyCompare != 0) {
    return sortKeyCompare;
  }

  return left.contact.name.compareTo(right.contact.name);
}

String _leadingCharacter(String name) {
  final trimmedName = name.trimLeft();
  if (trimmedName.isEmpty) {
    return '';
  }

  for (final rune in trimmedName.runes) {
    final character = String.fromCharCode(rune);
    if (_meaningfulCharacterPattern.hasMatch(character)) {
      return character;
    }
  }

  return trimmedName.substring(0, 1);
}

final RegExp _latinInitialPattern = RegExp(r'^[A-Z]$', caseSensitive: false);
final RegExp _meaningfulCharacterPattern = RegExp(r'[A-Za-z0-9\u4E00-\u9FFF]');

class _ContactIndexEntry {
  final Contact contact;
  final String indexLabel;
  final bool isLatinLeadingName;
  final String sortKey;

  const _ContactIndexEntry({
    required this.contact,
    required this.indexLabel,
    required this.isLatinLeadingName,
    required this.sortKey,
  });

  factory _ContactIndexEntry.fromContact(Contact contact) {
    return _ContactIndexEntry(
      contact: contact,
      indexLabel: resolveContactIndexLabel(contact.name),
      isLatinLeadingName: _resolveIsLatinLeadingName(contact.name),
      sortKey: resolveContactSortKey(contact.name),
    );
  }
}

bool _resolveIsLatinLeadingName(String name) {
  return isLatinLeadingName(name);
}