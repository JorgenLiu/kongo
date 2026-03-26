import '../models/action_item.dart';

/// 从 Markdown 文本中提取待办事项（action items）。
///
/// 支持三种格式：
/// - `- [ ]` / `- [x]` 复选框语法
/// - `TODO:` / `待办:` 前缀
/// - `1.` 有序列表
List<ActionItem> parseActionItems(String content) {
  final checkboxPattern = RegExp(r'^\s*(?:-|\*)\s*\[( |x|X)\]\s+(.+)$');
  final todoPattern = RegExp(r'^\s*(?:TODO|待办)[:：]\s*(.+)$', caseSensitive: false);
  final numberedPattern = RegExp(r'^\s*\d+\.\s+(.+)$');

  final items = <ActionItem>[];

  for (final rawLine in content.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty) {
      continue;
    }

    final checkboxMatch = checkboxPattern.firstMatch(line);
    if (checkboxMatch != null) {
      items.add(
        ActionItem(
          title: checkboxMatch.group(2)!.trim(),
          completed: checkboxMatch.group(1)!.toLowerCase() == 'x',
        ),
      );
      continue;
    }

    final todoMatch = todoPattern.firstMatch(line);
    if (todoMatch != null) {
      items.add(ActionItem(title: todoMatch.group(1)!.trim()));
      continue;
    }

    final numberedMatch = numberedPattern.firstMatch(line);
    if (numberedMatch != null) {
      items.add(ActionItem(title: _normalizeActionItemTitle(numberedMatch.group(1)!.trim(), todoPattern)));
    }
  }

  return items;
}

String _normalizeActionItemTitle(String value, RegExp todoPattern) {
  final todoMatch = todoPattern.firstMatch(value);
  if (todoMatch != null) {
    return todoMatch.group(1)!.trim();
  }

  return value.trim();
}
