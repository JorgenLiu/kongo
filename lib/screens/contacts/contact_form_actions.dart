import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/page_transitions.dart';
import '../../providers/tag_provider.dart';
import '../tags/tag_management_screen.dart';

Future<Set<String>?> openTagManagementFromContactForm(BuildContext context) async {
  await Navigator.of(context).push<void>(
    SlidePageRoute(
      builder: (_) => const TagManagementScreen(),
    ),
  );

  if (!context.mounted) {
    return null;
  }

  final tagProvider = context.read<TagProvider>();
  await tagProvider.loadTags();
  if (!context.mounted) {
    return null;
  }

  return tagProvider.tags.map((tag) => tag.id).toSet();
}