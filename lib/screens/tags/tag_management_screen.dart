import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_constants.dart';
import '../../models/tag.dart';
import '../../providers/tag_provider.dart';
import '../../utils/contact_action_helpers.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/search_bar.dart' as custom_search;
import '../../widgets/tag/tag_list_tile.dart';
import 'tag_management_actions.dart';

class TagManagementScreen extends StatefulWidget {
  const TagManagementScreen({super.key});

  @override
  State<TagManagementScreen> createState() => _TagManagementScreenState();
}

class _TagManagementScreenState extends State<TagManagementScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tagProvider = context.read<TagProvider>();
      if (!tagProvider.initialized) {
        tagProvider.loadTags();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createTag() async {
    final tagProvider = context.read<TagProvider>();
    final draft = await showTagFormDialog(
      context,
      existingTagNames: tagProvider.tags.map((tag) => tag.name.trim()).toSet(),
    );
    if (draft == null || !mounted) {
      return;
    }

    final provider = context.read<TagProvider>();
    await provider.createTag(draft);
    if (!mounted) {
      return;
    }

    showProviderResultSnackBar(
      context,
      error: provider.error,
      successMessage: '分组已创建',
      onErrorHandled: provider.clearError,
    );
  }

  Future<void> _editTag(Tag tag) async {
    final tagProvider = context.read<TagProvider>();
    final draft = await showTagFormDialog(
      context,
      initialTag: tag,
      existingTagNames: tagProvider.tags
          .where((candidate) => candidate.id != tag.id)
          .map((candidate) => candidate.name.trim())
          .toSet(),
    );
    if (draft == null || !mounted) {
      return;
    }

    final provider = context.read<TagProvider>();
    await provider.updateTag(
      tag.copyWith(name: draft.name),
    );
    if (!mounted) {
      return;
    }

    showProviderResultSnackBar(
      context,
      error: provider.error,
      successMessage: '分组已更新',
      onErrorHandled: provider.clearError,
    );
  }

  Future<void> _deleteTag(Tag tag) async {
    final confirmed = await showDeleteTagConfirmDialog(
      context,
      tag: tag,
    );
    if (!confirmed || !mounted) {
      return;
    }

    final provider = context.read<TagProvider>();
    await provider.deleteTag(tag.id);
    if (!mounted) {
      return;
    }

    showProviderResultSnackBar(
      context,
      error: provider.error,
      successMessage: '分组已删除',
      onErrorHandled: provider.clearError,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TagProvider>(
      builder: (context, tagProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('分组管理'),
          ),
          body: SafeArea(
            child: Column(
              children: [
                custom_search.SearchBar(
                  controller: _searchController,
                  hintText: '搜索分组...',
                  onChanged: tagProvider.searchByKeyword,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('${tagProvider.tags.length} 个分组'),
                  ),
                ),
                Expanded(child: _buildBody(tagProvider)),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _createTag,
            tooltip: '新建分组',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildBody(TagProvider tagProvider) {
    if (tagProvider.loading && !tagProvider.initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tagProvider.error != null && tagProvider.tags.isEmpty) {
      return ErrorState(
        message: tagProvider.error!.message,
        onRetry: tagProvider.loadTags,
      );
    }

    if (tagProvider.tags.isEmpty) {
      return EmptyState(
        icon: Icons.label_outline,
        message: _searchController.text.isEmpty ? '暂无分组' : '未找到匹配的分组',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      itemCount: tagProvider.tags.length,
      itemBuilder: (context, index) {
        final tag = tagProvider.tags[index];
        return TagListTile(
          tag: tag,
          onEdit: () => _editTag(tag),
          onDelete: () => _deleteTag(tag),
        );
      },
    );
  }
}