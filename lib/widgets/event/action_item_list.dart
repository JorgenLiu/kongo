import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../models/action_item.dart';

class ActionItemList extends StatelessWidget {
  final List<ActionItem> items;
  final String emptyText;

  const ActionItemList({
    super.key,
    required this.items,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(
        emptyText,
        style: const TextStyle(color: AppColors.outline),
      );
    }

    return Column(
      children: items
          .map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                item.completed ? Icons.check_circle_outline : Icons.radio_button_unchecked,
                color: item.completed ? AppColors.success : AppColors.outline,
              ),
              title: Text(item.title),
            ),
          )
          .toList(),
    );
  }
}