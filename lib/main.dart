import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_theme.dart';
import 'screens/app_shell_screen.dart';
import 'services/app_dependencies.dart';
import 'services/contact_service.dart';
import 'services/event_service.dart';
import 'services/read/contact_read_service.dart';
import 'services/read/event_read_service.dart';
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
        ChangeNotifierProvider.value(value: dependencies.attachmentProvider),
        ChangeNotifierProvider.value(value: dependencies.contactProvider),
        ChangeNotifierProvider.value(value: dependencies.eventProvider),
        ChangeNotifierProvider.value(value: dependencies.summaryProvider),
        ChangeNotifierProvider.value(value: dependencies.tagProvider),
        Provider<ContactService>.value(value: dependencies.contactService),
        Provider<EventService>.value(value: dependencies.eventService),
        Provider<SummaryService>.value(value: dependencies.summaryService),
        Provider<ContactReadService>.value(value: dependencies.contactReadService),
        Provider<EventReadService>.value(value: dependencies.eventReadService),
      ],
      child: MaterialApp(
        title: 'Kongo',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        builder: (context, child) => WindowThemeSync(
          child: child ?? const SizedBox.shrink(),
        ),
        home: const AppShellScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

