import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/tag.dart';

typedef ContactTagFilterSelection = List<String>;

class ContactTagFilterSheet extends StatefulWidget {
  final List<Tag> tags;
  final List<String> initialTagIds;

  const ContactTagFilterSheet({
    super.key,
    required this.tags,
    required this.initialTagIds,
  });

  @override
  State<ContactTagFilterSheet> createState() => _ContactTagFilterSheetState();
}

class _ContactTagFilterSheetState extends State<ContactTagFilterSheet> {
  late final Set<String> _selectedTagIds;

  @override
  void initState() {
    super.initState();
    _selectedTagIds = widget.initialTagIds.toSet();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '按分组筛选联系人',
              style: TextStyle(
                fontSize: AppFontSize.titleLarge,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              '结果会按匹配分组数量从高到低排序。',
              style: TextStyle(
                fontSize: AppFontSize.bodySmall,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (widget.tags.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text('暂无分组可用于筛选。'),
              )
            else
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: widget.tags.map((tag) {
                  final selected = _selectedTagIds.contains(tag.id);
                  return FilterChip(
                    label: Text(tag.name),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        if (selected) {
                          _selectedTagIds.remove(tag.id);
                        } else {
                          _selectedTagIds.add(tag.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop<ContactTagFilterSelection>(
                        const <String>[],
                      );
                    },
                    child: const Text('清空'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop<ContactTagFilterSelection>(
                        _selectedTagIds.toList(),
                      );
                    },
                    child: const Text('应用筛选'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}