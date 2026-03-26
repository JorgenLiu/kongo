import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/app_constants.dart';
import 'contacts/contacts_list_screen.dart';
import 'desktop_shell_layout.dart';
import 'home/home_overview_screen.dart';
import 'search/global_search_screen.dart';
import 'settings/settings_overview_screen.dart';
import 'summaries/summary_overview_screen.dart';
import 'todos/todo_board_screen.dart';

class AppShellScreen extends StatefulWidget {
  const AppShellScreen({super.key});

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends State<AppShellScreen> {
  int _selectedIndex = 0;

  void _selectIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_useDesktopShell(context)) {
      return DesktopShellLayout(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectIndex,
        pageBuilder: _buildCurrentPage,
      );
    }

    return Scaffold(
      body: _buildCurrentPage(_selectedIndex),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectIndex,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: '首页'),
          NavigationDestination(icon: Icon(Icons.contacts_outlined), label: '通讯录'),
          NavigationDestination(icon: Icon(Icons.search_outlined), label: '检索'),
          NavigationDestination(icon: Icon(Icons.checklist_rtl_outlined), label: '待办'),
          NavigationDestination(icon: Icon(Icons.summarize_outlined), label: '总结'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: '设置'),
        ],
      ),
    );
  }

  bool _useDesktopShell(BuildContext context) {
    if (kIsWeb) {
      return MediaQuery.sizeOf(context).width >= AppBreakpoints.desktopShell;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return true;
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        return false;
    }
  }

  Widget _buildCurrentPage(int index) {
    switch (index) {
      case 0:
        return const HomeOverviewScreen();
      case 1:
        return const ContactsListScreen();
      case 2:
        return const GlobalSearchScreen();
      case 3:
        return const TodoBoardScreen();
      case 4:
        return const SummaryOverviewScreen();
      case 5:
        return const SettingsOverviewScreen();
      default:
        return const HomeOverviewScreen();
    }
  }
}