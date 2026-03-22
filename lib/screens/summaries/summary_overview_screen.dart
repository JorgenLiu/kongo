import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_constants.dart';
import '../../providers/summary_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/search_bar.dart' as custom_search;
import '../../widgets/common/workbench_page_header.dart';
import '../../widgets/summary/daily_summary_list.dart';
import 'summary_overview_actions.dart';

class SummaryOverviewScreen extends StatefulWidget {
  const SummaryOverviewScreen({super.key});

  @override
  State<SummaryOverviewScreen> createState() => _SummaryOverviewScreenState();
}

class _SummaryOverviewScreenState extends State<SummaryOverviewScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SummaryProvider>();
      if (!provider.initialized && !provider.loading) {
        provider.loadSummaries();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SummaryProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: WorkbenchPageHeader(
                    eyebrow: 'Summary',
                    title: '总结',
                    titleKey: const Key('summaryPageHeaderTitle'),
                    description: '按天记录工作推进，拆分为当日总结和明日计划。',
                    trailing: FilledButton.icon(
                      onPressed: () => createDailySummary(context),
                      icon: const Icon(Icons.add),
                      label: const Text('新建总结'),
                    ),
                  ),
                ),
                custom_search.SearchBar(
                  controller: _searchController,
                  hintText: '搜索总结内容或明日计划...',
                  onChanged: provider.searchByKeyword,
                  onClear: provider.clearFilters,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      provider.keyword.trim().isEmpty
                          ? '共 ${provider.summaries.length} 条总结'
                          : '找到 ${provider.summaries.length} 条总结',
                      style: TextStyle(
                        fontSize: AppFontSize.bodySmall,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _buildBody(provider),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(SummaryProvider provider) {
    if (provider.loading && !provider.initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null && provider.summaries.isEmpty) {
      return ErrorState(
        message: provider.error!.message,
        onRetry: provider.loadSummaries,
      );
    }

    return RefreshIndicator(
      onRefresh: provider.loadSummaries,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        children: [
          if (provider.summaries.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xl),
              child: EmptyState(
                icon: provider.keyword.trim().isEmpty
                    ? Icons.summarize_outlined
                    : Icons.search_off_outlined,
                message: provider.keyword.trim().isEmpty ? '还没有每日总结' : '未找到匹配的总结',
              ),
            )
          else
            DailySummaryList(
              summaries: provider.summaries,
              onEdit: (summary) => editDailySummary(context, summary: summary),
              onDelete: (summary) => deleteDailySummary(context, summary: summary),
            ),
        ],
      ),
    );
  }
}