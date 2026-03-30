import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_constants.dart';
import '../../models/reminder_default_offset.dart';
import '../../models/reminder_authorization_status.dart';
import '../../providers/reminder_settings_provider.dart';

class ReminderSettingsSection extends StatelessWidget {
  const ReminderSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final provider = context.watch<ReminderSettingsProvider>();
    final settings = provider.settings;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_active_outlined, size: 20, color: colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '系统提醒',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Chip(label: Text(provider.authorizationStatus.label)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'v1 先支持 macOS 本地通知，覆盖事件提醒、联系人重要日期提醒，以及复用首页摘要的每日 AI 简报提醒。农历重要日期暂不参与通知调度。',
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
            ),
            const SizedBox(height: AppSpacing.md),
            if (provider.loading)
              const Center(child: CircularProgressIndicator())
            else ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: settings.remindersEnabled,
                onChanged: provider.busy ? null : provider.setRemindersEnabled,
                title: const Text('启用系统提醒'),
                subtitle: const Text('关闭后会取消当前已调度的 Kongo 通知'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: settings.eventRemindersEnabled,
                onChanged: provider.busy || !settings.remindersEnabled
                    ? null
                    : provider.setEventRemindersEnabled,
                title: const Text('事件提醒'),
                subtitle: const Text('根据事件提醒时间触发本地通知'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: settings.milestoneRemindersEnabled,
                onChanged: provider.busy || !settings.remindersEnabled
                    ? null
                    : provider.setMilestoneRemindersEnabled,
                title: const Text('联系人重要日期提醒'),
                subtitle: const Text('按提前天数在当天上午 9 点触发提醒'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: settings.postEventFollowUpEnabled,
                onChanged: provider.busy || !settings.remindersEnabled
                    ? null
                    : provider.setPostEventFollowUpEnabled,
                title: const Text('会后补充提醒'),
                subtitle: const Text('事件结束后提醒你用一句话补充决定、承诺或后续动作'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: settings.dailyBriefReminderEnabled,
                onChanged: provider.busy || !settings.remindersEnabled
                    ? null
                    : provider.setDailyBriefReminderEnabled,
                title: const Text('每日 AI 简报提醒'),
                subtitle: const Text('固定时间推送当天首页 AI 简报摘要'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                enabled: !provider.busy &&
                    settings.remindersEnabled &&
                    settings.dailyBriefReminderEnabled,
                title: const Text('每日 AI 简报时间'),
                subtitle: const Text('提醒内容直接复用当天首页 AI 简报摘要'),
                trailing: Text(
                  _formatTimeLabel(
                    settings.dailyBriefReminderHour,
                    settings.dailyBriefReminderMinute,
                  ),
                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                onTap: !provider.busy &&
                        settings.remindersEnabled &&
                        settings.dailyBriefReminderEnabled
                    ? () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                            hour: settings.dailyBriefReminderHour,
                            minute: settings.dailyBriefReminderMinute,
                          ),
                        );
                        if (picked == null || !context.mounted) {
                          return;
                        }
                        await provider.setDailyBriefReminderTime(
                          hour: picked.hour,
                          minute: picked.minute,
                        );
                      }
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<ReminderDefaultOffset>(
                isExpanded: true,
                initialValue: settings.eventDefaultOffset,
                decoration: const InputDecoration(labelText: '新建事件默认提醒'),
                items: ReminderDefaultOffset.values
                    .map(
                      (option) => DropdownMenuItem(
                        value: option,
                        child: Text(option.label),
                      ),
                    )
                    .toList(growable: false),
                onChanged: provider.busy || !settings.remindersEnabled
                    ? null
                    : (value) {
                        if (value != null) {
                          provider.setEventDefaultOffset(value);
                        }
                      },
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<int>(
                isExpanded: true,
                initialValue: settings.milestoneDefaultReminderDaysBefore,
                decoration: const InputDecoration(labelText: '新建重要日期默认提醒'),
                items: kMilestoneReminderDayOptions
                    .map(
                      (option) => DropdownMenuItem(
                        value: option.daysBefore,
                        child: Text(option.label),
                      ),
                    )
                    .toList(growable: false),
                onChanged: provider.busy || !settings.remindersEnabled
                    ? null
                    : (value) {
                        if (value != null) {
                          provider.setMilestoneDefaultReminderDaysBefore(value);
                        }
                      },
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: provider.busy ? null : provider.requestAuthorization,
                    icon: provider.requestingAuthorization
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.lock_open_outlined),
                    label: Text(provider.requestingAuthorization ? '请求中...' : '请求通知权限'),
                  ),
                  FilledButton.icon(
                    onPressed: provider.busy ? null : provider.rebuildNow,
                    icon: provider.rebuilding
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync_outlined),
                    label: Text(provider.rebuilding ? '重建中...' : '立即重建提醒'),
                  ),
                ],
              ),
              if (provider.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  provider.errorMessage!,
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _formatTimeLabel(int hour, int minute) {
    final hourLabel = hour.toString().padLeft(2, '0');
    final minuteLabel = minute.toString().padLeft(2, '0');
    return '$hourLabel:$minuteLabel';
  }
}