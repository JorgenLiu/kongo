import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/contact.dart';
import '../../utils/form_input_validators.dart';

enum QuickCaptureConfirmChoice {
  /// 关联到已有联系人
  linkExisting,

  /// 新建联系人并关联
  createNew,

  /// 跳过关联，存为 knowledge note
  skip,
}

class QuickCaptureConfirmResult {
  final QuickCaptureConfirmChoice choice;

  /// non-null 当 choice == linkExisting
  final String? existingContactId;

  /// non-null 当 choice == createNew
  final String? newContactName;

  const QuickCaptureConfirmResult._({
    required this.choice,
    this.existingContactId,
    this.newContactName,
  });

  factory QuickCaptureConfirmResult.linkExisting(String contactId) =>
      QuickCaptureConfirmResult._(
        choice: QuickCaptureConfirmChoice.linkExisting,
        existingContactId: contactId,
      );

  factory QuickCaptureConfirmResult.createNew(String name) =>
      QuickCaptureConfirmResult._(
        choice: QuickCaptureConfirmChoice.createNew,
        newContactName: name,
      );

  const QuickCaptureConfirmResult.skip()
      : choice = QuickCaptureConfirmChoice.skip,
        existingContactId = null,
        newContactName = null;
}

/// 弹出 Quick Capture 联系人确认对话框。
///
/// - 当 [matchedContact] 非 null 时，同时提供"关联到已有联系人"和"新建联系人"两个选项。
/// - 当 [matchedContact] 为 null 时，只提供"新建联系人"选项。
/// - 任何路径都提供"跳过关联"出口。
///
/// 对话框被直接关闭（点击外部或 ESC）时返回 null，行为等同于跳过。
Future<QuickCaptureConfirmResult?> showQuickCaptureConfirmDialog(
  BuildContext context, {
  required String candidateName,
  Contact? matchedContact,
}) {
  return showDialog<QuickCaptureConfirmResult>(
    context: context,
    builder: (context) => _QuickCaptureConfirmDialog(
      candidateName: candidateName,
      matchedContact: matchedContact,
    ),
  );
}

class _QuickCaptureConfirmDialog extends StatefulWidget {
  final String candidateName;
  final Contact? matchedContact;

  const _QuickCaptureConfirmDialog({
    required this.candidateName,
    required this.matchedContact,
  });

  @override
  State<_QuickCaptureConfirmDialog> createState() => _QuickCaptureConfirmDialogState();
}

class _QuickCaptureConfirmDialogState extends State<_QuickCaptureConfirmDialog> {
  late final TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.candidateName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _hasMatch => widget.matchedContact != null;

  void _linkExisting() {
    Navigator.of(context).pop(
      QuickCaptureConfirmResult.linkExisting(widget.matchedContact!.id),
    );
  }

  void _createNew() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      QuickCaptureConfirmResult.createNew(_nameController.text.trim()),
    );
  }

  void _skip() {
    Navigator.of(context).pop(const QuickCaptureConfirmResult.skip());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('识别到联系人'),
      content: SizedBox(
        width: 340,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _hasMatch
                    ? '输入中识别到「${widget.matchedContact!.name}」（已有联系人），可直接关联或新建。'
                    : '输入中识别到姓名，未在联系人库中找到匹配。确认姓名后新建联系人，或跳过关联。',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _nameController,
                autofocus: !_hasMatch,
                maxLength: FormFieldLimits.contactName,
                decoration: const InputDecoration(
                  labelText: '新联系人姓名',
                  hintText: '确认或修改识别到的姓名',
                  counterText: '',
                ),
                validator: (value) => FormInputValidators.requiredText(
                  value,
                  fieldName: '联系人姓名',
                  maxLength: FormFieldLimits.contactName,
                ),
                onFieldSubmitted: (_) => _createNew(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _skip,
          child: const Text('跳过关联'),
        ),
        if (_hasMatch)
          OutlinedButton(
            onPressed: _linkExisting,
            child: Text('关联到${widget.matchedContact!.name}'),
          ),
        FilledButton(
          onPressed: _createNew,
          child: const Text('新建联系人'),
        ),
      ],
    );
  }
}
