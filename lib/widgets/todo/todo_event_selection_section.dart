import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/event.dart';
import 'todo_searchable_selection_section.dart';

class TodoEventSelectionSection extends StatefulWidget {
  final List<Event> events;
  final Set<String> selectedIds;
  final List<String> selectedContactIds;
  final void Function(String id, bool selected) onChanged;
  final Future<void> Function(String keyword, List<String> selectedContactIds)?
      onQuickCreate;
  final bool creating;

  const TodoEventSelectionSection({
    super.key,
    required this.events,
    required this.selectedIds,
    required this.selectedContactIds,
    required this.onChanged,
    this.onQuickCreate,
    this.creating = false,
  });

  @override
  State<TodoEventSelectionSection> createState() =>
      _TodoEventSelectionSectionState();
}

class _TodoEventSelectionSectionState extends State<TodoEventSelectionSection> {
  late final TextEditingController _searchController;

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
    return TodoSearchableSelectionSection<Event>(
      title: '关联事件',
      searchLabel: '搜索事件',
      selectedSectionTitle: '已选事件',
      resultsSectionTitle: '事件结果',
      emptyMessage: '暂无可选事件',
      noMatchMessage: '没有匹配的事件',
      items: widget.events,
      selectedIds: widget.selectedIds,
      idOf: (item) => item.id,
      labelOf: (item) => item.title,
      searchTokensOf: (item) => [
        item.title,
        item.location ?? '',
        item.description ?? '',
      ],
      subtitleOf: (item) => item.location,
      leadingBuilder: (context, item, selected) => _EventLeadingBadge(selected: selected),
      keyPrefix: 'todoEvent',
      searchController: _searchController,
      trailing: TextButton.icon(
        key: const Key('todoEvent_quickCreateButton'),
        onPressed: widget.creating || widget.onQuickCreate == null
            ? null
            : () async {
                await widget.onQuickCreate!(
                  _searchController.text.trim(),
                  widget.selectedContactIds,
                );
              },
        icon: widget.creating
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.event_available_rounded, size: 18),
        label: const Text('新建事件'),
      ),
      onChanged: widget.onChanged,
    );
  }
}

class _EventLeadingBadge extends StatelessWidget {
  final bool selected;

  const _EventLeadingBadge({required this.selected});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: selected ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.event_outlined,
        size: 18,
        color: selected ? colorScheme.primary : colorScheme.outline,
      ),
    );
  }
}