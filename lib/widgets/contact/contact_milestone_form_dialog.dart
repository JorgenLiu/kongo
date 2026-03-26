import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/contact_milestone.dart';
import '../../models/contact_milestone_draft.dart';
import '../../utils/display_formatters.dart';

/// 添加/编辑重要日期对话框，返回 [ContactMilestoneDraft] 或 null（取消）。
Future<ContactMilestoneDraft?> showMilestoneFormDialog(
  BuildContext context, {
  ContactMilestone? existing,
}) {
  return showDialog<ContactMilestoneDraft>(
    context: context,
    builder: (context) => _MilestoneFormDialog(existing: existing),
  );
}

class _MilestoneFormDialog extends StatefulWidget {
  final ContactMilestone? existing;

  const _MilestoneFormDialog({this.existing});

  @override
  State<_MilestoneFormDialog> createState() => _MilestoneFormDialogState();
}

class _MilestoneFormDialogState extends State<_MilestoneFormDialog> {
  late ContactMilestoneType _type;
  late TextEditingController _labelController;
  late TextEditingController _notesController;
  DateTime? _selectedDate;
  late bool _isRecurring;
  late bool _reminderEnabled;
  late int _reminderDaysBefore;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _type = existing?.type ?? ContactMilestoneType.birthday;
    _labelController = TextEditingController(text: existing?.label ?? '');
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _selectedDate = existing?.milestoneDate;
    _isRecurring = existing?.isRecurring ?? true;
    _reminderEnabled = existing?.reminderEnabled ?? false;
    _reminderDaysBefore = existing?.reminderDaysBefore ?? 1;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(_isEditing ? '编辑重要日期' : '添加重要日期'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 类型选择
              DropdownButtonFormField<ContactMilestoneType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: '类型'),
                items: ContactMilestoneType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text('${type.icon}  ${type.label}'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _type = value);
                  }
                },
              ),

              // 自定义名称（仅自定义类型显示或允许覆盖）
              if (_type == ContactMilestoneType.custom) ...[
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _labelController,
                  decoration: const InputDecoration(
                    labelText: '名称',
                    hintText: '例如：公司周年',
                  ),
                  maxLength: 50,
                ),
              ],

              const SizedBox(height: AppSpacing.md),

              // 日期选择
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '日期',
                    suffixIcon: Icon(Icons.calendar_month_outlined),
                  ),
                  child: Text(
                    _selectedDate == null
                        ? '选择日期'
                        : formatDateTimeLabel(_selectedDate!).split(' ').first,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // 每年重复
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('每年重复'),
                subtitle: const Text('生日、纪念日等周期性日期'),
                value: _isRecurring,
                onChanged: (value) => setState(() => _isRecurring = value),
              ),

              // 提醒
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('启用提醒'),
                value: _reminderEnabled,
                onChanged: (value) => setState(() => _reminderEnabled = value),
              ),

              if (_reminderEnabled) ...[
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<int>(
                  initialValue: _reminderDaysBefore,
                  decoration: const InputDecoration(labelText: '提前提醒天数'),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('当天')),
                    DropdownMenuItem(value: 1, child: Text('提前 1 天')),
                    DropdownMenuItem(value: 3, child: Text('提前 3 天')),
                    DropdownMenuItem(value: 7, child: Text('提前 7 天')),
                    DropdownMenuItem(value: 14, child: Text('提前 14 天')),
                    DropdownMenuItem(value: 30, child: Text('提前 30 天')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _reminderDaysBefore = value);
                    }
                  },
                ),
              ],

              const SizedBox(height: AppSpacing.md),

              // 备注
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: '备注',
                  hintText: '可选备注',
                ),
                maxLines: 2,
                maxLength: 200,
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
          child: Text(_isEditing ? '保存' : '添加'),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final initialDate = _selectedDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );

    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submit() {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择日期')),
      );
      return;
    }

      if (_type == ContactMilestoneType.custom && _labelController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('自定义重要日期必须填写名称')),
      );
      return;
    }

    Navigator.of(context).pop(
      ContactMilestoneDraft(
        type: _type,
        label: _type == ContactMilestoneType.custom ? _labelController.text.trim() : null,
        milestoneDate: _selectedDate!,
        isRecurring: _isRecurring,
        reminderEnabled: _reminderEnabled,
        reminderDaysBefore: _reminderDaysBefore,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      ),
    );
  }
}
