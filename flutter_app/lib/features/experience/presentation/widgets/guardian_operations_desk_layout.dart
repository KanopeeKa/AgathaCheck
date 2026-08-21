import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_tokens.dart';

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
    this.todayHeader,
  });

  /// The viewport breakpoint is evaluated by the parent before page padding.
  static const wideBreakpoint = 900.0;

  final bool useWideLayout;
  final Widget petsSection;
  final Widget eventsSection;
  final Widget vetsSection;
  final Widget? todayHeader;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, _) {
        final isWide = useWideLayout;

        return Center(
          child: ConstrainedBox(
            key: const Key('guardian_operations_desk_content'),
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (todayHeader != null) ...[
                  todayHeader!,
                  const SizedBox(height: 16),
                ],
                GuardianDeskSectionCard(
                  key: const Key('guardian_desk_primary_section_card'),
                  emphasized: true,
                  child: petsSection,
                ),
                const SizedBox(height: 20),
                if (isWide)
                  Row(
                    key: const Key('guardian_desk_secondary_sections_wide'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: GuardianDeskSectionCard(child: eventsSection),
                      ),
                      const SizedBox(width: 20),
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
                      const SizedBox(height: 20),
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
    final borderColor = emphasized
        ? AppColorTokens.operationsOlive.withValues(alpha: 0.28)
        : colors.outlineVariant;

    return Container(
      decoration: BoxDecoration(
        color: emphasized ? AppColorTokens.operationsSurface : colors.surface,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColorTokens.operationsOlive.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: emphasized ? 96 : 56,
                height: 5,
                color: emphasized
                    ? AppColorTokens.operationsGold
                    : AppColorTokens.guardianCarePrimary,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 6),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
