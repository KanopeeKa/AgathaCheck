import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_tokens.dart';

/// Responsive presentation shell for the guardian's three dashboard sections.
///
/// It only changes layout and surface hierarchy; data, actions, and section
/// semantics remain owned by the existing Guardian dashboard widgets.
class PetCareOperationsDeskLayout extends StatelessWidget {
  const PetCareOperationsDeskLayout({
    super.key,
    required this.useWideLayout,
    required this.petsSection,
    required this.eventsSection,
    required this.vetsSection,
    this.fosteringSection,
  });

  /// Canonical max width for the guardian dashboard content grid (D-desk-7).
  static const maxContentWidth = 1120.0;

  /// The viewport breakpoint is evaluated by the parent before page padding.
  static const wideBreakpoint = 900.0;

  final bool useWideLayout;
  final Widget petsSection;
  final Widget eventsSection;
  final Widget vetsSection;
  final Widget? fosteringSection;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, _) {
        final isWide = useWideLayout;

        return Center(
          child: ConstrainedBox(
            key: const Key('guardian_operations_desk_content'),
            constraints: const BoxConstraints(maxWidth: maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PetCareDeskSectionCard(
                  key: const Key('guardian_desk_primary_section_card'),
                  showSurface: false,
                  child: petsSection,
                ),
                const SizedBox(height: 28),
                if (isWide)
                  IntrinsicHeight(
                    child: Row(
                      key: const Key('guardian_desk_secondary_sections_wide'),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 3, child: eventsSection),
                        const SizedBox(width: 20),
                        Expanded(flex: 2, child: vetsSection),
                      ],
                    ),
                  )
                else
                  Column(
                    key: const Key('guardian_desk_secondary_sections_narrow'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      eventsSection,
                      const SizedBox(height: 28),
                      vetsSection,
                    ],
                  ),
                if (fosteringSection != null) ...[
                  const SizedBox(height: 28),
                  fosteringSection!,
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class PetCareDeskSectionCard extends StatelessWidget {
  const PetCareDeskSectionCard({
    super.key,
    required this.child,
    this.tint,
    this.showSurface = true,
  });

  final Widget child;
  final Color? tint;
  final bool showSurface;

  @override
  Widget build(BuildContext context) {
    if (!showSurface) return child;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint ?? AppColorTokens.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: child,
      ),
    );
  }
}
