import 'package:flutter/material.dart';

/// Responsive presentation shell for the guardian's three dashboard sections.
///
/// It only changes layout and surface hierarchy; data, actions, and section
/// semantics remain owned by the existing Guardian dashboard widgets.
class GuardianOperationsDeskLayout extends StatelessWidget {
  const GuardianOperationsDeskLayout({
    super.key,
    required this.useWideLayout,
    required this.petsSection,
    required this.eventsSection,
    required this.vetsSection,
  });

  /// The viewport breakpoint is evaluated by the parent before page padding.
  static const wideBreakpoint = 900.0;

  final bool useWideLayout;
  final Widget petsSection;
  final Widget eventsSection;
  final Widget vetsSection;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, _) {
        final isWide = useWideLayout;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GuardianDeskSectionCard(emphasized: true, child: petsSection),
                const SizedBox(height: 16),
                if (isWide)
                  Row(
                    key: const Key('guardian_desk_secondary_sections_wide'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: GuardianDeskSectionCard(child: eventsSection),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GuardianDeskSectionCard(child: vetsSection),
                      ),
                    ],
                  )
                else
                  Column(
                    key: const Key('guardian_desk_secondary_sections_narrow'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GuardianDeskSectionCard(child: eventsSection),
                      const SizedBox(height: 16),
                      GuardianDeskSectionCard(child: vetsSection),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class GuardianDeskSectionCard extends StatelessWidget {
  const GuardianDeskSectionCard({
    super.key,
    required this.child,
    this.emphasized = false,
  });

  final Widget child;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: emphasized ? colors.primaryContainer : colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
        child: child,
      ),
    );
  }
}
