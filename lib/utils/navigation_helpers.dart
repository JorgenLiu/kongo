import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/page_transitions.dart';

Route<T> buildAdaptiveDetailRoute<T>(Widget child) {
  if (defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux) {
    return SlidePageRoute<T>(builder: (_) => child);
  }

  return MaterialPageRoute<T>(builder: (_) => child);
}