CREATE FUNCTION public.clear_pinned_org_on_membership_loss() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
      IF TG_OP = 'DELETE' THEN
        UPDATE users
           SET pinned_organization_id = NULL,
               updated_at = NOW()
         WHERE id = OLD.user_id
           AND pinned_organization_id = OLD.organization_id;
        RETURN OLD;
      END IF;
      IF TG_OP = 'UPDATE'
         AND NEW.role LIKE 'pending_%'
         AND (OLD.role IS NULL OR OLD.role NOT LIKE 'pending_%') THEN
        UPDATE users
           SET pinned_organization_id = NULL,
               updated_at = NOW()
         WHERE id = NEW.user_id
           AND pinned_organization_id = NEW.organization_id;
      END IF;
      RETURN NEW;
    END;
    $$;
CREATE TABLE public._migrations (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    applied_at timestamp with time zone DEFAULT now()
);
CREATE TABLE public.account_erasure_operations (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    status character varying(20) DEFAULT 'accepted'::character varying NOT NULL,
    status_token_hash character varying(64) NOT NULL,
    requested_at timestamp with time zone DEFAULT now() NOT NULL,
    db_erased_at timestamp with time zone,
    completed_at timestamp with time zone,
    failed_at timestamp with time zone,
    last_error_redacted text,
    CONSTRAINT account_erasure_operations_status_check CHECK (((status)::text = ANY ((ARRAY['accepted'::character varying, 'in_progress'::character varying, 'completed'::character varying, 'failed'::character varying])::text[])))
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
CREATE TABLE public.care_establishments (
    id uuid NOT NULL,
    pet_id uuid NOT NULL,
    care_family character varying(50) NOT NULL,
    health_entry_id uuid NOT NULL,
    established_at timestamp with time zone NOT NULL,
    policy_version character varying(20) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE public.care_milestone_presentations (
    id uuid NOT NULL,
    milestone_id uuid NOT NULL,
    user_id uuid NOT NULL,
    shown_at timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE public.care_milestones (
    id uuid NOT NULL,
    pet_id uuid NOT NULL,
    milestone_type character varying(50) NOT NULL,
    care_family character varying(50),
    source_entity_id uuid,
    care_period_key character varying(50),
    dedupe_key character varying(100) NOT NULL,
    achieved_at timestamp with time zone NOT NULL,
    policy_version character varying(20) NOT NULL,
    bundle_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE public.care_recommendations (
    id uuid NOT NULL,
    pet_id uuid NOT NULL,
    care_family character varying(50) NOT NULL,
    suggestion_key character varying(100) NOT NULL,
    status character varying(30) DEFAULT 'pending'::character varying NOT NULL,
    engine_version character varying(20) NOT NULL,
    knowledge_version character varying(20) NOT NULL,
    suggested_name character varying(255) NOT NULL,
    suggested_frequency character varying(30) NOT NULL,
    suggested_frequency_interval integer DEFAULT 1 NOT NULL,
    rationale_key character varying(100) NOT NULL,
    health_entry_id uuid,
    responded_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE public.care_safeguards (
    id uuid NOT NULL,
    pet_id uuid NOT NULL,
    safeguard_type character varying(50) NOT NULL,
    safeguard_key character varying(100) NOT NULL,
    status character varying(30) DEFAULT 'active'::character varying NOT NULL,
    policy_version character varying(20) NOT NULL,
    copy_key character varying(100) NOT NULL,
    evidence_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    dismissed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE public.care_schedule_events (
    id uuid NOT NULL,
    health_entry_id uuid NOT NULL,
    health_occurrence_id uuid,
    event_type character varying(50) NOT NULL,
    from_date date,
    to_date date,
    from_anchor character varying(50),
    to_anchor character varying(50),
    reason_code character varying(100),
    reason_note text,
    actor_user_id uuid,
    occurred_at timestamp with time zone DEFAULT now() NOT NULL,
    effective_from date,
    idempotency_key character varying(255),
    policy_version character varying(20) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    payload jsonb,
    undone_at timestamp with time zone,
    CONSTRAINT care_schedule_events_event_type_check CHECK (((event_type)::text = ANY ((ARRAY['rescheduled'::character varying, 'skipped'::character varying, 'paused'::character varying, 'resumed'::character varying, 'cadence_adjusted'::character varying, 'completed'::character varying, 'postponed'::character varying, 'materialised'::character varying, 'late_choice_applied'::character varying, 'not_recorded_closed'::character varying, 'schedule_scope_changed'::character varying, 'planned'::character varying, 'recorded'::character varying, 'stack_resolved'::character varying, 'undone'::character varying, 'schedule_changed'::character varying, 'completion_date_changed'::character varying])::text[])))
);
CREATE TABLE public.cleanup_jobs (
    id uuid NOT NULL,
    job_type character varying(64) NOT NULL,
    dedupe_key character varying(255) NOT NULL,
    correlation_id uuid,
    payload jsonb DEFAULT '{}'::jsonb,
    status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    attempts integer DEFAULT 0 NOT NULL,
    max_attempts integer DEFAULT 8 NOT NULL,
    next_attempt_at timestamp with time zone DEFAULT now() NOT NULL,
    lease_token uuid,
    lease_expires_at timestamp with time zone,
    last_error_redacted text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    completed_at timestamp with time zone,
    CONSTRAINT cleanup_jobs_attempts_check CHECK ((attempts >= 0)),
    CONSTRAINT cleanup_jobs_max_attempts_check CHECK ((max_attempts > 0)),
    CONSTRAINT cleanup_jobs_status_check CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'running'::character varying, 'succeeded'::character varying, 'retryable'::character varying, 'dead'::character varying])::text[])))
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
CREATE TABLE public.email_templates (
    id uuid NOT NULL,
    organization_id uuid NOT NULL,
    template_key character varying(100) NOT NULL,
    locale character varying(10) DEFAULT 'en'::character varying NOT NULL,
    subject text NOT NULL,
    body_html text NOT NULL,
    body_text text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
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
    repeat_end_date date,
    schedule_times jsonb,
    care_family character varying(50),
    care_source character varying(50) DEFAULT 'guardian_defined'::character varying,
    paused_since date,
    schedule_policy_version character varying(20),
    care_setting character varying(20) DEFAULT 'home'::character varying NOT NULL,
    care_planning character varying(20) DEFAULT 'planned'::character varying NOT NULL,
    care_importance character varying(20) NOT NULL,
    importance_overridden boolean DEFAULT false NOT NULL,
    provider_contact_id uuid,
    provider_typed_name text,
    care_blocks jsonb DEFAULT '{}'::jsonb NOT NULL,
    schedule_anchor_date date,
    late_completion_choice character varying(16),
    paused_until date,
    series_resumed_on date,
    CONSTRAINT health_entries_late_completion_choice_check CHECK (((late_completion_choice IS NULL) OR ((late_completion_choice)::text = ANY ((ARRAY['keep'::character varying, 'skip_next'::character varying, 'shift_following'::character varying])::text[]))))
);
CREATE TABLE public.health_entry_absence_resolutions (
    id uuid NOT NULL,
    health_entry_id uuid NOT NULL,
    planned_absence_id uuid NOT NULL,
    decision text NOT NULL,
    carer_kind text,
    carer_user_id uuid,
    carer_name text,
    absence_note text,
    dates_decided_for jsonb DEFAULT '[]'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT health_entry_absence_resolutions_carer_fields_check CHECK ((((carer_kind IS NULL) AND (carer_user_id IS NULL) AND (carer_name IS NULL)) OR ((carer_kind = 'shared_user'::text) AND (carer_name IS NULL)) OR ((carer_kind = 'note_only'::text) AND (carer_user_id IS NULL) AND (carer_name IS NOT NULL)))),
    CONSTRAINT health_entry_absence_resolutions_carer_kind_check CHECK (((carer_kind IS NULL) OR (carer_kind = ANY (ARRAY['shared_user'::text, 'note_only'::text])))),
    CONSTRAINT health_entry_absence_resolutions_decision_check CHECK ((decision = ANY (ARRAY['keep_date'::text, 'move_before'::text, 'move_after'::text, 'nothing_needed'::text])))
);
CREATE TABLE public.health_event_photos (
    id uuid NOT NULL,
    health_entry_id uuid NOT NULL,
    url text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    health_occurrence_id uuid
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
CREATE TABLE public.health_occurrences (
    id uuid NOT NULL,
    health_entry_id uuid NOT NULL,
    scheduled_date date NOT NULL,
    scheduled_time time without time zone,
    status character varying(50) DEFAULT 'pending'::character varying NOT NULL,
    completed_on date,
    marked_at timestamp with time zone,
    marked_by_user_id uuid,
    notes text DEFAULT ''::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    completion_timing character varying(20),
    performed_by_user_id uuid,
    performed_by_snapshot jsonb,
    marked_by_snapshot jsonb,
    provider_contact_id uuid,
    provider_typed_name text,
    provider_contact_snapshot jsonb,
    origin character varying(16) DEFAULT 'computed'::character varying NOT NULL,
    close_reason character varying(16),
    series_date date,
    CONSTRAINT health_occurrences_close_reason_check CHECK (((close_reason IS NULL) OR ((close_reason)::text = ANY ((ARRAY['user'::character varying, 'not_recorded'::character varying, 'paused'::character varying, 'covered'::character varying, 'system'::character varying])::text[])))),
    CONSTRAINT health_occurrences_completion_timing_check CHECK (((completion_timing IS NULL) OR ((completion_timing)::text = ANY ((ARRAY['early'::character varying, 'on_time'::character varying, 'late'::character varying])::text[])))),
    CONSTRAINT health_occurrences_origin_check CHECK (((origin)::text = ANY ((ARRAY['schedule'::character varying, 'computed'::character varying, 'planned'::character varying])::text[]))),
    CONSTRAINT health_occurrences_status_check CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'completed'::character varying, 'skipped'::character varying])::text[])))
);
CREATE TABLE public.household_members (
    household_id uuid NOT NULL,
    user_id uuid NOT NULL,
    access_tier text NOT NULL,
    is_organiser boolean DEFAULT false NOT NULL,
    joined_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT household_members_access_tier_check CHECK ((access_tier = ANY (ARRAY['full_access'::text, 'can_log_care'::text])))
);
CREATE TABLE public.household_pets (
    household_id uuid NOT NULL,
    pet_id uuid NOT NULL,
    added_at timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE public.households (
    id uuid NOT NULL,
    name text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
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
    health_entry_id character varying(255),
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
CREATE TABLE public.organization_role_permission_defaults (
    organization_id uuid NOT NULL,
    role_tier character varying(16) NOT NULL,
    permission_key character varying(64) NOT NULL,
    granted boolean DEFAULT true NOT NULL,
    CONSTRAINT organization_role_permission_defaults_tier_check CHECK (((role_tier)::text = ANY ((ARRAY['associate'::character varying, 'admin'::character varying])::text[])))
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
    card_visibility text DEFAULT 'all'::text NOT NULL,
    phone_visibility text DEFAULT 'admins_or_named'::text NOT NULL,
    email_visibility text DEFAULT 'admins_or_named'::text NOT NULL,
    address_visibility text DEFAULT 'admins_or_named'::text NOT NULL,
    CONSTRAINT organization_users_address_visibility_check CHECK ((address_visibility = ANY (ARRAY['admins_or_named'::text, 'admins'::text, 'named'::text, 'hidden'::text]))),
    CONSTRAINT organization_users_card_visibility_check CHECK ((card_visibility = ANY (ARRAY['all'::text, 'admins'::text, 'named'::text]))),
    CONSTRAINT organization_users_email_visibility_check CHECK ((email_visibility = ANY (ARRAY['admins'::text, 'admins_and_foster_managers'::text, 'admins_or_named'::text, 'named'::text]))),
    CONSTRAINT organization_users_phone_visibility_check CHECK ((phone_visibility = ANY (ARRAY['admins'::text, 'admins_and_foster_managers'::text, 'admins_or_named'::text, 'named'::text]))),
    CONSTRAINT organization_users_role_check CHECK (((role)::text = ANY ((ARRAY['associate'::character varying, 'admin'::character varying, 'super_admin'::character varying, 'pending_associate'::character varying, 'pending_admin'::character varying, 'pending_super_admin'::character varying])::text[])))
);
CREATE TABLE public.organization_visibility_grants (
    id uuid NOT NULL,
    organization_id uuid NOT NULL,
    subject_user_id uuid NOT NULL,
    grantee_user_id uuid NOT NULL,
    field text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT organization_visibility_grants_field_check CHECK ((field = ANY (ARRAY['card'::text, 'phone'::text, 'email'::text, 'address'::text])))
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
CREATE TABLE public.people_contact_private_notes (
    contact_id uuid NOT NULL,
    user_id uuid NOT NULL,
    note text DEFAULT ''::text NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE public.people_contact_roles (
    contact_id uuid NOT NULL,
    role text NOT NULL,
    CONSTRAINT people_contact_roles_role_check CHECK ((role = ANY (ARRAY['sitter'::text, 'walker'::text, 'vet'::text, 'vet_nurse'::text, 'groomer'::text, 'trainer'::text, 'behaviourist'::text, 'boarding'::text, 'emergency_contact'::text, 'other'::text])))
);
CREATE TABLE public.people_contacts (
    id uuid NOT NULL,
    directory_id uuid NOT NULL,
    kind text NOT NULL,
    name text NOT NULL,
    phone text,
    email text,
    address text,
    website text,
    works_at_contact_id uuid,
    linked_user_id uuid,
    inactive_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    legacy_vet_id uuid,
    CONSTRAINT people_contacts_kind_check CHECK ((kind = ANY (ARRAY['person'::text, 'organisation'::text])))
);
CREATE TABLE public.people_directories (
    id uuid NOT NULL,
    owner_user_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    household_id uuid,
    CONSTRAINT people_directories_owner_xor_household CHECK ((((owner_user_id IS NOT NULL) AND (household_id IS NULL)) OR ((household_id IS NOT NULL) AND (owner_user_id IS NULL))))
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
CREATE TABLE public.pet_access_events (
    id uuid NOT NULL,
    pet_id uuid NOT NULL,
    subject_user_id uuid,
    event_type text NOT NULL,
    access_source text NOT NULL,
    detail jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT pet_access_events_access_source_check CHECK ((access_source = ANY (ARRAY['household'::text, 'direct_share'::text, 'absence'::text, 'owner'::text])))
);
CREATE TABLE public.pet_activity_events (
    id uuid NOT NULL,
    pet_id uuid NOT NULL,
    org_id uuid NOT NULL,
    event_type text NOT NULL,
    actor_user_id uuid,
    occurred_at timestamp with time zone DEFAULT now() NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT pet_activity_events_event_type_check CHECK ((event_type = ANY (ARRAY['health_log'::text, 'foster_session'::text, 'profile_edit'::text, 'document_upload'::text])))
);
CREATE TABLE public.pet_contact_relationships (
    id uuid NOT NULL,
    pet_id uuid NOT NULL,
    contact_id uuid NOT NULL,
    relationship_kind text NOT NULL,
    is_primary boolean DEFAULT false NOT NULL,
    active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT pet_contact_relationships_relationship_kind_check CHECK ((relationship_kind = ANY (ARRAY['primary_vet'::text, 'out_of_hours_vet'::text, 'emergency_contact'::text, 'care_provider'::text, 'other'::text])))
);
CREATE TABLE public.pet_lifecycle_notifications (
    pet_id uuid NOT NULL,
    event text NOT NULL,
    recipient_user_id uuid NOT NULL,
    notified_at timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE public.pet_share_invite_pets (
    invite_id uuid NOT NULL,
    pet_id uuid NOT NULL
);
CREATE TABLE public.pet_share_invites (
    id uuid NOT NULL,
    inviter_user_id uuid NOT NULL,
    invitee_email character varying(255) NOT NULL,
    invitee_user_id uuid,
    role character varying(20) NOT NULL,
    code character varying(32) NOT NULL,
    status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    responded_at timestamp with time zone,
    expires_at timestamp with time zone NOT NULL,
    CONSTRAINT pet_share_invites_role_check CHECK (((role)::text = ANY ((ARRAY['carer'::character varying, 'co_parent'::character varying])::text[]))),
    CONSTRAINT pet_share_invites_status_check CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'accepted'::character varying, 'declined'::character varying, 'revoked'::character varying, 'expired'::character varying])::text[])))
);
CREATE TABLE public.pet_share_links (
    id uuid NOT NULL,
    pet_id uuid NOT NULL,
    code character varying(32) NOT NULL,
    created_by uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    claimed_by uuid,
    claimed_at timestamp with time zone,
    expires_at timestamp with time zone,
    access_role character varying(32) DEFAULT 'carer'::character varying NOT NULL,
    CONSTRAINT pet_share_links_access_role_check CHECK (((access_role)::text = ANY ((ARRAY['carer'::character varying, 'co_parent'::character varying])::text[])))
);
CREATE TABLE public.pet_tag_assignments (
    pet_tag_id uuid NOT NULL,
    pet_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE public.pet_tags (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    name character varying(64) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
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
    care_holder_org_id uuid,
    last_activity_at timestamp with time zone,
    weight_reference_value double precision,
    weight_reference_authority character varying(50),
    weight_management_context character varying(50) DEFAULT 'none'::character varying NOT NULL,
    home_timezone text DEFAULT 'UTC'::text NOT NULL,
    CONSTRAINT pets_weight_management_context_check CHECK (((weight_management_context)::text = ANY ((ARRAY['none'::character varying, 'vet_managed'::character varying, 'care_plan'::character varying, 'treatment_related'::character varying])::text[]))),
    CONSTRAINT pets_weight_reference_authority_check CHECK (((weight_reference_authority IS NULL) OR ((weight_reference_authority)::text = ANY ((ARRAY['vet_target'::character varying, 'guardian_reference'::character varying, 'historical_baseline'::character varying])::text[]))))
);
CREATE TABLE public.planned_absence_carer_invite_pets (
    invite_id uuid NOT NULL,
    pet_id uuid NOT NULL
);
CREATE TABLE public.planned_absence_carer_invites (
    id uuid NOT NULL,
    planned_absence_id uuid NOT NULL,
    contact_id uuid NOT NULL,
    inviter_user_id uuid NOT NULL,
    invitee_email character varying(255) NOT NULL,
    invitee_user_id uuid,
    code character varying(32) NOT NULL,
    status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    responded_at timestamp with time zone,
    expires_at timestamp with time zone NOT NULL,
    CONSTRAINT planned_absence_carer_invites_status_check CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'accepted'::character varying, 'declined'::character varying, 'revoked'::character varying, 'expired'::character varying])::text[])))
);
CREATE TABLE public.planned_absence_guest_grants (
    id uuid NOT NULL,
    planned_absence_id uuid NOT NULL,
    pet_id uuid NOT NULL,
    grantee_user_id uuid NOT NULL,
    granted_by_user_id uuid NOT NULL,
    contact_id uuid,
    invite_id uuid,
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    revoked_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT planned_absence_guest_grants_status_check CHECK (((status)::text = ANY ((ARRAY['active'::character varying, 'revoked'::character varying, 'expired'::character varying])::text[])))
);
CREATE TABLE public.planned_absence_pets (
    planned_absence_id uuid NOT NULL,
    pet_id uuid NOT NULL,
    carer_kind text,
    carer_user_id uuid,
    carer_name text,
    carer_note text,
    pet_note text,
    contact_id uuid,
    CONSTRAINT planned_absence_pets_carer_fields_check CHECK ((((carer_kind IS NULL) AND (carer_user_id IS NULL) AND (carer_name IS NULL) AND (carer_note IS NULL)) OR ((carer_kind = 'shared_user'::text) AND (carer_name IS NULL) AND (carer_note IS NULL)) OR ((carer_kind = 'note_only'::text) AND (carer_user_id IS NULL) AND (carer_name IS NOT NULL)))),
    CONSTRAINT planned_absence_pets_carer_kind_check CHECK (((carer_kind IS NULL) OR (carer_kind = ANY (ARRAY['shared_user'::text, 'note_only'::text]))))
);
CREATE TABLE public.planned_absences (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    starts_on date NOT NULL,
    ends_on date NOT NULL,
    provenance character varying(50) DEFAULT 'user_declared'::character varying NOT NULL,
    source_ref text,
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    cancelled_at timestamp with time zone,
    handover_note text,
    last_handover_downloaded_at timestamp with time zone,
    timezone character varying(64) DEFAULT 'UTC'::character varying NOT NULL,
    CONSTRAINT planned_absences_date_order CHECK ((ends_on >= starts_on))
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
CREATE TABLE public.refresh_sessions (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    token_hash text NOT NULL,
    family_id uuid NOT NULL,
    rotated_from uuid,
    revoked_at timestamp with time zone,
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE public.refresh_tokens (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    token character varying(255) NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);
CREATE TABLE public.users (
    id uuid NOT NULL,
    email character varying(255) NOT NULL,
    password_hash character varying(255) NOT NULL,
    first_name character varying(100) DEFAULT ''::character varying,
    last_name character varying(100) DEFAULT ''::character varying,
    category character varying(50) DEFAULT 'pet_carer'::character varying,
    bio text DEFAULT ''::text,
    photo_url text DEFAULT ''::text,
    locale character varying(10) DEFAULT 'en'::character varying,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    pinned_organization_id uuid,
    timezone character varying(64) DEFAULT 'UTC'::character varying NOT NULL
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
    created_at timestamp with time zone DEFAULT now(),
    measurement_source character varying(50) DEFAULT 'guardian'::character varying NOT NULL,
    health_occurrence_id uuid,
    CONSTRAINT weight_entries_measurement_source_check CHECK (((measurement_source)::text = ANY ((ARRAY['guardian'::character varying, 'clinic'::character varying, 'device'::character varying, 'imported'::character varying])::text[])))
);
ALTER TABLE ONLY public._migrations
    ADD CONSTRAINT _migrations_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.account_erasure_operations
    ADD CONSTRAINT account_erasure_operations_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.adoption_journeys
    ADD CONSTRAINT adoption_journeys_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.adoption_visits
    ADD CONSTRAINT adoption_visits_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.archived_pets
    ADD CONSTRAINT archived_pets_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.audit_events
    ADD CONSTRAINT audit_events_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.care_establishments
    ADD CONSTRAINT care_establishments_health_entry_id_key UNIQUE (health_entry_id);
ALTER TABLE ONLY public.care_establishments
    ADD CONSTRAINT care_establishments_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.care_milestone_presentations
    ADD CONSTRAINT care_milestone_presentations_milestone_id_user_id_key UNIQUE (milestone_id, user_id);
ALTER TABLE ONLY public.care_milestone_presentations
    ADD CONSTRAINT care_milestone_presentations_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.care_milestones
    ADD CONSTRAINT care_milestones_pet_id_dedupe_key_key UNIQUE (pet_id, dedupe_key);
ALTER TABLE ONLY public.care_milestones
    ADD CONSTRAINT care_milestones_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.care_recommendations
    ADD CONSTRAINT care_recommendations_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.care_safeguards
    ADD CONSTRAINT care_safeguards_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.care_schedule_events
    ADD CONSTRAINT care_schedule_events_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.cleanup_jobs
    ADD CONSTRAINT cleanup_jobs_dedupe_key_key UNIQUE (dedupe_key);
ALTER TABLE ONLY public.cleanup_jobs
    ADD CONSTRAINT cleanup_jobs_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.custody_transfers
    ADD CONSTRAINT custody_transfers_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.document_templates
    ADD CONSTRAINT document_templates_org_key_unique UNIQUE (organization_id, template_key);
ALTER TABLE ONLY public.document_templates
    ADD CONSTRAINT document_templates_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.email_templates
    ADD CONSTRAINT email_templates_organization_id_template_key_locale_key UNIQUE (organization_id, template_key, locale);
ALTER TABLE ONLY public.email_templates
    ADD CONSTRAINT email_templates_pkey PRIMARY KEY (id);
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
ALTER TABLE ONLY public.health_entry_absence_resolutions
    ADD CONSTRAINT health_entry_absence_resoluti_health_entry_id_planned_absen_key UNIQUE (health_entry_id, planned_absence_id);
ALTER TABLE ONLY public.health_entry_absence_resolutions
    ADD CONSTRAINT health_entry_absence_resolutions_pkey PRIMARY KEY (id);
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
ALTER TABLE ONLY public.health_occurrences
    ADD CONSTRAINT health_occurrences_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.household_members
    ADD CONSTRAINT household_members_pkey PRIMARY KEY (household_id, user_id);
ALTER TABLE ONLY public.household_pets
    ADD CONSTRAINT household_pets_pkey PRIMARY KEY (pet_id);
ALTER TABLE ONLY public.households
    ADD CONSTRAINT households_pkey PRIMARY KEY (id);
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
ALTER TABLE ONLY public.organization_role_permission_defaults
    ADD CONSTRAINT organization_role_permission_defaults_pkey PRIMARY KEY (organization_id, role_tier, permission_key);
ALTER TABLE ONLY public.organization_users
    ADD CONSTRAINT organization_users_organization_id_user_id_key UNIQUE (organization_id, user_id);
ALTER TABLE ONLY public.organization_users
    ADD CONSTRAINT organization_users_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.organization_visibility_grants
    ADD CONSTRAINT organization_visibility_grant_organization_id_subject_user__key UNIQUE (organization_id, subject_user_id, grantee_user_id, field);
ALTER TABLE ONLY public.organization_visibility_grants
    ADD CONSTRAINT organization_visibility_grants_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.people_contact_private_notes
    ADD CONSTRAINT people_contact_private_notes_pkey PRIMARY KEY (contact_id, user_id);
ALTER TABLE ONLY public.people_contact_roles
    ADD CONSTRAINT people_contact_roles_pkey PRIMARY KEY (contact_id, role);
ALTER TABLE ONLY public.people_contacts
    ADD CONSTRAINT people_contacts_legacy_vet_id_key UNIQUE (legacy_vet_id);
ALTER TABLE ONLY public.people_contacts
    ADD CONSTRAINT people_contacts_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.people_directories
    ADD CONSTRAINT people_directories_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.pet_access_events
    ADD CONSTRAINT pet_access_events_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.pet_access
    ADD CONSTRAINT pet_access_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.pet_activity_events
    ADD CONSTRAINT pet_activity_events_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.pet_contact_relationships
    ADD CONSTRAINT pet_contact_relationships_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.pet_lifecycle_notifications
    ADD CONSTRAINT pet_lifecycle_notifications_pkey PRIMARY KEY (pet_id, event, recipient_user_id);
ALTER TABLE ONLY public.pet_share_invite_pets
    ADD CONSTRAINT pet_share_invite_pets_pkey PRIMARY KEY (invite_id, pet_id);
ALTER TABLE ONLY public.pet_share_invites
    ADD CONSTRAINT pet_share_invites_code_key UNIQUE (code);
ALTER TABLE ONLY public.pet_share_invites
    ADD CONSTRAINT pet_share_invites_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.pet_share_links
    ADD CONSTRAINT pet_share_links_code_key UNIQUE (code);
ALTER TABLE ONLY public.pet_share_links
    ADD CONSTRAINT pet_share_links_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.pet_tag_assignments
    ADD CONSTRAINT pet_tag_assignments_pkey PRIMARY KEY (pet_tag_id, pet_id);
ALTER TABLE ONLY public.pet_tags
    ADD CONSTRAINT pet_tags_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.pet_timeline_entries
    ADD CONSTRAINT pet_timeline_entries_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.pets
    ADD CONSTRAINT pets_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.planned_absence_carer_invite_pets
    ADD CONSTRAINT planned_absence_carer_invite_pets_pkey PRIMARY KEY (invite_id, pet_id);
ALTER TABLE ONLY public.planned_absence_carer_invites
    ADD CONSTRAINT planned_absence_carer_invites_code_key UNIQUE (code);
ALTER TABLE ONLY public.planned_absence_carer_invites
    ADD CONSTRAINT planned_absence_carer_invites_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.planned_absence_guest_grants
    ADD CONSTRAINT planned_absence_guest_grants_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.planned_absence_guest_grants
    ADD CONSTRAINT planned_absence_guest_grants_unique UNIQUE (planned_absence_id, pet_id, grantee_user_id);
ALTER TABLE ONLY public.planned_absence_pets
    ADD CONSTRAINT planned_absence_pets_pkey PRIMARY KEY (planned_absence_id, pet_id);
ALTER TABLE ONLY public.planned_absences
    ADD CONSTRAINT planned_absences_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.prospects
    ADD CONSTRAINT prospects_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.refresh_sessions
    ADD CONSTRAINT refresh_sessions_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_token_key UNIQUE (token);
ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);
ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.vets
    ADD CONSTRAINT vets_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.weight_entries
    ADD CONSTRAINT weight_entries_pkey PRIMARY KEY (id);
CREATE UNIQUE INDEX care_recommendations_pet_family_key_idx ON public.care_recommendations USING btree (pet_id, care_family, suggestion_key);
CREATE INDEX care_recommendations_pet_status_idx ON public.care_recommendations USING btree (pet_id, status);
CREATE UNIQUE INDEX care_safeguards_pet_key_idx ON public.care_safeguards USING btree (pet_id, safeguard_key);
CREATE INDEX care_safeguards_pet_status_idx ON public.care_safeguards USING btree (pet_id, status);
CREATE INDEX idx_account_erasure_operations_status ON public.account_erasure_operations USING btree (status);
CREATE UNIQUE INDEX idx_account_erasure_operations_user_id ON public.account_erasure_operations USING btree (user_id);
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
CREATE INDEX idx_care_establishments_pet_family ON public.care_establishments USING btree (pet_id, care_family);
CREATE INDEX idx_care_establishments_pet_id ON public.care_establishments USING btree (pet_id);
CREATE INDEX idx_care_milestone_presentations_user ON public.care_milestone_presentations USING btree (user_id, shown_at DESC);
CREATE INDEX idx_care_milestones_pet_bundle ON public.care_milestones USING btree (pet_id, bundle_id);
CREATE INDEX idx_care_milestones_pet_id ON public.care_milestones USING btree (pet_id);
CREATE INDEX idx_care_schedule_events_entry_occurred ON public.care_schedule_events USING btree (health_entry_id, occurred_at DESC);
CREATE UNIQUE INDEX idx_care_schedule_events_idempotency ON public.care_schedule_events USING btree (idempotency_key) WHERE (idempotency_key IS NOT NULL);
CREATE INDEX idx_care_schedule_events_occurrence ON public.care_schedule_events USING btree (health_occurrence_id) WHERE (health_occurrence_id IS NOT NULL);
CREATE INDEX idx_cleanup_jobs_correlation_id ON public.cleanup_jobs USING btree (correlation_id) WHERE (correlation_id IS NOT NULL);
CREATE INDEX idx_cleanup_jobs_status_next_attempt ON public.cleanup_jobs USING btree (status, next_attempt_at);
CREATE INDEX idx_custody_transfers_pet_status ON public.custody_transfers USING btree (pet_id, status);
CREATE INDEX idx_custody_transfers_to_org ON public.custody_transfers USING btree (to_org_id, status);
CREATE INDEX idx_document_templates_org_type ON public.document_templates USING btree (organization_id, template_type);
CREATE INDEX idx_email_templates_org_key ON public.email_templates USING btree (organization_id, template_key);
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
CREATE INDEX idx_health_entries_care_tick ON public.health_entries USING btree (status, recurrence_anchor) WHERE ((status)::text = ANY ((ARRAY['active'::character varying, 'paused'::character varying])::text[]));
CREATE INDEX idx_health_entries_pet_id ON public.health_entries USING btree (pet_id);
CREATE INDEX idx_health_entries_provider_contact_id ON public.health_entries USING btree (provider_contact_id) WHERE (provider_contact_id IS NOT NULL);
CREATE INDEX idx_health_entries_user_id ON public.health_entries USING btree (user_id);
CREATE INDEX idx_health_entry_absence_resolutions_absence ON public.health_entry_absence_resolutions USING btree (planned_absence_id);
CREATE INDEX idx_health_entry_absence_resolutions_entry ON public.health_entry_absence_resolutions USING btree (health_entry_id);
CREATE INDEX idx_health_event_photos_occurrence ON public.health_event_photos USING btree (health_occurrence_id) WHERE (health_occurrence_id IS NOT NULL);
CREATE INDEX idx_health_issue_documents_issue_id ON public.health_issue_documents USING btree (health_issue_id);
CREATE INDEX idx_health_occurrences_entry_id ON public.health_occurrences USING btree (health_entry_id);
CREATE INDEX idx_health_occurrences_entry_series_slot ON public.health_occurrences USING btree (health_entry_id, COALESCE(series_date, scheduled_date));
CREATE INDEX idx_health_occurrences_entry_status_date ON public.health_occurrences USING btree (health_entry_id, status, scheduled_date, scheduled_time);
CREATE UNIQUE INDEX idx_health_occurrences_open_slot ON public.health_occurrences USING btree (health_entry_id, scheduled_date, COALESCE(scheduled_time, '00:00:00'::time without time zone)) WHERE ((status)::text = 'pending'::text);
CREATE INDEX idx_health_occurrences_provider_contact_id ON public.health_occurrences USING btree (provider_contact_id) WHERE (provider_contact_id IS NOT NULL);
CREATE INDEX idx_household_members_user_id ON public.household_members USING btree (user_id);
CREATE INDEX idx_household_pets_household_id ON public.household_pets USING btree (household_id);
CREATE INDEX idx_notifications_user_id ON public.notifications USING btree (user_id);
CREATE INDEX idx_org_connection_requests_target ON public.org_connection_requests USING btree (target_org_id, status);
CREATE INDEX idx_org_connections_high ON public.org_connections USING btree (org_high_id);
CREATE INDEX idx_org_connections_low ON public.org_connections USING btree (org_low_id);
CREATE INDEX idx_org_foster_parents_org_id ON public.org_foster_parents USING btree (organization_id);
CREATE UNIQUE INDEX idx_org_permissions_active ON public.organization_permissions USING btree (organization_id, user_id, permission_key) WHERE (revoked_at IS NULL);
CREATE INDEX idx_org_permissions_org_user ON public.organization_permissions USING btree (organization_id, user_id);
CREATE INDEX idx_org_pet_home_hidden_org ON public.org_pet_home_hidden USING btree (organization_id, pet_id);
CREATE INDEX idx_org_role_permission_defaults_org_tier ON public.organization_role_permission_defaults USING btree (organization_id, role_tier);
CREATE INDEX idx_org_users_user_id ON public.organization_users USING btree (user_id);
CREATE INDEX idx_org_visibility_grants_grantee ON public.organization_visibility_grants USING btree (organization_id, grantee_user_id);
CREATE INDEX idx_org_visibility_grants_subject ON public.organization_visibility_grants USING btree (organization_id, subject_user_id);
CREATE INDEX idx_organizations_name ON public.organizations USING btree (name);
CREATE INDEX idx_pa_carer_invites_absence ON public.planned_absence_carer_invites USING btree (planned_absence_id);
CREATE INDEX idx_pa_carer_invites_invitee_email ON public.planned_absence_carer_invites USING btree (lower((invitee_email)::text));
CREATE INDEX idx_pa_guest_grants_grantee_active ON public.planned_absence_guest_grants USING btree (grantee_user_id) WHERE ((status)::text = 'active'::text);
CREATE INDEX idx_pa_guest_grants_pet_active ON public.planned_absence_guest_grants USING btree (pet_id) WHERE ((status)::text = 'active'::text);
CREATE INDEX idx_people_contacts_directory_id ON public.people_contacts USING btree (directory_id);
CREATE INDEX idx_people_contacts_legacy_vet_id ON public.people_contacts USING btree (legacy_vet_id) WHERE (legacy_vet_id IS NOT NULL);
CREATE INDEX idx_pet_access_events_pet_created ON public.pet_access_events USING btree (pet_id, created_at DESC);
CREATE UNIQUE INDEX idx_pet_access_pet_user ON public.pet_access USING btree (pet_id, user_id);
CREATE INDEX idx_pet_activity_events_occurred_at ON public.pet_activity_events USING btree (occurred_at);
CREATE INDEX idx_pet_activity_events_org_id ON public.pet_activity_events USING btree (org_id);
CREATE INDEX idx_pet_activity_events_pet_id ON public.pet_activity_events USING btree (pet_id);
CREATE INDEX idx_pet_contact_relationships_contact_id ON public.pet_contact_relationships USING btree (contact_id);
CREATE INDEX idx_pet_contact_relationships_pet_id ON public.pet_contact_relationships USING btree (pet_id);
CREATE INDEX idx_pet_lifecycle_notifications_recipient ON public.pet_lifecycle_notifications USING btree (recipient_user_id);
CREATE INDEX idx_pet_share_invite_pets_pet_id ON public.pet_share_invite_pets USING btree (pet_id);
CREATE INDEX idx_pet_share_invites_invitee_email ON public.pet_share_invites USING btree (lower((invitee_email)::text));
CREATE INDEX idx_pet_share_invites_invitee_user_id ON public.pet_share_invites USING btree (invitee_user_id) WHERE (invitee_user_id IS NOT NULL);
CREATE INDEX idx_pet_share_links_code ON public.pet_share_links USING btree (code);
CREATE INDEX idx_pet_share_links_expires_at ON public.pet_share_links USING btree (expires_at) WHERE ((status)::text = 'pending'::text);
CREATE INDEX idx_pet_share_links_pet_id ON public.pet_share_links USING btree (pet_id);
CREATE INDEX idx_pet_tag_assignments_pet_id ON public.pet_tag_assignments USING btree (pet_id);
CREATE UNIQUE INDEX idx_pet_tags_user_name_lower ON public.pet_tags USING btree (user_id, lower((name)::text));
CREATE INDEX idx_pet_timeline_entries_pet_id ON public.pet_timeline_entries USING btree (pet_id, start_date);
CREATE INDEX idx_planned_absence_pets_contact_id ON public.planned_absence_pets USING btree (contact_id) WHERE (contact_id IS NOT NULL);
CREATE INDEX idx_planned_absence_pets_pet ON public.planned_absence_pets USING btree (pet_id);
CREATE INDEX idx_planned_absences_user_starts ON public.planned_absences USING btree (user_id, starts_on);
CREATE INDEX idx_prospects_email_lower ON public.prospects USING btree (lower((email)::text)) WHERE (email IS NOT NULL);
CREATE INDEX idx_prospects_org_id ON public.prospects USING btree (organization_id);
CREATE INDEX idx_refresh_sessions_family_id ON public.refresh_sessions USING btree (family_id);
CREATE UNIQUE INDEX idx_refresh_sessions_token_hash ON public.refresh_sessions USING btree (token_hash);
CREATE INDEX idx_refresh_sessions_user_id ON public.refresh_sessions USING btree (user_id);
CREATE INDEX idx_users_pinned_organization_id ON public.users USING btree (pinned_organization_id) WHERE (pinned_organization_id IS NOT NULL);
CREATE INDEX idx_vets_organization_id ON public.vets USING btree (organization_id);
CREATE UNIQUE INDEX idx_weight_entries_health_occurrence_id ON public.weight_entries USING btree (health_occurrence_id) WHERE (health_occurrence_id IS NOT NULL);
CREATE UNIQUE INDEX people_directories_household_unique ON public.people_directories USING btree (household_id) WHERE (household_id IS NOT NULL);
CREATE UNIQUE INDEX people_directories_owner_user_unique ON public.people_directories USING btree (owner_user_id) WHERE (owner_user_id IS NOT NULL);
CREATE TRIGGER trg_clear_pinned_org_on_membership_loss AFTER DELETE OR UPDATE OF role ON public.organization_users FOR EACH ROW EXECUTE FUNCTION public.clear_pinned_org_on_membership_loss();
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
ALTER TABLE ONLY public.care_establishments
    ADD CONSTRAINT care_establishments_health_entry_id_fkey FOREIGN KEY (health_entry_id) REFERENCES public.health_entries(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.care_establishments
    ADD CONSTRAINT care_establishments_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES public.pets(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.care_milestone_presentations
    ADD CONSTRAINT care_milestone_presentations_milestone_id_fkey FOREIGN KEY (milestone_id) REFERENCES public.care_milestones(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.care_milestone_presentations
    ADD CONSTRAINT care_milestone_presentations_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.care_milestones
    ADD CONSTRAINT care_milestones_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES public.pets(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.care_recommendations
    ADD CONSTRAINT care_recommendations_health_entry_id_fkey FOREIGN KEY (health_entry_id) REFERENCES public.health_entries(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.care_recommendations
    ADD CONSTRAINT care_recommendations_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES public.pets(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.care_safeguards
    ADD CONSTRAINT care_safeguards_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES public.pets(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.care_schedule_events
    ADD CONSTRAINT care_schedule_events_actor_user_id_fkey FOREIGN KEY (actor_user_id) REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.care_schedule_events
    ADD CONSTRAINT care_schedule_events_health_entry_id_fkey FOREIGN KEY (health_entry_id) REFERENCES public.health_entries(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.care_schedule_events
    ADD CONSTRAINT care_schedule_events_health_occurrence_id_fkey FOREIGN KEY (health_occurrence_id) REFERENCES public.health_occurrences(id) ON DELETE SET NULL;
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
ALTER TABLE ONLY public.email_templates
    ADD CONSTRAINT email_templates_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;
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
    ADD CONSTRAINT health_entries_provider_contact_id_fkey FOREIGN KEY (provider_contact_id) REFERENCES public.people_contacts(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.health_entries
    ADD CONSTRAINT health_entries_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.health_entry_absence_resolutions
    ADD CONSTRAINT health_entry_absence_resolutions_carer_user_id_fkey FOREIGN KEY (carer_user_id) REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.health_entry_absence_resolutions
    ADD CONSTRAINT health_entry_absence_resolutions_health_entry_id_fkey FOREIGN KEY (health_entry_id) REFERENCES public.health_entries(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.health_entry_absence_resolutions
    ADD CONSTRAINT health_entry_absence_resolutions_planned_absence_id_fkey FOREIGN KEY (planned_absence_id) REFERENCES public.planned_absences(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.health_event_photos
    ADD CONSTRAINT health_event_photos_health_entry_id_fkey FOREIGN KEY (health_entry_id) REFERENCES public.health_entries(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.health_event_photos
    ADD CONSTRAINT health_event_photos_health_occurrence_id_fkey FOREIGN KEY (health_occurrence_id) REFERENCES public.health_occurrences(id) ON DELETE SET NULL;
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
ALTER TABLE ONLY public.health_occurrences
    ADD CONSTRAINT health_occurrences_health_entry_id_fkey FOREIGN KEY (health_entry_id) REFERENCES public.health_entries(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.health_occurrences
    ADD CONSTRAINT health_occurrences_marked_by_user_id_fkey FOREIGN KEY (marked_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.health_occurrences
    ADD CONSTRAINT health_occurrences_performed_by_user_id_fkey FOREIGN KEY (performed_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.health_occurrences
    ADD CONSTRAINT health_occurrences_provider_contact_id_fkey FOREIGN KEY (provider_contact_id) REFERENCES public.people_contacts(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.household_members
    ADD CONSTRAINT household_members_household_id_fkey FOREIGN KEY (household_id) REFERENCES public.households(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.household_members
    ADD CONSTRAINT household_members_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.household_pets
    ADD CONSTRAINT household_pets_household_id_fkey FOREIGN KEY (household_id) REFERENCES public.households(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.household_pets
    ADD CONSTRAINT household_pets_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES public.pets(id) ON DELETE CASCADE;
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
ALTER TABLE ONLY public.organization_role_permission_defaults
    ADD CONSTRAINT organization_role_permission_defaults_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.organization_users
    ADD CONSTRAINT organization_users_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.organization_users
    ADD CONSTRAINT organization_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.organization_visibility_grants
    ADD CONSTRAINT organization_visibility_grants_grantee_user_id_fkey FOREIGN KEY (grantee_user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.organization_visibility_grants
    ADD CONSTRAINT organization_visibility_grants_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.organization_visibility_grants
    ADD CONSTRAINT organization_visibility_grants_subject_user_id_fkey FOREIGN KEY (subject_user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.people_contact_private_notes
    ADD CONSTRAINT people_contact_private_notes_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES public.people_contacts(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.people_contact_private_notes
    ADD CONSTRAINT people_contact_private_notes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.people_contact_roles
    ADD CONSTRAINT people_contact_roles_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES public.people_contacts(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.people_contacts
    ADD CONSTRAINT people_contacts_directory_id_fkey FOREIGN KEY (directory_id) REFERENCES public.people_directories(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.people_contacts
    ADD CONSTRAINT people_contacts_legacy_vet_id_fkey FOREIGN KEY (legacy_vet_id) REFERENCES public.vets(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.people_contacts
    ADD CONSTRAINT people_contacts_linked_user_id_fkey FOREIGN KEY (linked_user_id) REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.people_contacts
    ADD CONSTRAINT people_contacts_works_at_contact_id_fkey FOREIGN KEY (works_at_contact_id) REFERENCES public.people_contacts(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.people_directories
    ADD CONSTRAINT people_directories_household_id_fkey FOREIGN KEY (household_id) REFERENCES public.households(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.people_directories
    ADD CONSTRAINT people_directories_owner_user_id_fkey FOREIGN KEY (owner_user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.pet_access_events
    ADD CONSTRAINT pet_access_events_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES public.pets(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.pet_access_events
    ADD CONSTRAINT pet_access_events_subject_user_id_fkey FOREIGN KEY (subject_user_id) REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.pet_access
    ADD CONSTRAINT pet_access_invited_by_fkey FOREIGN KEY (invited_by) REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.pet_access
    ADD CONSTRAINT pet_access_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES public.pets(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.pet_access
    ADD CONSTRAINT pet_access_share_link_id_fkey FOREIGN KEY (share_link_id) REFERENCES public.pet_share_links(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.pet_access
    ADD CONSTRAINT pet_access_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.pet_activity_events
    ADD CONSTRAINT pet_activity_events_actor_user_id_fkey FOREIGN KEY (actor_user_id) REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.pet_activity_events
    ADD CONSTRAINT pet_activity_events_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.pet_activity_events
    ADD CONSTRAINT pet_activity_events_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES public.pets(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.pet_contact_relationships
    ADD CONSTRAINT pet_contact_relationships_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES public.people_contacts(id) ON DELETE RESTRICT;
ALTER TABLE ONLY public.pet_contact_relationships
    ADD CONSTRAINT pet_contact_relationships_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES public.pets(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.pet_lifecycle_notifications
    ADD CONSTRAINT pet_lifecycle_notifications_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES public.pets(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.pet_lifecycle_notifications
    ADD CONSTRAINT pet_lifecycle_notifications_recipient_user_id_fkey FOREIGN KEY (recipient_user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.pet_share_invite_pets
    ADD CONSTRAINT pet_share_invite_pets_invite_id_fkey FOREIGN KEY (invite_id) REFERENCES public.pet_share_invites(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.pet_share_invite_pets
    ADD CONSTRAINT pet_share_invite_pets_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES public.pets(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.pet_share_invites
    ADD CONSTRAINT pet_share_invites_invitee_user_id_fkey FOREIGN KEY (invitee_user_id) REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.pet_share_invites
    ADD CONSTRAINT pet_share_invites_inviter_user_id_fkey FOREIGN KEY (inviter_user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.pet_share_links
    ADD CONSTRAINT pet_share_links_claimed_by_fkey FOREIGN KEY (claimed_by) REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.pet_share_links
    ADD CONSTRAINT pet_share_links_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.pet_share_links
    ADD CONSTRAINT pet_share_links_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES public.pets(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.pet_tag_assignments
    ADD CONSTRAINT pet_tag_assignments_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES public.pets(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.pet_tag_assignments
    ADD CONSTRAINT pet_tag_assignments_pet_tag_id_fkey FOREIGN KEY (pet_tag_id) REFERENCES public.pet_tags(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.pet_tags
    ADD CONSTRAINT pet_tags_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
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
ALTER TABLE ONLY public.planned_absence_carer_invite_pets
    ADD CONSTRAINT planned_absence_carer_invite_pets_invite_id_fkey FOREIGN KEY (invite_id) REFERENCES public.planned_absence_carer_invites(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.planned_absence_carer_invite_pets
    ADD CONSTRAINT planned_absence_carer_invite_pets_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES public.pets(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.planned_absence_carer_invites
    ADD CONSTRAINT planned_absence_carer_invites_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES public.people_contacts(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.planned_absence_carer_invites
    ADD CONSTRAINT planned_absence_carer_invites_invitee_user_id_fkey FOREIGN KEY (invitee_user_id) REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.planned_absence_carer_invites
    ADD CONSTRAINT planned_absence_carer_invites_inviter_user_id_fkey FOREIGN KEY (inviter_user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.planned_absence_carer_invites
    ADD CONSTRAINT planned_absence_carer_invites_planned_absence_id_fkey FOREIGN KEY (planned_absence_id) REFERENCES public.planned_absences(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.planned_absence_guest_grants
    ADD CONSTRAINT planned_absence_guest_grants_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES public.people_contacts(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.planned_absence_guest_grants
    ADD CONSTRAINT planned_absence_guest_grants_granted_by_user_id_fkey FOREIGN KEY (granted_by_user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.planned_absence_guest_grants
    ADD CONSTRAINT planned_absence_guest_grants_grantee_user_id_fkey FOREIGN KEY (grantee_user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.planned_absence_guest_grants
    ADD CONSTRAINT planned_absence_guest_grants_invite_id_fkey FOREIGN KEY (invite_id) REFERENCES public.planned_absence_carer_invites(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.planned_absence_guest_grants
    ADD CONSTRAINT planned_absence_guest_grants_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES public.pets(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.planned_absence_guest_grants
    ADD CONSTRAINT planned_absence_guest_grants_planned_absence_id_fkey FOREIGN KEY (planned_absence_id) REFERENCES public.planned_absences(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.planned_absence_pets
    ADD CONSTRAINT planned_absence_pets_carer_user_id_fkey FOREIGN KEY (carer_user_id) REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.planned_absence_pets
    ADD CONSTRAINT planned_absence_pets_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES public.people_contacts(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.planned_absence_pets
    ADD CONSTRAINT planned_absence_pets_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES public.pets(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.planned_absence_pets
    ADD CONSTRAINT planned_absence_pets_planned_absence_id_fkey FOREIGN KEY (planned_absence_id) REFERENCES public.planned_absences(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.planned_absences
    ADD CONSTRAINT planned_absences_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.prospects
    ADD CONSTRAINT prospects_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.prospects
    ADD CONSTRAINT prospects_lawful_basis_attested_by_fkey FOREIGN KEY (lawful_basis_attested_by) REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.prospects
    ADD CONSTRAINT prospects_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.prospects
    ADD CONSTRAINT prospects_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.refresh_sessions
    ADD CONSTRAINT refresh_sessions_rotated_from_fkey FOREIGN KEY (rotated_from) REFERENCES public.refresh_sessions(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.refresh_sessions
    ADD CONSTRAINT refresh_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pinned_organization_id_fkey FOREIGN KEY (pinned_organization_id) REFERENCES public.organizations(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.vets
    ADD CONSTRAINT vets_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.vets
    ADD CONSTRAINT vets_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.weight_entries
    ADD CONSTRAINT weight_entries_health_occurrence_id_fkey FOREIGN KEY (health_occurrence_id) REFERENCES public.health_occurrences(id) ON DELETE SET NULL;
ALTER TABLE ONLY public.weight_entries
    ADD CONSTRAINT weight_entries_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES public.pets(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.weight_entries
    ADD CONSTRAINT weight_entries_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
