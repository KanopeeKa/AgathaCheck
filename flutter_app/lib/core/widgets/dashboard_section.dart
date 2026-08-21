import 'package:flutter/material.dart';

/// Reusable dashboard section shell (experience-program Phase 0.4).
///
/// Pure presentation — no domain logic. Phase 2/3 compose preview content via
/// [previewBuilder] and optional [endLink].
///
/// Uses a top border accent (category theme) instead of a filled card surface.
class DashboardSection extends StatelessWidget {
  const DashboardSection({
    super.key,
    required this.title,
    this.headerAction,
    required this.previewBuilder,
    this.endLink,
    this.accentColor,
  });

  final String title;
  final Widget? headerAction;
  final Widget Function(BuildContext context) previewBuilder;
  final DashboardSectionLink? endLink;

  /// Top border colour; defaults to [ColorScheme.primary].
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = accentColor ?? theme.colorScheme.primary;

    return Semantics(
      container: true,
      label: title,
      explicitChildNodes: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: borderColor, width: 2)),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final titleWidget = ExcludeSemantics(
                      child: Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                    if (headerAction == null) return titleWidget;

                    if (constraints.maxWidth < 440) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          titleWidget,
                          const SizedBox(height: 4),
                          headerAction!,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: titleWidget),
                        headerAction!,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                previewBuilder(context),
                if (endLink != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: endLink!.onPressed,
                      child: Text(endLink!.label),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardSectionLink {
  const DashboardSectionLink({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;
}
