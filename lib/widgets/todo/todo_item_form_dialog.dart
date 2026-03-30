import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../config/page_transitions.dart';
import '../../models/contact.dart';
import '../../models/event.dart';
import '../../models/tag.dart';
import '../../models/todo_item.dart';
import '../../models/todo_item_draft.dart';
import '../../utils/form_input_validators.dart';
import '../common/side_sheet_scaffold.dart';
import 'todo_contact_selection_section.dart';
import 'todo_event_selection_section.dart';

typedef TodoCreateContactCallback = Future<Contact?> Function(String keyword);
typedef TodoCreateEventCallback = Future<Event?> Function(
  String keyword,
  List<String> selectedContactIds,
);

Future<TodoItemDraft?> showTodoItemFormDialog(
  BuildContext context, {
  TodoItem? initialItem,
  String? initialTitle,
  List<Contact> availableContacts = const [],
  List<Event> availableEvents = const [],
  List<Tag> availableTags = const [],
  List<String> initialContactIds = const [],
  List<String> initialEventIds = const [],
  TodoCreateContactCallback? onCreateContact,
  TodoCreateEventCallback? onCreateEvent,
}) async {
  return Navigator.of(context).push<TodoItemDraft>(
    SideSheetPageRoute(
      builder: (_) => _TodoItemFormSheet(
        initialItem: initialItem,
        initialTitle: initialTitle,
        availableContacts: availableContacts,
        availableEvents: availableEvents,
        availableTags: availableTags,
        initialContactIds: initialContactIds,
        initialEventIds: initialEventIds,
        onCreateContact: onCreateContact,
        onCreateEvent: onCreateEvent,
      ),
    ),
  );
}

class _TodoItemFormSheet extends StatefulWidget {
  final TodoItem? initialItem;
  final String? initialTitle;
  final List<Contact> availableContacts;
  final List<Event> availableEvents;
  final List<Tag> availableTags;
  final List<String> initialContactIds;
  final List<String> initialEventIds;
  final TodoCreateContactCallback? onCreateContact;
  final TodoCreateEventCallback? onCreateEvent;

  const _TodoItemFormSheet({
    required this.initialItem,
    required this.initialTitle,
    required this.availableContacts,
    required this.availableEvents,
    required this.availableTags,
    required this.initialContactIds,
    required this.initialEventIds,
    required this.onCreateContact,
    required this.onCreateEvent,
  });

  @override
  State<_TodoItemFormSheet> createState() => _TodoItemFormSheetState();
}

class _TodoItemFormSheetState extends State<_TodoItemFormSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late final Set<String> _selectedContactIds;
  late final Set<String> _selectedEventIds;
  late List<Contact> _availableContacts;
  late List<Event> _availableEvents;
  late TodoItemStatus _status;
  final _formKey = GlobalKey<FormState>();
  bool _creatingContact = false;
  bool _creatingEvent = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialItem?.title ?? widget.initialTitle ?? '');
    _notesController = TextEditingController(text: widget.initialItem?.notes ?? '');
    _selectedContactIds = {...widget.initialContactIds};
    _selectedEventIds = {...widget.initialEventIds};
    _availableContacts = List<Contact>.from(widget.availableContacts);
    _availableEvents = List<Event>.from(widget.availableEvents);
    _status = widget.initialItem?.status ?? TodoItemStatus.pending;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.initialItem == null;
    return SideSheetScaffold(
      title: isNew ? '新建待办项' : '编辑待办项',
      onClose: () => Navigator.of(context).pop(),
      action: FilledButton(
        onPressed: _submit,
        child: const Text('保存'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                autofocus: true,
                maxLength: FormFieldLimits.todoItemTitle,
                decoration: const InputDecoration(
                  labelText: '待办项标题',
                  hintText: '例如：确认报价方案 / 联系渠道负责人',
                ),
                validator: (value) => FormInputValidators.requiredText(
                  value,
                  fieldName: '待办项标题',
                  maxLength: FormFieldLimits.todoItemTitle,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '备注',
                  hintText: '可选：补充执行说明',
                ),
                validator: (value) => FormInputValidators.optionalText(
                  value,
                  fieldName: '备注',
                  maxLength: FormFieldLimits.notes,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SegmentedButton<TodoItemStatus>(
                segments: const [
                  ButtonSegment(value: TodoItemStatus.pending, label: Text('待处理')),
                  ButtonSegment(value: TodoItemStatus.completed, label: Text('已完成')),
                ],
                selected: {_status},
                onSelectionChanged: (selection) {
                  setState(() {
                    _status = selection.first;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TodoContactSelectionSection(
                contacts: _availableContacts,
                tags: widget.availableTags,
                selectedIds: _selectedContactIds,
                creating: _creatingContact,
                onQuickCreate: widget.onCreateContact == null
                    ? null
                    : _handleCreateContact,
                onChanged: (id, selected) {
                  setState(() {
                    if (selected) {
                      _selectedContactIds.add(id);
                    } else {
                      _selectedContactIds.remove(id);
                    }
                  });
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TodoEventSelectionSection(
                events: _availableEvents,
                selectedIds: _selectedEventIds,
                selectedContactIds: _selectedContactIds.toList(growable: false),
                creating: _creatingEvent,
                onQuickCreate: widget.onCreateEvent == null
                    ? null
                    : _handleCreateEvent,
                onChanged: (id, selected) {
                  setState(() {
                    if (selected) {
                      _selectedEventIds.add(id);
                    } else {
                      _selectedEventIds.remove(id);
                    }
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(
      TodoItemDraft(
        title: _titleController.text.trim(),
        notes: _notesController.text.trim(),
        status: _status,
        contactIds: _selectedContactIds.toList(growable: false),
        eventIds: _selectedEventIds.toList(growable: false),
      ),
    );
  }

  Future<void> _handleCreateContact(String keyword) async {
    if (_creatingContact || widget.onCreateContact == null) {
      return;
    }

    setState(() {
      _creatingContact = true;
    });
    final created = await widget.onCreateContact!(keyword);
    if (!mounted) {
      return;
    }

    setState(() {
      _creatingContact = false;
      if (created == null) {
        return;
      }
      _upsertContact(created);
      _selectedContactIds.add(created.id);
    });
  }

  Future<void> _handleCreateEvent(
    String keyword,
    List<String> selectedContactIds,
  ) async {
    if (_creatingEvent || widget.onCreateEvent == null) {
      return;
    }

    setState(() {
      _creatingEvent = true;
    });
    final created = await widget.onCreateEvent!(keyword, selectedContactIds);
    if (!mounted) {
      return;
    }

    setState(() {
      _creatingEvent = false;
      if (created == null) {
        return;
      }
      _upsertEvent(created);
      _selectedEventIds.add(created.id);
    });
  }

  void _upsertContact(Contact contact) {
    _availableContacts = [
      ..._availableContacts.where((item) => item.id != contact.id),
      contact,
    ]..sort((left, right) => left.name.compareTo(right.name));
  }

  void _upsertEvent(Event event) {
    _availableEvents = [
      ..._availableEvents.where((item) => item.id != event.id),
      event,
    ]..sort((left, right) => left.title.compareTo(right.title));
  }
}