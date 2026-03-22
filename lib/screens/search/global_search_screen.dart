import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_constants.dart';
import '../../providers/global_search_provider.dart';
import '../../services/contact_service.dart';
import '../../services/read/event_read_service.dart';
import '../../services/summary_service.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/search_bar.dart' as custom_search;
import '../../widgets/common/workbench_page_header.dart';
import '../../widgets/search/global_search_results.dart';
import 'global_search_actions.dart';

class GlobalSearchScreen extends StatelessWidget {
  const GlobalSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => GlobalSearchProvider(
        context.read<ContactService>(),
        context.read<EventReadService>(),
        context.read<SummaryService>(),
      ),
      child: const _GlobalSearchView(),
    );
  }
}

class _GlobalSearchView extends StatefulWidget {
  const _GlobalSearchView();

  @override
  State<_GlobalSearchView> createState() => _GlobalSearchViewState();
}

class _GlobalSearchViewState extends State<_GlobalSearchView> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GlobalSearchProvider>(
      builder: (context, provider, _) => Scaffold(
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
                child: const WorkbenchPageHeader(
                  eyebrow: 'Search',
                  title: '检索',
                  titleKey: Key('globalSearchPageHeaderTitle'),
                  description: '统一检索联系人、日程和总结，直接跳到对应处理页面。',
                ),
              ),
              custom_search.SearchBar(
                controller: _searchController,
                hintText: '搜索联系人、日程、地点、总结内容...',
                onChanged: provider.search,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    provider.hasQuery ? '共命中 ${provider.totalResults} 项结果' : '输入关键词开始检索',
                    style: TextStyle(
                      fontSize: AppFontSize.bodySmall,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
              ),
              Expanded(child: _buildBody(context, provider)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, GlobalSearchProvider provider) {
    if (provider.loading && !provider.initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null && provider.totalResults == 0) {
      return ErrorState(
        message: provider.error!.message,
        onRetry: () => provider.search(provider.keyword),
      );
    }

    if (!provider.hasQuery) {
      return const EmptyState(
        icon: Icons.travel_explore_outlined,
        message: '输入关键词以搜索联系人、日程和总结',
      );
    }

    if (provider.totalResults == 0) {
      return const EmptyState(
        icon: Icons.search_off_outlined,
        message: '未找到匹配内容',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      children: [
        GlobalSearchResults(
          query: provider.keyword,
          contacts: provider.contacts,
          events: provider.events,
          summaries: provider.summaries,
          onContactTap: (contact) => openGlobalSearchContact(context, contact),
          onEventTap: (item) => openGlobalSearchEvent(context, item),
          onSummaryTap: (summary) => openGlobalSearchSummary(context, summary),
        ),
      ],
    );
  }
}