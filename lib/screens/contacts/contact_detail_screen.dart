import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_constants.dart';
import '../../providers/contact_detail_provider.dart';
import '../../services/read/contact_read_service.dart';
import '../../widgets/common/detail_skeleton.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/contact/contact_detail_attachments_section.dart';
import '../../widgets/contact/contact_detail_events_section.dart';
import '../../widgets/contact/contact_detail_header.dart';
import '../../widgets/contact/contact_detail_info_section.dart';
import '../../widgets/contact/contact_detail_quick_entry_row.dart';
import '../../widgets/contact/contact_detail_tags_section.dart';
import 'contact_detail_actions.dart';

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
          ContactDetailProvider(context.read<ContactReadService>(), contactId)..load(),
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
        if (provider.loading && provider.data == null) {
          return const DetailSkeleton();
        }

        if (provider.error != null && provider.data == null) {
          return _buildErrorState(context, provider);
        }

        final data = provider.data;
        if (data == null) {
          return const SizedBox.shrink();
        }

        return RefreshIndicator(
          onRefresh: provider.refresh,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              ContactDetailHeader(
                contact: data.contact,
                onEdit: () => editContactDetail(context, data.contact),
                onDelete: () => deleteContactDetail(context, data.contact),
              ),
              const SizedBox(height: AppSpacing.md),
              ContactDetailQuickEntryRow(
                eventCount: data.events.length,
                attachmentCount: data.attachments.length,
                onEventsTap: () => openContactEventsModule(context, data.contact),
                onAttachmentsTap: () => showPendingContactModuleHint(context, '附件'),
              ),
              const SizedBox(height: AppSpacing.md),
              ContactDetailInfoSection(contact: data.contact),
              const SizedBox(height: AppSpacing.md),
              ContactDetailTagsSection(tags: data.tags),
              const SizedBox(height: AppSpacing.md),
              ContactDetailEventsSection(
                contact: data.contact,
                events: data.events,
                eventTypeNames: data.eventTypeNames,
                onOpenModule: () => openContactEventsModule(context, data.contact),
                onOpenEvent: (eventId) => openRelatedEventDetail(context, eventId),
              ),
              const SizedBox(height: AppSpacing.md),
              ContactDetailAttachmentsSection(
                attachments: data.attachments,
                onOpenModule: () => showPendingContactModuleHint(context, '附件'),
              ),
            ],
          ),
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