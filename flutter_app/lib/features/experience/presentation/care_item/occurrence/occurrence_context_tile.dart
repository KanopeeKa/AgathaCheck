import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/features/pet_care/pet_care.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

/// Tappable summary: pet, care item, lifecycle chip, open count (D-OCC-002).
class OccurrenceContextTile extends ConsumerWidget {
  const OccurrenceContextTile({
    super.key,
    required this.detail,
    required this.onOpenCareDetails,
  });

  final OccurrenceDetail detail;
  final VoidCallback onOpenCareDetails;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final item = detail.item;
    final schedule = detail.schedule;
    final petAsync = ref.watch(petByIdProvider(item.petId));
    final finished = _isFinished(item, schedule);
    final paused = schedule?.status == 'paused' || item.status == 'paused';
    final openCount = schedule?.openOccurrences.length ?? 0;

    return Semantics(
      identifier: 'occurrence_context_tile',
      button: true,
      label: _semanticsLabel(
        l,
        petAsync,
        item.name,
        finished,
        paused,
        openCount,
      ),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: const Key('occurrence_about_item'),
          onTap: onOpenCareDetails,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: petAsync.when(
                loading: () => const SizedBox(
                  height: 40,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                error: (_, __) => _Content(
                  petName: '…',
                  petPhoto: null,
                  apiBaseUrl: ref.watch(apiBaseUrlProvider),
                  careName: item.name,
                  finished: finished,
                  paused: paused,
                  openCount: openCount,
                  showOpenCount: !finished,
                ),
                data: (pet) => _Content(
                  petName: pet?.name ?? '…',
                  petPhoto: pet?.photoPath,
                  apiBaseUrl: ref.watch(apiBaseUrlProvider),
                  careName: item.name,
                  finished: finished,
                  paused: paused,
                  openCount: openCount,
                  showOpenCount: !finished,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isFinished(CareItemSummary item, CareItemSchedule? schedule) {
    if (item.status == 'completed') return true;
    return schedule?.status == 'completed';
  }

  String _semanticsLabel(
    AppLocalizations l,
    AsyncValue<Pet?> petAsync,
    String careName,
    bool finished,
    bool paused,
    int openCount,
  ) {
    final petName = petAsync.value?.name ?? '';
    final parts = <String>[
      if (petName.isNotEmpty) petName,
      careName,
      if (finished) l.careItemStatusFinished,
      if (paused && !finished) l.careItemPausedStatus,
      if (!finished) l.occurrenceOpenCount(openCount),
      l.occurrenceAboutItem,
    ];
    return parts.join(', ');
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.petName,
    required this.petPhoto,
    required this.apiBaseUrl,
    required this.careName,
    required this.finished,
    required this.paused,
    required this.openCount,
    required this.showOpenCount,
  });

  final String petName;
  final String? petPhoto;
  final String apiBaseUrl;
  final String careName;
  final bool finished;
  final bool paused;
  final int openCount;
  final bool showOpenCount;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: ClipOval(
                child: buildPetPhotoOrPlaceholder(
                  photoPath: petPhoto,
                  apiBaseUrl: apiBaseUrl,
                  fit: BoxFit.cover,
                  semanticLabel: petName,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                petName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          careName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (finished || paused || showOpenCount) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (finished)
                CareItemStatusPill(
                  label: l.careItemStatusFinished,
                  tone: CareItemStatusTone.neutral,
                ),
              if (paused && !finished)
                CareItemStatusPill(
                  label: l.careItemPausedStatus,
                  tone: CareItemStatusTone.neutral,
                ),
              if (showOpenCount)
                Text(
                  l.occurrenceOpenCount(openCount),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
