import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../../config/app_constants.dart';
import '../../models/event.dart';
import '../../models/reminder_default_offset.dart';
import '../../providers/event_provider.dart';
import '../../providers/tag_provider.dart';
import '../../services/settings_preferences_store.dart';
import '../../utils/reminder_default_time_resolver.dart';
import '../../utils/unsaved_changes_guard.dart';
import '../../utils/event_participant_roles.dart';
import '../../utils/text_normalize.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/event/event_form_basic_section.dart';
import '../../widgets/event/event_form_participants_section.dart';
import '../../widgets/event/event_form_reminder_section.dart';
import '../../widgets/event/event_form_schedule_section.dart';
import '../../widgets/common/side_sheet_scaffold.dart';
import 'event_form_actions.dart';

class EventFormScreen extends StatefulWidget {
  final Event? initialEvent;
  final Map<String, String> initialParticipantRoles;
  final String? suggestedContactId;
  final String? initialTitle;
  final DateTime? initialStartAt;
  final bool sideSheet;

  const EventFormScreen({
    super.key,
    this.initialEvent,
    this.initialParticipantRoles = const {},
    this.suggestedContactId,
    this.initialTitle,
    this.initialStartAt,
    this.sideSheet = false,
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
  late bool _reminderEnabled;
  DateTime? _reminderAt;
  late bool _initialReminderEnabledBaseline;
  DateTime? _initialReminderAtBaseline;
  ReminderDefaultOffset _eventDefaultOffset = ReminderDefaultOffset.minutes30;
  bool _didLoadReminderDefaults = false;
  bool _didManuallyEditReminder = false;
  String? _participantErrorText;
  bool _isSaving = false;
  bool _allowPop = false;
  bool _cachedHasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    final initialEvent = widget.initialEvent;
    _titleController = TextEditingController(text: initialEvent?.title ?? widget.initialTitle ?? '');
    _locationController = TextEditingController(text: initialEvent?.location ?? '');
    _descriptionController = TextEditingController(text: initialEvent?.description ?? '');
    _titleController.addListener(_onFormChanged);
    _locationController.addListener(_onFormChanged);
    _descriptionController.addListener(_onFormChanged);
    _selectedEventTypeId = initialEvent?.eventTypeId;
    _selectedCreatedByContactId = initialEvent?.createdByContactId ?? widget.suggestedContactId;
    _selectedParticipantRoles = {
      ...widget.initialParticipantRoles.map(
        (contactId, role) => MapEntry(contactId, EventParticipantRoles.normalize(role)),
      ),
      if (widget.initialParticipantRoles.isEmpty && widget.suggestedContactId != null)
        widget.suggestedContactId!: EventParticipantRoles.participant,
    };
    _startAt = initialEvent?.startAt ?? widget.initialStartAt;
    _endAt = initialEvent?.endAt;
    _reminderEnabled = initialEvent?.reminderEnabled ?? false;
    _reminderAt = initialEvent?.reminderAt;
    _initialReminderEnabledBaseline = _reminderEnabled;
    _initialReminderAtBaseline = _reminderAt;

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

    if (widget.sideSheet) {
      return PopScope(
        canPop: _allowPop || !_hasUnsavedChanges,
        child: SideSheetScaffold(
          title: title,
          onClose: _handleClose,
          action: FilledButton.tonal(
            onPressed: _isSaving ? null : _submit,
            child: const Text('保存'),
          ),
          body: _buildFormBody(),
        ),
      );
    }

    return PopScope(
      canPop: _allowPop || !_hasUnsavedChanges,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleClose,
          ),
          title: Text(title),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FilledButton.tonal(
                onPressed: _isSaving ? null : _submit,
                child: const Text('保存'),
              ),
            ),
          ],
        ),
        body: _buildFormBody(),
      ),
    );
  }

  Future<void> _handleClose() async {
    final navigator = Navigator.of(context);
    if (_allowPop || !_hasUnsavedChanges) {
      navigator.pop();
      return;
    }
    final shouldDiscard = await showDiscardChangesDialog(context);
    if (shouldDiscard && context.mounted) {
      navigator.pop();
    }
  }

  Widget _buildFormBody() {
    return Consumer2<EventProvider, TagProvider>(
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
                          _maybeApplyDefaultReminderFromStartChange();
                        });
                      },
                      onEndChanged: (value) {
                        setState(() {
                          _endAt = value;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    EventFormReminderSection(
                      reminderEnabled: _reminderEnabled,
                      reminderAt: _reminderAt,
                      startAt: _startAt,
                      onReminderEnabledChanged: (value) {
                        setState(() {
                          _didManuallyEditReminder = true;
                          _reminderEnabled = value;
                          _reminderAt = value ? (_reminderAt ?? _defaultReminderAt()) : null;
                        });
                      },
                      onReminderAtChanged: (value) {
                        setState(() {
                          _didManuallyEditReminder = true;
                          _reminderAt = value;
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
    );
  }

  Future<void> _loadInitialData() async {
    final eventProvider = context.read<EventProvider>();
    final tagProvider = context.read<TagProvider>();
    final settingsStore = context.read<SettingsPreferencesStore>();

    await eventProvider.loadFormOptions();
    if (!mounted) {
      return;
    }

    if (!tagProvider.initialized && !tagProvider.loading) {
      await tagProvider.loadTags();
    }

    if (!widget.isEditing && !_didLoadReminderDefaults) {
      final settings = await settingsStore.getReminderSettings();
      if (!mounted) {
        return;
      }

      setState(() {
        _eventDefaultOffset = settings.eventDefaultOffset;
        _applyReminderDefaults();
        _didLoadReminderDefaults = true;
      });
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

    final draft = validateAndBuildEventDraft(
      formKey: _formKey,
      scaffoldContext: context,
      titleController: _titleController,
      locationController: _locationController,
      descriptionController: _descriptionController,
      selectedEventTypeId: _selectedEventTypeId,
      selectedCreatedByContactId: _selectedCreatedByContactId,
      selectedParticipantRoles: _selectedParticipantRoles,
      startAt: _startAt,
      endAt: _endAt,
      reminderEnabled: _reminderEnabled,
      reminderAt: _reminderAt,
      initialEvent: widget.initialEvent,
      onParticipantError: (message) {
        setState(() {
          _participantErrorText = message;
        });
      },
    );

    if (draft == null) return;

    setState(() {
      _isSaving = true;
      _allowPop = true;
    });
    Navigator.of(context).pop(draft);
  }

  void _onFormChanged() {
    final current = _hasUnsavedChanges;
    if (current != _cachedHasUnsavedChanges) {
      setState(() {
        _cachedHasUnsavedChanges = current;
      });
    }
  }

  bool get _hasUnsavedChanges {
    final initialEvent = widget.initialEvent;
    if (_titleController.text.trim() != (initialEvent?.title ?? widget.initialTitle ?? '')) {
      return true;
    }
    if (normalizeOptionalText(_locationController.text) != initialEvent?.location) {
      return true;
    }
    if (normalizeOptionalText(_descriptionController.text) != initialEvent?.description) {
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
    if (widget.isEditing) {
      if (_reminderEnabled != (initialEvent?.reminderEnabled ?? false)) {
        return true;
      }
      if (_reminderAt != initialEvent?.reminderAt) {
        return true;
      }
    } else {
      if (_reminderEnabled != _initialReminderEnabledBaseline) {
        return true;
      }
      if (_reminderAt != _initialReminderAtBaseline) {
        return true;
      }
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

  DateTime _defaultReminderAt() {
    return resolveEventReminderAtFromDefaultOffset(
          startAt: _startAt ?? DateTime.now().add(const Duration(hours: 1)),
          offset: ReminderDefaultOffset.minutes30,
        ) ??
        DateTime.now().add(const Duration(minutes: 30));
  }

  void _applyReminderDefaults() {
    _reminderEnabled = _eventDefaultOffset.isEnabled;
    _reminderAt = resolveEventReminderAtFromDefaultOffset(
      startAt: _startAt,
      offset: _eventDefaultOffset,
    );
    _initialReminderEnabledBaseline = _reminderEnabled;
    _initialReminderAtBaseline = _reminderAt;
  }

  void _maybeApplyDefaultReminderFromStartChange() {
    if (widget.isEditing || !_didLoadReminderDefaults || _didManuallyEditReminder) {
      return;
    }

    _reminderEnabled = _eventDefaultOffset.isEnabled;
    _reminderAt = resolveEventReminderAtFromDefaultOffset(
      startAt: _startAt,
      offset: _eventDefaultOffset,
    );
    _initialReminderEnabledBaseline = _reminderEnabled;
    _initialReminderAtBaseline = _reminderAt;
  }
}