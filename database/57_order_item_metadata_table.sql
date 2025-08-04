-- =============================================================================
-- Order Item Metadata Table
-- =============================================================================
-- This table normalizes the 'metadata' JSONB column from the order_items table
-- Stores metadata information for order items

CREATE TABLE IF NOT EXISTS order_item_metadata (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_item_id UUID NOT NULL REFERENCES order_items(id) ON DELETE CASCADE,
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Metadata identification
    metadata_key VARCHAR(100) NOT NULL,
    metadata_value TEXT,
    metadata_type VARCHAR(50) DEFAULT 'string' CHECK (metadata_type IN (
        'string', 'number', 'boolean', 'date', 'datetime', 'json', 'array', 'object', 'url', 'email', 'phone'
    )),
    
    -- Metadata properties
    metadata_group VARCHAR(100),
    metadata_category VARCHAR(100),
    metadata_subcategory VARCHAR(100),
    display_order INTEGER DEFAULT 0,
    
    -- Validation
    validation_rules JSONB DEFAULT '{}',
    is_valid BOOLEAN DEFAULT TRUE,
    validation_errors JSONB DEFAULT '[]',
    last_validated_at TIMESTAMPTZ,
    
    -- Localization
    language_code VARCHAR(5) DEFAULT 'en',
    localized_keys JSONB DEFAULT '{}', -- {"ar": "الوصف", "en": "Description"}
    localized_values JSONB DEFAULT '{}', -- {"ar": "قيمة", "en": "Value"}
    
    -- Display properties
    display_name VARCHAR(255),
    display_value TEXT,
    display_format VARCHAR(50), -- 'text', 'html', 'markdown', 'json'
    display_icon VARCHAR(50),
    display_color VARCHAR(7), -- Hex color code
    is_visible BOOLEAN DEFAULT TRUE,
    is_editable BOOLEAN DEFAULT TRUE,
    
    -- Data source and tracking
    data_source VARCHAR(50) DEFAULT 'manual' CHECK (data_source IN (
        'manual', 'system', 'import', 'api', 'webhook', 'calculated', 'inherited'
    )),
    source_reference VARCHAR(255),
    source_system VARCHAR(100),
    
    -- Versioning
    version INTEGER DEFAULT 1,
    previous_value TEXT,
    change_reason VARCHAR(255),
    changed_by_user_id UUID,
    
    -- Performance tracking
    access_count INTEGER DEFAULT 0,
    last_accessed_at TIMESTAMPTZ,
    update_frequency INTEGER DEFAULT 0, -- Updates per month
    
    -- SEO and marketing
    seo_weight DECIMAL(3,2) DEFAULT 0.00,
    marketing_tags JSONB DEFAULT '[]',
    search_keywords JSONB DEFAULT '[]',
    
    -- Privacy and security
    is_sensitive BOOLEAN DEFAULT FALSE,
    privacy_level VARCHAR(20) DEFAULT 'public' CHECK (privacy_level IN (
        'public', 'internal', 'restricted', 'confidential', 'secret'
    )),
    encryption_status VARCHAR(20) DEFAULT 'none' CHECK (encryption_status IN (
        'none', 'encrypted', 'hashed', 'masked'
    )),
    
    -- Auto-expiration
    expires_at TIMESTAMPTZ,
    auto_delete_expired BOOLEAN DEFAULT FALSE,
    expiration_action VARCHAR(20) DEFAULT 'none' CHECK (expiration_action IN (
        'none', 'delete', 'archive', 'anonymize', 'notify'
    )),
    
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
    UNIQUE(order_item_id, metadata_key, language_code)
);

-- =============================================================================
-- Order Item Metadata History Table
-- =============================================================================
-- Track changes to order item metadata

CREATE TABLE IF NOT EXISTS order_item_metadata_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    metadata_id UUID REFERENCES order_item_metadata(id) ON DELETE SET NULL,
    order_item_id UUID NOT NULL REFERENCES order_items(id) ON DELETE CASCADE,
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
-- Order Item Metadata Templates Table
-- =============================================================================
-- Define templates for common metadata patterns

CREATE TABLE IF NOT EXISTS order_item_metadata_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Template identification
    template_name VARCHAR(100) NOT NULL,
    template_description TEXT,
    template_category VARCHAR(100),
    
    -- Template structure
    metadata_schema JSONB NOT NULL DEFAULT '{}',
    default_values JSONB DEFAULT '{}',
    validation_rules JSONB DEFAULT '{}',
    
    -- Template properties
    is_active BOOLEAN DEFAULT TRUE,
    is_system_template BOOLEAN DEFAULT FALSE,
    applies_to_all_items BOOLEAN DEFAULT FALSE,
    item_filters JSONB DEFAULT '{}',
    
    -- Usage tracking
    usage_count INTEGER DEFAULT 0,
    last_used_at TIMESTAMPTZ,
    
    -- Validation and testing
    validation_status VARCHAR(20) DEFAULT 'valid' CHECK (validation_status IN (
        'valid', 'invalid', 'testing', 'disabled'
    )),
    last_validated_at TIMESTAMPTZ,
    
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
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_order_item_id ON order_item_metadata(order_item_id);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_order_id ON order_item_metadata(order_id);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_store_id ON order_item_metadata(store_id);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_metadata_key ON order_item_metadata(metadata_key);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_metadata_type ON order_item_metadata(metadata_type);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_external_metadata_id ON order_item_metadata(external_metadata_id);

-- Metadata properties
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_metadata_group ON order_item_metadata(metadata_group);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_metadata_category ON order_item_metadata(metadata_category);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_metadata_subcategory ON order_item_metadata(metadata_subcategory);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_display_order ON order_item_metadata(display_order);

-- Validation
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_is_valid ON order_item_metadata(is_valid);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_last_validated_at ON order_item_metadata(last_validated_at DESC);

-- Localization
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_language_code ON order_item_metadata(language_code);

-- Display properties
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_display_name ON order_item_metadata(display_name);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_display_format ON order_item_metadata(display_format);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_is_visible ON order_item_metadata(is_visible) WHERE is_visible = TRUE;
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_is_editable ON order_item_metadata(is_editable) WHERE is_editable = TRUE;

-- Data source
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_data_source ON order_item_metadata(data_source);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_source_reference ON order_item_metadata(source_reference);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_source_system ON order_item_metadata(source_system);

-- Versioning
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_version ON order_item_metadata(version DESC);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_changed_by ON order_item_metadata(changed_by_user_id);

-- Performance tracking
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_access_count ON order_item_metadata(access_count DESC);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_last_accessed_at ON order_item_metadata(last_accessed_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_update_frequency ON order_item_metadata(update_frequency DESC);

-- SEO and marketing
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_seo_weight ON order_item_metadata(seo_weight DESC);

-- Privacy and security
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_is_sensitive ON order_item_metadata(is_sensitive) WHERE is_sensitive = TRUE;
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_privacy_level ON order_item_metadata(privacy_level);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_encryption_status ON order_item_metadata(encryption_status);

-- Auto-expiration
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_expires_at ON order_item_metadata(expires_at) WHERE expires_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_auto_delete_expired ON order_item_metadata(auto_delete_expired) WHERE auto_delete_expired = TRUE;
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_expiration_action ON order_item_metadata(expiration_action);

-- Sync information
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_sync_status ON order_item_metadata(sync_status);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_last_sync_at ON order_item_metadata(last_sync_at DESC);

-- Timestamps
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_created_at ON order_item_metadata(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_updated_at ON order_item_metadata(updated_at DESC);

-- JSONB indexes
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_validation_rules ON order_item_metadata USING gin(validation_rules);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_validation_errors ON order_item_metadata USING gin(validation_errors);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_localized_keys ON order_item_metadata USING gin(localized_keys);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_localized_values ON order_item_metadata USING gin(localized_values);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_marketing_tags ON order_item_metadata USING gin(marketing_tags);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_search_keywords ON order_item_metadata USING gin(search_keywords);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_external_references ON order_item_metadata USING gin(external_references);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_custom_fields ON order_item_metadata USING gin(custom_fields);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_sync_errors ON order_item_metadata USING gin(sync_errors);

-- Text search indexes
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_key_text ON order_item_metadata USING gin(to_tsvector('english', metadata_key));
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_value_text ON order_item_metadata USING gin(to_tsvector('english', COALESCE(metadata_value, '')));
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_display_name_text ON order_item_metadata USING gin(to_tsvector('english', COALESCE(display_name, '')));
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_display_value_text ON order_item_metadata USING gin(to_tsvector('english', COALESCE(display_value, '')));

-- Composite indexes
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_item_key_lang ON order_item_metadata(order_item_id, metadata_key, language_code);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_order_key ON order_item_metadata(order_id, metadata_key);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_store_key ON order_item_metadata(store_id, metadata_key);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_group_category ON order_item_metadata(metadata_group, metadata_category, metadata_subcategory);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_type_source ON order_item_metadata(metadata_type, data_source);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_visible_editable ON order_item_metadata(is_visible, is_editable);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_privacy_encryption ON order_item_metadata(privacy_level, encryption_status);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_expiration ON order_item_metadata(expires_at, auto_delete_expired, expiration_action) WHERE expires_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_performance ON order_item_metadata(access_count DESC, update_frequency DESC, last_accessed_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_seo_marketing ON order_item_metadata(seo_weight DESC, metadata_type) WHERE seo_weight > 0;

-- History table indexes
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_history_metadata_id ON order_item_metadata_history(metadata_id);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_history_order_item_id ON order_item_metadata_history(order_item_id);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_history_order_id ON order_item_metadata_history(order_id);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_history_store_id ON order_item_metadata_history(store_id);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_history_metadata_key ON order_item_metadata_history(metadata_key);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_history_change_type ON order_item_metadata_history(change_type);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_history_created_at ON order_item_metadata_history(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_history_changed_by ON order_item_metadata_history(changed_by_user_id);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_history_version ON order_item_metadata_history(version_before, version_after);

-- Templates table indexes
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_templates_store_id ON order_item_metadata_templates(store_id);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_templates_template_name ON order_item_metadata_templates(template_name);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_templates_template_category ON order_item_metadata_templates(template_category);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_templates_is_active ON order_item_metadata_templates(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_templates_is_system ON order_item_metadata_templates(is_system_template) WHERE is_system_template = TRUE;
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_templates_applies_to_all ON order_item_metadata_templates(applies_to_all_items) WHERE applies_to_all_items = TRUE;
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_templates_usage_count ON order_item_metadata_templates(usage_count DESC);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_templates_validation_status ON order_item_metadata_templates(validation_status);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_templates_created_at ON order_item_metadata_templates(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_templates_metadata_schema ON order_item_metadata_templates USING gin(metadata_schema);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_templates_default_values ON order_item_metadata_templates USING gin(default_values);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_templates_validation_rules ON order_item_metadata_templates USING gin(validation_rules);
CREATE INDEX IF NOT EXISTS idx_order_item_metadata_templates_item_filters ON order_item_metadata_templates USING gin(item_filters);

-- =============================================================================
-- Triggers
-- =============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_order_item_metadata_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_order_item_metadata_updated_at
    BEFORE UPDATE ON order_item_metadata
    FOR EACH ROW
    EXECUTE FUNCTION update_order_item_metadata_updated_at();

CREATE TRIGGER trigger_update_order_item_metadata_templates_updated_at
    BEFORE UPDATE ON order_item_metadata_templates
    FOR EACH ROW
    EXECUTE FUNCTION update_order_item_metadata_updated_at();

-- Track metadata changes
CREATE OR REPLACE FUNCTION track_order_item_metadata_changes()
RETURNS TRIGGER AS $$
DECLARE
    change_type_val VARCHAR(20);
BEGIN
    IF TG_OP = 'INSERT' THEN
        change_type_val := 'created';
        INSERT INTO order_item_metadata_history (
            metadata_id, order_item_id, order_id, store_id, metadata_key,
            change_type, new_value, new_metadata_type, version_after, change_source
        ) VALUES (
            NEW.id, NEW.order_item_id, NEW.order_id, NEW.store_id, NEW.metadata_key,
            change_type_val, NEW.metadata_value, NEW.metadata_type, NEW.version, 'system'
        );
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        change_type_val := 'updated';
        
        -- Track value changes
        IF OLD.metadata_value IS DISTINCT FROM NEW.metadata_value OR 
           OLD.metadata_type IS DISTINCT FROM NEW.metadata_type THEN
            INSERT INTO order_item_metadata_history (
                metadata_id, order_item_id, order_id, store_id, metadata_key,
                change_type, old_value, new_value,
                old_metadata_type, new_metadata_type,
                version_before, version_after,
                changed_by_user_id, change_reason, change_source
            ) VALUES (
                NEW.id, NEW.order_item_id, NEW.order_id, NEW.store_id, NEW.metadata_key,
                change_type_val, OLD.metadata_value, NEW.metadata_value,
                OLD.metadata_type, NEW.metadata_type,
                OLD.version, NEW.version,
                NEW.changed_by_user_id, NEW.change_reason, 'system'
            );
        END IF;
        
        -- Track validation status changes
        IF OLD.is_valid != NEW.is_valid THEN
            change_type_val := CASE WHEN NEW.is_valid THEN 'validated' ELSE 'invalidated' END;
            INSERT INTO order_item_metadata_history (
                metadata_id, order_item_id, order_id, store_id, metadata_key,
                change_type, old_value, new_value, change_source
            ) VALUES (
                NEW.id, NEW.order_item_id, NEW.order_id, NEW.store_id, NEW.metadata_key,
                change_type_val, OLD.is_valid::text, NEW.is_valid::text, 'system'
            );
        END IF;
        
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO order_item_metadata_history (
            metadata_id, order_item_id, order_id, store_id, metadata_key,
            change_type, old_value, old_metadata_type, version_before, change_source
        ) VALUES (
            OLD.id, OLD.order_item_id, OLD.order_id, OLD.store_id, OLD.metadata_key,
            'deleted', OLD.metadata_value, OLD.metadata_type, OLD.version, 'system'
        );
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_track_order_item_metadata_changes
    AFTER INSERT OR UPDATE OR DELETE ON order_item_metadata
    FOR EACH ROW
    EXECUTE FUNCTION track_order_item_metadata_changes();

-- Validate metadata values
CREATE OR REPLACE FUNCTION validate_order_item_metadata_value()
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
        WHEN 'url' THEN
            IF NEW.metadata_value !~ '^https?://[^\s/$.?#].[^\s]*$' THEN
                validation_errors := validation_errors || '["Value must be a valid URL"]'::jsonb;
                is_valid_value := FALSE;
            END IF;
        WHEN 'email' THEN
            IF NEW.metadata_value !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
                validation_errors := validation_errors || '["Value must be a valid email address"]'::jsonb;
                is_valid_value := FALSE;
            END IF;
    END CASE;
    
    -- Validate display color if provided
    IF NEW.display_color IS NOT NULL AND NEW.display_color !~ '^#[0-9A-Fa-f]{6}$' THEN
        validation_errors := validation_errors || '["Display color must be a valid hex color code"]'::jsonb;
        is_valid_value := FALSE;
    END IF;
    
    -- Update validation status
    NEW.is_valid := is_valid_value;
    NEW.validation_errors := validation_errors;
    NEW.last_validated_at := CURRENT_TIMESTAMP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validate_order_item_metadata_value
    BEFORE INSERT OR UPDATE ON order_item_metadata
    FOR EACH ROW
    EXECUTE FUNCTION validate_order_item_metadata_value();

-- Auto-expire metadata
CREATE OR REPLACE FUNCTION auto_expire_order_item_metadata()
RETURNS INTEGER AS $$
DECLARE
    expired_count INTEGER := 0;
    metadata_record order_item_metadata;
BEGIN
    FOR metadata_record IN
        SELECT *
        FROM order_item_metadata
        WHERE expires_at IS NOT NULL
        AND expires_at <= CURRENT_TIMESTAMP
        AND auto_delete_expired = TRUE
    LOOP
        CASE metadata_record.expiration_action
            WHEN 'delete' THEN
                DELETE FROM order_item_metadata WHERE id = metadata_record.id;
            WHEN 'archive' THEN
                UPDATE order_item_metadata
                SET is_visible = FALSE, data_source = 'archived'
                WHERE id = metadata_record.id;
            WHEN 'anonymize' THEN
                UPDATE order_item_metadata
                SET metadata_value = '[EXPIRED]', is_sensitive = FALSE
                WHERE id = metadata_record.id;
        END CASE;
        
        expired_count := expired_count + 1;
    END LOOP;
    
    RETURN expired_count;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Helper Functions
-- =============================================================================

/**
 * Get metadata for order item
 * @param p_order_item_id UUID - Order item ID
 * @param p_language_code VARCHAR - Language code (optional)
 * @return TABLE - Order item metadata
 */
CREATE OR REPLACE FUNCTION get_order_item_metadata(
    p_order_item_id UUID,
    p_language_code VARCHAR DEFAULT 'en'
)
RETURNS TABLE (
    metadata_id UUID,
    metadata_key VARCHAR,
    metadata_value TEXT,
    metadata_type VARCHAR,
    display_name VARCHAR,
    display_value TEXT,
    is_visible BOOLEAN,
    is_editable BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        oim.id as metadata_id,
        oim.metadata_key,
        oim.metadata_value,
        oim.metadata_type,
        COALESCE(
            oim.localized_keys ->> p_language_code,
            oim.display_name,
            oim.metadata_key
        ) as display_name,
        COALESCE(
            oim.localized_values ->> p_language_code,
            oim.display_value,
            oim.metadata_value
        ) as display_value,
        oim.is_visible,
        oim.is_editable
    FROM order_item_metadata oim
    WHERE oim.order_item_id = p_order_item_id
    AND (oim.language_code = p_language_code OR oim.language_code = 'en')
    AND oim.is_valid = TRUE
    AND (oim.expires_at IS NULL OR oim.expires_at > CURRENT_TIMESTAMP)
    ORDER BY oim.metadata_group, oim.display_order, oim.metadata_key;
END;
$$ LANGUAGE plpgsql;

/**
 * Set metadata for order item
 * @param p_order_item_id UUID - Order item ID
 * @param p_metadata_key VARCHAR - Metadata key
 * @param p_metadata_value TEXT - Metadata value
 * @param p_metadata_type VARCHAR - Metadata type (optional)
 * @param p_language_code VARCHAR - Language code (optional)
 * @return UUID - Metadata ID
 */
CREATE OR REPLACE FUNCTION set_order_item_metadata(
    p_order_item_id UUID,
    p_metadata_key VARCHAR,
    p_metadata_value TEXT,
    p_metadata_type VARCHAR DEFAULT 'string',
    p_language_code VARCHAR DEFAULT 'en'
)
RETURNS UUID AS $$
DECLARE
    metadata_id UUID;
    order_item_record order_items;
BEGIN
    -- Get order item record
    SELECT * INTO order_item_record FROM order_items WHERE id = p_order_item_id;
    
    IF order_item_record.id IS NULL THEN
        RAISE EXCEPTION 'Order item not found';
    END IF;
    
    -- Insert or update metadata
    INSERT INTO order_item_metadata (
        order_item_id, order_id, store_id, metadata_key, metadata_value,
        metadata_type, language_code, data_source
    ) VALUES (
        p_order_item_id, order_item_record.order_id, order_item_record.store_id,
        p_metadata_key, p_metadata_value, p_metadata_type, p_language_code, 'manual'
    )
    ON CONFLICT (order_item_id, metadata_key, language_code)
    DO UPDATE SET
        metadata_value = EXCLUDED.metadata_value,
        metadata_type = EXCLUDED.metadata_type,
        version = order_item_metadata.version + 1,
        previous_value = order_item_metadata.metadata_value,
        updated_at = CURRENT_TIMESTAMP
    RETURNING id INTO metadata_id;
    
    RETURN metadata_id;
END;
$$ LANGUAGE plpgsql;

/**
 * Search order item metadata
 * @param p_store_id UUID - Store ID
 * @param p_search_term TEXT - Search term
 * @param p_metadata_type VARCHAR - Metadata type filter (optional)
 * @param p_language_code VARCHAR - Language code (optional)
 * @return TABLE - Search results
 */
CREATE OR REPLACE FUNCTION search_order_item_metadata(
    p_store_id UUID,
    p_search_term TEXT,
    p_metadata_type VARCHAR DEFAULT NULL,
    p_language_code VARCHAR DEFAULT 'en'
)
RETURNS TABLE (
    metadata_id UUID,
    order_item_id UUID,
    order_id UUID,
    metadata_key VARCHAR,
    metadata_value TEXT,
    display_name VARCHAR,
    relevance_score REAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        oim.id as metadata_id,
        oim.order_item_id,
        oim.order_id,
        oim.metadata_key,
        oim.metadata_value,
        COALESCE(
            oim.localized_keys ->> p_language_code,
            oim.display_name,
            oim.metadata_key
        ) as display_name,
        (
            ts_rank(to_tsvector('english', oim.metadata_key), plainto_tsquery('english', p_search_term)) +
            ts_rank(to_tsvector('english', COALESCE(oim.metadata_value, '')), plainto_tsquery('english', p_search_term)) +
            ts_rank(to_tsvector('english', COALESCE(oim.display_name, '')), plainto_tsquery('english', p_search_term))
        ) as relevance_score
    FROM order_item_metadata oim
    WHERE oim.store_id = p_store_id
    AND oim.is_valid = TRUE
    AND oim.is_visible = TRUE
    AND (oim.expires_at IS NULL OR oim.expires_at > CURRENT_TIMESTAMP)
    AND (p_metadata_type IS NULL OR oim.metadata_type = p_metadata_type)
    AND (
        to_tsvector('english', oim.metadata_key) @@ plainto_tsquery('english', p_search_term) OR
        to_tsvector('english', COALESCE(oim.metadata_value, '')) @@ plainto_tsquery('english', p_search_term) OR
        to_tsvector('english', COALESCE(oim.display_name, '')) @@ plainto_tsquery('english', p_search_term)
    )
    ORDER BY relevance_score DESC, oim.access_count DESC
    LIMIT 100;
END;
$$ LANGUAGE plpgsql;

/**
 * Apply metadata template to order item
 * @param p_order_item_id UUID - Order item ID
 * @param p_template_name VARCHAR - Template name
 * @return INTEGER - Number of metadata entries created
 */
CREATE OR REPLACE FUNCTION apply_order_item_metadata_template(
    p_order_item_id UUID,
    p_template_name VARCHAR
)
RETURNS INTEGER AS $$
DECLARE
    order_item_record order_items;
    template_record order_item_metadata_templates;
    schema_key TEXT;
    schema_value JSONB;
    entries_created INTEGER := 0;
BEGIN
    -- Get order item record
    SELECT * INTO order_item_record FROM order_items WHERE id = p_order_item_id;
    
    IF order_item_record.id IS NULL THEN
        RAISE EXCEPTION 'Order item not found';
    END IF;
    
    -- Get template
    SELECT * INTO template_record
    FROM order_item_metadata_templates
    WHERE store_id = order_item_record.store_id
    AND template_name = p_template_name
    AND is_active = TRUE;
    
    IF template_record.id IS NULL THEN
        RAISE EXCEPTION 'Template not found or inactive';
    END IF;
    
    -- Apply template schema
    FOR schema_key, schema_value IN
        SELECT * FROM jsonb_each(template_record.metadata_schema)
    LOOP
        INSERT INTO order_item_metadata (
            order_item_id, order_id, store_id, metadata_key,
            metadata_value, metadata_type, data_source
        ) VALUES (
            p_order_item_id, order_item_record.order_id, order_item_record.store_id,
            schema_key,
            COALESCE(
                template_record.default_values ->> schema_key,
                schema_value ->> 'default',
                ''
            ),
            COALESCE(schema_value ->> 'type', 'string'),
            'template'
        )
        ON CONFLICT (order_item_id, metadata_key, language_code) DO NOTHING;
        
        entries_created := entries_created + 1;
    END LOOP;
    
    -- Update template usage
    UPDATE order_item_metadata_templates
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
CREATE OR REPLACE FUNCTION get_order_item_metadata_stats(
    p_store_id UUID
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_metadata', COUNT(*),
        'unique_keys', COUNT(DISTINCT metadata_key),
        'valid_metadata', COUNT(*) FILTER (WHERE is_valid = TRUE),
        'invalid_metadata', COUNT(*) FILTER (WHERE is_valid = FALSE),
        'visible_metadata', COUNT(*) FILTER (WHERE is_visible = TRUE),
        'editable_metadata', COUNT(*) FILTER (WHERE is_editable = TRUE),
        'sensitive_metadata', COUNT(*) FILTER (WHERE is_sensitive = TRUE),
        'expired_metadata', COUNT(*) FILTER (WHERE expires_at IS NOT NULL AND expires_at <= CURRENT_TIMESTAMP),
        'avg_access_count', AVG(access_count),
        'avg_update_frequency', AVG(update_frequency),
        'avg_seo_weight', AVG(seo_weight),
        'metadata_types', (
            SELECT jsonb_object_agg(metadata_type, type_count)
            FROM (
                SELECT metadata_type, COUNT(*) as type_count
                FROM order_item_metadata
                WHERE store_id = p_store_id
                GROUP BY metadata_type
            ) type_stats
        ),
        'data_sources', (
            SELECT jsonb_object_agg(data_source, source_count)
            FROM (
                SELECT data_source, COUNT(*) as source_count
                FROM order_item_metadata
                WHERE store_id = p_store_id
                GROUP BY data_source
            ) source_stats
        ),
        'privacy_levels', (
            SELECT jsonb_object_agg(privacy_level, privacy_count)
            FROM (
                SELECT privacy_level, COUNT(*) as privacy_count
                FROM order_item_metadata
                WHERE store_id = p_store_id
                GROUP BY privacy_level
            ) privacy_stats
        ),
        'top_metadata_keys', (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'metadata_key', metadata_key,
                    'usage_count', COUNT(*),
                    'avg_access_count', AVG(access_count),
                    'avg_seo_weight', AVG(seo_weight)
                )
            )
            FROM (
                SELECT 
                    metadata_key,
                    COUNT(*) as usage_count,
                    AVG(access_count) as avg_access,
                    AVG(seo_weight) as avg_seo
                FROM order_item_metadata
                WHERE store_id = p_store_id
                GROUP BY metadata_key
                ORDER BY COUNT(*) DESC, AVG(access_count) DESC
                LIMIT 10
            ) top_keys_stats
        )
    ) INTO result
    FROM order_item_metadata
    WHERE store_id = p_store_id;
    
    RETURN COALESCE(result, '{"error": "No metadata found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Comments
-- =============================================================================

COMMENT ON TABLE order_item_metadata IS 'Normalized metadata from order_items.metadata JSONB column';
COMMENT ON TABLE order_item_metadata_history IS 'Track changes to order item metadata';
COMMENT ON TABLE order_item_metadata_templates IS 'Templates for common metadata patterns';

COMMENT ON COLUMN order_item_metadata.metadata_type IS 'Type of metadata value for validation';
COMMENT ON COLUMN order_item_metadata.privacy_level IS 'Privacy level for data protection';
COMMENT ON COLUMN order_item_metadata.encryption_status IS 'Encryption status of the value';
COMMENT ON COLUMN order_item_metadata.seo_weight IS 'SEO importance weight (0-1)';

COMMENT ON FUNCTION get_order_item_metadata(UUID, VARCHAR) IS 'Get metadata for order item with localization';
COMMENT ON FUNCTION set_order_item_metadata(UUID, VARCHAR, TEXT, VARCHAR, VARCHAR) IS 'Set metadata for order item';
COMMENT ON FUNCTION search_order_item_metadata(UUID, TEXT, VARCHAR, VARCHAR) IS 'Search order item metadata';
COMMENT ON FUNCTION apply_order_item_metadata_template(UUID, VARCHAR) IS 'Apply metadata template to order item';
COMMENT ON FUNCTION get_order_item_metadata_stats(UUID) IS 'Get metadata statistics for store';