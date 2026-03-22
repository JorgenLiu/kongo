import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/app_constants.dart';
import '../../utils/display_formatters.dart';
import '../../utils/form_input_validators.dart';

class EventFormScheduleSection extends StatefulWidget {
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
  State<EventFormScheduleSection> createState() => _EventFormScheduleSectionState();
}

class _EventFormScheduleSectionState extends State<EventFormScheduleSection> {
  late final TextEditingController _startTimeController;
  late final TextEditingController _endTimeController;
  String? _pendingStartText;
  String? _pendingEndText;

  @override
  void initState() {
    super.initState();
    _startTimeController = TextEditingController(text: _formatTime(widget.startAt));
    _endTimeController = TextEditingController(text: _formatTime(widget.endAt));
  }

  @override
  void didUpdateWidget(covariant EventFormScheduleSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final startText = _formatTime(widget.startAt);
    if (_startTimeController.text != startText) {
      _scheduleControllerSync(
        controller: _startTimeController,
        nextText: startText,
        isStart: true,
      );
    }

    final endText = _formatTime(widget.endAt);
    if (_endTimeController.text != endText) {
      _scheduleControllerSync(
        controller: _endTimeController,
        nextText: endText,
        isStart: false,
      );
    }
  }

  @override
  void dispose() {
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  void _scheduleControllerSync({
    required TextEditingController controller,
    required String nextText,
    required bool isStart,
  }) {
    if (isStart) {
      _pendingStartText = nextText;
    } else {
      _pendingEndText = nextText;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final pendingText = isStart ? _pendingStartText : _pendingEndText;
      if (pendingText != nextText || controller.text == nextText) {
        return;
      }

      controller.value = controller.value.copyWith(
        text: nextText,
        selection: TextSelection.collapsed(offset: nextText.length),
        composing: TextRange.empty,
      );

      if (isStart) {
        _pendingStartText = null;
      } else {
        _pendingEndText = null;
      }
    });
  }

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
            const SizedBox(height: AppSpacing.xs),
            Text(
              '保留日期选择，时间直接输入 24 小时制，避免再出现无意义的表盘。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            _DateTimeRow(
              label: '开始时间',
              value: widget.startAt,
              timeController: _startTimeController,
              onDateTap: () => _pickDate(isStart: true),
              onTimeChanged: (value) => _handleTimeChanged(value, isStart: true),
              onClear: () {
                _startTimeController.clear();
                widget.onStartChanged(null);
              },
              dateFieldKey: const Key('eventForm_startDateField'),
              timeFieldKey: const Key('eventForm_startTimeField'),
              clearButtonKey: const Key('eventForm_clearStartButton'),
            ),
            const SizedBox(height: AppSpacing.md),
            _DateTimeRow(
              label: '结束时间',
              value: widget.endAt,
              timeController: _endTimeController,
              onDateTap: () => _pickDate(isStart: false),
              onTimeChanged: (value) => _handleTimeChanged(value, isStart: false),
              onClear: () {
                _endTimeController.clear();
                widget.onEndChanged(null);
              },
              dateFieldKey: const Key('eventForm_endDateField'),
              timeFieldKey: const Key('eventForm_endTimeField'),
              clearButtonKey: const Key('eventForm_clearEndButton'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final currentValue = isStart ? widget.startAt : widget.endAt;
    final initialValue = currentValue ?? DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialValue,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );

    if (pickedDate == null || !mounted) {
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
      widget.onStartChanged(mergedValue);
    } else {
      widget.onEndChanged(mergedValue);
    }
  }

  void _handleTimeChanged(String rawValue, {required bool isStart}) {
    final parsedTime = _parseTime(rawValue);
    if (parsedTime == null) {
      return;
    }

    final currentValue = isStart ? widget.startAt : widget.endAt;
    final baseDate = currentValue ?? DateTime.now();
    final mergedValue = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      parsedTime.$1,
      parsedTime.$2,
    );

    if (isStart) {
      widget.onStartChanged(mergedValue);
    } else {
      widget.onEndChanged(mergedValue);
    }
  }

  (int, int)? _parseTime(String rawValue) {
    final normalized = rawValue.trim();
    if (normalized.isEmpty) {
      return null;
    }

    final parts = normalized.split(':');
    if (parts.length != 2) {
      return null;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }

    return (hour, minute);
  }

  String _formatTime(DateTime? value) {
    if (value == null) {
      return '';
    }

    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _DateTimeRow extends StatelessWidget {
  final String label;
  final DateTime? value;
  final TextEditingController timeController;
  final VoidCallback onDateTap;
  final ValueChanged<String> onTimeChanged;
  final VoidCallback onClear;
  final Key dateFieldKey;
  final Key timeFieldKey;
  final Key clearButtonKey;

  const _DateTimeRow({
    required this.label,
    required this.value,
    required this.timeController,
    required this.onDateTap,
    required this.onTimeChanged,
    required this.onClear,
    required this.dateFieldKey,
    required this.timeFieldKey,
    required this.clearButtonKey,
  });

  @override
  Widget build(BuildContext context) {
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
              width: 120,
              child: TextFormField(
                key: timeFieldKey,
                controller: timeController,
                maxLength: 5,
                keyboardType: TextInputType.datetime,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[0-9:]')),
                ],
                onChanged: onTimeChanged,
                validator: FormInputValidators.time,
                decoration: const InputDecoration(
                  labelText: '时间',
                  hintText: '09:30',
                ),
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: AppSpacing.sm),
              TextButton(
                key: clearButtonKey,
                onPressed: onClear,
                child: const Text('清除'),
              ),
            ],
          ],
        ),
      ],
    );
  }
}