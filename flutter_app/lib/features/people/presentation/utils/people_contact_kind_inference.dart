/// Infer person vs organisation without asking the user (mirrors server rules).
String inferPeopleContactKind({
  required String name,
  required Set<String> roles,
}) {
  if (roles.contains('boarding')) return 'organisation';
  if (roles.contains('sitter') || roles.contains('walker')) return 'person';

  final lower = name.toLowerCase();
  const keywords = [
    'clinic',
    'clinique',
    'vets',
    'veterinary',
    'hospital',
    'kennel',
    'boarding',
    'pension',
    'cabinet',
    'salon',
    'ltd',
    'limited',
  ];
  for (final word in keywords) {
    if (lower.contains(word)) return 'organisation';
  }
  return 'person';
}
