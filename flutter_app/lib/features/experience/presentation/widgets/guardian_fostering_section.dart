import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import 'guardian_dashboard_section_header.dart';
import 'guardian_illustrated_empty_state.dart';
import 'guardian_operations_desk_layout.dart';

/// Guardian-facing summary of established foster relationships.
///
/// This deliberately derives only from Guardian-visible foster pets. It never
/// invents Shelter session data or exposes placement information that belongs
/// to a Shelter workflow.
class GuardianFosteringSection extends StatelessWidget {
  const GuardianFosteringSection({
    super.key,
    required this.pets,
    this.showAll = false,
  });

  final List<Pet> pets;
  final bool showAll;

  static const _previewLimit = 2;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final fostered = pets
        .where((pet) => pet.isFoster && !pet.passedAway)
        .toList(growable: false);
    final shelters = <String, List<Pet>>{};
    for (final pet in fostered) {
      final shelter = pet.organizationName?.trim();
      if (shelter == null || shelter.isEmpty) continue;
      shelters.putIfAbsent(shelter, () => []).add(pet);
    }
    final hasOverflow =
        !showAll &&
        (fostered.length > _previewLimit || shelters.length > _previewLimit);

    return Semantics(
      container: true,
      label: l.fosteringSessions,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GuardianDashboardSectionHeader(
            title: l.fosteringSessionsEyebrow,
            actionLabel: hasOverflow ? l.allFosteringSessions : null,
            onAction: hasOverflow ? () => context.go('/g/fostering') : null,
          ),
          const SizedBox(height: 10),
          GuardianDeskSectionCard(
            tint: AppColorTokens.organizationLight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (fostered.isEmpty)
                  GuardianIllustratedEmptyState(
                    key: const Key('guardian_dashboard_empty_fostering'),
                    title: l.guardianEmptyFosteringTitle,
                    body: l.guardianEmptyFosteringBody,
                  )
                else ...[
                  for (final pet in fostered.take(
                    showAll ? fostered.length : _previewLimit,
                  ))
                    _FosteringPetRow(pet: pet, l: l),
                ],
                const SizedBox(height: 16),
                Text(
                  l.shelters,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                if (shelters.isEmpty)
                  GuardianIllustratedEmptyState(
                    key: const Key('guardian_dashboard_empty_shelters'),
                    assetPath: 'assets/dashboard/guardian-empty-fostering.png',
                    title: l.guardianEmptyShelterTitle,
                    body: l.guardianEmptyShelterBody,
                    actionLabel: l.connectShelter,
                    actionIcon: Icons.business_outlined,
                    actionKey: const Key('guardian_dashboard_empty_shelters_action'),
                    onAction: () => context.go('/o/orgs'),
                  )
                else
                  for (final entry in shelters.entries.take(
                    showAll ? shelters.length : _previewLimit,
                  ))
                    _ShelterRow(
                      name: entry.key,
                      fosteredPets: entry.value,
                      l: l,
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FosteringPetRow extends StatelessWidget {
  const _FosteringPetRow({required this.pet, required this.l});

  final Pet pet;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final shelter = pet.organizationName?.trim();
    final hasActiveStatus =
        pet.fosterPlacementStatus?.trim().toLowerCase() == 'active';
    return Semantics(
      button: true,
      label: '${pet.name}, ${hasActiveStatus ? l.active : l.fostering}',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/pet/${pet.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColorTokens.organizationSoft,
                foregroundColor: AppColorTokens.organizationActive,
                child: const Icon(Icons.pets_outlined, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (shelter != null && shelter.isNotEmpty)
                      Text(
                        shelter,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              _FosteringStatus(label: hasActiveStatus ? l.active : l.fostering),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShelterRow extends StatelessWidget {
  const _ShelterRow({
    required this.name,
    required this.fosteredPets,
    required this.l,
  });

  final String name;
  final List<Pet> fosteredPets;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          '$name, ${l.connected}, ${l.activeFosteringCount(fosteredPets.length)}',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/o/orgs'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: AppColorTokens.surface,
                foregroundColor: AppColorTokens.organizationActive,
                child: Icon(Icons.home_work_outlined, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    _FosteringStatus(label: l.connected),
                  ],
                ),
              ),
              Text(
                l.activeFosteringCount(fosteredPets.length),
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _FosteringStatus extends StatelessWidget {
  const _FosteringStatus({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppColorTokens.organizationActive,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
