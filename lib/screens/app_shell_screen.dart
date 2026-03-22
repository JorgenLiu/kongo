import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/app_constants.dart';
import 'contacts/contacts_list_screen.dart';
import 'events/events_list_screen.dart';
import 'search/global_search_screen.dart';
import 'settings/settings_overview_screen.dart';
import 'summaries/summary_overview_screen.dart';

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
    final destinations = const [
      NavigationDestination(icon: Icon(Icons.event_note_outlined), label: '日程'),
      NavigationDestination(icon: Icon(Icons.contacts_outlined), label: '通讯录'),
      NavigationDestination(icon: Icon(Icons.search_outlined), label: '检索'),
      NavigationDestination(icon: Icon(Icons.summarize_outlined), label: '总结'),
      NavigationDestination(icon: Icon(Icons.settings_outlined), label: '设置'),
    ];

    if (_useDesktopShell(context)) {
      return _DesktopShellLayout(
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
        destinations: destinations,
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
        return const EventsListScreen();
      case 1:
        return const ContactsListScreen();
      case 2:
        return const GlobalSearchScreen();
      case 3:
        return const SummaryOverviewScreen();
      case 4:
        return const SettingsOverviewScreen();
      default:
        return const EventsListScreen();
    }
  }
}

class _DesktopShellLayout extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget Function(int index) pageBuilder;

  const _DesktopShellLayout({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.pageBuilder,
  });

  @override
  State<_DesktopShellLayout> createState() => _DesktopShellLayoutState();
}

class _DesktopShellLayoutState extends State<_DesktopShellLayout> {
  late final List<GlobalKey<NavigatorState>> _navigatorKeys;
  late int _activeIndex;
  bool _sidebarCollapsed = false;

  @override
  void initState() {
    super.initState();
    _navigatorKeys = List<GlobalKey<NavigatorState>>.generate(
      5,
      (_) => GlobalKey<NavigatorState>(),
    );
    _activeIndex = widget.selectedIndex;
  }

  @override
  void didUpdateWidget(covariant _DesktopShellLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != _activeIndex) {
      _activeIndex = widget.selectedIndex;
    }
  }

  Route<void> _buildRoute(int index) {
    return MaterialPageRoute<void>(
      builder: (_) => widget.pageBuilder(index),
      settings: RouteSettings(name: 'desktop-shell-$index'),
    );
  }

  Future<bool> _popNavigatorToRoot(GlobalKey<NavigatorState> navigatorKey) async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      return true;
    }

    while (navigator.canPop()) {
      final didPop = await navigator.maybePop();
      if (!didPop) {
        return false;
      }
    }

    return true;
  }

  Future<void> _handleDestinationSelected(int index) async {
    if (index == _activeIndex) {
      final resetCurrent = await _popNavigatorToRoot(_navigatorKeys[index]);
      if (!mounted || !resetCurrent) {
        return;
      }

      setState(() {
        _navigatorKeys[index] = GlobalKey<NavigatorState>();
      });
      return;
    }

    final currentIndex = _activeIndex;
    final currentTabReset = await _popNavigatorToRoot(_navigatorKeys[currentIndex]);
    if (!mounted || !currentTabReset) {
      return;
    }

    setState(() {
      _navigatorKeys[currentIndex] = GlobalKey<NavigatorState>();
      _navigatorKeys[index] = GlobalKey<NavigatorState>();
    });

    widget.onDestinationSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sidebarHorizontalPadding = _sidebarCollapsed ? 0.0 : AppSpacing.md;

    return Scaffold(
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: _sidebarCollapsed
                ? AppDimensions.sidebarCollapsedWidth
                : AppDimensions.sidebarWidth,
            padding: EdgeInsets.fromLTRB(
              sidebarHorizontalPadding,
              AppSpacing.lg,
              sidebarHorizontalPadding,
              AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              border: Border(
                right: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: Column(
              crossAxisAlignment: _sidebarCollapsed
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                if (!_sidebarCollapsed) ...[
                  Text(
                    'Kongo',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '桌面工作台',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ] else
                  Text(
                    'K',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: NavigationRail(
                    selectedIndex: _activeIndex,
                    onDestinationSelected: _handleDestinationSelected,
                    extended: !_sidebarCollapsed,
                    backgroundColor: Colors.transparent,
                    indicatorColor: colorScheme.primaryContainer,
                    minWidth: AppDimensions.sidebarCollapsedWidth,
                    minExtendedWidth: AppDimensions.sidebarNavMinWidth,
                    labelType: NavigationRailLabelType.none,
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.event_note_outlined),
                        label: Text('日程'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.contacts_outlined),
                        label: Text('通讯录'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.search_outlined),
                        label: Text('检索'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.summarize_outlined),
                        label: Text('总结'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.settings_outlined),
                        label: Text('设置'),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
                  icon: Icon(
                    _sidebarCollapsed
                        ? Icons.chevron_right_rounded
                        : Icons.chevron_left_rounded,
                  ),
                  tooltip: _sidebarCollapsed ? '展开侧栏' : '收起侧栏',
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: IndexedStack(
                index: _activeIndex,
                children: List<Widget>.generate(
                  _navigatorKeys.length,
                  (index) => _DesktopShellTabNavigator(
                    navigatorKey: _navigatorKeys[index],
                    rootRoute: _buildRoute(index),
                    active: index == _activeIndex,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopShellTabNavigator extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final Route<void> rootRoute;
  final bool active;

  const _DesktopShellTabNavigator({
    required this.navigatorKey,
    required this.rootRoute,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Offstage(
      offstage: !active,
      child: TickerMode(
        enabled: active,
        child: Navigator(
          key: navigatorKey,
          onGenerateInitialRoutes: (_, __) => [rootRoute],
        ),
      ),
    );
  }
}