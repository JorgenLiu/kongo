import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Route<T> buildAdaptiveDetailRoute<T>(Widget child) {
  if (defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => child,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }

  return MaterialPageRoute<T>(builder: (_) => child);
}