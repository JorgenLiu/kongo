import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_constants.dart';
import '../../providers/home_provider.dart';
import '../../services/read/home_read_service.dart';
import '../../utils/display_formatters.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/workbench_page_header.dart';
import '../../widgets/home/home_overview_content.dart';
import 'home_overview_actions.dart';

class HomeOverviewScreen extends StatelessWidget {
  const HomeOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          HomeProvider(context.read<HomeReadService>())..load(),
      child: const _HomeOverviewView(),
    );
  }
}

class _HomeOverviewView extends StatelessWidget {
  const _HomeOverviewView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            WorkbenchPageHeader(
              eyebrow: 'WORKBENCH · ${formatCompactDateLabel(DateTime.now())}',
              title: '今日工作台',
              titleKey: const Key('homePageHeaderTitle'),
            ),
            const SizedBox(height: AppSpacing.lg),
            Consumer<HomeProvider>(
              builder: (context, provider, _) {
                final Widget child;

                if (provider.loading && provider.data == null) {
                  child = const Padding(
                    key: ValueKey('home_loading'),
                    padding: EdgeInsets.only(top: AppSpacing.xl),
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else if (provider.error != null && provider.data == null) {
                  child = ErrorState(
                    key: const ValueKey('home_error'),
                    message: provider.error?.message ?? '加载失败',
                    onRetry: provider.load,
                  );
                } else if (provider.data == null) {
                  child = const SizedBox.shrink(key: ValueKey('home_empty'));
                } else {
                  final data = provider.data!;

                  child = HomeOverviewContent(
                    data: data,
                    onCreateContact: () => createContactFromHome(context),
                    onCreateEvent: () => createEventFromHome(context),
                    onCreateTodayEvent: () => createTodayEventFromHome(context),
                    onOpenEvents: () => openEventsFromHome(context),
                    onOpenContacts: () => openContactsFromHome(context),
                    onOpenTodos: () => openTodosFromHome(context),
                    onOpenEventsByDate: (date) => openEventsFromHome(
                      context,
                      initialSelectedDate: date,
                    ),
                    onOpenEventDetail: (id) => openEventDetailFromHome(context, id),
                    onOpenSummaries: () => openSummariesFromHome(context),
                    onOpenContactDetail: (id) => openContactDetailFromHome(context, id),
                  );
                }

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: child,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}