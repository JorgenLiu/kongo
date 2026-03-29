import 'package:flutter/material.dart';

import '../../models/event.dart';
import '../../models/event_draft.dart';

/// 校验事件表单并构建 [EventDraft]。
///
/// 返回 null 表示校验失败（已通过 [onParticipantError] / [scaffoldContext] 显示了错误提示）。
EventDraft? validateAndBuildEventDraft({
  required GlobalKey<FormState> formKey,
  required BuildContext scaffoldContext,
  required TextEditingController titleController,
  required TextEditingController locationController,
  required TextEditingController descriptionController,
  required String? selectedEventTypeId,
  required String? selectedCreatedByContactId,
  required Map<String, String> selectedParticipantRoles,
  required DateTime? startAt,
  required DateTime? endAt,
  required bool reminderEnabled,
  required DateTime? reminderAt,
  required Event? initialEvent,
  required ValueChanged<String> onParticipantError,
}) {
  if (!formKey.currentState!.validate()) {
    return null;
  }

  if (selectedParticipantRoles.isEmpty) {
    onParticipantError('请至少选择一个参与人');
    return null;
  }

  if (startAt != null && endAt != null && endAt.isBefore(startAt)) {
    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
      const SnackBar(content: Text('结束时间不能早于开始时间')),
    );
    return null;
  }

  if (reminderEnabled && startAt == null) {
    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
      const SnackBar(content: Text('启用事件提醒前请先设置开始时间')),
    );
    return null;
  }

  if (reminderEnabled && reminderAt == null) {
    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
      const SnackBar(content: Text('请选择提醒时间')),
    );
    return null;
  }

  if (reminderEnabled && reminderAt != null && startAt != null && reminderAt.isAfter(startAt)) {
    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
      const SnackBar(content: Text('提醒时间不能晚于开始时间')),
    );
    return null;
  }

  return EventDraft(
    title: titleController.text.trim(),
    eventTypeId: selectedEventTypeId,
    startAt: startAt,
    endAt: endAt,
    location: _normalize(locationController.text),
    description: _normalize(descriptionController.text),
    reminderEnabled: reminderEnabled,
    reminderAt: reminderEnabled ? reminderAt : null,
    createdByContactId: selectedCreatedByContactId,
    participantIds: selectedParticipantRoles.keys.toList(),
    participantRoles: selectedParticipantRoles,
  );
}

String? _normalize(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    return null;
  }
  return normalized;
}
