import 'package:flutter/material.dart';

import '../../config/app_constants.dart';

class ContactAlphabetIndexBar extends StatelessWidget {
  final List<String> indices;
  final String? selectedIndex;
  final ValueChanged<String> onSelected;

  const ContactAlphabetIndexBar({
    super.key,
    required this.indices,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (indices.length <= 1) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemCount = indices.length;
        final spacingCount = itemCount - 1;
        final spacing = constraints.maxHeight.isFinite && constraints.maxHeight < 560
            ? 0.0
            : AppSpacing.xs.toDouble();
        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight - (AppSpacing.xs * 2) - (spacingCount * spacing)
            : itemCount * 20;
        final itemHeight = (availableHeight / itemCount).clamp(12.0, 24.0);
        final fontSize = (itemHeight * 0.52).clamp(8.0, 11.0);

        return Container(
          width: 32,
          margin: const EdgeInsets.only(left: AppSpacing.sm),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...indices.indexed.map(
                (entry) {
                  final index = entry.$1;
                  final label = entry.$2;
                  final isLast = index == indices.length - 1;

                  return Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : spacing),
                    child: _AlphabetIndexItem(
                      key: ValueKey('contactAlphabetIndex_$label'),
                      label: label,
                      selected: selectedIndex == label,
                      itemHeight: itemHeight,
                      fontSize: fontSize,
                      onTap: () => onSelected(label),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AlphabetIndexItem extends StatelessWidget {
  final String label;
  final bool selected;
  final double itemHeight;
  final double fontSize;
  final VoidCallback onTap;

  const _AlphabetIndexItem({
    super.key,
    required this.label,
    required this.selected,
    required this.itemHeight,
    required this.fontSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          width: 24,
          height: itemHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? colorScheme.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: fontSize,
              color: selected ? colorScheme.onPrimaryContainer : colorScheme.outline,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}