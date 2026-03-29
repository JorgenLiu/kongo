enum DailyBriefDeliveryChannel {
  systemReminder('system_reminder');

  const DailyBriefDeliveryChannel(this.value);

  final String value;

  static DailyBriefDeliveryChannel fromValue(String value) {
    return DailyBriefDeliveryChannel.values.firstWhere(
      (channel) => channel.value == value,
      orElse: () => throw FormatException('Unsupported delivery channel: $value'),
    );
  }
}

class DailyBriefDeliveryStatus {
  final String dateKey;
  final DailyBriefDeliveryChannel channel;
  final DateTime deliveredAt;
  final String briefStatus;
  final String summaryHash;

  const DailyBriefDeliveryStatus({
    required this.dateKey,
    required this.channel,
    required this.deliveredAt,
    required this.briefStatus,
    required this.summaryHash,
  });

  factory DailyBriefDeliveryStatus.fromJson(Map<String, dynamic> json) {
    final dateKey = (json['dateKey'] as String?)?.trim();
    final channelValue = (json['channel'] as String?)?.trim();
    final briefStatus = (json['briefStatus'] as String?)?.trim();
    final summaryHash = (json['summaryHash'] as String?)?.trim();
    final deliveredAtRaw = json['deliveredAt'];

    if (dateKey == null || dateKey.isEmpty) {
      throw const FormatException('Daily brief delivery dateKey is required');
    }
    if (channelValue == null || channelValue.isEmpty) {
      throw const FormatException('Daily brief delivery channel is required');
    }
    if (briefStatus == null || briefStatus.isEmpty) {
      throw const FormatException('Daily brief delivery briefStatus is required');
    }
    if (summaryHash == null || summaryHash.isEmpty) {
      throw const FormatException('Daily brief delivery summaryHash is required');
    }

    final deliveredAt = _parseDateTime(deliveredAtRaw);
    if (deliveredAt == null) {
      throw const FormatException('Daily brief delivery deliveredAt is invalid');
    }

    return DailyBriefDeliveryStatus(
      dateKey: dateKey,
      channel: DailyBriefDeliveryChannel.fromValue(channelValue),
      deliveredAt: deliveredAt,
      briefStatus: briefStatus,
      summaryHash: summaryHash,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dateKey': dateKey,
      'channel': channel.value,
      'deliveredAt': deliveredAt.toIso8601String(),
      'briefStatus': briefStatus,
      'summaryHash': summaryHash,
    };
  }

  static DateTime? _parseDateTime(Object? rawValue) {
    if (rawValue is String && rawValue.trim().isNotEmpty) {
      return DateTime.tryParse(rawValue);
    }
    return null;
  }
}