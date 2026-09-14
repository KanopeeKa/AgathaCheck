import 'package:flutter/material.dart';

import 'care_surface_tokens.dart';

/// One row or header inside a [CareCollectionInsetList].
class CareCollectionInsetItem {
  const CareCollectionInsetItem({
    required this.child,
    this.showDividerBefore = false,
  });

  final Widget child;

  /// When true, inserts a collection hairline divider immediately before [child].
  final bool showDividerBefore;
}

/// Collection role — soft plum-neutral group with inset rows and white dividers.
class CareCollectionInsetList extends StatelessWidget {
  const CareCollectionInsetList({
    super.key,
    required this.children,
    this.semanticLabel,
  });

  final List<CareCollectionInsetItem> children;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    final columnChildren = <Widget>[];
    for (final item in children) {
      if (item.showDividerBefore) {
        columnChildren.add(
          Divider(
            height: 1,
            thickness: 1,
            color: CareSurfaceTokens.collectionDivider(),
          ),
        );
      }
      columnChildren.add(item.child);
    }

    return Semantics(
      container: semanticLabel != null,
      label: semanticLabel,
      child: Material(
        key: const Key('pet_care_collection_inset_list'),
        color: CareSurfaceTokens.collectionBackground(),
        borderRadius: BorderRadius.circular(CareSurfaceTokens.collectionRadius),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: columnChildren,
        ),
      ),
    );
  }
}
