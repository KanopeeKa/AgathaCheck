import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../organization/presentation/providers/organization_providers.dart';
import '../../controllers/pet_form_controller.dart';
import 'pet_org_section.dart';

enum _OwnershipMode { personal, organization }

class PetOwnershipSelector extends ConsumerWidget {
  final PetFormController controller;
  final String? initialOrgId;
  final String? selectedOrgId;
  final ValueChanged<String?> onOrgIdChanged;

  const PetOwnershipSelector({
    required this.controller,
    required this.onOrgIdChanged,
    this.initialOrgId,
    this.selectedOrgId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final orgsAsync = ref.watch(organizationListProvider);
    return orgsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (orgs) {
        if (orgs.isEmpty && initialOrgId == null) {
          return const SizedBox.shrink();
        }

        if (initialOrgId != null) {
          final orgName = orgs
              .where((o) => o.id == initialOrgId)
              .map((o) => o.name)
              .firstOrNull;
          return Card(
            child: ListTile(
              leading: const Icon(Icons.business),
              title: Text(l.orgPet),
              subtitle: Text(orgName ?? initialOrgId!),
            ),
          );
        }

        final mode = selectedOrgId == null
            ? _OwnershipMode.personal
            : _OwnershipMode.organization;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.petOwnership,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                RadioListTile<_OwnershipMode>(
                  key: const Key('pet_ownership_personal'),
                  title: Text(l.myPet),
                  value: _OwnershipMode.personal,
                  groupValue: mode,
                  onChanged: (_) => onOrgIdChanged(null),
                ),
                RadioListTile<_OwnershipMode>(
                  key: const Key('pet_ownership_org'),
                  title: Text(l.orgPet),
                  value: _OwnershipMode.organization,
                  groupValue: mode,
                  onChanged: orgs.isEmpty
                      ? null
                      : (_) => onOrgIdChanged(
                            selectedOrgId ?? orgs.first.id,
                          ),
                ),
                if (mode == _OwnershipMode.organization && orgs.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  PetOrgSection(
                    selectedOrgId: selectedOrgId ?? orgs.first.id,
                    orgs: orgs
                        .map((o) => {'id': o.id, 'name': o.name})
                        .toList(),
                    onChanged: onOrgIdChanged,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
