import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_constants.dart';
import '../../providers/todo_board_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/workbench_page_header.dart';
import '../../widgets/todo/todo_board_filters_bar.dart';
import '../../widgets/todo/todo_group_detail_panel.dart';
import '../../widgets/todo/todo_group_sidebar.dart';
import 'todo_board_actions.dart';
import 'todo_link_actions.dart';

class TodoBoardScreen extends StatefulWidget {
  final bool showAppBar;
  final String? initialGroupId;

  const TodoBoardScreen({
    super.key,
    this.showAppBar = false,
    this.initialGroupId,
  });

  @override
  State<TodoBoardScreen> createState() => _TodoBoardScreenState();
}

class _TodoBoardScreenState extends State<TodoBoardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TodoBoardProvider>();
      if (!provider.initialized && !provider.loading) {
        provider.load(selectedGroupId: widget.initialGroupId);
      } else if (widget.initialGroupId != null && provider.selectedGroupId != widget.initialGroupId) {
        provider.selectGroup(widget.initialGroupId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar ? AppBar(title: const Text('待办事项组')) : null,
      body: SafeArea(
        child: Consumer<TodoBoardProvider>(
          builder: (context, provider, _) {
            final Widget child;

            if (provider.loading && provider.data == null) {
              child = const Center(
                key: ValueKey('todo_loading'),
                child: CircularProgressIndicator(),
              );
            } else if (provider.error != null && provider.data == null) {
              child = ErrorState(
                key: const ValueKey('todo_error'),
                message: provider.error?.message ?? '待办加载失败',
                onRetry: provider.load,
              );
            } else if (provider.data == null) {
              child = const SizedBox.shrink(key: ValueKey('todo_empty'));
            } else {
              final data = provider.data!;

              child = Padding(
                key: const ValueKey('todo_content'),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    WorkbenchPageHeader(
                      eyebrow: 'Todo',
                      title: '待办事项组',
                      titleKey: const Key('todoPageHeaderTitle'),
                      trailing: data.groups.isNotEmpty
                          ? TodoBoardFiltersBar(
                              groupVisibility: provider.groupVisibility,
                              itemFilter: provider.itemFilter,
                              itemSort: provider.itemSort,
                              onGroupVisibilityChanged: provider.setGroupVisibility,
                              onItemFilterChanged: provider.setItemFilter,
                              onItemSortChanged: provider.setItemSort,
                            )
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (data.groups.isEmpty) {
                          if (constraints.maxWidth >= AppBreakpoints.standard) {
                            return _TodoDesktopEmptyState(
                              onCreateGroup: () => createTodoGroupAction(context),
                            );
                          }
                          return EmptyState(
                            icon: Icons.playlist_add_check_rounded,
                            iconSize: 72,
                            message: '还没有待办事项组',
                            subtitle: '待办组可以帮你按项目或主题组织任务，并关联联系人和日程。',
                            actionLabel: '新建待办组',
                            onAction: () => createTodoGroupAction(context),
                            asCard: true,
                          );
                        }

                        if (constraints.maxWidth >= AppBreakpoints.standard) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 320,
                                child: TodoGroupSidebar(
                                  groups: data.groups,
                                  selectedGroupId: provider.selectedGroupId,
                                  onCreateGroup: () => createTodoGroupAction(context),
                                  onSelectGroup: provider.selectGroup,
                                  onEditGroup: (item) => editTodoGroupAction(context, item.group),
                                  onArchiveGroup: (item) => toggleTodoGroupArchivedAction(context, item.group),
                                  onDeleteGroup: (item) => deleteTodoGroupAction(context, item.group),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: TodoGroupDetailPanel(
                                  detail: data.selectedGroup,
                                  selectionMode: provider.selectionMode,
                                  selectedItemIds: provider.selectedItemIds,
                                  visibleItemCount: provider.visibleItemCount,
                                  onCreateRootItem: () => createTodoItemAction(
                                    context,
                                    groupId: data.selectedGroup!.group.id,
                                  ),
                                  onStartSelection: () => startTodoBatchSelectionAction(context),
                                  onClearSelection: () => clearTodoBatchSelectionAction(context),
                                  onSelectAll: () => selectAllTodoItemsAction(context),
                                  onBatchMarkCompleted: () => batchCompleteTodoItemsAction(context, completed: true),
                                  onBatchMarkPending: () => batchCompleteTodoItemsAction(context, completed: false),
                                  onBatchDelete: () => batchDeleteTodoItemsAction(context),
                                  onEditItem: (node) => editTodoItemAction(context, node),
                                  onDeleteItem: (node) => deleteTodoItemAction(context, node),
                                  onToggleCompleted: (node, completed) =>
                                      toggleTodoItemCompletedAction(context, node, completed),
                                  onToggleSelection: (itemId) => toggleTodoItemSelectionAction(context, itemId),
                                  onOpenContact: (contactId) => openTodoLinkedContactDetail(context, contactId),
                                  onOpenEvent: (eventId) => openTodoLinkedEventDetail(context, eventId),
                                ),
                              ),
                            ],
                          );
                        }

                        return Column(
                          children: [
                            SizedBox(
                              height: 180,
                              child: TodoGroupSidebar(
                                groups: data.groups,
                                selectedGroupId: provider.selectedGroupId,
                                onCreateGroup: () => createTodoGroupAction(context),
                                onSelectGroup: provider.selectGroup,
                                onEditGroup: (item) => editTodoGroupAction(context, item.group),
                                onArchiveGroup: (item) => toggleTodoGroupArchivedAction(context, item.group),
                                onDeleteGroup: (item) => deleteTodoGroupAction(context, item.group),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Expanded(
                              child: TodoGroupDetailPanel(
                                detail: data.selectedGroup,
                                selectionMode: provider.selectionMode,
                                selectedItemIds: provider.selectedItemIds,
                                visibleItemCount: provider.visibleItemCount,
                                onCreateRootItem: () => createTodoItemAction(
                                  context,
                                  groupId: data.selectedGroup!.group.id,
                                ),
                                onStartSelection: () => startTodoBatchSelectionAction(context),
                                onClearSelection: () => clearTodoBatchSelectionAction(context),
                                onSelectAll: () => selectAllTodoItemsAction(context),
                                onBatchMarkCompleted: () => batchCompleteTodoItemsAction(context, completed: true),
                                onBatchMarkPending: () => batchCompleteTodoItemsAction(context, completed: false),
                                onBatchDelete: () => batchDeleteTodoItemsAction(context),
                                onEditItem: (node) => editTodoItemAction(context, node),
                                onDeleteItem: (node) => deleteTodoItemAction(context, node),
                                onToggleCompleted: (node, completed) =>
                                    toggleTodoItemCompletedAction(context, node, completed),
                                onToggleSelection: (itemId) => toggleTodoItemSelectionAction(context, itemId),
                                onOpenContact: (contactId) => openTodoLinkedContactDetail(context, contactId),
                                onOpenEvent: (eventId) => openTodoLinkedEventDetail(context, eventId),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
            }

            return child;
          },
        ),
      ),
    );
  }
}

/// 桌面端待办事项组空状态：左侧大图标 + 右侧文案与操作，充分利用横向空间。
class _TodoDesktopEmptyState extends StatelessWidget {
  final VoidCallback onCreateGroup;

  const _TodoDesktopEmptyState({required this.onCreateGroup});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.playlist_add_check_rounded,
              size: 96,
              color: colorScheme.outline.withValues(alpha: 0.3),
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '还没有待办事项组',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '待办组可以帮你按项目或主题组织任务，并关联联系人和日程。',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.outline,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed: onCreateGroup,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('新建待办组'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}