import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Temporary allowlist until people-client-integration-7f3b migrates callers.
const _externalAllowlist = <String>{
  'flutter_app/lib/core/router/experience_routes.dart',
  'flutter_app/lib/core/router/vet_routes.dart',
  'flutter_app/lib/features/pet_profile/presentation/providers/pet_vet_contacts_provider.dart',
  'flutter_app/lib/features/pet_profile/presentation/widgets/pet_form/pet_form_vet_section.dart',
  'flutter_app/lib/features/health_tracking/presentation/widgets/care_provider_field.dart',
  'flutter_app/lib/features/pet_care/context/presentation/widgets/away_plan_carer_edit_dialog.dart',
};

void main() {
  test('outside people/, only people.dart may import features/people/*', () {
    final repoRoot = p.normalize(p.join(Directory.current.path, '..'));
    final libRoot = p.join(repoRoot, 'flutter_app/lib');
    final violations = <String>[];

    for (final entity in Directory(libRoot).listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final rel = p.relative(entity.path, from: repoRoot).replaceAll('\\', '/');
      if (rel.startsWith('flutter_app/lib/features/people/')) continue;

      final content = entity.readAsStringSync();
      final importRe = RegExp(
        r'''(?:import|export)\s+['"]([^'"]*features/people/[^'"]+)['"]''',
      );
      for (final match in importRe.allMatches(content)) {
        final target = match.group(1)!;
        if (target.endsWith('people.dart')) continue;
        if (_externalAllowlist.contains(rel)) continue;
        violations.add('$rel → $target');
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Import people.dart instead:\n${violations.join('\n')}',
    );
  });

  test('presentation never imports forbidden data layers', () {
    const forbidden = [
      'features/people/data/datasources/',
      'features/people/data/dto/',
      'features/people/data/people_api.dart',
      'features/people/data/people_repository_impl.dart',
      'features/people/data/households_api.dart',
      'features/people/data/people_api_exception.dart',
    ];
    final repoRoot = p.normalize(p.join(Directory.current.path, '..'));
    final presentationRoot = p.join(
      repoRoot,
      'flutter_app/lib/features/people/presentation',
    );
    final violations = <String>[];

    for (final entity in Directory(
      presentationRoot,
    ).listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final rel = p.relative(entity.path, from: repoRoot).replaceAll('\\', '/');
      final content = entity.readAsStringSync();
      for (final banned in forbidden) {
        if (content.contains(banned)) {
          violations.add('$rel → $banned');
        }
      }
    }

    expect(violations, isEmpty);
  });
}
