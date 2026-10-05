import '../../domain/entities/contact_summary.dart';

List<ContactSummary> findAddPersonDuplicates({
  required List<ContactSummary> roster,
  required String name,
  String? phone,
  String? email,
  int limit = 3,
}) {
  final nameTrim = name.trim().toLowerCase();
  final phoneDigits = _digitsOnly(phone);
  final emailNorm = email?.trim().toLowerCase() ?? '';

  if (nameTrim.length < 2 && phoneDigits.isEmpty && emailNorm.isEmpty) {
    return const [];
  }

  final matches = <ContactSummary>[];
  for (final c in roster) {
    if (c.isInactive) continue;
    var score = 0;
    if (nameTrim.length >= 2 && c.name.toLowerCase().contains(nameTrim)) {
      score += 2;
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
