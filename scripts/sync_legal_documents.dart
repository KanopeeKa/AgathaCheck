// ignore_for_file: avoid_print
//
// Copies legal markdown from regulatory/legal/ into flutter_app/assets/legal/,
// replacing date placeholders and internal link stubs.
//
// Usage: dart run scripts/sync_legal_documents.dart [--date=YYYY-MM-DD]

import 'dart:io';

void main(List<String> args) {
  final date = _parseDate(args) ?? DateTime.now();
  final enDate = _formatEnglishDate(date);
  final frDate = _formatFrenchDate(date);

  final pairs = <({String source, String target})>[
    (
      source: 'regulatory/legal/en/terms-of-use.md',
      target: 'flutter_app/assets/legal/en/terms-of-use.md',
    ),
    (
      source: 'regulatory/legal/en/privacy-notice.md',
      target: 'flutter_app/assets/legal/en/privacy-notice.md',
    ),
    (
      source: 'regulatory/legal/en/legal-notice.md',
      target: 'flutter_app/assets/legal/en/legal-notice.md',
    ),
    (
      source: 'regulatory/legal/en/dpa.md',
      target: 'flutter_app/assets/legal/en/dpa.md',
    ),
    (
      source: 'regulatory/legal/fr/conditions-dutilisation.md',
      target: 'flutter_app/assets/legal/fr/conditions-dutilisation.md',
    ),
    (
      source: 'regulatory/legal/fr/politique-de-confidentialite.md',
      target: 'flutter_app/assets/legal/fr/politique-de-confidentialite.md',
    ),
    (
      source: 'regulatory/legal/fr/mentions-legales.md',
      target: 'flutter_app/assets/legal/fr/mentions-legales.md',
    ),
    (
      source: 'regulatory/legal/fr/dpa.md',
      target: 'flutter_app/assets/legal/fr/dpa.md',
    ),
  ];

  for (final pair in pairs) {
    final sourceFile = File(pair.source);
    if (!sourceFile.existsSync()) {
      stderr.writeln('Missing source file: ${pair.source}');
      exitCode = 1;
      continue;
    }

    var content = sourceFile.readAsStringSync();
    final isFrench = pair.source.contains('/fr/');
    content = _transformContent(content, isFrench: isFrench, enDate: enDate, frDate: frDate);

    final targetFile = File(pair.target);
    targetFile.parent.createSync(recursive: true);
    targetFile.writeAsStringSync(content);
    print('Wrote ${pair.target}');
  }

  final manifestPath = 'flutter_app/pubspec.yaml';
  final manifest = File(manifestPath).readAsStringSync();
  if (!manifest.contains('assets/legal/')) {
    stderr.writeln(
      'Warning: flutter_app/pubspec.yaml does not list assets/legal/. '
      'Ensure legal assets are registered.',
    );
  }
}

DateTime? _parseDate(List<String> args) {
  for (final arg in args) {
    if (arg.startsWith('--date=')) {
      return DateTime.parse(arg.substring('--date='.length));
    }
  }
  return null;
}

String _formatEnglishDate(DateTime date) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String _formatFrenchDate(DateTime date) {
  const months = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String _transformContent(
  String content, {
  required bool isFrench,
  required String enDate,
  required String frDate,
}) {
  const privacyRoute = '/legal/privacy-notice';

  var transformed = content
      .replaceAll('[insert date]', enDate)
      .replaceAll('[à compléter]', frDate)
      .replaceAll('(link-to-privacy-notice)', '($privacyRoute)')
      .replaceAll('(lien-vers-la-politique)', '($privacyRoute)')
      .replaceAll('(link)', '($privacyRoute)')
      .replaceAll('(lien)', '($privacyRoute)')
      .replaceAll(
        '[link to sub-processor list or Privacy Notice section]',
        '[Privacy Notice]($privacyRoute)',
      )
      .replaceAll(
        '[lien vers la liste des sous-traitants ou section de la Politique de confidentialité]',
        '[Politique de confidentialité]($privacyRoute)',
      );

  if (isFrench) {
    transformed = transformed.replaceAll('[insert date]', frDate);
  } else {
    transformed = transformed.replaceAll('[à compléter]', enDate);
  }

  return transformed;
}
