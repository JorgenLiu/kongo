import 'package:flutter/material.dart';

import '../../models/tag.dart';
import '../../models/tag_draft.dart';
import '../../utils/form_input_validators.dart';

Future<TagDraft?> showTagFormDialog(
  BuildContext context, {
  Tag? initialTag,
  Set<String> existingTagNames = const <String>{},
}) async {
  return showDialog<TagDraft>(
    context: context,
    builder: (context) => _TagFormDialog(
      initialTag: initialTag,
      existingTagNames: existingTagNames,
    ),
  );
}

class _TagFormDialog extends StatefulWidget {
  final Tag? initialTag;
  final Set<String> existingTagNames;

  const _TagFormDialog({
    required this.initialTag,
    required this.existingTagNames,
  });

  @override
  State<_TagFormDialog> createState() => _TagFormDialogState();
}

class _TagFormDialogState extends State<_TagFormDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTag?.name ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialTag == null ? '新建分组' : '编辑分组'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          maxLength: FormFieldLimits.tagName,
          decoration: const InputDecoration(
            labelText: '分组名称',
            hintText: '请输入分组名称',
          ),
          validator: (value) {
            final requiredError = FormInputValidators.requiredText(
              value,
              fieldName: '分组名称',
              maxLength: FormFieldLimits.tagName,
            );
            if (requiredError != null) {
              return requiredError;
            }

            final normalized = value!.trim();
            if (widget.existingTagNames.contains(normalized)) {
              return '分组名称不能重复';
            }
            return null;
          },
          onFieldSubmitted: (_) => _submit(),
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
      TagDraft(name: _controller.text.trim()),
    );
  }
}

Future<bool> showDeleteTagConfirmDialog(
  BuildContext context, {
  required Tag tag,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('删除分组'),
      content: Text('确定要删除分组“${tag.name}”吗？该操作不可撤销。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('删除'),
        ),
      ],
    ),
  );

  return confirmed ?? false;
}