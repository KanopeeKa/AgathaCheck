/// Derives up to two uppercase initials for a care team / clinic display name.
///
/// Multi-word names use the first character of the first and last word
/// (e.g. "Dr. Smith" → "DS"). Single-word names with three or more characters
/// use the first and third letters (e.g. "Sevetys" → "SV").
String vetInitialsFromName(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length >= 2) {
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
  final word = parts.first;
  if (word.length >= 3) {
    return '${word[0]}${word[2]}'.toUpperCase();
  }
  if (word.length == 2) return word.toUpperCase();
  return word[0].toUpperCase();
}
