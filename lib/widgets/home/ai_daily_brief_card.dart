import 'package:flutter/material.dart';

import '../../models/home_daily_brief.dart';
import 'home_daily_brief_hero.dart';

typedef HomeDailyBriefActionHandler = void Function(
  HomeDailyBriefActionType action,
  String? targetId,
);

class AiDailyBriefCard extends StatelessWidget {
  final HomeDailyBrief? brief;
  final bool loading;
  final bool refreshing;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final HomeDailyBriefActionHandler? onActionTap;

  const AiDailyBriefCard({
    super.key,
    required this.brief,
    this.loading = false,
    this.refreshing = false,
    this.errorMessage,
    this.onRetry,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return HomeDailyBriefHero(
      brief: brief,
      loading: loading,
      refreshing: refreshing,
      errorMessage: errorMessage,
      onRetry: onRetry,
      onActionTap: onActionTap,
    );
  }
}