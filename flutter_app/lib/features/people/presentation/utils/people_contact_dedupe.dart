import '../../domain/entities/people_contact.dart';

List<PeopleContact> findDuplicateContacts({
  required List<PeopleContact> directory,
  required String name,
  String? phone,
  String? email,
  int limit = 3,
}) {
  final nameTrim = name.trim().toLowerCase();
  if (nameTrim.length < 2 &&
      (phone?.trim().isEmpty ?? true) &&
      (email?.trim().isEmpty ?? true)) {
    return const [];
  }

  final phoneDigits = _digitsOnly(phone);
  final emailNorm = email?.trim().toLowerCase() ?? '';

  final matches = <PeopleContact>[];
  for (final c in directory) {
    var score = 0;
    if (nameTrim.length >= 2 &&
        c.name.toLowerCase().contains(nameTrim)) {
      score += 2;
    }
    if (phoneDigits.isNotEmpty &&
        _digitsOnly(c.phone) == phoneDigits) {
      score += 3;
    }
    if (emailNorm.isNotEmpty &&
        (c.email?.trim().toLowerCase() ?? '') == emailNorm) {
      score += 3;
    }
    if (score >= 2) matches.add(c);
  }

  matches.sort((a, b) => a.name.compareTo(b.name));
  return matches.take(limit).toList();
}

String _digitsOnly(String? value) {
  if (value == null) return '';
  return value.replaceAll(RegExp(r'\D'), '');
}
