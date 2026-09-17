import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../experience/domain/entities/app_experience.dart';
import '../../../experience/presentation/widgets/experience_shell_scaffold.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../../../pet_profile/domain/entities/pet_viewer_role.dart';
import '../../domain/entities/pet_access.dart';
import '../../domain/entities/share_invite.dart';
import '../pet_sharing_panel.dart';
import '../providers/share_pet_providers.dart';
import '../providers/sharing_providers.dart';
import '../widgets/share_pet_owner_body.dart';
import '../widgets/share_pet_selector.dart';

/// Unified sharing screen for pet detail and bulk share entry points.
class SharePetScreen extends ConsumerStatefulWidget {
  const SharePetScreen({
    super.key,
    this.petId,
    this.initialPetIds = const [],
    this.initialPetId,
  });

  /// Single-pet route: `/pet/:petId/share`.
  final String? petId;

  /// Bulk route extra: selected pet IDs.
  final List<String> initialPetIds;

  /// Optional initial selection within [initialPetIds].
  final String? initialPetId;

  @override
  ConsumerState<SharePetScreen> createState() => _SharePetScreenState();
}

class _SharePetScreenState extends ConsumerState<SharePetScreen> {
  late List<String> _petIds;

  @override
  void initState() {
    super.initState();
    _petIds = _resolvePetIds();
    final initial = widget.initialPetId ?? widget.petId;
    if (initial != null && _petIds.contains(initial)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(sharePetNotifierProvider(_petIds).notifier).selectPet(initial);
      });
    }
  }

  List<String> _resolvePetIds() {
    if (widget.petId != null) return [widget.petId!];
    return widget.initialPetIds;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final petsAsync = ref.watch(sharePetListProvider(_petIds));
    final shareState = ref.watch(sharePetNotifierProvider(_petIds));

    return ExperienceShellScaffold(
      experience: AppExperience.petCare,
      currentLocation: GoRouterState.of(context).uri.path,
      screenTitle: l.sharePet,
      backPath: widget.petId != null ? '/pet/${widget.petId}' : '/pc/pets',
      child: petsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(l.errorWithMessage('$error'))),
        data: (pets) {
          if (pets.isEmpty) {
            return Center(child: Text(l.petNotFound));
          }

          final selectedId = shareState.selectedPetId ?? pets.first.id;
          final selectedPet = pets.firstWhere(
            (p) => p.id == selectedId,
            orElse: () => pets.first,
          );
          final viewerRole = sharePetViewerRole(selectedPet);

          if (viewerRole == PetViewerRole.organization) {
            return Center(child: Text(l.sharePetOrgNotAvailable));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_petIds.length > 1)
                SharePetSelector(
                  pets: pets,
                  selectedPetId: selectedId,
                  onSelected: (id) => ref
                      .read(sharePetNotifierProvider(_petIds).notifier)
                      .selectPet(id),
                ),
              if (shareState.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (shareState.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    l.couldNotLoadSharingInfo,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              _SharePetBody(
                pet: selectedPet,
                allPetIds: _petIds,
                viewerRole: viewerRole,
                shareNotifier: ref.read(
                  sharePetNotifierProvider(_petIds).notifier,
                ),
                pendingInvites:
                    shareState.accessByPet[selectedId]?.pendingInvites ??
                    const [],
                accessList:
                    shareState.accessByPet[selectedId]?.access ?? const [],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SharePetBody extends ConsumerWidget {
  const _SharePetBody({
    required this.pet,
    required this.allPetIds,
    required this.viewerRole,
    required this.shareNotifier,
    required this.pendingInvites,
    required this.accessList,
  });

  final Pet pet;
  final List<String> allPetIds;
  final PetViewerRole viewerRole;
  final SharePetNotifier shareNotifier;
  final List<ShareInvite> pendingInvites;
  final List<PetAccess> accessList;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (viewerRole) {
      case PetViewerRole.fosterCarer:
        final linksAsync = ref.watch(petShareLinksNotifierProvider(pet.id));
        return linksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) =>
              Text(AppLocalizations.of(context)!.couldNotLoadSharingInfo),
          data: (links) =>
              FosterSharingContent(petId: pet.id, pet: pet, shareLinks: links),
        );
      case PetViewerRole.sharedCarer:
        return FollowerSharingContent(petId: pet.id, pet: pet);
      case PetViewerRole.guardian:
      case PetViewerRole.coParent:
        final linksAsync = ref.watch(petShareLinksNotifierProvider(pet.id));
        final canTransfer =
            viewerRole == PetViewerRole.guardian && pet.organizationId == null;
        return linksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) =>
              Text(AppLocalizations.of(context)!.couldNotLoadSharingInfo),
          data: (links) => SharePetOwnerBody(
            pet: pet,
            allPetIds: allPetIds,
            accessList: accessList,
            shareLinks: links,
            pendingInvites: pendingInvites,
            canTransferOwnership: canTransfer,
            onInviteSent: () => shareNotifier.refresh(),
          ),
        );
      case PetViewerRole.organization:
        return const SizedBox.shrink();
    }
  }
}
