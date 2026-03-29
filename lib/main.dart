import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'ai/ai_service.dart';
import 'config/ai_config_store.dart';
import 'config/app_theme.dart';
import 'models/contact_draft.dart';
import 'models/event_draft.dart';
import 'models/reminder_interaction.dart';
import 'providers/calendar_time_node_settings_provider.dart';
import 'providers/reminder_settings_provider.dart';
import 'providers/theme_notifier.dart';
import 'screens/app_shell_screen.dart';
import 'screens/contacts/contact_detail_screen.dart';
import 'screens/events/event_detail_screen.dart';
import 'services/app_dependencies.dart';
import 'services/contact_milestone_service.dart';
import 'services/contact_service.dart';
import 'services/daily_brief_delivery_service.dart';
import 'services/event_service.dart';
import 'services/home_daily_brief_service.dart';
import 'services/quick_capture_parser.dart';
import 'services/quick_capture_service.dart';
import 'services/quick_note_enrichment_service.dart';
import 'services/read/contact_read_service.dart';
import 'services/read/event_read_service.dart';
import 'services/read/home_read_service.dart';
import 'services/read/notes_read_service.dart';
import 'services/read/summary_read_service.dart';
import 'services/read/todo_read_service.dart';
import 'services/reminder_service.dart';
import 'services/ai_secret_store.dart';
import 'services/settings_preferences_store.dart';
import 'services/summary_service.dart';
import 'utils/navigation_helpers.dart';
import 'widgets/common/window_theme_sync.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dependencies = await AppDependencies.bootstrap();
  runApp(MyApp(dependencies: dependencies));
}

class MyApp extends StatefulWidget {
  final AppDependencies dependencies;

  const MyApp({
    super.key,
    required this.dependencies,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  StreamSubscription<ReminderInteraction>? _reminderInteractionSubscription;

  @override
  void initState() {
    super.initState();
    _reminderInteractionSubscription = widget
        .dependencies.reminderInteractionService.interactions
        .listen(_handleReminderInteraction);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final interaction = await widget.dependencies.reminderInteractionService
          .consumePendingInteraction();
      if (interaction != null) {
        _handleReminderInteraction(interaction);
      }
    });

    const MethodChannel('kongo/quickCapture').setMethodCallHandler(_handleQuickCapture);

    unawaited(
      widget.dependencies.quickNoteEnrichmentService.enrichPending().catchError((_) {}),
    );
  }

  @override
  void dispose() {
    _reminderInteractionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeNotifier(widget.dependencies.settingsPreferencesStore),
        ),
        ChangeNotifierProvider(
          create: (_) => CalendarTimeNodeSettingsProvider(
            widget.dependencies.calendarTimeNodeSettingsService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ReminderSettingsProvider(widget.dependencies.reminderService),
        ),
        ChangeNotifierProvider.value(value: widget.dependencies.attachmentProvider),
        ChangeNotifierProvider.value(value: widget.dependencies.notesProvider),
        ChangeNotifierProvider.value(value: widget.dependencies.contactProvider),
        ChangeNotifierProvider.value(value: widget.dependencies.eventProvider),
        ChangeNotifierProvider.value(value: widget.dependencies.summaryProvider),
        ChangeNotifierProvider.value(value: widget.dependencies.tagProvider),
        ChangeNotifierProvider.value(value: widget.dependencies.todoBoardProvider),
        Provider<AiConfigStore>.value(value: widget.dependencies.aiConfigStore),
        Provider<AiSecretStore>.value(value: widget.dependencies.aiSecretStore),
        Provider<SettingsPreferencesStore>.value(value: widget.dependencies.settingsPreferencesStore),
        Provider<ContactService>.value(value: widget.dependencies.contactService),
        Provider<EventService>.value(value: widget.dependencies.eventService),
        Provider<ReminderService>.value(value: widget.dependencies.reminderService),
        Provider<SummaryService>.value(value: widget.dependencies.summaryService),
        Provider<ContactMilestoneService>.value(value: widget.dependencies.contactMilestoneService),
        Provider<ContactReadService>.value(value: widget.dependencies.contactReadService),
        Provider<EventReadService>.value(value: widget.dependencies.eventReadService),
        Provider<HomeReadService>.value(value: widget.dependencies.homeReadService),
        Provider<HomeDailyBriefService>.value(value: widget.dependencies.homeDailyBriefService),
        Provider<DailyBriefDeliveryService>.value(
          value: widget.dependencies.dailyBriefDeliveryService,
        ),
        Provider<SummaryReadService>.value(value: widget.dependencies.summaryReadService),
        Provider<TodoReadService>.value(value: widget.dependencies.todoReadService),
        Provider<AiService>.value(value: widget.dependencies.aiService),
        Provider<QuickCaptureService>.value(value: widget.dependencies.quickCaptureService),
        Provider<QuickNoteEnrichmentService>.value(
          value: widget.dependencies.quickNoteEnrichmentService,
        ),
        Provider<NotesReadService>.value(value: widget.dependencies.notesReadService),
      ],
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, _) {
          return MaterialApp(
            navigatorKey: _navigatorKey,
            scaffoldMessengerKey: _scaffoldMessengerKey,
            title: 'Kongo',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeNotifier.mode,
            builder: (context, child) => WindowThemeSync(
              child: child ?? const SizedBox.shrink(),
            ),
            home: const AppShellScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }

  void _handleReminderInteraction(ReminderInteraction interaction) {
    if (interaction.isSnooze) {
      unawaited(_handleReminderSnooze(interaction));
      return;
    }

    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    if (interaction.opensEventDetail) {
      navigator.push(
        buildAdaptiveDetailRoute(
          EventDetailScreen(
            eventId: interaction.targetId,
            preferPostEventFollowUp:
                interaction.targetType == ReminderInteractionTargetType.eventFollowUp,
          ),
        ),
      );
      return;
    }

    if (interaction.targetType == ReminderInteractionTargetType.dailyBrief) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const AppShellScreen()),
        (route) => false,
      );
      return;
    }

    if (interaction.targetType == ReminderInteractionTargetType.contactMilestone &&
        interaction.contactId != null) {
      navigator.push(
        buildAdaptiveDetailRoute(
          ContactDetailScreen(contactId: interaction.contactId!),
        ),
      );
    }
  }

  Future<void> _handleReminderSnooze(ReminderInteraction interaction) async {
    try {
      await widget.dependencies.reminderService.snoozeReminder(interaction);
      _scaffoldMessengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('${interaction.snoozeAction!.label}已设置')),
        );
    } catch (_) {
      _scaffoldMessengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('稍后提醒设置失败，请稍后重试')),
        );
    }
  }

  // ──────────────────── Quick Capture ────────────────────

  Future<dynamic> _handleQuickCapture(MethodCall call) async {
    switch (call.method) {
      case 'parse':
        return _handleParse(call.arguments as String? ?? '');
      case 'save':
        await _handleSave(call.arguments as Map? ?? {});
        return null;
      default:
        return null;
    }
  }

  /// 解析输入文本，返回结构化 JSON 给 Swift 侧渲染确认 UI。
  Future<Map<String, dynamic>> _handleParse(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return {'hasContact': false, 'hasEvent': false};

    final contacts = await widget.dependencies.contactService.getContacts();
    final parser = QuickCaptureParser();
    final result = parser.parse(trimmed, contacts);

    final response = <String, dynamic>{};

    // 联系人信息
    if (result.matchedContact != null) {
      response['hasContact'] = true;
      response['contactType'] = 'matched';
      response['contactName'] = result.matchedContact!.name;
      response['contactId'] = result.matchedContact!.id;
    } else if (result.candidateNewName != null) {
      response['hasContact'] = true;
      response['contactType'] = 'candidate';
      response['contactName'] = result.candidateNewName!;
    } else {
      response['hasContact'] = false;
    }

    // 事件/时间信息
    if (result.detectedDate != null) {
      response['hasEvent'] = true;
      response['eventDate'] = result.detectedDate!.toIso8601String();
      response['eventTitle'] = result.suggestedEventTitle ?? trimmed;

      // 查询同日已有事件
      final existingEvents = await widget.dependencies.eventService
          .getEventsByDate(result.detectedDate!);
      if (existingEvents.isNotEmpty) {
        response['existingEvents'] = existingEvents
            .map((e) => {
                  'id': e.id,
                  'title': e.title,
                  'startAt': e.startAt?.toIso8601String(),
                })
            .toList();
      }
    } else {
      response['hasEvent'] = false;
    }

    return response;
  }

  /// 根据 Swift 侧用户确认结果，执行创建/关联/保存。
  Future<void> _handleSave(Map args) async {
    final text = (args['text'] as String? ?? '').trim();
    if (text.isEmpty) return;

    final contactAction = args['contactAction'] as String? ?? 'skip';
    final eventAction = args['eventAction'] as String? ?? 'skip';

    // ── 联系人处理 ──
    String? linkedContactId;
    if (contactAction == 'link') {
      linkedContactId = args['contactId'] as String?;
    } else if (contactAction == 'create') {
      final name = args['newContactName'] as String?;
      if (name != null && name.trim().isNotEmpty) {
        final newContact =
            await widget.dependencies.contactService.createContact(
          ContactDraft(name: name.trim()),
        );
        linkedContactId = newContact.id;
        unawaited(widget.dependencies.contactProvider.loadContacts());
      }
    }

    // ── 事件处理 ──
    String? linkedEventId;
    if (eventAction == 'link') {
      linkedEventId = args['eventId'] as String?;
    } else if (eventAction == 'create') {
      final title = args['newEventTitle'] as String?;
      final dateStr = args['eventDate'] as String?;
      if (title != null && title.trim().isNotEmpty && dateStr != null) {
        final participantIds = <String>[];
        if (linkedContactId != null) participantIds.add(linkedContactId);
        final newEvent = await widget.dependencies.eventService.createEvent(
          EventDraft(
            title: title.trim(),
            startAt: DateTime.tryParse(dateStr),
            participantIds: participantIds,
            participantRoles: const {},
          ),
        );
        linkedEventId = newEvent.id;
      }
    }

    // ── 保存 note ──
    final noteType = (linkedContactId != null || linkedEventId != null)
        ? 'structured'
        : 'knowledge';
    await widget.dependencies.quickCaptureService.saveNote(
      text,
      linkedContactId: linkedContactId,
      linkedEventId: linkedEventId,
      noteType: noteType,
    );

    unawaited(widget.dependencies.notesProvider.refresh());
  }
}

