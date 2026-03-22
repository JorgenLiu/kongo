import 'package:flutter/material.dart';

import '../tags/tag_management_screen.dart';

Future<void> openTagManagementFromSettings(BuildContext context) async {
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => const TagManagementScreen(),
    ),
  );
}