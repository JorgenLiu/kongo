/// 将空白字符串正规化为 null，非空字符串去除首尾空白。
String? normalizeOptionalText(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
