-- Recreate empty health_history for rollback (no data restore).

CREATE TABLE IF NOT EXISTS public.health_history (
    id uuid NOT NULL,
    health_entry_id uuid NOT NULL,
    status character varying(50) NOT NULL,
    notes text DEFAULT ''::text,
    changed_at timestamp with time zone DEFAULT now(),
    due_date date,
    completed_on date,
    marked_by_user_id uuid
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'health_history_pkey'
  ) THEN
    ALTER TABLE ONLY public.health_history
      ADD CONSTRAINT health_history_pkey PRIMARY KEY (id);
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'health_history_health_entry_id_fkey'
  ) THEN
    ALTER TABLE ONLY public.health_history
      ADD CONSTRAINT health_history_health_entry_id_fkey
      FOREIGN KEY (health_entry_id) REFERENCES public.health_entries(id) ON DELETE CASCADE;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'health_history_marked_by_user_id_fkey'
  ) THEN
    ALTER TABLE ONLY public.health_history
      ADD CONSTRAINT health_history_marked_by_user_id_fkey
      FOREIGN KEY (marked_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;
  END IF;
END $$;
