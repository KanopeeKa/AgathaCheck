/**
 * Shared Flutter domain coverage universe (J.1) — eligible paths, lcov parsing,
 * and source line heuristics when a file is absent from lcov.
 */
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const GEN_SUFFIX = ['.g.dart', '.freezed.dart', '.mocks.dart', '.gen.dart'];

function loadFrozenManifest(repoRoot) {
  const manifestPath = path.join(
    repoRoot,
    'docs/engineering/frozen-domains/manifest.json',
  );
  if (!fs.existsSync(manifestPath)) {
    return { sourceRoots: [], activeSurfacesToRemove: [] };
  }
  return JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
}

function frozenDomainSourcePrefixes(manifest) {
  const roots = manifest.sourceRoots || [];
  return roots.map((root) => {
    const normalized = root.replace(/^flutter_app\//, '');
    return `lib/${normalized.replace(/^lib\//, '')}`;
  });
}

function isFrozenDomainSource(file, frozenPrefixes) {
  return frozenPrefixes.some(
    (prefix) => file === prefix || file.startsWith(`${prefix}/`),
  );
}

function isGeneratedDomainSource(file) {
  return GEN_SUFFIX.some((suffix) => file.endsWith(suffix));
}

function isUnderFeaturesDomain(file) {
  return /^lib\/features\/[^/]+\/domain\//.test(file);
}

/**
 * Eligible domain dart files: active features per manifest, not generated, not frozen.
 * @param {string} flutterRoot absolute path to flutter_app
 */
function listEligibleDomainSources(flutterRoot) {
  const repoRoot = path.resolve(flutterRoot, '..');
  const manifest = loadFrozenManifest(repoRoot);
  const frozenPrefixes = frozenDomainSourcePrefixes(manifest);
  const activeSurfaces = new Set(
    (manifest.activeSurfacesToRemove || []).map((p) =>
      p.replace(/^flutter_app\//, ''),
    ),
  );

  const output = execSync('find lib -path "*/domain/*.dart"', {
    cwd: flutterRoot,
    encoding: 'utf8',
  });

  return output
    .trim()
    .split('\n')
    .filter(Boolean)
    .filter((file) => isUnderFeaturesDomain(file))
    .filter((file) => !isFrozenDomainSource(file, frozenPrefixes))
    .filter((file) => !activeSurfaces.has(file))
    .filter((file) => !isGeneratedDomainSource(file))
    .sort();
}

function libPathToPackageUri(libPath) {
  const withoutLib = libPath.replace(/^lib\//, '');
  return `package:pet_profile_app/${withoutLib}`;
}

function normalizeLcovPath(sf) {
  const marker = 'lib/';
  const idx = sf.lastIndexOf(marker);
  return idx >= 0 ? sf.slice(idx) : sf.replace(/^\.\//, '');
}

function parseLcov(text) {
  const records = new Map();

  for (const rec of text.split('end_of_record')) {
    const sfMatch = rec.match(/^SF:(.+)$/m);
    if (!sfMatch) continue;

    const sf = normalizeLcovPath(sfMatch[1].trim());
    let total = 0;
    let hit = 0;

    for (const line of rec.split('\n')) {
      if (!line.startsWith('DA:')) continue;
      const [, hits] = line.slice(3).split(',');
      total += 1;
      if (Number(hits) > 0) hit += 1;
    }

    records.set(sf, { total, hit });
  }

  return records;
}

/** Heuristic executable lines when lcov has no DA entries for a source file. */
function countHeuristicExecutableLines(absPath) {
  const text = fs.readFileSync(absPath, 'utf8');
  let total = 0;
  let block = false;
  for (const raw of text.split('\n')) {
    let s = raw.trim();
    if (!s) continue;
    while (s) {
      if (block) {
        const j = s.indexOf('*/');
        if (j < 0) break;
        block = false;
        s = s.slice(j + 2).trim();
        continue;
      }
      if (s.startsWith('/*')) {
        block = true;
        s = s.slice(2).trim();
        continue;
      }
      if (
        s.startsWith('//') ||
        s.startsWith('*') ||
        s.startsWith('import ') ||
        s.startsWith('export ') ||
        s.startsWith('part ') ||
        s.startsWith('library') ||
        s.startsWith('@')
      ) {
        break;
      }
      total += 1;
      break;
    }
  }
  return total;
}

/**
 * Aggregate domain coverage; files missing from lcov count as 0% (J.1-1).
 */
function measureDomainCoverage({ flutterRoot, lcovText, domainFiles, threshold }) {
  const records = parseLcov(lcovText);
  let measuredFiles = 0;
  let totalLines = 0;
  let hitLines = 0;
  const uncovered = [];
  const missingFromLcov = [];

  for (const file of domainFiles) {
    const record = records.get(file);
    let total = 0;
    let hit = 0;

    if (record && record.total > 0) {
      total = record.total;
      hit = record.hit;
    } else {
      const abs = path.join(flutterRoot, file);
      if (!fs.existsSync(abs)) continue;
      total = countHeuristicExecutableLines(abs);
      if (total === 0) continue;
      missingFromLcov.push(file);
    }

    measuredFiles += 1;
    totalLines += total;
    hitLines += hit;

    const pct = total > 0 ? (100 * hit) / total : 0;
    if (threshold != null && pct + 1e-9 < threshold) {
      uncovered.push({ file, pct, hit, total });
    }
  }

  const overallPct = totalLines > 0 ? (100 * hitLines) / totalLines : 0;
  return {
    measuredFiles,
    totalLines,
    hitLines,
    overallPct,
    uncovered,
    missingFromLcov,
  };
}

module.exports = {
  GEN_SUFFIX,
  frozenDomainSourcePrefixes,
  isFrozenDomainSource,
  isGeneratedDomainSource,
  listEligibleDomainSources,
  libPathToPackageUri,
  normalizeLcovPath,
  parseLcov,
  countHeuristicExecutableLines,
  measureDomainCoverage,
};
