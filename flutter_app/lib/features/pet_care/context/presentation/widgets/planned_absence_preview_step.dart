import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/utils/calendar_date.dart';
import '../../../../../l10n/app_localizations.dart';
import '../providers/care_context_providers.dart';
import 'care_period_pet_preview_section.dart';

class PlannedAbsencePreviewStep extends ConsumerWidget {
  const PlannedAbsencePreviewStep({
    super.key,
    required this.startsOn,
    required this.endsOn,
    required this.petNamesById,
    required this.selectedPetIds,
    required this.onRetry,
  });

  final String startsOn;
  final String endsOn;
  final Map<String, String> petNamesById;
  final List<String> selectedPetIds;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final orderedPetIds = [...selectedPetIds]..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.careContextAwayPreviewStepTitle,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          l.careContextAwayPreviewIntro,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l.careContextAwayPreviewDateRange(
            _formatRangeDate(startsOn),
            _formatRangeDate(endsOn),
          ),
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 20),
        ...orderedPetIds.map((petId) {
          final previewKey = (petId: petId, startsOn: startsOn, endsOn: endsOn);
          final coverageAsync = ref.watch(
            carePeriodCoverageProvider(previewKey),
          );
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: coverageAsync.when(
              loading: () => CarePeriodPetPreviewSection.loading(
                petName: petNamesById[petId] ?? '',
              ),
              error: (_, __) => CarePeriodPetPreviewSection.error(
                petName: petNamesById[petId] ?? '',
                message: l.careContextAwayPreviewError,
                onRetry: onRetry,
              ),
              data: (result) => CarePeriodPetPreviewSection(
                petName: petNamesById[petId] ?? '',
                result: result,
              ),
            ),
          );
        }),
      ],
    );
  }

  String _formatRangeDate(String isoDate) {
    final parsed = parseCalendarDate(isoDate);
    if (parsed == null) return isoDate;
    return formatCalendarDateDisplay(parsed);
  }
}
