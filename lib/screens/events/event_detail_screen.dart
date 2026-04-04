import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_constants.dart';
import '../../models/event.dart';
import '../../providers/event_detail_provider.dart';
import '../../services/read/event_read_service.dart';
import '../../services/read/notes_read_service.dart';
import '../../services/read/todo_read_service.dart';
import '../../widgets/common/detail_skeleton.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/responsive_detail_layout.dart';
import '../../widgets/event/event_detail_attachments_section.dart';
import '../../widgets/event/event_detail_header.dart';
import '../../widgets/event/event_detail_info_section.dart';
import '../../widgets/event/event_detail_participants_section.dart';
import '../../widgets/event/event_post_event_follow_up_card.dart';
import '../../widgets/notes/linked_notes_section.dart';
import '../../widgets/todo/related_todo_section.dart';
import 'event_detail_actions.dart';
import '../todos/todo_link_actions.dart';

class EventDetailScreen extends StatelessWidget {
  final String eventId;
  final bool preferPostEventFollowUp;

  const EventDetailScreen({
    super.key,
    required this.eventId,
    this.preferPostEventFollowUp = false,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => EventDetailProvider(
        context.read<EventReadService>(),
        context.read<TodoReadService>(),
        eventId,
        notesReadService: context.read<NotesReadService>(),
      )..load(),
      child: _EventDetailView(preferPostEventFollowUp: preferPostEventFollowUp),
    );
  }
}

class _EventDetailView extends StatelessWidget {
  final bool preferPostEventFollowUp;

  const _EventDetailView({required this.preferPostEventFollowUp});

  @override
  Widget build(BuildContext context) {
    return Consumer<EventDetailProvider>(
      builder: (context, provider, _) {
        final data = provider.data;

        return Scaffold(
          appBar: AppBar(
            title: const Text('事件详情'),
            actions: data == null
                ? null
                : [
                    IconButton(
                      tooltip: '编辑事件',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => editEventDetail(
                        context,
                        event: data.event,
                        participantRoles: {
                          for (final entry in data.participantEntries)
                            entry.contact.id: entry.role,
                        },
                      ),
                    ),
                    IconButton(
                      tooltip: '删除事件',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => deleteEventDetail(context, event: data.event),
                    ),
                  ],
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildBody(context, provider),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, EventDetailProvider provider) {
    if (provider.loading && provider.data == null) {
      return const DetailSkeleton(key: ValueKey('event_detail_skeleton'));
    }

    if (provider.error != null && provider.data == null) {
      return KeyedSubtree(
        key: const ValueKey('event_detail_error'),
        child: _buildErrorState(provider),
      );
    }

    final data = provider.data;
    if (data == null) {
      return const SizedBox.shrink(key: ValueKey('event_detail_empty'));
    }

    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= AppBreakpoints.wide;
          final showPostEventFollowUp = _shouldShowPostEventFollowUp(data.event);
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              EventDetailHeader(
                event: data.event,
                eventTypeName: data.eventTypeName,
                participantCount: data.participants.length,
                attachmentCount: data.attachments.length,
              ),
              if (showPostEventFollowUp) ...[
                const SizedBox(height: AppSpacing.md),
                EventPostEventFollowUpCard(
                  autofocus: preferPostEventFollowUp,
                  onSave: (note) => saveEventFollowUpNote(
                    context,
                    event: data.event,
                    note: note,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              ...buildResponsiveDetailSections(
                wide: wide,
                primarySections: [
                  EventDetailInfoSection(
                    event: data.event,
                    createdByContact: data.createdByContact,
                  ),
                ],
                secondarySections: [
                  EventDetailParticipantsSection(
                    participants: data.participantEntries,
                    onOpenContact: (participant) =>
                        openEventParticipantContactDetail(
                            context, participant.contact.id),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  EventDetailAttachmentsSection(
                    attachments: data.attachments,
                    onOpenInLibrary: data.attachments.isNotEmpty
                        ? () => openEventFilesLibrary(context, event: data.event)
                        : null,
                    onAddAttachment: () =>
                        addEventAttachment(context, event: data.event),
                    onOpenAttachment: (attachment) => openEventAttachment(
                      context,
                      attachment: attachment,
                    ),
                    onUnlinkAttachment: (attachment) =>
                        unlinkEventAttachment(
                      context,
                      event: data.event,
                      attachment: attachment,
                    ),
                    onDeleteAttachment: (attachment) =>
                        deleteEventAttachment(
                      context,
                      event: data.event,
                      attachment: attachment,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  RelatedTodoSection(
                    title: '相关待办',
                    emptyMessage: '当前还没有关联到这个事件的待办项。',
                    items: provider.linkedTodoItems,
                    onCreate: () => createTodoFromEventDetailAction(context, data.event),
                    onOpenGroup: (item) => openTodoBoardForGroupAction(context, item.group.id),
                  ),
                  if (provider.linkedNotes.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    LinkedNotesSection(notes: provider.linkedNotes),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorState(EventDetailProvider provider) {
    return ErrorState(
      message: provider.error?.message ?? '事件详情加载失败',
      onRetry: provider.load,
    );
  }

  bool _shouldShowPostEventFollowUp(Event event) {
    final anchorTime = event.endAt ?? event.startAt;
    if (anchorTime == null) {
      return false;
    }

    final now = DateTime.now();
    if (anchorTime.isAfter(now)) {
      return false;
    }

    return anchorTime.isAfter(now.subtract(const Duration(days: 3)));
  }
}