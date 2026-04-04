import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_constants.dart';
import '../../providers/global_search_provider.dart';
import '../../repositories/info_tag_repository.dart';
import '../../repositories/quick_note_repository.dart';
import '../../services/attachment_service.dart';
import '../../services/contact_service.dart';
import '../../services/read/event_read_service.dart';
import '../../services/summary_service.dart';
import '../../utils/input_debouncer.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/skeleton_list.dart';
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
        context.read<AttachmentService>(),
        context.read<QuickNoteRepository>(),
        infoTagRepository: context.read<InfoTagRepository>(),
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
  late final InputDebouncer _searchDebouncer;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchDebouncer = InputDebouncer();
  }

  @override
  void dispose() {
    _searchDebouncer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchChanged(String keyword) {
    _searchDebouncer.run(() {
      if (!mounted) {
        return;
      }

      context.read<GlobalSearchProvider>().search(keyword);
    });
  }

  void _handleSearchClear() {
    _searchDebouncer.cancel();
    context.read<GlobalSearchProvider>().search('');
  }

  @override
  Widget build(BuildContext context) {
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
              child: const WorkbenchPageHeader(
                eyebrow: 'Search',
                title: '检索',
                titleKey: Key('globalSearchPageHeaderTitle'),
              ),
            ),
            custom_search.SearchBar(
              controller: _searchController,
              hintText: '搜索联系人、日程、地点、总结内容、文件、记录...',
              onChanged: _handleSearchChanged,
              onClear: _handleSearchClear,
            ),
            Consumer<GlobalSearchProvider>(
              builder: (context, provider, _) {
                return Padding(
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
                );
              },
            ),
            Expanded(
              child: Consumer<GlobalSearchProvider>(
                builder: (context, provider, _) => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildBody(context, provider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, GlobalSearchProvider provider) {
    if (provider.loading && !provider.initialized) {
      return const SkeletonList(key: ValueKey('search_skeleton'));
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
        subtitle: '支持搜索姓名、电话、地点、日程标题或总结内容',
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
          attachments: provider.attachments,
          notes: provider.notes,
          contactsByInfoTag: provider.contactsByInfoTag,
          onContactTap: (contact) => openGlobalSearchContact(context, contact),
          onEventTap: (item) => openGlobalSearchEvent(context, item),
          onSummaryTap: (summary) => openGlobalSearchSummary(context, summary),
          onAttachmentTap: (attachment) => openGlobalSearchAttachment(context, attachment),
          onNoteTap: (note) => openGlobalSearchNote(context, note),
        ),
      ],
    );
  }
}