import 'todo_item.dart';

class TodoItemDraft {
  final String title;
  final String? notes;
  final TodoItemStatus status;
  final List<String> contactIds;
  final List<String> eventIds;

  const TodoItemDraft({
    required this.title,
    this.notes,
    this.status = TodoItemStatus.pending,
    this.contactIds = const [],
    this.eventIds = const [],
  });
}