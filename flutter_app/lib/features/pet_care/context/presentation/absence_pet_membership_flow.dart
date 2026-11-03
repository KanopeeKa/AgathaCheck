import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/pet_profile.dart';
import '../data/datasources/care_context_remote_datasource.dart';
import '../domain/entities/planned_absence.dart';
import 'providers/care_context_providers.dart';

/// Add/remove pets on a saved absence (declarer-only writes).
class AbsencePetMembershipFlow {
  const AbsencePetMembershipFlow._();

  static Future<void> showAddPetSheet({
    required BuildContext context,
    required WidgetRef ref,
    required PlannedAbsence absence,
    required List<Pet> allPets,
  }) async {
    final l = AppLocalizations.of(context)!;
    final onAbsence = absence.petIds.toSet();
    final candidates = allPets
        .where((pet) => !pet.passedAway && !onAbsence.contains(pet.id))
        .toList(growable: false)
      ..sort((a, b) => a.name.compareTo(b.name));
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.careContextAddPetNoneAvailable)),
      );
      return;
    }

    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Text(
                  l.careContextAddPetToAbsenceTitle,
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
              for (final pet in candidates)
                ListTile(
                  key: Key('add_pet_to_absence_${pet.id}'),
                  title: Text(pet.name),
                  subtitle: Text(pet.species),
                  onTap: () => Navigator.of(ctx).pop(pet.id),
                ),
            ],
          ),
        );
      },
    );
    if (picked == null || !context.mounted) return;
    await _addPet(
      context: context,
      ref: ref,
      absenceId: absence.id,
      petId: picked,
      allPets: allPets,
    );
  }

  static Future<void> _addPet({
    required BuildContext context,
    required WidgetRef ref,
    required String absenceId,
    required String petId,
    required List<Pet> allPets,
    bool confirmGuestAccessWiden = false,
  }) async {
    final l = AppLocalizations.of(context)!;
    try {
      final result = await ref
          .read(careContextRepositoryProvider)
          .addPetToPlannedAbsence(
            absenceId: absenceId,
            petId: petId,
            confirmGuestAccessWiden: confirmGuestAccessWiden,
          );
      ref.invalidate(plannedAbsencesListProvider);
      ref.invalidate(plannedAbsenceDetailProvider(absenceId));
      ref.invalidate(awayPlanReadinessProvider(absenceId));
      ref.invalidate(petPlannedAbsencesProvider(petId));
      if (!context.mounted) return;
      _showOverlapWarnings(context, l, result.overlapWarnings, allPets);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.careContextAddPetSuccess)),
      );
    } on CareContextApiException catch (e) {
      if (!context.mounted) return;
      if (e.code == 'guest_access_widen_required') {
        final ok = await _confirmGuestWiden(context, l);
        if (ok && context.mounted) {
          await _addPet(
            context: context,
            ref: ref,
            absenceId: absenceId,
            petId: petId,
            allPets: allPets,
            confirmGuestAccessWiden: true,
          );
        }
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.careContextAddPetFailed)),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.careContextAddPetFailed)),
      );
    }
  }

  static Future<void> confirmAndRemovePet({
    required BuildContext context,
    required WidgetRef ref,
    required PlannedAbsence absence,
    required String petId,
    required String petName,
  }) async {
    final l = AppLocalizations.of(context)!;
    final isLastPet = absence.petIds.length <= 1;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.careContextRemovePetConfirmTitle(petName)),
        content: Text(
          isLastPet
              ? l.careContextRemovePetLastConfirmBody(petName)
              : l.careContextRemovePetConfirmBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            key: const Key('remove_pet_from_absence_confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.careContextRemovePetConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final result = await ref
          .read(careContextRepositoryProvider)
          .removePetFromPlannedAbsence(
            absenceId: absence.id,
            petId: petId,
            confirmDeleteAbsence: isLastPet,
          );
      ref.invalidate(plannedAbsencesListProvider);
      ref.invalidate(petPlannedAbsencesProvider(petId));
      if (!context.mounted) return;
      if (result.absenceDeleted) {
        context.go('/pc/away');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.careContextRemovePetAbsenceDeleted)),
        );
        return;
      }
      ref.invalidate(plannedAbsenceDetailProvider(absence.id));
      ref.invalidate(awayPlanReadinessProvider(absence.id));
      context.goNamed(
        'petCarePlannedAbsenceDetail',
        pathParameters: {'id': absence.id},
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.careContextRemovePetSuccess(petName))),
      );
    } on CareContextApiException catch (e) {
      if (!context.mounted) return;
      if (e.code == 'last_pet_removal_requires_confirm') {
        await confirmAndRemovePet(
          context: context,
          ref: ref,
          absence: absence,
          petId: petId,
          petName: petName,
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.careContextRemovePetFailed)),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.careContextRemovePetFailed)),
      );
    }
  }

  static Future<bool> _confirmGuestWiden(
    BuildContext context,
    AppLocalizations l,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.careContextAwayGuestWidenConfirmTitle),
        content: Text(l.careContextAwayGuestWidenConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.careContextAwayContinue),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  static void _showOverlapWarnings(
    BuildContext context,
    AppLocalizations l,
    List<PlannedAbsenceOverlapWarning> warnings,
    List<Pet> allPets,
  ) {
    if (warnings.isEmpty) return;
    final namesById = {for (final pet in allPets) pet.id: pet.name};
    for (final warning in warnings) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l.careContextAwayOverlapWarning(
              namesById[warning.petId] ?? l.petLabel,
              warning.conflictingStartsOn,
              warning.conflictingEndsOn,
            ),
          ),
        ),
      );
    }
  }
}
