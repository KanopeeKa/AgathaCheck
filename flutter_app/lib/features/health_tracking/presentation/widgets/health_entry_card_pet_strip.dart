import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/api_base_url_provider.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../../../pet_profile/presentation/utils/pet_accent_color.dart';
import '../../../pet_profile/presentation/widgets/pet_photo_image.dart';
import '../../domain/entities/health_entry.dart';

class HealthEntryPetStrip extends ConsumerWidget {
  const HealthEntryPetStrip({
    super.key,
    this.pet,
    this.petName,
    required this.colorScheme,
  });

  final Pet? pet;
  final String? petName;
  final ColorScheme colorScheme;

  String get _displayName {
    final fromPet = pet?.name;
    if (fromPet != null && fromPet.isNotEmpty) return fromPet;
    final fromEntry = petName;
    if (fromEntry != null && fromEntry.isNotEmpty) return fromEntry;
    return '?';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final stripColor = pet != null
        ? resolvePetAccentColor(context, pet!)
        : AppColorTokens.petCarePrimary;
    final apiBaseUrl = ref.watch(apiBaseUrlProvider);

    return Container(
      width: 52,
      decoration: BoxDecoration(color: stripColor.withValues(alpha: 0.12)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: ClipOval(
              child: buildPetPhotoOrPlaceholder(
                photoPath: pet?.photoPath,
                apiBaseUrl: apiBaseUrl,
                fit: BoxFit.cover,
                semanticLabel: pet?.name,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              _displayName,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class HealthEntryFrequencyBadge extends StatelessWidget {
  const HealthEntryFrequencyBadge({
    super.key,
    required this.frequency,
    this.interval = 1,
  });

  final HealthFrequency frequency;
  final int interval;

  String _displayLabel(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (frequency == HealthFrequency.once) return l.doesNotRepeat;
    if (frequency == HealthFrequency.custom) return l.custom;
    final period = frequency.label;
    if (interval == 1) return l.everyPeriod(period);
    return l.everyNPeriods(interval, '${period}s');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _displayLabel(context),
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 10,
          color: theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
