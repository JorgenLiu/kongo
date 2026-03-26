class FormFieldLimits {
  static const int contactName = 80;
  static const int phone = 32;
  static const int email = 120;
  static const int address = 200;
  static const int notes = 1000;
  static const int eventTitle = 120;
  static const int eventLocation = 120;
  static const int eventDescription = 1000;
  static const int summaryBody = 4000;
  static const int tagName = 32;
  static const int todoGroupTitle = 48;
  static const int todoItemTitle = 120;
}

class FormInputValidators {
  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final RegExp _phonePattern = RegExp(r'^[0-9+()\-\s]{5,32}$');

  static String? requiredText(
    String? value, {
    required String fieldName,
    required int maxLength,
  }) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return '$fieldName不能为空';
    }
    if (normalized.length > maxLength) {
      return '$fieldName不能超过 $maxLength 个字符';
    }
    return null;
  }

  static String? optionalText(
    String? value, {
    required String fieldName,
    required int maxLength,
  }) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return null;
    }
    if (normalized.length > maxLength) {
      return '$fieldName不能超过 $maxLength 个字符';
    }
    return null;
  }

  static String? phone(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return null;
    }
    if (normalized.length > FormFieldLimits.phone) {
      return '电话不能超过 ${FormFieldLimits.phone} 个字符';
    }
    if (!_phonePattern.hasMatch(normalized)) {
      return '请输入有效的电话号码';
    }
    return null;
  }

  static String? email(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return null;
    }
    if (normalized.length > FormFieldLimits.email) {
      return '邮箱不能超过 ${FormFieldLimits.email} 个字符';
    }
    if (!_emailPattern.hasMatch(normalized)) {
      return '请输入有效的邮箱地址';
    }
    return null;
  }

  static String? time(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return null;
    }

    final parts = normalized.split(':');
    if (parts.length != 2) {
      return '请输入有效时间，如 09:30';
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return '请输入有效时间，如 09:30';
    }
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return '请输入有效时间，如 09:30';
    }

    return null;
  }
}