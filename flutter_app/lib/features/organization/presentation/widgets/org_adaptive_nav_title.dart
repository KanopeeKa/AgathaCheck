import 'package:flutter/material.dart';

/// Organisation nav title (D-v3-NAV-2): [titleMedium] → wrap ≤2 lines → ≥12sp → ellipsis.
class OrgAdaptiveNavTitle extends StatelessWidget {
  const OrgAdaptiveNavTitle({super.key, required this.title});

  static const double minFontSize = 12;

  final String title;

  @override
  Widget build(BuildContext context) {
    final baseStyle =
        Theme.of(context).textTheme.titleMedium ??
        const TextStyle(fontSize: 16);
    final maxFontSize = baseStyle.fontSize ?? 16;

    return LayoutBuilder(
      builder: (context, constraints) {
        final fontSize = _fitFontSize(
          text: title,
          style: baseStyle,
          maxWidth: constraints.maxWidth,
          maxFontSize: maxFontSize,
          minFontSize: minFontSize,
          maxLines: 2,
        );

        return Text(
          title,
          style: baseStyle.copyWith(fontSize: fontSize),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        );
      },
    );
  }

  @visibleForTesting
  static double fitFontSizeForTest({
    required String text,
    required TextStyle style,
    required double maxWidth,
    required double maxFontSize,
    double minFontSize = minFontSize,
    int maxLines = 2,
  }) {
    return _fitFontSize(
      text: text,
      style: style,
      maxWidth: maxWidth,
      maxFontSize: maxFontSize,
      minFontSize: minFontSize,
      maxLines: maxLines,
    );
  }

  static double _fitFontSize({
    required String text,
    required TextStyle style,
    required double maxWidth,
    required double maxFontSize,
    required double minFontSize,
    required int maxLines,
  }) {
    if (maxWidth <= 0 || text.isEmpty) return maxFontSize;

    if (!_exceedsMaxLines(
      text: text,
      style: style,
      maxWidth: maxWidth,
      fontSize: maxFontSize,
      maxLines: maxLines,
    )) {
      return maxFontSize;
    }

    var low = minFontSize;
    var high = maxFontSize;
    var best = minFontSize;

    while (high - low > 0.5) {
      final mid = (low + high) / 2;
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: style.copyWith(fontSize: mid),
        ),
        maxLines: maxLines,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: maxWidth);

      if (painter.didExceedMaxLines) {
        high = mid - 0.5;
      } else {
        best = mid;
        low = mid + 0.5;
      }
    }

    return best.clamp(minFontSize, maxFontSize);
  }

  static bool _exceedsMaxLines({
    required String text,
    required TextStyle style,
    required double maxWidth,
    required double fontSize,
    required int maxLines,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: style.copyWith(fontSize: fontSize),
      ),
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    return painter.didExceedMaxLines;
  }
}
