-- D-CSM-035: retire health_history; care history reads from health_occurrences only.

DO $$
DECLARE
  v_count bigint;
BEGIN
  IF to_regclass('public.health_history') IS NOT NULL THEN
    SELECT COUNT(*)::bigint INTO v_count FROM public.health_history;
    RAISE NOTICE 'drop_health_history: % rows before drop', v_count;
  END IF;
END $$;

DROP TABLE IF EXISTS public.health_history;
