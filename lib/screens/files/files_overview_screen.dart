import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_constants.dart';
import '../../models/attachment.dart';
import '../../providers/files_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/skeleton_list.dart';
import '../../widgets/common/file_library_item_card.dart';
import '../../widgets/common/workbench_page_header.dart';
import '../../widgets/files/file_library_filter_bar.dart';
import '../../widgets/files/file_library_selection_bar.dart';
import '../../widgets/common/search_bar.dart' as custom_search;
import 'files_overview_actions.dart';

class FilesOverviewScreen extends StatefulWidget {
  const FilesOverviewScreen({super.key});

  @override
  State<FilesOverviewScreen> createState() => _FilesOverviewScreenState();
}

class _FilesOverviewScreenState extends State<FilesOverviewScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<FilesProvider>();
      if (!provider.initialized && !provider.loading) {
        provider.loadFiles();
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
    return Consumer<FilesProvider>(
      builder: (context, provider, child) {
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
                    eyebrow: 'Files',
                    title: '文件',
                    titleKey: const Key('filesPageHeaderTitle'),
                    trailing: _buildHeaderActions(context, provider),
                  ),
                ),
                custom_search.SearchBar(
                  controller: _searchController,
                  hintText: '搜索文件...',
                  onChanged: provider.searchByKeyword,
                ),
                FileLibraryFilterBar(
                  activeStorageFilter: provider.activeStorageFilter,
                  activeSort: provider.activeSort,
                  missingSourceOnly: provider.missingSourceOnly,
                  onStorageFilterChanged: provider.updateStorageFilter,
                  onSortChanged: provider.updateSort,
                  onMissingSourceOnlyChanged: provider.setMissingSourceOnly,
                ),
                if (provider.selectionMode)
                  FileLibrarySelectionBar(
                    selectedCount: provider.selectedCount,
                    selectedLinkedCount: provider.selectedLinkedCount,
                    allVisibleSelected: provider.allVisibleSelected,
                    onToggleSelectAllVisible: provider.toggleSelectAllVisible,
                    onDeleteSelected: () => deleteSelectedFilesFromLibrary(context),
                    onCancelSelection: provider.exitSelectionMode,
                  ),
                Expanded(child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildBody(provider),
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(FilesProvider provider) {
    if (provider.loading && !provider.initialized) {
      return const SkeletonList(key: ValueKey('files_skeleton'));
    }

    if (provider.error != null && provider.files.isEmpty) {
      return ErrorState(
        message: provider.error!.message,
        onRetry: provider.loadFiles,
      );
    }

    if (provider.files.isEmpty) {
      return EmptyState(
        icon: Icons.folder_open_outlined,
        message: provider.keyword.isEmpty &&
                provider.activeStorageFilter == FilesLibraryStorageFilter.all &&
                !provider.missingSourceOnly
            ? '暂无文件，事件和总结中的附件会集中显示在这里'
            : '未找到匹配的文件',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      itemCount: provider.files.length,
      itemBuilder: (context, index) {
        final attachment = provider.files[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: FileLibraryItemCard(
            attachment: attachment,
            linkCount: provider.linkCountFor(attachment.id),
            selectionMode: provider.selectionMode,
            selected: provider.isSelected(attachment.id),
            onSelectedChanged: (_) => provider.toggleSelection(attachment.id),
            onTap: () => openFileFromLibrary(context, attachment),
            onPreview: () => openFilePreviewFromLibrary(context, attachment),
            onReveal: () => revealFileFromLibrary(context, attachment),
            onRelink: attachment.storageMode == AttachmentStorageMode.linked
                ? () => relinkFileFromLibrary(context, attachment)
                : null,
            onConvertToManaged: attachment.storageMode == AttachmentStorageMode.linked
                ? () => convertFileToManagedFromLibrary(context, attachment)
                : null,
            onDelete: () => deleteFileFromLibrary(context, attachment),
          ),
        );
      },
    );
  }

  Widget? _buildHeaderActions(BuildContext context, FilesProvider provider) {
    final actions = <Widget>[];

    if (!provider.selectionMode && provider.orphanFileCount > 0) {
      actions.add(
        FilledButton.tonalIcon(
          onPressed: () => cleanupOrphanFilesFromLibrary(context),
          icon: const Icon(Icons.cleaning_services_outlined),
          label: Text('清理孤立项 (${provider.orphanFileCount})'),
        ),
      );
    }

    actions.add(
      OutlinedButton.icon(
        onPressed: provider.selectionMode ? provider.exitSelectionMode : provider.enterSelectionMode,
        icon: Icon(provider.selectionMode ? Icons.close_rounded : Icons.checklist_rtl_outlined),
        label: Text(provider.selectionMode ? '退出多选' : '批量选择'),
      ),
    );

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.end,
      children: actions,
    );
  }
}