-- Pet Care domain rename: users.category pet_guardian → pet_carer (D38).

BEGIN;

UPDATE users
SET category = 'pet_carer', updated_at = NOW()
WHERE category = 'pet_guardian';

ALTER TABLE users
  ALTER COLUMN category SET DEFAULT 'pet_carer';

COMMIT;
