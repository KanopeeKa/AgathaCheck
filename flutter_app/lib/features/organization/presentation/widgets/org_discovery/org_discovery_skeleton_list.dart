import 'package:flutter/material.dart';

import '../../utils/org_screen_theme.dart';

/// Placeholder tiles shown while discoverable organisations are loading.
class OrgDiscoverySkeletonList extends StatelessWidget {
  const OrgDiscoverySkeletonList({super.key, this.count = 2});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final placeholder = colorScheme.surfaceContainerHighest;

    return Column(
      key: const Key('org_discovery_skeleton_list'),
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i < count - 1 ? 8 : 0),
            child: Card(
              color: orgListCardColor(),
              elevation: 0,
              shape: orgListCardTheme().shape,
              clipBehavior: Clip.antiAlias,
              margin: EdgeInsets.zero,
              child: SizedBox(
                height: 240,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 2, child: ColoredBox(color: placeholder)),
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: placeholder,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 12,
                              width: 120,
                              decoration: BoxDecoration(
                                color: placeholder,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 10,
                              width: 80,
                              decoration: BoxDecoration(
                                color: placeholder,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
