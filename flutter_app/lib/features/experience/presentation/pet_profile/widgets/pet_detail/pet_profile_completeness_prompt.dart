import 'package:flutter/material.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pet_profile_app/core/theme/app_color_tokens.dart';
import 'package:pet_profile_app/core/utils/constants.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:pet_profile_app/features/pet_care/pet_care.dart';

/// Single compact card for missing neuter and/or microchip profile data.
class PetProfileCompletenessPrompt extends ConsumerWidget {
  const PetProfileCompletenessPrompt({
    super.key,
    required this.pet,
    required this.viewerContext,
  });

  final Pet pet;
  final PetDetailContext viewerContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final canRecord = viewerContext.can(PetDetailAction.editProfile);
    final showNeuter =
        pet.neuterStatus == profileFactStatusUnknown &&
        !pet.neuterDismissed &&
        !AppConstants.speciesWithoutNeutering.contains(pet.species);
    final showChip =
        pet.identificationStatus == profileFactStatusUnknown &&
        !pet.chipDismissed;

    if (!showNeuter && !showChip) {
      return const SizedBox.shrink();
    }

    final items = <CareCollectionInsetItem>[];
    if (showNeuter) {
      items.add(
        CareCollectionInsetItem(
          child: _PromptLine(
            key: const Key('pet_profile_prompt_neuter'),
            message: l.profilePromptNeuterMissing,
            icon: Icons.info_outline,
            recordLabel: l.profileFactCaptureRecord,
            dismissLabel: l.dismiss,
            canRecord: canRecord,
            onRecord: () => showProfileFactCaptureSheet(
              context,
              ref,
              pet: pet,
              topic: ProfileFactCaptureTopic.neuter,
            ),
            onDismiss: () =>
                NeuterReminderController(ref).dismissNeuterReminder(pet),
          ),
        ),
      );
    }
    if (showChip) {
      items.add(
        CareCollectionInsetItem(
          showDividerBefore: items.isNotEmpty,
          child: _PromptLine(
            key: const Key('pet_profile_prompt_chip'),
            message: l.profilePromptChipMissing,
            icon: Icons.memory_outlined,
            recordLabel: l.profileFactCaptureRecord,
            dismissLabel: l.dismiss,
            canRecord: canRecord,
            onRecord: () => showProfileFactCaptureSheet(
              context,
              ref,
              pet: pet,
              topic: ProfileFactCaptureTopic.chip,
            ),
            onDismiss: () =>
                ChipReminderController(ref).dismissChipReminder(pet),
          ),
        ),
      );
    }

    final semanticsLabel = [
      if (showNeuter) l.profilePromptNeuterMissing,
      if (showChip) l.profilePromptChipMissing,
    ].join('; ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: CareCollectionInsetList(
        key: const Key('pet_profile_completeness_prompt'),
        semanticLabel: semanticsLabel,
        children: items,
      ),
    );
  }
}

class _PromptLine extends StatelessWidget {
  const _PromptLine({
    super.key,
    required this.message,
    required this.icon,
    required this.recordLabel,
    required this.dismissLabel,
    required this.canRecord,
    required this.onRecord,
    required this.onDismiss,
  });

  final String message;
  final IconData icon;
  final String recordLabel;
  final String dismissLabel;
  final bool canRecord;
  final VoidCallback onRecord;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      leading: Icon(icon, color: AppColorTokens.muted, size: 20),
      title: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(color: AppColorTokens.body),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            key: const Key('profile_fact_capture_record'),
            onPressed: canRecord ? onRecord : null,
            child: Text(recordLabel),
          ),
          TextButton(onPressed: onDismiss, child: Text(dismissLabel)),
        ],
      ),
    );
  }
}
