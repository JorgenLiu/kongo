import 'package:flutter/material.dart';

import '../../config/app_constants.dart';
import '../../providers/files_provider.dart';

class FileLibraryFilterBar extends StatelessWidget {
  final FilesLibraryStorageFilter activeStorageFilter;
  final FilesLibrarySort activeSort;
  final bool missingSourceOnly;
  final ValueChanged<FilesLibraryStorageFilter> onStorageFilterChanged;
  final ValueChanged<FilesLibrarySort> onSortChanged;
  final ValueChanged<bool> onMissingSourceOnlyChanged;

  const FileLibraryFilterBar({
    super.key,
    required this.activeStorageFilter,
    required this.activeSort,
    required this.missingSourceOnly,
    required this.onStorageFilterChanged,
    required this.onSortChanged,
    required this.onMissingSourceOnlyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
      child: Row(
        children: [
          _SortMenu(
            activeSort: activeSort,
            onChanged: onSortChanged,
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterChip(
            label: '全部',
            selected: activeStorageFilter == FilesLibraryStorageFilter.all,
            onSelected: () => onStorageFilterChanged(FilesLibraryStorageFilter.all),
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterChip(
            label: '已托管',
            selected: activeStorageFilter == FilesLibraryStorageFilter.managed,
            onSelected: () => onStorageFilterChanged(FilesLibraryStorageFilter.managed),
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterChip(
            label: '外部引用',
            selected: activeStorageFilter == FilesLibraryStorageFilter.linked,
            onSelected: () => onStorageFilterChanged(FilesLibraryStorageFilter.linked),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilterChip(
            label: const Text('原文件缺失'),
            selected: missingSourceOnly,
            onSelected: onMissingSourceOnlyChanged,
          ),
        ],
      ),
    );
  }
}

class _SortMenu extends StatelessWidget {
  final FilesLibrarySort activeSort;
  final ValueChanged<FilesLibrarySort> onChanged;

  const _SortMenu({
    required this.activeSort,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<FilesLibrarySort>(
      tooltip: '排序方式',
      onSelected: onChanged,
      itemBuilder: (context) => [
        _buildItem(FilesLibrarySort.updatedAtDesc, '最近更新'),
        _buildItem(FilesLibrarySort.fileNameAsc, '文件名 A-Z'),
        _buildItem(FilesLibrarySort.fileSizeDesc, '文件大小'),
      ],
      child: InputChip(
        avatar: const Icon(Icons.swap_vert_rounded, size: 18),
        label: Text(_labelFor(activeSort)),
        onPressed: null,
      ),
    );
  }

  PopupMenuItem<FilesLibrarySort> _buildItem(FilesLibrarySort sort, String label) {
    return PopupMenuItem<FilesLibrarySort>(
      value: sort,
      child: Row(
        children: [
          Icon(
            activeSort == sort ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(label),
        ],
      ),
    );
  }

  String _labelFor(FilesLibrarySort sort) {
    switch (sort) {
      case FilesLibrarySort.updatedAtDesc:
        return '最近更新';
      case FilesLibrarySort.fileNameAsc:
        return '文件名 A-Z';
      case FilesLibrarySort.fileSizeDesc:
        return '文件大小';
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}