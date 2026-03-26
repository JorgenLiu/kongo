String formatDateTimeLabel(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${value.year}-$month-$day $hour:$minute';
}

String formatTimeOnly(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

const _weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

String formatChineseDateLabel(DateTime value) {
  return '${value.year}年${value.month}月${value.day}日 ${_weekdays[value.weekday - 1]}';
}

String formatCompactDateLabel(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}.$month.$day ${_weekdays[value.weekday - 1]}';
}

String formatFileSizeLabel(int sizeBytes) {
  if (sizeBytes >= 1024 * 1024 * 1024) {
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  if (sizeBytes >= 1024 * 1024) {
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (sizeBytes >= 1024) {
    return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
  }
  return '$sizeBytes B';
}