CREATE TABLE public._migrations (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    applied_at timestamp with time zone DEFAULT now()
);
CREATE TABLE public.adoption_journeys (
    id uuid NOT NULL,
    organization_id uuid NOT NULL,
    fostering_session_id uuid NOT NULL,
    pet_id uuid NOT NULL,
    foster_user_id uuid,
    status character varying(64) NOT NULL,
    adoption_conditions text DEFAULT ''::text NOT NULL,
    started_at timestamp with time zone,
    finalised_at timestamp with time zone,
    cancelled_at timestamp with time zone,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    milestone_items jsonb DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT adoption_journeys_status_check CHECK (((status)::text = ANY ((ARRAY['awaiting_foster_confirmation'::character varying, 'pending_conditions'::character varying, 'finalised'::character varying, 'cancelled'::character varying])::text[])))
);
CREATE TABLE public.adoption_visits (
    id uuid NOT NULL,
    organization_id uuid NOT NULL,
    prospect_id uuid,
    fostering_session_id uuid,
    pet_id uuid NOT NULL,
    scheduled_at timestamp with time zone NOT NULL,
    status character varying(32) DEFAULT 'scheduled'::character varying NOT NULL,
    visit_outcome character varying(32),
    outcome_notes text DEFAULT ''::text NOT NULL,
    assigned_foster_parent_id uuid,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT adoption_visits_status_check CHECK (((status)::text = ANY ((ARRAY['scheduled'::character varying, 'completed'::character varying, 'cancelled'::character varying])::text[]))),
    CONSTRAINT adoption_visits_visit_outcome_check CHECK (((visit_outcome IS NULL) OR ((visit_outcome)::text = ANY ((ARRAY['positive'::character varying, 'negative'::character varying, 'no_show'::character varying])::text[]))))
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
CREATE TABLE public.document_templates (
    id uuid NOT NULL,
    organization_id uuid NOT NULL,
    template_key character varying(128) NOT NULL,
    template_type character varying(64) NOT NULL,
    label character varying(255) DEFAULT ''::character varying NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    is_required boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    is_public boolean DEFAULT false NOT NULL,
    CONSTRAINT document_templates_type_check CHECK (((template_type)::text = ANY ((ARRAY['session_checklist'::character varying, 'adoption_milestone'::character varying])::text[])))
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
    foster_user_id uuid,
    org_foster_parent_id uuid,
    status character varying(50) DEFAULT 'pending'::character varying NOT NULL,
    start_date date,
    end_date date,
    notes text DEFAULT ''::text,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    responded_at timestamp with time zone,
    adoption_conditions text DEFAULT ''::text,
    shelter_foster_relationship_id uuid,
    session_type text DEFAULT 'standard_foster'::text NOT NULL,
    foster_request_response_id uuid,
    shelter_start_confirmed_at timestamp with time zone,
    foster_start_confirmed_at timestamp with time zone,
    session_checklist_items jsonb DEFAULT '{}'::jsonb NOT NULL,
    flagged_for_admin_review boolean DEFAULT false NOT NULL,
    CONSTRAINT foster_placements_session_type_check CHECK ((session_type = ANY (ARRAY['standard_foster'::text, 'foster_in_view_to_adopt'::text])))
);
CREATE TABLE public.foster_profiles (
    id uuid NOT NULL,
    user_id uuid,
    display_name character varying(255) DEFAULT ''::character varying NOT NULL,
    email character varying(255),
    phone character varying(50),
    foster_address text DEFAULT ''::text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    species_capacities jsonb DEFAULT '[]'::jsonb NOT NULL,
    self_declared_competencies jsonb DEFAULT '[]'::jsonb NOT NULL,
    confirmed_competencies jsonb DEFAULT '[]'::jsonb NOT NULL
);
CREATE TABLE public.foster_request_pets (
    id uuid NOT NULL,
    foster_request_id uuid NOT NULL,
    pet_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);
CREATE TABLE public.foster_request_responses (
    id uuid NOT NULL,
    foster_request_id uuid NOT NULL,
    org_foster_parent_id uuid NOT NULL,
    response character varying(32) DEFAULT 'pending'::character varying NOT NULL,
    message text DEFAULT ''::text NOT NULL,
    earliest_availability date,
    capacity_confirmed_at timestamp with time zone,
    responded_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT foster_request_responses_response_check CHECK (((response)::text = ANY ((ARRAY['can_help'::character varying, 'cannot_help'::character varying, 'pending'::character varying])::text[])))
);
CREATE TABLE public.foster_request_targets (
    id uuid NOT NULL,
    foster_request_id uuid NOT NULL,
    org_foster_parent_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);
CREATE TABLE public.foster_requests (
    id uuid NOT NULL,
    organization_id uuid NOT NULL,
    message text DEFAULT ''::text NOT NULL,
    status character varying(32) DEFAULT 'draft'::character varying NOT NULL,
    created_by uuid,
    sent_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT foster_requests_status_check CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'sent'::character varying, 'cancelled'::character varying])::text[])))
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
CREATE TABLE public.health_issue_documents (
    id uuid NOT NULL,
    health_issue_id uuid NOT NULL,
    url text NOT NULL,
    created_at timestamp with time zone DEFAULT now()
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
    created_at timestamp with time zone DEFAULT now(),
    kind character varying(16) DEFAULT 'care'::character varying NOT NULL,
    priority character varying(8) DEFAULT 'normal'::character varying NOT NULL,
    resolved_at timestamp with time zone,
    CONSTRAINT notifications_kind_check CHECK (((kind)::text = ANY ((ARRAY['care'::character varying, 'administrative'::character varying])::text[]))),
    CONSTRAINT notifications_priority_check CHECK (((priority)::text = ANY ((ARRAY['normal'::character varying, 'urgent'::character varying])::text[])))
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
    lawful_basis_attested_by uuid,
    approval_state character varying(32) DEFAULT 'approved'::character varying NOT NULL,
    creation_source character varying(32) DEFAULT 'manual_shelter_entry'::character varying,
    foster_profile_id uuid,
    opt_out_at timestamp with time zone,
    retention_category text DEFAULT 'shelter_foster_relationship'::text NOT NULL,
    visible_to text DEFAULT 'both'::text NOT NULL,
    address_visibility text DEFAULT 'full'::text NOT NULL,
    contact_visibility text DEFAULT 'both'::text NOT NULL,
    rules_agreement_at timestamp with time zone,
    notification_message_channel text DEFAULT 'in_app'::text NOT NULL,
    CONSTRAINT org_foster_parents_address_visibility_check CHECK ((address_visibility = ANY (ARRAY['full'::text, 'town'::text, 'hidden'::text]))),
    CONSTRAINT org_foster_parents_approval_state_check CHECK (((approval_state)::text = ANY ((ARRAY['under_review'::character varying, 'approved'::character varying, 'declined'::character varying, 'archived'::character varying])::text[]))),
    CONSTRAINT org_foster_parents_contact_visibility_check CHECK ((contact_visibility = ANY (ARRAY['email'::text, 'phone'::text, 'neither'::text, 'both'::text]))),
    CONSTRAINT org_foster_parents_creation_source_check CHECK (((creation_source)::text = ANY ((ARRAY['invite'::character varying, 'manual_shelter_entry'::character varying, 'member'::character varying])::text[]))),
    CONSTRAINT org_foster_parents_notification_message_channel_check CHECK ((notification_message_channel = ANY (ARRAY['in_app'::text, 'email'::text, 'both'::text]))),
    CONSTRAINT org_foster_parents_retention_category_check CHECK ((retention_category = ANY (ARRAY['shelter_foster_relationship'::text, 'declined_archived'::text, 'manual_contact'::text]))),
    CONSTRAINT org_foster_parents_visible_to_check CHECK ((visible_to = ANY (ARRAY['other_fosters'::text, 'admins'::text, 'both'::text, 'nobody'::text])))
);
CREATE TABLE public.org_pet_home_hidden (
    user_id uuid NOT NULL,
    pet_id uuid NOT NULL,
    organization_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE public.organization_permissions (
    id uuid NOT NULL,
    organization_id uuid NOT NULL,
    user_id uuid NOT NULL,
    permission_key character varying(64) NOT NULL,
    source character varying(32) DEFAULT 'individual'::character varying NOT NULL,
    granted_by uuid NOT NULL,
    granted_at timestamp with time zone DEFAULT now() NOT NULL,
    revoked_at timestamp with time zone,
    revoked_by uuid
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
    admin_notes text DEFAULT ''::text,
    CONSTRAINT organization_users_role_check CHECK (((role)::text = ANY ((ARRAY['associate'::character varying, 'foster'::character varying, 'admin'::character varying, 'super_admin'::character varying, 'pending_associate'::character varying, 'pending_foster'::character varying, 'pending_admin'::character varying, 'pending_super_admin'::character varying])::text[])))
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
    primary_contact_ref text,
    town character varying(120),
    administrative_area character varying(120),
    description text,
    is_discoverable boolean DEFAULT true NOT NULL,
    legal_identifier_1 character varying(64),
    legal_identifier_2 character varying(64),
    legal_identifier_3 character varying(64),
    public_profile_metadata jsonb DEFAULT '{}'::jsonb NOT NULL
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
CREATE TABLE public.pet_timeline_entries (
    id uuid NOT NULL,
    pet_id uuid NOT NULL,
    entry_type character varying(16) DEFAULT 'manual'::character varying NOT NULL,
    title character varying(255) DEFAULT ''::character varying NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    start_date date NOT NULL,
    end_date date,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT pet_timeline_entries_type_check CHECK (((entry_type)::text = 'manual'::text))
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
CREATE TABLE public.prospects (
    id uuid NOT NULL,
    organization_id uuid NOT NULL,
    display_name character varying(255) DEFAULT ''::character varying NOT NULL,
    email character varying(255),
    phone character varying(50),
    notes text DEFAULT ''::text,
    lawful_basis_attested_at timestamp with time zone,
    lawful_basis_attested_by uuid,
    opt_out_at timestamp with time zone,
    retention_category text DEFAULT 'manual_contact'::text NOT NULL,
    creation_source character varying(32) DEFAULT 'manual_shelter_entry'::character varying NOT NULL,
    user_id uuid,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT prospects_creation_source_check CHECK (((creation_source)::text = ANY ((ARRAY['manual_shelter_entry'::character varying, 'registered_user'::character varying])::text[]))),
    CONSTRAINT prospects_retention_category_check CHECK ((retention_category = ANY (ARRAY['manual_contact'::text, 'declined_archived'::text, 'prospect_relationship'::text])))
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
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    organization_id uuid
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
ALTER TABLE ONLY public.adoption_journeys
    ADD CONSTRAINT adoption_journeys_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.adoption_visits
    ADD CONSTRAINT adoption_visits_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.archived_pets
    ADD CONSTRAINT archived_pets_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.audit_events
    ADD CONSTRAINT audit_events_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.custody_transfers
    ADD CONSTRAINT custody_transfers_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.document_templates
    ADD CONSTRAINT document_templates_org_key_unique UNIQUE (organization_id, template_key);
ALTER TABLE ONLY public.document_templates
    ADD CONSTRAINT document_templates_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.family_event_history
    ADD CONSTRAINT family_event_history_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.family_events
    ADD CONSTRAINT family_events_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.foster_placements
    ADD CONSTRAINT foster_placements_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.foster_profiles
    ADD CONSTRAINT foster_profiles_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.foster_profiles
    ADD CONSTRAINT foster_profiles_user_id_key UNIQUE (user_id);
ALTER TABLE ONLY public.foster_request_pets
    ADD CONSTRAINT foster_request_pets_foster_request_id_pet_id_key UNIQUE (foster_request_id, pet_id);
ALTER TABLE ONLY public.foster_request_pets
    ADD CONSTRAINT foster_request_pets_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.foster_request_responses
    ADD CONSTRAINT foster_request_responses_foster_request_id_org_foster_paren_key UNIQUE (foster_request_id, org_foster_parent_id);
ALTER TABLE ONLY public.foster_request_responses
    ADD CONSTRAINT foster_request_responses_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.foster_request_targets
    ADD CONSTRAINT foster_request_targets_foster_request_id_org_foster_parent__key UNIQUE (foster_request_id, org_foster_parent_id);
ALTER TABLE ONLY public.foster_request_targets
    ADD CONSTRAINT foster_request_targets_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.foster_requests
    ADD CONSTRAINT foster_requests_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.health_entries
    ADD CONSTRAINT health_entries_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.health_event_photos
    ADD CONSTRAINT health_event_photos_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.health_history
    ADD CONSTRAINT health_history_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.health_issue_documents
    ADD CONSTRAINT health_issue_documents_pkey PRIMARY KEY (id);
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
ALTER TABLE ONLY public.organization_permissions
    ADD CONSTRAINT organization_permissions_pkey PRIMARY KEY (id);
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
ALTER TABLE ONLY public.pet_timeline_entries
    ADD CONSTRAINT pet_timeline_entries_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.pets
    ADD CONSTRAINT pets_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.prospects
    ADD CONSTRAINT prospects_pkey PRIMARY KEY (id);
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
CREATE UNIQUE INDEX idx_adoption_journeys_one_open_per_session ON public.adoption_journeys USING btree (fostering_session_id) WHERE ((status)::text = ANY ((ARRAY['awaiting_foster_confirmation'::character varying, 'pending_conditions'::character varying])::text[]));
CREATE INDEX idx_adoption_journeys_org_id ON public.adoption_journeys USING btree (organization_id);
CREATE INDEX idx_adoption_journeys_session_id ON public.adoption_journeys USING btree (fostering_session_id);
CREATE INDEX idx_adoption_visits_org_id ON public.adoption_visits USING btree (organization_id);
CREATE INDEX idx_adoption_visits_prospect_id ON public.adoption_visits USING btree (prospect_id) WHERE (prospect_id IS NOT NULL);
CREATE INDEX idx_adoption_visits_session_id ON public.adoption_visits USING btree (fostering_session_id) WHERE (fostering_session_id IS NOT NULL);
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
CREATE INDEX idx_document_templates_org_type ON public.document_templates USING btree (organization_id, template_type);
CREATE INDEX idx_family_event_history_event_id ON public.family_event_history USING btree (family_event_id);
CREATE INDEX idx_family_events_org_id ON public.family_events USING btree (organization_id);
CREATE INDEX idx_family_events_pet_id ON public.family_events USING btree (pet_id);
CREATE INDEX idx_foster_placements_foster_user_status ON public.foster_placements USING btree (foster_user_id, status);
CREATE UNIQUE INDEX idx_foster_placements_one_open_session_per_pet ON public.foster_placements USING btree (pet_id) WHERE ((status)::text = ANY ((ARRAY['pending_acceptance'::character varying, 'preparation'::character varying, 'ready_to_start'::character varying, 'active'::character varying, 'end_pending_confirmation'::character varying, 'adoption_in_progress'::character varying, 'pending'::character varying, 'in_progress'::character varying, 'waiting_adoption_confirmation'::character varying, 'pending_adoption_conditions'::character varying])::text[]));
CREATE INDEX idx_foster_placements_org_id ON public.foster_placements USING btree (organization_id);
CREATE INDEX idx_foster_profiles_email_lower ON public.foster_profiles USING btree (lower((email)::text)) WHERE (email IS NOT NULL);
CREATE INDEX idx_foster_request_pets_request_id ON public.foster_request_pets USING btree (foster_request_id);
CREATE INDEX idx_foster_request_responses_request_id ON public.foster_request_responses USING btree (foster_request_id);
CREATE INDEX idx_foster_request_targets_request_id ON public.foster_request_targets USING btree (foster_request_id);
CREATE INDEX idx_foster_requests_org_id ON public.foster_requests USING btree (organization_id);
CREATE INDEX idx_health_entries_pet_id ON public.health_entries USING btree (pet_id);
CREATE INDEX idx_health_entries_user_id ON public.health_entries USING btree (user_id);
CREATE INDEX idx_notifications_user_id ON public.notifications USING btree (user_id);
CREATE INDEX idx_org_connection_requests_target ON public.org_connection_requests USING btree (target_org_id, status);
CREATE INDEX idx_org_connections_high ON public.org_connections USING btree (org_high_id);
CREATE INDEX idx_org_connections_low ON public.org_connections USING btree (org_low_id);
CREATE INDEX idx_org_foster_parents_org_id ON public.org_foster_parents USING btree (organization_id);
CREATE UNIQUE INDEX idx_org_permissions_active ON public.organization_permissions USING btree (organization_id, user_id, permission_key) WHERE (revoked_at IS NULL);
CREATE INDEX idx_org_permissions_org_user ON public.organization_permissions USING btree (organization_id, user_id);
CREATE INDEX idx_org_pet_home_hidden_org ON public.org_pet_home_hidden USING btree (organization_id, pet_id);
CREATE INDEX idx_org_users_user_id ON public.organization_users USING btree (user_id);
CREATE INDEX idx_organizations_name ON public.organizations USING btree (name);
CREATE UNIQUE INDEX idx_pet_access_pet_user ON public.pet_access USING btree (pet_id, user_id);
CREATE INDEX idx_pet_share_links_code ON public.pet_share_links USING btree (code);
CREATE INDEX idx_pet_share_links_pet_id ON public.pet_share_links USING btree (pet_id);
CREATE INDEX idx_pet_timeline_entries_pet_id ON public.pet_timeline_entries USING btree (pet_id, start_date);
CREATE INDEX idx_prospects_email_lower ON public.prospects USING btree (lower((email)::text)) WHERE (email IS NOT NULL);
CREATE INDEX idx_prospects_org_id ON public.prospects USING btree (organization_id);
CREATE INDEX idx_vets_organization_id ON public.vets USING btree (organization_id);
ALTER TABLE ONLY public.adoption_journeys
    ADD CONSTRAINT adoption_journeys_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.adoption_journeys
    ADD CONSTRAINT adoption_journeys_foster_user_id_fkey FOREIGN KEY (foster_user_id) REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.adoption_journeys
    ADD CONSTRAINT adoption_journeys_fostering_session_id_fkey FOREIGN KEY (fostering_session_id) REFERENCES public.foster_placements(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.adoption_journeys
    ADD CONSTRAINT adoption_journeys_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.adoption_journeys
    ADD CONSTRAINT adoption_journeys_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES public.pets(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.adoption_visits
    ADD CONSTRAINT adoption_visits_assigned_foster_parent_id_fkey FOREIGN KEY (assigned_foster_parent_id) REFERENCES public.org_foster_parents(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.adoption_visits
    ADD CONSTRAINT adoption_visits_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.adoption_visits
    ADD CONSTRAINT adoption_visits_fostering_session_id_fkey FOREIGN KEY (fostering_session_id) REFERENCES public.foster_placements(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.adoption_visits
    ADD CONSTRAINT adoption_visits_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.adoption_visits
    ADD CONSTRAINT adoption_visits_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES public.pets(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.adoption_visits
    ADD CONSTRAINT adoption_visits_prospect_id_fkey FOREIGN KEY (prospect_id) REFERENCES public.prospects(id) ON DELETE SET NULL;
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
ALTER TABLE ONLY public.document_templates
    ADD CONSTRAINT document_templates_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;
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
ALTER TABLE ONLY public.foster_placements
    ADD CONSTRAINT foster_placements_shelter_foster_relationship_id_fkey FOREIGN KEY (shelter_foster_relationship_id) REFERENCES public.org_foster_parents(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.foster_profiles
    ADD CONSTRAINT foster_profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.foster_request_pets
    ADD CONSTRAINT foster_request_pets_foster_request_id_fkey FOREIGN KEY (foster_request_id) REFERENCES public.foster_requests(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.foster_request_pets
    ADD CONSTRAINT foster_request_pets_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES public.pets(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.foster_request_responses
    ADD CONSTRAINT foster_request_responses_foster_request_id_fkey FOREIGN KEY (foster_request_id) REFERENCES public.foster_requests(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.foster_request_responses
    ADD CONSTRAINT foster_request_responses_org_foster_parent_id_fkey FOREIGN KEY (org_foster_parent_id) REFERENCES public.org_foster_parents(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.foster_request_targets
    ADD CONSTRAINT foster_request_targets_foster_request_id_fkey FOREIGN KEY (foster_request_id) REFERENCES public.foster_requests(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.foster_request_targets
    ADD CONSTRAINT foster_request_targets_org_foster_parent_id_fkey FOREIGN KEY (org_foster_parent_id) REFERENCES public.org_foster_parents(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.foster_requests
    ADD CONSTRAINT foster_requests_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.foster_requests
    ADD CONSTRAINT foster_requests_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;
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
ALTER TABLE ONLY public.health_issue_documents
    ADD CONSTRAINT health_issue_documents_health_issue_id_fkey FOREIGN KEY (health_issue_id) REFERENCES public.health_issues(id) ON DELETE CASCADE;
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
    ADD CONSTRAINT org_foster_parents_foster_profile_id_fkey FOREIGN KEY (foster_profile_id) REFERENCES public.foster_profiles(id) ON DELETE SET NULL;
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
ALTER TABLE ONLY public.organization_permissions
    ADD CONSTRAINT organization_permissions_granted_by_fkey FOREIGN KEY (granted_by) REFERENCES public.users(id);
ALTER TABLE ONLY public.organization_permissions
    ADD CONSTRAINT organization_permissions_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.organization_permissions
    ADD CONSTRAINT organization_permissions_revoked_by_fkey FOREIGN KEY (revoked_by) REFERENCES public.users(id);
ALTER TABLE ONLY public.organization_permissions
    ADD CONSTRAINT organization_permissions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
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
ALTER TABLE ONLY public.pet_timeline_entries
    ADD CONSTRAINT pet_timeline_entries_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.pet_timeline_entries
    ADD CONSTRAINT pet_timeline_entries_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES public.pets(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.pets
    ADD CONSTRAINT pets_care_holder_org_id_fkey FOREIGN KEY (care_holder_org_id) REFERENCES public.organizations(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.pets
    ADD CONSTRAINT pets_care_holder_user_id_fkey FOREIGN KEY (care_holder_user_id) REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.pets
    ADD CONSTRAINT pets_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.pets
    ADD CONSTRAINT pets_vet_id_fkey FOREIGN KEY (vet_id) REFERENCES public.vets(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.prospects
    ADD CONSTRAINT prospects_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.prospects
    ADD CONSTRAINT prospects_lawful_basis_attested_by_fkey FOREIGN KEY (lawful_basis_attested_by) REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.prospects
    ADD CONSTRAINT prospects_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.prospects
    ADD CONSTRAINT prospects_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.shared_pets
    ADD CONSTRAINT shared_pets_invited_by_fkey FOREIGN KEY (invited_by) REFERENCES public.users(id);
ALTER TABLE ONLY public.shared_pets
    ADD CONSTRAINT shared_pets_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES public.pets(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.shared_pets
    ADD CONSTRAINT shared_pets_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.vets
    ADD CONSTRAINT vets_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.vets
    ADD CONSTRAINT vets_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.weight_entries
    ADD CONSTRAINT weight_entries_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES public.pets(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.weight_entries
    ADD CONSTRAINT weight_entries_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
