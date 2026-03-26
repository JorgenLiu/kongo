import 'package:flutter/material.dart';

class VisualStrikethroughText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow overflow;

  const VisualStrikethroughText({
    super.key,
    required this.text,
    this.style,
    this.maxLines,
    this.overflow = TextOverflow.clip,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedStyle = DefaultTextStyle.of(context).style.merge(style);

    return CustomPaint(
      foregroundPainter: _VisualStrikethroughPainter(
        text: text,
        style: resolvedStyle,
        textDirection: Directionality.of(context),
        maxLines: maxLines,
        overflow: overflow,
        color: resolvedStyle.color ?? Theme.of(context).colorScheme.outline,
      ),
      child: Text(
        text,
        maxLines: maxLines,
        overflow: overflow,
        style: resolvedStyle,
      ),
    );
  }
}

class _VisualStrikethroughPainter extends CustomPainter {
  final String text;
  final TextStyle style;
  final TextDirection textDirection;
  final int? maxLines;
  final TextOverflow overflow;
  final Color color;

  const _VisualStrikethroughPainter({
    required this.text,
    required this.style,
    required this.textDirection,
    required this.maxLines,
    required this.overflow,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (text.isEmpty || size.width <= 0 || size.height <= 0) {
      return;
    }

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection,
      maxLines: maxLines,
      ellipsis: overflow == TextOverflow.ellipsis ? '...' : null,
    )..layout(maxWidth: size.width);

    final metrics = textPainter.computeLineMetrics();
    if (metrics.isEmpty) {
      return;
    }

    final strokeWidth = ((style.fontSize ?? 14) * 0.055).clamp(1.0, 2.2);
    final paint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final metric in metrics) {
      final lineY = metric.baseline - (metric.ascent * 0.36);
      final start = Offset(metric.left, lineY);
      final end = Offset(metric.left + metric.width, lineY);
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _VisualStrikethroughPainter oldDelegate) {
    return text != oldDelegate.text ||
        style != oldDelegate.style ||
        textDirection != oldDelegate.textDirection ||
        maxLines != oldDelegate.maxLines ||
        overflow != oldDelegate.overflow ||
        color != oldDelegate.color;
  }
}