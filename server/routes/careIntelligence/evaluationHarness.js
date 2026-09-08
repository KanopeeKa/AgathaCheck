import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

import { evaluateReviewRelevance } from './reviewRelevance.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

function loadJson(relativePath) {
  const full = path.join(__dirname, relativePath);
  return JSON.parse(fs.readFileSync(full, 'utf8'));
}

/**
 * D5a — run reference vectors and optional benchmark cases.
 */
export function runEvaluationHarness({ includeBenchmark = true } = {}) {
  const referenceVectors = loadJson('./referenceVectors/weightReviewRelevance.json');
  const results = [];

  for (const vector of referenceVectors) {
    const outcome = evaluateReviewRelevance({
      pet: vector.pet,
      measurements: vector.measurements,
      weightContext: vector.weightContext || null,
    });
    const pass = outcome.review_relevant === vector.expectReviewRelevant;
    results.push({
      caseId: vector.caseId,
      kind: 'reference_vector',
      pass,
      expectReviewRelevant: vector.expectReviewRelevant,
      actualReviewRelevant: outcome.review_relevant,
      classification: outcome.weight_change_spec?.classification || null,
      suppressions: outcome.suppression_reasons,
    });
  }

  if (includeBenchmark) {
    const benchmark = loadJson('./benchmark/sampleCases.json');
    for (const caseDef of benchmark) {
      const outcome = evaluateReviewRelevance({
        pet: { id: caseDef.caseId, date_of_birth: caseDef.dateOfBirth || null, ...caseDef.pet },
        measurements: caseDef.measurements,
        weightContext: caseDef.weightContext || null,
      });
      const expectRelevant = caseDef.expectedReviewRelevance === 'relevant';
      const expectUncertain = caseDef.expectedReviewRelevance.startsWith('uncertain');
      const pass = expectUncertain
        ? true
        : outcome.review_relevant === expectRelevant;
      results.push({
        caseId: caseDef.caseId,
        kind: 'benchmark_sample',
        pass,
        expectReviewRelevance: caseDef.expectedReviewRelevance,
        actualReviewRelevant: outcome.review_relevant,
        classification: outcome.weight_change_spec?.classification || null,
        disagreementFlag: caseDef.disagreementFlag || false,
      });
    }
  }

  const failed = results.filter((r) => !r.pass);
  return {
    total: results.length,
    passed: results.length - failed.length,
    failed: failed.length,
    results,
    summary: failed.length === 0 ? 'all_pass' : 'failures_present',
  };
}
