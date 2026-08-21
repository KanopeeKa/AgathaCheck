import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/vet.dart';
import '../utils/vet_accent.dart';

/// Compact, text-first vet row for dashboard and list previews.
class VetCompactRow extends StatelessWidget {
  const VetCompactRow({
    super.key,
    required this.vet,
    required this.linkedPetCount,
    required this.onTap,
    this.showChevron = true,
  });

  final Vet vet;

  /// Null while the pet list is still resolving, so a partial dashboard never
  /// presents an unknown relationship count as zero.
  final int? linkedPetCount;
  final VoidCallback onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final town = vetTownLabel(vet.address);
    final linkedPetLabel = linkedPetCount == null
        ? null
        : l.vetLinkedPetCount(linkedPetCount!);
    final semanticLabel = [
      vet.name,
      if (town.isNotEmpty) town,
      if (linkedPetLabel != null) linkedPetLabel,
    ].join(', ');

    return Semantics(
      key: Key('vet_compact_row_${vet.id}'),
      button: true,
      label: semanticLabel,
      onTap: onTap,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.local_hospital_outlined,
                        size: 18,
                        color: resolveVetAccent(
                          context,
                          organizationId: vet.organizationId,
                        ).primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          vet.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (town.isNotEmpty || linkedPetLabel != null) ...[
                          const SizedBox(height: 2),
                          Wrap(
                            spacing: 6,
                            runSpacing: 2,
                            children: [
                              if (town.isNotEmpty)
                                Text(
                                  town,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              if (linkedPetLabel != null)
                                Text(
                                  linkedPetLabel,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (showChevron) ...[
                    const SizedBox(width: 8),
                    ExcludeSemantics(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
