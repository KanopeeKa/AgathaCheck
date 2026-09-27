import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../pet_profile/domain/entities/care_family.dart';
import '../../../../pet_profile/domain/entities/pet.dart';
import '../../../domain/entities/care_item_blocks.dart';
import '../../../domain/entities/health_entry.dart';

/// Read-only category block rows — only fields with values (D-CIE-019).
class CareCategoryBlocksDetailSection extends StatelessWidget {
  const CareCategoryBlocksDetailSection({
    super.key,
    required this.entry,
    required this.pet,
    required this.muted,
  });

  final HealthEntry entry;
  final Pet pet;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final family = entry.careFamily;
    if (family == null) return const SizedBox.shrink();

    final blocks = entry.careBlocks;
    final rows = <Widget>[];

    switch (family) {
      case CareFamily.medication:
      case CareFamily.parasitePrevention:
        rows.addAll(_productDoseRows(l, blocks.productDose));
      case CareFamily.vaccination:
      case CareFamily.wellnessReview:
        rows.addAll(_visitRows(l, blocks.visit));
      case CareFamily.weightMonitoring:
        rows.addAll(_weightRows(l, pet));
      case CareFamily.dental:
      case CareFamily.grooming:
      case CareFamily.nailCare:
      case CareFamily.other:
        break;
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final textColor = muted ? theme.colorScheme.onSurfaceVariant : null;

    return Column(
      key: const Key('care_category_blocks_detail'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          DefaultTextStyle(
            style: theme.textTheme.bodyMedium!.copyWith(color: textColor),
            child: rows[i],
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  List<Widget> _productDoseRows(AppLocalizations l, ProductDoseBlock? block) {
    if (block == null || block.isEmpty) return [];
    final out = <Widget>[];
    void add(String label, String value) {
      final t = value.trim();
      if (t.isEmpty) return;
      out.add(_labelValue(l, label, t));
    }

    add(l.careCategoryBlockProductName, block.productName);
    add(l.careCategoryBlockForm, block.form);
    add(l.careCategoryBlockStrength, block.strength);
    final dose = block.legacyDosageLine();
    if (dose.isNotEmpty) {
      add(l.dosage, dose);
    }
    add(l.careCategoryBlockRouteMethod, block.routeMethod);
    return out;
  }

  List<Widget> _visitRows(AppLocalizations l, VisitBlock? block) {
    if (block == null || block.isEmpty) return [];
    return [
      _labelValue(l, l.careCategoryBlockQuestionsToAsk, block.questionsToAsk),
    ];
  }

  List<Widget> _weightRows(AppLocalizations l, Pet pet) {
    final ref = pet.weightReferenceValue;
    if (ref == null) return [];
    return [_labelValue(l, l.careCategoryBlockWeightTargetTitle, '$ref kg')];
  }

  Widget _labelValue(AppLocalizations l, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value),
      ],
    );
  }
}
