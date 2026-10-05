import 'package:flutter/material.dart';

/// Placeholder row while people lists load.
class PersonSkeleton extends StatelessWidget {
  const PersonSkeleton({super.key, this.count = 3, this.compact = false});

  final int count;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final placeholder = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Column(
      key: const Key('people_person_skeleton'),
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: EdgeInsets.only(bottom: compact ? 4 : 8),
            child: Container(
              height: compact ? 48 : 56,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: compact ? 36 : 40,
                    height: compact ? 36 : 40,
                    decoration: BoxDecoration(
                      color: placeholder,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 12,
                          width: 140,
                          decoration: BoxDecoration(
                            color: placeholder,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        if (!compact) ...[
                          const SizedBox(height: 6),
                          Container(
                            height: 10,
                            width: 100,
                            decoration: BoxDecoration(
                              color: placeholder,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
