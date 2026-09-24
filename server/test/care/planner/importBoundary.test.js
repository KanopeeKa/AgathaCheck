import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const plannerDir = path.join(__dirname, '../../../lib/care/planner');

const PURE_FILES = ['planAbsenceCare.js', 'candidateMoves.js'];

describe('care planner import boundary (D-ACP-008)', () => {
  for (const file of PURE_FILES) {
    it(`${file} does not import intelligence or pool`, () => {
      const source = fs.readFileSync(path.join(plannerDir, file), 'utf8');
      expect(source).not.toMatch(/care\/intelligence/);
      expect(source).not.toMatch(/\bpool\b/);
      expect(source).not.toMatch(/Date\.now\(/);
    });
  }

  it('planner sources do not import care intelligence', () => {
    const files = fs.readdirSync(plannerDir).filter((f) => f.endsWith('.js'));
    for (const file of files) {
      const source = fs.readFileSync(path.join(plannerDir, file), 'utf8');
      expect(source).not.toMatch(/care\/intelligence/);
    }
  });
});
