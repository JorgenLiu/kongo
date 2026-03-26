import 'dart:io';

import '../ai/ai_provider.dart';
import '../ai/ai_service.dart';
import '../providers/contact_provider.dart';
import '../providers/files_provider.dart';
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
import '../repositories/event_repository.dart';
import '../repositories/summary_repository.dart';
import '../repositories/tag_repository.dart';
import 'attachment_preview_service.dart';
import 'attachment_service.dart';
import 'calendar_time_node_settings_service.dart';
import 'contact_milestone_service.dart';
import 'contact_service.dart';
import 'database_service.dart';
import 'event_service.dart';
import 'read/contact_read_service.dart';
import 'read/event_read_service.dart';
import 'read/home_read_service.dart';
import 'read/summary_read_service.dart';
import 'read/todo_read_service.dart';
import 'settings_preferences_store.dart';
import 'summary_service.dart';
import 'tag_service.dart';
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
  final SettingsPreferencesStore settingsPreferencesStore;
  final CalendarTimeNodeSettingsService calendarTimeNodeSettingsService;
  final TodoService todoService;
  final ContactReadService contactReadService;
  final EventReadService eventReadService;
  final HomeReadService homeReadService;
  final SummaryReadService summaryReadService;
  final TodoReadService todoReadService;
  final AiService aiService;

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
    required this.settingsPreferencesStore,
    required this.calendarTimeNodeSettingsService,
    required this.todoService,
    required this.contactReadService,
    required this.eventReadService,
    required this.homeReadService,
    required this.summaryReadService,
    required this.todoReadService,
    required this.aiService,
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
    final eventService = DefaultEventService(
      eventRepository,
      contactRepository,
      attachmentRepository,
    );
    final tagService = DefaultTagService(tagRepository, contactRepository);
    final contactService = DefaultContactService(
      contactRepository,
      tagRepository,
      eventRepository,
    );
    final contactMilestoneService = DefaultContactMilestoneService(
      milestoneRepository,
      contactRepository,
    );
    final settingsPreferencesStore = JsonSettingsPreferencesStore(
      settingsDirectoryResolver: settingsDirectoryResolver,
      legacyPreferenceRepository: appPreferenceRepository,
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
    final homeReadService = DefaultHomeReadService(
      eventReadService,
      contactRepository,
      contactMilestoneService,
      summaryService,
    );
    final aiService = DefaultAiService(
      provider: aiProvider,
      aiJobRepository: aiJobRepository,
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
    if (preloadContacts) {
      await contactProvider.loadContacts();
    }

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
      settingsPreferencesStore: settingsPreferencesStore,
      calendarTimeNodeSettingsService: calendarTimeNodeSettingsService,
      todoService: todoService,
      contactReadService: contactReadService,
      eventReadService: eventReadService,
      homeReadService: homeReadService,
      summaryReadService: summaryReadService,
      todoReadService: todoReadService,
      aiService: aiService,
    );
  }

  Future<void> dispose({bool deleteDatabase = false}) async {
    if (deleteDatabase) {
      await databaseService.deleteDatabaseFile();
      return;
    }

    await databaseService.closeDatabase();
  }
}