import 'package:flutter/material.dart';

/// Highlights [query] matches inside [text] (case-insensitive).
class HubHighlightedText extends StatelessWidget {
  const HubHighlightedText({
    super.key,
    required this.text,
    required this.query,
    required this.style,
    this.maxLines,
  });

  final String text;
  final String query;
  final TextStyle? style;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }
    final lowerText = text.toLowerCase();
    final lowerQuery = trimmed.toLowerCase();
    final start = lowerText.indexOf(lowerQuery);
    if (start < 0) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }
    final end = start + trimmed.length;
    final theme = Theme.of(context);
    final highlightStyle = style?.copyWith(
      backgroundColor: theme.colorScheme.primaryContainer.withValues(
        alpha: 0.65,
      ),
      fontWeight: FontWeight.w700,
    );
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          if (start > 0) TextSpan(text: text.substring(0, start)),
          TextSpan(text: text.substring(start, end), style: highlightStyle),
          if (end < text.length) TextSpan(text: text.substring(end)),
        ],
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}
