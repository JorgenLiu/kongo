import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_constants.dart';
import '../../models/event.dart';
import '../../providers/event_detail_provider.dart';
import '../../services/read/event_read_service.dart';
import '../../services/read/todo_read_service.dart';
import '../../widgets/common/detail_skeleton.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/event/event_detail_attachments_section.dart';
import '../../widgets/event/event_detail_header.dart';
import '../../widgets/event/event_detail_info_section.dart';
import '../../widgets/event/event_detail_participants_section.dart';
import '../../widgets/todo/related_todo_section.dart';
import 'event_detail_actions.dart';
import '../todos/todo_link_actions.dart';

class EventDetailScreen extends StatelessWidget {
  final String eventId;

  const EventDetailScreen({
    super.key,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => EventDetailProvider(
        context.read<EventReadService>(),
        context.read<TodoReadService>(),
        eventId,
      )..load(),
      child: const _EventDetailView(),
    );
  }
}

class _EventDetailView extends StatelessWidget {
  const _EventDetailView();

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
                      onPressed: () => _editEvent(
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
                      onPressed: () => _deleteEvent(context, event: data.event),
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
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              EventDetailHeader(
                event: data.event,
                eventTypeName: data.eventTypeName,
                participantCount: data.participants.length,
                attachmentCount: data.attachments.length,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (wide)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: EventDetailInfoSection(
                          event: data.event,
                          createdByContact: data.createdByContact,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            EventDetailParticipantsSection(
                              participants: data.participantEntries,
                              onOpenContact: (participant) =>
                                  openEventParticipantContactDetail(
                                      context, participant.contact.id),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            EventDetailAttachmentsSection(
                              attachments: data.attachments,
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
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                EventDetailInfoSection(
                  event: data.event,
                  createdByContact: data.createdByContact,
                ),
                const SizedBox(height: AppSpacing.lg),
                EventDetailParticipantsSection(
                  participants: data.participantEntries,
                  onOpenContact: (participant) =>
                      openEventParticipantContactDetail(context, participant.contact.id),
                ),
                const SizedBox(height: AppSpacing.lg),
                EventDetailAttachmentsSection(
                  attachments: data.attachments,
                  onAddAttachment: () => addEventAttachment(context, event: data.event),
                  onOpenAttachment: (attachment) => openEventAttachment(
                    context,
                    attachment: attachment,
                  ),
                  onUnlinkAttachment: (attachment) => unlinkEventAttachment(
                    context,
                    event: data.event,
                    attachment: attachment,
                  ),
                  onDeleteAttachment: (attachment) => deleteEventAttachment(
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
              ],
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

  Future<void> _editEvent(
    BuildContext context, {
    required Event event,
    required Map<String, String> participantRoles,
  }) {
    return editEventDetail(
      context,
      event: event,
      participantRoles: participantRoles,
    );
  }

  Future<void> _deleteEvent(BuildContext context, {required Event event}) {
    return deleteEventDetail(context, event: event);
  }
}