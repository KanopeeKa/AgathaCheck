import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../providers/foster_placements_providers.dart';
import '../utils/foster_placement_display.dart';
import 'pet_foster_placement/foster_placement_active_content.dart';
import 'pet_foster_placement/foster_placement_dialogs.dart';
import 'pet_foster_placement/foster_placement_not_in_foster_content.dart';

class PetFosterPlacementSection extends ConsumerWidget {
  const PetFosterPlacementSection({
    super.key,
    required this.orgId,
    required this.petId,
    required this.petName,
  });

  final String orgId;
  final String petId;
  final String petName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final placementAsync = ref.watch(
      petFosterPlacementProvider((orgId, petId)),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: placementAsync.when(
          loading: () => ExpansionTile(
            leading: Icon(Icons.home_work_outlined, color: colorScheme.primary),
            title: Text(
              l.fosterPlacement,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            children: const [
              Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
          error: (e, _) => ExpansionTile(
            leading: Icon(Icons.home_work_outlined, color: colorScheme.primary),
            title: Text(
              l.fosterPlacement,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('$e', style: TextStyle(color: colorScheme.error)),
              ),
            ],
          ),
          data: (state) {
            final placement = state.placement;
            final fosterLabel =
                placement != null &&
                    (placement.fosterName.isNotEmpty ||
                        placement.fosterEmail.isNotEmpty)
                ? (placement.fosterName.isNotEmpty
                      ? placement.fosterName
                      : placement.fosterEmail)
                : null;

            return ExpansionTile(
              leading: Icon(
                Icons.home_work_outlined,
                color: colorScheme.primary,
              ),
              title: Text(
                l.fosterPlacement,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                fosterPlacementSummary(
                  l,
                  status: state.isNotInFoster ? null : placement?.status,
                  sessionStatus: state.isNotInFoster
                      ? null
                      : placement?.sessionStatus,
                  fosterName: fosterLabel,
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: state.isNotInFoster
                      ? FosterPlacementNotInFosterContent(
                          l: l,
                          theme: theme,
                          onStart: () => FosterPlacementDialogs.showStartDialog(
                            context: context,
                            ref: ref,
                            l: l,
                            orgId: orgId,
                            petId: petId,
                            petName: petName,
                          ),
                          onDirectAdopt: () =>
                              FosterPlacementDialogs.showDirectAdoptDialog(
                                context: context,
                                ref: ref,
                                l: l,
                                orgId: orgId,
                                petId: petId,
                                petName: petName,
                              ),
                        )
                      : FosterPlacementActiveContent(
                          l: l,
                          theme: theme,
                          placement: placement!,
                          onStartAdoption: () =>
                              FosterPlacementDialogs.showStartAdoptionDialog(
                                context: context,
                                ref: ref,
                                l: l,
                                orgId: orgId,
                                petId: petId,
                                petName: petName,
                                placement: placement,
                              ),
                          onEnd: () => FosterPlacementDialogs.confirmEnd(
                            context: context,
                            ref: ref,
                            l: l,
                            orgId: orgId,
                            petId: petId,
                            petName: petName,
                            placement: placement,
                          ),
                          onCompleteConditions: () =>
                              FosterPlacementDialogs.completeConditions(
                                context: context,
                                ref: ref,
                                l: l,
                                orgId: orgId,
                                petId: petId,
                                placement: placement,
                              ),
                          onCancelAdoption: () =>
                              FosterPlacementDialogs.confirmCancelAdoption(
                                context: context,
                                ref: ref,
                                l: l,
                                orgId: orgId,
                                petId: petId,
                                petName: petName,
                                placement: placement,
                              ),
                          sessionAction: placement.isSessionOpen
                              ? TextButton.icon(
                                  key: const Key('open_fostering_session_button'),
                                  onPressed: () => context.push(
                                    '/o/orgs/$orgId/placements/${placement.id}/session',
                                  ),
                                  icon: const Icon(Icons.open_in_new, size: 18),
                                  label: Text(l.fosteringSessionManage),
                                )
                              : null,
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
