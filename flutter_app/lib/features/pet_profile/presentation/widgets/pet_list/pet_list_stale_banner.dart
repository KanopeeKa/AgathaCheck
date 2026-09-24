import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../providers/pet_providers.dart';

/// Shown when the pet list was loaded from offline cache (D2 hybrid reads).
class PetListStaleBanner extends ConsumerWidget {
  const PetListStaleBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isStale = ref.watch(petListFetchMetadataProvider).isStale;
    if (!isStale) {
      return const SizedBox.shrink();
    }
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Semantics(
      identifier: 'pet_list_stale_banner',
      liveRegion: true,
      child: Material(
        color: theme.colorScheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 20,
                color: theme.colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l.petListStaleBannerMessage,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => ref.invalidate(petListProvider),
                child: Text(l.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
