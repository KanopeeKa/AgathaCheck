import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

class CategoryBadge extends StatelessWidget {
  const CategoryBadge({required this.category, super.key});
  final String category;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPro = category == 'professional_multi_pet';
    return Chip(
      label: Text(
        isPro ? l10n.professionalMultiPet : l10n.petGuardian,
        style: TextStyle(
          color: isPro ? l10n.proChipTextColor : l10n.guardianChipTextColor,
        ),
      ),
      backgroundColor: isPro ? l10n.proChipBgColor : l10n.guardianChipBgColor,
    );
  }
}
