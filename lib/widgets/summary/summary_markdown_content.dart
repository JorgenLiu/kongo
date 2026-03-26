import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../config/app_constants.dart';

class SummaryMarkdownContent extends StatelessWidget {
  final String content;
  final String emptyText;
  final bool selectable;

  const SummaryMarkdownContent({
    super.key,
    required this.content,
    this.emptyText = '未填写',
    this.selectable = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmedContent = content.trim();

    if (trimmedContent.isEmpty) {
      return Text(
        emptyText,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.outline,
        ),
      );
    }

    return MarkdownBody(
      data: _normalizeMarkdown(trimmedContent),
      selectable: selectable,
      shrinkWrap: true,
      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
        p: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface,
          height: 1.45,
        ),
        h1: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        h2: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        h3: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        listBullet: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
        blockquote: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.outline,
          fontStyle: FontStyle.italic,
        ),
        blockquotePadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        blockquoteDecoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border(
            left: BorderSide(
              color: theme.colorScheme.primary,
              width: 3,
            ),
          ),
        ),
        code: theme.textTheme.bodySmall?.copyWith(
          fontFamily: 'monospace',
          color: theme.colorScheme.primary,
        ),
        codeblockDecoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        codeblockPadding: const EdgeInsets.all(AppSpacing.sm),
      ),
    );
  }

  String _normalizeMarkdown(String input) {
    return input
        .split('\n')
        .map((line) => line
            .replaceFirstMapped(
              RegExp(r'^(\s*(?:-|\*)\s*)\[( |x|X)\]\s+(.+)$'),
              (match) {
                final prefix = match.group(1)!;
                final checked = match.group(2)!.toLowerCase() == 'x';
                final title = match.group(3)!;
                return '$prefix${checked ? '☑' : '☐'} $title';
              },
            )
            .replaceFirstMapped(
              RegExp(r'^\s*(?:TODO|待办)[:：]\s*(.+)$', caseSensitive: false),
              (match) => '- ☐ ${match.group(1)!}',
            ))
        .join('\n');
  }
}