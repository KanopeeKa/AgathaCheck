/**
 * Extract health_entry_form_screen private widgets (pet selector + photos).
 * Run from flutter_app/: node scripts/extract-health-entry-form-widgets.mjs
 */
import fs from 'fs';

const path =
  'lib/features/health_tracking/presentation/screens/health_entry_form_screen.dart';
const lines = fs.readFileSync(path, 'utf8').split('\n');

function slice(start, end) {
  return lines.slice(start - 1, end).join('\n');
}

const outDir = 'lib/features/health_tracking/presentation/widgets/health_entry_form';
fs.mkdirSync(outDir, { recursive: true });

fs.writeFileSync(
  `${outDir}/health_entry_pet_selector.dart`,
  `import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../pet_profile/domain/entities/pet.dart';

${slice(973, 1083).replace(/_PetSelector/g, 'HealthEntryPetSelector')}
`,
);

const photosEnd = lines.length;
fs.writeFileSync(
  `${outDir}/health_entry_photos_section.dart`,
  `import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../data/datasources/health_remote_datasource.dart';

${slice(1128, photosEnd).replace(/_PhotosSection/g, 'HealthEntryPhotosSection')}
`,
);

let screen = slice(1, 972)
  .replace(/_PetSelector/g, 'HealthEntryPetSelector')
  .replace(/_PhotosSection/g, 'HealthEntryPhotosSection');

screen = screen.replace(
  "import '../widgets/entry_due_completed_row.dart';",
  `import '../widgets/entry_due_completed_row.dart';
import '../widgets/health_entry_form/health_entry_pet_selector.dart';
import '../widgets/health_entry_form/health_entry_photos_section.dart';
`,
);

fs.writeFileSync(path, `${screen}\n`);
console.log('Extracted health entry form widgets.');
