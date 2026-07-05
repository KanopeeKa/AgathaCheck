/**
 * Split organizations.test.js → test/organizations/*.test.js
 * Run from server/: node scripts/split-organizations-tests.mjs
 */
import fs from 'fs';

const src = fs.readFileSync('test/organizations.test.js', 'utf8');
const lines = src.split('\n');

const helpers = lines.slice(0, 250).join('\n').replace(
  /^function makeOrgRow/m,
  'export function makeOrgRow',
).replace(
  /^function buildMockPool/m,
  'export function buildMockPool',
);

const helperImports = `import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../../bin/server.js';
import { buildMockPool, makeOrgRow } from './helpers.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const userId = 'test-user-id';
const token = jwt.sign({ id: userId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '1h' });
const orgId = 'org-1';
const memberId = 'member-user-id';
const inviteId = 'invite-1';
`;

fs.mkdirSync('test/organizations', { recursive: true });
fs.writeFileSync('test/organizations/helpers.js', helpers);

const blocks = [
  { file: 'authGuard.test.js', start: 259, end: 296, title: 'Auth guard - 401 without token' },
  { file: 'core.test.js', start: 298, end: 530, title: 'Organizations core CRUD' },
  { file: 'members.test.js', start: 532, end: 699, title: 'Organization members & invites' },
  { file: 'pets.test.js', start: 651, end: 699, title: 'Organization pets' },
  { file: 'authorization.test.js', start: 701, end: 836, title: 'Authorization guards' },
  { file: 'fosterParents.test.js', start: 838, end: 1000, title: 'Foster parents directory' },
  { file: 'people.test.js', start: 1002, end: 1181, title: 'People directory' },
  { file: 'placements.test.js', start: 1183, end: 1278, title: 'Foster placements & transfer' },
  { file: 'edgeCases.test.js', start: 1280, end: 1344, title: 'Error handling & field mapping' },
];

// Fix overlapping blocks - pets is inside members range. Let me use precise ranges:
const preciseBlocks = [
  { file: 'authGuard.test.js', start: 259, end: 296 },
  { file: 'core.test.js', start: 298, end: 530 },
  { file: 'members.test.js', start: 532, end: 649 },
  { file: 'pets.test.js', start: 651, end: 699 },
  { file: 'authorization.test.js', start: 701, end: 836 },
  { file: 'fosterParents.test.js', start: 838, end: 1000 },
  { file: 'people.test.js', start: 1002, end: 1181 },
  { file: 'placements.test.js', start: 1183, end: 1278 },
  { file: 'edgeCases.test.js', start: 1280, end: lines.length - 1 },
];

for (const block of preciseBlocks) {
  let body = lines.slice(block.start - 1, block.end).join('\n');
  body = body.replace(/^  describe/gm, 'describe');
  const content = `${helperImports}

describe('Organizations API', () => {
  let app;

  beforeAll(() => {
    app = createApp(buildMockPool());
  });

${body.split('\n').map((l) => `  ${l}`).join('\n')}
});
`;
  fs.writeFileSync(`test/organizations/${block.file}`, content);
}

fs.unlinkSync('test/organizations.test.js');
console.log('Test split complete. Removed monolithic organizations.test.js');
