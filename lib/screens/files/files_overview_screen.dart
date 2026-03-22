import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_constants.dart';
import '../../providers/files_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/file_library_item_card.dart';
import '../../widgets/common/workbench_page_header.dart';
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
                  ),
                ),
                custom_search.SearchBar(
                  controller: _searchController,
                  hintText: '搜索文件...',
                  onChanged: provider.searchByKeyword,
                ),
                Expanded(child: _buildBody(provider)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(FilesProvider provider) {
    if (provider.loading && !provider.initialized) {
      return const Center(child: CircularProgressIndicator());
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
        message: provider.keyword.isEmpty ? '暂无文件，事件和总结中的附件会集中显示在这里' : '未找到匹配的文件',
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
            onTap: () => openFileFromLibrary(context, attachment),
          ),
        );
      },
    );
  }
}