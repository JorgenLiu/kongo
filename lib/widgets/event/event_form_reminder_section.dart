import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../utils/display_formatters.dart';

class EventFormReminderSection extends StatelessWidget {
  final bool reminderEnabled;
  final DateTime? reminderAt;
  final DateTime? startAt;
  final ValueChanged<bool> onReminderEnabledChanged;
  final ValueChanged<DateTime?> onReminderAtChanged;

  const EventFormReminderSection({
    super.key,
    required this.reminderEnabled,
    required this.reminderAt,
    required this.startAt,
    required this.onReminderEnabledChanged,
    required this.onReminderAtChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '提醒设置',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'v1 先支持固定时间提醒。建议先填写开始时间，再设置提醒时间。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: reminderEnabled,
              title: const Text('启用事件提醒'),
              subtitle: Text(
                startAt == null ? '建议先设置开始时间' : '开始时间：${formatDateTimeLabel(startAt!)}',
              ),
              onChanged: onReminderEnabledChanged,
            ),
            if (reminderEnabled) ...[
              const SizedBox(height: AppSpacing.sm),
              _ReminderDateTimeRow(
                value: reminderAt,
                onDateTap: () => _pickDate(context),
                onTimeTap: () => _pickTime(context),
                onClear: () => onReminderAtChanged(null),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final currentValue = reminderAt ?? _defaultReminderAt();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: currentValue,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );

    if (pickedDate == null || !context.mounted) {
      return;
    }

    onReminderAtChanged(
      DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        currentValue.hour,
        currentValue.minute,
      ),
    );
  }

  Future<void> _pickTime(BuildContext context) async {
    final currentValue = reminderAt ?? _defaultReminderAt();
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentValue.hour, minute: currentValue.minute),
      initialEntryMode: TimePickerEntryMode.input,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (pickedTime == null || !context.mounted) {
      return;
    }

    onReminderAtChanged(
      DateTime(
        currentValue.year,
        currentValue.month,
        currentValue.day,
        pickedTime.hour,
        pickedTime.minute,
      ),
    );
  }

  DateTime _defaultReminderAt() {
    final fallback = startAt ?? DateTime.now().add(const Duration(hours: 1));
    return fallback.subtract(const Duration(minutes: 30));
  }
}

class _ReminderDateTimeRow extends StatelessWidget {
  final DateTime? value;
  final VoidCallback onDateTap;
  final VoidCallback onTimeTap;
  final VoidCallback onClear;

  const _ReminderDateTimeRow({
    required this.value,
    required this.onDateTap,
    required this.onTimeTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final timeText = value == null ? '' : formatTimeOnly(value!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '提醒时间',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: InkWell(
                onTap: onDateTap,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '日期',
                    hintText: '选择日期',
                    suffixIcon: Icon(Icons.calendar_month_outlined),
                  ),
                  child: Text(
                    value == null ? '选择日期' : formatDateTimeLabel(value!).split(' ').first,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 140,
              child: InkWell(
                onTap: onTimeTap,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '时间',
                    hintText: '选择时间',
                    suffixIcon: Icon(Icons.access_time_outlined),
                  ),
                  child: Text(
                    timeText.isEmpty ? '选择时间' : timeText,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: timeText.isEmpty ? Theme.of(context).hintColor : null,
                        ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Visibility(
              visible: value != null,
              maintainAnimation: true,
              maintainSize: true,
              maintainState: true,
              child: TextButton(
                onPressed: value == null ? null : onClear,
                child: const Text('清除'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}