import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/form/app_form_labeled_field.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../pet_profile/domain/entities/care_family.dart';
import '../../../../pet_profile/domain/entities/pet.dart';
import '../../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../../domain/entities/care_item_blocks.dart';
import 'collapsible_care_block_tile.dart';

class CareCategoryBlocksEditSection extends ConsumerWidget {
  const CareCategoryBlocksEditSection({
    super.key,
    required this.careFamily,
    required this.blocks,
    required this.selectedPetIds,
    required this.onBlocksChanged,
  });

  final CareFamily? careFamily;
  final CareItemBlocks blocks;
  final Set<String> selectedPetIds;
  final ValueChanged<CareItemBlocks> onBlocksChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (careFamily == null) return const SizedBox.shrink();
    final l = AppLocalizations.of(context)!;

    switch (careFamily!) {
      case CareFamily.medication:
      case CareFamily.parasitePrevention:
        return _ProductDoseEditor(
          l: l,
          block: blocks.productDose ?? const ProductDoseBlock(),
          onChanged: (pd) => onBlocksChanged(
            blocks.copyWith(
              productDose: pd.isEmpty ? null : pd,
              clearProductDose: pd.isEmpty,
            ),
          ),
        );
      case CareFamily.vaccination:
      case CareFamily.wellnessReview:
        return _VisitEditor(
          l: l,
          block: blocks.visit ?? const VisitBlock(),
          onChanged: (v) => onBlocksChanged(
            blocks.copyWith(visit: v.isEmpty ? null : v, clearVisit: v.isEmpty),
          ),
        );
      case CareFamily.weightMonitoring:
        return _WeightTargetHint(
          l: l,
          selectedPetIds: selectedPetIds,
          petsAsync: ref.watch(petListProvider),
        );
      case CareFamily.dental:
      case CareFamily.grooming:
      case CareFamily.nailCare:
      case CareFamily.other:
        return const SizedBox.shrink();
    }
  }
}

class _ProductDoseEditor extends StatelessWidget {
  const _ProductDoseEditor({
    required this.l,
    required this.block,
    required this.onChanged,
  });

  final AppLocalizations l;
  final ProductDoseBlock block;
  final ValueChanged<ProductDoseBlock> onChanged;

  @override
  Widget build(BuildContext context) {
    return CollapsibleCareBlockTile(
      title: l.careCategoryBlockProductDoseTitle,
      collapsedLabel: l.careCategoryBlockAddProductDose,
      hasContent: block.hasAnyValue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _textField(
            key: const Key('care_block_product_name'),
            label: l.careCategoryBlockProductName,
            value: block.productName,
            onChanged: (v) => onChanged(block.copyWith(productName: v)),
          ),
          const SizedBox(height: 12),
          _textField(
            key: const Key('care_block_form'),
            label: l.careCategoryBlockForm,
            value: block.form,
            onChanged: (v) => onChanged(block.copyWith(form: v)),
          ),
          const SizedBox(height: 12),
          _textField(
            key: const Key('care_block_strength'),
            label: l.careCategoryBlockStrength,
            value: block.strength,
            onChanged: (v) => onChanged(block.copyWith(strength: v)),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _textField(
                  key: const Key('care_block_dose_amount'),
                  label: l.careCategoryBlockDoseAmount,
                  value: block.doseAmount,
                  onChanged: (v) => onChanged(block.copyWith(doseAmount: v)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _textField(
                  key: const Key('care_block_dose_unit'),
                  label: l.careCategoryBlockDoseUnit,
                  value: block.doseUnit,
                  onChanged: (v) => onChanged(block.copyWith(doseUnit: v)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _textField(
            key: const Key('care_block_route'),
            label: l.careCategoryBlockRouteMethod,
            value: block.routeMethod,
            onChanged: (v) => onChanged(block.copyWith(routeMethod: v)),
          ),
        ],
      ),
    );
  }

  Widget _textField({
    required Key key,
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return AppFormLabeledField(
      label: label,
      child: TextFormField(key: key, initialValue: value, onChanged: onChanged),
    );
  }
}

class _VisitEditor extends StatelessWidget {
  const _VisitEditor({
    required this.l,
    required this.block,
    required this.onChanged,
  });

  final AppLocalizations l;
  final VisitBlock block;
  final ValueChanged<VisitBlock> onChanged;

  @override
  Widget build(BuildContext context) {
    return CollapsibleCareBlockTile(
      title: l.careCategoryBlockVisitTitle,
      collapsedLabel: l.careCategoryBlockAddVisit,
      hasContent: block.hasAnyValue,
      child: AppFormLabeledField(
        label: l.careCategoryBlockQuestionsToAsk,
        child: TextFormField(
          key: const Key('care_block_questions'),
          initialValue: block.questionsToAsk,
          maxLines: 3,
          onChanged: (v) => onChanged(block.copyWith(questionsToAsk: v)),
        ),
      ),
    );
  }
}

class _WeightTargetHint extends StatelessWidget {
  const _WeightTargetHint({
    required this.l,
    required this.selectedPetIds,
    required this.petsAsync,
  });

  final AppLocalizations l;
  final Set<String> selectedPetIds;
  final AsyncValue<List<Pet>> petsAsync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return petsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (pets) {
        if (selectedPetIds.length != 1) return const SizedBox.shrink();
        Pet? pet;
        for (final candidate in pets) {
          if (candidate.id == selectedPetIds.first) {
            pet = candidate;
            break;
          }
        }
        if (pet == null) return const SizedBox.shrink();
        final refWeight = pet.weightReferenceValue;
        return Column(
          key: const Key('care_block_weight_target'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.careCategoryBlockWeightTargetTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l.careCategoryBlockWeightTargetFromPet(pet.name),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (refWeight != null) ...[
              const SizedBox(height: 4),
              Text(
                '${l.weightReferenceValueLabel}: $refWeight kg',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ],
        );
      },
    );
  }
}
