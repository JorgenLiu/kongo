import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../models/contact.dart';
import '../../models/event.dart';
import '../../models/todo_item_draft.dart';
import '../../providers/contact_detail_provider.dart';
import '../../providers/event_detail_provider.dart';
import '../../providers/provider_error.dart';
import '../../providers/todo_board_provider.dart';
import '../../services/read/todo_read_service.dart';
import '../../utils/navigation_helpers.dart';
import '../../widgets/todo/todo_item_form_dialog.dart';
import '../contacts/contact_detail_screen.dart';
import '../events/event_detail_screen.dart';
import 'todo_item_form_actions.dart';
import 'todo_board_screen.dart';

Future<void> openTodoLinkedContactDetail(BuildContext context, String contactId) async {
  await Navigator.of(context).push(
    buildAdaptiveDetailRoute(ContactDetailScreen(contactId: contactId)),
  );
}

Future<void> openTodoLinkedEventDetail(BuildContext context, String eventId) async {
  await Navigator.of(context).push(
    buildAdaptiveDetailRoute(EventDetailScreen(eventId: eventId)),
  );
}

Future<void> openTodoBoardForGroupAction(BuildContext context, String groupId) async {
  await Navigator.of(context).push(
    buildAdaptiveDetailRoute(
      TodoBoardScreen(
        showAppBar: true,
        initialGroupId: groupId,
      ),
    ),
  );
}

Future<void> createTodoFromContactDetailAction(BuildContext context, Contact contact) async {
  final created = await _createLinkedTodoAction(
    context,
    initialContactIds: [contact.id],
    initialTitle: '跟进 ${contact.name}',
  );
  if (!created || !context.mounted) {
    return;
  }
  await _refreshProviderIfPresent<ContactDetailProvider>(
    context,
    (provider) => provider.refresh(),
  );
}

Future<void> createTodoFromEventDetailAction(BuildContext context, Event event) async {
  final created = await _createLinkedTodoAction(
    context,
    initialEventIds: [event.id],
    initialTitle: '推进 ${event.title}',
  );
  if (!created || !context.mounted) {
    return;
  }
  await _refreshProviderIfPresent<EventDetailProvider>(
    context,
    (provider) => provider.refresh(),
  );
}

Future<bool> _createLinkedTodoAction(
  BuildContext context, {
  List<String> initialContactIds = const [],
  List<String> initialEventIds = const [],
  String? initialTitle,
}) async {
  final provider = context.read<TodoBoardProvider>();
  if (provider.data == null && !provider.loading) {
    await provider.load();
  }
  if (!context.mounted) {
    return false;
  }

  final groups = provider.data?.groups ?? const <TodoGroupListItemReadModel>[];
  if (groups.isEmpty) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger != null) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('请先在待办页面创建一个待办组')),
      );
    }
    return false;
  }

  final groupId = await _showTodoGroupPickerDialog(context, groups);
  if (groupId == null || !context.mounted) {
    return false;
  }

  final availableTags = await loadTodoFormTags(context);
  if (!context.mounted) {
    return false;
  }

  final draft = await showTodoItemFormDialog(
    context,
    availableContacts: provider.data?.availableContacts ?? const [],
    availableEvents: provider.data?.availableEvents ?? const [],
    availableTags: availableTags,
    initialContactIds: initialContactIds,
    initialEventIds: initialEventIds,
    initialTitle: initialTitle,
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
    return false;
  }

  final messenger = ScaffoldMessenger.maybeOf(context);
  await provider.createItem(
    groupId,
    TodoItemDraft(
      title: draft.title,
      notes: draft.notes,
      status: draft.status,
      contactIds: draft.contactIds,
      eventIds: draft.eventIds,
    ),
  );

  if (messenger != null) {
    final providerError = provider.error is ProviderError ? provider.error as ProviderError : null;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(providerError?.message ?? '关联待办已创建'),
        backgroundColor: providerError == null ? null : AppColors.error,
      ),
    );
    if (providerError != null) {
      provider.clearError();
    }
  } else if (provider.error != null) {
    provider.clearError();
  }
  return provider.error == null;
}

Future<void> _refreshProviderIfPresent<T>(
  BuildContext context,
  Future<void> Function(T provider) refresh,
) async {
  try {
    final provider = Provider.of<T>(context, listen: false);
    await refresh(provider);
  } on ProviderNotFoundException {
    return;
  }
}

Future<String?> _showTodoGroupPickerDialog(
  BuildContext context,
  List<TodoGroupListItemReadModel> groups,
) async {
  String selectedGroupId = groups.first.group.id;

  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('选择待办组'),
      content: StatefulBuilder(
        builder: (context, setState) => SizedBox(
          width: 420,
          child: DropdownButtonFormField<String>(
            initialValue: selectedGroupId,
            decoration: const InputDecoration(labelText: '待办组'),
            items: groups
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item.group.id,
                    child: Text(item.group.title),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedGroupId = value;
                });
              }
            },
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('取消')),
        FilledButton(onPressed: () => Navigator.of(context).pop(selectedGroupId), child: const Text('下一步')),
      ],
    ),
  );
}