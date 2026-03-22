import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../models/event.dart';

class MonthlyEventCalendar extends StatefulWidget {
  final List<Event> events;
  final DateTime? initialMonth;
  final DateTime? selectedDate;
  final ValueChanged<DateTime?>? onDateSelected;
  final bool showFrame;
  final bool compact;

  const MonthlyEventCalendar({
    super.key,
    required this.events,
    this.initialMonth,
    this.selectedDate,
    this.onDateSelected,
    this.showFrame = true,
    this.compact = false,
  });

  @override
  State<MonthlyEventCalendar> createState() => _MonthlyEventCalendarState();
}

class _MonthlyEventCalendarState extends State<MonthlyEventCalendar> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    _visibleMonth = _normalizeMonth(
      widget.initialMonth ?? widget.selectedDate ?? DateTime.now(),
    );
  }

  @override
  void didUpdateWidget(covariant MonthlyEventCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selectedDate = widget.selectedDate;
    if (selectedDate != null && !_isSameMonth(selectedDate, _visibleMonth)) {
      _visibleMonth = _normalizeMonth(selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final weekdayLabels = const ['一', '二', '三', '四', '五', '六', '日'];
    final monthStart = _visibleMonth;
    final nextMonthStart = DateTime(monthStart.year, monthStart.month + 1);
    final monthEnd = DateTime(nextMonthStart.year, nextMonthStart.month, 0);
    final firstWeekdayOffset = monthStart.weekday - DateTime.monday;
    final countsByDateKey = _buildCountsByDateKey(monthStart);
    final dayCells = <Widget>[];

    for (var index = 0; index < firstWeekdayOffset; index++) {
      dayCells.add(const SizedBox.shrink());
    }

    for (var day = 1; day <= monthEnd.day; day++) {
      final date = DateTime(monthStart.year, monthStart.month, day);
      final eventCount = countsByDateKey[_dateKey(date)] ?? 0;
      final isToday = _isSameDate(date, DateTime.now());
      final isSelected = _isSameDate(date, widget.selectedDate);

      dayCells.add(
        _CalendarDayCell(
          key: Key('eventsMonthlyCalendar_day_$day'),
          day: day,
          eventCount: eventCount,
          compact: widget.compact,
          isToday: isToday,
          isSelected: isSelected,
          onTap: () => _handleDateTap(date),
        ),
      );
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildToolbar(context),
        SizedBox(height: widget.compact ? AppSpacing.xs : AppSpacing.sm),
        Row(
          children: weekdayLabels
              .map(
                (label) => Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.outline,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpacing.xs),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.xs,
          crossAxisSpacing: AppSpacing.xs,
          childAspectRatio: widget.compact ? 1.34 : 1.92,
          children: dayCells,
        ),
      ],
    );

    if (!widget.showFrame) {
      return KeyedSubtree(
        key: const Key('eventsMonthlyCalendar'),
        child: content,
      );
    }

    return Card(
      key: const Key('eventsMonthlyCalendar'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: content,
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final monthLabel = widget.compact
        ? '${_visibleMonth.year}/${_visibleMonth.month.toString().padLeft(2, '0')}'
        : '${_visibleMonth.year} 年 ${_visibleMonth.month} 月';

    return Row(
      children: [
        IconButton(
          key: const Key('eventsMonthlyCalendar_previousMonth'),
          visualDensity: widget.compact ? VisualDensity.compact : VisualDensity.standard,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 24, height: 24),
          onPressed: () => _changeMonth(-1),
          icon: const Icon(Icons.chevron_left),
          tooltip: '上一个月',
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: TextButton(
            key: const Key('eventsMonthlyCalendar_monthPicker'),
            onPressed: _openMonthPicker,
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: widget.compact ? AppSpacing.xs : AppSpacing.sm,
                vertical: 0,
              ),
              minimumSize: Size(0, widget.compact ? 28 : 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              monthLabel,
              overflow: TextOverflow.ellipsis,
              style: (widget.compact ? textTheme.titleSmall : textTheme.titleLarge)?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        IconButton(
          key: const Key('eventsMonthlyCalendar_nextMonth'),
          visualDensity: widget.compact ? VisualDensity.compact : VisualDensity.standard,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 24, height: 24),
          onPressed: () => _changeMonth(1),
          icon: const Icon(Icons.chevron_right),
          tooltip: '下一个月',
        ),
        if (!widget.compact) ...[
          const Spacer(),
          if (widget.selectedDate != null && widget.onDateSelected != null)
            TextButton(
              key: const Key('eventsMonthlyCalendar_clearSelection'),
              onPressed: () => widget.onDateSelected!(null),
              child: const Text('清除筛选'),
            ),
        ],
      ],
    );
  }

  void _handleDateTap(DateTime date) {
    final currentSelectedDate = widget.selectedDate;
    if (currentSelectedDate != null && _isSameDate(currentSelectedDate, date)) {
      widget.onDateSelected?.call(null);
      return;
    }

    widget.onDateSelected?.call(date);
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  Future<void> _openMonthPicker() async {
    final nextVisibleMonth = await showDialog<DateTime>(
      context: context,
      builder: (context) => _MonthPickerDialog(
        initialMonth: _visibleMonth,
        years: _availableYears(),
      ),
    );

    if (nextVisibleMonth == null) {
      return;
    }

    setState(() {
      _visibleMonth = _normalizeMonth(nextVisibleMonth);
    });
  }

  List<int> _availableYears() {
    final nowYear = DateTime.now().year;
    var minYear = _visibleMonth.year < nowYear - 2 ? _visibleMonth.year : nowYear - 2;
    var maxYear = _visibleMonth.year > nowYear + 2 ? _visibleMonth.year : nowYear + 2;

    for (final event in widget.events) {
      final startAt = event.startAt;
      if (startAt == null) {
        continue;
      }

      if (startAt.year < minYear) {
        minYear = startAt.year;
      }
      if (startAt.year > maxYear) {
        maxYear = startAt.year;
      }
    }

    return List<int>.generate(maxYear - minYear + 1, (index) => minYear + index);
  }

  Map<String, int> _buildCountsByDateKey(DateTime visibleMonth) {
    final result = <String, int>{};

    for (final event in widget.events) {
      final startAt = event.startAt;
      if (startAt == null || startAt.year != visibleMonth.year || startAt.month != visibleMonth.month) {
        continue;
      }

      final key = _dateKey(startAt);
      result[key] = (result[key] ?? 0) + 1;
    }

    return result;
  }

  DateTime _normalizeMonth(DateTime value) {
    return DateTime(value.year, value.month);
  }

  String _dateKey(DateTime value) {
    final monthText = value.month.toString().padLeft(2, '0');
    final dayText = value.day.toString().padLeft(2, '0');
    return '${value.year}-$monthText-$dayText';
  }

  bool _isSameDate(DateTime? left, DateTime? right) {
    if (left == null || right == null) {
      return false;
    }

    return left.year == right.year && left.month == right.month && left.day == right.day;
  }

  bool _isSameMonth(DateTime left, DateTime right) {
    return left.year == right.year && left.month == right.month;
  }
}

class _CalendarDayCell extends StatelessWidget {
  final int day;
  final int eventCount;
  final bool compact;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  const _CalendarDayCell({
    super.key,
    required this.day,
    required this.eventCount,
    required this.compact,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasEvents = eventCount > 0;
    final backgroundColor = isSelected
        ? colorScheme.primaryContainer
        : isToday
            ? colorScheme.surfaceContainerHigh
            : colorScheme.surfaceContainerLow;
    final foregroundColor = isSelected
        ? colorScheme.onPrimaryContainer
        : hasEvents
            ? AppColors.warning
            : colorScheme.onSurface;

    return LayoutBuilder(
      builder: (context, constraints) {
        final shortestSide = constraints.biggest.shortestSide;
        final fontSize = (shortestSide * (compact ? 0.36 : 0.41)).clamp(12.0, 24.0);

        return Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Stack(
              children: [
                Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w800,
                        color: foregroundColor,
                        height: 1,
                      ),
                    ),
                  ),
                ),
                if (hasEvents)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 2.5),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        eventCount > 9 ? '9+' : '$eventCount',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onPrimary,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MonthPickerDialog extends StatefulWidget {
  final DateTime initialMonth;
  final List<int> years;

  const _MonthPickerDialog({
    required this.initialMonth,
    required this.years,
  });

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialMonth.year;
    _selectedMonth = widget.initialMonth.month;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择年月'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int>(
            initialValue: _selectedYear,
            decoration: const InputDecoration(labelText: '年份'),
            items: widget.years
                .map(
                  (year) => DropdownMenuItem<int>(
                    value: year,
                    child: Text('$year 年'),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _selectedYear = value;
              });
            },
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<int>(
            initialValue: _selectedMonth,
            decoration: const InputDecoration(labelText: '月份'),
            items: List<int>.generate(12, (index) => index + 1)
                .map(
                  (month) => DropdownMenuItem<int>(
                    value: month,
                    child: Text('$month 月'),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _selectedMonth = value;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(DateTime(_selectedYear, _selectedMonth)),
          child: const Text('确定'),
        ),
      ],
    );
  }
}