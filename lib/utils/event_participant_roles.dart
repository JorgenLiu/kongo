class EventParticipantRoleOption {
  final String value;
  final String label;

  const EventParticipantRoleOption({
    required this.value,
    required this.label,
  });
}

class EventParticipantRoles {
  static const String initiator = 'initiator';
  static const String participant = 'participant';
  static const String investor = 'investor';
  static const String supporter = 'supporter';
  static const String observer = 'observer';

  static const List<EventParticipantRoleOption> options = [
    EventParticipantRoleOption(value: initiator, label: '发起者'),
    EventParticipantRoleOption(value: investor, label: '投资人'),
    EventParticipantRoleOption(value: supporter, label: '支持者'),
    EventParticipantRoleOption(value: participant, label: '参与人'),
    EventParticipantRoleOption(value: observer, label: '观察者'),
  ];

  static String normalize(String? value) {
    final normalized = value?.trim().toLowerCase();
    for (final option in options) {
      if (option.value == normalized) {
        return option.value;
      }
    }

    return participant;
  }

  static String labelOf(String? value) {
    final normalized = normalize(value);
    for (final option in options) {
      if (option.value == normalized) {
        return option.label;
      }
    }

    return '参与人';
  }

  static int sortIndexOf(String? value) {
    final normalized = normalize(value);
    for (var index = 0; index < options.length; index++) {
      if (options[index].value == normalized) {
        return index;
      }
    }

    return options.length;
  }
}