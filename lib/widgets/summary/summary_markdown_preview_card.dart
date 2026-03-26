import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import 'summary_markdown_content.dart';

class SummaryMarkdownPreviewCard extends StatelessWidget {
  final TextEditingController todaySummaryController;
  final TextEditingController tomorrowPlanController;

  const SummaryMarkdownPreviewCard({
    super.key,
    required this.todaySummaryController,
    required this.tomorrowPlanController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        todaySummaryController,
        tomorrowPlanController,
      ]),
      builder: (context, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Markdown 预览',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '支持标题、列表、引用、代码块，以及 TODO/复选框写法。',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                _PreviewSection(
                  title: '当日总结预览',
                  content: todaySummaryController.text,
                ),
                const SizedBox(height: AppSpacing.md),
                _PreviewSection(
                  title: '明日计划预览',
                  content: tomorrowPlanController.text,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PreviewSection extends StatelessWidget {
  final String title;
  final String content;

  const _PreviewSection({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SummaryMarkdownContent(content: content),
      ],
    );
  }
}