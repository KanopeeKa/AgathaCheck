import 'package:flutter/material.dart';

import '../theme/app_color_tokens.dart';

/// Bordered white module for profile sections (People around {pet}, etc.).
class SurfaceModule extends StatelessWidget {
  const SurfaceModule({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final String? semanticLabel;

  static const double cornerRadius = 16;

  @override
  Widget build(BuildContext context) {
    final module = Padding(
      padding: margin,
      child: Material(
        color: AppColorTokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cornerRadius),
          side: const BorderSide(color: AppColorTokens.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: padding, child: child),
      ),
    );
    if (semanticLabel == null) return module;
    return Semantics(container: true, label: semanticLabel, child: module);
  }
}
