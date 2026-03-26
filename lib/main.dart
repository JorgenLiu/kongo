import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'ai/ai_service.dart';
import 'config/app_theme.dart';
import 'providers/calendar_time_node_settings_provider.dart';
import 'providers/theme_notifier.dart';
import 'screens/app_shell_screen.dart';
import 'services/app_dependencies.dart';
import 'services/contact_milestone_service.dart';
import 'services/contact_service.dart';
import 'services/event_service.dart';
import 'services/read/contact_read_service.dart';
import 'services/read/event_read_service.dart';
import 'services/read/home_read_service.dart';
import 'services/read/summary_read_service.dart';
import 'services/read/todo_read_service.dart';
import 'services/summary_service.dart';
import 'widgets/common/window_theme_sync.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dependencies = await AppDependencies.bootstrap();
  runApp(MyApp(dependencies: dependencies));
}

class MyApp extends StatelessWidget {
  final AppDependencies dependencies;

  const MyApp({
    super.key,
    required this.dependencies,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeNotifier(dependencies.settingsPreferencesStore),
        ),
        ChangeNotifierProvider(
          create: (_) => CalendarTimeNodeSettingsProvider(
            dependencies.calendarTimeNodeSettingsService,
          ),
        ),
        ChangeNotifierProvider.value(value: dependencies.attachmentProvider),
        ChangeNotifierProvider.value(value: dependencies.contactProvider),
        ChangeNotifierProvider.value(value: dependencies.eventProvider),
        ChangeNotifierProvider.value(value: dependencies.summaryProvider),
        ChangeNotifierProvider.value(value: dependencies.tagProvider),
        ChangeNotifierProvider.value(value: dependencies.todoBoardProvider),
        Provider<ContactService>.value(value: dependencies.contactService),
        Provider<EventService>.value(value: dependencies.eventService),
        Provider<SummaryService>.value(value: dependencies.summaryService),
        Provider<ContactMilestoneService>.value(value: dependencies.contactMilestoneService),
        Provider<ContactReadService>.value(value: dependencies.contactReadService),
        Provider<EventReadService>.value(value: dependencies.eventReadService),
        Provider<HomeReadService>.value(value: dependencies.homeReadService),
        Provider<SummaryReadService>.value(value: dependencies.summaryReadService),
        Provider<TodoReadService>.value(value: dependencies.todoReadService),
        Provider<AiService>.value(value: dependencies.aiService),
      ],
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, _) {
          return MaterialApp(
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
}

