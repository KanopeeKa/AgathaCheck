-- Child C: deterministic care_family backfill (spec §7.2)
--
-- Clears type-only guesses from 053 and applies name-based rules only where
-- unambiguous. Arguable rows stay NULL (honestly uncategorised).
--
-- Mapping table (applied in order):
-- | Rule | care_family |
-- | type = medication | medication |
-- | name ~ flea/tick/parasite (preventive/other) | parasite_prevention |
-- | name ~ rabies/vaccin/booster (preventive/other) | vaccination |
-- | name ~ nail | nail_care |
-- | name ~ weight | weight_monitoring |
-- | name ~ groom | grooming |
-- | name ~ dental/teeth | dental |
-- | vet_visit + name ~ wellness/annual check/checkup | wellness_review |
--
-- Rollback policy: leave values in place (no destructive down migration).

-- Remove non-unambiguous type-only assignments from migration 053.
UPDATE health_entries
SET care_family = NULL
WHERE care_family = 'other'
  AND type IN ('preventive', 'other', 'family_event', 'procedure');

UPDATE health_entries
SET care_family = NULL
WHERE care_family = 'wellness_review'
  AND type = 'vet_visit';

-- Unambiguous type → family.
UPDATE health_entries
SET care_family = 'medication'
WHERE type = 'medication'
  AND (care_family IS NULL OR care_family = 'other');

-- Name-based preventive / other mappings (NULL only).
UPDATE health_entries
SET care_family = 'parasite_prevention'
WHERE care_family IS NULL
  AND type IN ('preventive', 'other')
  AND (
    LOWER(name) LIKE '%flea%'
    OR LOWER(name) LIKE '%tick%'
    OR LOWER(name) LIKE '%parasite%'
  );

UPDATE health_entries
SET care_family = 'vaccination'
WHERE care_family IS NULL
  AND type IN ('preventive', 'other')
  AND (
    LOWER(name) LIKE '%rabies%'
    OR LOWER(name) LIKE '%vaccin%'
    OR LOWER(name) LIKE '%booster%'
  );

UPDATE health_entries
SET care_family = 'nail_care'
WHERE care_family IS NULL
  AND LOWER(name) LIKE '%nail%';

UPDATE health_entries
SET care_family = 'weight_monitoring'
WHERE care_family IS NULL
  AND LOWER(name) LIKE '%weight%';

UPDATE health_entries
SET care_family = 'grooming'
WHERE care_family IS NULL
  AND LOWER(name) LIKE '%groom%';

UPDATE health_entries
SET care_family = 'dental'
WHERE care_family IS NULL
  AND (
    LOWER(name) LIKE '%dental%'
    OR LOWER(name) LIKE '%teeth%'
  );

UPDATE health_entries
SET care_family = 'wellness_review'
WHERE care_family IS NULL
  AND type = 'vet_visit'
  AND (
    LOWER(name) LIKE '%wellness%'
    OR LOWER(name) LIKE '%annual check%'
    OR LOWER(name) LIKE '%check-up%'
    OR LOWER(name) LIKE '%checkup%'
  );
