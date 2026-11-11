import 'package:flutter/material.dart';

import '../../../../../../l10n/app_localizations.dart';

/// Collapsed-by-default section header for paused or closed care on All care.
class GlobalEventsCollapsibleSection extends StatelessWidget {
  const GlobalEventsCollapsibleSection({
    super.key,
    required this.sectionKey,
    required this.semanticsIdentifier,
    required this.title,
    required this.count,
    required this.expanded,
    required this.onToggle,
    required this.children,
  });

  final Key sectionKey;
  final String semanticsIdentifier;
  final String title;
  final int count;
  final bool expanded;
  final VoidCallback onToggle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    if (count == 0) return const SizedBox.shrink();

    return Column(
      key: sectionKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          button: true,
          expanded: expanded,
          identifier: semanticsIdentifier,
          hint: expanded
              ? l.globalEventsHideSection(title)
              : l.globalEventsShowSection(title),
          child: InkWell(
            key: Key('${semanticsIdentifier}_toggle'),
            onTap: onToggle,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.globalEventsLifecycleSection(title, count),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ExcludeSemantics(
                      child: Icon(
                        expanded ? Icons.expand_less : Icons.expand_more,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (expanded) ...children,
      ],
    );
  }
}
