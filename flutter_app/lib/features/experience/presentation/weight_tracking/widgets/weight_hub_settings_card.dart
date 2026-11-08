import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../sheets/weight_settings_edit_sheet.dart';
import 'weight_context_labels.dart';

/// Weight reference and management settings for a pet (read from [Pet], not overview).
class WeightHubSettingsCard extends ConsumerWidget {
  const WeightHubSettingsCard({super.key, required this.petId});

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final petsAsync = ref.watch(allPetsIncludingOrgProvider);
    final viewerContext = ref.watch(petDetailViewerContextProvider(petId));
    final canEdit =
        viewerContext.isPolicyResolved &&
        viewerContext.can(PetDetailAction.editProfile);

    return petsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: LinearProgressIndicator(),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (pets) {
        final pet = pets.where((p) => p.id == petId).firstOrNull;
        if (pet == null) return const SizedBox.shrink();

        final referenceWeight = WeightContextLabels.referenceWeightDisplay(
          l,
          valueKg: pet.weightReferenceValue,
        );
        final referenceSource = WeightContextLabels.referenceAuthorityDisplay(
          l,
          pet.weightReferenceAuthority,
        );
        final management = WeightContextLabels.managementContextDisplay(
          l,
          pet.weightManagementContext,
        );

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Card(
            key: const Key('weight_hub_settings_card'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.weightHubSettingsTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (canEdit)
                        TextButton(
                          key: const Key('weight_hub_settings_edit'),
                          onPressed: () => showWeightSettingsEditSheet(
                            context: context,
                            ref: ref,
                            pet: pet,
                          ),
                          child: Text(l.edit),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _SettingRow(
                    label: l.weightReferenceValueLabel,
                    value: referenceWeight,
                    semanticsId: 'weight_hub_setting_reference_weight',
                  ),
                  _SettingRow(
                    label: l.weightReferenceAuthorityLabel,
                    value: referenceSource,
                    semanticsId: 'weight_hub_setting_reference_source',
                  ),
                  _SettingRow(
                    label: l.weightManagementContextLabel,
                    value: management,
                    semanticsId: 'weight_hub_setting_management',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.label,
    required this.value,
    required this.semanticsId,
  });

  final String label;
  final String value;
  final String semanticsId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        identifier: semanticsId,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(value, style: theme.textTheme.bodyLarge),
            ),
          ],
        ),
      ),
    );
  }
}
