import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_color_tokens.dart';
import '../../../../../core/utils/constants.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/pet.dart';
import '../../controllers/chip_reminder_controller.dart';
import '../../controllers/neuter_reminder_controller.dart';

/// Single compact card for missing neuter and/or microchip profile data.
class PetProfileCompletenessPrompt extends ConsumerWidget {
  const PetProfileCompletenessPrompt({super.key, required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final showNeuter =
        pet.neuteredDate == null &&
        !pet.neuterDismissed &&
        !AppConstants.speciesWithoutNeutering.contains(pet.species);
    final showChip = pet.chipId.isEmpty && !pet.chipDismissed;

    if (!showNeuter && !showChip) {
      return const SizedBox.shrink();
    }

    final rows = <Widget>[];
    if (showNeuter) {
      rows.add(
        _PromptLine(
          key: const Key('pet_profile_prompt_neuter'),
          message: l.profilePromptNeuterMissing,
          icon: Icons.info_outline,
          dismissLabel: l.dismiss,
          onDismiss: () =>
              NeuterReminderController(ref).dismissNeuterReminder(pet),
        ),
      );
    }
    if (showChip) {
      if (rows.isNotEmpty) {
        rows.add(const Divider(height: 1));
      }
      rows.add(
        _PromptLine(
          key: const Key('pet_profile_prompt_chip'),
          message: l.profilePromptChipMissing,
          icon: Icons.memory_outlined,
          dismissLabel: l.dismiss,
          onDismiss: () => ChipReminderController(ref).dismissChipReminder(pet),
        ),
      );
    }

    final semanticsLabel = [
      if (showNeuter) l.profilePromptNeuterMissing,
      if (showChip) l.profilePromptChipMissing,
    ].join('; ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Semantics(
        container: true,
        label: semanticsLabel,
        child: Material(
          key: const Key('pet_profile_completeness_prompt'),
          color: AppColorTokens.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: rows,
          ),
        ),
      ),
    );
  }
}

class _PromptLine extends StatelessWidget {
  const _PromptLine({
    super.key,
    required this.message,
    required this.icon,
    required this.dismissLabel,
    required this.onDismiss,
  });

  final String message;
  final IconData icon;
  final String dismissLabel;
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
      trailing: TextButton(onPressed: onDismiss, child: Text(dismissLabel)),
    );
  }
}
