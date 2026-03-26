import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/app_constants.dart';
import '../utils/unsaved_changes_guard.dart';

/// 桌面端 Shell 布局，包含可折叠侧栏导航和多 Tab Navigator。
class DesktopShellLayout extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget Function(int index) pageBuilder;

  const DesktopShellLayout({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.pageBuilder,
  });

  @override
  State<DesktopShellLayout> createState() => _DesktopShellLayoutState();
}

class _DesktopShellLayoutState extends State<DesktopShellLayout> {
  late final List<GlobalKey<NavigatorState>> _navigatorKeys;
  late final Set<int> _initializedTabs;
  late int _activeIndex;
  bool _sidebarCollapsed = false;

  @override
  void initState() {
    super.initState();
    _navigatorKeys = List<GlobalKey<NavigatorState>>.generate(
      6,
      (_) => GlobalKey<NavigatorState>(),
    );
    _activeIndex = widget.selectedIndex;
    _initializedTabs = <int>{widget.selectedIndex};
  }

  @override
  void didUpdateWidget(covariant DesktopShellLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != _activeIndex) {
      _activeIndex = widget.selectedIndex;
    }
    _initializedTabs.add(widget.selectedIndex);
  }

  Route<void> _buildRoute(int index) {
    return MaterialPageRoute<void>(
      builder: (_) => widget.pageBuilder(index),
      settings: RouteSettings(name: 'desktop-shell-$index'),
    );
  }

  Future<bool> _popNavigatorToRoot(
    GlobalKey<NavigatorState> navigatorKey,
  ) async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      return true;
    }

    while (navigator.canPop()) {
      final didPop = await navigator.maybePop();
      if (!didPop) {
        return false;
      }
      // PopScope(canPop: false) makes maybePop return true without
      // actually popping.  Detect this and ask the user to confirm.
      if (navigator.canPop()) {
        if (!mounted) return false;
        // Route is still there — a PopScope guard blocked the pop.
        final shouldDiscard = await showDiscardChangesDialog(context);
        if (!shouldDiscard || !mounted) {
          return false;
        }
        // Force-pop the guarded route.
        navigator.pop();
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
      return;
    }

    final resetCurrent = await _popNavigatorToRoot(
      _navigatorKeys[_activeIndex],
    );
    if (!mounted || !resetCurrent) {
      return;
    }

    setState(() {
      _navigatorKeys[_activeIndex] = GlobalKey<NavigatorState>();
    });

    widget.onDestinationSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sidebarHorizontalPadding = _sidebarCollapsed ? 0.0 : AppSpacing.md;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.digit1, meta: true): () =>
            _handleDestinationSelected(0),
        const SingleActivator(LogicalKeyboardKey.digit2, meta: true): () =>
            _handleDestinationSelected(1),
        const SingleActivator(LogicalKeyboardKey.digit3, meta: true): () =>
            _handleDestinationSelected(2),
        const SingleActivator(LogicalKeyboardKey.digit4, meta: true): () =>
            _handleDestinationSelected(3),
        const SingleActivator(LogicalKeyboardKey.digit5, meta: true): () =>
            _handleDestinationSelected(4),
        const SingleActivator(LogicalKeyboardKey.digit6, meta: true): () =>
          _handleDestinationSelected(5),
        const SingleActivator(LogicalKeyboardKey.escape): () {
          final nav = _navigatorKeys[_activeIndex].currentState;
          if (nav != null && nav.canPop()) {
            nav.pop();
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
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
                  52.0,
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (!_sidebarCollapsed) ...[
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'K',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        color: colorScheme.onPrimary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'Kongo',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                              ),
                            ],
                          ),
                        ),
                    ] else
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'K',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isExtended = constraints.maxWidth >=
                              AppDimensions.sidebarNavMinWidth;
                          return NavigationRail(
                            selectedIndex: _activeIndex,
                            onDestinationSelected:
                                _handleDestinationSelected,
                            extended: isExtended,
                            backgroundColor: Colors.transparent,
                            indicatorColor:
                                colorScheme.primary.withValues(alpha: 0.22),
                            minWidth:
                                AppDimensions.sidebarCollapsedWidth,
                            minExtendedWidth:
                                AppDimensions.sidebarNavMinWidth,
                            labelType: isExtended
                                ? NavigationRailLabelType.none
                                : NavigationRailLabelType.all,
                        destinations: const [
                          NavigationRailDestination(
                            icon: Icon(Icons.dashboard_outlined),
                            label: Text('首页'),
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
                            icon: Icon(Icons.checklist_rtl_outlined),
                            label: Text('待办'),
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
                      );
                        },
                      ),
                    ),
                    if (!_sidebarCollapsed)
                      Center(
                        child: IconButton(
                          onPressed: () => setState(
                            () => _sidebarCollapsed = !_sidebarCollapsed,
                          ),
                          icon: const Icon(Icons.menu_open_rounded, size: 20),
                          tooltip: '收起侧栏',
                          style: IconButton.styleFrom(
                            foregroundColor: colorScheme.outline,
                          ),
                        ),
                      )
                    else
                      Center(
                        child: IconButton(
                          onPressed: () => setState(
                            () => _sidebarCollapsed = !_sidebarCollapsed,
                          ),
                          icon: const Icon(Icons.menu_rounded, size: 20),
                          tooltip: '展开侧栏',
                          style: IconButton.styleFrom(
                            foregroundColor: colorScheme.outline,
                          ),
                        ),
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
                      (index) => _initializedTabs.contains(index)
                          ? AnimatedOpacity(
                              opacity: index == _activeIndex ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 120),
                              child: _DesktopShellTabNavigator(
                                navigatorKey: _navigatorKeys[index],
                                rootRoute: _buildRoute(index),
                                active: index == _activeIndex,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
