import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/contact.dart';
import '../../models/tag.dart';
import 'todo_searchable_selection_section.dart';

class TodoContactSelectionSection extends StatefulWidget {
  final List<Contact> contacts;
  final List<Tag> tags;
  final Set<String> selectedIds;
  final void Function(String id, bool selected) onChanged;
  final Future<void> Function(String keyword)? onQuickCreate;
  final bool creating;

  const TodoContactSelectionSection({
    super.key,
    required this.contacts,
    required this.tags,
    required this.selectedIds,
    required this.onChanged,
    this.onQuickCreate,
    this.creating = false,
  });

  @override
  State<TodoContactSelectionSection> createState() =>
      _TodoContactSelectionSectionState();
}

class _TodoContactSelectionSectionState
    extends State<TodoContactSelectionSection> {
  late final TextEditingController _searchController;
  String? _selectedTagName;
  bool _tagsExpanded = false;

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
    return TodoSearchableSelectionSection<Contact>(
      title: '关联联系人',
      searchLabel: '搜索联系人',
      selectedSectionTitle: '已选联系人',
      resultsSectionTitle: '联系人结果',
      emptyMessage: '暂无可选联系人',
      noMatchMessage: '没有匹配的联系人',
      items: widget.contacts,
      selectedIds: widget.selectedIds,
      idOf: (item) => item.id,
      labelOf: (item) => item.name,
      searchTokensOf: (item) => [
        item.name,
        item.phone ?? '',
        item.email ?? '',
        ...item.tags,
      ],
      subtitleOf: (item) {
        if ((item.phone ?? '').isNotEmpty) {
          return item.phone;
        }
        if ((item.email ?? '').isNotEmpty) {
          return item.email;
        }
        if (item.tags.isNotEmpty) {
          return item.tags.join(' / ');
        }
        return null;
      },
      leadingBuilder: (context, item, selected) => _ContactAvatarBadge(
        name: item.name,
        selected: selected,
      ),
      keyPrefix: 'todoContact',
      searchController: _searchController,
      itemFilter: (item) =>
          _selectedTagName == null || item.tags.contains(_selectedTagName),
      activeFilterLabel:
          _selectedTagName == null ? null : '当前分组：$_selectedTagName',
      onClearActiveFilter: _selectedTagName == null
          ? null
          : () {
              setState(() {
                _selectedTagName = null;
              });
            },
      trailing: TextButton.icon(
        key: const Key('todoContact_quickCreateButton'),
        onPressed: widget.creating || widget.onQuickCreate == null
            ? null
            : () async {
                await widget.onQuickCreate!(_searchController.text.trim());
              },
        icon: widget.creating
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.person_add_alt_1_rounded, size: 18),
        label: const Text('新建联系人'),
      ),
      filtersSection: widget.tags.isEmpty
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '按分组筛选',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    ChoiceChip(
                      key: const Key('todoContact_filter_all'),
                      label: const Text('全部分组'),
                      selected: _selectedTagName == null,
                      onSelected: (_) {
                        setState(() {
                          _selectedTagName = null;
                        });
                      },
                    ),
                    ...(_tagsExpanded ? widget.tags : widget.tags.take(5)).map(
                      (tag) => ChoiceChip(
                        key: Key('todoContact_filter_${tag.id}'),
                        label: Text(tag.name),
                        selected: _selectedTagName == tag.name,
                        onSelected: (_) {
                          setState(() {
                            _selectedTagName = _selectedTagName == tag.name
                                ? null
                                : tag.name;
                          });
                        },
                      ),
                    ),
                    if (!_tagsExpanded && widget.tags.length > 5)
                      ActionChip(
                        label: Text('+${widget.tags.length - 5}'),
                        onPressed: () => setState(() => _tagsExpanded = true),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
              ],
            ),
      onChanged: widget.onChanged,
    );
  }
}

class _ContactAvatarBadge extends StatelessWidget {
  final String name;
  final bool selected;

  const _ContactAvatarBadge({
    required this.name,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initial = name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: selected ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: selected ? colorScheme.primary : colorScheme.onSurface,
        ),
      ),
    );
  }
}