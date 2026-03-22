import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WindowThemeSync extends StatefulWidget {
  final Widget child;

  const WindowThemeSync({
    super.key,
    required this.child,
  });

  @override
  State<WindowThemeSync> createState() => _WindowThemeSyncState();
}

class _WindowThemeSyncState extends State<WindowThemeSync> {
  static const MethodChannel _channel = MethodChannel('kongo/window_chrome');

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

    try {
      await _channel.invokeMethod<void>('updateWindowChrome', {
        'title': 'Kongo',
        'backgroundColor': backgroundColor,
        'dark': brightness == Brightness.dark,
      });
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }
}