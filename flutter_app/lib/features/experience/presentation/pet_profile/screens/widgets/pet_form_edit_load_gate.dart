import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pet_profile_app/core/widgets/app_logo_title.dart';
import 'package:pet_profile_app/features/people/people.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

/// Loads pet + vet context when editing before showing the form scaffold.
class PetFormEditLoadGate extends ConsumerWidget {
  const PetFormEditLoadGate({
    super.key,
    required this.petId,
    required this.title,
    required this.isInitialized,
    required this.onPetLoaded,
    required this.form,
  });

  final String petId;
  final String title;
  final bool isInitialized;
  final void Function(Pet pet, {String? primaryVetContactId}) onPetLoaded;
  final Widget form;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final petAsync = ref.watch(petByIdProvider(petId));

    return petAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: AppLogoTitle(title: title)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: AppLogoTitle(title: title)),
        body: Center(child: Text(l.petNotFound)),
      ),
      data: (pet) {
        if (pet != null && !isInitialized) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            PetPeople? petPeople;
            try {
              petPeople = ref.read(petPeopleProvider(pet.id)).valueOrNull;
              petPeople ??= await ref.read(petPeopleProvider(pet.id).future);
            } catch (_) {
              petPeople = null;
            }
            var selectedId = primaryVetRelationship(petPeople)?.contactId;
            if (selectedId == null && pet.vetId != null) {
              try {
                selectedId = await ref.read(
                  legacyVetContactIdProvider(pet.vetId!).future,
                );
              } catch (_) {
                selectedId = null;
              }
            }
            if (!context.mounted) return;
            onPetLoaded(pet, primaryVetContactId: selectedId);
          });
        }
        return form;
      },
    );
  }
}
