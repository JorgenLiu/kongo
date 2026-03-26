import 'package:flutter/material.dart';

import '../../config/page_transitions.dart';
import '../tags/tag_management_screen.dart';

Future<void> openTagManagementFromSettings(BuildContext context) async {
  await Navigator.of(context).push<void>(
    SlidePageRoute(
      builder: (_) => const TagManagementScreen(),
    ),
  );
}