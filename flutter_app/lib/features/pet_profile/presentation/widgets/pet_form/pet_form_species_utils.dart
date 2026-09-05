import '../../../../../core/utils/constants.dart';
import '../../../data/utils/pet_profile_normalize.dart';

const primaryPetSpecies = ['Dog', 'Cat'];

String normalizePetFormSpecies(String? raw) => normalizePetSpecies(raw);

bool isPrimaryPetSpecies(String species) =>
    primaryPetSpecies.contains(species);

List<String> morePetSpeciesOptions() => AppConstants.species
    .where((species) => !primaryPetSpecies.contains(species))
    .toList();
