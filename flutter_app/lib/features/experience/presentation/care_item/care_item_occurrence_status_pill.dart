import 'package:flutter/material.dart';

import 'package:pet_profile_app/features/pet_care/pet_care.dart';

import 'package:pet_profile_app/features/care_item/domain/occurrence_display.dart';

import 'detail/care_item_attention_occurrence_row.dart';

/// Status pill for occurrence leaf screens (EX-10 bridge from pet_care).
class CareItemOccurrenceStatusPill extends StatelessWidget {
  const CareItemOccurrenceStatusPill({super.key, required this.pill});

  final OccurrencePillStyle pill;

  @override
  Widget build(BuildContext context) {
    return CareItemStatusPill(
      label: pill.label,
      tone: careItemStatusToneForPill(pill.tone),
    );
  }
}
