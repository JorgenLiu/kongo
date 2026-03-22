import 'package:flutter/material.dart';

class HighlightedSearchText extends StatelessWidget {
  final String text;
  final String? query;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const HighlightedSearchText({
    super.key,
    required this.text,
    this.query,
    this.style,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = query?.trim();
    if (normalizedQuery == null || normalizedQuery.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final sourceLower = text.toLowerCase();
    final queryLower = normalizedQuery.toLowerCase();
    final spans = <TextSpan>[];
    final highlightStyle = (style ?? DefaultTextStyle.of(context).style).copyWith(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      color: Theme.of(context).colorScheme.onPrimaryContainer,
      fontWeight: FontWeight.w700,
    );

    var start = 0;
    while (start < text.length) {
      final index = sourceLower.indexOf(queryLower, start);
      if (index < 0) {
        spans.add(TextSpan(text: text.substring(start), style: style));
        break;
      }

      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index), style: style));
      }

      final end = index + queryLower.length;
      spans.add(TextSpan(text: text.substring(index, end), style: highlightStyle));
      start = end;
    }

    return RichText(
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      text: TextSpan(style: style ?? DefaultTextStyle.of(context).style, children: spans),
    );
  }
}