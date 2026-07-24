CREATE TABLE public._migrations (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    applied_at timestamp with time zone DEFAULT now()
);
CREATE TABLE public.archived_pets (
    id uuid NOT NULL,
    organization_id uuid,
    user_id uuid,
    pet_id uuid,
    pet_name character varying(255) DEFAULT ''::character varying,
    species character varying(100) DEFAULT ''::character varying,
    pdf_data text DEFAULT ''::text,
    transfer_type character varying(50) DEFAULT 'other'::character varying,
    transferred_to_user_id uuid,
    transferred_to_org_id uuid,
    notes text DEFAULT ''::text,
    archived_at timestamp with time zone DEFAULT now(),
    created_at timestamp with time zone DEFAULT now(),
    shadow_snapshot jsonb DEFAULT '{}'::jsonb NOT NULL,
    frozen_at timestamp with time zone
);
CREATE TABLE public.audit_events (
    id uuid NOT NULL,
    occurred_at timestamp with time zone DEFAULT now() NOT NULL,
    actor_user_id uuid,
    actor_pseudonym text,
    actor_type text DEFAULT 'user'::text NOT NULL,
    action text NOT NULL,
    resource_type text NOT NULL,
    resource_id text,
    org_id uuid,
    pet_id character varying(255),
    outcome text DEFAULT 'success'::text NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    request_id text,
    ip_address inet,
    user_agent text,
    retention_tier text DEFAULT 'hot'::text NOT NULL,
    CONSTRAINT audit_events_actor_type_check CHECK ((actor_type = ANY (ARRAY['user'::text, 'system'::text, 'support'::text]))),
    CONSTRAINT audit_events_outcome_check CHECK ((outcome = ANY (ARRAY['success'::text, 'failure'::text]))),
    CONSTRAINT audit_events_retention_tier_check CHECK ((retention_tier = ANY (ARRAY['hot'::text, 'warm'::text, 'cold'::text])))
);
CREATE TABLE public.custody_transfers (
    id uuid NOT NULL,
    pet_id uuid NOT NULL,
    transfer_kind character varying(32) NOT NULL,
    from_org_id uuid,
    from_user_id uuid,
    to_org_id uuid,
    to_user_id uuid,
    requested_by_user_id uuid NOT NULL,
    requesting_org_id uuid,
    status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    cancel_reason text DEFAULT ''::text,
    notes text DEFAULT ''::text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    responded_at timestamp with time zone,
    responded_by_user_id uuid
);
CREATE TABLE public.family_event_history (
    id uuid NOT NULL,
    family_event_id uuid NOT NULL,
    due_date date,
    completed_on date,
    marked_at timestamp with time zone DEFAULT now(),
    marked_by_user_id uuid,
    notes text DEFAULT ''::text,
    status character varying(50) DEFAULT 'completed'::character varying NOT NULL
);
CREATE TABLE public.family_events (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    event_type character varying(50) NOT NULL,
    notes text DEFAULT ''::text,
    created_at timestamp with time zone DEFAULT now(),
    pet_id uuid,
    organization_id uuid,
    assigned_to_user_id uuid,
    from_date date,
    to_date date,
    created_by uuid,
    updated_at timestamp with time zone DEFAULT now(),
    marked_at timestamp with time zone
);
CREATE TABLE public.foster_placements (
    id uuid NOT NULL,
    organization_id uuid NOT NULL,
    pet_id uuid NOT NULL,
    foster_user_id uuid NOT NULL,
    org_foster_parent_id uuid,
    status character varying(50) DEFAULT 'pending'::character varying NOT NULL,
    start_date date,
    end_date date,
    notes text DEFAULT ''::text,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    responded_at timestamp with time zone,
    adoption_conditions text DEFAULT ''::text
);
CREATE TABLE public.health_entries (
    id uuid NOT NULL,
    pet_id uuid NOT NULL,
    user_id uuid NOT NULL,
    type character varying(50) NOT NULL,
    name character varying(255) DEFAULT ''::character varying,
    dosage character varying(255) DEFAULT ''::character varying,
    frequency character varying(50) DEFAULT 'once'::character varying,
    frequency_days integer,
    frequency_interval integer DEFAULT 1,
    start_date date,
    next_due_date date,
    notes text DEFAULT ''::text,
    health_issue_id uuid,
    remind_days_before integer DEFAULT 1,
    status character varying(50) DEFAULT 'active'::character varying,
    completed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    completed_on date,
    recurrence_anchor character varying(50) DEFAULT 'from_completion'::character varying,
    repeat_end_date date
);
CREATE TABLE public.health_event_photos (
    id uuid NOT NULL,
    health_entry_id uuid NOT NULL,
    url text NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);
CREATE TABLE public.health_history (
    id uuid NOT NULL,
    health_entry_id uuid NOT NULL,
    status character varying(50) NOT NULL,
    notes text DEFAULT ''::text,
    changed_at timestamp with time zone DEFAULT now(),
    due_date date,
    completed_on date,
    marked_by_user_id uuid
);
CREATE TABLE public.health_issue_events (
    id uuid NOT NULL,
    health_issue_id uuid NOT NULL,
    user_id uuid NOT NULL,
    event_type character varying(50) NOT NULL,
    notes text DEFAULT ''::text,
    created_at timestamp with time zone DEFAULT now()
);
CREATE TABLE public.health_issues (
    id uuid NOT NULL,
    pet_id uuid NOT NULL,
    user_id uuid NOT NULL,
    issue_type character varying(50) NOT NULL,
    name character varying(255) DEFAULT ''::character varying,
    notes text DEFAULT ''::text,
    start_date date,
    end_date date,
    status character varying(50) DEFAULT 'active'::character varying,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);
CREATE TABLE public.notification_preferences (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    preference character varying(50) NOT NULL,
    value character varying(50) NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);
CREATE TABLE public.notifications (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    pet_id uuid,
    pet_name character varying(255),
    health_entry_id uuid,
    organization_id uuid,
    title character varying(255) DEFAULT ''::character varying,
    type character varying(50) DEFAULT 'general'::character varying,
    message text NOT NULL,
    is_read boolean DEFAULT false,
    read boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now()
);
CREATE TABLE public.org_connection_requests (
    id uuid NOT NULL,
    requesting_org_id uuid NOT NULL,
    target_org_id uuid NOT NULL,
    token character varying(64) NOT NULL,
    status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    created_by uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    revoked_at timestamp with time zone,
    CONSTRAINT org_connection_requests_distinct CHECK ((requesting_org_id <> target_org_id))
);
CREATE TABLE public.org_connections (
    id uuid NOT NULL,
    org_low_id uuid NOT NULL,
    org_high_id uuid NOT NULL,
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    connected_at timestamp with time zone DEFAULT now() NOT NULL,
    revoked_at timestamp with time zone,
    revoked_by_org_id uuid,
    CONSTRAINT org_connections_distinct CHECK ((org_low_id <> org_high_id))
);
CREATE TABLE public.org_foster_parents (
    id uuid NOT NULL,
    organization_id uuid NOT NULL,
    display_name character varying(255) DEFAULT ''::character varying NOT NULL,
    email character varying(255),
    phone character varying(50),
    notes text DEFAULT ''::text,
    user_id uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    foster_address text DEFAULT ''::text,
    lawful_basis_attested_at timestamp with time zone,
    lawful_basis_attested_by uuid
);
CREATE TABLE public.org_pet_home_hidden (
    user_id uuid NOT NULL,
    pet_id uuid NOT NULL,
    organization_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE public.organization_users (
    id uuid NOT NULL,
    organization_id uuid NOT NULL,
    user_id uuid NOT NULL,
    role character varying(50) DEFAULT 'member'::character varying,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    foster_phone character varying(50) DEFAULT ''::character varying,
    foster_address text DEFAULT ''::text,
    admin_notes text DEFAULT ''::text
);
CREATE TABLE public.organizations (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    type character varying(50) DEFAULT 'professional'::character varying,
    email character varying(255),
    phone character varying(50),
    address text,
    website character varying(255),
    bio text DEFAULT ''::text,
    photo_url text DEFAULT ''::text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    logo_url text DEFAULT ''::text,
    primary_contact_ref text
);
CREATE TABLE public.password_reset_tokens (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    code character varying(6) NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    used boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now()
);
CREATE TABLE public.pet_access (
    id uuid NOT NULL,
    pet_id uuid NOT NULL,
    user_id uuid NOT NULL,
    role character varying(50) DEFAULT 'shared'::character varying,
    hidden boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    invited_by uuid,
    share_link_id uuid
);
CREATE TABLE public.pet_share_links (
    id uuid NOT NULL,
    pet_id uuid NOT NULL,
    code character varying(32) NOT NULL,
    created_by uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    claimed_by uuid,
    claimed_at timestamp with time zone
);
CREATE TABLE public.pets (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    species character varying(100) NOT NULL,
    breed character varying(100) DEFAULT ''::character varying,
    age double precision,
    date_of_birth date,
    weight double precision,
    gender character varying(20),
    bio text DEFAULT ''::text,
    insurance text DEFAULT ''::text,
    neutered_date date,
    neuter_dismissed boolean DEFAULT false,
    chip_id text DEFAULT ''::text,
    chip_dismissed boolean DEFAULT false,
    photo_path text,
    vet_id uuid,
    color_index bigint,
    identification text,
    passed_away boolean DEFAULT false,
    organization_id uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    care_holder_kind character varying(10),
    care_holder_user_id uuid,
    care_holder_org_id uuid
);
CREATE TABLE public.refresh_tokens (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    token character varying(255) NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);
CREATE TABLE public.shared_pets (
    id uuid NOT NULL,
    pet_id uuid NOT NULL,
    user_id uuid NOT NULL,
    role character varying(50) DEFAULT 'shared'::character varying,
    invited_by uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);
CREATE TABLE public.users (
    id uuid NOT NULL,
    email character varying(255) NOT NULL,
    password_hash character varying(255) NOT NULL,
    first_name character varying(100) DEFAULT ''::character varying,
    last_name character varying(100) DEFAULT ''::character varying,
    category character varying(50) DEFAULT 'pet_guardian'::character varying,
    bio text DEFAULT ''::text,
    photo_url text DEFAULT ''::text,
    locale character varying(10) DEFAULT 'en'::character varying,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);
CREATE TABLE public.vets (
    id uuid NOT NULL,
    user_id uuid,
    name character varying(255) NOT NULL,
    clinic character varying(255),
    phone character varying(50),
    email character varying(255),
    website character varying DEFAULT ''::character varying,
    address text DEFAULT ''::text,
    notes text DEFAULT ''::text,
    organization_id uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);
CREATE TABLE public.weight_entries (
    id uuid NOT NULL,
    pet_id uuid NOT NULL,
    user_id uuid NOT NULL,
    weight double precision NOT NULL,
    unit character varying(10) DEFAULT 'kg'::character varying,
    date date,
    notes text DEFAULT ''::text,
    measured_at timestamp with time zone DEFAULT now(),
    created_at timestamp with time zone DEFAULT now()
);
ALTER TABLE ONLY public._migrations
    ADD CONSTRAINT _migrations_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.archived_pets
    ADD CONSTRAINT archived_pets_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.audit_events
    ADD CONSTRAINT audit_events_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.custody_transfers
    ADD CONSTRAINT custody_transfers_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.family_event_history
    ADD CONSTRAINT family_event_history_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.family_events
    ADD CONSTRAINT family_events_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.foster_placements
    ADD CONSTRAINT foster_placements_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.health_entries
    ADD CONSTRAINT health_entries_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.health_event_photos
    ADD CONSTRAINT health_event_photos_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.health_history
    ADD CONSTRAINT health_history_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.health_issue_events
    ADD CONSTRAINT health_issue_events_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.health_issues
    ADD CONSTRAINT health_issues_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.notification_preferences
    ADD CONSTRAINT notification_preferences_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.org_connection_requests
    ADD CONSTRAINT org_connection_requests_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.org_connection_requests
    ADD CONSTRAINT org_connection_requests_token_key UNIQUE (token);
ALTER TABLE ONLY public.org_connections
    ADD CONSTRAINT org_connections_org_low_id_org_high_id_key UNIQUE (org_low_id, org_high_id);
ALTER TABLE ONLY public.org_connections
    ADD CONSTRAINT org_connections_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.org_foster_parents
    ADD CONSTRAINT org_foster_parents_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.org_pet_home_hidden
    ADD CONSTRAINT org_pet_home_hidden_pkey PRIMARY KEY (user_id, pet_id);
ALTER TABLE ONLY public.organization_users
    ADD CONSTRAINT organization_users_organization_id_user_id_key UNIQUE (organization_id, user_id);
ALTER TABLE ONLY public.organization_users
    ADD CONSTRAINT organization_users_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.pet_access
    ADD CONSTRAINT pet_access_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.pet_share_links
    ADD CONSTRAINT pet_share_links_code_key UNIQUE (code);
ALTER TABLE ONLY public.pet_share_links
    ADD CONSTRAINT pet_share_links_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.pets
    ADD CONSTRAINT pets_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_token_key UNIQUE (token);
ALTER TABLE ONLY public.shared_pets
    ADD CONSTRAINT shared_pets_pet_id_user_id_key UNIQUE (pet_id, user_id);
ALTER TABLE ONLY public.shared_pets
    ADD CONSTRAINT shared_pets_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);
ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.vets
    ADD CONSTRAINT vets_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.weight_entries
    ADD CONSTRAINT weight_entries_pkey PRIMARY KEY (id);
CREATE INDEX idx_archived_pets_organization_id ON public.archived_pets USING btree (organization_id);
CREATE INDEX idx_audit_events_action ON public.audit_events USING btree (action);
CREATE INDEX idx_audit_events_actor_user_id ON public.audit_events USING btree (actor_user_id) WHERE (actor_user_id IS NOT NULL);
CREATE INDEX idx_audit_events_occurred_at ON public.audit_events USING btree (occurred_at);
CREATE INDEX idx_audit_events_org_id ON public.audit_events USING btree (org_id) WHERE (org_id IS NOT NULL);
CREATE INDEX idx_audit_events_pet_id ON public.audit_events USING btree (pet_id) WHERE (pet_id IS NOT NULL);
CREATE INDEX idx_audit_events_resource ON public.audit_events USING btree (resource_type, resource_id);
CREATE INDEX idx_audit_events_retention_tier ON public.audit_events USING btree (retention_tier, occurred_at);
CREATE INDEX idx_custody_transfers_pet_status ON public.custody_transfers USING btree (pet_id, status);
CREATE INDEX idx_custody_transfers_to_org ON public.custody_transfers USING btree (to_org_id, status);
CREATE INDEX idx_family_event_history_event_id ON public.family_event_history USING btree (family_event_id);
CREATE INDEX idx_family_events_org_id ON public.family_events USING btree (organization_id);
CREATE INDEX idx_family_events_pet_id ON public.family_events USING btree (pet_id);
CREATE INDEX idx_foster_placements_foster_user_status ON public.foster_placements USING btree (foster_user_id, status);
CREATE UNIQUE INDEX idx_foster_placements_one_active_pet ON public.foster_placements USING btree (pet_id) WHERE ((status)::text = ANY ((ARRAY['pending'::character varying, 'in_progress'::character varying, 'waiting_adoption_confirmation'::character varying, 'pending_adoption_conditions'::character varying])::text[]));
CREATE INDEX idx_foster_placements_org_id ON public.foster_placements USING btree (organization_id);
CREATE INDEX idx_health_entries_pet_id ON public.health_entries USING btree (pet_id);
CREATE INDEX idx_health_entries_user_id ON public.health_entries USING btree (user_id);
CREATE INDEX idx_notifications_user_id ON public.notifications USING btree (user_id);
CREATE INDEX idx_org_connection_requests_target ON public.org_connection_requests USING btree (target_org_id, status);
CREATE INDEX idx_org_connections_high ON public.org_connections USING btree (org_high_id);
CREATE INDEX idx_org_connections_low ON public.org_connections USING btree (org_low_id);
CREATE INDEX idx_org_foster_parents_org_id ON public.org_foster_parents USING btree (organization_id);
CREATE INDEX idx_org_pet_home_hidden_org ON public.org_pet_home_hidden USING btree (organization_id, pet_id);
CREATE INDEX idx_org_users_user_id ON public.organization_users USING btree (user_id);
CREATE INDEX idx_organizations_name ON public.organizations USING btree (name);
CREATE UNIQUE INDEX idx_pet_access_pet_user ON public.pet_access USING btree (pet_id, user_id);
CREATE INDEX idx_pet_share_links_code ON public.pet_share_links USING btree (code);
CREATE INDEX idx_pet_share_links_pet_id ON public.pet_share_links USING btree (pet_id);
ALTER TABLE ONLY public.archived_pets
    ADD CONSTRAINT archived_pets_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.archived_pets
    ADD CONSTRAINT archived_pets_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.audit_events
    ADD CONSTRAINT audit_events_actor_user_id_fkey FOREIGN KEY (actor_user_id) REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.custody_transfers
    ADD CONSTRAINT custody_transfers_from_org_id_fkey FOREIGN KEY (from_org_id) REFERENCES public.organizations(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.custody_transfers
    ADD CONSTRAINT custody_transfers_from_user_id_fkey FOREIGN KEY (from_user_id) REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.custody_transfers
    ADD CONSTRAINT custody_transfers_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES public.pets(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.custody_transfers
    ADD CONSTRAINT custody_transfers_requested_by_user_id_fkey FOREIGN KEY (requested_by_user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.custody_transfers
    ADD CONSTRAINT custody_transfers_requesting_org_id_fkey FOREIGN KEY (requesting_org_id) REFERENCES public.organizations(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.custody_transfers
    ADD CONSTRAINT custody_transfers_responded_by_user_id_fkey FOREIGN KEY (responded_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.custody_transfers
    ADD CONSTRAINT custody_transfers_to_org_id_fkey FOREIGN KEY (to_org_id) REFERENCES public.organizations(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.custody_transfers
    ADD CONSTRAINT custody_transfers_to_user_id_fkey FOREIGN KEY (to_user_id) REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.family_event_history
    ADD CONSTRAINT family_event_history_family_event_id_fkey FOREIGN KEY (family_event_id) REFERENCES public.family_events(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.family_event_history
    ADD CONSTRAINT family_event_history_marked_by_user_id_fkey FOREIGN KEY (marked_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.family_events
    ADD CONSTRAINT family_events_assigned_to_user_id_fkey FOREIGN KEY (assigned_to_user_id) REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.family_events
    ADD CONSTRAINT family_events_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.family_events
    ADD CONSTRAINT family_events_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.family_events
    ADD CONSTRAINT family_events_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES public.pets(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.family_events
    ADD CONSTRAINT family_events_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.foster_placements
    ADD CONSTRAINT foster_placements_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.foster_placements
    ADD CONSTRAINT foster_placements_foster_user_id_fkey FOREIGN KEY (foster_user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.foster_placements
    ADD CONSTRAINT foster_placements_org_foster_parent_id_fkey FOREIGN KEY (org_foster_parent_id) REFERENCES public.org_foster_parents(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.foster_placements
    ADD CONSTRAINT foster_placements_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.foster_placements
    ADD CONSTRAINT foster_placements_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES public.pets(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.health_entries
    ADD CONSTRAINT health_entries_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES public.pets(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.health_entries
    ADD CONSTRAINT health_entries_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.health_event_photos
    ADD CONSTRAINT health_event_photos_health_entry_id_fkey FOREIGN KEY (health_entry_id) REFERENCES public.health_entries(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.health_history
    ADD CONSTRAINT health_history_health_entry_id_fkey FOREIGN KEY (health_entry_id) REFERENCES public.health_entries(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.health_history
    ADD CONSTRAINT health_history_marked_by_user_id_fkey FOREIGN KEY (marked_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.health_issue_events
    ADD CONSTRAINT health_issue_events_health_issue_id_fkey FOREIGN KEY (health_issue_id) REFERENCES public.health_issues(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.health_issue_events
    ADD CONSTRAINT health_issue_events_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.health_issues
    ADD CONSTRAINT health_issues_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES public.pets(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.health_issues
    ADD CONSTRAINT health_issues_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.notification_preferences
    ADD CONSTRAINT notification_preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.org_connection_requests
    ADD CONSTRAINT org_connection_requests_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.org_connection_requests
    ADD CONSTRAINT org_connection_requests_requesting_org_id_fkey FOREIGN KEY (requesting_org_id) REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.org_connection_requests
    ADD CONSTRAINT org_connection_requests_target_org_id_fkey FOREIGN KEY (target_org_id) REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.org_connections
    ADD CONSTRAINT org_connections_org_high_id_fkey FOREIGN KEY (org_high_id) REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.org_connections
    ADD CONSTRAINT org_connections_org_low_id_fkey FOREIGN KEY (org_low_id) REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.org_connections
    ADD CONSTRAINT org_connections_revoked_by_org_id_fkey FOREIGN KEY (revoked_by_org_id) REFERENCES public.organizations(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.org_foster_parents
    ADD CONSTRAINT org_foster_parents_lawful_basis_attested_by_fkey FOREIGN KEY (lawful_basis_attested_by) REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.org_foster_parents
    ADD CONSTRAINT org_foster_parents_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.org_foster_parents
    ADD CONSTRAINT org_foster_parents_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.org_pet_home_hidden
    ADD CONSTRAINT org_pet_home_hidden_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.org_pet_home_hidden
    ADD CONSTRAINT org_pet_home_hidden_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES public.pets(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.org_pet_home_hidden
    ADD CONSTRAINT org_pet_home_hidden_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.organization_users
    ADD CONSTRAINT organization_users_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.organization_users
    ADD CONSTRAINT organization_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.pet_access
    ADD CONSTRAINT pet_access_invited_by_fkey FOREIGN KEY (invited_by) REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.pet_access
    ADD CONSTRAINT pet_access_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES public.pets(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.pet_access
    ADD CONSTRAINT pet_access_share_link_id_fkey FOREIGN KEY (share_link_id) REFERENCES public.pet_share_links(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.pet_access
    ADD CONSTRAINT pet_access_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.pet_share_links
    ADD CONSTRAINT pet_share_links_claimed_by_fkey FOREIGN KEY (claimed_by) REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.pet_share_links
    ADD CONSTRAINT pet_share_links_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.pet_share_links
    ADD CONSTRAINT pet_share_links_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES public.pets(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.pets
    ADD CONSTRAINT pets_care_holder_org_id_fkey FOREIGN KEY (care_holder_org_id) REFERENCES public.organizations(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.pets
    ADD CONSTRAINT pets_care_holder_user_id_fkey FOREIGN KEY (care_holder_user_id) REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.pets
    ADD CONSTRAINT pets_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.pets
    ADD CONSTRAINT pets_vet_id_fkey FOREIGN KEY (vet_id) REFERENCES public.vets(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.shared_pets
    ADD CONSTRAINT shared_pets_invited_by_fkey FOREIGN KEY (invited_by) REFERENCES public.users(id);
ALTER TABLE ONLY public.shared_pets
    ADD CONSTRAINT shared_pets_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES public.pets(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.shared_pets
    ADD CONSTRAINT shared_pets_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.vets
    ADD CONSTRAINT vets_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.weight_entries
    ADD CONSTRAINT weight_entries_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES public.pets(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.weight_entries
    ADD CONSTRAINT weight_entries_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
