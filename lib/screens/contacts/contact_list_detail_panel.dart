import 'package:flutter/material.dart';

import '../../widgets/common/empty_state.dart';
import 'contact_detail_screen.dart';

/// 通讯录列表页右侧内嵌详情面板。
///
/// 有选中联系人时展示 [ContactDetailScreen]；否则显示空状态引导。
class ContactListDetailPanel extends StatelessWidget {
  final String? contactId;

  const ContactListDetailPanel({super.key, this.contactId});

  @override
  Widget build(BuildContext context) {
    if (contactId == null) {
      return const Center(
        child: EmptyState(
          icon: Icons.person_outline,
          message: '选择一位联系人查看详情',
        ),
      );
    }
    return ContactDetailScreen(contactId: contactId!, showAppBar: false);
  }
}
