/**
 * Extract pet_list_screen private widgets into widgets/pet_list/
 * Run: node scripts/extract-pet-list-widgets.mjs (from flutter_app/)
 */
import fs from 'fs';

const src = fs.readFileSync(
  'lib/features/pet_profile/presentation/screens/pet_list_screen.dart',
  'utf8',
);
const lines = src.split('\n');

function slice(start, end) {
  return lines.slice(start - 1, end).join('\n');
}

const outDir = 'lib/features/pet_profile/presentation/widgets/pet_list';
fs.mkdirSync(outDir, { recursive: true });

const sectionHeader = `import 'package:flutter/material.dart';

${slice(605, 651).replace(/_SectionHeader/g, 'PetListSectionHeader')}
`;

const dueEvents = `import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/utils/constants.dart';
import '../../../../health_tracking/domain/entities/health_entry.dart';
import '../../../../health_tracking/presentation/providers/health_providers.dart';
import '../../../domain/entities/pet.dart';

${slice(360, 603).replace(/_DueEventsSection/g, 'DueEventsSection')}
`;

const pendingShares = `import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/utils/constants.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../organization/presentation/providers/organization_providers.dart';
import '../../../../sharing/presentation/providers/sharing_providers.dart';

${slice(653, 899)
  .replace(/_PendingSharesSection/g, 'PendingSharesSection')
  .replace(/_PendingShareCard/g, 'PendingShareCard')}
`;

const pendingFoster = `import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../organization/domain/entities/foster_placement.dart';
import '../../../../organization/presentation/providers/foster_placements_providers.dart';

${slice(901, 1048)
  .replace(/_PendingFosterPlacementsSection/g, 'PendingFosterPlacementsSection')
  .replace(/_PendingFosterPlacementCard/g, 'PendingFosterPlacementCard')}
`;

const pendingAdoption = `import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../organization/domain/entities/foster_placement.dart';
import '../../../../organization/presentation/providers/foster_placements_providers.dart';

${slice(1050, 1182)
  .replace(/_PendingAdoptionPlacementsSection/g, 'PendingAdoptionPlacementsSection')
  .replace(/_PendingAdoptionPlacementCard/g, 'PendingAdoptionPlacementCard')}
`;

fs.writeFileSync(`${outDir}/pet_list_section_header.dart`, sectionHeader);
fs.writeFileSync(`${outDir}/due_events_section.dart`, dueEvents);
fs.writeFileSync(`${outDir}/pending_shares_section.dart`, pendingShares);
fs.writeFileSync(`${outDir}/pending_foster_placements_section.dart`, pendingFoster);
fs.writeFileSync(`${outDir}/pending_adoption_placements_section.dart`, pendingAdoption);

// Trim pet_list_screen: keep lines 1-358 only, add imports
const screenHeader = lines.slice(0, 26).join('\n');
const screenBody = lines.slice(26, 293).join('\n'); // through OrgFilterChips usage
const screenRest = lines.slice(293, 358).join('\n');

const newScreen = `${screenHeader}
import '../widgets/pet_list/due_events_section.dart';
import '../widgets/pet_list/pending_adoption_placements_section.dart';
import '../widgets/pet_list/pending_foster_placements_section.dart';
import '../widgets/pet_list/pending_shares_section.dart';
import '../widgets/pet_list/pet_list_section_header.dart';
${lines.slice(26, 27).join('\n') ? '' : ''}${screenBody.replace(/_SectionHeader/g, 'PetListSectionHeader').replace(/_DueEventsSection/g, 'DueEventsSection').replace(/_PendingSharesSection/g, 'PendingSharesSection').replace(/_PendingFosterPlacementsSection/g, 'PendingFosterPlacementsSection').replace(/_PendingAdoptionPlacementsSection/g, 'PendingAdoptionPlacementsSection')}
`;

// Simpler: replace in full file up to line 358
let screen = slice(1, 358)
  .replace(/_SectionHeader/g, 'PetListSectionHeader')
  .replace(/_DueEventsSection/g, 'DueEventsSection')
  .replace(/_PendingSharesSection/g, 'PendingSharesSection')
  .replace(/_PendingFosterPlacementsSection/g, 'PendingFosterPlacementsSection')
  .replace(/_PendingAdoptionPlacementsSection/g, 'PendingAdoptionPlacementsSection');

const importBlock = `import '../widgets/pet_list/due_events_section.dart';
import '../widgets/pet_list/pending_adoption_placements_section.dart';
import '../widgets/pet_list/pending_foster_placements_section.dart';
import '../widgets/pet_list/pending_shares_section.dart';
import '../widgets/pet_list/pet_list_section_header.dart';
`;

screen = screen.replace(
  "import '../widgets/passed_away_pets_section.dart';",
  `import '../widgets/passed_away_pets_section.dart';\n${importBlock}`,
);

fs.writeFileSync(
  'lib/features/pet_profile/presentation/screens/pet_list_screen.dart',
  screen + '\n',
);

console.log('Extracted pet_list widgets.');
