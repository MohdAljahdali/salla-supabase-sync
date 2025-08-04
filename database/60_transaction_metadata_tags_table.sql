-- =============================================================================
-- Transaction Metadata Table
-- =============================================================================
-- This table normalizes the metadata JSONB column from transactions

CREATE TABLE IF NOT EXISTS transaction_metadata (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id UUID NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Metadata identification
    metadata_key VARCHAR(255) NOT NULL,
    metadata_value TEXT,
    metadata_type VARCHAR(50) DEFAULT 'string' CHECK (metadata_type IN (
        'string', 'number', 'boolean', 'date', 'datetime', 'json', 'array', 'url', 'email'
    )),
    
    -- Metadata properties
    is_sensitive BOOLEAN DEFAULT FALSE,
    is_encrypted BOOLEAN DEFAULT FALSE,
    is_public BOOLEAN DEFAULT FALSE,
    is_searchable BOOLEAN DEFAULT TRUE,
    is_required BOOLEAN DEFAULT FALSE,
    
    -- Validation
    validation_rules JSONB DEFAULT '{}', -- JSON schema or validation rules
    is_valid BOOLEAN DEFAULT TRUE,
    validation_errors JSONB DEFAULT '[]',
    last_validated_at TIMESTAMPTZ,
    
    -- Localization
    locale VARCHAR(10) DEFAULT 'en',
    localized_values JSONB DEFAULT '{}', -- {"ar": "value", "en": "value"}
    
    -- Display properties
    display_name VARCHAR(255),
    display_order INTEGER DEFAULT 0,
    display_group VARCHAR(100),
    is_visible BOOLEAN DEFAULT TRUE,
    
    -- Data source
    source_system VARCHAR(100), -- salla, external_api, manual, import
    source_reference VARCHAR(255),
    source_timestamp TIMESTAMPTZ,
    
    -- Versioning
    version INTEGER DEFAULT 1,
    previous_value TEXT,
    change_reason VARCHAR(255),
    
    -- Performance tracking
    access_count INTEGER DEFAULT 0,
    last_accessed_at TIMESTAMPTZ,
    popularity_score DECIMAL(5,2) DEFAULT 0.00,
    
    -- SEO and marketing
    seo_weight INTEGER DEFAULT 0 CHECK (seo_weight >= 0 AND seo_weight <= 10),
    marketing_tags TEXT[],
    
    -- Privacy and compliance
    privacy_level VARCHAR(20) DEFAULT 'public' CHECK (privacy_level IN (
        'public', 'internal', 'confidential', 'restricted'
    )),
    retention_days INTEGER, -- Auto-delete after X days
    
    -- Auto-expiration
    expires_at TIMESTAMPTZ,
    is_expired BOOLEAN GENERATED ALWAYS AS (expires_at IS NOT NULL AND expires_at < CURRENT_TIMESTAMP) STORED,
    
    -- External references
    external_metadata_id VARCHAR(255),
    external_references JSONB DEFAULT '{}',
    
    -- Sync information
    sync_status VARCHAR(20) DEFAULT 'synced' CHECK (sync_status IN ('pending', 'syncing', 'synced', 'error')),
    last_sync_at TIMESTAMPTZ,
    sync_errors JSONB DEFAULT '[]',
    
    -- Custom fields
    custom_fields JSONB DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    UNIQUE(transaction_id, metadata_key)
);

-- =============================================================================
-- Transaction Metadata History Table
-- =============================================================================
-- Track changes to transaction metadata

CREATE TABLE IF NOT EXISTS transaction_metadata_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    metadata_id UUID NOT NULL REFERENCES transaction_metadata(id) ON DELETE CASCADE,
    transaction_id UUID NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Change tracking
    change_type VARCHAR(20) NOT NULL CHECK (change_type IN ('created', 'updated', 'deleted', 'expired')),
    changed_fields JSONB DEFAULT '[]', -- Array of changed field names
    old_values JSONB DEFAULT '{}', -- Previous values
    new_values JSONB DEFAULT '{}', -- New values
    
    -- Change context
    change_reason VARCHAR(255),
    changed_by_user_id UUID,
    changed_by_system VARCHAR(100),
    change_source VARCHAR(50) DEFAULT 'manual' CHECK (change_source IN (
        'manual', 'api', 'webhook', 'sync', 'automation', 'migration'
    )),
    
    -- Additional context
    context_data JSONB DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- Transaction Metadata Templates Table
-- =============================================================================
-- Predefined metadata templates for transactions

CREATE TABLE IF NOT EXISTS transaction_metadata_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Template identification
    template_name VARCHAR(255) NOT NULL,
    template_description TEXT,
    template_category VARCHAR(100), -- payment, shipping, tax, marketing
    
    -- Template structure
    metadata_schema JSONB NOT NULL, -- JSON schema for metadata structure
    default_values JSONB DEFAULT '{}',
    required_fields TEXT[] DEFAULT '{}',
    
    -- Template properties
    is_active BOOLEAN DEFAULT TRUE,
    is_system_template BOOLEAN DEFAULT FALSE,
    usage_count INTEGER DEFAULT 0,
    
    -- Validation
    validation_rules JSONB DEFAULT '{}',
    
    -- Localization
    supported_locales TEXT[] DEFAULT '{"en"}',
    localized_labels JSONB DEFAULT '{}',
    
    -- External references
    external_template_id VARCHAR(255),
    external_references JSONB DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    UNIQUE(store_id, template_name)
);

-- =============================================================================
-- Transaction Tags Table
-- =============================================================================
-- This table normalizes the tags array column from transactions

CREATE TABLE IF NOT EXISTS transaction_tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id UUID NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Tag identification
    tag_name VARCHAR(255) NOT NULL,
    tag_slug VARCHAR(255) NOT NULL, -- URL-friendly version
    tag_category VARCHAR(100), -- payment, status, priority, source
    
    -- Tag assignment properties
    assigned_by_user_id UUID,
    assigned_by_system VARCHAR(100),
    assignment_reason VARCHAR(255),
    assignment_confidence DECIMAL(3,2) DEFAULT 1.00 CHECK (assignment_confidence >= 0 AND assignment_confidence <= 1),
    
    -- Display properties
    display_name VARCHAR(255),
    display_color VARCHAR(7), -- Hex color code
    display_icon VARCHAR(50),
    display_order INTEGER DEFAULT 0,
    
    -- Tag lifecycle
    is_active BOOLEAN DEFAULT TRUE,
    is_system_tag BOOLEAN DEFAULT FALSE,
    is_auto_assigned BOOLEAN DEFAULT FALSE,
    
    -- Performance tracking
    usage_count INTEGER DEFAULT 1,
    click_count INTEGER DEFAULT 0,
    last_used_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    popularity_score DECIMAL(5,2) DEFAULT 0.00,
    
    -- A/B testing
    ab_test_group VARCHAR(50),
    ab_test_variant VARCHAR(50),
    conversion_rate DECIMAL(5,4) DEFAULT 0.0000,
    
    -- Context and conditions
    context_data JSONB DEFAULT '{}',
    assignment_conditions JSONB DEFAULT '{}', -- Conditions for auto-assignment
    
    -- Quality metrics
    relevance_score DECIMAL(3,2) DEFAULT 1.00 CHECK (relevance_score >= 0 AND relevance_score <= 1),
    accuracy_score DECIMAL(3,2) DEFAULT 1.00 CHECK (accuracy_score >= 0 AND accuracy_score <= 1),
    
    -- External references
    external_tag_id VARCHAR(255),
    external_references JSONB DEFAULT '{}',
    
    -- Sync information
    sync_status VARCHAR(20) DEFAULT 'synced' CHECK (sync_status IN ('pending', 'syncing', 'synced', 'error')),
    last_sync_at TIMESTAMPTZ,
    sync_errors JSONB DEFAULT '[]',
    
    -- Custom fields
    custom_fields JSONB DEFAULT '{}',
    
    -- Timestamps
    assigned_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    UNIQUE(transaction_id, tag_name)
);

-- =============================================================================
-- Transaction Tag History Table
-- =============================================================================
-- Track changes to transaction tag assignments

CREATE TABLE IF NOT EXISTS transaction_tag_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tag_assignment_id UUID REFERENCES transaction_tags(id) ON DELETE CASCADE,
    transaction_id UUID NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Tag information
    tag_name VARCHAR(255) NOT NULL,
    
    -- Change tracking
    change_type VARCHAR(20) NOT NULL CHECK (change_type IN ('assigned', 'removed', 'updated', 'bulk_assigned')),
    changed_fields JSONB DEFAULT '[]',
    old_values JSONB DEFAULT '{}',
    new_values JSONB DEFAULT '{}',
    
    -- Change context
    change_reason VARCHAR(255),
    changed_by_user_id UUID,
    changed_by_system VARCHAR(100),
    change_source VARCHAR(50) DEFAULT 'manual' CHECK (change_source IN (
        'manual', 'api', 'webhook', 'sync', 'automation', 'bulk_operation'
    )),
    
    -- Bulk operation tracking
    bulk_operation_id UUID,
    bulk_operation_total INTEGER,
    
    -- Additional context
    context_data JSONB DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- Transaction Tag Rules Table
-- =============================================================================
-- Rules for automatic tag assignment

CREATE TABLE IF NOT EXISTS transaction_tag_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Rule identification
    rule_name VARCHAR(255) NOT NULL,
    rule_description TEXT,
    rule_category VARCHAR(100), -- auto_assignment, validation, cleanup
    
    -- Rule conditions
    conditions JSONB NOT NULL, -- JSON conditions for rule execution
    tag_names TEXT[] NOT NULL, -- Tags to assign when conditions are met
    
    -- Rule properties
    is_active BOOLEAN DEFAULT TRUE,
    priority INTEGER DEFAULT 0, -- Higher priority rules execute first
    execution_order INTEGER DEFAULT 0,
    
    -- Performance tracking
    execution_count INTEGER DEFAULT 0,
    success_count INTEGER DEFAULT 0,
    last_executed_at TIMESTAMPTZ,
    average_execution_time_ms INTEGER DEFAULT 0,
    
    -- Rule lifecycle
    effective_from TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    effective_until TIMESTAMPTZ,
    
    -- External references
    external_rule_id VARCHAR(255),
    external_references JSONB DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    UNIQUE(store_id, rule_name)
);

-- =============================================================================
-- Transaction Tag Suggestions Table
-- =============================================================================
-- AI/ML generated tag suggestions

CREATE TABLE IF NOT EXISTS transaction_tag_suggestions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id UUID NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Suggestion details
    suggested_tag_name VARCHAR(255) NOT NULL,
    suggestion_reason TEXT,
    confidence_score DECIMAL(3,2) NOT NULL CHECK (confidence_score >= 0 AND confidence_score <= 1),
    
    -- Suggestion source
    suggestion_source VARCHAR(100) NOT NULL, -- ml_model, rule_engine, user_behavior, similar_transactions
    model_name VARCHAR(100),
    model_version VARCHAR(20),
    
    -- Suggestion status
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN (
        'pending', 'accepted', 'rejected', 'expired', 'auto_applied'
    )),
    
    -- User interaction
    reviewed_by_user_id UUID,
    reviewed_at TIMESTAMPTZ,
    review_feedback TEXT,
    
    -- Performance tracking
    view_count INTEGER DEFAULT 0,
    click_count INTEGER DEFAULT 0,
    
    -- Auto-expiration
    expires_at TIMESTAMPTZ DEFAULT (CURRENT_TIMESTAMP + INTERVAL '30 days'),
    is_expired BOOLEAN GENERATED ALWAYS AS (expires_at < CURRENT_TIMESTAMP) STORED,
    
    -- Context data
    context_data JSONB DEFAULT '{}',
    feature_data JSONB DEFAULT '{}', -- ML features used for suggestion
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- Indexes
-- =============================================================================

-- Transaction Metadata indexes
CREATE INDEX IF NOT EXISTS idx_transaction_metadata_transaction_id ON transaction_metadata(transaction_id);
CREATE INDEX IF NOT EXISTS idx_transaction_metadata_store_id ON transaction_metadata(store_id);
CREATE INDEX IF NOT EXISTS idx_transaction_metadata_key ON transaction_metadata(metadata_key);
CREATE INDEX IF NOT EXISTS idx_transaction_metadata_type ON transaction_metadata(metadata_type);
CREATE INDEX IF NOT EXISTS idx_transaction_metadata_is_sensitive ON transaction_metadata(is_sensitive) WHERE is_sensitive = TRUE;
CREATE INDEX IF NOT EXISTS idx_transaction_metadata_is_searchable ON transaction_metadata(is_searchable) WHERE is_searchable = TRUE;
CREATE INDEX IF NOT EXISTS idx_transaction_metadata_locale ON transaction_metadata(locale);
CREATE INDEX IF NOT EXISTS idx_transaction_metadata_display_group ON transaction_metadata(display_group);
CREATE INDEX IF NOT EXISTS idx_transaction_metadata_source_system ON transaction_metadata(source_system);
CREATE INDEX IF NOT EXISTS idx_transaction_metadata_privacy_level ON transaction_metadata(privacy_level);
CREATE INDEX IF NOT EXISTS idx_transaction_metadata_expires_at ON transaction_metadata(expires_at) WHERE expires_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_transaction_metadata_is_expired ON transaction_metadata(is_expired) WHERE is_expired = TRUE;
CREATE INDEX IF NOT EXISTS idx_transaction_metadata_sync_status ON transaction_metadata(sync_status);
CREATE INDEX IF NOT EXISTS idx_transaction_metadata_created_at ON transaction_metadata(created_at DESC);

-- JSONB indexes for metadata
CREATE INDEX IF NOT EXISTS idx_transaction_metadata_validation_rules ON transaction_metadata USING gin(validation_rules);
CREATE INDEX IF NOT EXISTS idx_transaction_metadata_localized_values ON transaction_metadata USING gin(localized_values);
CREATE INDEX IF NOT EXISTS idx_transaction_metadata_external_references ON transaction_metadata USING gin(external_references);
CREATE INDEX IF NOT EXISTS idx_transaction_metadata_custom_fields ON transaction_metadata USING gin(custom_fields);
CREATE INDEX IF NOT EXISTS idx_transaction_metadata_sync_errors ON transaction_metadata USING gin(sync_errors);

-- Full-text search index for metadata values
CREATE INDEX IF NOT EXISTS idx_transaction_metadata_value_fts ON transaction_metadata USING gin(to_tsvector('english', metadata_value)) WHERE is_searchable = TRUE;

-- Metadata History indexes
CREATE INDEX IF NOT EXISTS idx_transaction_metadata_history_metadata_id ON transaction_metadata_history(metadata_id);
CREATE INDEX IF NOT EXISTS idx_transaction_metadata_history_transaction_id ON transaction_metadata_history(transaction_id);
CREATE INDEX IF NOT EXISTS idx_transaction_metadata_history_store_id ON transaction_metadata_history(store_id);
CREATE INDEX IF NOT EXISTS idx_transaction_metadata_history_change_type ON transaction_metadata_history(change_type);
CREATE INDEX IF NOT EXISTS idx_transaction_metadata_history_change_source ON transaction_metadata_history(change_source);
CREATE INDEX IF NOT EXISTS idx_transaction_metadata_history_created_at ON transaction_metadata_history(created_at DESC);

-- Metadata Templates indexes
CREATE INDEX IF NOT EXISTS idx_transaction_metadata_templates_store_id ON transaction_metadata_templates(store_id);
CREATE INDEX IF NOT EXISTS idx_transaction_metadata_templates_category ON transaction_metadata_templates(template_category);
CREATE INDEX IF NOT EXISTS idx_transaction_metadata_templates_is_active ON transaction_metadata_templates(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_transaction_metadata_templates_is_system ON transaction_metadata_templates(is_system_template) WHERE is_system_template = TRUE;

-- Transaction Tags indexes
CREATE INDEX IF NOT EXISTS idx_transaction_tags_transaction_id ON transaction_tags(transaction_id);
CREATE INDEX IF NOT EXISTS idx_transaction_tags_store_id ON transaction_tags(store_id);
CREATE INDEX IF NOT EXISTS idx_transaction_tags_tag_name ON transaction_tags(tag_name);
CREATE INDEX IF NOT EXISTS idx_transaction_tags_tag_slug ON transaction_tags(tag_slug);
CREATE INDEX IF NOT EXISTS idx_transaction_tags_tag_category ON transaction_tags(tag_category);
CREATE INDEX IF NOT EXISTS idx_transaction_tags_is_active ON transaction_tags(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_transaction_tags_is_system_tag ON transaction_tags(is_system_tag) WHERE is_system_tag = TRUE;
CREATE INDEX IF NOT EXISTS idx_transaction_tags_is_auto_assigned ON transaction_tags(is_auto_assigned) WHERE is_auto_assigned = TRUE;
CREATE INDEX IF NOT EXISTS idx_transaction_tags_assigned_by_user_id ON transaction_tags(assigned_by_user_id);
CREATE INDEX IF NOT EXISTS idx_transaction_tags_popularity_score ON transaction_tags(popularity_score DESC);
CREATE INDEX IF NOT EXISTS idx_transaction_tags_last_used_at ON transaction_tags(last_used_at DESC);
CREATE INDEX IF NOT EXISTS idx_transaction_tags_sync_status ON transaction_tags(sync_status);
CREATE INDEX IF NOT EXISTS idx_transaction_tags_assigned_at ON transaction_tags(assigned_at DESC);

-- Tag History indexes
CREATE INDEX IF NOT EXISTS idx_transaction_tag_history_tag_assignment_id ON transaction_tag_history(tag_assignment_id);
CREATE INDEX IF NOT EXISTS idx_transaction_tag_history_transaction_id ON transaction_tag_history(transaction_id);
CREATE INDEX IF NOT EXISTS idx_transaction_tag_history_store_id ON transaction_tag_history(store_id);
CREATE INDEX IF NOT EXISTS idx_transaction_tag_history_tag_name ON transaction_tag_history(tag_name);
CREATE INDEX IF NOT EXISTS idx_transaction_tag_history_change_type ON transaction_tag_history(change_type);
CREATE INDEX IF NOT EXISTS idx_transaction_tag_history_change_source ON transaction_tag_history(change_source);
CREATE INDEX IF NOT EXISTS idx_transaction_tag_history_bulk_operation_id ON transaction_tag_history(bulk_operation_id) WHERE bulk_operation_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_transaction_tag_history_created_at ON transaction_tag_history(created_at DESC);

-- Tag Rules indexes
CREATE INDEX IF NOT EXISTS idx_transaction_tag_rules_store_id ON transaction_tag_rules(store_id);
CREATE INDEX IF NOT EXISTS idx_transaction_tag_rules_category ON transaction_tag_rules(rule_category);
CREATE INDEX IF NOT EXISTS idx_transaction_tag_rules_is_active ON transaction_tag_rules(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_transaction_tag_rules_priority ON transaction_tag_rules(priority DESC);
CREATE INDEX IF NOT EXISTS idx_transaction_tag_rules_execution_order ON transaction_tag_rules(execution_order);
CREATE INDEX IF NOT EXISTS idx_transaction_tag_rules_effective_from ON transaction_tag_rules(effective_from);
CREATE INDEX IF NOT EXISTS idx_transaction_tag_rules_effective_until ON transaction_tag_rules(effective_until) WHERE effective_until IS NOT NULL;

-- Tag Suggestions indexes
CREATE INDEX IF NOT EXISTS idx_transaction_tag_suggestions_transaction_id ON transaction_tag_suggestions(transaction_id);
CREATE INDEX IF NOT EXISTS idx_transaction_tag_suggestions_store_id ON transaction_tag_suggestions(store_id);
CREATE INDEX IF NOT EXISTS idx_transaction_tag_suggestions_suggested_tag_name ON transaction_tag_suggestions(suggested_tag_name);
CREATE INDEX IF NOT EXISTS idx_transaction_tag_suggestions_status ON transaction_tag_suggestions(status);
CREATE INDEX IF NOT EXISTS idx_transaction_tag_suggestions_confidence_score ON transaction_tag_suggestions(confidence_score DESC);
CREATE INDEX IF NOT EXISTS idx_transaction_tag_suggestions_suggestion_source ON transaction_tag_suggestions(suggestion_source);
CREATE INDEX IF NOT EXISTS idx_transaction_tag_suggestions_expires_at ON transaction_tag_suggestions(expires_at);
CREATE INDEX IF NOT EXISTS idx_transaction_tag_suggestions_is_expired ON transaction_tag_suggestions(is_expired) WHERE is_expired = TRUE;
CREATE INDEX IF NOT EXISTS idx_transaction_tag_suggestions_reviewed_by_user_id ON transaction_tag_suggestions(reviewed_by_user_id);
CREATE INDEX IF NOT EXISTS idx_transaction_tag_suggestions_created_at ON transaction_tag_suggestions(created_at DESC);

-- Composite indexes
CREATE INDEX IF NOT EXISTS idx_transaction_metadata_store_key_type ON transaction_metadata(store_id, metadata_key, metadata_type);
CREATE INDEX IF NOT EXISTS idx_transaction_tags_store_category_name ON transaction_tags(store_id, tag_category, tag_name);
CREATE INDEX IF NOT EXISTS idx_transaction_tag_suggestions_store_status_confidence ON transaction_tag_suggestions(store_id, status, confidence_score DESC);

-- =============================================================================
-- Triggers
-- =============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_transaction_metadata_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_transaction_metadata_updated_at
    BEFORE UPDATE ON transaction_metadata
    FOR EACH ROW
    EXECUTE FUNCTION update_transaction_metadata_updated_at();

CREATE TRIGGER trigger_update_transaction_metadata_templates_updated_at
    BEFORE UPDATE ON transaction_metadata_templates
    FOR EACH ROW
    EXECUTE FUNCTION update_transaction_metadata_updated_at();

CREATE TRIGGER trigger_update_transaction_tags_updated_at
    BEFORE UPDATE ON transaction_tags
    FOR EACH ROW
    EXECUTE FUNCTION update_transaction_metadata_updated_at();

CREATE TRIGGER trigger_update_transaction_tag_rules_updated_at
    BEFORE UPDATE ON transaction_tag_rules
    FOR EACH ROW
    EXECUTE FUNCTION update_transaction_metadata_updated_at();

CREATE TRIGGER trigger_update_transaction_tag_suggestions_updated_at
    BEFORE UPDATE ON transaction_tag_suggestions
    FOR EACH ROW
    EXECUTE FUNCTION update_transaction_metadata_updated_at();

-- Track metadata changes
CREATE OR REPLACE FUNCTION track_transaction_metadata_changes()
RETURNS TRIGGER AS $$
DECLARE
    changed_fields TEXT[];
    old_values JSONB := '{}';
    new_values JSONB := '{}';
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO transaction_metadata_history (
            metadata_id, transaction_id, store_id, change_type,
            new_values, change_source
        ) VALUES (
            NEW.id, NEW.transaction_id, NEW.store_id, 'created',
            to_jsonb(NEW), 'system'
        );
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        -- Detect changed fields
        IF OLD.metadata_value IS DISTINCT FROM NEW.metadata_value THEN
            changed_fields := array_append(changed_fields, 'metadata_value');
            old_values := old_values || jsonb_build_object('metadata_value', OLD.metadata_value);
            new_values := new_values || jsonb_build_object('metadata_value', NEW.metadata_value);
        END IF;
        
        IF OLD.is_valid IS DISTINCT FROM NEW.is_valid THEN
            changed_fields := array_append(changed_fields, 'is_valid');
            old_values := old_values || jsonb_build_object('is_valid', OLD.is_valid);
            new_values := new_values || jsonb_build_object('is_valid', NEW.is_valid);
        END IF;
        
        -- Insert history record if there are changes
        IF array_length(changed_fields, 1) > 0 THEN
            INSERT INTO transaction_metadata_history (
                metadata_id, transaction_id, store_id, change_type,
                changed_fields, old_values, new_values, change_source
            ) VALUES (
                NEW.id, NEW.transaction_id, NEW.store_id, 'updated',
                to_jsonb(changed_fields), old_values, new_values, 'system'
            );
        END IF;
        
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO transaction_metadata_history (
            metadata_id, transaction_id, store_id, change_type,
            old_values, change_source
        ) VALUES (
            OLD.id, OLD.transaction_id, OLD.store_id, 'deleted',
            to_jsonb(OLD), 'system'
        );
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_track_transaction_metadata_changes
    AFTER INSERT OR UPDATE OR DELETE ON transaction_metadata
    FOR EACH ROW
    EXECUTE FUNCTION track_transaction_metadata_changes();

-- Track tag assignment changes
CREATE OR REPLACE FUNCTION track_transaction_tag_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO transaction_tag_history (
            tag_assignment_id, transaction_id, store_id, tag_name,
            change_type, new_values, change_source
        ) VALUES (
            NEW.id, NEW.transaction_id, NEW.store_id, NEW.tag_name,
            'assigned', to_jsonb(NEW), 'system'
        );
        
        -- Update usage count and last used timestamp
        UPDATE transaction_tags 
        SET usage_count = usage_count + 1,
            last_used_at = CURRENT_TIMESTAMP
        WHERE id = NEW.id;
        
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO transaction_tag_history (
            tag_assignment_id, transaction_id, store_id, tag_name,
            change_type, old_values, new_values, change_source
        ) VALUES (
            NEW.id, NEW.transaction_id, NEW.store_id, NEW.tag_name,
            'updated', to_jsonb(OLD), to_jsonb(NEW), 'system'
        );
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO transaction_tag_history (
            tag_assignment_id, transaction_id, store_id, tag_name,
            change_type, old_values, change_source
        ) VALUES (
            OLD.id, OLD.transaction_id, OLD.store_id, OLD.tag_name,
            'removed', to_jsonb(OLD), 'system'
        );
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_track_transaction_tag_changes
    AFTER INSERT OR UPDATE OR DELETE ON transaction_tags
    FOR EACH ROW
    EXECUTE FUNCTION track_transaction_tag_changes();

-- Auto-expire tag suggestions
CREATE OR REPLACE FUNCTION auto_expire_tag_suggestions()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_expired = TRUE AND OLD.is_expired = FALSE THEN
        NEW.status = 'expired';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_expire_tag_suggestions
    BEFORE UPDATE ON transaction_tag_suggestions
    FOR EACH ROW
    EXECUTE FUNCTION auto_expire_tag_suggestions();

-- Update tag popularity scores
CREATE OR REPLACE FUNCTION update_tag_popularity_score()
RETURNS TRIGGER AS $$
BEGIN
    -- Simple popularity calculation based on usage and recency
    NEW.popularity_score = LEAST(10.0, 
        (NEW.usage_count * 0.1) + 
        (NEW.click_count * 0.05) + 
        CASE 
            WHEN NEW.last_used_at > CURRENT_TIMESTAMP - INTERVAL '7 days' THEN 2.0
            WHEN NEW.last_used_at > CURRENT_TIMESTAMP - INTERVAL '30 days' THEN 1.0
            ELSE 0.0
        END
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_tag_popularity_score
    BEFORE UPDATE ON transaction_tags
    FOR EACH ROW
    WHEN (OLD.usage_count IS DISTINCT FROM NEW.usage_count OR 
          OLD.click_count IS DISTINCT FROM NEW.click_count OR 
          OLD.last_used_at IS DISTINCT FROM NEW.last_used_at)
    EXECUTE FUNCTION update_tag_popularity_score();

-- =============================================================================
-- Helper Functions
-- =============================================================================

/**
 * Get transaction metadata
 * @param p_transaction_id UUID - Transaction ID
 * @param p_metadata_key VARCHAR - Optional specific metadata key
 * @return JSONB - Metadata values
 */
CREATE OR REPLACE FUNCTION get_transaction_metadata(
    p_transaction_id UUID,
    p_metadata_key VARCHAR DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    IF p_metadata_key IS NOT NULL THEN
        SELECT jsonb_build_object(
            'key', tm.metadata_key,
            'value', tm.metadata_value,
            'type', tm.metadata_type,
            'is_sensitive', tm.is_sensitive,
            'display_name', tm.display_name,
            'locale', tm.locale
        ) INTO result
        FROM transaction_metadata tm
        WHERE tm.transaction_id = p_transaction_id
        AND tm.metadata_key = p_metadata_key
        AND tm.is_expired = FALSE;
    ELSE
        SELECT jsonb_object_agg(
            tm.metadata_key,
            jsonb_build_object(
                'value', tm.metadata_value,
                'type', tm.metadata_type,
                'display_name', tm.display_name,
                'is_sensitive', tm.is_sensitive
            )
        ) INTO result
        FROM transaction_metadata tm
        WHERE tm.transaction_id = p_transaction_id
        AND tm.is_expired = FALSE;
    END IF;
    
    RETURN COALESCE(result, '{}'::jsonb);
END;
$$ LANGUAGE plpgsql;

/**
 * Set transaction metadata
 * @param p_transaction_id UUID - Transaction ID
 * @param p_metadata_key VARCHAR - Metadata key
 * @param p_metadata_value TEXT - Metadata value
 * @param p_metadata_type VARCHAR - Metadata type
 * @return BOOLEAN - Success status
 */
CREATE OR REPLACE FUNCTION set_transaction_metadata(
    p_transaction_id UUID,
    p_metadata_key VARCHAR,
    p_metadata_value TEXT,
    p_metadata_type VARCHAR DEFAULT 'string'
)
RETURNS BOOLEAN AS $$
DECLARE
    v_store_id UUID;
BEGIN
    -- Get store_id from transaction
    SELECT store_id INTO v_store_id
    FROM transactions
    WHERE id = p_transaction_id;
    
    IF v_store_id IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Insert or update metadata
    INSERT INTO transaction_metadata (
        transaction_id, store_id, metadata_key, metadata_value, metadata_type
    ) VALUES (
        p_transaction_id, v_store_id, p_metadata_key, p_metadata_value, p_metadata_type
    )
    ON CONFLICT (transaction_id, metadata_key)
    DO UPDATE SET
        metadata_value = EXCLUDED.metadata_value,
        metadata_type = EXCLUDED.metadata_type,
        version = transaction_metadata.version + 1,
        previous_value = transaction_metadata.metadata_value,
        updated_at = CURRENT_TIMESTAMP;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

/**
 * Get transaction tags
 * @param p_transaction_id UUID - Transaction ID
 * @return TEXT[] - Array of tag names
 */
CREATE OR REPLACE FUNCTION get_transaction_tags(
    p_transaction_id UUID
)
RETURNS TEXT[] AS $$
DECLARE
    result TEXT[];
BEGIN
    SELECT array_agg(tag_name ORDER BY display_order, tag_name) INTO result
    FROM transaction_tags
    WHERE transaction_id = p_transaction_id
    AND is_active = TRUE;
    
    RETURN COALESCE(result, '{}');
END;
$$ LANGUAGE plpgsql;

/**
 * Assign tag to transaction
 * @param p_transaction_id UUID - Transaction ID
 * @param p_tag_name VARCHAR - Tag name
 * @param p_assigned_by_user_id UUID - User ID who assigned the tag
 * @return BOOLEAN - Success status
 */
CREATE OR REPLACE FUNCTION assign_transaction_tag(
    p_transaction_id UUID,
    p_tag_name VARCHAR,
    p_assigned_by_user_id UUID DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    v_store_id UUID;
    v_tag_slug VARCHAR;
BEGIN
    -- Get store_id from transaction
    SELECT store_id INTO v_store_id
    FROM transactions
    WHERE id = p_transaction_id;
    
    IF v_store_id IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Generate tag slug
    v_tag_slug := lower(regexp_replace(p_tag_name, '[^a-zA-Z0-9]+', '-', 'g'));
    
    -- Insert tag assignment
    INSERT INTO transaction_tags (
        transaction_id, store_id, tag_name, tag_slug, assigned_by_user_id
    ) VALUES (
        p_transaction_id, v_store_id, p_tag_name, v_tag_slug, p_assigned_by_user_id
    )
    ON CONFLICT (transaction_id, tag_name) DO NOTHING;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

/**
 * Remove tag from transaction
 * @param p_transaction_id UUID - Transaction ID
 * @param p_tag_name VARCHAR - Tag name
 * @return BOOLEAN - Success status
 */
CREATE OR REPLACE FUNCTION remove_transaction_tag(
    p_transaction_id UUID,
    p_tag_name VARCHAR
)
RETURNS BOOLEAN AS $$
BEGIN
    DELETE FROM transaction_tags
    WHERE transaction_id = p_transaction_id
    AND tag_name = p_tag_name;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

/**
 * Get transaction tag statistics
 * @param p_store_id UUID - Store ID
 * @return JSONB - Tag statistics
 */
CREATE OR REPLACE FUNCTION get_transaction_tag_stats(
    p_store_id UUID
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_tags', COUNT(*),
        'active_tags', COUNT(*) FILTER (WHERE is_active = TRUE),
        'system_tags', COUNT(*) FILTER (WHERE is_system_tag = TRUE),
        'auto_assigned_tags', COUNT(*) FILTER (WHERE is_auto_assigned = TRUE),
        'tag_category_breakdown', (
            SELECT jsonb_object_agg(tag_category, category_count)
            FROM (
                SELECT tag_category, COUNT(*) as category_count
                FROM transaction_tags
                WHERE store_id = p_store_id
                AND tag_category IS NOT NULL
                GROUP BY tag_category
            ) category_stats
        ),
        'most_popular_tags', (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'tag_name', tag_name,
                    'usage_count', usage_count,
                    'popularity_score', popularity_score
                )
                ORDER BY popularity_score DESC
            )
            FROM (
                SELECT tag_name, usage_count, popularity_score
                FROM transaction_tags
                WHERE store_id = p_store_id
                AND is_active = TRUE
                ORDER BY popularity_score DESC
                LIMIT 10
            ) popular_tags
        )
    ) INTO result
    FROM transaction_tags
    WHERE store_id = p_store_id;
    
    RETURN COALESCE(result, '{"error": "No tags found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Comments
-- =============================================================================

COMMENT ON TABLE transaction_metadata IS 'Normalized metadata from transactions';
COMMENT ON TABLE transaction_metadata_history IS 'Track changes to transaction metadata';
COMMENT ON TABLE transaction_metadata_templates IS 'Predefined metadata templates for transactions';
COMMENT ON TABLE transaction_tags IS 'Normalized tags from transactions';
COMMENT ON TABLE transaction_tag_history IS 'Track changes to transaction tag assignments';
COMMENT ON TABLE transaction_tag_rules IS 'Rules for automatic tag assignment';
COMMENT ON TABLE transaction_tag_suggestions IS 'AI/ML generated tag suggestions';

COMMENT ON COLUMN transaction_metadata.metadata_key IS 'Unique key for the metadata field';
COMMENT ON COLUMN transaction_metadata.is_sensitive IS 'Whether metadata contains sensitive information';
COMMENT ON COLUMN transaction_metadata.is_expired IS 'Auto-calculated expiration status';
COMMENT ON COLUMN transaction_tags.popularity_score IS 'Calculated popularity score based on usage and recency';
COMMENT ON COLUMN transaction_tag_suggestions.confidence_score IS 'ML model confidence in tag suggestion (0-1)';

COMMENT ON FUNCTION get_transaction_metadata(UUID, VARCHAR) IS 'Get metadata for transaction';
COMMENT ON FUNCTION set_transaction_metadata(UUID, VARCHAR, TEXT, VARCHAR) IS 'Set metadata for transaction';
COMMENT ON FUNCTION get_transaction_tags(UUID) IS 'Get tags for transaction';
COMMENT ON FUNCTION assign_transaction_tag(UUID, VARCHAR, UUID) IS 'Assign tag to transaction';
COMMENT ON FUNCTION remove_transaction_tag(UUID, VARCHAR) IS 'Remove tag from transaction';
COMMENT ON FUNCTION get_transaction_tag_stats(UUID) IS 'Get tag statistics for store';