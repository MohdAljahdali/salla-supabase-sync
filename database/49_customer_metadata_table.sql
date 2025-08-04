-- =============================================================================
-- Customer Metadata Table
-- =============================================================================
-- This table normalizes the 'metadata' JSONB column from the customers table
-- Stores additional customer metadata and custom fields

CREATE TABLE IF NOT EXISTS customer_metadata (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Metadata identification
    meta_key VARCHAR(255) NOT NULL,
    meta_value TEXT,
    meta_type VARCHAR(50) DEFAULT 'string' CHECK (meta_type IN (
        'string', 'number', 'boolean', 'date', 'datetime', 'json', 'array', 'url', 'email', 'phone'
    )),
    
    -- Metadata properties
    is_public BOOLEAN DEFAULT FALSE, -- Whether customer can see this metadata
    is_searchable BOOLEAN DEFAULT TRUE,
    is_required BOOLEAN DEFAULT FALSE,
    is_system BOOLEAN DEFAULT FALSE, -- System-generated metadata
    
    -- Data validation
    validation_rules JSONB DEFAULT '{}', -- Validation rules for the value
    is_valid BOOLEAN DEFAULT TRUE,
    validation_errors JSONB DEFAULT '[]',
    last_validated_at TIMESTAMPTZ,
    
    -- Localization
    language_code VARCHAR(10) DEFAULT 'ar',
    localized_values JSONB DEFAULT '{}', -- {"en": "value", "ar": "قيمة"}
    
    -- Display properties
    display_name VARCHAR(255),
    display_order INTEGER DEFAULT 0,
    display_group VARCHAR(100), -- Group metadata fields together
    help_text TEXT,
    placeholder_text VARCHAR(255),
    
    -- Data source and origin
    source_system VARCHAR(100) DEFAULT 'salla',
    source_field VARCHAR(255), -- Original field name from source
    import_batch_id UUID,
    
    -- Versioning and history
    version INTEGER DEFAULT 1,
    previous_value TEXT,
    change_reason VARCHAR(255),
    changed_by_user_id UUID,
    
    -- Performance and analytics
    usage_count INTEGER DEFAULT 0, -- How often this metadata is accessed
    last_accessed_at TIMESTAMPTZ,
    
    -- SEO and marketing
    seo_weight DECIMAL(3,2) DEFAULT 0, -- Weight for SEO purposes (0.00 to 1.00)
    marketing_segment VARCHAR(100), -- Marketing segment this metadata relates to
    
    -- Privacy and compliance
    is_pii BOOLEAN DEFAULT FALSE, -- Personally Identifiable Information
    retention_period_days INTEGER, -- How long to keep this data
    anonymize_after_days INTEGER, -- When to anonymize this data
    
    -- External references
    external_id VARCHAR(255),
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
    expires_at TIMESTAMPTZ, -- When this metadata expires
    
    -- Constraints
    CONSTRAINT customer_metadata_unique_key UNIQUE(customer_id, meta_key),
    CONSTRAINT customer_metadata_seo_weight_check CHECK (seo_weight >= 0 AND seo_weight <= 1)
);

-- =============================================================================
-- Customer Metadata History Table
-- =============================================================================
-- Track changes to customer metadata

CREATE TABLE IF NOT EXISTS customer_metadata_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    metadata_id UUID REFERENCES customer_metadata(id) ON DELETE SET NULL,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Change information
    meta_key VARCHAR(255) NOT NULL,
    change_type VARCHAR(20) NOT NULL CHECK (change_type IN (
        'created', 'updated', 'deleted', 'validated', 'anonymized', 'expired'
    )),
    old_value TEXT,
    new_value TEXT,
    old_meta_type VARCHAR(50),
    new_meta_type VARCHAR(50),
    
    -- Change context
    changed_by_user_id UUID,
    change_reason VARCHAR(255),
    change_source VARCHAR(50) DEFAULT 'system',
    batch_id UUID, -- For bulk operations
    
    -- Compliance tracking
    compliance_action VARCHAR(100), -- GDPR, data retention, etc.
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- Customer Metadata Templates Table
-- =============================================================================
-- Define templates for common metadata structures

CREATE TABLE IF NOT EXISTS customer_metadata_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Template identification
    template_name VARCHAR(255) NOT NULL,
    template_description TEXT,
    template_category VARCHAR(100), -- 'profile', 'preferences', 'analytics', etc.
    
    -- Template structure
    metadata_fields JSONB NOT NULL, -- Array of field definitions
    default_values JSONB DEFAULT '{}',
    validation_schema JSONB DEFAULT '{}',
    
    -- Template properties
    is_active BOOLEAN DEFAULT TRUE,
    is_system_template BOOLEAN DEFAULT FALSE,
    version VARCHAR(20) DEFAULT '1.0',
    
    -- Usage tracking
    usage_count INTEGER DEFAULT 0,
    last_used_at TIMESTAMPTZ,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT customer_metadata_templates_unique_name UNIQUE(store_id, template_name)
);

-- =============================================================================
-- Indexes
-- =============================================================================

-- Basic indexes
CREATE INDEX IF NOT EXISTS idx_customer_metadata_customer_id ON customer_metadata(customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_metadata_store_id ON customer_metadata(store_id);
CREATE INDEX IF NOT EXISTS idx_customer_metadata_meta_key ON customer_metadata(meta_key);
CREATE INDEX IF NOT EXISTS idx_customer_metadata_external_id ON customer_metadata(external_id);

-- Metadata properties
CREATE INDEX IF NOT EXISTS idx_customer_metadata_meta_type ON customer_metadata(meta_type);
CREATE INDEX IF NOT EXISTS idx_customer_metadata_is_public ON customer_metadata(is_public);
CREATE INDEX IF NOT EXISTS idx_customer_metadata_is_searchable ON customer_metadata(is_searchable) WHERE is_searchable = TRUE;
CREATE INDEX IF NOT EXISTS idx_customer_metadata_is_required ON customer_metadata(is_required) WHERE is_required = TRUE;
CREATE INDEX IF NOT EXISTS idx_customer_metadata_is_system ON customer_metadata(is_system);

-- Data validation
CREATE INDEX IF NOT EXISTS idx_customer_metadata_is_valid ON customer_metadata(is_valid);
CREATE INDEX IF NOT EXISTS idx_customer_metadata_last_validated_at ON customer_metadata(last_validated_at DESC);

-- Localization
CREATE INDEX IF NOT EXISTS idx_customer_metadata_language_code ON customer_metadata(language_code);

-- Display properties
CREATE INDEX IF NOT EXISTS idx_customer_metadata_display_group ON customer_metadata(display_group);
CREATE INDEX IF NOT EXISTS idx_customer_metadata_display_order ON customer_metadata(display_order);

-- Data source
CREATE INDEX IF NOT EXISTS idx_customer_metadata_source_system ON customer_metadata(source_system);
CREATE INDEX IF NOT EXISTS idx_customer_metadata_source_field ON customer_metadata(source_field);
CREATE INDEX IF NOT EXISTS idx_customer_metadata_import_batch_id ON customer_metadata(import_batch_id) WHERE import_batch_id IS NOT NULL;

-- Versioning
CREATE INDEX IF NOT EXISTS idx_customer_metadata_version ON customer_metadata(version DESC);
CREATE INDEX IF NOT EXISTS idx_customer_metadata_changed_by ON customer_metadata(changed_by_user_id);

-- Performance
CREATE INDEX IF NOT EXISTS idx_customer_metadata_usage_count ON customer_metadata(usage_count DESC);
CREATE INDEX IF NOT EXISTS idx_customer_metadata_last_accessed_at ON customer_metadata(last_accessed_at DESC);

-- SEO and marketing
CREATE INDEX IF NOT EXISTS idx_customer_metadata_seo_weight ON customer_metadata(seo_weight DESC);
CREATE INDEX IF NOT EXISTS idx_customer_metadata_marketing_segment ON customer_metadata(marketing_segment);

-- Privacy and compliance
CREATE INDEX IF NOT EXISTS idx_customer_metadata_is_pii ON customer_metadata(is_pii) WHERE is_pii = TRUE;
CREATE INDEX IF NOT EXISTS idx_customer_metadata_retention_period ON customer_metadata(retention_period_days);
CREATE INDEX IF NOT EXISTS idx_customer_metadata_anonymize_after ON customer_metadata(anonymize_after_days);

-- Sync information
CREATE INDEX IF NOT EXISTS idx_customer_metadata_sync_status ON customer_metadata(sync_status);
CREATE INDEX IF NOT EXISTS idx_customer_metadata_last_sync_at ON customer_metadata(last_sync_at DESC);

-- Timestamps
CREATE INDEX IF NOT EXISTS idx_customer_metadata_created_at ON customer_metadata(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_customer_metadata_updated_at ON customer_metadata(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_customer_metadata_expires_at ON customer_metadata(expires_at) WHERE expires_at IS NOT NULL;

-- JSONB indexes
CREATE INDEX IF NOT EXISTS idx_customer_metadata_validation_rules ON customer_metadata USING gin(validation_rules);
CREATE INDEX IF NOT EXISTS idx_customer_metadata_validation_errors ON customer_metadata USING gin(validation_errors);
CREATE INDEX IF NOT EXISTS idx_customer_metadata_localized_values ON customer_metadata USING gin(localized_values);
CREATE INDEX IF NOT EXISTS idx_customer_metadata_external_references ON customer_metadata USING gin(external_references);
CREATE INDEX IF NOT EXISTS idx_customer_metadata_custom_fields ON customer_metadata USING gin(custom_fields);
CREATE INDEX IF NOT EXISTS idx_customer_metadata_sync_errors ON customer_metadata USING gin(sync_errors);

-- Text search indexes
CREATE INDEX IF NOT EXISTS idx_customer_metadata_meta_value_text ON customer_metadata USING gin(to_tsvector('english', meta_value)) WHERE is_searchable = TRUE;
CREATE INDEX IF NOT EXISTS idx_customer_metadata_display_name_text ON customer_metadata USING gin(to_tsvector('english', display_name));

-- Composite indexes
CREATE INDEX IF NOT EXISTS idx_customer_metadata_customer_key ON customer_metadata(customer_id, meta_key, is_public);
CREATE INDEX IF NOT EXISTS idx_customer_metadata_customer_group ON customer_metadata(customer_id, display_group, display_order);
CREATE INDEX IF NOT EXISTS idx_customer_metadata_searchable ON customer_metadata(is_searchable, meta_type, language_code) WHERE is_searchable = TRUE;
CREATE INDEX IF NOT EXISTS idx_customer_metadata_compliance ON customer_metadata(is_pii, retention_period_days, created_at) WHERE is_pii = TRUE;

-- History table indexes
CREATE INDEX IF NOT EXISTS idx_customer_metadata_history_metadata_id ON customer_metadata_history(metadata_id);
CREATE INDEX IF NOT EXISTS idx_customer_metadata_history_customer_id ON customer_metadata_history(customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_metadata_history_store_id ON customer_metadata_history(store_id);
CREATE INDEX IF NOT EXISTS idx_customer_metadata_history_meta_key ON customer_metadata_history(meta_key);
CREATE INDEX IF NOT EXISTS idx_customer_metadata_history_change_type ON customer_metadata_history(change_type);
CREATE INDEX IF NOT EXISTS idx_customer_metadata_history_created_at ON customer_metadata_history(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_customer_metadata_history_changed_by ON customer_metadata_history(changed_by_user_id);
CREATE INDEX IF NOT EXISTS idx_customer_metadata_history_batch_id ON customer_metadata_history(batch_id) WHERE batch_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_customer_metadata_history_compliance ON customer_metadata_history(compliance_action) WHERE compliance_action IS NOT NULL;

-- Templates table indexes
CREATE INDEX IF NOT EXISTS idx_customer_metadata_templates_store_id ON customer_metadata_templates(store_id);
CREATE INDEX IF NOT EXISTS idx_customer_metadata_templates_name ON customer_metadata_templates(template_name);
CREATE INDEX IF NOT EXISTS idx_customer_metadata_templates_category ON customer_metadata_templates(template_category);
CREATE INDEX IF NOT EXISTS idx_customer_metadata_templates_is_active ON customer_metadata_templates(is_active);
CREATE INDEX IF NOT EXISTS idx_customer_metadata_templates_is_system ON customer_metadata_templates(is_system_template);
CREATE INDEX IF NOT EXISTS idx_customer_metadata_templates_usage_count ON customer_metadata_templates(usage_count DESC);
CREATE INDEX IF NOT EXISTS idx_customer_metadata_templates_last_used_at ON customer_metadata_templates(last_used_at DESC);

-- =============================================================================
-- Triggers
-- =============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_customer_metadata_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_customer_metadata_updated_at
    BEFORE UPDATE ON customer_metadata
    FOR EACH ROW
    EXECUTE FUNCTION update_customer_metadata_updated_at();

CREATE TRIGGER trigger_update_customer_metadata_templates_updated_at
    BEFORE UPDATE ON customer_metadata_templates
    FOR EACH ROW
    EXECUTE FUNCTION update_customer_metadata_updated_at();

-- Track metadata changes
CREATE OR REPLACE FUNCTION track_customer_metadata_changes()
RETURNS TRIGGER AS $$
DECLARE
    change_type_val VARCHAR(20);
BEGIN
    IF TG_OP = 'INSERT' THEN
        change_type_val := 'created';
        INSERT INTO customer_metadata_history (
            metadata_id, customer_id, store_id, meta_key, change_type,
            new_value, new_meta_type, change_source
        ) VALUES (
            NEW.id, NEW.customer_id, NEW.store_id, NEW.meta_key, change_type_val,
            NEW.meta_value, NEW.meta_type, 'system'
        );
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        change_type_val := 'updated';
        
        -- Only log if value actually changed
        IF OLD.meta_value IS DISTINCT FROM NEW.meta_value OR OLD.meta_type IS DISTINCT FROM NEW.meta_type THEN
            -- Update version
            NEW.version := OLD.version + 1;
            NEW.previous_value := OLD.meta_value;
            
            INSERT INTO customer_metadata_history (
                metadata_id, customer_id, store_id, meta_key, change_type,
                old_value, new_value, old_meta_type, new_meta_type,
                changed_by_user_id, change_reason, change_source
            ) VALUES (
                NEW.id, NEW.customer_id, NEW.store_id, NEW.meta_key, change_type_val,
                OLD.meta_value, NEW.meta_value, OLD.meta_type, NEW.meta_type,
                NEW.changed_by_user_id, NEW.change_reason, 'system'
            );
        END IF;
        
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        change_type_val := 'deleted';
        INSERT INTO customer_metadata_history (
            metadata_id, customer_id, store_id, meta_key, change_type,
            old_value, old_meta_type, change_source
        ) VALUES (
            OLD.id, OLD.customer_id, OLD.store_id, OLD.meta_key, change_type_val,
            OLD.meta_value, OLD.meta_type, 'system'
        );
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_track_customer_metadata_changes
    AFTER INSERT OR UPDATE OR DELETE ON customer_metadata
    FOR EACH ROW
    EXECUTE FUNCTION track_customer_metadata_changes();

-- Validate metadata value based on type
CREATE OR REPLACE FUNCTION validate_metadata_value()
RETURNS TRIGGER AS $$
BEGIN
    -- Reset validation status
    NEW.is_valid := TRUE;
    NEW.validation_errors := '[]'::jsonb;
    NEW.last_validated_at := CURRENT_TIMESTAMP;
    
    -- Validate based on meta_type
    CASE NEW.meta_type
        WHEN 'number' THEN
            IF NEW.meta_value !~ '^-?\d+(\.\d+)?$' THEN
                NEW.is_valid := FALSE;
                NEW.validation_errors := '["Invalid number format"]'::jsonb;
            END IF;
        WHEN 'boolean' THEN
            IF NEW.meta_value NOT IN ('true', 'false', '1', '0', 'yes', 'no') THEN
                NEW.is_valid := FALSE;
                NEW.validation_errors := '["Invalid boolean value"]'::jsonb;
            END IF;
        WHEN 'email' THEN
            IF NEW.meta_value !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
                NEW.is_valid := FALSE;
                NEW.validation_errors := '["Invalid email format"]'::jsonb;
            END IF;
        WHEN 'url' THEN
            IF NEW.meta_value !~ '^https?://[^\s/$.?#].[^\s]*$' THEN
                NEW.is_valid := FALSE;
                NEW.validation_errors := '["Invalid URL format"]'::jsonb;
            END IF;
        WHEN 'phone' THEN
            IF NEW.meta_value !~ '^[+]?[0-9\s\-\(\)]+$' THEN
                NEW.is_valid := FALSE;
                NEW.validation_errors := '["Invalid phone format"]'::jsonb;
            END IF;
        WHEN 'date' THEN
            BEGIN
                PERFORM NEW.meta_value::date;
            EXCEPTION WHEN OTHERS THEN
                NEW.is_valid := FALSE;
                NEW.validation_errors := '["Invalid date format"]'::jsonb;
            END;
        WHEN 'datetime' THEN
            BEGIN
                PERFORM NEW.meta_value::timestamptz;
            EXCEPTION WHEN OTHERS THEN
                NEW.is_valid := FALSE;
                NEW.validation_errors := '["Invalid datetime format"]'::jsonb;
            END;
        WHEN 'json' THEN
            BEGIN
                PERFORM NEW.meta_value::jsonb;
            EXCEPTION WHEN OTHERS THEN
                NEW.is_valid := FALSE;
                NEW.validation_errors := '["Invalid JSON format"]'::jsonb;
            END;
        ELSE
            -- For string and other types, no specific validation
            NULL;
    END CASE;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validate_metadata_value
    BEFORE INSERT OR UPDATE ON customer_metadata
    FOR EACH ROW
    WHEN (NEW.meta_value IS NOT NULL)
    EXECUTE FUNCTION validate_metadata_value();

-- Auto-expire metadata
CREATE OR REPLACE FUNCTION auto_expire_metadata()
RETURNS TRIGGER AS $$
BEGIN
    -- Mark expired metadata
    UPDATE customer_metadata 
    SET 
        is_valid = FALSE,
        validation_errors = '["Metadata expired"]'::jsonb
    WHERE expires_at < CURRENT_TIMESTAMP 
    AND is_valid = TRUE;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_expire_metadata
    AFTER INSERT ON customer_metadata
    FOR EACH STATEMENT
    EXECUTE FUNCTION auto_expire_metadata();

-- =============================================================================
-- Helper Functions
-- =============================================================================

/**
 * Get customer metadata by key or group
 * @param p_customer_id UUID - Customer ID
 * @param p_meta_key VARCHAR - Specific metadata key (optional)
 * @param p_display_group VARCHAR - Display group filter (optional)
 * @return TABLE - Customer metadata
 */
CREATE OR REPLACE FUNCTION get_customer_metadata(
    p_customer_id UUID,
    p_meta_key VARCHAR DEFAULT NULL,
    p_display_group VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    meta_key VARCHAR,
    meta_value TEXT,
    meta_type VARCHAR,
    display_name VARCHAR,
    is_public BOOLEAN,
    is_valid BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cm.meta_key,
        cm.meta_value,
        cm.meta_type,
        cm.display_name,
        cm.is_public,
        cm.is_valid
    FROM customer_metadata cm
    WHERE cm.customer_id = p_customer_id
    AND (p_meta_key IS NULL OR cm.meta_key = p_meta_key)
    AND (p_display_group IS NULL OR cm.display_group = p_display_group)
    ORDER BY cm.display_order, cm.meta_key;
END;
$$ LANGUAGE plpgsql;

/**
 * Set customer metadata value
 * @param p_customer_id UUID - Customer ID
 * @param p_meta_key VARCHAR - Metadata key
 * @param p_meta_value TEXT - Metadata value
 * @param p_meta_type VARCHAR - Value type
 * @return BOOLEAN - Success status
 */
CREATE OR REPLACE FUNCTION set_customer_metadata(
    p_customer_id UUID,
    p_meta_key VARCHAR,
    p_meta_value TEXT,
    p_meta_type VARCHAR DEFAULT 'string'
)
RETURNS BOOLEAN AS $$
DECLARE
    store_id_val UUID;
    existing_metadata UUID;
BEGIN
    -- Get store_id from customer
    SELECT store_id INTO store_id_val FROM customers WHERE id = p_customer_id;
    
    IF store_id_val IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Check if metadata already exists
    SELECT id INTO existing_metadata 
    FROM customer_metadata 
    WHERE customer_id = p_customer_id AND meta_key = p_meta_key;
    
    IF existing_metadata IS NOT NULL THEN
        -- Update existing metadata
        UPDATE customer_metadata 
        SET 
            meta_value = p_meta_value,
            meta_type = p_meta_type,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = existing_metadata;
    ELSE
        -- Create new metadata
        INSERT INTO customer_metadata (
            customer_id, store_id, meta_key, meta_value, meta_type
        ) VALUES (
            p_customer_id, store_id_val, p_meta_key, p_meta_value, p_meta_type
        );
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

/**
 * Search customers by metadata
 * @param p_store_id UUID - Store ID
 * @param p_search_criteria JSONB - Search criteria
 * @return TABLE - Matching customers
 */
CREATE OR REPLACE FUNCTION search_customers_by_metadata(
    p_store_id UUID,
    p_search_criteria JSONB
)
RETURNS TABLE (
    customer_id UUID,
    customer_name VARCHAR,
    customer_email VARCHAR,
    matching_metadata JSONB
) AS $$
DECLARE
    criteria_key VARCHAR;
    criteria_value TEXT;
    criteria_record RECORD;
BEGIN
    -- This is a simplified implementation
    -- In practice, you'd want more sophisticated search logic
    
    RETURN QUERY
    SELECT DISTINCT
        c.id as customer_id,
        CONCAT(c.first_name, ' ', c.last_name) as customer_name,
        c.email as customer_email,
        jsonb_agg(
            jsonb_build_object(
                'key', cm.meta_key,
                'value', cm.meta_value,
                'type', cm.meta_type
            )
        ) as matching_metadata
    FROM customers c
    JOIN customer_metadata cm ON cm.customer_id = c.id
    WHERE c.store_id = p_store_id
    AND cm.is_searchable = TRUE
    AND (
        -- Simple text search in metadata values
        (p_search_criteria ? 'search_term' AND 
         cm.meta_value ILIKE '%' || (p_search_criteria->>'search_term') || '%')
        OR
        -- Exact key-value match
        (p_search_criteria ? 'exact_matches' AND
         EXISTS (
             SELECT 1 FROM jsonb_each_text(p_search_criteria->'exact_matches') as kv
             WHERE cm.meta_key = kv.key AND cm.meta_value = kv.value
         ))
    )
    GROUP BY c.id, c.first_name, c.last_name, c.email;
END;
$$ LANGUAGE plpgsql;

/**
 * Apply metadata template to customer
 * @param p_customer_id UUID - Customer ID
 * @param p_template_id UUID - Template ID
 * @param p_values JSONB - Values to set (optional)
 * @return INTEGER - Number of metadata fields created
 */
CREATE OR REPLACE FUNCTION apply_metadata_template(
    p_customer_id UUID,
    p_template_id UUID,
    p_values JSONB DEFAULT '{}'
)
RETURNS INTEGER AS $$
DECLARE
    template_record customer_metadata_templates;
    field_record RECORD;
    fields_created INTEGER := 0;
    store_id_val UUID;
BEGIN
    -- Get template
    SELECT * INTO template_record 
    FROM customer_metadata_templates 
    WHERE id = p_template_id AND is_active = TRUE;
    
    IF template_record.id IS NULL THEN
        RETURN 0;
    END IF;
    
    -- Get store_id from customer
    SELECT store_id INTO store_id_val FROM customers WHERE id = p_customer_id;
    
    IF store_id_val IS NULL THEN
        RETURN 0;
    END IF;
    
    -- Apply each field from template
    FOR field_record IN 
        SELECT * FROM jsonb_array_elements(template_record.metadata_fields)
    LOOP
        -- Create metadata field
        INSERT INTO customer_metadata (
            customer_id, store_id, meta_key, meta_value, meta_type,
            display_name, display_group, is_required, is_public
        ) VALUES (
            p_customer_id, store_id_val,
            field_record.value->>'key',
            COALESCE(
                p_values->>field_record.value->>'key',
                template_record.default_values->>field_record.value->>'key',
                field_record.value->>'default_value'
            ),
            COALESCE(field_record.value->>'type', 'string'),
            field_record.value->>'display_name',
            template_record.template_category,
            COALESCE((field_record.value->>'required')::boolean, FALSE),
            COALESCE((field_record.value->>'public')::boolean, FALSE)
        )
        ON CONFLICT (customer_id, meta_key) DO NOTHING;
        
        fields_created := fields_created + 1;
    END LOOP;
    
    -- Update template usage
    UPDATE customer_metadata_templates 
    SET 
        usage_count = usage_count + 1,
        last_used_at = CURRENT_TIMESTAMP
    WHERE id = p_template_id;
    
    RETURN fields_created;
END;
$$ LANGUAGE plpgsql;

/**
 * Get customer metadata statistics
 * @param p_customer_id UUID - Customer ID
 * @return JSONB - Metadata statistics
 */
CREATE OR REPLACE FUNCTION get_customer_metadata_stats(
    p_customer_id UUID
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_metadata', COUNT(*),
        'public_metadata', COUNT(*) FILTER (WHERE is_public = TRUE),
        'valid_metadata', COUNT(*) FILTER (WHERE is_valid = TRUE),
        'required_metadata', COUNT(*) FILTER (WHERE is_required = TRUE),
        'system_metadata', COUNT(*) FILTER (WHERE is_system = TRUE),
        'pii_metadata', COUNT(*) FILTER (WHERE is_pii = TRUE),
        'metadata_types', (
            SELECT jsonb_object_agg(meta_type, type_count)
            FROM (
                SELECT meta_type, COUNT(*) as type_count
                FROM customer_metadata
                WHERE customer_id = p_customer_id
                GROUP BY meta_type
            ) type_stats
        ),
        'display_groups', (
            SELECT jsonb_object_agg(display_group, group_count)
            FROM (
                SELECT display_group, COUNT(*) as group_count
                FROM customer_metadata
                WHERE customer_id = p_customer_id AND display_group IS NOT NULL
                GROUP BY display_group
            ) group_stats
        ),
        'source_systems', (
            SELECT jsonb_object_agg(source_system, source_count)
            FROM (
                SELECT source_system, COUNT(*) as source_count
                FROM customer_metadata
                WHERE customer_id = p_customer_id
                GROUP BY source_system
            ) source_stats
        ),
        'avg_seo_weight', AVG(seo_weight),
        'total_usage_count', SUM(usage_count)
    ) INTO result
    FROM customer_metadata
    WHERE customer_id = p_customer_id;
    
    RETURN COALESCE(result, '{"error": "No metadata found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Comments
-- =============================================================================

COMMENT ON TABLE customer_metadata IS 'Normalized customer metadata from customers.metadata JSONB column';
COMMENT ON TABLE customer_metadata_history IS 'Track changes to customer metadata';
COMMENT ON TABLE customer_metadata_templates IS 'Templates for common customer metadata structures';

COMMENT ON COLUMN customer_metadata.meta_key IS 'Metadata field key/name';
COMMENT ON COLUMN customer_metadata.meta_type IS 'Data type of the metadata value';
COMMENT ON COLUMN customer_metadata.is_pii IS 'Whether this metadata contains personally identifiable information';
COMMENT ON COLUMN customer_metadata.retention_period_days IS 'How long to keep this metadata (for compliance)';
COMMENT ON COLUMN customer_metadata.seo_weight IS 'Weight for SEO purposes (0.00 to 1.00)';
COMMENT ON COLUMN customer_metadata.version IS 'Version number for change tracking';

COMMENT ON FUNCTION get_customer_metadata(UUID, VARCHAR, VARCHAR) IS 'Get customer metadata by key or group';
COMMENT ON FUNCTION set_customer_metadata(UUID, VARCHAR, TEXT, VARCHAR) IS 'Set customer metadata value';
COMMENT ON FUNCTION search_customers_by_metadata(UUID, JSONB) IS 'Search customers by metadata criteria';
COMMENT ON FUNCTION apply_metadata_template(UUID, UUID, JSONB) IS 'Apply metadata template to customer';
COMMENT ON FUNCTION get_customer_metadata_stats(UUID) IS 'Get customer metadata statistics';