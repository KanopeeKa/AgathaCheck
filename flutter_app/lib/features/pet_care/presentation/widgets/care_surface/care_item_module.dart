import 'package:flutter/material.dart';

import 'care_surface_tokens.dart';

/// White bordered module on the care page canvas (Care Item detail sections).
class CareItemModule extends StatelessWidget {
  const CareItemModule({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsets padding;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final module = Material(
      color: CareSurfaceTokens.moduleBackground(),
      borderRadius: BorderRadius.circular(CareSurfaceTokens.collectionRadius),
      child: Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(CareSurfaceTokens.collectionRadius),
          border: Border.all(color: CareSurfaceTokens.moduleBorder()),
        ),
        child: child,
      ),
    );

    if (semanticLabel == null) return module;
    return Semantics(container: true, label: semanticLabel, child: module);
  }
}

/// Page background for Care Item detail scroll areas.
class CareItemDetailCanvas extends StatelessWidget {
  const CareItemDetailCanvas({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: CareSurfaceTokens.collectionBackground(),
      child: child,
    );
  }
}

/// Breakpoint for two-column Care Item layout (spec §Web).
const double kCareItemTwoColumnBreakpoint = 900;
