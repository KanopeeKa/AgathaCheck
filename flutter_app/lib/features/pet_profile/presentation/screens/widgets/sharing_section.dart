import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/pet.dart';
import '../../../../sharing/presentation/providers/sharing_providers.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../widgets/sharing/follower_sharing_content.dart';
import '../../widgets/sharing/foster_sharing_content.dart';
import '../../widgets/sharing/owner_sharing_content.dart';

class SharingSection extends ConsumerWidget {
  const SharingSection({required this.petId, required this.pet, super.key});

  final String petId;
  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (pet.isShared) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            leading: Icon(Icons.people, color: theme.colorScheme.primary),
            title: Text(
              l.sharingSection,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: FollowerSharingContent(petId: petId, pet: pet),
              ),
            ],
          ),
        ),
      );
    }

    if (pet.isFoster) {
      final linksAsync = ref.watch(petShareLinksNotifierProvider(petId));

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            leading: Icon(Icons.people, color: theme.colorScheme.primary),
            title: Text(
              l.sharingSection,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: linksAsync.when(
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
              ),
            ],
          ),
        ),
      );
    }

    final accessAsync = ref.watch(petAccessNotifierProvider(petId));
    final linksAsync = ref.watch(petShareLinksNotifierProvider(petId));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          leading: Icon(Icons.people, color: theme.colorScheme.primary),
          title: Text(
            l.sharingSection,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: accessAsync.when(
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
            ),
          ],
        ),
      ),
    );
  }
}
