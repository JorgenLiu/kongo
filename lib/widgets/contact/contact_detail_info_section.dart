import 'package:flutter/material.dart';

import '../../models/contact.dart';
import '../common/labeled_info_row.dart';
import '../common/section_card.dart';

class ContactDetailInfoSection extends StatelessWidget {
  final Contact contact;

  const ContactDetailInfoSection({
    super.key,
    required this.contact,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '联系信息',
      child: Column(
        children: [
          LabeledInfoRow(label: '电话', value: contact.phone, labelWidth: 64),
          LabeledInfoRow(label: '邮箱', value: contact.email, labelWidth: 64),
          LabeledInfoRow(label: '地址', value: contact.address, labelWidth: 64),
          LabeledInfoRow(label: '备注', value: contact.notes, multiline: true, labelWidth: 64),
        ],
      ),
    );
  }
}