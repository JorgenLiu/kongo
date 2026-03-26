import 'package:flutter/material.dart';

import '../../models/todo_group.dart';
import '../../models/todo_group_draft.dart';
import '../../utils/form_input_validators.dart';

Future<TodoGroupDraft?> showTodoGroupFormDialog(
  BuildContext context, {
  TodoGroup? initialGroup,
}) async {
  return showDialog<TodoGroupDraft>(
    context: context,
    builder: (context) => _TodoGroupFormDialog(initialGroup: initialGroup),
  );
}

class _TodoGroupFormDialog extends StatefulWidget {
  final TodoGroup? initialGroup;

  const _TodoGroupFormDialog({required this.initialGroup});

  @override
  State<_TodoGroupFormDialog> createState() => _TodoGroupFormDialogState();
}

class _TodoGroupFormDialogState extends State<_TodoGroupFormDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialGroup?.title ?? '');
    _descriptionController = TextEditingController(text: widget.initialGroup?.description ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialGroup == null ? '新建待办组' : '编辑待办组'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                autofocus: true,
                maxLength: FormFieldLimits.todoGroupTitle,
                decoration: const InputDecoration(
                  labelText: '待办组名称',
                  hintText: '例如：本周推进 / 招聘 / 渠道合作',
                ),
                validator: (value) => FormInputValidators.requiredText(
                  value,
                  fieldName: '待办组名称',
                  maxLength: FormFieldLimits.todoGroupTitle,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '说明',
                  hintText: '可选：描述这个待办组的目标或范围',
                ),
                validator: (value) => FormInputValidators.optionalText(
                  value,
                  fieldName: '说明',
                  maxLength: FormFieldLimits.notes,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('保存'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(
      TodoGroupDraft(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
      ),
    );
  }
}