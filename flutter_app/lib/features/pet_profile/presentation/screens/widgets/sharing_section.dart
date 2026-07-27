import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/pet.dart';
import '../../../../sharing/presentation/providers/sharing_providers.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../widgets/sharing/follower_sharing_content.dart';
import '../../widgets/sharing/foster_sharing_content.dart';
import '../../widgets/sharing/owner_sharing_content.dart';

/// Opens sharing controls in a modal bottom sheet (pet profile app bar).
Future<void> showSharingSheet(
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

    if (pet.isShared) {
      return FollowerSharingContent(petId: petId, pet: pet);
    }

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

    final accessAsync = ref.watch(petAccessNotifierProvider(petId));
    final linksAsync = ref.watch(petShareLinksNotifierProvider(petId));

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
        ),
      ),
    );
  }
}

class SharingSection extends ConsumerWidget {
  const SharingSection({required this.petId, required this.pet, super.key});

  final String petId;
  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    Widget content(String title, Widget child) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            leading: Icon(Icons.people, color: theme.colorScheme.primary),
            title: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: child,
              ),
            ],
          ),
        ),
      );
    }

    if (pet.isShared) {
      return content(
        l.sharingSection,
        FollowerSharingContent(petId: petId, pet: pet),
      );
    }

    if (pet.isFoster) {
      final linksAsync = ref.watch(petShareLinksNotifierProvider(petId));
      return content(
        l.sharingSection,
        linksAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l.couldNotLoadSharingInfo,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
          data: (links) => FosterSharingContent(
            petId: petId,
            pet: pet,
            shareLinks: links,
          ),
        ),
      );
    }

    final accessAsync = ref.watch(petAccessNotifierProvider(petId));
    final linksAsync = ref.watch(petShareLinksNotifierProvider(petId));

    return content(
      l.sharingSection,
      accessAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l.couldNotLoadSharingInfo,
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
        data: (accessList) => linksAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l.couldNotLoadSharingInfo,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
          data: (links) => OwnerSharingContent(
            petId: petId,
            pet: pet,
            accessList: accessList,
            shareLinks: links,
          ),
        ),
      ),
    );
  }
}
