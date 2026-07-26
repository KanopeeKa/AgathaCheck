import 'package:flutter/material.dart';

/// Reusable dashboard section shell (experience-program Phase 0.4).
///
/// Pure presentation — no domain logic. Phase 2/3 compose preview content via
/// [previewBuilder] and optional [endLink].
class DashboardSection extends StatelessWidget {
  const DashboardSection({
    super.key,
    required this.title,
    this.headerAction,
    required this.previewBuilder,
    this.endLink,
  });

  final String title;
  final Widget? headerAction;
  final Widget Function(BuildContext context) previewBuilder;
  final DashboardSectionLink? endLink;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (headerAction != null) headerAction!,
                ],
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
    );
  }
}

class DashboardSectionLink {
  const DashboardSectionLink({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;
}
