import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/vet.dart';
import '../utils/vet_accent.dart';

/// Compact vet row: `Name · city` with linked pet count right-aligned.
class VetCompactRow extends StatelessWidget {
  const VetCompactRow({
    super.key,
    required this.vet,
    required this.linkedPetCount,
    required this.onTap,
    this.showChevron = true,
  });

  final Vet vet;
  final int linkedPetCount;
  final VoidCallback onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final town = vetTownLabel(vet.address);
    final titleLine = town.isEmpty ? vet.name : '${vet.name} · $town';

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
                child: Text(
                  titleLine,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l.vetLinkedPetCount(linkedPetCount),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (showChevron) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
