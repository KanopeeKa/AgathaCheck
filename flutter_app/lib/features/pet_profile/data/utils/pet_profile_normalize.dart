/// Canonical pet profile values for species and gender on the wire.

const _speciesAliases = <String, String>{
  'dog': 'Dog',
  'cat': 'Cat',
  'bird': 'Bird',
  'fish': 'Fish',
  'rabbit': 'Rabbit',
  'hamster': 'Hamster',
  'ferret': 'Ferret',
  'horse / poney': 'Horse / Poney',
  'horse / pony': 'Horse / Poney',
  'other': 'Other',
};

const _canonicalSpecies = <String>{
  'Dog',
  'Cat',
  'Bird',
  'Fish',
  'Rabbit',
  'Hamster',
  'Ferret',
  'Horse / Poney',
  'Other',
};

const _genderAliases = <String, String>{
  'male': 'Male',
  'female': 'Female',
  'm': 'Male',
  'f': 'Female',
};

const _canonicalGenders = <String>{'Male', 'Female'};

String normalizePetSpecies(String? raw) {
  if (raw == null) return '';
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  if (_canonicalSpecies.contains(trimmed)) return trimmed;
  return _speciesAliases[trimmed.toLowerCase()] ?? trimmed;
}

String? normalizePetGender(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  if (_canonicalGenders.contains(trimmed)) return trimmed;
  return _genderAliases[trimmed.toLowerCase()] ?? trimmed;
}
