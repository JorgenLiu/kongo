import 'package:flutter/material.dart';

import '../../config/app_constants.dart';

class EventPostEventFollowUpCard extends StatefulWidget {
  final bool autofocus;
  final Future<void> Function(String note) onSave;

  const EventPostEventFollowUpCard({
    super.key,
    required this.onSave,
    this.autofocus = false,
  });

  @override
  State<EventPostEventFollowUpCard> createState() => _EventPostEventFollowUpCardState();
}

class _EventPostEventFollowUpCardState extends State<EventPostEventFollowUpCard> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: colorScheme.primaryContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.post_add_outlined, color: colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '会后补充',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '用一句话记下这次沟通的决定、承诺或后续动作，后面回看事件会轻松很多。',
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('event_follow_up_input'),
              controller: _controller,
              autofocus: widget.autofocus,
              enabled: !_saving,
              maxLength: 120,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              decoration: const InputDecoration(
                labelText: '一句话补充',
                hintText: '例如：客户确认下周给反馈，我负责周三前补报价',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? '保存中...' : '保存补充'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final note = _controller.text.trim();
    if (note.isEmpty) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await widget.onSave(note);
      if (!mounted) {
        return;
      }
      _controller.clear();
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }
}