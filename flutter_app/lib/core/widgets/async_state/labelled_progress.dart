import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// A progress indicator that always says what is loading (design system § 6.10, review rule X-7).
///
/// [label] names the wait for assistive technology ("Loading away plans"); it defaults to the
/// localized "Loading". Set [centered] to false for an inline indicator inside a row or caption.
class LabelledProgress extends StatelessWidget {
  const LabelledProgress({
    super.key,
    this.label,
    this.centered = true,
    this.size = 36,
  });

  /// Localized description of what is loading. Defaults to `loadingLabel`.
  final String? label;

  /// Centre the indicator in the available space (screen or section loading).
  final bool centered;

  /// Diameter of the indicator in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    final text = label ?? AppLocalizations.of(context)!.loadingLabel;
    final indicator = Semantics(
      label: text,
      liveRegion: true,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: CircularProgressIndicator(strokeWidth: size < 24 ? 2 : 4),
        ),
      ),
    );
    return centered ? Center(child: indicator) : indicator;
  }
}
