bool _isVowel(String character) {
  return RegExp(
    r'[aeiouyàâäáãåæèéêëìíîïòóôöõùúûüýÿ]',
    caseSensitive: false,
  ).hasMatch(character);
}

const _trailingNoiseWords = {
  'center',
  'centre',
  'clinic',
  'hospital',
  'practice',
};

const _leadingNoiseWords = {'dr', 'the'};

const _fillerWords = {'and', 'de', 'des', 'du', 'la', 'le', 'les', 'of', 'the'};

/// Generates a two-character monogram for a veterinary clinic / care team name.
///
/// Multi-word names use the first letters of the first two significant words.
/// Single-word names use the first letter plus the first consonant that follows.
String careTeamInitialsFromName(String name) {
  final cleaned = name.replaceAll(RegExp(r'[^\w\s]'), ' ').trim();
  if (cleaned.isEmpty) return '?';

  var parts = cleaned
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: true);

  while (parts.isNotEmpty &&
      _trailingNoiseWords.contains(parts.last.toLowerCase())) {
    parts.removeLast();
  }

  if (parts.isNotEmpty &&
      _leadingNoiseWords.contains(parts.first.toLowerCase())) {
    parts.removeAt(0);
  }

  parts = parts
      .where((part) => !_fillerWords.contains(part.toLowerCase()))
      .toList(growable: false);

  if (parts.isEmpty) {
    final fallback = name.replaceAll(RegExp(r'[^\w]'), '').toUpperCase();
    if (fallback.isEmpty) return '?';
    return fallback.length >= 2 ? fallback.substring(0, 2) : fallback;
  }

  if (parts.length >= 2) {
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  final word = parts.first;
  final first = word[0].toUpperCase();
  for (var index = 1; index < word.length; index++) {
    final character = word[index];
    if (!_isVowel(character)) {
      return '$first${character.toUpperCase()}';
    }
  }

  if (word.length >= 2) {
    return '${first}${word[1].toUpperCase()}';
  }
  return first;
}
