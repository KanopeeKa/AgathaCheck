import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/archived_pet.dart';
import '../providers/organization_providers.dart';

class ArchivedPetsScreen extends ConsumerWidget {
  const ArchivedPetsScreen({
    super.key,
    this.orgId,
  });

  final int? orgId;

  bool get _isOrgArchive => orgId != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archivedAsync = _isOrgArchive
        ? ref.watch(orgArchivedPetsProvider(orgId!))
        : ref.watch(userArchivedPetsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.archivedPets),
        leading: IconButton(
          key: const Key('org_archived_back'),
          icon: const Icon(Icons.arrow_back),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => context.pop(),
        ),
      ),
      body: archivedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text('$e'),
              const SizedBox(height: 8),
              ElevatedButton(
                key: const Key('org_archived_retry'),
                onPressed: () {
                  if (_isOrgArchive) {
                    ref.invalidate(orgArchivedPetsProvider(orgId!));
                  } else {
                    ref.invalidate(userArchivedPetsProvider);
                  }
                },
                child: Text(l.retry),
              ),
            ],
          ),
        ),
        data: (archivedPets) {
          if (archivedPets.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      Icons.archive_outlined,
                      size: 80,
                      color: colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l.noArchivedPets,
                    style: theme.textTheme.headlineSmall,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: archivedPets.length,
            itemBuilder: (context, index) {
              final archived = archivedPets[index];
              return _ArchivedPetCard(archivedPet: archived);
            },
          );
        },
      ),
    );
  }
}

class _ArchivedPetCard extends StatelessWidget {
  const _ArchivedPetCard({required this.archivedPet});

  final ArchivedPet archivedPet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;
    final dateFormat = DateFormat.yMMMd();
    final archivedDate = archivedPet.archivedAt ?? archivedPet.createdAt;

    String transferLabel(String type) {
      switch (type.toLowerCase()) {
        case 'adoption':
          return l.transferTypeAdoption;
        case 'transfer':
          return l.transferTypeTransfer;
        case 'release':
          return l.transferTypeRelease;
        default:
          return l.transferTypeOther;
      }
    }

    return MergeSemantics(
      child: Semantics(
        label: '${archivedPet.petName}, ${archivedPet.species}, '
            '${transferLabel(archivedPet.transferType)}, '
            '${archivedDate != null ? dateFormat.format(archivedDate) : ''}',
        child: Card(
          key: Key('org_archived_card_${archivedPet.id}'),
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  child: Icon(
                    _transferTypeIcon(archivedPet.transferType),
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        archivedPet.petName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (archivedPet.species.isNotEmpty) ...[
                            Text(
                              archivedPet.species,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _transferTypeColor(
                                      archivedPet.transferType)
                                  .withAlpha(30),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              transferLabel(archivedPet.transferType),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _transferTypeColor(
                                    archivedPet.transferType),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (archivedDate != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          l.archivedOn(dateFormat.format(archivedDate)),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (archivedPet.notes.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          archivedPet.notes,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _transferTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'adoption':
        return Icons.favorite;
      case 'transfer':
        return Icons.swap_horiz;
      case 'release':
        return Icons.nature_people;
      default:
        return Icons.archive;
    }
  }

  Color _transferTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'adoption':
        return Colors.pink;
      case 'transfer':
        return Colors.blue;
      case 'release':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
