import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/router/shell_return_navigation.dart';
import '../../../../../l10n/app_localizations.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';
import '../away_plan_copy.dart';
import '../providers/care_context_providers.dart';

class AbsencePetPill extends ConsumerWidget {
  const AbsencePetPill({
    super.key,
    required this.absenceId,
    required this.petId,
    required this.petName,
  });

  final String absenceId;
  final String petId;
  final String petName;

  static const _kMinTouchTarget = 48.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final statusAsync = ref.watch(
      perPetAwayPlanStatusProvider((absenceId: absenceId, petId: petId)),
    );
    final pet = ref.watch(petByIdProvider(petId)).valueOrNull;
    final statusLine = statusAsync.maybeWhen(
      data: (status) => AwayPlanCopy.petPillStatusLine(l, status),
      orElse: () => null,
    );
    final actionLabel = l.careContextSeePetAwayPlan(petName);

    return Semantics(
      identifier: 'absence_pet_pill_$petId',
      button: true,
      label: statusLine == null ? actionLabel : '$actionLabel. $statusLine',
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          key: Key('absence_pet_pill_$petId'),
          borderRadius: BorderRadius.circular(12),
          onTap: () => openPetAwayPlan(context, absenceId, petId),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: _kMinTouchTarget),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CareEventRowPetAvatar(pet: pet, petName: petName),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          petName,
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          actionLabel,
                          style: theme.textTheme.bodyMedium,
                        ),
                        if (statusLine != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            statusLine,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
