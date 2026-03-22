import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/contact.dart';
import '../../models/tag.dart';
import '../../utils/event_participant_roles.dart';

class EventFormParticipantsSection extends StatefulWidget {
  final List<Contact> contacts;
  final List<Tag> tags;
  final Map<String, String> selectedParticipantRoles;
  final ValueChanged<String> onParticipantToggled;
  final void Function(String contactId, String role) onParticipantRoleChanged;
  final String? errorText;

  const EventFormParticipantsSection({
    super.key,
    required this.contacts,
    required this.tags,
    required this.selectedParticipantRoles,
    required this.onParticipantToggled,
    required this.onParticipantRoleChanged,
    required this.errorText,
  });

  @override
  State<EventFormParticipantsSection> createState() => _EventFormParticipantsSectionState();
}

class _EventFormParticipantsSectionState extends State<EventFormParticipantsSection> {
  late final TextEditingController _searchController;
  final Set<String> _selectedTagIds = <String>{};

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedContacts = widget.contacts
        .where((contact) => widget.selectedParticipantRoles.containsKey(contact.id))
        .toList();
    final filteredContacts = _buildFilteredContacts();
    final hasActiveSearch =
        _searchController.text.trim().isNotEmpty || _selectedTagIds.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '参与人',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '先按姓名、电话或分组缩小范围，再把需要的人加入事件。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (widget.errorText != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                widget.errorText!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: AppFontSize.bodySmall,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('eventForm_participantSearchField'),
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '搜索联系人姓名、电话或邮箱',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.trim().isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
            ),
            if (widget.tags.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: widget.tags.map((tag) {
                  final selected = _selectedTagIds.contains(tag.id);
                  return FilterChip(
                    key: Key('eventForm_participantTag_${tag.id}'),
                    label: Text(tag.name),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        if (selected) {
                          _selectedTagIds.remove(tag.id);
                        } else {
                          _selectedTagIds.add(tag.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Text(
              '已选联系人 ${selectedContacts.length}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (selectedContacts.isEmpty)
              Text(
                '还没有参与人，搜索后添加。',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              Column(
                children: selectedContacts.map((contact) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _SelectedParticipantCard(
                      contact: contact,
                      role: widget.selectedParticipantRoles[contact.id] ?? EventParticipantRoles.participant,
                      onRoleChanged: (role) => widget.onParticipantRoleChanged(contact.id, role),
                      onRemove: () => widget.onParticipantToggled(contact.id),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: AppSpacing.md),
            Text(
              hasActiveSearch ? '搜索结果 ${filteredContacts.length}' : '搜索结果',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (widget.contacts.isEmpty)
              const Text('暂无可选联系人')
            else if (!hasActiveSearch)
              Text(
                '输入关键词或选择分组后，再从结果里添加联系人。',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else if (filteredContacts.isEmpty)
              Text(
                '没有匹配的联系人。',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              Column(
                children: filteredContacts.map((contact) {
                  final selected = widget.selectedParticipantRoles.containsKey(contact.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _ParticipantResultCard(
                      contact: contact,
                      selected: selected,
                      onToggle: () => widget.onParticipantToggled(contact.id),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  List<Contact> _buildFilteredContacts() {
    final keyword = _searchController.text.trim().toLowerCase();
    final results = widget.contacts.where((contact) {
      final matchesKeyword = keyword.isEmpty || _contactSearchText(contact).contains(keyword);
      final matchCount = _selectedTagIds
          .where((tagId) => contact.tags.contains(_resolveTagName(tagId)))
          .length;
      final matchesTags = _selectedTagIds.isEmpty || matchCount > 0;
      return matchesKeyword && matchesTags;
    }).toList();

    results.sort((left, right) {
      final leftMatches = _selectedTagIds
          .where((tagId) => left.tags.contains(_resolveTagName(tagId)))
          .length;
      final rightMatches = _selectedTagIds
          .where((tagId) => right.tags.contains(_resolveTagName(tagId)))
          .length;

      if (rightMatches != leftMatches) {
        return rightMatches.compareTo(leftMatches);
      }

      return left.name.compareTo(right.name);
    });

    return results;
  }

  String _contactSearchText(Contact contact) {
    return [
      contact.name,
      contact.phone ?? '',
      contact.email ?? '',
      ...contact.tags,
    ].join(' ').toLowerCase();
  }

  String _resolveTagName(String tagId) {
    for (final tag in widget.tags) {
      if (tag.id == tagId) {
        return tag.name;
      }
    }

    return '';
  }
}

class _ParticipantResultCard extends StatelessWidget {
  final Contact contact;
  final bool selected;
  final VoidCallback onToggle;

  const _ParticipantResultCard({
    required this.contact,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            alignment: Alignment.center,
            child: Text(
              contact.name.isNotEmpty ? contact.name[0] : '?',
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (contact.phone != null && contact.phone!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    contact.phone!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ],
                if (contact.tags.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: contact.tags.take(3).map((tagName) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Text(
                          tagName,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton.tonalIcon(
            key: Key(selected ? 'eventForm_removeParticipant_${contact.id}' : 'eventForm_addParticipant_${contact.id}'),
            onPressed: onToggle,
            icon: Icon(selected ? Icons.remove_circle_outline : Icons.add_circle_outline),
            label: Text(selected ? '移除' : '添加'),
          ),
        ],
      ),
    );
  }
}

class _SelectedParticipantCard extends StatelessWidget {
  final Contact contact;
  final String role;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback onRemove;

  const _SelectedParticipantCard({
    required this.contact,
    required this.role,
    required this.onRoleChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('eventForm_selectedParticipant_${contact.id}'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (contact.phone != null && contact.phone!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    contact.phone!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  key: Key('eventForm_participantRole_${contact.id}'),
                  initialValue: EventParticipantRoles.normalize(role),
                  decoration: const InputDecoration(
                    labelText: '关系角色',
                  ),
                  items: EventParticipantRoles.options
                      .map(
                        (option) => DropdownMenuItem<String>(
                          value: option.value,
                          child: Text(option.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      onRoleChanged(value);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            onPressed: onRemove,
            tooltip: '移除参与人',
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}