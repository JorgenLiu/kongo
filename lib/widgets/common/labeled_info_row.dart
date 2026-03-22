import 'package:flutter/material.dart';

import '../../config/app_constants.dart';

class LabeledInfoRow extends StatelessWidget {
  final String label;
  final String? value;
  final bool multiline;
  final double labelWidth;

  const LabeledInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.multiline = false,
    this.labelWidth = 72,
  });

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: TextStyle(
                color: colorScheme.outline,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value!)),
        ],
      ),
    );
  }
}