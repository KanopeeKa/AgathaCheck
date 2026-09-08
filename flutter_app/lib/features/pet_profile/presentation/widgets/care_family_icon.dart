import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../domain/entities/care_family.dart';
import '../../domain/services/care_family_inference.dart';
import '../../../health_tracking/domain/entities/health_entry.dart';

/// Care-family icon with plum semantic styling.
class CareFamilyIcon extends StatelessWidget {
  const CareFamilyIcon({super.key, required this.family, this.size = 20});

  final CareFamily family;
  final double size;

  factory CareFamilyIcon.forEntry(HealthEntry entry, {double size = 20}) {
    return CareFamilyIcon(family: inferCareFamily(entry), size: size);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 12,
      height: size + 12,
      decoration: BoxDecoration(
        color: AppColorTokens.petCareLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _iconFor(family),
        size: size,
        color: AppColorTokens.petCarePrimary.withValues(alpha: 0.72),
      ),
    );
  }

  static IconData _iconFor(CareFamily family) {
    return switch (family) {
      CareFamily.medication => Icons.medication_outlined,
      CareFamily.vaccination => Icons.vaccines_outlined,
      CareFamily.parasitePrevention => Icons.shield_outlined,
      CareFamily.wellnessReview => Icons.medical_services_outlined,
      CareFamily.dental => Icons.health_and_safety_outlined,
      CareFamily.weightMonitoring => Icons.monitor_weight_outlined,
      CareFamily.grooming => Icons.content_cut_outlined,
      CareFamily.nailCare => Icons.spa_outlined,
      CareFamily.other => Icons.event_note_outlined,
    };
  }
}
