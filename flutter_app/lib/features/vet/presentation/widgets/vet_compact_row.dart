import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/vet.dart';
import '../utils/vet_accent.dart';

/// Compact vet row for the guardian dashboard preview (name, city, pet count).
class VetCompactRow extends StatelessWidget {
  const VetCompactRow({
    super.key,
    required this.vet,
    required this.linkedPetCount,
    required this.onTap,
  });

  final Vet vet;
  final int linkedPetCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final town = vetTownLabel(vet.address);
    final subtitleParts = <String>[
      if (town.isNotEmpty) town,
      if (linkedPetCount > 0) l.vetLinkedPetCount(linkedPetCount),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Row(
            children: [
              Icon(
                Icons.local_hospital_outlined,
                size: 18,
                color: resolveVetAccent(
                  context,
                  organizationId: vet.organizationId,
                ).primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vet.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitleParts.isNotEmpty)
                      Text(
                        subtitleParts.join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
