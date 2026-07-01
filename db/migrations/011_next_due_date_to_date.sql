-- Calendar due dates must be stored as DATE, not TIMESTAMPTZ. Inserting
-- 'YYYY-MM-DD' into TIMESTAMPTZ is interpreted in the session timezone; reading
-- the instant back with UTC date components shifts the day east of UTC.

SET TIME ZONE 'UTC';

ALTER TABLE health_entries
  ALTER COLUMN next_due_date TYPE DATE
  USING (
    CASE
      WHEN next_due_date IS NULL THEN NULL
      ELSE next_due_date::date
    END
  );
