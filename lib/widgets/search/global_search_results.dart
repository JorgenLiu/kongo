import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/contact.dart';
import '../../models/event_summary.dart';
import '../../services/read/event_read_service.dart';
import '../event/event_search_results_list.dart';
import 'highlighted_search_text.dart';

class GlobalSearchResults extends StatelessWidget {
  final String query;
  final List<Contact> contacts;
  final List<EventListItemReadModel> events;
  final List<DailySummary> summaries;
  final ValueChanged<Contact> onContactTap;
  final ValueChanged<EventListItemReadModel> onEventTap;
  final ValueChanged<DailySummary> onSummaryTap;

  const GlobalSearchResults({
    super.key,
    required this.query,
    required this.contacts,
    required this.events,
    required this.summaries,
    required this.onContactTap,
    required this.onEventTap,
    required this.onSummaryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (contacts.isNotEmpty) ...[
          _SearchSection(
            title: '联系人',
            count: contacts.length,
            child: Column(
              children: contacts
                  .map(
                    (contact) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _ContactSearchResultCard(
                        contact: contact,
                        query: query,
                        onTap: () => onContactTap(contact),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (events.isNotEmpty) ...[
          _SearchSection(
            title: '日程',
            count: events.length,
            child: EventSearchResultsList(
              items: events,
              highlightQuery: query,
              onItemTap: onEventTap,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (summaries.isNotEmpty)
          _SearchSection(
            title: '总结',
            count: summaries.length,
            child: Column(
              children: summaries
                  .map(
                    (summary) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _SummarySearchResultCard(
                        summary: summary,
                        query: query,
                        onTap: () => onSummaryTap(summary),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class _ContactSearchResultCard extends StatelessWidget {
  final Contact contact;
  final String query;
  final VoidCallback onTap;

  const _ContactSearchResultCard({
    required this.contact,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: HighlightedSearchText(
                      text: contact.name,
                      query: query,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: colorScheme.outline),
                ],
              ),
              if ((contact.phone ?? '').isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                HighlightedSearchText(
                  text: contact.phone!,
                  query: query,
                  style: TextStyle(color: colorScheme.outline),
                ),
              ],
              if ((contact.email ?? '').isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                HighlightedSearchText(
                  text: contact.email!,
                  query: query,
                  style: TextStyle(color: colorScheme.outline),
                ),
              ],
              if ((contact.notes ?? '').isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                HighlightedSearchText(
                  text: contact.notes!,
                  query: query,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SummarySearchResultCard extends StatelessWidget {
  final DailySummary summary;
  final String query;
  final VoidCallback onTap;

  const _SummarySearchResultCard({
    required this.summary,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${summary.summaryDate.year} 年 ${summary.summaryDate.month} 月 ${summary.summaryDate.day} 日',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _SummaryBlock(
                label: '当日总结',
                content: summary.todaySummary,
                query: query,
              ),
              const SizedBox(height: AppSpacing.sm),
              _SummaryBlock(
                label: '明日计划',
                content: summary.tomorrowPlan,
                query: query,
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: Icon(Icons.chevron_right_rounded, color: colorScheme.outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryBlock extends StatelessWidget {
  final String label;
  final String content;
  final String query;

  const _SummaryBlock({
    required this.label,
    required this.content,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        HighlightedSearchText(
          text: content.trim().isEmpty ? '未填写' : content.trim(),
          query: query,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _SearchSection extends StatelessWidget {
  final String title;
  final int count;
  final Widget child;

  const _SearchSection({
    required this.title,
    required this.count,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '$count 项',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }
}