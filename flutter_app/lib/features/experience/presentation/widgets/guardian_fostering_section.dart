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
  static const _fosterInviteAsset =
      'assets/dashboard/guardian-foster-invite.png';
  static const _fosterThanksAsset =
      'assets/dashboard/guardian-foster-thanks.png';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final fostered = pets
        .where((pet) => pet.isFoster && !pet.passedAway)
        .toList(growable: false);
    final shelters = <String, _ShelterGroup>{};
    for (final pet in fostered) {
      final shelter = pet.organizationName?.trim();
      if (shelter == null || shelter.isEmpty) continue;
      final key = pet.organizationId?.trim().isNotEmpty == true
          ? pet.organizationId!.trim()
          : shelter;
      shelters
          .putIfAbsent(
            key,
            () => _ShelterGroup(
              name: shelter,
              organizationId: pet.organizationId,
            ),
          )
          .pets
          .add(pet);
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
            titleColor: AppColorTokens.organizationActive,
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
                if (shelters.isEmpty)
                  GuardianIllustratedEmptyState(
                    key: const Key('guardian_dashboard_empty_shelters'),
                    assetPath: _fosterInviteAsset,
                    title: l.guardianFosterInviteTitle,
                    body: l.guardianFosterInviteBody,
                    actionLabel: l.findAShelter,
                    actionIcon: Icons.business_outlined,
                    actionKey: const Key(
                      'guardian_dashboard_empty_shelters_action',
                    ),
                    onAction: () => context.go('/o/orgs'),
                  )
                else ...[
                  GuardianIllustratedEmptyState(
                    key: const Key('guardian_dashboard_linked_shelters'),
                    assetPath: _fosterThanksAsset,
                    title: l.guardianLinkedShelterTitle,
                    body: l.guardianLinkedShelterBody,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l.yourShelters,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final entry in shelters.entries.take(
                    showAll ? shelters.length : _previewLimit,
                  ))
                    _ShelterRow(group: entry.value, l: l),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const Key('guardian_dashboard_find_another_shelter'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => context.go('/o/orgs'),
                      icon: const Icon(Icons.add_business_outlined, size: 18),
                      label: Text(l.findAnotherShelter),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (hasOverflow)
            GuardianDashboardSectionLink(
              label: l.allFosteringSessions,
              onPressed: () => context.go('/pc/fostering'),
            ),
        ],
      ),
    );
  }
}

class _ShelterGroup {
  _ShelterGroup({required this.name, required this.organizationId});

  final String name;
  final String? organizationId;
  final List<Pet> pets = [];
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
        onTap: () => context.push('/pet/${pet.id}/fostering-session'),
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
  const _ShelterRow({required this.group, required this.l});

  final _ShelterGroup group;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          '${group.name}, ${l.connected}, ${l.activeFosteringCount(group.pets.length)}',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openOrganizationProfile(context),
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
                    Text(
                      group.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    _FosteringStatus(label: l.connected),
                  ],
                ),
              ),
              Text(
                l.activeFosteringCount(group.pets.length),
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

  void _openOrganizationProfile(BuildContext context) {
    final orgId = group.organizationId?.trim();
    if (orgId == null || orgId.isEmpty) {
      context.go('/o/orgs');
      return;
    }
    final returnTo = Uri.encodeComponent(GoRouterState.of(context).uri.path);
    context.push('/o/orgs/$orgId?returnTo=$returnTo');
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
