import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/todo_board_view_options.dart';

class TodoBoardFiltersBar extends StatelessWidget {
  final TodoGroupVisibility groupVisibility;
  final TodoItemFilter itemFilter;
  final TodoItemSort itemSort;
  final ValueChanged<TodoGroupVisibility> onGroupVisibilityChanged;
  final ValueChanged<TodoItemFilter> onItemFilterChanged;
  final ValueChanged<TodoItemSort> onItemSortChanged;

  const TodoBoardFiltersBar({
    super.key,
    required this.groupVisibility,
    required this.itemFilter,
    required this.itemSort,
    required this.onGroupVisibilityChanged,
    required this.onItemFilterChanged,
    required this.onItemSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
            _LabeledDropdown<TodoGroupVisibility>(
              label: '分组范围',
              value: groupVisibility,
              options: TodoGroupVisibility.values,
              labelOf: (item) => item.label,
              onChanged: onGroupVisibilityChanged,
            ),
            const SizedBox(width: AppSpacing.sm),
            _LabeledDropdown<TodoItemFilter>(
              label: '事项筛选',
              value: itemFilter,
              options: TodoItemFilter.values,
              labelOf: (item) => item.label,
              onChanged: onItemFilterChanged,
            ),
            const SizedBox(width: AppSpacing.sm),
            _LabeledDropdown<TodoItemSort>(
              label: '排序方式',
              value: itemSort,
              options: TodoItemSort.values,
              labelOf: (item) => item.label,
              onChanged: onItemSortChanged,
          ),
        ],
    );
  }
}

class _LabeledDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> options;
  final String Function(T value) labelOf;
  final ValueChanged<T> onChanged;

  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        );
    return DropdownMenu<T>(
      width: 160,
      initialSelection: value,
      label: Text(label),
      requestFocusOnTap: false,
      enableFilter: false,
      enableSearch: false,
      trailingIcon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: colorScheme.primary,
      ),
      selectedTrailingIcon: Icon(
        Icons.keyboard_arrow_up_rounded,
        color: colorScheme.primary,
      ),
      textStyle: textStyle,
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(colorScheme.surface),
        surfaceTintColor: WidgetStatePropertyAll(colorScheme.surface),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(color: colorScheme.outline),
          ),
        ),
        maximumSize: const WidgetStatePropertyAll(Size.fromHeight(280)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 10),
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.outline,
            ),
      ),
      dropdownMenuEntries: options
          .map(
            (item) => DropdownMenuEntry<T>(
              value: item,
              label: labelOf(item),
              style: ButtonStyle(
                textStyle: WidgetStatePropertyAll(textStyle),
              ),
            ),
          )
          .toList(growable: false),
      onSelected: (nextValue) {
        if (nextValue != null) onChanged(nextValue);
      },
    );
  }
}