import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../../config/app_constants.dart';
import '../../models/event.dart';
import '../../models/event_draft.dart';
import '../../providers/event_provider.dart';
import '../../providers/tag_provider.dart';
import '../../utils/unsaved_changes_guard.dart';
import '../../utils/event_participant_roles.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/event/event_form_basic_section.dart';
import '../../widgets/event/event_form_participants_section.dart';
import '../../widgets/event/event_form_schedule_section.dart';

class EventFormScreen extends StatefulWidget {
  final Event? initialEvent;
  final Map<String, String> initialParticipantRoles;
  final String? suggestedContactId;

  const EventFormScreen({
    super.key,
    this.initialEvent,
    this.initialParticipantRoles = const {},
    this.suggestedContactId,
  });

  bool get isEditing => initialEvent != null;

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController;

  String? _selectedEventTypeId;
  String? _selectedCreatedByContactId;
  late Map<String, String> _selectedParticipantRoles;
  DateTime? _startAt;
  DateTime? _endAt;
  String? _participantErrorText;
  bool _isSaving = false;
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    final initialEvent = widget.initialEvent;
    _titleController = TextEditingController(text: initialEvent?.title ?? '');
    _locationController = TextEditingController(text: initialEvent?.location ?? '');
    _descriptionController = TextEditingController(text: initialEvent?.description ?? '');
    _selectedEventTypeId = initialEvent?.eventTypeId;
    _selectedCreatedByContactId = initialEvent?.createdByContactId ?? widget.suggestedContactId;
    _selectedParticipantRoles = {
      ...widget.initialParticipantRoles.map(
        (contactId, role) => MapEntry(contactId, EventParticipantRoles.normalize(role)),
      ),
      if (widget.initialParticipantRoles.isEmpty && widget.suggestedContactId != null)
        widget.suggestedContactId!: EventParticipantRoles.participant,
    };
    _startAt = initialEvent?.startAt;
    _endAt = initialEvent?.endAt;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing ? '编辑事件' : '新建事件';

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        if (_allowPop || !_hasUnsavedChanges) {
          return true;
        }

        return showDiscardChangesDialog(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            TextButton(
              onPressed: _isSaving ? null : _submit,
              child: const Text('保存'),
            ),
          ],
        ),
        body: Consumer2<EventProvider, TagProvider>(
          builder: (context, provider, tagProvider, _) {
          final loadingInitialData =
              (provider.loading && !provider.initialized) ||
              (tagProvider.loading && !tagProvider.initialized);
          if (loadingInitialData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && !provider.initialized) {
            return ErrorState(
              message: provider.error!.message,
              onRetry: _loadInitialData,
            );
          }

          if (tagProvider.error != null && !tagProvider.initialized) {
            return ErrorState(
              message: tagProvider.error!.message,
              onRetry: _loadInitialData,
            );
          }

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppDimensions.formMaxWidth),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        EventFormBasicSection(
                          titleController: _titleController,
                          locationController: _locationController,
                          descriptionController: _descriptionController,
                          selectedEventTypeId: _selectedEventTypeId,
                          onEventTypeChanged: (value) {
                            setState(() {
                              _selectedEventTypeId = value;
                            });
                          },
                          selectedCreatedByContactId: _selectedCreatedByContactId,
                          onCreatedByContactChanged: (value) {
                            setState(() {
                              _selectedCreatedByContactId = value;
                            });
                          },
                          eventTypes: provider.eventTypes,
                          contacts: provider.availableContacts,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        EventFormScheduleSection(
                          startAt: _startAt,
                          endAt: _endAt,
                          onStartChanged: (value) {
                            setState(() {
                              _startAt = value;
                            });
                          },
                          onEndChanged: (value) {
                            setState(() {
                              _endAt = value;
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        EventFormParticipantsSection(
                          contacts: provider.availableContacts,
                          tags: tagProvider.tags,
                          selectedParticipantRoles: _selectedParticipantRoles,
                          onParticipantToggled: _toggleParticipant,
                          onParticipantRoleChanged: _changeParticipantRole,
                          errorText: _participantErrorText,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        FilledButton(
                          key: const Key('eventForm_submitButton'),
                          onPressed: _isSaving ? null : _submit,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(widget.isEditing ? '保存修改' : '创建事件'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        ),
      ),
    );
  }

  Future<void> _loadInitialData() async {
    await context.read<EventProvider>().loadFormOptions();
    if (!mounted) {
      return;
    }

    final tagProvider = context.read<TagProvider>();
    if (!tagProvider.initialized && !tagProvider.loading) {
      await tagProvider.loadTags();
    }
  }

  void _toggleParticipant(String contactId) {
    setState(() {
      if (_selectedParticipantRoles.containsKey(contactId)) {
        _selectedParticipantRoles.remove(contactId);
      } else {
        _selectedParticipantRoles[contactId] = EventParticipantRoles.participant;
      }
      if (_selectedParticipantRoles.isNotEmpty) {
        _participantErrorText = null;
      }
    });
  }

  void _changeParticipantRole(String contactId, String role) {
    setState(() {
      if (_selectedParticipantRoles.containsKey(contactId)) {
        _selectedParticipantRoles[contactId] = EventParticipantRoles.normalize(role);
      }
    });
  }

  void _submit() {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedParticipantRoles.isEmpty) {
      setState(() {
        _participantErrorText = '请至少选择一个参与人';
      });
      return;
    }

    if (_startAt != null && _endAt != null && _endAt!.isBefore(_startAt!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('结束时间不能早于开始时间')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _allowPop = true;
    });
    Navigator.of(context).pop(
      EventDraft(
        title: _titleController.text.trim(),
        eventTypeId: _selectedEventTypeId,
        startAt: _startAt,
        endAt: _endAt,
        location: _normalize(_locationController.text),
        description: _normalize(_descriptionController.text),
        reminderEnabled: widget.initialEvent?.reminderEnabled ?? false,
        reminderAt: widget.initialEvent?.reminderAt,
        createdByContactId: _selectedCreatedByContactId,
        participantIds: _selectedParticipantRoles.keys.toList(),
        participantRoles: _selectedParticipantRoles,
      ),
    );
  }

  String? _normalize(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  bool get _hasUnsavedChanges {
    final initialEvent = widget.initialEvent;
    if (_titleController.text.trim() != (initialEvent?.title ?? '')) {
      return true;
    }
    if (_normalize(_locationController.text) != initialEvent?.location) {
      return true;
    }
    if (_normalize(_descriptionController.text) != initialEvent?.description) {
      return true;
    }
    if (_selectedEventTypeId != initialEvent?.eventTypeId) {
      return true;
    }
    if (_selectedCreatedByContactId != (initialEvent?.createdByContactId ?? widget.suggestedContactId)) {
      return true;
    }
    if (_startAt != initialEvent?.startAt) {
      return true;
    }
    if (_endAt != initialEvent?.endAt) {
      return true;
    }

    final initialParticipantRoles = {
      ...widget.initialParticipantRoles.map(
        (contactId, role) => MapEntry(contactId, EventParticipantRoles.normalize(role)),
      ),
      if (widget.initialParticipantRoles.isEmpty && widget.suggestedContactId != null)
        widget.suggestedContactId!: EventParticipantRoles.participant,
    };
    return !mapEquals(_selectedParticipantRoles, initialParticipantRoles);
  }
}