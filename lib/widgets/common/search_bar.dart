import 'package:flutter/material.dart';
import '../../config/app_constants.dart';

/// 搜索框
class SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;
  final VoidCallback? onClear;

  const SearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = '搜索联系人...',
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final shadowOpacity = Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.06;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final hasValue = value.text.trim().isNotEmpty;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: hasValue
                    ? colorScheme.primary.withValues(alpha: 0.55)
                    : colorScheme.outlineVariant,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: shadowOpacity),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.md),
                  child: Icon(
                    Icons.search,
                    size: 18,
                    color: hasValue ? colorScheme.primary : colorScheme.outline,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    cursorColor: colorScheme.primary,
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: TextStyle(color: colorScheme.outline),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                if (hasValue)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    color: colorScheme.outline,
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                      onClear?.call();
                    },
                  )
                else
                  const SizedBox(width: AppSpacing.sm),
              ],
            ),
          );
        },
      ),
    );
  }
}
