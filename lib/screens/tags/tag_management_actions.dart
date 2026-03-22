import 'package:flutter/material.dart';

import '../../models/tag.dart';
import '../../models/tag_draft.dart';
import '../../utils/form_input_validators.dart';

Future<TagDraft?> showTagFormDialog(
  BuildContext context, {
  Tag? initialTag,
  Set<String> existingTagNames = const <String>{},
}) async {
  final controller = TextEditingController(text: initialTag?.name ?? '');
  final formKey = GlobalKey<FormState>();

  final result = await showDialog<TagDraft>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(initialTag == null ? '新建分组' : '编辑分组'),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
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
            if (existingTagNames.contains(normalized)) {
              return '分组名称不能重复';
            }
            return null;
          },
          onFieldSubmitted: (_) {
            if (!formKey.currentState!.validate()) {
              return;
            }

            Navigator.of(context).pop(
              TagDraft(name: controller.text.trim()),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            if (!formKey.currentState!.validate()) {
              return;
            }

            Navigator.of(context).pop(
              TagDraft(name: controller.text.trim()),
            );
          },
          child: const Text('保存'),
        ),
      ],
    ),
  );

  controller.dispose();
  return result;
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