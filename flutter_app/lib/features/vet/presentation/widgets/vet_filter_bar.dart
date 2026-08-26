import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../organization/domain/entities/organization.dart';
import '../../../organization/presentation/providers/organization_providers.dart';

/// Filter chips for vet list: All | My vets | per-org (dropdown when >3 orgs).
class VetFilterBar extends ConsumerWidget {
  const VetFilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    this.guardianOnly = false,
  });

  /// `null` = all, `'_personal'` = personal vets, otherwise org id.
  final String? selectedFilter;
  final ValueChanged<String?> onFilterChanged;
  final bool guardianOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final orgsAsync = ref.watch(organizationListProvider);
    final orgs = orgsAsync.valueOrNull ?? <Organization>[];

    if (orgs.isEmpty && guardianOnly) {
      return const SizedBox.shrink();
    }

    if (orgs.length > 3) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String?>(
                key: const Key('vet_org_filter_dropdown'),
                initialValue: selectedFilter,
                decoration: InputDecoration(
                  labelText: l.all,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: null, child: Text(l.all)),
                  DropdownMenuItem(value: '_personal', child: Text(l.myVets)),
                  ...orgs.map(
                    (org) =>
                        DropdownMenuItem(value: org.id, child: Text(org.name)),
                  ),
                ],
                onChanged: onFilterChanged,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (!guardianOnly) ...[
              FilterChip(
                label: Text(l.all),
                selected: selectedFilter == null,
                onSelected: (_) => onFilterChanged(null),
              ),
              const SizedBox(width: 8),
            ],
            FilterChip(
              label: Text(l.myVets),
              selected: selectedFilter == '_personal',
              onSelected: (_) => onFilterChanged('_personal'),
            ),
            ...orgs.map(
              (org) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: FilterChip(
                  avatar: const Icon(Icons.business, size: 16),
                  label: Text(org.name),
                  selected: selectedFilter == org.id,
                  onSelected: (_) => onFilterChanged(org.id),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
