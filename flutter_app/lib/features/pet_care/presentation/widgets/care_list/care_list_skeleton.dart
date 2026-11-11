import 'package:flutter/material.dart';

import '../care_surface/care_surface_tokens.dart';

/// Placeholder cards while All care primary loads (care-item-evolution §Agenda).
class CareListSkeleton extends StatelessWidget {
  const CareListSkeleton({super.key, this.cardCount = 3});

  final int cardCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.colorScheme.onSurface.withValues(alpha: 0.08);
    return Semantics(
      identifier: 'care_list_skeleton',
      label: 'Loading care',
      child: Padding(
        key: const Key('care_list_skeleton'),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Material(
          color: CareSurfaceTokens.collectionBackground(),
          borderRadius: BorderRadius.circular(
            CareSurfaceTokens.collectionRadius,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: CareSurfaceTokens.collectionHeaderPadding,
                child: _Bone(width: 96, height: 16, color: base),
              ),
              for (var i = 0; i < cardCount; i++) ...[
                Divider(
                  height: 1,
                  thickness: 1,
                  color: CareSurfaceTokens.collectionDivider(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Bone(width: 180, height: 14, color: base),
                      const SizedBox(height: 8),
                      _Bone(width: 240, height: 12, color: base),
                      const SizedBox(height: 8),
                      _Bone(width: 120, height: 12, color: base),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({required this.width, required this.height, required this.color});

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
