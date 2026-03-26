import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/platform_window_chrome_service.dart';

class WindowThemeSync extends StatefulWidget {
  final Widget child;
  final PlatformWindowChromeService _chromeService;

  const WindowThemeSync({
    super.key,
    required this.child,
    PlatformWindowChromeService chromeService =
        const DefaultPlatformWindowChromeService(),
  }) : _chromeService = chromeService;

  @override
  State<WindowThemeSync> createState() => _WindowThemeSyncState();
}

class _WindowThemeSyncState extends State<WindowThemeSync> {
  int? _lastBackgroundColor;
  Brightness? _lastBrightness;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleSync();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  void _scheduleSync() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _syncWindowChrome(Theme.of(context));
    });
  }

  Future<void> _syncWindowChrome(ThemeData theme) async {
    final backgroundColor = theme.scaffoldBackgroundColor.toARGB32();
    final brightness = theme.brightness;
    if (_lastBackgroundColor == backgroundColor && _lastBrightness == brightness) {
      return;
    }

    _lastBackgroundColor = backgroundColor;
    _lastBrightness = brightness;

    await widget._chromeService.updateWindowChrome(
      title: 'Kongo',
      backgroundColor: backgroundColor,
      dark: brightness == Brightness.dark,
    );
  }
}