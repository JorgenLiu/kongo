import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../models/home_daily_brief.dart';
import '../../widgets/common/error_state.dart';
import 'ai_daily_brief_card.dart';
import 'home_daily_brief_item_list.dart';
import 'home_daily_brief_summary_panel.dart';

class HomeDailyBriefHero extends StatelessWidget {
  final HomeDailyBrief? brief;
  final bool loading;
  final bool refreshing;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final HomeDailyBriefActionHandler? onActionTap;

  const HomeDailyBriefHero({
    super.key,
    required this.brief,
    this.loading = false,
    this.refreshing = false,
    this.errorMessage,
    this.onRetry,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      key: const Key('aiDailyBriefCard'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.tertiaryContainer.withValues(alpha: 0.92),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroHeader(
              refreshing: refreshing,
              disableRefresh: loading || refreshing,
              onRetry: onRetry,
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildBody(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final resolvedBrief = brief;

    if (loading && resolvedBrief == null) {
      return const SizedBox(
        key: Key('aiDailyBriefLoadingState'),
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null && resolvedBrief == null) {
      return ErrorState(
        key: const Key('aiDailyBriefErrorState'),
        message: errorMessage!,
        onRetry: onRetry,
        retryLabel: '重新生成',
      );
    }

    if (resolvedBrief == null) {
      return const _HeroInfoBlock(
        key: Key('aiDailyBriefUnavailableState'),
        title: '今日简报暂未就绪',
        message: '加载首页数据后，秘书简报会在这里出现。',
      );
    }

    switch (resolvedBrief.status) {
      case HomeDailyBriefStatus.unavailable:
        return _HeroInfoBlock(
          key: const Key('aiDailyBriefUnavailableState'),
          title: 'AI 尚未启用',
          message: resolvedBrief.summary ?? '配置 AI 后可获得今日秘书简报。',
        );
      case HomeDailyBriefStatus.failed:
        return ErrorState(
          key: const Key('aiDailyBriefErrorState'),
          message: resolvedBrief.errorMessage ?? '今日简报生成失败',
          onRetry: onRetry,
          retryLabel: '重新生成',
        );
      case HomeDailyBriefStatus.empty:
        return _HeroInfoBlock(
          key: const Key('aiDailyBriefEmptyState'),
          title: '今天节奏平稳',
          message: resolvedBrief.summary ?? '今天没有明显风险或待跟进项。',
        );
      case HomeDailyBriefStatus.ready:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (resolvedBrief.summary != null && resolvedBrief.summary!.isNotEmpty)
              HomeDailyBriefSummaryPanel(summary: resolvedBrief.summary!),
            if (resolvedBrief.summary != null && resolvedBrief.summary!.isNotEmpty)
              const SizedBox(height: AppSpacing.lg),
            HomeDailyBriefItemList(
              items: resolvedBrief.items,
              onActionTap: onActionTap,
            ),
          ],
        );
    }
  }
}

class _HeroHeader extends StatelessWidget {
  final bool refreshing;
  final bool disableRefresh;
  final VoidCallback? onRetry;

  const _HeroHeader({
    required this.refreshing,
    required this.disableRefresh,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.26),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(
            Icons.auto_awesome,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '今日秘书简报',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '先读结论，再进入今天的工作台。',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          key: const Key('aiDailyBriefRefreshButton'),
          tooltip: '刷新今日简报',
          onPressed: disableRefresh ? null : onRetry,
          icon: refreshing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.refresh, color: colorScheme.onPrimaryContainer),
        ),
      ],
    );
  }
}

class _HeroInfoBlock extends StatelessWidget {
  final String title;
  final String message;

  const _HeroInfoBlock({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.82),
            ),
          ),
        ],
      ),
    );
  }
}