import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_constants.dart';
import '../../models/calendar_time_node.dart';
import '../../providers/calendar_time_node_settings_provider.dart';

class CalendarTimeNodeSection extends StatelessWidget {
  const CalendarTimeNodeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Consumer<CalendarTimeNodeSettingsProvider>(
      builder: (context, provider, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.event_note_outlined, size: 20, color: colorScheme.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '时间节点',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '控制日程页周历和月历中展示哪些时间节点来源。',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _CalendarTimeNodeToggleTile(
                  kind: CalendarTimeNodeKind.contactMilestone,
                  value: provider.isEnabled(CalendarTimeNodeKind.contactMilestone),
                  enabled: !provider.loading,
                ),
                const Divider(height: AppSpacing.lg),
                _CalendarTimeNodeToggleTile(
                  kind: CalendarTimeNodeKind.publicHoliday,
                  value: provider.isEnabled(CalendarTimeNodeKind.publicHoliday),
                  enabled: !provider.loading,
                ),
                const Divider(height: AppSpacing.lg),
                _CalendarTimeNodeToggleTile(
                  kind: CalendarTimeNodeKind.marketingCampaign,
                  value: provider.isEnabled(CalendarTimeNodeKind.marketingCampaign),
                  enabled: !provider.loading,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CalendarTimeNodeToggleTile extends StatelessWidget {
  final CalendarTimeNodeKind kind;
  final bool value;
  final bool enabled;

  const _CalendarTimeNodeToggleTile({
    required this.kind,
    required this.value,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SwitchListTile(
      value: value,
      onChanged: enabled
          ? (nextValue) => _handleChanged(context, nextValue)
          : null,
      title: Text(
        kind.label,
        style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(kind.description),
      contentPadding: EdgeInsets.zero,
    );
  }

  Future<void> _handleChanged(BuildContext context, bool nextValue) async {
    try {
      await context.read<CalendarTimeNodeSettingsProvider>().setKindEnabled(kind, nextValue);
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('时间节点设置保存失败，请稍后重试')),
      );
    }
  }
}