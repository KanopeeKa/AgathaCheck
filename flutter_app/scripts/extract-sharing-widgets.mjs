/**
 * Extract sharing_section private widgets.
 * Run from flutter_app/: node scripts/extract-sharing-widgets.mjs
 */
import fs from 'fs';

const path =
  'lib/features/pet_profile/presentation/screens/widgets/sharing_section.dart';
const lines = fs.readFileSync(path, 'utf8').split('\n');

function slice(start, end) {
  return lines.slice(start - 1, end).join('\n');
}

const outDir = 'lib/features/pet_profile/presentation/widgets/sharing';
fs.mkdirSync(outDir, { recursive: true });

const commonImports = `import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../sharing/domain/entities/pet_access.dart';
import '../../../../sharing/domain/entities/share_link.dart';
import '../../../../sharing/presentation/providers/sharing_providers.dart';
import '../../../domain/entities/pet.dart';
`;

const replacements = [
  ['_FollowerSharingContent', 'FollowerSharingContent'],
  ['_FosterSharingContent', 'FosterSharingContent'],
  ['_OwnerSharingContent', 'OwnerSharingContent'],
  ['_ShareLinkTile', 'ShareLinkTile'],
  ['_AccessTile', 'AccessTile'],
];

function rename(body) {
  let out = body;
  for (const [from, to] of replacements) {
    out = out.replaceAll(from, to);
  }
  return out;
}

const files = [
  { name: 'follower_sharing_content.dart', start: 130, end: 196 },
  { name: 'foster_sharing_content.dart', start: 198, end: 297 },
  { name: 'owner_sharing_content.dart', start: 299, end: 528 },
  { name: 'share_link_tile.dart', start: 530, end: 629 },
  { name: 'access_tile.dart', start: 631, end: lines.length },
];

for (const f of files) {
  fs.writeFileSync(
    `${outDir}/${f.name}`,
    `${commonImports}\n${rename(slice(f.start, f.end))}\n`,
  );
}

let screen = rename(slice(1, 128));
screen = screen.replace(
  "import '../../../../../l10n/app_localizations.dart';",
  `import '../../../../../l10n/app_localizations.dart';
import '../../widgets/sharing/access_tile.dart';
import '../../widgets/sharing/follower_sharing_content.dart';
import '../../widgets/sharing/foster_sharing_content.dart';
import '../../widgets/sharing/owner_sharing_content.dart';
import '../../widgets/sharing/share_link_tile.dart';
`,
);

fs.writeFileSync(path, `${screen}\n`);
console.log('Extracted sharing widgets.');
