/// Supported species for structured Pet Care intelligence (cats and dogs).
enum PetSpecies {
  cat,
  dog,
}

/// Resolves free-text [Pet.species] to a supported species when possible.
PetSpecies? resolveSupportedSpecies(String raw) {
  final normalized = raw.trim().toLowerCase();
  if (normalized.isEmpty) return null;
  if (normalized == 'cat' || normalized == 'cats') return PetSpecies.cat;
  if (normalized == 'dog' || normalized == 'dogs') return PetSpecies.dog;
  return null;
}

extension PetSpeciesWire on PetSpecies {
  String get wireValue => name;
}
