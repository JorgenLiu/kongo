import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/event_summary.dart';
import '../../models/event_summary_draft.dart';
import '../../utils/form_input_validators.dart';
import '../../utils/unsaved_changes_guard.dart';
import '../../widgets/summary/summary_markdown_preview_card.dart';

class SummaryFormScreen extends StatefulWidget {
  final DailySummary? initialSummary;

  const SummaryFormScreen({
    super.key,
    this.initialSummary,
  });

  bool get isEditing => initialSummary != null;

  @override
  State<SummaryFormScreen> createState() => _SummaryFormScreenState();
}

class _SummaryFormScreenState extends State<SummaryFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _todaySummaryController;
  late final TextEditingController _tomorrowPlanController;
  late DateTime _selectedDate;
  bool _isSaving = false;
  bool _allowPop = false;
  bool _cachedHasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = _normalizeDate(widget.initialSummary?.summaryDate ?? DateTime.now());
    _todaySummaryController = TextEditingController(
      text: widget.initialSummary?.todaySummary ?? '',
    );
    _tomorrowPlanController = TextEditingController(
      text: widget.initialSummary?.tomorrowPlan ?? '',
    );
    _todaySummaryController.addListener(_onFormChanged);
    _tomorrowPlanController.addListener(_onFormChanged);
  }

  @override
  void dispose() {
    _todaySummaryController.dispose();
    _tomorrowPlanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowPop || !_hasUnsavedChanges,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (_allowPop || !_hasUnsavedChanges) {
                Navigator.of(context).pop();
                return;
              }
              final shouldDiscard = await showDiscardChangesDialog(context);
              if (shouldDiscard && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Text(widget.isEditing ? '编辑总结' : '新建总结'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FilledButton.tonal(
                onPressed: _isSaving ? null : _submit,
                child: const Text('保存'),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppDimensions.formMaxWidth),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('日期'),
                        subtitle: Text('${_selectedDate.year} 年 ${_selectedDate.month} 月 ${_selectedDate.day} 日'),
                        trailing: const Icon(Icons.calendar_today_outlined),
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _todaySummaryController,
                        maxLength: FormFieldLimits.summaryBody,
                        decoration: const InputDecoration(
                          labelText: '当日总结',
                          hintText: '记录今天完成了什么、有哪些判断和结论。支持 Markdown。',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 8,
                        minLines: 6,
                        validator: (value) => FormInputValidators.optionalText(
                          value,
                          fieldName: '当日总结',
                          maxLength: FormFieldLimits.summaryBody,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _tomorrowPlanController,
                        maxLength: FormFieldLimits.summaryBody,
                        decoration: const InputDecoration(
                          labelText: '明日计划',
                          hintText: '记录明天的推进计划。支持 Markdown、TODO: 或 - [ ] 形式。',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 8,
                        minLines: 6,
                        validator: (value) {
                          final lengthError = FormInputValidators.optionalText(
                            value,
                            fieldName: '明日计划',
                            maxLength: FormFieldLimits.summaryBody,
                          );
                          if (lengthError != null) {
                            return lengthError;
                          }
                          if (_todaySummaryController.text.trim().isEmpty && (value == null || value.trim().isEmpty)) {
                            return '当日总结和明日计划至少填写一项';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SummaryMarkdownPreviewCard(
                        todaySummaryController: _todaySummaryController,
                        tomorrowPlanController: _tomorrowPlanController,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton(
                        onPressed: _isSaving ? null : _submit,
                        child: Text(widget.isEditing ? '保存修改' : '创建总结'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selectedDate == null) {
      return;
    }

    setState(() {
      _selectedDate = _normalizeDate(selectedDate);
    });
  }

  void _submit() {
    if (_isSaving) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _allowPop = true;
    });

    Navigator.of(context).pop(
      DailySummaryDraft(
        summaryDate: _selectedDate,
        todaySummary: _todaySummaryController.text.trim(),
        tomorrowPlan: _tomorrowPlanController.text.trim(),
        source: widget.initialSummary?.source ?? SummarySource.manual,
        createdByContactId: widget.initialSummary?.createdByContactId,
        aiJobId: widget.initialSummary?.aiJobId,
      ),
    );
  }

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  void _onFormChanged() {
    final current = _hasUnsavedChanges;
    if (current != _cachedHasUnsavedChanges) {
      setState(() {
        _cachedHasUnsavedChanges = current;
      });
    }
  }

  bool get _hasUnsavedChanges {
    final initialSummary = widget.initialSummary;
    return _selectedDate != _normalizeDate(initialSummary?.summaryDate ?? DateTime.now()) ||
        _todaySummaryController.text.trim() != (initialSummary?.todaySummary ?? '') ||
        _tomorrowPlanController.text.trim() != (initialSummary?.tomorrowPlan ?? '');
  }
}