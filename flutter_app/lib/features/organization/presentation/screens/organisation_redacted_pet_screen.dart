import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/presentation/widgets/pet_detail/pet_photo.dart';
import '../providers/org_provider_pet_summary.dart';
import '../widgets/org_shell_app_bar_title.dart';
import '../widgets/org_shell_scaffold.dart';

/// Minimal read-only org pet profile for view-only members (Option B).
class OrganisationRedactedPetScreen extends ConsumerWidget {
  const OrganisationRedactedPetScreen({
    super.key,
    required this.orgId,
    required this.petId,
  });

  final String orgId;
  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petAsync = ref.watch(
      orgRedactedPetProvider((orgId: orgId, petId: petId)),
    );
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;

    final title = petAsync.maybeWhen(
      data: (pet) => pet.name,
      orElse: () => l.orgPets,
    );

    return OrgShellScaffold(
      key: const Key('org_redacted_pet_screen'),
      title: title,
      orgId: orgId,
      navVariant: OrgNavTitleVariant.withOrgLogo,
      child: petAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l.errorWithMessage(error.toString()),
                style: TextStyle(color: colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (pet) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: SizedBox(
                    width: 160,
                    height: 160,
                    child: PetPhoto(pet: pet),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  pet.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _DetailRow(
                  label: l.species.replaceAll(' *', ''),
                  value: pet.species,
                ),
                if (pet.breed.isNotEmpty)
                  _DetailRow(label: l.breed, value: pet.breed),
                if (pet.ageDisplay != null)
                  _DetailRow(label: l.pdfAge, value: pet.ageDisplay!),
              ],
            ),
          ),
        ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
