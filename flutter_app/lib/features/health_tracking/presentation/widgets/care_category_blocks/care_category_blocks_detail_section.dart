import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../pet_care/presentation/widgets/care_surface/care_item_detail_row.dart';
import '../../../../pet_profile/pet_profile.dart';
import '../../../domain/entities/care_item_blocks.dart';
import '../../../domain/entities/health_entry.dart';

/// Read-only category block rows — only fields with values (D-CIE-019).
class CareCategoryBlocksDetailSection extends StatelessWidget {
  const CareCategoryBlocksDetailSection({
    super.key,
    required this.entry,
    required this.pet,
    required this.muted,
    this.skipDosageLine = false,
  });

  final HealthEntry entry;
  final Pet pet;
  final bool muted;

  /// When true, [ProductDoseBlock.legacyDosageLine] is omitted (shown elsewhere).
  final bool skipDosageLine;

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
        rows.addAll(
          _productDoseRows(
            l,
            blocks.productDose,
            skipDosageLine: skipDosageLine,
          ),
        );
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

    return Column(
      key: const Key('care_category_blocks_detail'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  List<Widget> _productDoseRows(
    AppLocalizations l,
    ProductDoseBlock? block, {
    required bool skipDosageLine,
  }) {
    if (block == null || block.isEmpty) return [];
    final out = <Widget>[];
    void add(String label, String value) {
      final t = value.trim();
      if (t.isEmpty) return;
      out.add(CareItemDetailRow(label: label, value: t, muted: muted));
    }

    add(l.careCategoryBlockProductName, block.productName);
    add(l.careCategoryBlockForm, block.form);
    add(l.careCategoryBlockStrength, block.strength);
    if (!skipDosageLine) {
      final dose = block.legacyDosageLine();
      if (dose.isNotEmpty) {
        add(l.dosage, dose);
      }
    }
    add(l.careCategoryBlockRouteMethod, block.routeMethod);
    return out;
  }

  List<Widget> _visitRows(AppLocalizations l, VisitBlock? block) {
    if (block == null || block.isEmpty) return [];
    final questions = block.questionsToAsk.trim();
    if (questions.isEmpty) return [];
    return [
      CareItemDetailRow(
        label: l.careCategoryBlockQuestionsToAsk,
        value: questions,
        muted: muted,
      ),
    ];
  }

  List<Widget> _weightRows(AppLocalizations l, Pet pet) {
    final ref = pet.weightReferenceValue;
    if (ref == null) return [];
    return [
      CareItemDetailRow(
        label: l.careCategoryBlockWeightTargetTitle,
        value: '$ref kg',
        muted: muted,
      ),
    ];
  }
}

/// Primary dosage line for Details: structured block first, then legacy field.
String? careItemPrimaryDosageLine(HealthEntry entry) {
  final fromBlock = entry.careBlocks.productDose?.legacyDosageLine() ?? '';
  if (fromBlock.trim().isNotEmpty) return fromBlock.trim();
  final legacy = entry.dosage.trim();
  return legacy.isEmpty ? null : legacy;
}
