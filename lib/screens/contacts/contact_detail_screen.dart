import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_constants.dart';
import '../../providers/contact_detail_provider.dart';
import '../../services/read/contact_read_service.dart';
import '../../services/read/notes_read_service.dart';
import '../../services/read/todo_read_service.dart';
import '../../widgets/common/detail_skeleton.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/responsive_detail_layout.dart';
import '../../widgets/contact/contact_detail_attachments_section.dart';
import '../../widgets/contact/contact_detail_events_section.dart';
import '../../widgets/contact/contact_detail_header.dart';
import '../../widgets/contact/contact_detail_info_section.dart';
import '../../widgets/contact/contact_detail_milestones_section.dart';
import '../../widgets/contact/contact_detail_quick_entry_row.dart';
import '../../widgets/contact/contact_detail_info_tags_section.dart';
import '../../widgets/contact/contact_detail_tags_section.dart';
import '../../widgets/contact/contact_detail_notes_section.dart';
import '../../widgets/todo/related_todo_section.dart';
import 'contact_detail_actions.dart';
import '../todos/todo_link_actions.dart';

class ContactDetailScreen extends StatelessWidget {
  final String contactId;
  final bool showAppBar;

  const ContactDetailScreen({
    super.key,
    required this.contactId,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          ContactDetailProvider(
            context.read<ContactReadService>(),
            context.read<TodoReadService>(),
            contactId,
            notesReadService: context.read<NotesReadService>(),
          )..load(),
      child: _ContactDetailView(
        contactId: contactId,
        showAppBar: showAppBar,
      ),
    );
  }
}

class _ContactDetailView extends StatelessWidget {
  final String contactId;
  final bool showAppBar;

  const _ContactDetailView({
    required this.contactId,
    required this.showAppBar,
  });

  @override
  Widget build(BuildContext context) {
    final content = Consumer<ContactDetailProvider>(
      builder: (context, provider, _) {
        final Widget child;

        if (provider.loading && provider.data == null) {
          child = const DetailSkeleton(key: ValueKey('contact_detail_skeleton'));
        } else if (provider.error != null && provider.data == null) {
          child = KeyedSubtree(
            key: const ValueKey('contact_detail_error'),
            child: _buildErrorState(context, provider),
          );
        } else if (provider.data == null) {
          child = const SizedBox.shrink(key: ValueKey('contact_detail_empty'));
        } else {
          final data = provider.data!;

          child = RefreshIndicator(
            key: const ValueKey('contact_detail_content'),
            onRefresh: provider.refresh,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= AppBreakpoints.wide;
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  ContactDetailHeader(
                    contact: data.contact,
                    onEdit: () => editContactDetail(context, data.contact),
                    onDelete: () => deleteContactDetail(context, data.contact),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ContactDetailQuickEntryRow(
                    eventCount: data.events.length,
                    attachmentCount: data.attachments.length,
                    onEventsTap: () => openContactEventsModule(context, data.contact),
                    onAttachmentsTap: () => openContactFilesLibrary(
                      context,
                      contact: data.contact,
                      eventIds: data.events.map((e) => e.id).toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ...buildResponsiveDetailSections(
                    wide: wide,
                    primarySections: [
                      ContactDetailInfoSection(contact: data.contact),
                      const SizedBox(height: AppSpacing.lg),
                      ContactDetailTagsSection(tags: data.tags),
                      const SizedBox(height: AppSpacing.lg),
                      ContactDetailInfoTagsSection(infoTags: data.contact.infoTags),
                    ],
                    secondarySections: [
                      ContactDetailMilestonesSection(
                        milestones: data.milestones,
                        onAdd: () => addMilestoneAction(context, data.contact.id),
                        onEdit: (milestone) => editMilestoneAction(context, milestone),
                        onDelete: (milestone) => deleteMilestoneAction(context, milestone),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ContactDetailAttachmentsSection(
                        attachments: data.attachments,
                        onOpenModule: () => openContactFilesLibrary(
                          context,
                          contact: data.contact,
                          eventIds: data.events.map((e) => e.id).toList(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      RelatedTodoSection(
                        title: '相关待办',
                        emptyMessage: '当前还没有关联到这个联系人的待办项。',
                        items: provider.linkedTodoItems,
                        onCreate: () => createTodoFromContactDetailAction(context, data.contact),
                        onOpenGroup: (item) => openTodoBoardForGroupAction(context, item.group.id),
                      ),
                      if (provider.linkedNotes.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        ContactDetailNotesSection(
                          notes: provider.linkedNotes,
                          onViewAll: () => openNotesFilteredByContact(
                            context,
                            data.contact,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ContactDetailEventsSection(
                    contact: data.contact,
                    events: data.events,
                    eventTypeNames: data.eventTypeNames,
                    eventTypeColors: data.eventTypeColors,
                    onOpenModule: () => openContactEventsModule(context, data.contact),
                    onOpenEvent: (eventId) => openRelatedEventDetail(context, eventId),
                  ),
                ],
              );
            },
          ),
        );
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: child,
        );
      },
    );

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: const Text('联系人详情'),
            )
          : null,
      body: content,
    );
  }

  Widget _buildErrorState(BuildContext context, ContactDetailProvider provider) {
    return ErrorState(
      message: provider.error?.message ?? '联系人详情加载失败',
      onRetry: provider.load,
    );
  }
}