enum ReminderAuthorizationStatus {
  notDetermined,
  denied,
  authorized,
  unsupported,
}

extension ReminderAuthorizationStatusX on ReminderAuthorizationStatus {
  bool get allowsScheduling => this == ReminderAuthorizationStatus.authorized;

  String get label {
    switch (this) {
      case ReminderAuthorizationStatus.notDetermined:
        return '未请求';
      case ReminderAuthorizationStatus.denied:
        return '已拒绝';
      case ReminderAuthorizationStatus.authorized:
        return '已授权';
      case ReminderAuthorizationStatus.unsupported:
        return '当前平台不支持';
    }
  }
}