/**
 * CSM-17 integration gate — hard regression before Care Through Change UI.
 * Care Context projection corpus · Care Progression weight evidence · CIM ruleEngine baseline.
 */

import { corpusCases } from '../careContext/carePeriodProjectionCorpus.js';
import {
  evaluateWeightEstablishment,
  WEIGHT_ESTABLISHMENT_POLICY_VERSION,
} from '../../lib/care/progression/weightEstablishmentPolicy.js';
import {
  evaluateCareRecommendationCandidates,
  hasActiveRecurringCare,
} from '../../routes/careIntelligence/ruleEngine.js';

describe('CSM-17 integration gate', () => {
  describe('Care Context — projection corpus unchanged', () => {
    it('has exactly 30 corpus cases', () => {
      expect(corpusCases.length).toBe(30);
    });

    it.each(corpusCases.map((c) => [c.id, c]))('corpus case %s', (_id, fixture) => {
      fixture.run();
    });
  });

  describe('Care Progression — weight from occurrence-linked evidence only', () => {
    const petId = 'pet-gate';
    const healthEntryId = 'he-gate';

    function makeEntry(overrides = {}) {
      return {
        id: healthEntryId,
        pet_id: petId,
        care_family: 'weight_monitoring',
        status: 'active',
        frequency: 'weekly',
        frequency_interval: 1,
        ...overrides,
      };
    }

    function makeEvidence(dates) {
      return dates.map((date, index) => ({
        occurrenceId: `occ-${index}`,
        completedOn: date,
        measurement: { date, weight: 10 + index, unit: 'kg' },
      }));
    }

    it('establishes only with sufficient occurrence-linked evidence', () => {
      const established = evaluateWeightEstablishment(petId, healthEntryId, {
        entry: makeEntry(),
        completedEvidence: makeEvidence([
          '2026-06-01',
          '2026-06-08',
          '2026-06-15',
          '2026-06-22',
        ]),
      });
      expect(established.maturity).toBe('established');
      expect(established.policyVersion).toBe(WEIGHT_ESTABLISHMENT_POLICY_VERSION);
    });

    it('does not establish without linked occurrence evidence', () => {
      const result = evaluateWeightEstablishment(petId, healthEntryId, {
        entry: makeEntry(),
        completedEvidence: [],
      });
      expect(result.maturity).toBeNull();
      expect(result.reasonCodes).toContain('insufficient_evidence');
    });

    it('ignores legacy mark-taken completions without linked weight', () => {
      const result = evaluateWeightEstablishment(petId, healthEntryId, {
        entry: makeEntry(),
        completedEvidence: makeEvidence(['2026-06-01', '2026-06-08', '2026-06-15']),
        legacyCompletedWithoutWeight: 2,
      });
      expect(result.maturity).toBeNull();
      expect(result.reasonCodes).toContain('legacy_completion_ignored');
    });
  });

  describe('CIM — ruleEngine baseline for entries without schedule events', () => {
    const now = new Date('2026-09-07');

    function makePet(overrides = {}) {
      return {
        id: 'pet-1',
        species: 'Dog',
        date_of_birth: new Date('2020-01-01'),
        ...overrides,
      };
    }

    it('suggests three families for adult dog with empty health entries', () => {
      const candidates = evaluateCareRecommendationCandidates({
        pet: makePet(),
        healthEntries: [],
        existingRecommendations: [],
        now,
      });
      expect(candidates.map((c) => c.care_family).sort()).toEqual([
        'dental',
        'weight_monitoring',
        'wellness_review',
      ]);
    });

    it('does not suggest for unsupported species', () => {
      const candidates = evaluateCareRecommendationCandidates({
        pet: makePet({ species: 'Rabbit' }),
        healthEntries: [],
        existingRecommendations: [],
        now,
      });
      expect(candidates).toHaveLength(0);
    });

    it('suppresses when active recurring care exists for family', () => {
      const candidates = evaluateCareRecommendationCandidates({
        pet: makePet(),
        healthEntries: [{
          frequency: 'monthly',
          care_family: 'weight_monitoring',
        }],
        existingRecommendations: [],
        now,
      });
      expect(candidates.some((c) => c.care_family === 'weight_monitoring')).toBe(false);
    });

    it('hasActiveRecurringCare unchanged for baseline entries', () => {
      expect(hasActiveRecurringCare([
        { frequency: 'monthly', care_family: 'weight_monitoring' },
      ], 'weight_monitoring')).toBe(true);
      expect(hasActiveRecurringCare([
        { frequency: 'once', care_family: 'weight_monitoring' },
      ], 'weight_monitoring')).toBe(false);
    });
  });
});
