-- =============================================================================
-- Invoice Metadata and Tags Table
-- =============================================================================
-- This file normalizes the metadata JSONB column and tags array from the invoices table
-- into separate tables with proper structure and relationships

-- =============================================================================
-- Invoice Metadata Table
-- =============================================================================

CREATE TABLE IF NOT EXISTS invoice_metadata (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Metadata identification
    metadata_key VARCHAR(100) NOT NULL,
    metadata_type VARCHAR(30) DEFAULT 'text' CHECK (metadata_type IN (
        'text', 'number', 'boolean', 'date', 'datetime', 'url', 'email', 'phone', 
        'json', 'array', 'object', 'file', 'image', 'currency', 'percentage'
    )),
    metadata_category VARCHAR(50) DEFAULT 'general' CHECK (metadata_category IN (
        'general', 'business', 'technical', 'marketing', 'analytics', 'compliance',
        'integration', 'customization', 'workflow', 'reporting', 'audit', 'seo'
    )),
    
    -- Metadata values (polymorphic storage)
    text_value TEXT,
    number_value DECIMAL(15,4),
    boolean_value BOOLEAN,
    date_value DATE,
    datetime_value TIMESTAMPTZ,
    json_value JSONB,
    array_value TEXT[],
    
    -- Display and formatting
    display_name VARCHAR(255),
    display_order INTEGER DEFAULT 100,
    display_format VARCHAR(50), -- How to format the value for display
    display_unit VARCHAR(20), -- Unit for numeric values
    
    -- Validation and constraints
    is_required BOOLEAN DEFAULT FALSE,
    is_readonly BOOLEAN DEFAULT FALSE,
    is_system_generated BOOLEAN DEFAULT FALSE,
    validation_rules JSONB DEFAULT '{}', -- JSON schema for validation
    default_value TEXT,
    
    -- Visibility and permissions
    is_visible BOOLEAN DEFAULT TRUE,
    is_public BOOLEAN DEFAULT FALSE, -- Can be shown to customers
    is_internal BOOLEAN DEFAULT FALSE, -- Internal use only
    visibility_level VARCHAR(20) DEFAULT 'admin' CHECK (visibility_level IN (
        'public', 'customer', 'staff', 'admin', 'system'
    )),
    
    -- Localization
    language_code VARCHAR(5) DEFAULT 'en', -- ISO 639-1
    localized_values JSONB DEFAULT '{}', -- Values in different languages
    localized_display_names JSONB DEFAULT '{}', -- Display names in different languages
    
    -- Data source and provenance
    data_source VARCHAR(50) DEFAULT 'manual' CHECK (data_source IN (
        'manual', 'api', 'import', 'system', 'integration', 'webhook', 'calculation'
    )),
    source_system VARCHAR(100), -- Which system provided this metadata
    source_reference VARCHAR(255), -- Reference in source system
    
    -- Versioning and history
    version INTEGER DEFAULT 1,
    previous_value TEXT, -- Previous value for change tracking
    change_reason VARCHAR(255), -- Reason for last change
    
    -- Performance and caching
    is_indexed BOOLEAN DEFAULT FALSE, -- Should this be indexed for search
    is_cached BOOLEAN DEFAULT FALSE, -- Should this be cached
    cache_ttl INTEGER, -- Cache time-to-live in seconds
    
    -- SEO and marketing
    seo_relevant BOOLEAN DEFAULT FALSE,
    meta_tag_name VARCHAR(100), -- HTML meta tag name
    meta_tag_content TEXT, -- HTML meta tag content
    
    -- Privacy and compliance
    contains_pii BOOLEAN DEFAULT FALSE, -- Contains personally identifiable information
    gdpr_category VARCHAR(50), -- GDPR data category
    retention_period_days INTEGER, -- How long to retain this data
    
    -- Auto-expiration
    expires_at TIMESTAMPTZ, -- When this metadata expires
    auto_delete_on_expiry BOOLEAN DEFAULT FALSE,
    
    -- External integrations
    external_metadata_id VARCHAR(255),
    integration_mapping JSONB DEFAULT '{}', -- Mapping to external systems
    
    -- Data quality and validation
    data_quality_score DECIMAL(3,2) CHECK (data_quality_score >= 0 AND data_quality_score <= 1),
    validation_status VARCHAR(20) DEFAULT 'valid' CHECK (validation_status IN (
        'valid', 'invalid', 'warning', 'pending_validation'
    )),
    validation_errors TEXT[],
    
    -- Sync information
    sync_status VARCHAR(20) DEFAULT 'synced' CHECK (sync_status IN ('pending', 'syncing', 'synced', 'error')),
    last_sync_at TIMESTAMPTZ,
    sync_errors JSONB DEFAULT '[]',
    
    -- Custom fields for extensibility
    custom_fields JSONB DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    UNIQUE(invoice_id, metadata_key, language_code),
    CHECK (
        (metadata_type = 'text' AND text_value IS NOT NULL) OR
        (metadata_type = 'number' AND number_value IS NOT NULL) OR
        (metadata_type = 'boolean' AND boolean_value IS NOT NULL) OR
        (metadata_type = 'date' AND date_value IS NOT NULL) OR
        (metadata_type = 'datetime' AND datetime_value IS NOT NULL) OR
        (metadata_type IN ('json', 'object') AND json_value IS NOT NULL) OR
        (metadata_type = 'array' AND array_value IS NOT NULL) OR
        metadata_type IN ('url', 'email', 'phone', 'file', 'image', 'currency', 'percentage')
    )
);

-- =============================================================================
-- Invoice Metadata History Table
-- =============================================================================
-- Track changes to metadata

CREATE TABLE IF NOT EXISTS invoice_metadata_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    metadata_id UUID NOT NULL REFERENCES invoice_metadata(id) ON DELETE CASCADE,
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Change tracking
    change_type VARCHAR(20) NOT NULL CHECK (change_type IN (
        'created', 'updated', 'deleted', 'value_changed', 'visibility_changed',
        'validation_updated', 'expired', 'synced'
    )),
    changed_fields JSONB, -- Array of field names that changed
    old_values JSONB, -- Previous values of changed fields
    new_values JSONB, -- New values of changed fields
    
    -- Change context
    change_reason VARCHAR(255),
    change_source VARCHAR(50) DEFAULT 'manual' CHECK (change_source IN (
        'manual', 'api', 'import', 'system', 'integration', 'webhook', 'expiration'
    )),
    
    -- User context
    changed_by_user_id UUID,
    changed_by_user_type VARCHAR(20) DEFAULT 'admin' CHECK (changed_by_user_type IN (
        'admin', 'system', 'api', 'customer', 'integration'
    )),
    
    -- Session context
    session_id VARCHAR(255),
    request_id VARCHAR(255),
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- Invoice Metadata Templates Table
-- =============================================================================
-- Store reusable metadata templates

CREATE TABLE IF NOT EXISTS invoice_metadata_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Template identification
    template_name VARCHAR(100) NOT NULL,
    template_description TEXT,
    template_category VARCHAR(50) DEFAULT 'general',
    
    -- Template configuration
    metadata_schema JSONB NOT NULL, -- JSON schema defining the metadata structure
    default_values JSONB DEFAULT '{}', -- Default values for metadata fields
    
    -- Template properties
    is_active BOOLEAN DEFAULT TRUE,
    is_system_template BOOLEAN DEFAULT FALSE,
    usage_count INTEGER DEFAULT 0,
    
    -- Validation and constraints
    validation_rules JSONB DEFAULT '{}',
    required_fields TEXT[],
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    UNIQUE(store_id, template_name)
);

-- =============================================================================
-- Invoice Tags Table
-- =============================================================================

CREATE TABLE IF NOT EXISTS invoice_tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Tag identification
    tag_name VARCHAR(100) NOT NULL,
    tag_slug VARCHAR(100) NOT NULL, -- URL-friendly version
    tag_type VARCHAR(30) DEFAULT 'general' CHECK (tag_type IN (
        'general', 'category', 'status', 'priority', 'workflow', 'marketing',
        'compliance', 'integration', 'custom', 'system', 'temporary'
    )),
    
    -- Tag properties
    tag_color VARCHAR(7) CHECK (tag_color ~ '^#[0-9A-Fa-f]{6}$'), -- Hex color for display
    tag_icon VARCHAR(50), -- Icon name or Unicode
    tag_description TEXT,
    
    -- Assignment properties
    assigned_by_user_id UUID,
    assignment_reason VARCHAR(255),
    assignment_source VARCHAR(50) DEFAULT 'manual' CHECK (assignment_source IN (
        'manual', 'api', 'import', 'system', 'rule', 'ai', 'webhook'
    )),
    
    -- Display and formatting
    display_order INTEGER DEFAULT 100,
    is_visible BOOLEAN DEFAULT TRUE,
    is_public BOOLEAN DEFAULT FALSE, -- Can be shown to customers
    
    -- Lifecycle management
    is_active BOOLEAN DEFAULT TRUE,
    is_temporary BOOLEAN DEFAULT FALSE,
    expires_at TIMESTAMPTZ, -- When this tag assignment expires
    auto_remove_on_expiry BOOLEAN DEFAULT FALSE,
    
    -- Performance and analytics
    click_count INTEGER DEFAULT 0,
    view_count INTEGER DEFAULT 0,
    last_clicked_at TIMESTAMPTZ,
    last_viewed_at TIMESTAMPTZ,
    
    -- A/B testing and experimentation
    ab_test_variant VARCHAR(50),
    experiment_id VARCHAR(100),
    
    -- Context and conditions
    context_data JSONB DEFAULT '{}', -- Additional context for the tag
    conditional_rules JSONB DEFAULT '{}', -- Rules for when tag should be shown
    
    -- Quality and relevance
    relevance_score DECIMAL(3,2) DEFAULT 1.0 CHECK (relevance_score >= 0 AND relevance_score <= 1),
    quality_score DECIMAL(3,2) DEFAULT 1.0 CHECK (quality_score >= 0 AND quality_score <= 1),
    
    -- Localization
    language_code VARCHAR(5) DEFAULT 'en',
    localized_names JSONB DEFAULT '{}',
    localized_descriptions JSONB DEFAULT '{}',
    
    -- External integrations
    external_tag_id VARCHAR(255),
    integration_mapping JSONB DEFAULT '{}',
    
    -- Sync information
    sync_status VARCHAR(20) DEFAULT 'synced' CHECK (sync_status IN ('pending', 'syncing', 'synced', 'error')),
    last_sync_at TIMESTAMPTZ,
    sync_errors JSONB DEFAULT '[]',
    
    -- Custom fields for extensibility
    custom_fields JSONB DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    UNIQUE(invoice_id, tag_name, language_code)
);

-- =============================================================================
-- Invoice Tag History Table
-- =============================================================================
-- Track changes to tag assignments

CREATE TABLE IF NOT EXISTS invoice_tag_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tag_id UUID NOT NULL REFERENCES invoice_tags(id) ON DELETE CASCADE,
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Change tracking
    change_type VARCHAR(20) NOT NULL CHECK (change_type IN (
        'assigned', 'removed', 'updated', 'activated', 'deactivated', 'expired', 'clicked', 'viewed'
    )),
    changed_fields JSONB,
    old_values JSONB,
    new_values JSONB,
    
    -- Change context
    change_reason VARCHAR(255),
    change_source VARCHAR(50) DEFAULT 'manual',
    
    -- User context
    changed_by_user_id UUID,
    changed_by_user_type VARCHAR(20) DEFAULT 'admin',
    
    -- Session context
    session_id VARCHAR(255),
    request_id VARCHAR(255),
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- Invoice Tag Rules Table
-- =============================================================================
-- Store rules for automatic tag assignment

CREATE TABLE IF NOT EXISTS invoice_tag_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Rule identification
    rule_name VARCHAR(100) NOT NULL,
    rule_description TEXT,
    rule_type VARCHAR(30) DEFAULT 'condition' CHECK (rule_type IN (
        'condition', 'schedule', 'event', 'threshold', 'pattern', 'ml_model'
    )),
    
    -- Rule configuration
    conditions JSONB NOT NULL, -- Conditions that trigger the rule
    actions JSONB NOT NULL, -- Actions to take when rule is triggered
    
    -- Tag assignment
    tags_to_assign TEXT[], -- Tags to assign when rule matches
    tags_to_remove TEXT[], -- Tags to remove when rule matches
    
    -- Rule properties
    is_active BOOLEAN DEFAULT TRUE,
    priority INTEGER DEFAULT 100, -- Higher priority rules run first
    
    -- Execution settings
    execution_mode VARCHAR(20) DEFAULT 'immediate' CHECK (execution_mode IN (
        'immediate', 'batch', 'scheduled', 'manual'
    )),
    schedule_expression VARCHAR(100), -- Cron expression for scheduled rules
    
    -- Performance tracking
    execution_count INTEGER DEFAULT 0,
    success_count INTEGER DEFAULT 0,
    error_count INTEGER DEFAULT 0,
    last_executed_at TIMESTAMPTZ,
    average_execution_time_ms INTEGER,
    
    -- Validation and testing
    is_test_mode BOOLEAN DEFAULT FALSE,
    test_results JSONB DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    UNIQUE(store_id, rule_name)
);

-- =============================================================================
-- Invoice Tag Suggestions Table
-- =============================================================================
-- Store AI/ML generated tag suggestions

CREATE TABLE IF NOT EXISTS invoice_tag_suggestions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Suggestion details
    suggested_tag VARCHAR(100) NOT NULL,
    suggestion_type VARCHAR(30) DEFAULT 'ai' CHECK (suggestion_type IN (
        'ai', 'ml', 'rule_based', 'pattern_matching', 'collaborative_filtering', 'content_based'
    )),
    
    -- Confidence and scoring
    confidence_score DECIMAL(3,2) NOT NULL CHECK (confidence_score >= 0 AND confidence_score <= 1),
    relevance_score DECIMAL(3,2) DEFAULT 0.5 CHECK (relevance_score >= 0 AND relevance_score <= 1),
    quality_score DECIMAL(3,2) DEFAULT 0.5 CHECK (quality_score >= 0 AND quality_score <= 1),
    
    -- Suggestion context
    suggestion_reason TEXT,
    supporting_evidence JSONB DEFAULT '{}',
    model_version VARCHAR(50),
    
    -- User interaction
    is_accepted BOOLEAN,
    is_rejected BOOLEAN,
    user_feedback TEXT,
    feedback_score INTEGER CHECK (feedback_score >= 1 AND feedback_score <= 5),
    
    -- Status and lifecycle
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN (
        'pending', 'accepted', 'rejected', 'expired', 'superseded'
    )),
    expires_at TIMESTAMPTZ DEFAULT (CURRENT_TIMESTAMP + INTERVAL '30 days'),
    
    -- Performance tracking
    view_count INTEGER DEFAULT 0,
    click_count INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    UNIQUE(invoice_id, suggested_tag)
);

-- =============================================================================
-- Indexes
-- =============================================================================

-- Primary indexes for invoice_metadata
CREATE INDEX IF NOT EXISTS idx_invoice_metadata_invoice_id ON invoice_metadata(invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoice_metadata_store_id ON invoice_metadata(store_id);
CREATE INDEX IF NOT EXISTS idx_invoice_metadata_key ON invoice_metadata(metadata_key);
CREATE INDEX IF NOT EXISTS idx_invoice_metadata_type ON invoice_metadata(metadata_type);
CREATE INDEX IF NOT EXISTS idx_invoice_metadata_category ON invoice_metadata(metadata_category);
CREATE INDEX IF NOT EXISTS idx_invoice_metadata_is_visible ON invoice_metadata(is_visible);
CREATE INDEX IF NOT EXISTS idx_invoice_metadata_is_public ON invoice_metadata(is_public);
CREATE INDEX IF NOT EXISTS idx_invoice_metadata_visibility_level ON invoice_metadata(visibility_level);
CREATE INDEX IF NOT EXISTS idx_invoice_metadata_data_source ON invoice_metadata(data_source);
CREATE INDEX IF NOT EXISTS idx_invoice_metadata_is_indexed ON invoice_metadata(is_indexed);
CREATE INDEX IF NOT EXISTS idx_invoice_metadata_expires_at ON invoice_metadata(expires_at) WHERE expires_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_invoice_metadata_sync_status ON invoice_metadata(sync_status);
CREATE INDEX IF NOT EXISTS idx_invoice_metadata_created_at ON invoice_metadata(created_at DESC);

-- Composite indexes for metadata
CREATE INDEX IF NOT EXISTS idx_invoice_metadata_invoice_key ON invoice_metadata(invoice_id, metadata_key);
CREATE INDEX IF NOT EXISTS idx_invoice_metadata_store_category ON invoice_metadata(store_id, metadata_category);
CREATE INDEX IF NOT EXISTS idx_invoice_metadata_type_visible ON invoice_metadata(metadata_type, is_visible);
CREATE INDEX IF NOT EXISTS idx_invoice_metadata_public_lang ON invoice_metadata(is_public, language_code);

-- JSONB indexes for metadata
CREATE INDEX IF NOT EXISTS idx_invoice_metadata_json_value ON invoice_metadata USING gin(json_value);
CREATE INDEX IF NOT EXISTS idx_invoice_metadata_localized_values ON invoice_metadata USING gin(localized_values);
CREATE INDEX IF NOT EXISTS idx_invoice_metadata_validation_rules ON invoice_metadata USING gin(validation_rules);
CREATE INDEX IF NOT EXISTS idx_invoice_metadata_integration_mapping ON invoice_metadata USING gin(integration_mapping);
CREATE INDEX IF NOT EXISTS idx_invoice_metadata_custom_fields ON invoice_metadata USING gin(custom_fields);
CREATE INDEX IF NOT EXISTS idx_invoice_metadata_sync_errors ON invoice_metadata USING gin(sync_errors);

-- Array indexes for metadata
CREATE INDEX IF NOT EXISTS idx_invoice_metadata_array_value ON invoice_metadata USING gin(array_value);
CREATE INDEX IF NOT EXISTS idx_invoice_metadata_validation_errors ON invoice_metadata USING gin(validation_errors);

-- Text search indexes for metadata
CREATE INDEX IF NOT EXISTS idx_invoice_metadata_text_search ON invoice_metadata USING gin(to_tsvector('english', COALESCE(text_value, '')));
CREATE INDEX IF NOT EXISTS idx_invoice_metadata_display_name_search ON invoice_metadata USING gin(to_tsvector('english', COALESCE(display_name, '')));

-- Primary indexes for invoice_tags
CREATE INDEX IF NOT EXISTS idx_invoice_tags_invoice_id ON invoice_tags(invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoice_tags_store_id ON invoice_tags(store_id);
CREATE INDEX IF NOT EXISTS idx_invoice_tags_tag_name ON invoice_tags(tag_name);
CREATE INDEX IF NOT EXISTS idx_invoice_tags_tag_slug ON invoice_tags(tag_slug);
CREATE INDEX IF NOT EXISTS idx_invoice_tags_tag_type ON invoice_tags(tag_type);
CREATE INDEX IF NOT EXISTS idx_invoice_tags_is_active ON invoice_tags(is_active);
CREATE INDEX IF NOT EXISTS idx_invoice_tags_is_visible ON invoice_tags(is_visible);
CREATE INDEX IF NOT EXISTS idx_invoice_tags_is_public ON invoice_tags(is_public);
CREATE INDEX IF NOT EXISTS idx_invoice_tags_assignment_source ON invoice_tags(assignment_source);
CREATE INDEX IF NOT EXISTS idx_invoice_tags_expires_at ON invoice_tags(expires_at) WHERE expires_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_invoice_tags_relevance_score ON invoice_tags(relevance_score DESC);
CREATE INDEX IF NOT EXISTS idx_invoice_tags_sync_status ON invoice_tags(sync_status);
CREATE INDEX IF NOT EXISTS idx_invoice_tags_created_at ON invoice_tags(created_at DESC);

-- Composite indexes for tags
CREATE INDEX IF NOT EXISTS idx_invoice_tags_invoice_name ON invoice_tags(invoice_id, tag_name);
CREATE INDEX IF NOT EXISTS idx_invoice_tags_store_type ON invoice_tags(store_id, tag_type);
CREATE INDEX IF NOT EXISTS idx_invoice_tags_active_visible ON invoice_tags(is_active, is_visible);
CREATE INDEX IF NOT EXISTS idx_invoice_tags_type_score ON invoice_tags(tag_type, relevance_score DESC);

-- JSONB indexes for tags
CREATE INDEX IF NOT EXISTS idx_invoice_tags_context_data ON invoice_tags USING gin(context_data);
CREATE INDEX IF NOT EXISTS idx_invoice_tags_conditional_rules ON invoice_tags USING gin(conditional_rules);
CREATE INDEX IF NOT EXISTS idx_invoice_tags_localized_names ON invoice_tags USING gin(localized_names);
CREATE INDEX IF NOT EXISTS idx_invoice_tags_integration_mapping ON invoice_tags USING gin(integration_mapping);
CREATE INDEX IF NOT EXISTS idx_invoice_tags_custom_fields ON invoice_tags USING gin(custom_fields);
CREATE INDEX IF NOT EXISTS idx_invoice_tags_sync_errors ON invoice_tags USING gin(sync_errors);

-- Text search indexes for tags
CREATE INDEX IF NOT EXISTS idx_invoice_tags_name_search ON invoice_tags USING gin(to_tsvector('english', tag_name));
CREATE INDEX IF NOT EXISTS idx_invoice_tags_description_search ON invoice_tags USING gin(to_tsvector('english', COALESCE(tag_description, '')));

-- History table indexes
CREATE INDEX IF NOT EXISTS idx_invoice_metadata_history_metadata_id ON invoice_metadata_history(metadata_id);
CREATE INDEX IF NOT EXISTS idx_invoice_metadata_history_invoice_id ON invoice_metadata_history(invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoice_metadata_history_change_type ON invoice_metadata_history(change_type);
CREATE INDEX IF NOT EXISTS idx_invoice_metadata_history_created_at ON invoice_metadata_history(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_invoice_tag_history_tag_id ON invoice_tag_history(tag_id);
CREATE INDEX IF NOT EXISTS idx_invoice_tag_history_invoice_id ON invoice_tag_history(invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoice_tag_history_change_type ON invoice_tag_history(change_type);
CREATE INDEX IF NOT EXISTS idx_invoice_tag_history_created_at ON invoice_tag_history(created_at DESC);

-- Template and rule indexes
CREATE INDEX IF NOT EXISTS idx_invoice_metadata_templates_store_id ON invoice_metadata_templates(store_id);
CREATE INDEX IF NOT EXISTS idx_invoice_metadata_templates_category ON invoice_metadata_templates(template_category);
CREATE INDEX IF NOT EXISTS idx_invoice_metadata_templates_is_active ON invoice_metadata_templates(is_active);

CREATE INDEX IF NOT EXISTS idx_invoice_tag_rules_store_id ON invoice_tag_rules(store_id);
CREATE INDEX IF NOT EXISTS idx_invoice_tag_rules_type ON invoice_tag_rules(rule_type);
CREATE INDEX IF NOT EXISTS idx_invoice_tag_rules_is_active ON invoice_tag_rules(is_active);
CREATE INDEX IF NOT EXISTS idx_invoice_tag_rules_priority ON invoice_tag_rules(priority DESC);

-- Suggestion indexes
CREATE INDEX IF NOT EXISTS idx_invoice_tag_suggestions_invoice_id ON invoice_tag_suggestions(invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoice_tag_suggestions_store_id ON invoice_tag_suggestions(store_id);
CREATE INDEX IF NOT EXISTS idx_invoice_tag_suggestions_status ON invoice_tag_suggestions(status);
CREATE INDEX IF NOT EXISTS idx_invoice_tag_suggestions_confidence ON invoice_tag_suggestions(confidence_score DESC);
CREATE INDEX IF NOT EXISTS idx_invoice_tag_suggestions_expires_at ON invoice_tag_suggestions(expires_at);

-- =============================================================================
-- Triggers
-- =============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_invoice_metadata_tags_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_invoice_metadata_updated_at
    BEFORE UPDATE ON invoice_metadata
    FOR EACH ROW
    EXECUTE FUNCTION update_invoice_metadata_tags_updated_at();

CREATE TRIGGER trigger_update_invoice_tags_updated_at
    BEFORE UPDATE ON invoice_tags
    FOR EACH ROW
    EXECUTE FUNCTION update_invoice_metadata_tags_updated_at();

CREATE TRIGGER trigger_update_invoice_metadata_templates_updated_at
    BEFORE UPDATE ON invoice_metadata_templates
    FOR EACH ROW
    EXECUTE FUNCTION update_invoice_metadata_tags_updated_at();

CREATE TRIGGER trigger_update_invoice_tag_rules_updated_at
    BEFORE UPDATE ON invoice_tag_rules
    FOR EACH ROW
    EXECUTE FUNCTION update_invoice_metadata_tags_updated_at();

CREATE TRIGGER trigger_update_invoice_tag_suggestions_updated_at
    BEFORE UPDATE ON invoice_tag_suggestions
    FOR EACH ROW
    EXECUTE FUNCTION update_invoice_metadata_tags_updated_at();

-- Track metadata changes in history
CREATE OR REPLACE FUNCTION track_invoice_metadata_changes()
RETURNS TRIGGER AS $$
DECLARE
    v_changed_fields TEXT[];
    v_old_values JSONB;
    v_new_values JSONB;
    v_change_type VARCHAR(20);
BEGIN
    IF TG_OP = 'INSERT' THEN
        v_change_type := 'created';
        INSERT INTO invoice_metadata_history (
            metadata_id, invoice_id, store_id, change_type,
            new_values, created_at
        ) VALUES (
            NEW.id, NEW.invoice_id, NEW.store_id, v_change_type,
            to_jsonb(NEW), CURRENT_TIMESTAMP
        );
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        -- Determine specific change type
        IF OLD.text_value IS DISTINCT FROM NEW.text_value OR
           OLD.number_value IS DISTINCT FROM NEW.number_value OR
           OLD.boolean_value IS DISTINCT FROM NEW.boolean_value OR
           OLD.json_value IS DISTINCT FROM NEW.json_value THEN
            v_change_type := 'value_changed';
        ELSIF OLD.is_visible != NEW.is_visible OR OLD.visibility_level != NEW.visibility_level THEN
            v_change_type := 'visibility_changed';
        ELSIF OLD.validation_status != NEW.validation_status THEN
            v_change_type := 'validation_updated';
        ELSE
            v_change_type := 'updated';
        END IF;
        
        -- Detect changed fields
        SELECT array_agg(key), 
               jsonb_object_agg(key, old_value),
               jsonb_object_agg(key, new_value)
        INTO v_changed_fields, v_old_values, v_new_values
        FROM (
            SELECT key, 
                   old_record.value as old_value,
                   new_record.value as new_value
            FROM jsonb_each(to_jsonb(OLD)) old_record
            JOIN jsonb_each(to_jsonb(NEW)) new_record ON old_record.key = new_record.key
            WHERE old_record.value IS DISTINCT FROM new_record.value
            AND old_record.key NOT IN ('updated_at', 'last_sync_at')
        ) changes;
        
        IF array_length(v_changed_fields, 1) > 0 THEN
            INSERT INTO invoice_metadata_history (
                metadata_id, invoice_id, store_id, change_type,
                changed_fields, old_values, new_values, created_at
            ) VALUES (
                NEW.id, NEW.invoice_id, NEW.store_id, v_change_type,
                v_changed_fields, v_old_values, v_new_values, CURRENT_TIMESTAMP
            );
        END IF;
        
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO invoice_metadata_history (
            metadata_id, invoice_id, store_id, change_type,
            old_values, created_at
        ) VALUES (
            OLD.id, OLD.invoice_id, OLD.store_id, 'deleted',
            to_jsonb(OLD), CURRENT_TIMESTAMP
        );
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_track_invoice_metadata_changes
    AFTER INSERT OR UPDATE OR DELETE ON invoice_metadata
    FOR EACH ROW
    EXECUTE FUNCTION track_invoice_metadata_changes();

-- Track tag changes in history
CREATE OR REPLACE FUNCTION track_invoice_tag_changes()
RETURNS TRIGGER AS $$
DECLARE
    v_changed_fields TEXT[];
    v_old_values JSONB;
    v_new_values JSONB;
    v_change_type VARCHAR(20);
BEGIN
    IF TG_OP = 'INSERT' THEN
        v_change_type := 'assigned';
        INSERT INTO invoice_tag_history (
            tag_id, invoice_id, store_id, change_type,
            new_values, created_at
        ) VALUES (
            NEW.id, NEW.invoice_id, NEW.store_id, v_change_type,
            to_jsonb(NEW), CURRENT_TIMESTAMP
        );
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        -- Determine specific change type
        IF OLD.is_active != NEW.is_active THEN
            v_change_type := CASE WHEN NEW.is_active THEN 'activated' ELSE 'deactivated' END;
        ELSIF OLD.click_count != NEW.click_count THEN
            v_change_type := 'clicked';
        ELSIF OLD.view_count != NEW.view_count THEN
            v_change_type := 'viewed';
        ELSE
            v_change_type := 'updated';
        END IF;
        
        -- Detect changed fields
        SELECT array_agg(key), 
               jsonb_object_agg(key, old_value),
               jsonb_object_agg(key, new_value)
        INTO v_changed_fields, v_old_values, v_new_values
        FROM (
            SELECT key, 
                   old_record.value as old_value,
                   new_record.value as new_value
            FROM jsonb_each(to_jsonb(OLD)) old_record
            JOIN jsonb_each(to_jsonb(NEW)) new_record ON old_record.key = new_record.key
            WHERE old_record.value IS DISTINCT FROM new_record.value
            AND old_record.key NOT IN ('updated_at', 'last_sync_at', 'last_clicked_at', 'last_viewed_at')
        ) changes;
        
        IF array_length(v_changed_fields, 1) > 0 THEN
            INSERT INTO invoice_tag_history (
                tag_id, invoice_id, store_id, change_type,
                changed_fields, old_values, new_values, created_at
            ) VALUES (
                NEW.id, NEW.invoice_id, NEW.store_id, v_change_type,
                v_changed_fields, v_old_values, v_new_values, CURRENT_TIMESTAMP
            );
        END IF;
        
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO invoice_tag_history (
            tag_id, invoice_id, store_id, change_type,
            old_values, created_at
        ) VALUES (
            OLD.id, OLD.invoice_id, OLD.store_id, 'removed',
            to_jsonb(OLD), CURRENT_TIMESTAMP
        );
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_track_invoice_tag_changes
    AFTER INSERT OR UPDATE OR DELETE ON invoice_tags
    FOR EACH ROW
    EXECUTE FUNCTION track_invoice_tag_changes();

-- Auto-expire metadata and tags
CREATE OR REPLACE FUNCTION auto_expire_metadata_and_tags()
RETURNS TRIGGER AS $$
BEGIN
    -- Check for expired metadata
    UPDATE invoice_metadata
    SET is_visible = FALSE,
        updated_at = CURRENT_TIMESTAMP
    WHERE expires_at <= CURRENT_TIMESTAMP
    AND is_visible = TRUE;
    
    -- Auto-delete expired metadata if configured
    DELETE FROM invoice_metadata
    WHERE expires_at <= CURRENT_TIMESTAMP
    AND auto_delete_on_expiry = TRUE;
    
    -- Check for expired tags
    UPDATE invoice_tags
    SET is_active = FALSE,
        updated_at = CURRENT_TIMESTAMP
    WHERE expires_at <= CURRENT_TIMESTAMP
    AND is_active = TRUE;
    
    -- Auto-remove expired tags if configured
    DELETE FROM invoice_tags
    WHERE expires_at <= CURRENT_TIMESTAMP
    AND auto_remove_on_expiry = TRUE;
    
    -- Expire old tag suggestions
    UPDATE invoice_tag_suggestions
    SET status = 'expired',
        updated_at = CURRENT_TIMESTAMP
    WHERE expires_at <= CURRENT_TIMESTAMP
    AND status = 'pending';
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create a scheduled job to run expiration cleanup (this would typically be done via pg_cron or external scheduler)
-- For now, we'll create the function and it can be called manually or via cron

-- Update tag popularity scores
CREATE OR REPLACE FUNCTION update_tag_popularity_scores()
RETURNS TRIGGER AS $$
BEGIN
    -- Update relevance score based on usage
    IF TG_OP = 'UPDATE' AND (OLD.click_count != NEW.click_count OR OLD.view_count != NEW.view_count) THEN
        NEW.relevance_score := LEAST(1.0, 
            0.3 + (NEW.click_count * 0.1) + (NEW.view_count * 0.01)
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_tag_popularity_scores
    BEFORE UPDATE ON invoice_tags
    FOR EACH ROW
    EXECUTE FUNCTION update_tag_popularity_scores();

-- =============================================================================
-- Helper Functions
-- =============================================================================

/**
 * Get invoice metadata with complete details
 * @param p_invoice_id UUID - Invoice ID
 * @param p_visibility_level VARCHAR - Visibility level filter
 * @return JSONB - Complete metadata
 */
CREATE OR REPLACE FUNCTION get_invoice_metadata(
    p_invoice_id UUID,
    p_visibility_level VARCHAR(20) DEFAULT 'admin'
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'metadata', jsonb_agg(
            jsonb_build_object(
                'id', im.id,
                'key', im.metadata_key,
                'type', im.metadata_type,
                'category', im.metadata_category,
                'value', CASE 
                    WHEN im.metadata_type = 'text' THEN to_jsonb(im.text_value)
                    WHEN im.metadata_type = 'number' THEN to_jsonb(im.number_value)
                    WHEN im.metadata_type = 'boolean' THEN to_jsonb(im.boolean_value)
                    WHEN im.metadata_type = 'date' THEN to_jsonb(im.date_value)
                    WHEN im.metadata_type = 'datetime' THEN to_jsonb(im.datetime_value)
                    WHEN im.metadata_type IN ('json', 'object') THEN im.json_value
                    WHEN im.metadata_type = 'array' THEN to_jsonb(im.array_value)
                    ELSE to_jsonb(im.text_value)
                END,
                'display_name', im.display_name,
                'display_order', im.display_order,
                'is_public', im.is_public,
                'language_code', im.language_code
            )
            ORDER BY im.display_order, im.metadata_key
        ) FILTER (WHERE im.is_visible = TRUE),
        'metadata_summary', jsonb_build_object(
            'total_count', COUNT(*),
            'visible_count', COUNT(*) FILTER (WHERE im.is_visible = TRUE),
            'public_count', COUNT(*) FILTER (WHERE im.is_public = TRUE),
            'categories', jsonb_agg(DISTINCT im.metadata_category) FILTER (WHERE im.metadata_category IS NOT NULL)
        )
    ) INTO result
    FROM invoice_metadata im
    WHERE im.invoice_id = p_invoice_id
    AND (p_visibility_level = 'admin' OR 
         (p_visibility_level = 'public' AND im.is_public = TRUE) OR
         im.visibility_level = p_visibility_level);
    
    RETURN COALESCE(result, '{"metadata": [], "metadata_summary": {"total_count": 0}}'::jsonb);
END;
$$ LANGUAGE plpgsql;

/**
 * Get invoice tags with complete details
 * @param p_invoice_id UUID - Invoice ID
 * @param p_include_inactive BOOLEAN - Include inactive tags
 * @return JSONB - Complete tags data
 */
CREATE OR REPLACE FUNCTION get_invoice_tags(
    p_invoice_id UUID,
    p_include_inactive BOOLEAN DEFAULT FALSE
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'tags', jsonb_agg(
            jsonb_build_object(
                'id', it.id,
                'name', it.tag_name,
                'slug', it.tag_slug,
                'type', it.tag_type,
                'color', it.tag_color,
                'icon', it.tag_icon,
                'description', it.tag_description,
                'is_active', it.is_active,
                'is_public', it.is_public,
                'relevance_score', it.relevance_score,
                'assignment_source', it.assignment_source,
                'created_at', it.created_at
            )
            ORDER BY it.display_order, it.relevance_score DESC, it.tag_name
        ) FILTER (WHERE it.is_visible = TRUE AND (p_include_inactive OR it.is_active = TRUE)),
        'tags_summary', jsonb_build_object(
            'total_count', COUNT(*),
            'active_count', COUNT(*) FILTER (WHERE it.is_active = TRUE),
            'public_count', COUNT(*) FILTER (WHERE it.is_public = TRUE),
            'types', jsonb_agg(DISTINCT it.tag_type) FILTER (WHERE it.tag_type IS NOT NULL),
            'average_relevance', AVG(it.relevance_score) FILTER (WHERE it.is_active = TRUE)
        )
    ) INTO result
    FROM invoice_tags it
    WHERE it.invoice_id = p_invoice_id
    AND it.is_visible = TRUE;
    
    RETURN COALESCE(result, '{"tags": [], "tags_summary": {"total_count": 0}}'::jsonb);
END;
$$ LANGUAGE plpgsql;

/**
 * Set invoice metadata value
 * @param p_invoice_id UUID - Invoice ID
 * @param p_metadata_key VARCHAR - Metadata key
 * @param p_value TEXT - Value to set
 * @param p_metadata_type VARCHAR - Type of metadata
 * @return JSONB - Operation result
 */
CREATE OR REPLACE FUNCTION set_invoice_metadata(
    p_invoice_id UUID,
    p_metadata_key VARCHAR(100),
    p_value TEXT,
    p_metadata_type VARCHAR(30) DEFAULT 'text'
)
RETURNS JSONB AS $$
DECLARE
    v_store_id UUID;
    v_metadata_id UUID;
    result JSONB;
BEGIN
    -- Get store ID from invoice
    SELECT store_id INTO v_store_id
    FROM invoices
    WHERE id = p_invoice_id;
    
    IF v_store_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Invoice not found');
    END IF;
    
    -- Insert or update metadata
    INSERT INTO invoice_metadata (
        invoice_id, store_id, metadata_key, metadata_type,
        text_value, number_value, boolean_value, date_value, datetime_value, json_value
    ) VALUES (
        p_invoice_id, v_store_id, p_metadata_key, p_metadata_type,
        CASE WHEN p_metadata_type = 'text' THEN p_value ELSE NULL END,
        CASE WHEN p_metadata_type = 'number' THEN p_value::DECIMAL ELSE NULL END,
        CASE WHEN p_metadata_type = 'boolean' THEN p_value::BOOLEAN ELSE NULL END,
        CASE WHEN p_metadata_type = 'date' THEN p_value::DATE ELSE NULL END,
        CASE WHEN p_metadata_type = 'datetime' THEN p_value::TIMESTAMPTZ ELSE NULL END,
        CASE WHEN p_metadata_type IN ('json', 'object') THEN p_value::JSONB ELSE NULL END
    )
    ON CONFLICT (invoice_id, metadata_key, language_code)
    DO UPDATE SET
        text_value = CASE WHEN p_metadata_type = 'text' THEN p_value ELSE NULL END,
        number_value = CASE WHEN p_metadata_type = 'number' THEN p_value::DECIMAL ELSE NULL END,
        boolean_value = CASE WHEN p_metadata_type = 'boolean' THEN p_value::BOOLEAN ELSE NULL END,
        date_value = CASE WHEN p_metadata_type = 'date' THEN p_value::DATE ELSE NULL END,
        datetime_value = CASE WHEN p_metadata_type = 'datetime' THEN p_value::TIMESTAMPTZ ELSE NULL END,
        json_value = CASE WHEN p_metadata_type IN ('json', 'object') THEN p_value::JSONB ELSE NULL END,
        updated_at = CURRENT_TIMESTAMP
    RETURNING id INTO v_metadata_id;
    
    RETURN jsonb_build_object(
        'success', true,
        'metadata_id', v_metadata_id,
        'key', p_metadata_key,
        'value', p_value,
        'type', p_metadata_type
    );
END;
$$ LANGUAGE plpgsql;

/**
 * Search metadata across invoices
 * @param p_store_id UUID - Store ID
 * @param p_search_term TEXT - Search term
 * @param p_metadata_type VARCHAR - Filter by type
 * @param p_limit INTEGER - Result limit
 * @return JSONB - Search results
 */
CREATE OR REPLACE FUNCTION search_invoice_metadata(
    p_store_id UUID,
    p_search_term TEXT,
    p_metadata_type VARCHAR(30) DEFAULT NULL,
    p_limit INTEGER DEFAULT 50
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'results', jsonb_agg(
            jsonb_build_object(
                'invoice_id', im.invoice_id,
                'metadata_key', im.metadata_key,
                'metadata_type', im.metadata_type,
                'value', CASE 
                    WHEN im.metadata_type = 'text' THEN to_jsonb(im.text_value)
                    WHEN im.metadata_type = 'number' THEN to_jsonb(im.number_value)
                    WHEN im.metadata_type = 'boolean' THEN to_jsonb(im.boolean_value)
                    ELSE to_jsonb(im.text_value)
                END,
                'display_name', im.display_name,
                'created_at', im.created_at
            )
            ORDER BY im.created_at DESC
        ),
        'total_count', COUNT(*)
    ) INTO result
    FROM invoice_metadata im
    WHERE im.store_id = p_store_id
    AND im.is_visible = TRUE
    AND (p_metadata_type IS NULL OR im.metadata_type = p_metadata_type)
    AND (
        im.metadata_key ILIKE '%' || p_search_term || '%' OR
        im.text_value ILIKE '%' || p_search_term || '%' OR
        im.display_name ILIKE '%' || p_search_term || '%'
    )
    LIMIT p_limit;
    
    RETURN COALESCE(result, '{"results": [], "total_count": 0}'::jsonb);
END;
$$ LANGUAGE plpgsql;

/**
 * Apply metadata template to invoice
 * @param p_invoice_id UUID - Invoice ID
 * @param p_template_name VARCHAR - Template name
 * @return JSONB - Application result
 */
CREATE OR REPLACE FUNCTION apply_metadata_template(
    p_invoice_id UUID,
    p_template_name VARCHAR(100)
)
RETURNS JSONB AS $$
DECLARE
    v_store_id UUID;
    v_template RECORD;
    v_metadata_key TEXT;
    v_metadata_config JSONB;
    v_applied_count INTEGER := 0;
    result JSONB;
BEGIN
    -- Get store ID from invoice
    SELECT store_id INTO v_store_id
    FROM invoices
    WHERE id = p_invoice_id;
    
    IF v_store_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Invoice not found');
    END IF;
    
    -- Get template
    SELECT * INTO v_template
    FROM invoice_metadata_templates
    WHERE store_id = v_store_id
    AND template_name = p_template_name
    AND is_active = TRUE;
    
    IF v_template.id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Template not found');
    END IF;
    
    -- Apply template metadata
    FOR v_metadata_key, v_metadata_config IN
        SELECT key, value
        FROM jsonb_each(v_template.metadata_schema)
    LOOP
        INSERT INTO invoice_metadata (
            invoice_id, store_id, metadata_key, metadata_type,
            text_value, display_name, metadata_category,
            is_required, validation_rules, data_source
        ) VALUES (
            p_invoice_id, v_store_id, v_metadata_key,
            COALESCE(v_metadata_config->>'type', 'text'),
            COALESCE(v_template.default_values->>v_metadata_key, v_metadata_config->>'default'),
            COALESCE(v_metadata_config->>'display_name', v_metadata_key),
            COALESCE(v_metadata_config->>'category', 'general'),
            COALESCE((v_metadata_config->>'required')::BOOLEAN, FALSE),
            COALESCE(v_metadata_config->'validation', '{}'),
            'template_application'
        )
        ON CONFLICT (invoice_id, metadata_key, language_code) DO NOTHING;
        
        v_applied_count := v_applied_count + 1;
    END LOOP;
    
    -- Update template usage count
    UPDATE invoice_metadata_templates
    SET usage_count = usage_count + 1,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = v_template.id;
    
    RETURN jsonb_build_object(
        'success', true,
        'template_applied', p_template_name,
        'metadata_fields_applied', v_applied_count
    );
END;
$$ LANGUAGE plpgsql;

/**
 * Get metadata and tags statistics for store
 * @param p_store_id UUID - Store ID
 * @return JSONB - Statistics
 */
CREATE OR REPLACE FUNCTION get_metadata_tags_statistics(
    p_store_id UUID
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'metadata_stats', jsonb_build_object(
            'total_metadata_entries', COUNT(DISTINCT im.id),
            'unique_metadata_keys', COUNT(DISTINCT im.metadata_key),
            'metadata_by_type', (
                SELECT jsonb_object_agg(metadata_type, type_count)
                FROM (
                    SELECT metadata_type, COUNT(*) as type_count
                    FROM invoice_metadata
                    WHERE store_id = p_store_id
                    GROUP BY metadata_type
                ) type_stats
            ),
            'metadata_by_category', (
                SELECT jsonb_object_agg(metadata_category, category_count)
                FROM (
                    SELECT metadata_category, COUNT(*) as category_count
                    FROM invoice_metadata
                    WHERE store_id = p_store_id
                    GROUP BY metadata_category
                ) category_stats
            )
        ),
        'tags_stats', jsonb_build_object(
            'total_tag_assignments', COUNT(DISTINCT it.id),
            'unique_tags', COUNT(DISTINCT it.tag_name),
            'active_tags', COUNT(DISTINCT it.id) FILTER (WHERE it.is_active = TRUE),
            'tags_by_type', (
                SELECT jsonb_object_agg(tag_type, type_count)
                FROM (
                    SELECT tag_type, COUNT(*) as type_count
                    FROM invoice_tags
                    WHERE store_id = p_store_id
                    GROUP BY tag_type
                ) type_stats
            ),
            'average_relevance_score', AVG(it.relevance_score) FILTER (WHERE it.is_active = TRUE)
        ),
        'templates_stats', jsonb_build_object(
            'total_templates', COUNT(DISTINCT imt.id),
            'active_templates', COUNT(DISTINCT imt.id) FILTER (WHERE imt.is_active = TRUE),
            'total_template_usage', SUM(imt.usage_count)
        ),
        'rules_stats', jsonb_build_object(
            'total_rules', COUNT(DISTINCT itr.id),
            'active_rules', COUNT(DISTINCT itr.id) FILTER (WHERE itr.is_active = TRUE),
            'total_rule_executions', SUM(itr.execution_count)
        )
    ) INTO result
    FROM invoice_metadata im
    FULL OUTER JOIN invoice_tags it ON it.store_id = im.store_id
    FULL OUTER JOIN invoice_metadata_templates imt ON imt.store_id = COALESCE(im.store_id, it.store_id)
    FULL OUTER JOIN invoice_tag_rules itr ON itr.store_id = COALESCE(im.store_id, it.store_id, imt.store_id)
    WHERE COALESCE(im.store_id, it.store_id, imt.store_id, itr.store_id) = p_store_id;
    
    RETURN COALESCE(result, '{"error": "No data found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Comments
-- =============================================================================

COMMENT ON TABLE invoice_metadata IS 'Normalized metadata for invoices with comprehensive data management and validation';
COMMENT ON TABLE invoice_metadata_history IS 'Track changes to invoice metadata';
COMMENT ON TABLE invoice_metadata_templates IS 'Reusable metadata templates for invoices';
COMMENT ON TABLE invoice_tags IS 'Normalized tags for invoices with advanced features and analytics';
COMMENT ON TABLE invoice_tag_history IS 'Track changes to invoice tag assignments';
COMMENT ON TABLE invoice_tag_rules IS 'Rules for automatic tag assignment';
COMMENT ON TABLE invoice_tag_suggestions IS 'AI/ML generated tag suggestions';

COMMENT ON COLUMN invoice_metadata.metadata_key IS 'Unique identifier for the metadata field';
COMMENT ON COLUMN invoice_metadata.json_value IS 'JSON value for complex metadata';
COMMENT ON COLUMN invoice_metadata.validation_rules IS 'JSON schema for validating metadata values';
COMMENT ON COLUMN invoice_tags.tag_slug IS 'URL-friendly version of tag name';
COMMENT ON COLUMN invoice_tags.relevance_score IS 'Score indicating tag relevance (0.0 to 1.0)';
COMMENT ON COLUMN invoice_tags.context_data IS 'Additional context information for the tag';

COMMENT ON FUNCTION get_invoice_metadata(UUID, VARCHAR) IS 'Get complete metadata with visibility filtering for invoice';
COMMENT ON FUNCTION get_invoice_tags(UUID, BOOLEAN) IS 'Get complete tags data for invoice';
COMMENT ON FUNCTION set_invoice_metadata(UUID, VARCHAR, TEXT, VARCHAR) IS 'Set metadata value for invoice';
COMMENT ON FUNCTION search_invoice_metadata(UUID, TEXT, VARCHAR, INTEGER) IS 'Search metadata across invoices';
COMMENT ON FUNCTION apply_metadata_template(UUID, VARCHAR) IS 'Apply metadata template to invoice';
COMMENT ON FUNCTION get_metadata_tags_statistics(UUID) IS 'Get comprehensive statistics for metadata and tags';