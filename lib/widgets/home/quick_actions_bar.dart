import 'package:flutter/material.dart';

import '../../config/app_constants.dart';

/// 快捷操作按钮组。
class QuickActionsBar extends StatelessWidget {
  final VoidCallback onCreateContact;
  final VoidCallback onCreateEvent;

  const QuickActionsBar({
    super.key,
    required this.onCreateContact,
    required this.onCreateEvent,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.end,
      children: [
        FilledButton.icon(
          onPressed: onCreateContact,
          icon: const Icon(Icons.person_add_outlined, size: 18),
          label: const Text('新建联系人'),
        ),
        FilledButton.icon(
          onPressed: onCreateEvent,
          icon: const Icon(Icons.event_outlined, size: 18),
          label: const Text('新建事件'),
        ),
      ],
    );
  }
}
