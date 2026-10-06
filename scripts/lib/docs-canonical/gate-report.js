'use strict';

const fs = require('fs');
const path = require('path');
const { parseFrontmatter } = require('./yaml');
const { parseRequirements, parseAcceptanceCriteria } = require('./parse-md');
const { COVERAGE_RE } = require('./constants');

function collectFeatureDocs(root) {
  const domainsDir = path.join(root, 'docs/domains');
  const files = [];
  if (!fs.existsSync(domainsDir)) {
    return files;
  }
  for (const domain of fs.readdirSync(domainsDir)) {
    const featDir = path.join(domainsDir, domain, 'features');
    if (!fs.existsSync(featDir)) {
      continue;
    }
    for (const name of fs.readdirSync(featDir)) {
      if (name.endsWith('.md')) {
        files.push(`docs/domains/${domain}/features/${name}`);
      }
    }
  }
  return files.sort();
}

function gateReport(ctx) {
  const { root, json } = ctx;
  const byDomain = {};
  let totalReq = 0;
  let traced = 0;
  let tbd = 0;

  for (const rel of collectFeatureDocs(root)) {
    const domain = rel.split('/')[2];
    if (!byDomain[domain]) {
      byDomain[domain] = { features: 0, requirements: 0, ac_rows: 0, traced: 0, tbd: 0 };
    }
    byDomain[domain].features += 1;
    const full = path.join(root, rel);
    let body;
    try {
      ({ body } = parseFrontmatter(full, root));
    } catch {
      continue;
    }
    const reqs = parseRequirements(body);
    const acs = parseAcceptanceCriteria(body);
    byDomain[domain].requirements += reqs.length;
    totalReq += reqs.length;
    byDomain[domain].ac_rows += acs.length;

    for (const row of acs) {
      const cov = String(row.coverage || '').trim();
      if (/TBD\s*—\s*consolidate/i.test(cov)) {
        tbd += 1;
        byDomain[domain].tbd += 1;
      } else if (COVERAGE_RE.test(cov)) {
        traced += 1;
        byDomain[domain].traced += 1;
      }
    }
  }

  const report = {
    generated_at: new Date().toISOString(),
    domains: byDomain,
    totals: { requirements: totalReq, ac_traced: traced, ac_tbd: tbd },
  };

  if (json) {
    console.log(JSON.stringify(report, null, 2));
    return { report, exitCode: 0 };
  }

  console.log('# Docs canonical report\n');
  console.log('| Domain | Features | Requirements | AC traced | AC TBD |');
  console.log('|--------|----------|--------------|-----------|--------|');
  for (const [domain, row] of Object.entries(byDomain).sort()) {
    console.log(
      `| ${domain} | ${row.features} | ${row.requirements} | ${row.traced} | ${row.tbd} |`,
    );
  }
  console.log(`\nTotals: ${totalReq} requirements, ${traced} traced AC, ${tbd} TBD legacy`);
  return { report, exitCode: 0 };
}

module.exports = { gateReport, collectFeatureDocs };
