-- =============================================================================
-- Order Metadata Table
-- =============================================================================
-- This table normalizes the 'metadata' JSONB column from the orders table
-- Stores metadata information for orders

CREATE TABLE IF NOT EXISTS order_metadata (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Metadata identification
    metadata_key VARCHAR(100) NOT NULL,
    metadata_value TEXT,
    metadata_type VARCHAR(50) DEFAULT 'string' CHECK (metadata_type IN (
        'string', 'number', 'boolean', 'date', 'datetime', 'json', 'url', 'email', 'phone'
    )),
    
    -- Metadata properties
    is_system_metadata BOOLEAN DEFAULT FALSE,
    is_public BOOLEAN DEFAULT TRUE,
    is_searchable BOOLEAN DEFAULT TRUE,
    is_required BOOLEAN DEFAULT FALSE,
    is_encrypted BOOLEAN DEFAULT FALSE,
    
    -- Validation
    validation_rules JSONB DEFAULT '{}',
    is_valid BOOLEAN DEFAULT TRUE,
    validation_errors JSONB DEFAULT '[]',
    last_validated_at TIMESTAMPTZ,
    
    -- Localization
    language_code VARCHAR(5) DEFAULT 'en',
    localized_values JSONB DEFAULT '{}', -- {"ar": "value_in_arabic", "en": "value_in_english"}
    
    -- Display properties
    display_name VARCHAR(255),
    display_order INTEGER DEFAULT 0,
    display_group VARCHAR(100),
    is_featured BOOLEAN DEFAULT FALSE,
    show_in_summary BOOLEAN DEFAULT FALSE,
    
    -- Data source and tracking
    data_source VARCHAR(50) DEFAULT 'manual' CHECK (data_source IN (
        'manual', 'automatic', 'imported', 'calculated', 'webhook', 'api', 'system'
    )),
    source_reference VARCHAR(255),
    created_by_user_id UUID,
    updated_by_user_id UUID,
    
    -- Versioning
    version INTEGER DEFAULT 1,
    previous_value TEXT,
    change_reason VARCHAR(255),
    
    -- Performance and analytics
    access_count INTEGER DEFAULT 0,
    last_accessed_at TIMESTAMPTZ,
    usage_frequency DECIMAL(5,2) DEFAULT 0.00,
    performance_impact DECIMAL(3,2) DEFAULT 0.00,
    
    -- SEO and marketing
    seo_weight DECIMAL(3,2) DEFAULT 0.00,
    marketing_value DECIMAL(3,2) DEFAULT 0.00,
    conversion_impact DECIMAL(3,2) DEFAULT 0.00,
    
    -- Privacy and compliance
    privacy_level VARCHAR(20) DEFAULT 'public' CHECK (privacy_level IN (
        'public', 'internal', 'restricted', 'confidential', 'secret'
    )),
    data_classification VARCHAR(50),
    retention_period_days INTEGER,
    gdpr_category VARCHAR(50),
    
    -- Auto-expiration
    expires_at TIMESTAMPTZ,
    auto_delete_after_days INTEGER,
    
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
    UNIQUE(order_id, metadata_key, language_code)
);

-- =============================================================================
-- Order Metadata History Table
-- =============================================================================
-- Track changes to order metadata

CREATE TABLE IF NOT EXISTS order_metadata_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    metadata_id UUID REFERENCES order_metadata(id) ON DELETE SET NULL,
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Metadata information
    metadata_key VARCHAR(100) NOT NULL,
    
    -- Change information
    change_type VARCHAR(20) NOT NULL CHECK (change_type IN (
        'created', 'updated', 'deleted', 'validated', 'invalidated', 'accessed', 'expired'
    )),
    old_value TEXT,
    new_value TEXT,
    old_metadata_type VARCHAR(50),
    new_metadata_type VARCHAR(50),
    
    -- Change context
    changed_by_user_id UUID,
    change_reason VARCHAR(255),
    change_source VARCHAR(50) DEFAULT 'system',
    
    -- Version tracking
    version_before INTEGER,
    version_after INTEGER,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- Order Metadata Templates Table
-- =============================================================================
-- Define templates for common metadata structures

CREATE TABLE IF NOT EXISTS order_metadata_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Template identification
    template_name VARCHAR(100) NOT NULL,
    template_description TEXT,
    template_category VARCHAR(50),
    
    -- Template structure
    metadata_schema JSONB NOT NULL DEFAULT '{}',
    default_values JSONB DEFAULT '{}',
    validation_rules JSONB DEFAULT '{}',
    
    -- Template properties
    is_active BOOLEAN DEFAULT TRUE,
    is_system_template BOOLEAN DEFAULT FALSE,
    auto_apply BOOLEAN DEFAULT FALSE,
    apply_conditions JSONB DEFAULT '{}',
    
    -- Usage tracking
    usage_count INTEGER DEFAULT 0,
    last_used_at TIMESTAMPTZ,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    UNIQUE(store_id, template_name)
);

-- =============================================================================
-- Indexes
-- =============================================================================

-- Basic indexes
CREATE INDEX IF NOT EXISTS idx_order_metadata_order_id ON order_metadata(order_id);
CREATE INDEX IF NOT EXISTS idx_order_metadata_store_id ON order_metadata(store_id);
CREATE INDEX IF NOT EXISTS idx_order_metadata_key ON order_metadata(metadata_key);
CREATE INDEX IF NOT EXISTS idx_order_metadata_type ON order_metadata(metadata_type);
CREATE INDEX IF NOT EXISTS idx_order_metadata_external_id ON order_metadata(external_metadata_id);

-- Metadata properties
CREATE INDEX IF NOT EXISTS idx_order_metadata_is_system ON order_metadata(is_system_metadata);
CREATE INDEX IF NOT EXISTS idx_order_metadata_is_public ON order_metadata(is_public) WHERE is_public = TRUE;
CREATE INDEX IF NOT EXISTS idx_order_metadata_is_searchable ON order_metadata(is_searchable) WHERE is_searchable = TRUE;
CREATE INDEX IF NOT EXISTS idx_order_metadata_is_required ON order_metadata(is_required) WHERE is_required = TRUE;
CREATE INDEX IF NOT EXISTS idx_order_metadata_is_encrypted ON order_metadata(is_encrypted) WHERE is_encrypted = TRUE;

-- Validation
CREATE INDEX IF NOT EXISTS idx_order_metadata_is_valid ON order_metadata(is_valid);
CREATE INDEX IF NOT EXISTS idx_order_metadata_last_validated_at ON order_metadata(last_validated_at DESC);

-- Localization
CREATE INDEX IF NOT EXISTS idx_order_metadata_language_code ON order_metadata(language_code);

-- Display properties
CREATE INDEX IF NOT EXISTS idx_order_metadata_display_order ON order_metadata(display_order);
CREATE INDEX IF NOT EXISTS idx_order_metadata_display_group ON order_metadata(display_group);
CREATE INDEX IF NOT EXISTS idx_order_metadata_is_featured ON order_metadata(is_featured) WHERE is_featured = TRUE;
CREATE INDEX IF NOT EXISTS idx_order_metadata_show_in_summary ON order_metadata(show_in_summary) WHERE show_in_summary = TRUE;

-- Data source and tracking
CREATE INDEX IF NOT EXISTS idx_order_metadata_data_source ON order_metadata(data_source);
CREATE INDEX IF NOT EXISTS idx_order_metadata_source_reference ON order_metadata(source_reference);
CREATE INDEX IF NOT EXISTS idx_order_metadata_created_by ON order_metadata(created_by_user_id);
CREATE INDEX IF NOT EXISTS idx_order_metadata_updated_by ON order_metadata(updated_by_user_id);

-- Versioning
CREATE INDEX IF NOT EXISTS idx_order_metadata_version ON order_metadata(version DESC);

-- Performance and analytics
CREATE INDEX IF NOT EXISTS idx_order_metadata_access_count ON order_metadata(access_count DESC);
CREATE INDEX IF NOT EXISTS idx_order_metadata_last_accessed_at ON order_metadata(last_accessed_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_metadata_usage_frequency ON order_metadata(usage_frequency DESC);
CREATE INDEX IF NOT EXISTS idx_order_metadata_performance_impact ON order_metadata(performance_impact DESC);

-- SEO and marketing
CREATE INDEX IF NOT EXISTS idx_order_metadata_seo_weight ON order_metadata(seo_weight DESC);
CREATE INDEX IF NOT EXISTS idx_order_metadata_marketing_value ON order_metadata(marketing_value DESC);
CREATE INDEX IF NOT EXISTS idx_order_metadata_conversion_impact ON order_metadata(conversion_impact DESC);

-- Privacy and compliance
CREATE INDEX IF NOT EXISTS idx_order_metadata_privacy_level ON order_metadata(privacy_level);
CREATE INDEX IF NOT EXISTS idx_order_metadata_data_classification ON order_metadata(data_classification);
CREATE INDEX IF NOT EXISTS idx_order_metadata_retention_period ON order_metadata(retention_period_days);
CREATE INDEX IF NOT EXISTS idx_order_metadata_gdpr_category ON order_metadata(gdpr_category);

-- Auto-expiration
CREATE INDEX IF NOT EXISTS idx_order_metadata_expires_at ON order_metadata(expires_at) WHERE expires_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_order_metadata_auto_delete_after_days ON order_metadata(auto_delete_after_days) WHERE auto_delete_after_days IS NOT NULL;

-- Sync information
CREATE INDEX IF NOT EXISTS idx_order_metadata_sync_status ON order_metadata(sync_status);
CREATE INDEX IF NOT EXISTS idx_order_metadata_last_sync_at ON order_metadata(last_sync_at DESC);

-- Timestamps
CREATE INDEX IF NOT EXISTS idx_order_metadata_created_at ON order_metadata(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_metadata_updated_at ON order_metadata(updated_at DESC);

-- JSONB indexes
CREATE INDEX IF NOT EXISTS idx_order_metadata_validation_rules ON order_metadata USING gin(validation_rules);
CREATE INDEX IF NOT EXISTS idx_order_metadata_validation_errors ON order_metadata USING gin(validation_errors);
CREATE INDEX IF NOT EXISTS idx_order_metadata_localized_values ON order_metadata USING gin(localized_values);
CREATE INDEX IF NOT EXISTS idx_order_metadata_external_references ON order_metadata USING gin(external_references);
CREATE INDEX IF NOT EXISTS idx_order_metadata_custom_fields ON order_metadata USING gin(custom_fields);
CREATE INDEX IF NOT EXISTS idx_order_metadata_sync_errors ON order_metadata USING gin(sync_errors);

-- Text search indexes
CREATE INDEX IF NOT EXISTS idx_order_metadata_key_text ON order_metadata USING gin(to_tsvector('english', metadata_key));
CREATE INDEX IF NOT EXISTS idx_order_metadata_value_text ON order_metadata USING gin(to_tsvector('english', COALESCE(metadata_value, '')));
CREATE INDEX IF NOT EXISTS idx_order_metadata_display_name_text ON order_metadata USING gin(to_tsvector('english', COALESCE(display_name, '')));

-- Composite indexes
CREATE INDEX IF NOT EXISTS idx_order_metadata_order_key_lang ON order_metadata(order_id, metadata_key, language_code);
CREATE INDEX IF NOT EXISTS idx_order_metadata_store_key ON order_metadata(store_id, metadata_key);
CREATE INDEX IF NOT EXISTS idx_order_metadata_display ON order_metadata(display_group, display_order, is_featured DESC);
CREATE INDEX IF NOT EXISTS idx_order_metadata_performance ON order_metadata(performance_impact DESC, usage_frequency DESC, access_count DESC);
CREATE INDEX IF NOT EXISTS idx_order_metadata_marketing ON order_metadata(marketing_value DESC, seo_weight DESC, conversion_impact DESC);
CREATE INDEX IF NOT EXISTS idx_order_metadata_privacy ON order_metadata(privacy_level, data_classification, gdpr_category);

-- History table indexes
CREATE INDEX IF NOT EXISTS idx_order_metadata_history_metadata_id ON order_metadata_history(metadata_id);
CREATE INDEX IF NOT EXISTS idx_order_metadata_history_order_id ON order_metadata_history(order_id);
CREATE INDEX IF NOT EXISTS idx_order_metadata_history_store_id ON order_metadata_history(store_id);
CREATE INDEX IF NOT EXISTS idx_order_metadata_history_key ON order_metadata_history(metadata_key);
CREATE INDEX IF NOT EXISTS idx_order_metadata_history_change_type ON order_metadata_history(change_type);
CREATE INDEX IF NOT EXISTS idx_order_metadata_history_created_at ON order_metadata_history(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_metadata_history_changed_by ON order_metadata_history(changed_by_user_id);
CREATE INDEX IF NOT EXISTS idx_order_metadata_history_version ON order_metadata_history(version_after DESC);

-- Templates table indexes
CREATE INDEX IF NOT EXISTS idx_order_metadata_templates_store_id ON order_metadata_templates(store_id);
CREATE INDEX IF NOT EXISTS idx_order_metadata_templates_name ON order_metadata_templates(template_name);
CREATE INDEX IF NOT EXISTS idx_order_metadata_templates_category ON order_metadata_templates(template_category);
CREATE INDEX IF NOT EXISTS idx_order_metadata_templates_is_active ON order_metadata_templates(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_order_metadata_templates_is_system ON order_metadata_templates(is_system_template);
CREATE INDEX IF NOT EXISTS idx_order_metadata_templates_auto_apply ON order_metadata_templates(auto_apply) WHERE auto_apply = TRUE;
CREATE INDEX IF NOT EXISTS idx_order_metadata_templates_usage_count ON order_metadata_templates(usage_count DESC);
CREATE INDEX IF NOT EXISTS idx_order_metadata_templates_last_used_at ON order_metadata_templates(last_used_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_metadata_templates_created_at ON order_metadata_templates(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_metadata_templates_schema ON order_metadata_templates USING gin(metadata_schema);
CREATE INDEX IF NOT EXISTS idx_order_metadata_templates_default_values ON order_metadata_templates USING gin(default_values);
CREATE INDEX IF NOT EXISTS idx_order_metadata_templates_apply_conditions ON order_metadata_templates USING gin(apply_conditions);

-- =============================================================================
-- Triggers
-- =============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_order_metadata_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_order_metadata_updated_at
    BEFORE UPDATE ON order_metadata
    FOR EACH ROW
    EXECUTE FUNCTION update_order_metadata_updated_at();

CREATE TRIGGER trigger_update_order_metadata_templates_updated_at
    BEFORE UPDATE ON order_metadata_templates
    FOR EACH ROW
    EXECUTE FUNCTION update_order_metadata_updated_at();

-- Track metadata changes
CREATE OR REPLACE FUNCTION track_order_metadata_changes()
RETURNS TRIGGER AS $$
DECLARE
    change_type_val VARCHAR(20);
BEGIN
    IF TG_OP = 'INSERT' THEN
        change_type_val := 'created';
        INSERT INTO order_metadata_history (
            metadata_id, order_id, store_id, metadata_key,
            change_type, new_value, new_metadata_type,
            changed_by_user_id, change_source, version_after
        ) VALUES (
            NEW.id, NEW.order_id, NEW.store_id, NEW.metadata_key,
            change_type_val, NEW.metadata_value, NEW.metadata_type,
            NEW.created_by_user_id, 'system', NEW.version
        );
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        change_type_val := 'updated';
        
        -- Track value changes
        IF OLD.metadata_value IS DISTINCT FROM NEW.metadata_value THEN
            INSERT INTO order_metadata_history (
                metadata_id, order_id, store_id, metadata_key,
                change_type, old_value, new_value,
                old_metadata_type, new_metadata_type,
                changed_by_user_id, change_reason, change_source,
                version_before, version_after
            ) VALUES (
                NEW.id, NEW.order_id, NEW.store_id, NEW.metadata_key,
                change_type_val, OLD.metadata_value, NEW.metadata_value,
                OLD.metadata_type, NEW.metadata_type,
                NEW.updated_by_user_id, NEW.change_reason, 'system',
                OLD.version, NEW.version
            );
        END IF;
        
        -- Track validation status changes
        IF OLD.is_valid != NEW.is_valid THEN
            change_type_val := CASE WHEN NEW.is_valid THEN 'validated' ELSE 'invalidated' END;
            INSERT INTO order_metadata_history (
                metadata_id, order_id, store_id, metadata_key,
                change_type, old_value, new_value,
                changed_by_user_id, change_source, version_after
            ) VALUES (
                NEW.id, NEW.order_id, NEW.store_id, NEW.metadata_key,
                change_type_val, OLD.is_valid::text, NEW.is_valid::text,
                NEW.updated_by_user_id, 'system', NEW.version
            );
        END IF;
        
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO order_metadata_history (
            metadata_id, order_id, store_id, metadata_key,
            change_type, old_value, old_metadata_type, change_source
        ) VALUES (
            OLD.id, OLD.order_id, OLD.store_id, OLD.metadata_key,
            'deleted', OLD.metadata_value, OLD.metadata_type, 'system'
        );
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_track_order_metadata_changes
    AFTER INSERT OR UPDATE OR DELETE ON order_metadata
    FOR EACH ROW
    EXECUTE FUNCTION track_order_metadata_changes();

-- Validate metadata values
CREATE OR REPLACE FUNCTION validate_order_metadata_value()
RETURNS TRIGGER AS $$
DECLARE
    validation_errors JSONB := '[]'::jsonb;
    is_valid_value BOOLEAN := TRUE;
BEGIN
    -- Validate based on metadata type
    CASE NEW.metadata_type
        WHEN 'number' THEN
            IF NEW.metadata_value !~ '^-?\d+(\.\d+)?$' THEN
                validation_errors := validation_errors || '["Value must be a valid number"]'::jsonb;
                is_valid_value := FALSE;
            END IF;
        WHEN 'boolean' THEN
            IF LOWER(NEW.metadata_value) NOT IN ('true', 'false', '1', '0', 'yes', 'no') THEN
                validation_errors := validation_errors || '["Value must be a valid boolean"]'::jsonb;
                is_valid_value := FALSE;
            END IF;
        WHEN 'email' THEN
            IF NEW.metadata_value !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
                validation_errors := validation_errors || '["Value must be a valid email address"]'::jsonb;
                is_valid_value := FALSE;
            END IF;
        WHEN 'url' THEN
            IF NEW.metadata_value !~ '^https?://[^\s/$.?#].[^\s]*$' THEN
                validation_errors := validation_errors || '["Value must be a valid URL"]'::jsonb;
                is_valid_value := FALSE;
            END IF;
        WHEN 'phone' THEN
            IF NEW.metadata_value !~ '^[+]?[0-9\s\-\(\)]+$' THEN
                validation_errors := validation_errors || '["Value must be a valid phone number"]'::jsonb;
                is_valid_value := FALSE;
            END IF;
        WHEN 'date' THEN
            BEGIN
                PERFORM NEW.metadata_value::date;
            EXCEPTION WHEN OTHERS THEN
                validation_errors := validation_errors || '["Value must be a valid date"]'::jsonb;
                is_valid_value := FALSE;
            END;
        WHEN 'datetime' THEN
            BEGIN
                PERFORM NEW.metadata_value::timestamptz;
            EXCEPTION WHEN OTHERS THEN
                validation_errors := validation_errors || '["Value must be a valid datetime"]'::jsonb;
                is_valid_value := FALSE;
            END;
        WHEN 'json' THEN
            BEGIN
                PERFORM NEW.metadata_value::jsonb;
            EXCEPTION WHEN OTHERS THEN
                validation_errors := validation_errors || '["Value must be valid JSON"]'::jsonb;
                is_valid_value := FALSE;
            END;
    END CASE;
    
    -- Update validation status
    NEW.is_valid := is_valid_value;
    NEW.validation_errors := validation_errors;
    NEW.last_validated_at := CURRENT_TIMESTAMP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validate_order_metadata_value
    BEFORE INSERT OR UPDATE ON order_metadata
    FOR EACH ROW
    EXECUTE FUNCTION validate_order_metadata_value();

-- Auto-expire metadata
CREATE OR REPLACE FUNCTION auto_expire_order_metadata()
RETURNS TRIGGER AS $$
BEGIN
    -- Delete expired metadata
    DELETE FROM order_metadata 
    WHERE expires_at <= CURRENT_TIMESTAMP;
    
    -- Delete metadata that has exceeded auto-delete period
    DELETE FROM order_metadata 
    WHERE auto_delete_after_days IS NOT NULL 
    AND created_at <= (CURRENT_TIMESTAMP - (auto_delete_after_days || ' days')::interval);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_expire_order_metadata
    AFTER INSERT OR UPDATE ON order_metadata
    FOR EACH STATEMENT
    EXECUTE FUNCTION auto_expire_order_metadata();

-- =============================================================================
-- Helper Functions
-- =============================================================================

/**
 * Get metadata for order
 * @param p_order_id UUID - Order ID
 * @param p_language_code VARCHAR - Language code (optional)
 * @return TABLE - Order metadata
 */
CREATE OR REPLACE FUNCTION get_order_metadata(
    p_order_id UUID,
    p_language_code VARCHAR DEFAULT 'en'
)
RETURNS TABLE (
    metadata_id UUID,
    metadata_key VARCHAR,
    metadata_value TEXT,
    metadata_type VARCHAR,
    display_name VARCHAR,
    display_group VARCHAR,
    is_featured BOOLEAN,
    is_public BOOLEAN,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        om.id as metadata_id,
        om.metadata_key,
        COALESCE(
            om.localized_values ->> p_language_code,
            om.metadata_value
        ) as metadata_value,
        om.metadata_type,
        om.display_name,
        om.display_group,
        om.is_featured,
        om.is_public,
        om.created_at
    FROM order_metadata om
    WHERE om.order_id = p_order_id
    AND (om.language_code = p_language_code OR om.language_code = 'en')
    AND om.is_valid = TRUE
    ORDER BY om.display_group, om.display_order, om.metadata_key;
END;
$$ LANGUAGE plpgsql;

/**
 * Set metadata for order
 * @param p_order_id UUID - Order ID
 * @param p_metadata_key VARCHAR - Metadata key
 * @param p_metadata_value TEXT - Metadata value
 * @param p_metadata_type VARCHAR - Metadata type
 * @param p_user_id UUID - User ID
 * @return UUID - Metadata ID
 */
CREATE OR REPLACE FUNCTION set_order_metadata(
    p_order_id UUID,
    p_metadata_key VARCHAR,
    p_metadata_value TEXT,
    p_metadata_type VARCHAR DEFAULT 'string',
    p_user_id UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    metadata_id UUID;
    order_record orders;
BEGIN
    -- Get order record
    SELECT * INTO order_record FROM orders WHERE id = p_order_id;
    
    IF order_record.id IS NULL THEN
        RAISE EXCEPTION 'Order not found';
    END IF;
    
    -- Check if metadata already exists
    SELECT id INTO metadata_id 
    FROM order_metadata 
    WHERE order_id = p_order_id AND metadata_key = p_metadata_key;
    
    IF metadata_id IS NOT NULL THEN
        -- Update existing metadata
        UPDATE order_metadata 
        SET 
            previous_value = metadata_value,
            metadata_value = p_metadata_value,
            metadata_type = p_metadata_type,
            updated_by_user_id = p_user_id,
            version = version + 1,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = metadata_id;
        
        RETURN metadata_id;
    END IF;
    
    -- Insert new metadata
    INSERT INTO order_metadata (
        order_id, store_id, metadata_key, metadata_value, metadata_type,
        created_by_user_id, updated_by_user_id
    ) VALUES (
        p_order_id, order_record.store_id, p_metadata_key, p_metadata_value, p_metadata_type,
        p_user_id, p_user_id
    ) RETURNING id INTO metadata_id;
    
    RETURN metadata_id;
END;
$$ LANGUAGE plpgsql;

/**
 * Search order metadata
 * @param p_store_id UUID - Store ID
 * @param p_search_term TEXT - Search term
 * @param p_metadata_type VARCHAR - Metadata type filter
 * @return TABLE - Search results
 */
CREATE OR REPLACE FUNCTION search_order_metadata(
    p_store_id UUID,
    p_search_term TEXT,
    p_metadata_type VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    order_id UUID,
    metadata_key VARCHAR,
    metadata_value TEXT,
    metadata_type VARCHAR,
    display_name VARCHAR,
    relevance_score REAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        om.order_id,
        om.metadata_key,
        om.metadata_value,
        om.metadata_type,
        om.display_name,
        (
            ts_rank(to_tsvector('english', COALESCE(om.metadata_key, '') || ' ' || COALESCE(om.metadata_value, '')), 
                    plainto_tsquery('english', p_search_term)) +
            CASE WHEN om.metadata_key ILIKE '%' || p_search_term || '%' THEN 0.5 ELSE 0 END +
            CASE WHEN om.metadata_value ILIKE '%' || p_search_term || '%' THEN 0.3 ELSE 0 END
        )::REAL as relevance_score
    FROM order_metadata om
    WHERE om.store_id = p_store_id
    AND om.is_searchable = TRUE
    AND om.is_valid = TRUE
    AND (
        to_tsvector('english', COALESCE(om.metadata_key, '') || ' ' || COALESCE(om.metadata_value, '')) @@ plainto_tsquery('english', p_search_term)
        OR om.metadata_key ILIKE '%' || p_search_term || '%'
        OR om.metadata_value ILIKE '%' || p_search_term || '%'
    )
    AND (p_metadata_type IS NULL OR om.metadata_type = p_metadata_type)
    ORDER BY relevance_score DESC, om.metadata_key;
END;
$$ LANGUAGE plpgsql;

/**
 * Apply metadata template to order
 * @param p_order_id UUID - Order ID
 * @param p_template_name VARCHAR - Template name
 * @param p_user_id UUID - User ID
 * @return INTEGER - Number of metadata entries created
 */
CREATE OR REPLACE FUNCTION apply_order_metadata_template(
    p_order_id UUID,
    p_template_name VARCHAR,
    p_user_id UUID DEFAULT NULL
)
RETURNS INTEGER AS $$
DECLARE
    template_record order_metadata_templates;
    order_record orders;
    metadata_entry RECORD;
    entries_created INTEGER := 0;
BEGIN
    -- Get order record
    SELECT * INTO order_record FROM orders WHERE id = p_order_id;
    
    IF order_record.id IS NULL THEN
        RAISE EXCEPTION 'Order not found';
    END IF;
    
    -- Get template
    SELECT * INTO template_record 
    FROM order_metadata_templates 
    WHERE store_id = order_record.store_id 
    AND template_name = p_template_name 
    AND is_active = TRUE;
    
    IF template_record.id IS NULL THEN
        RAISE EXCEPTION 'Template not found or inactive';
    END IF;
    
    -- Apply template metadata
    FOR metadata_entry IN
        SELECT 
            key as metadata_key,
            value as default_value
        FROM jsonb_each_text(template_record.default_values)
    LOOP
        -- Create metadata entry if it doesn't exist
        IF NOT EXISTS (
            SELECT 1 FROM order_metadata 
            WHERE order_id = p_order_id AND metadata_key = metadata_entry.metadata_key
        ) THEN
            PERFORM set_order_metadata(
                p_order_id,
                metadata_entry.metadata_key,
                metadata_entry.default_value,
                'string',
                p_user_id
            );
            
            entries_created := entries_created + 1;
        END IF;
    END LOOP;
    
    -- Update template usage
    UPDATE order_metadata_templates 
    SET 
        usage_count = usage_count + 1,
        last_used_at = CURRENT_TIMESTAMP
    WHERE id = template_record.id;
    
    RETURN entries_created;
END;
$$ LANGUAGE plpgsql;

/**
 * Get metadata statistics for store
 * @param p_store_id UUID - Store ID
 * @return JSONB - Metadata statistics
 */
CREATE OR REPLACE FUNCTION get_order_metadata_stats(
    p_store_id UUID
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_metadata_entries', COUNT(*),
        'unique_metadata_keys', COUNT(DISTINCT metadata_key),
        'valid_entries', COUNT(*) FILTER (WHERE is_valid = TRUE),
        'invalid_entries', COUNT(*) FILTER (WHERE is_valid = FALSE),
        'system_metadata', COUNT(*) FILTER (WHERE is_system_metadata = TRUE),
        'public_metadata', COUNT(*) FILTER (WHERE is_public = TRUE),
        'searchable_metadata', COUNT(*) FILTER (WHERE is_searchable = TRUE),
        'featured_metadata', COUNT(*) FILTER (WHERE is_featured = TRUE),
        'encrypted_metadata', COUNT(*) FILTER (WHERE is_encrypted = TRUE),
        'avg_access_count', AVG(access_count),
        'avg_usage_frequency', AVG(usage_frequency),
        'avg_performance_impact', AVG(performance_impact),
        'avg_seo_weight', AVG(seo_weight),
        'avg_marketing_value', AVG(marketing_value),
        'metadata_types', (
            SELECT jsonb_object_agg(metadata_type, type_count)
            FROM (
                SELECT metadata_type, COUNT(*) as type_count
                FROM order_metadata
                WHERE store_id = p_store_id
                GROUP BY metadata_type
            ) type_stats
        ),
        'data_sources', (
            SELECT jsonb_object_agg(data_source, source_count)
            FROM (
                SELECT data_source, COUNT(*) as source_count
                FROM order_metadata
                WHERE store_id = p_store_id
                GROUP BY data_source
            ) source_stats
        ),
        'privacy_levels', (
            SELECT jsonb_object_agg(privacy_level, level_count)
            FROM (
                SELECT privacy_level, COUNT(*) as level_count
                FROM order_metadata
                WHERE store_id = p_store_id
                GROUP BY privacy_level
            ) privacy_stats
        ),
        'top_metadata_keys', (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'metadata_key', metadata_key,
                    'usage_count', SUM(access_count),
                    'avg_performance_impact', AVG(performance_impact)
                )
            )
            FROM (
                SELECT 
                    metadata_key,
                    SUM(access_count) as total_access,
                    AVG(performance_impact) as avg_impact
                FROM order_metadata
                WHERE store_id = p_store_id
                GROUP BY metadata_key
                ORDER BY SUM(access_count) DESC, AVG(performance_impact) DESC
                LIMIT 10
            ) top_keys_stats
        )
    ) INTO result
    FROM order_metadata
    WHERE store_id = p_store_id;
    
    RETURN COALESCE(result, '{"error": "No metadata found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Comments
-- =============================================================================

COMMENT ON TABLE order_metadata IS 'Normalized metadata from orders.metadata JSONB column';
COMMENT ON TABLE order_metadata_history IS 'Track changes to order metadata';
COMMENT ON TABLE order_metadata_templates IS 'Templates for common metadata structures';

COMMENT ON COLUMN order_metadata.metadata_type IS 'Type of metadata value for validation';
COMMENT ON COLUMN order_metadata.privacy_level IS 'Privacy level for compliance and access control';
COMMENT ON COLUMN order_metadata.performance_impact IS 'Impact on system performance (0.00 to 1.00)';
COMMENT ON COLUMN order_metadata.retention_period_days IS 'Data retention period in days';

COMMENT ON FUNCTION get_order_metadata(UUID, VARCHAR) IS 'Get metadata for order with localization';
COMMENT ON FUNCTION set_order_metadata(UUID, VARCHAR, TEXT, VARCHAR, UUID) IS 'Set metadata for order';
COMMENT ON FUNCTION search_order_metadata(UUID, TEXT, VARCHAR) IS 'Search order metadata';
COMMENT ON FUNCTION apply_order_metadata_template(UUID, VARCHAR, UUID) IS 'Apply metadata template to order';
COMMENT ON FUNCTION get_order_metadata_stats(UUID) IS 'Get metadata statistics for store';