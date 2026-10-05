import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// H.2-3: presentation → data imports may only shrink (pinned list).
void main() {
  final flutterRoot =
      Directory(p.join(Directory.current.path, 'lib')).existsSync()
      ? Directory.current.path
      : p.join(Directory.current.path, 'flutter_app');
  final presentationRoot = p.join(
    flutterRoot,
    'lib',
    'features',
    'health_tracking',
    'presentation',
  );

  const pinnedRelativePaths = {
    'controllers/health_entry_form_controller.dart',
    'controllers/health_entry_form_state.dart',
    'providers/care_item_absence_providers.dart',
    'providers/care_item_absence_resolution_sync.dart',
    'providers/pet_event_view_providers.dart',
    'widgets/entry_document_section.dart',
    'widgets/health_entry_form/health_entry_advanced_settings_section.dart',
    'widgets/health_entry_form/health_entry_document_handler.dart',
    'widgets/health_entry_form/health_entry_photos_section.dart',
    'widgets/pet_event_documents_strip.dart',
  };

  test('health presentation data imports match pinned baseline', () {
    final importers = <String>{};
    final presentationDir = Directory(presentationRoot);
    expect(presentationDir.existsSync(), isTrue);

    for (final entity in presentationDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final content = entity.readAsStringSync();
      if (!content.contains('health_tracking/data/') &&
          !content.contains('../../data/') &&
          !content.contains('../../../data/')) {
        continue;
      }
      if (!content.contains('/data/')) continue;
      final relative = p
          .relative(entity.path, from: presentationRoot)
          .replaceAll('\\', '/');
      if (content.contains('features/health_tracking/data/') ||
          RegExp(r"import\s+'(\.\./)+data/").hasMatch(content)) {
        importers.add(relative);
      }
    }

    expect(
      importers,
      pinnedRelativePaths,
      reason:
          'Unexpected presentation → data imports.\n'
          'Found: ${importers.join(', ')}\n'
          'Update the pin only when removing imports (never add).',
    );
  });
}
