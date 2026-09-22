import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../domain/entities/care_family.dart';
import '../../domain/services/care_family_inference.dart';
import '../../../health_tracking/domain/entities/health_entry.dart';
import 'care_family_custom_glyph.dart';

/// Care-family icon chip — shape-first, unified ink (Option A).
class CareFamilyIcon extends StatelessWidget {
  const CareFamilyIcon({
    super.key,
    required this.family,
    this.size = 20,
    this.showChip = true,
  });

  final CareFamily family;
  final double size;
  final bool showChip;

  factory CareFamilyIcon.forEntry(
    HealthEntry entry, {
    double size = 20,
    bool showChip = true,
  }) {
    return CareFamilyIcon(
      family: inferCareFamily(entry),
      size: size,
      showChip: showChip,
    );
  }

  factory CareFamilyIcon.forWire({
    required String? type,
    required String? careFamily,
    double size = 20,
    bool showChip = true,
  }) {
    return CareFamilyIcon(
      family: _familyFromWire(type: type, careFamily: careFamily),
      size: size,
      showChip: showChip,
    );
  }

  static CareFamily _familyFromWire({
    required String? type,
    required String? careFamily,
  }) {
    final fromWire = CareFamilyWire.fromWire(careFamily);
    if (fromWire != null) return fromWire;

    return switch (type) {
      'medication' => CareFamily.medication,
      'vet_visit' || 'vetVisit' => CareFamily.wellnessReview,
      'preventive' || 'vaccine' => CareFamily.other,
      _ => CareFamily.other,
    };
  }

  static IconData materialIconFor(CareFamily family) {
    return switch (family) {
      CareFamily.medication => Icons.medication_outlined,
      CareFamily.vaccination => Icons.vaccines_outlined,
      CareFamily.parasitePrevention => Icons.shield_outlined,
      CareFamily.wellnessReview => Icons.medical_services_outlined,
      CareFamily.dental => Icons.health_and_safety_outlined,
      CareFamily.weightMonitoring => Icons.scale_outlined,
      CareFamily.grooming => Icons.brush_outlined,
      CareFamily.nailCare => Icons.content_cut_outlined,
      CareFamily.other => Icons.sentiment_satisfied_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    const iconColor = AppColorTokens.petCarePrimary;
    final glyph = _glyph(iconColor);

    if (!showChip) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(child: glyph),
      );
    }

    return Container(
      width: size + 12,
      height: size + 12,
      decoration: BoxDecoration(
        color: AppColorTokens.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(child: glyph),
    );
  }

  Widget _glyph(Color iconColor) {
    return switch (family) {
      CareFamily.wellnessReview => CareFamilyCustomGlyph(
        family: CareFamilyGlyph.stethoscope,
        size: size,
        color: iconColor,
      ),
      CareFamily.dental => CareFamilyCustomGlyph(
        family: CareFamilyGlyph.tooth,
        size: size,
        color: iconColor,
      ),
      _ => Icon(materialIconFor(family), size: size, color: iconColor),
    };
  }
}
