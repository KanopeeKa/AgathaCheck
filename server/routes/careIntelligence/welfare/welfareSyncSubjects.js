import { evaluateMicrochipWelfare, microchipWelfareDedupeKey } from './microchipWelfareEvaluator.js';
import { evaluateNeuterWelfare, neuterWelfareDedupeKey } from './neuterWelfareEvaluator.js';

/** @typedef {{ evaluate: (pet: Record<string, unknown>) => object | null, dedupeKey: (petId: string) => string }} WelfareSubject */

export const WELFARE_SYNC_SUBJECTS = [
  {
    evaluate: evaluateMicrochipWelfare,
    dedupeKey: microchipWelfareDedupeKey,
  },
  {
    evaluate: evaluateNeuterWelfare,
    dedupeKey: neuterWelfareDedupeKey,
  },
];
