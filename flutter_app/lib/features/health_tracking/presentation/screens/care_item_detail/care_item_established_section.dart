import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../pet_profile/domain/entities/pet.dart';

/// Established badge and plain-language confirmation on Care Item detail.
class CareItemEstablishedSection extends StatelessWidget {
  const CareItemEstablishedSection({
    super.key,
    required this.pet,
    required this.isEstablished,
  });

  final Pet pet;
  final bool isEstablished;

  @override
  Widget build(BuildContext context) {
    if (!isEstablished) return const SizedBox.shrink();

    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        container: true,
        label: l.careItemEstablishedBody(pet.name),
        child: Row(
          key: const Key('care_item_established_section'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Chip(
              key: const Key('care_item_established_chip'),
              label: Text(l.careProgressionEstablishedMarker),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l.careItemEstablishedBody(pet.name),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
