import '../providers/contact_provider.dart';
import '../providers/files_provider.dart';
import '../providers/attachment_provider.dart';
import '../providers/event_provider.dart';
import '../providers/summary_provider.dart';
import '../providers/tag_provider.dart';
import '../repositories/attachment_repository.dart';
import '../repositories/contact_repository.dart';
import '../repositories/event_repository.dart';
import '../repositories/summary_repository.dart';
import '../repositories/tag_repository.dart';
import 'attachment_service.dart';
import 'contact_service.dart';
import 'database_service.dart';
import 'event_service.dart';
import 'read/contact_read_service.dart';
import 'read/event_read_service.dart';
import 'summary_service.dart';
import 'tag_service.dart';

class AppDependencies {
  final DatabaseService databaseService;
  final AttachmentProvider attachmentProvider;
  final ContactProvider contactProvider;
  final FilesProvider filesProvider;
  final EventProvider eventProvider;
  final SummaryProvider summaryProvider;
  final TagProvider tagProvider;
  final ContactService contactService;
  final TagService tagService;
  final EventService eventService;
  final SummaryService summaryService;
  final AttachmentService attachmentService;
  final ContactReadService contactReadService;
  final EventReadService eventReadService;

  AppDependencies._({
    required this.databaseService,
    required this.attachmentProvider,
    required this.contactProvider,
    required this.filesProvider,
    required this.eventProvider,
    required this.summaryProvider,
    required this.tagProvider,
    required this.contactService,
    required this.tagService,
    required this.eventService,
    required this.summaryService,
    required this.attachmentService,
    required this.contactReadService,
    required this.eventReadService,
  });

  static Future<AppDependencies> bootstrap({
    DatabaseService? databaseService,
    bool preloadContacts = true,
  }) async {
    final resolvedDatabaseService = databaseService ?? DatabaseService();
    await resolvedDatabaseService.initDatabase();

    final contactRepository = SqliteContactRepository(resolvedDatabaseService);
    final tagRepository = SqliteTagRepository(resolvedDatabaseService);
    final eventRepository = SqliteEventRepository(resolvedDatabaseService);
    final summaryRepository = SqliteSummaryRepository(resolvedDatabaseService);
    final attachmentRepository = SqliteAttachmentRepository(resolvedDatabaseService);

    final summaryService = DefaultSummaryService(
      summaryRepository,
      attachmentRepository,
    );
    final attachmentService = DefaultAttachmentService(
      attachmentRepository,
      eventRepository,
      summaryRepository,
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
    final contactReadService = DefaultContactReadService(
      contactRepository,
      tagRepository,
      eventRepository,
      attachmentRepository,
    );
    final eventReadService = DefaultEventReadService(
      contactRepository,
      eventRepository,
      attachmentRepository,
    );

    final contactProvider = ContactProvider(contactService);
    final attachmentProvider = AttachmentProvider(attachmentService);
  final filesProvider = FilesProvider(attachmentService);
    final eventProvider = EventProvider(eventService, contactService);
    final summaryProvider = SummaryProvider(summaryService);
    final tagProvider = TagProvider(tagService);
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
      contactService: contactService,
      tagService: tagService,
      eventService: eventService,
      summaryService: summaryService,
      attachmentService: attachmentService,
      contactReadService: contactReadService,
      eventReadService: eventReadService,
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