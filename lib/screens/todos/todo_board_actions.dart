import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../models/todo_group.dart';
import '../../models/todo_group_draft.dart';
import '../../providers/provider_error.dart';
import '../../providers/todo_board_provider.dart';
import '../../services/read/todo_read_service.dart';
import 'todo_item_form_actions.dart';
import '../../widgets/todo/todo_group_form_dialog.dart';
import '../../widgets/todo/todo_item_form_dialog.dart';

Future<void> createTodoGroupAction(BuildContext context) async {
  final draft = await showTodoGroupFormDialog(context);
  if (draft == null || !context.mounted) {
    return;
  }

  await _handleGroupMutation(
    context,
    draft: draft,
  );
}

Future<void> editTodoGroupAction(BuildContext context, TodoGroup group) async {
  final draft = await showTodoGroupFormDialog(context, initialGroup: group);
  if (draft == null || !context.mounted) {
    return;
  }

  await _handleGroupMutation(
    context,
    group: group,
    draft: draft,
  );
}

Future<void> deleteTodoGroupAction(BuildContext context, TodoGroup group) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('删除待办组'),
      content: Text('确定删除"${group.title}"吗？组内待办项也会一并删除。'),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),
        FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('删除')),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) {
    return;
  }

  final messenger = ScaffoldMessenger.maybeOf(context);
  final provider = context.read<TodoBoardProvider>();
  await provider.deleteGroup(group.id);
  _showProviderResultSnackBarWithMessenger(
    messenger,
    error: provider.error,
    successMessage: '待办组已删除',
    onErrorHandled: provider.clearError,
  );
}

Future<void> toggleTodoGroupArchivedAction(BuildContext context, TodoGroup group) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final provider = context.read<TodoBoardProvider>();
  if (group.archivedAt == null) {
    await provider.archiveGroup(group.id);
  } else {
    await provider.restoreGroup(group.id);
  }
  _showProviderResultSnackBarWithMessenger(
    messenger,
    error: provider.error,
    successMessage: group.archivedAt == null ? '待办组已归档' : '待办组已恢复',
    onErrorHandled: provider.clearError,
  );
}

Future<void> createTodoItemAction(
  BuildContext context, {
  required String groupId,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final provider = context.read<TodoBoardProvider>();
  final availableTags = await loadTodoFormTags(context);
  if (!context.mounted) {
    return;
  }
  final draft = await showTodoItemFormDialog(
    context,
    availableContacts: provider.data?.availableContacts ?? const [],
    availableEvents: provider.data?.availableEvents ?? const [],
    availableTags: availableTags,
    onCreateContact: (keyword) => quickCreateTodoContact(
      context,
      initialName: keyword,
    ),
    onCreateEvent: (keyword, selectedContactIds) => quickCreateTodoEvent(
      context,
      initialTitle: keyword,
      participantIds: selectedContactIds,
    ),
  );
  if (draft == null || !context.mounted) {
    return;
  }

  await provider.createItem(groupId, draft);
  if (!context.mounted) {
    return;
  }
  _showProviderResultSnackBarWithMessenger(
    messenger,
    error: provider.error,
    successMessage: '待办项已创建',
    onErrorHandled: provider.clearError,
  );
}

Future<void> editTodoItemAction(
  BuildContext context,
  TodoItemTreeNodeReadModel node,
) async {
  final provider = context.read<TodoBoardProvider>();
  final availableTags = await loadTodoFormTags(context);
  if (!context.mounted) {
    return;
  }
  final draft = await showTodoItemFormDialog(
    context,
    initialItem: node.item,
    availableContacts: provider.data?.availableContacts ?? const [],
    availableEvents: provider.data?.availableEvents ?? const [],
    availableTags: availableTags,
    initialContactIds: node.contacts.map((item) => item.id).toList(growable: false),
    initialEventIds: node.events.map((item) => item.id).toList(growable: false),
    onCreateContact: (keyword) => quickCreateTodoContact(
      context,
      initialName: keyword,
    ),
    onCreateEvent: (keyword, selectedContactIds) => quickCreateTodoEvent(
      context,
      initialTitle: keyword,
      participantIds: selectedContactIds,
    ),
  );
  if (draft == null || !context.mounted) {
    return;
  }

  final messenger = ScaffoldMessenger.maybeOf(context);
  await provider.updateItem(
    node.item.copyWith(
      title: draft.title,
      notes: draft.notes,
      status: draft.status,
    ),
    contactIds: draft.contactIds,
    eventIds: draft.eventIds,
  );
  _showProviderResultSnackBarWithMessenger(
    messenger,
    error: provider.error,
    successMessage: '待办项已更新',
    onErrorHandled: provider.clearError,
  );
}

Future<void> deleteTodoItemAction(
  BuildContext context,
  TodoItemTreeNodeReadModel node,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('删除待办项'),
      content: Text('确定删除“${node.item.title}”吗？'),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),
        FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('删除')),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) {
    return;
  }

  final messenger = ScaffoldMessenger.maybeOf(context);
  final provider = context.read<TodoBoardProvider>();
  await provider.deleteItem(node.item.id);
  _showProviderResultSnackBarWithMessenger(
    messenger,
    error: provider.error,
    successMessage: '待办项已删除',
    onErrorHandled: provider.clearError,
  );
}

Future<void> toggleTodoItemCompletedAction(
  BuildContext context,
  TodoItemTreeNodeReadModel node,
  bool completed,
) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final provider = context.read<TodoBoardProvider>();
  await provider.toggleItemCompleted(node.item, completed);
  _showProviderResultSnackBarWithMessenger(
    messenger,
    error: provider.error,
    successMessage: completed ? '待办项已完成' : '待办项已恢复为待处理',
    onErrorHandled: provider.clearError,
  );
}

void startTodoBatchSelectionAction(BuildContext context) {
  context.read<TodoBoardProvider>().enterSelectionMode();
}

void clearTodoBatchSelectionAction(BuildContext context) {
  context.read<TodoBoardProvider>().clearSelection();
}

void toggleTodoItemSelectionAction(BuildContext context, String itemId) {
  context.read<TodoBoardProvider>().toggleItemSelection(itemId);
}

void selectAllTodoItemsAction(BuildContext context) {
  context.read<TodoBoardProvider>().selectAllVisibleItems();
}

Future<void> batchCompleteTodoItemsAction(BuildContext context, {required bool completed}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final provider = context.read<TodoBoardProvider>();
  await provider.batchSetSelectedItemsCompleted(completed);
  _showProviderResultSnackBarWithMessenger(
    messenger,
    error: provider.error,
    successMessage: completed ? '已批量标记为完成' : '已批量恢复为待处理',
    onErrorHandled: provider.clearError,
  );
}

Future<void> batchDeleteTodoItemsAction(BuildContext context) async {
  final provider = context.read<TodoBoardProvider>();
  final count = provider.selectedItemIds.length;
  if (count == 0) {
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('批量删除待办项'),
      content: Text('确定删除已选择的 $count 个待办项吗？已选父项会连同子项一起删除。'),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),
        FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('删除')),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) {
    return;
  }

  final messenger = ScaffoldMessenger.maybeOf(context);
  await provider.batchDeleteSelectedItems();
  _showProviderResultSnackBarWithMessenger(
    messenger,
    error: provider.error,
    successMessage: '已批量删除待办项',
    onErrorHandled: provider.clearError,
  );
}

Future<void> _handleGroupMutation(
  BuildContext context, {
  TodoGroup? group,
  required TodoGroupDraft draft,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final provider = context.read<TodoBoardProvider>();
  if (group == null) {
    await provider.createGroup(draft);
  } else {
    await provider.updateGroup(
      group.copyWith(
        title: draft.title,
        description: draft.description,
      ),
    );
  }
  _showProviderResultSnackBarWithMessenger(
    messenger,
    error: provider.error,
    successMessage: group == null ? '待办组已创建' : '待办组已更新',
    onErrorHandled: provider.clearError,
  );
}

void _showProviderResultSnackBarWithMessenger(
  ScaffoldMessengerState? messenger, {
  required Object? error,
  required String successMessage,
  VoidCallback? onErrorHandled,
}) {
  if (messenger == null) {
    if (error != null) {
      onErrorHandled?.call();
    }
    return;
  }

  final providerError = error is ProviderError ? error : null;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(providerError?.message ?? successMessage),
      backgroundColor: providerError == null ? null : AppColors.error,
    ),
  );

  if (providerError != null) {
    onErrorHandled?.call();
  }
}