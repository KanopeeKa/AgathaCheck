import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../controllers/form_state.dart';

class FosterQuestionnaireSectionTabs extends StatelessWidget {
  const FosterQuestionnaireSectionTabs({
    super.key,
    required this.section,
    required this.onSectionSelected,
  });

  final FosterQuestionnaireSection section;
  final ValueChanged<FosterQuestionnaireSection> onSectionSelected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Semantics(
      label: l.fosterQuestionnaireSectionNavLabel,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _SectionTab(
              label: l.fosterQuestionnaireSectionProfile,
              selected: section == FosterQuestionnaireSection.profile,
              onTap: () => onSectionSelected(FosterQuestionnaireSection.profile),
            ),
            _SectionTab(
              label: l.fosterQuestionnaireSectionScreening,
              selected: section == FosterQuestionnaireSection.screening,
              onTap: () => onSectionSelected(FosterQuestionnaireSection.screening),
            ),
            _SectionTab(
              label: l.fosterQuestionnaireSectionAcknowledgement,
              selected: section == FosterQuestionnaireSection.acknowledgement,
              onTap: () =>
                  onSectionSelected(FosterQuestionnaireSection.acknowledgement),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTab extends StatelessWidget {
  const _SectionTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: true,
      selectedColor: theme.colorScheme.primaryContainer,
    );
  }
}
