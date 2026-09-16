import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../pet_profile/domain/entities/pet.dart';
import '../../sharing/domain/entities/pet_access.dart';
import '../../../l10n/app_localizations.dart';
import 'providers/sharing_providers.dart';
import 'widgets/follower_sharing_content.dart';
import 'widgets/foster_sharing_content.dart';
import 'widgets/owner_sharing_content.dart';

export 'widgets/follower_sharing_content.dart';
export 'widgets/foster_sharing_content.dart';
export 'widgets/owner_sharing_content.dart';

/// Opens sharing controls in a modal bottom sheet (pet profile app bar).
Future<void> showPetSharingPanel(
  BuildContext context,
  WidgetRef ref, {
  required String petId,
  required Pet pet,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.sharingSection,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: AppLocalizations.of(context)!.close,
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: SharingSectionContent(petId: petId, pet: pet),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

/// Sharing body without the profile expansion card wrapper.
class SharingSectionContent extends ConsumerWidget {
  const SharingSectionContent({
    required this.petId,
    required this.pet,
    super.key,
  });

  final String petId;
  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (pet.isFoster) {
      final linksAsync = ref.watch(petShareLinksNotifierProvider(petId));
      return linksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text(
          l.couldNotLoadSharingInfo,
          style: TextStyle(color: theme.colorScheme.error),
        ),
        data: (links) =>
            FosterSharingContent(petId: petId, pet: pet, shareLinks: links),
      );
    }

    if (pet.isShared && pet.accessRole != PetAccessRole.coParent) {
      return FollowerSharingContent(petId: petId, pet: pet);
    }

    final accessAsync = ref.watch(petAccessNotifierProvider(petId));
    final linksAsync = ref.watch(petShareLinksNotifierProvider(petId));
    final canTransferOwnership = !pet.isShared && pet.organizationId == null;

    return accessAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text(
        l.couldNotLoadSharingInfo,
        style: TextStyle(color: theme.colorScheme.error),
      ),
      data: (accessList) => linksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text(
          l.couldNotLoadSharingInfo,
          style: TextStyle(color: theme.colorScheme.error),
        ),
        data: (links) => OwnerSharingContent(
          petId: petId,
          pet: pet,
          accessList: accessList,
          shareLinks: links,
          canTransferOwnership: canTransferOwnership,
        ),
      ),
    );
  }
}
