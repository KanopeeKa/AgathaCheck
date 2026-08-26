import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/archived_pet.dart';
import '../providers/organization_providers.dart';
import '../widgets/org_shell_app_bar_title.dart';
import '../widgets/org_shell_scaffold.dart';

class ArchivedPetDetailScreen extends ConsumerWidget {
  const ArchivedPetDetailScreen({
    super.key,
    required this.orgId,
    required this.archiveId,
  });

  final String orgId;
  final String archiveId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archivedAsync = ref.watch(orgArchivedPetsProvider(orgId));
    final l = AppLocalizations.of(context)!;
    final dateFormat = DateFormat.yMMMd();

    return OrgShellScaffold(
      title: l.archivedPets,
      orgId: orgId,
      navVariant: OrgNavTitleVariant.withOrgLogo,
      leadingKey: const Key('archived_detail_back'),
      child: archivedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (archivedPets) {
          final archived = archivedPets
              .where((p) => p.id == archiveId)
              .cast<ArchivedPet?>()
              .firstOrNull;
          if (archived == null) {
            return Center(child: Text(l.noArchivedPets));
          }
          final snapshot = archived.shadowSnapshot ?? {};
          final capturedAt = archived.frozenAt ?? archived.archivedAt;
          final petSnapshot = snapshot['pet'] as Map<String, dynamic>? ?? {};
          final health = (snapshot['health_entries'] as List?) ?? [];
          final weights = (snapshot['weight_entries'] as List?) ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.ac_unit),
                  title: Text(archived.petName),
                  subtitle: Text(l.frozenShadow),
                  trailing: archived.hasShadowSnapshot
                      ? Chip(label: Text(l.frozenShadow))
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l.shadowSnapshotReadOnly,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (capturedAt != null) ...[
                const SizedBox(height: 8),
                Text(l.shadowCapturedAt(dateFormat.format(capturedAt))),
              ],
              const SizedBox(height: 16),
              if (petSnapshot.isNotEmpty) ...[
                Text(
                  petSnapshot['name']?.toString() ?? archived.petName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (petSnapshot['species'] != null)
                  Text(petSnapshot['species'].toString()),
              ],
              const SizedBox(height: 16),
              Text(
                l.shadowHealthEntries,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (health.isEmpty)
                Text(l.orgNoArchived)
              else
                ...health.map(
                  (entry) => ListTile(
                    dense: true,
                    title: Text(entry['name']?.toString() ?? ''),
                    subtitle: Text(entry['type']?.toString() ?? ''),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                l.shadowWeightEntries,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (weights.isEmpty)
                Text(l.orgNoArchived)
              else
                ...weights.map(
                  (entry) => ListTile(
                    dense: true,
                    title: Text('${entry['weight']} ${entry['unit']}'),
                    subtitle: Text(entry['date']?.toString() ?? ''),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
