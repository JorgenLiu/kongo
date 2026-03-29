import 'package:flutter/widgets.dart';

import '../../config/app_constants.dart';

/// Arranges [primarySections] and [secondarySections] side-by-side when
/// [wide] is true, or stacked vertically otherwise.
///
/// Designed for use inside a [ListView] — the returned list can be spread
/// directly into its `children`.
List<Widget> buildResponsiveDetailSections({
  required bool wide,
  required List<Widget> primarySections,
  required List<Widget> secondarySections,
  int primaryFlex = 3,
  int secondaryFlex = 2,
}) {
  if (wide) {
    return [
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: primaryFlex, child: Column(children: primarySections)),
            const SizedBox(width: AppSpacing.md),
            Expanded(flex: secondaryFlex, child: Column(children: secondarySections)),
          ],
        ),
      ),
    ];
  }
  return [
    ...primarySections,
    const SizedBox(height: AppSpacing.lg),
    ...secondarySections,
  ];
}
