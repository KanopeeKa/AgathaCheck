import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../pet_profile/domain/entities/pet.dart';
import '../../../../pet_profile/presentation/widgets/pet_card.dart';
import '../../providers/org_permissions_providers.dart';
import '../../providers/org_provider_pet_summary.dart';

/// Profile preview: up to 12 org pets sorted by last activity (summary API).
class OrganisationProfilePets extends ConsumerWidget {
  const OrganisationProfilePets({super.key, required this.orgId});

  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(orgPetSummaryProvider(orgId));
    final permissions = ref.watch(orgEffectivePermissionsProvider(orgId));
    final canManage = permissions.maybeWhen(
      data: (keys) => keys.contains('manage_pets'),
      orElse: () => false,
    );
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final mutedStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return summaryAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (error, _) => Text(
        l.errorWithMessage(error.toString()),
        style: TextStyle(color: theme.colorScheme.error),
      ),
      data: (pets) {
        if (pets.isEmpty) {
          return Text(l.orgNoPets, style: mutedStyle);
        }
        return PetTileStrip(
          key: const Key('org_profile_pets_strip'),
          useWrap: true,
          pets: pets,
          onPetTap: (pet) => _onPetTap(context, pet, canManage),
        );
      },
    );
  }

  void _onPetTap(BuildContext context, Pet pet, bool canManage) {
    if (canManage) {
      context.push('/pet/${pet.id}');
      return;
    }
    context.push('/o/orgs/$orgId/pets/${pet.id}/redacted');
  }
}
