import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/pet_cache_freshness.dart';
import '../../../domain/utils/pet_cache_relative_time.dart';
import '../../providers/pet_providers.dart';

/// Shown when the pet list was loaded from offline cache (D2 / D18).
class PetListStaleBanner extends ConsumerWidget {
  const PetListStaleBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metadata = ref.watch(petListFetchMetadataProvider);
    if (metadata.freshness == PetCacheFreshness.fresh) {
      return const SizedBox.shrink();
    }
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isInfo = metadata.freshness == PetCacheFreshness.stale;
    final message = isInfo
        ? l.petListStaleBannerOffline(
            metadata.fetchedAt != null
                ? petCacheRelativeTimeLabel(l, metadata.fetchedAt!)
                : l.petCacheRelativeJustNow,
          )
        : l.petListCacheOutOfDateBannerMessage;

    final background = isInfo
        ? theme.colorScheme.secondaryContainer
        : theme.colorScheme.errorContainer;
    final foreground = isInfo
        ? theme.colorScheme.onSecondaryContainer
        : theme.colorScheme.onErrorContainer;
    final icon = isInfo
        ? Icons.cloud_off_outlined
        : Icons.warning_amber_outlined;

    return Semantics(
      identifier: 'pet_list_stale_banner',
      liveRegion: true,
      child: Material(
        color: background,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: foreground),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: foreground,
                  ),
                ),
              ),
              if (!isInfo)
                Semantics(
                  label: l.petListCacheRetrySemanticsLabel,
                  button: true,
                  child: TextButton(
                    onPressed: () => ref.invalidate(petListProvider),
                    child: Text(l.retry),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
