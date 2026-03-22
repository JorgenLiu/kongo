import 'package:flutter/material.dart';

import '../../models/contact.dart';
import '../../models/event.dart';
import '../../utils/display_formatters.dart';
import '../common/labeled_info_row.dart';
import '../common/section_card.dart';

class EventDetailInfoSection extends StatelessWidget {
  final Event event;
  final Contact? createdByContact;

  const EventDetailInfoSection({
    super.key,
    required this.event,
    required this.createdByContact,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '基础信息',
      child: Column(
        children: [
          LabeledInfoRow(
            label: '开始时间',
            value: event.startAt != null ? formatDateTimeLabel(event.startAt!) : null,
          ),
          LabeledInfoRow(
            label: '结束时间',
            value: event.endAt != null ? formatDateTimeLabel(event.endAt!) : null,
          ),
          LabeledInfoRow(label: '地点', value: event.location),
          LabeledInfoRow(label: '创建人', value: createdByContact?.name),
          LabeledInfoRow(label: '提醒', value: event.reminderEnabled ? '已开启' : '未开启'),
          LabeledInfoRow(label: '描述', value: event.description, multiline: true),
        ],
      ),
    );
  }
}