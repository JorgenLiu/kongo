import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/home_daily_brief.dart';
import 'ai_daily_brief_card.dart';
import 'home_daily_brief_expandable_item.dart';

class HomeDailyBriefItemList extends StatefulWidget {
  final List<HomeDailyBriefItem> items;
  final HomeDailyBriefActionHandler? onActionTap;

  const HomeDailyBriefItemList({
    super.key,
    required this.items,
    this.onActionTap,
  });

  @override
  State<HomeDailyBriefItemList> createState() => _HomeDailyBriefItemListState();
}

class _HomeDailyBriefItemListState extends State<HomeDailyBriefItemList> {
  String? _expandedItemTitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('aiDailyBriefReadyState'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < widget.items.length; index++) ...[
          HomeDailyBriefExpandableItem(
            item: widget.items[index],
            expanded: _expandedItemTitle == widget.items[index].title,
            onToggle: () {
              setState(() {
                _expandedItemTitle = _expandedItemTitle == widget.items[index].title
                    ? null
                    : widget.items[index].title;
              });
            },
            onActionTap: widget.onActionTap,
          ),
          if (index < widget.items.length - 1)
            const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}