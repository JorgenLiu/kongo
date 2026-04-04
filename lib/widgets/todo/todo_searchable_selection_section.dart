import 'package:flutter/material.dart';

import '../../config/app_constants.dart';

class TodoSearchableSelectionSection<T> extends StatefulWidget {
  final String title;
  final String searchLabel;
  final String emptyMessage;
  final String noMatchMessage;
  final String selectedSectionTitle;
  final String resultsSectionTitle;
  final List<T> items;
  final Set<String> selectedIds;
  final String Function(T item) idOf;
  final String Function(T item) labelOf;
  final List<String> Function(T item) searchTokensOf;
  final String? Function(T item)? subtitleOf;
  final Widget Function(BuildContext context, T item, bool selected)? leadingBuilder;
  final void Function(String id, bool selected) onChanged;
  final String keyPrefix;
  final Widget? trailing;
  final Widget? filtersSection;
  final TextEditingController? searchController;
  final bool Function(T item)? itemFilter;
  final String? activeFilterLabel;
  final VoidCallback? onClearActiveFilter;

  const TodoSearchableSelectionSection({
    super.key,
    required this.title,
    required this.searchLabel,
    required this.emptyMessage,
    required this.noMatchMessage,
    this.selectedSectionTitle = '已选择',
    this.resultsSectionTitle = '搜索结果',
    required this.items,
    required this.selectedIds,
    required this.idOf,
    required this.labelOf,
    required this.searchTokensOf,
    this.subtitleOf,
    this.leadingBuilder,
    required this.onChanged,
    required this.keyPrefix,
    this.trailing,
    this.filtersSection,
    this.searchController,
    this.itemFilter,
    this.activeFilterLabel,
    this.onClearActiveFilter,
  });

  @override
  State<TodoSearchableSelectionSection<T>> createState() =>
      _TodoSearchableSelectionSectionState<T>();
}

class _TodoSearchableSelectionSectionState<T>
    extends State<TodoSearchableSelectionSection<T>> {
  late TextEditingController _searchController;
  late final ScrollController _scrollController;
  late bool _ownsSearchController;

  @override
  void initState() {
    super.initState();
    _ownsSearchController = widget.searchController == null;
    _searchController = widget.searchController ?? TextEditingController();
    _scrollController = ScrollController();
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void didUpdateWidget(covariant TodoSearchableSelectionSection<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchController != widget.searchController) {
      _searchController.removeListener(_handleSearchChanged);
      if (_ownsSearchController) {
        _searchController.dispose();
      }
      _ownsSearchController = widget.searchController == null;
      _searchController = widget.searchController ?? TextEditingController();
      _searchController.addListener(_handleSearchChanged);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.removeListener(_handleSearchChanged);
    if (_ownsSearchController) {
      _searchController.dispose();
    }
    super.dispose();
  }

  void _handleSearchChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final filteredItems = _filterItems();
    final selectedItems = widget.items
        .where((item) => widget.selectedIds.contains(widget.idOf(item)))
        .toList(growable: false)
      ..sort((left, right) =>
          widget.labelOf(left).compareTo(widget.labelOf(right)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.title,
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (widget.trailing != null) widget.trailing!,
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (widget.filtersSection != null) ...[
          widget.filtersSection!,
          const SizedBox(height: AppSpacing.sm),
        ],
        if (widget.activeFilterLabel != null && widget.activeFilterLabel!.trim().isNotEmpty) ...[
          Container(
            key: Key('${widget.keyPrefix}_activeFilterBar'),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Icon(Icons.tune_rounded, size: 16, color: colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    widget.activeFilterLabel!,
                    key: Key('${widget.keyPrefix}_activeFilterLabel'),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (widget.onClearActiveFilter != null)
                  TextButton(
                    key: Key('${widget.keyPrefix}_clearActiveFilterButton'),
                    onPressed: widget.onClearActiveFilter,
                    child: const Text('清除'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        TextField(
          key: Key('${widget.keyPrefix}_searchField'),
          controller: _searchController,
          decoration: InputDecoration(
            labelText: widget.searchLabel,
            prefixIcon: const Icon(Icons.search_outlined),
            suffixIcon: _searchController.text.trim().isEmpty
                ? null
                : IconButton(
                    tooltip: '清空搜索',
                    onPressed: _searchController.clear,
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
              if (selectedItems.isNotEmpty) ...[
                Text(
                  widget.selectedSectionTitle,
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: selectedItems
                      .map(
                        (item) => _SelectedEntityCard(
                          key: Key('${widget.keyPrefix}_selected_${widget.idOf(item)}'),
                          label: widget.labelOf(item),
                          subtitle: widget.subtitleOf?.call(item),
                          leading: widget.leadingBuilder?.call(context, item, true),
                          onRemove: () => widget.onChanged(widget.idOf(item), false),
                          removeButtonKey: Key('${widget.keyPrefix}_removeSelected_${widget.idOf(item)}'),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Text(
                widget.resultsSectionTitle,
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
        if (_searchController.text.trim().isEmpty &&
            (widget.activeFilterLabel == null ||
                widget.activeFilterLabel!.trim().isEmpty))
          Text(
            '\u8f93\u5165\u5173\u952e\u8bcd\u5f00\u59cb\u641c\u7d22',
            style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
          )
        else if (widget.items.isEmpty)
          Text(
            widget.emptyMessage,
            style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
          )
        else if (filteredItems.isEmpty)
          Text(
            widget.noMatchMessage,
            style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
          )
        else
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: filteredItems.length > 5,
              child: ListView.separated(
                controller: _scrollController,
                shrinkWrap: true,
                itemCount: filteredItems.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: colorScheme.outlineVariant.withAlpha(90),
                ),
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  final id = widget.idOf(item);
                  final selected = widget.selectedIds.contains(id);
                  final subtitle = widget.subtitleOf?.call(item);

                  return ListTile(
                    key: Key('${widget.keyPrefix}_option_$id'),
                    dense: true,
                    onTap: () => widget.onChanged(id, !selected),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    leading: widget.leadingBuilder?.call(context, item, selected) ??
                        Icon(
                          selected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 18,
                          color: selected ? colorScheme.primary : colorScheme.outline,
                        ),
                    title: Text(
                      widget.labelOf(item),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: subtitle == null || subtitle.isEmpty
                        ? null
                        : Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                    trailing: selected
                        ? FilledButton.tonalIcon(
                            onPressed: () => widget.onChanged(id, false),
                            icon: const Icon(Icons.check_rounded, size: 16),
                            label: const Text('已选'),
                          )
                        : OutlinedButton(
                            onPressed: () => widget.onChanged(id, true),
                            child: const Text('添加'),
                          ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  List<T> _filterItems() {
    final normalizedKeyword = _searchController.text.trim().toLowerCase();
    final items = widget.items.where((item) {
      final itemFilter = widget.itemFilter;
      if (itemFilter != null && !itemFilter(item)) {
        return false;
      }

      if (normalizedKeyword.isEmpty) {
        return true;
      }

      final tokens = widget.searchTokensOf(item)
          .map((token) => token.trim().toLowerCase())
          .where((token) => token.isNotEmpty);
      return tokens.any((token) => token.contains(normalizedKeyword));
    }).toList(growable: false);

    items.sort((left, right) {
      final leftSelected = widget.selectedIds.contains(widget.idOf(left));
      final rightSelected = widget.selectedIds.contains(widget.idOf(right));
      if (leftSelected != rightSelected) {
        return leftSelected ? -1 : 1;
      }
      return widget.labelOf(left).compareTo(widget.labelOf(right));
    });
    return items;
  }
}

class _SelectedEntityCard extends StatelessWidget {
  final String label;
  final String? subtitle;
  final Widget? leading;
  final VoidCallback onRemove;
  final Key removeButtonKey;

  const _SelectedEntityCard({
    super.key,
    required this.label,
    required this.subtitle,
    required this.leading,
    required this.onRemove,
    required this.removeButtonKey,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 240),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 28),
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.outline,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                key: removeButtonKey,
                visualDensity: VisualDensity.compact,
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded, size: 16),
                tooltip: '移除',
              ),
            ),
          ],
        ),
      ),
    );
  }
}