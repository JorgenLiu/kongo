import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../utils/display_formatters.dart';

class EventFormScheduleSection extends StatelessWidget {
  final DateTime? startAt;
  final DateTime? endAt;
  final ValueChanged<DateTime?> onStartChanged;
  final ValueChanged<DateTime?> onEndChanged;

  const EventFormScheduleSection({
    super.key,
    required this.startAt,
    required this.endAt,
    required this.onStartChanged,
    required this.onEndChanged,
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
              '时间安排',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            _DateTimeRow(
              label: '开始时间',
              value: startAt,
              onDateTap: () => _pickDate(context, isStart: true),
              onTimeTap: () => _pickTime(context, isStart: true),
              onClear: () => onStartChanged(null),
              dateFieldKey: const Key('eventForm_startDateField'),
              timeFieldKey: const Key('eventForm_startTimeField'),
              clearButtonKey: const Key('eventForm_clearStartButton'),
            ),
            const SizedBox(height: AppSpacing.md),
            _DateTimeRow(
              label: '结束时间',
              value: endAt,
              onDateTap: () => _pickDate(context, isStart: false),
              onTimeTap: () => _pickTime(context, isStart: false),
              onClear: () => onEndChanged(null),
              dateFieldKey: const Key('eventForm_endDateField'),
              timeFieldKey: const Key('eventForm_endTimeField'),
              clearButtonKey: const Key('eventForm_clearEndButton'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, {required bool isStart}) async {
    final currentValue = isStart ? startAt : endAt;
    final initialValue = currentValue ?? DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialValue,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );

    if (pickedDate == null || !context.mounted) {
      return;
    }

    final mergedValue = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      currentValue?.hour ?? 9,
      currentValue?.minute ?? 0,
    );

    if (isStart) {
      onStartChanged(mergedValue);
    } else {
      onEndChanged(mergedValue);
    }
  }

  Future<void> _pickTime(BuildContext context, {required bool isStart}) async {
    final currentValue = isStart ? startAt : endAt;
    final initialTime = currentValue != null
        ? TimeOfDay(hour: currentValue.hour, minute: currentValue.minute)
        : const TimeOfDay(hour: 9, minute: 0);

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
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

    final baseDate = currentValue ?? DateTime.now();
    final mergedValue = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (isStart) {
      onStartChanged(mergedValue);
    } else {
      onEndChanged(mergedValue);
    }
  }
}

class _DateTimeRow extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onDateTap;
  final VoidCallback onTimeTap;
  final VoidCallback onClear;
  final Key dateFieldKey;
  final Key timeFieldKey;
  final Key clearButtonKey;

  const _DateTimeRow({
    required this.label,
    required this.value,
    required this.onDateTap,
    required this.onTimeTap,
    required this.onClear,
    required this.dateFieldKey,
    required this.timeFieldKey,
    required this.clearButtonKey,
  });

  @override
  Widget build(BuildContext context) {
    final timeText = _formatTime(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: InkWell(
                key: dateFieldKey,
                onTap: onDateTap,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    hintText: '年/月/日',
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
                key: timeFieldKey,
                onTap: onTimeTap,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    hintText: 'HH:MM',
                    suffixIcon: Icon(Icons.access_time_outlined),
                  ),
                  child: Text(
                    timeText.isEmpty ? '选择时间' : timeText,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: timeText.isEmpty
                              ? Theme.of(context).hintColor
                              : null,
                        ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Visibility(
              visible: value != null,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: TextButton(
                key: clearButtonKey,
                onPressed: value != null ? onClear : null,
                child: const Text('清除'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatTime(DateTime? value) {
    if (value == null) return '';
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}