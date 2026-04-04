import 'dart:async';
import 'dart:io';

import '../ai/ai_provider.dart';
import '../ai/ai_service.dart';
import '../ai/openai_compatible_provider.dart';
import '../config/ai_config_store.dart';
import '../providers/contact_provider.dart';
import '../providers/files_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/attachment_provider.dart';
import '../providers/todo_board_provider.dart';
import '../repositories/app_preference_repository.dart';
import '../providers/event_provider.dart';
import '../providers/summary_provider.dart';
import '../providers/tag_provider.dart';
import '../repositories/todo_group_repository.dart';
import '../repositories/todo_item_repository.dart';
import '../repositories/ai_job_repository.dart';
import '../repositories/attachment_repository.dart';
import '../repositories/contact_milestone_repository.dart';
import '../repositories/contact_repository.dart';
import '../repositories/daily_brief_delivery_repository.dart';
import '../repositories/event_repository.dart';
import '../repositories/summary_repository.dart';
import '../repositories/tag_repository.dart';
import '../repositories/info_tag_repository.dart';
import 'attachment_preview_service.dart';
import 'ai_secret_store.dart';
import 'attachment_service.dart';
import 'calendar_time_node_settings_service.dart';
import 'contact_milestone_service.dart';
import 'contact_service.dart';
import 'database_service.dart';
import 'daily_brief_delivery_service.dart';
import 'event_service.dart';
import 'home_daily_brief_service.dart';
import 'quick_capture_service.dart';
import 'quick_note_enrichment_service.dart';
import 'read/contact_read_service.dart';
import 'read/event_read_service.dart';
import 'read/home_read_service.dart';
import 'read/notes_read_service.dart';
import 'read/summary_read_service.dart';
import 'read/todo_read_service.dart';
import '../repositories/quick_note_repository.dart';
import 'reminder_platform_gateway.dart';
import 'reminder_interaction_service.dart';
import 'reminder_service.dart';
import 'settings_preferences_store.dart';
import 'summary_service.dart';
import 'tag_service.dart';
import 'info_tag_service.dart';
import 'todo_service.dart';

class AppDependencies {
  final DatabaseService databaseService;
  final AttachmentProvider attachmentProvider;
  final ContactProvider contactProvider;
  final FilesProvider filesProvider;
  final EventProvider eventProvider;
  final SummaryProvider summaryProvider;
  final TagProvider tagProvider;
  final TodoBoardProvider todoBoardProvider;
  final ContactService contactService;
  final TagService tagService;
  final EventService eventService;
  final SummaryService summaryService;
  final AttachmentService attachmentService;
  final ContactMilestoneService contactMilestoneService;
  final ReminderService reminderService;
  final ReminderInteractionService reminderInteractionService;
  final SettingsPreferencesStore settingsPreferencesStore;
  final AiSecretStore aiSecretStore;
  final AiConfigStore aiConfigStore;
  final CalendarTimeNodeSettingsService calendarTimeNodeSettingsService;
  final TodoService todoService;
  final ContactReadService contactReadService;
  final EventReadService eventReadService;
  final HomeReadService homeReadService;
  final HomeDailyBriefService homeDailyBriefService;
  final DailyBriefDeliveryService dailyBriefDeliveryService;
  final SummaryReadService summaryReadService;
  final TodoReadService todoReadService;
  final AiService aiService;
  final QuickCaptureService quickCaptureService;
  final QuickNoteEnrichmentService quickNoteEnrichmentService;
  final NotesReadService notesReadService;
  final NotesProvider notesProvider;
  final QuickNoteRepository quickNoteRepository;
  final InfoTagRepository infoTagRepository;
  final InfoTagService infoTagService;

  AppDependencies._({
    required this.databaseService,
    required this.attachmentProvider,
    required this.contactProvider,
    required this.filesProvider,
    required this.eventProvider,
    required this.summaryProvider,
    required this.tagProvider,
    required this.todoBoardProvider,
    required this.contactService,
    required this.tagService,
    required this.eventService,
    required this.summaryService,
    required this.attachmentService,
    required this.contactMilestoneService,
    required this.reminderService,
    required this.reminderInteractionService,
    required this.settingsPreferencesStore,
    required this.aiSecretStore,
    required this.aiConfigStore,
    required this.calendarTimeNodeSettingsService,
    required this.todoService,
    required this.contactReadService,
    required this.eventReadService,
    required this.homeReadService,
    required this.homeDailyBriefService,
    required this.dailyBriefDeliveryService,
    required this.summaryReadService,
    required this.todoReadService,
    required this.aiService,
    required this.quickCaptureService,
    required this.quickNoteEnrichmentService,
    required this.notesReadService,
    required this.notesProvider,
    required this.quickNoteRepository,
    required this.infoTagRepository,
    required this.infoTagService,
  });

  static Future<AppDependencies> bootstrap({
    DatabaseService? databaseService,
    bool preloadContacts = true,
    bool enableFilesPreviewWarmup = true,
    Future<Directory> Function()? attachmentsDirectoryResolver,
    Future<Directory> Function()? attachmentPreviewsDirectoryResolver,
    Future<Directory> Function()? settingsDirectoryResolver,
    AttachmentPreviewGenerator? attachmentPreviewGenerator,
    AiProvider? aiProvider,
    AiSecretStore? aiSecretStore,
    ReminderPlatformGateway? reminderPlatformGateway,
    ReminderInteractionService? reminderInteractionService,
  }) async {
    final resolvedDatabaseService = databaseService ?? DatabaseService();
    await resolvedDatabaseService.initDatabase();

    final contactRepository = SqliteContactRepository(resolvedDatabaseService);
    final tagRepository = SqliteTagRepository(resolvedDatabaseService);
    final eventRepository = SqliteEventRepository(resolvedDatabaseService);
    final summaryRepository = SqliteSummaryRepository(resolvedDatabaseService);
    final attachmentRepository = SqliteAttachmentRepository(resolvedDatabaseService);
    final milestoneRepository = SqliteContactMilestoneRepository(resolvedDatabaseService);
    final appPreferenceRepository = SqliteAppPreferenceRepository(resolvedDatabaseService);
    final todoGroupRepository = SqliteTodoGroupRepository(resolvedDatabaseService);
    final todoItemRepository = SqliteTodoItemRepository(resolvedDatabaseService);
    final aiJobRepository = SqliteAiJobRepository(resolvedDatabaseService);

    final summaryService = DefaultSummaryService(
      summaryRepository,
      attachmentRepository,
    );
    final attachmentPreviewService = DefaultAttachmentPreviewService(
      attachmentRepository,
      previewsDirectoryResolver: attachmentPreviewsDirectoryResolver,
      previewGenerator: attachmentPreviewGenerator,
    );
    final attachmentService = DefaultAttachmentService(
      attachmentRepository,
      eventRepository,
      summaryRepository,
      attachmentsDirectoryResolver: attachmentsDirectoryResolver,
      attachmentPreviewService: attachmentPreviewService,
    );
    final settingsPreferencesStore = JsonSettingsPreferencesStore(
      settingsDirectoryResolver: settingsDirectoryResolver,
      legacyPreferenceRepository: appPreferenceRepository,
    );
    final resolvedReminderPlatformGateway = reminderPlatformGateway ??
        (Platform.isMacOS
            ? MethodChannelReminderPlatformGateway()
            : UnsupportedReminderPlatformGateway());
    final resolvedReminderInteractionService = reminderInteractionService ??
      (Platform.isMacOS
        ? MethodChannelReminderInteractionService()
        : UnsupportedReminderInteractionService());
    final resolvedAiSecretStore = aiSecretStore ?? (Platform.isMacOS
        ? MethodChannelAiSecretStore()
      : UnsupportedAiSecretStore());
    final reminderService = DefaultReminderService(
      resolvedReminderPlatformGateway,
      settingsPreferencesStore,
      eventRepository,
      milestoneRepository,
      contactRepository,
    );
    final eventService = DefaultEventService(
      eventRepository,
      contactRepository,
      attachmentRepository,
      reminderService: reminderService,
    );
    final tagService = DefaultTagService(tagRepository, contactRepository);
    final contactService = DefaultContactService(
      contactRepository,
      tagRepository,
      eventRepository,
      contactMilestoneRepository: milestoneRepository,
      reminderService: reminderService,
    );
    final contactMilestoneService = DefaultContactMilestoneService(
      milestoneRepository,
      contactRepository,
      reminderService: reminderService,
    );
    final aiConfigStore = AiConfigStore(
      settingsPreferencesStore,
      secretStore: resolvedAiSecretStore,
    );
    final calendarTimeNodeSettingsService =
        DefaultCalendarTimeNodeSettingsService(settingsPreferencesStore);
    final todoService = DefaultTodoService(
      todoGroupRepository,
      todoItemRepository,
      contactRepository,
      eventRepository,
    );
    final contactReadService = DefaultContactReadService(
      contactRepository,
      tagRepository,
      eventRepository,
      attachmentRepository,
      milestoneRepository,
    );
    final eventReadService = DefaultEventReadService(
      contactRepository,
      eventRepository,
      attachmentRepository,
      contactMilestoneService,
      calendarTimeNodeSettingsService,
    );
    final summaryReadService = DefaultSummaryReadService(
      summaryRepository,
      attachmentRepository,
    );
    final todoReadService = DefaultTodoReadService(
      todoGroupRepository,
      todoItemRepository,
      contactRepository,
      eventRepository,
    );
    final quickNoteRepository = SqliteQuickNoteRepository(resolvedDatabaseService);
    final homeReadService = DefaultHomeReadService(
      eventReadService,
      contactRepository,
      contactMilestoneService,
      todoGroupRepository,
      todoItemRepository,
      quickNoteRepository,
    );
    final resolvedAiProvider = aiProvider ?? await _loadConfiguredAiProvider(aiConfigStore);
    final aiService = DefaultAiService(
      provider: resolvedAiProvider,
      aiJobRepository: aiJobRepository,
    );
    final homeDailyBriefService = DefaultHomeDailyBriefService(aiService);
    final dailyBriefDeliveryRepository = SettingsDailyBriefDeliveryRepository(
      settingsPreferencesStore,
    );
    final dailyBriefDeliveryService = DefaultDailyBriefDeliveryService(
      dailyBriefDeliveryRepository,
    );

    final quickCaptureService = DefaultQuickCaptureService(resolvedDatabaseService, quickNoteRepository);
    final infoTagRepository = SqliteInfoTagRepository(resolvedDatabaseService);
    final infoTagService = DefaultInfoTagService(infoTagRepository);
    final quickNoteEnrichmentService = DefaultQuickNoteEnrichmentService(
      aiService,
      quickNoteRepository,
    );
    final notesReadService = DefaultNotesReadService(
      quickNoteRepository,
      summaryRepository,
      contactRepository: contactRepository,
      eventRepository: eventRepository,
    );

    final contactProvider = ContactProvider(contactService, contactMilestoneService);
    final attachmentProvider = AttachmentProvider(attachmentService);
    final filesProvider = FilesProvider(
      attachmentService,
      enableBackgroundPreviewWarmup: enableFilesPreviewWarmup,
    );
    final eventProvider = EventProvider(eventService, contactService);
    final summaryProvider = SummaryProvider(summaryService);
    final tagProvider = TagProvider(tagService);
    final todoBoardProvider = TodoBoardProvider(todoReadService, todoService);
    final notesProvider = NotesProvider(
      notesReadService,
      captureService: quickCaptureService,
      enrichmentService: quickNoteEnrichmentService,
    );
    if (preloadContacts) {
      await contactProvider.loadContacts();
    }

    unawaited(reminderService.rebuildPendingReminders().catchError((_) {}));

    return AppDependencies._(
      databaseService: resolvedDatabaseService,
      attachmentProvider: attachmentProvider,
      contactProvider: contactProvider,
      filesProvider: filesProvider,
      eventProvider: eventProvider,
      summaryProvider: summaryProvider,
      tagProvider: tagProvider,
      todoBoardProvider: todoBoardProvider,
      contactService: contactService,
      tagService: tagService,
      eventService: eventService,
      summaryService: summaryService,
      attachmentService: attachmentService,
      contactMilestoneService: contactMilestoneService,
      reminderService: reminderService,
      reminderInteractionService: resolvedReminderInteractionService,
      settingsPreferencesStore: settingsPreferencesStore,
      aiSecretStore: resolvedAiSecretStore,
      aiConfigStore: aiConfigStore,
      calendarTimeNodeSettingsService: calendarTimeNodeSettingsService,
      todoService: todoService,
      contactReadService: contactReadService,
      eventReadService: eventReadService,
      homeReadService: homeReadService,
      homeDailyBriefService: homeDailyBriefService,
      dailyBriefDeliveryService: dailyBriefDeliveryService,
      summaryReadService: summaryReadService,
      todoReadService: todoReadService,
      aiService: aiService,
      quickCaptureService: quickCaptureService,
      quickNoteEnrichmentService: quickNoteEnrichmentService,
      notesReadService: notesReadService,
      notesProvider: notesProvider,
      quickNoteRepository: quickNoteRepository,
      infoTagRepository: infoTagRepository,
      infoTagService: infoTagService,
    );
  }

  Future<void> dispose({bool deleteDatabase = false}) async {
    await reminderInteractionService.dispose();

    if (deleteDatabase) {
      await databaseService.deleteDatabaseFile();
      return;
    }

    await databaseService.closeDatabase();
  }
}

Future<AiProvider?> _loadConfiguredAiProvider(AiConfigStore store) async {
  final settings = await store.load();
  final providerConfig = settings.toProviderConfig();
  if (providerConfig == null) {
    return null;
  }

  return OpenAiCompatibleProvider(
    providerId: settings.presetProvider.name,
    config: providerConfig,
  );
}