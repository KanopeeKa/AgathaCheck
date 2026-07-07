import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

class CategoryBadge extends StatelessWidget {
  const CategoryBadge({required this.category, super.key});
  final String category;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPro = category == 'professional_multi_pet';
    final theme = Theme.of(context);
    return Chip(
      label: Text(
        isPro ? l10n.professionalMultiPet : l10n.petGuardian,
        style: TextStyle(
          color: isPro
              ? Colors.deepPurple.shade900
              : theme.colorScheme.onSecondaryContainer,
        ),
      ),
      backgroundColor: isPro
          ? Colors.deepPurple.shade50
          : theme.colorScheme.secondaryContainer,
    );
  }
}
