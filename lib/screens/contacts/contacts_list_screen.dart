import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_constants.dart';
import '../../models/tag.dart';
import '../../providers/contact_provider.dart';
import '../../providers/tag_provider.dart';
import '../../utils/contact_indexing.dart';
import '../../utils/input_debouncer.dart';
import '../../widgets/common/workbench_page_header.dart';
import '../../widgets/contact/contact_alphabet_index_bar.dart';
import '../../widgets/contact/contact_active_tag_filters.dart';
import '../../widgets/contact/contact_group_section.dart';
import '../../widgets/contact/contact_header_tags_bar.dart';
import '../../widgets/contact/contact_upcoming_milestones_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/skeleton_list.dart';
import '../../widgets/common/search_bar.dart' as custom_search;
import 'contacts_list_actions.dart';

/// 联系人列表屏幕
class ContactsListScreen extends StatefulWidget {
  const ContactsListScreen({super.key});

  @override
  State<ContactsListScreen> createState() => _ContactsListScreenState();
}

class _ContactsListScreenState extends State<ContactsListScreen> {
  late TextEditingController _searchController;
  late ScrollController _listScrollController;
  late final InputDebouncer _searchDebouncer;
  bool _headerTagsExpanded = false;
  String? _selectedQuickIndex;
  final Map<String, GlobalKey> _groupHeaderKeys = <String, GlobalKey>{};
  final GlobalKey _listViewportKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _listScrollController = ScrollController();
    _searchDebouncer = InputDebouncer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contactProvider = context.read<ContactProvider>();
      final tagProvider = context.read<TagProvider>();
      if (!contactProvider.initialized) {
        contactProvider.loadContacts();
      }
      if (!tagProvider.initialized) {
        tagProvider.loadTags();
      }
    });
  }

  @override
  void dispose() {
    _searchDebouncer.dispose();
    _searchController.dispose();
    _listScrollController.dispose();
    super.dispose();
  }

  /// 搜索联系人
  void _searchContacts(String query) {
    setState(() {
      _selectedQuickIndex = null;
    });
    _searchDebouncer.run(() {
      if (!mounted) {
        return;
      }

      context.read<ContactProvider>().searchByKeyword(query);
    });
  }

  void _clearSearchAndFilters() {
    _searchDebouncer.cancel();
    setState(() {
      _selectedQuickIndex = null;
    });
    context.read<ContactProvider>().clearFilters();
  }

  Future<void> _applyHeaderTag(Tag tag, ContactProvider contactProvider) async {
    setState(() {
      _selectedQuickIndex = null;
    });
    _searchController.clear();

    final nextTagIds = contactProvider.selectedTagIds.toSet();
    if (nextTagIds.contains(tag.id)) {
      nextTagIds.remove(tag.id);
    } else {
      nextTagIds.add(tag.id);
    }

    if (nextTagIds.isEmpty) {
      await contactProvider.clearFilters();
      return;
    }

    await contactProvider.searchByTags(nextTagIds.toList());
  }

  Future<void> _openContactDetail(dynamic contact) async {
    await openContactDetailFromList(context, contact);
  }

  Widget _buildTopHeader(ContactProvider contactProvider, TagProvider tagProvider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: WorkbenchPageHeader(
        eyebrow: 'Contacts',
        title: '通讯录',
        titleKey: const Key('contactsPageHeaderTitle'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.tonalIcon(
              onPressed: () => openTagManagementFromList(context),
              icon: const Icon(Icons.label_outline),
              label: const Text('分组管理'),
            ),
            const SizedBox(width: AppSpacing.sm),
            FilledButton.icon(
              onPressed: () => createContactFromList(context),
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('新建联系人'),
            ),
          ],
        ),
        metadata: [
          ContactHeaderTagsBar(
            tags: tagProvider.tags,
            selectedTagIds: contactProvider.selectedTagIds,
            expanded: _headerTagsExpanded,
            onToggleExpanded: () {
              setState(() {
                _headerTagsExpanded = !_headerTagsExpanded;
              });
            },
            onTagTap: (tag) => _applyHeaderTag(tag, contactProvider),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Consumer2<ContactProvider, TagProvider>(
              builder: (context, contactProvider, tagProvider, _) {
                return _buildTopHeader(contactProvider, tagProvider);
              },
            ),
            Expanded(
              child: Consumer2<ContactProvider, TagProvider>(
                builder: (context, contactProvider, tagProvider, _) {
                  final contactGroups = buildContactGroups(contactProvider.contacts);
                  final quickIndices = buildContactIndices(contactProvider.contacts);
                  final effectiveQuickIndex =
                      quickIndices.contains(_selectedQuickIndex) ? _selectedQuickIndex : null;
                  final selectedTags = resolveSelectedTags(
                    tagProvider.tags,
                    contactProvider.selectedTagIds,
                  );

                  return _buildListPane(
                    context,
                    contactProvider: contactProvider,
                    selectedTags: selectedTags,
                    contactGroups: contactGroups,
                    quickIndices: quickIndices,
                    selectedQuickIndex: effectiveQuickIndex,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListPane(
    BuildContext context, {
    required ContactProvider contactProvider,
    required List<Tag> selectedTags,
    required List<ContactGroup> contactGroups,
    required List<String> quickIndices,
    required String? selectedQuickIndex,
  }) {
    final contactCount = contactGroups.fold<int>(0, (sum, group) => sum + group.contacts.length);

    return Column(
      children: [
        custom_search.SearchBar(
          controller: _searchController,
          onChanged: _searchContacts,
          onClear: _clearSearchAndFilters,
          trailing: Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Text(
              key: const Key('contactsBodyCountLabel'),
              '$contactCount 人',
              style: TextStyle(
                fontSize: AppFontSize.bodySmall,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
        ),
        if (selectedTags.isNotEmpty)
          ContactActiveTagFilters(
            selectedTags: selectedTags,
            onOpenFilter: () => openTagFilterFromList(context),
            onClear: _clearSearchAndFilters,
          ),
        if (contactProvider.keyword.trim().isEmpty && selectedTags.isEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: ContactUpcomingMilestonesCard(
              items: contactProvider.upcomingMilestones,
              onContactTap: _openContactDetail,
            ),
          ),
          const Divider(height: 1, indent: AppSpacing.md, endIndent: AppSpacing.md),
          const SizedBox(height: AppSpacing.sm),
        ],
        Expanded(
          child: _buildBody(
            context,
            contactProvider,
            contactGroups,
            quickIndices,
            selectedQuickIndex,
          ),
        ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    ContactProvider contactProvider,
    List<ContactGroup> contactGroups,
    List<String> quickIndices,
    String? selectedQuickIndex,
  ) {
    final Widget child;

    if (contactProvider.loading && !contactProvider.initialized) {
      child = const SkeletonList(key: ValueKey('contacts_skeleton'));
    } else if (contactProvider.error != null && contactProvider.contacts.isEmpty) {
      child = ErrorState(
        key: const ValueKey('contacts_error'),
        message: contactProvider.error!.message,
        onRetry: contactProvider.loadContacts,
      );
    } else if (contactGroups.isEmpty) {
      child = _buildEmptyState();
    } else {
      child = Row(
        key: const ValueKey('contacts_content'),
      children: [
        Expanded(
          child: SingleChildScrollView(
            key: _listViewportKey,
            controller: _listScrollController,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < contactGroups.length; index++) ...[
                  ContactGroupSection(
                    key: ValueKey('contactGroup_${contactGroups[index].indexLabel}'),
                    label: contactGroups[index].indexLabel,
                    contacts: contactGroups[index].contacts,
                    headerKey: _headerKeyFor(contactGroups[index].indexLabel),
                    onTap: _openContactDetail,
                    onEdit: (contact) => editContactFromList(context, contact),
                    onDelete: (contact) => deleteContactFromList(context, contact),
                  ),
                  if (index < contactGroups.length - 1)
                    const SizedBox(height: AppSpacing.xs),
                ],
              ],
            ),
          ),
        ),
        if (quickIndices.length > 1) ...[
          const SizedBox(width: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.md,
              bottom: AppSpacing.md,
              right: AppSpacing.xs,
            ),
            child: ContactAlphabetIndexBar(
              indices: quickIndices,
              selectedIndex: selectedQuickIndex,
              onSelected: _handleQuickIndexSelected,
            ),
          ),
        ],
      ],
    );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: child,
    );
  }

  GlobalKey _headerKeyFor(String label) {
    return _groupHeaderKeys.putIfAbsent(label, GlobalKey.new);
  }

  Future<void> _handleQuickIndexSelected(String value) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _selectedQuickIndex = value;
    });

    final targetContext = _groupHeaderKeys[value]?.currentContext;
    final viewportContext = _listViewportKey.currentContext;
    if (targetContext == null || viewportContext == null) {
      return;
    }

    final targetBox = targetContext.findRenderObject() as RenderBox?;
    final viewportBox = viewportContext.findRenderObject() as RenderBox?;
    if (targetBox == null || viewportBox == null || !_listScrollController.hasClients) {
      return;
    }

    final offsetInViewport = targetBox.localToGlobal(
      Offset.zero,
      ancestor: viewportBox,
    ).dy;
    final targetOffset = (_listScrollController.offset + offsetInViewport - AppSpacing.sm).clamp(
      0.0,
      _listScrollController.position.maxScrollExtent,
    );

    await _listScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return EmptyState(
      icon: Icons.contacts_outlined,
      iconSize: 80,
      message: _searchController.text.isEmpty ? '暂无联系人' : '未找到匹配的联系人',
    );
  }
}
