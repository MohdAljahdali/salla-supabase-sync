-- =============================================================================
-- Product Metadata Table
-- =============================================================================
-- This table stores product metadata separately from the main products table
-- Normalizes the 'metadata' JSONB column from products table

CREATE TABLE IF NOT EXISTS product_metadata (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Metadata key-value information
    meta_key VARCHAR(255) NOT NULL,
    meta_value TEXT,
    meta_type VARCHAR(50) DEFAULT 'string' CHECK (meta_type IN (
        'string', 'number', 'boolean', 'date', 'datetime', 'json', 'array', 'url', 'email', 'phone'
    )),
    
    -- Metadata properties
    is_public BOOLEAN DEFAULT TRUE,
    is_searchable BOOLEAN DEFAULT FALSE,
    is_filterable BOOLEAN DEFAULT FALSE,
    is_required BOOLEAN DEFAULT FALSE,
    
    -- Display and grouping
    display_name VARCHAR(255),
    description TEXT,
    group_name VARCHAR(100),
    sort_order INTEGER DEFAULT 0,
    
    -- Validation rules
    validation_rules JSONB DEFAULT '{}', -- {"min_length": 5, "max_length": 100, "pattern": "regex"}
    allowed_values JSONB DEFAULT '[]', -- For enum-like fields
    
    -- Localization
    language_code VARCHAR(5) DEFAULT 'en',
    is_translatable BOOLEAN DEFAULT FALSE,
    
    -- SEO and marketing
    affects_seo BOOLEAN DEFAULT FALSE,
    seo_weight DECIMAL(3,2) DEFAULT 1.0,
    
    -- Analytics and tracking
    track_changes BOOLEAN DEFAULT FALSE,
    usage_count INTEGER DEFAULT 0,
    last_used_at TIMESTAMPTZ,
    
    -- External references
    external_key VARCHAR(255),
    source_system VARCHAR(100),
    
    -- Sync information
    sync_status VARCHAR(20) DEFAULT 'synced' CHECK (sync_status IN ('pending', 'syncing', 'synced', 'error')),
    last_sync_at TIMESTAMPTZ,
    sync_errors JSONB DEFAULT '[]',
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT product_metadata_unique_key UNIQUE (product_id, meta_key, language_code),
    CONSTRAINT product_metadata_sort_order_check CHECK (sort_order >= 0),
    CONSTRAINT product_metadata_seo_weight_check CHECK (seo_weight >= 0 AND seo_weight <= 10)
);

-- =============================================================================
-- Product Metadata History Table
-- =============================================================================
-- This table tracks changes to metadata values for auditing

CREATE TABLE IF NOT EXISTS product_metadata_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    metadata_id UUID NOT NULL REFERENCES product_metadata(id) ON DELETE CASCADE,
    product_id UUID NOT NULL,
    
    -- Change information
    old_value TEXT,
    new_value TEXT,
    change_type VARCHAR(20) NOT NULL CHECK (change_type IN ('create', 'update', 'delete')),
    change_reason VARCHAR(255),
    
    -- Change context
    changed_by_user_id UUID,
    changed_by_system VARCHAR(100),
    ip_address INET,
    user_agent TEXT,
    
    -- Timestamps
    changed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- Product Metadata Templates Table
-- =============================================================================
-- This table stores reusable metadata templates for different product types

CREATE TABLE IF NOT EXISTS product_metadata_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Template information
    template_name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100),
    
    -- Template properties
    is_active BOOLEAN DEFAULT TRUE,
    is_default BOOLEAN DEFAULT FALSE,
    
    -- Template definition
    metadata_fields JSONB NOT NULL DEFAULT '[]', -- Array of field definitions
    
    -- Usage tracking
    usage_count INTEGER DEFAULT 0,
    last_used_at TIMESTAMPTZ,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT product_metadata_templates_unique_name UNIQUE (store_id, template_name)
);

-- =============================================================================
-- Indexes
-- =============================================================================

-- Product Metadata Indexes
CREATE INDEX IF NOT EXISTS idx_product_metadata_product_id ON product_metadata(product_id);
CREATE INDEX IF NOT EXISTS idx_product_metadata_store_id ON product_metadata(store_id);
CREATE INDEX IF NOT EXISTS idx_product_metadata_meta_key ON product_metadata(meta_key);
CREATE INDEX IF NOT EXISTS idx_product_metadata_external_key ON product_metadata(external_key);

-- Value and type indexes
CREATE INDEX IF NOT EXISTS idx_product_metadata_meta_type ON product_metadata(meta_type);
CREATE INDEX IF NOT EXISTS idx_product_metadata_meta_value ON product_metadata(meta_value);
CREATE INDEX IF NOT EXISTS idx_product_metadata_meta_value_text ON product_metadata USING gin(to_tsvector('english', meta_value));

-- Properties indexes
CREATE INDEX IF NOT EXISTS idx_product_metadata_is_public ON product_metadata(is_public);
CREATE INDEX IF NOT EXISTS idx_product_metadata_is_searchable ON product_metadata(is_searchable);
CREATE INDEX IF NOT EXISTS idx_product_metadata_is_filterable ON product_metadata(is_filterable);
CREATE INDEX IF NOT EXISTS idx_product_metadata_is_required ON product_metadata(is_required);

-- Display and grouping
CREATE INDEX IF NOT EXISTS idx_product_metadata_group_name ON product_metadata(group_name);
CREATE INDEX IF NOT EXISTS idx_product_metadata_sort_order ON product_metadata(sort_order);
CREATE INDEX IF NOT EXISTS idx_product_metadata_product_group_sort ON product_metadata(product_id, group_name, sort_order);

-- Localization indexes
CREATE INDEX IF NOT EXISTS idx_product_metadata_language_code ON product_metadata(language_code);
CREATE INDEX IF NOT EXISTS idx_product_metadata_is_translatable ON product_metadata(is_translatable);

-- SEO indexes
CREATE INDEX IF NOT EXISTS idx_product_metadata_affects_seo ON product_metadata(affects_seo);
CREATE INDEX IF NOT EXISTS idx_product_metadata_seo_weight ON product_metadata(seo_weight DESC);

-- Analytics indexes
CREATE INDEX IF NOT EXISTS idx_product_metadata_usage_count ON product_metadata(usage_count DESC);
CREATE INDEX IF NOT EXISTS idx_product_metadata_last_used_at ON product_metadata(last_used_at DESC);

-- Source and sync indexes
CREATE INDEX IF NOT EXISTS idx_product_metadata_source_system ON product_metadata(source_system);
CREATE INDEX IF NOT EXISTS idx_product_metadata_sync_status ON product_metadata(sync_status);
CREATE INDEX IF NOT EXISTS idx_product_metadata_last_sync_at ON product_metadata(last_sync_at);

-- JSONB indexes
CREATE INDEX IF NOT EXISTS idx_product_metadata_validation_rules ON product_metadata USING gin(validation_rules);
CREATE INDEX IF NOT EXISTS idx_product_metadata_allowed_values ON product_metadata USING gin(allowed_values);
CREATE INDEX IF NOT EXISTS idx_product_metadata_sync_errors ON product_metadata USING gin(sync_errors);

-- Composite indexes
CREATE INDEX IF NOT EXISTS idx_product_metadata_searchable ON product_metadata(product_id, is_searchable, meta_key) WHERE is_searchable = TRUE;
CREATE INDEX IF NOT EXISTS idx_product_metadata_filterable ON product_metadata(meta_key, meta_value, is_filterable) WHERE is_filterable = TRUE;
CREATE INDEX IF NOT EXISTS idx_product_metadata_public_lang ON product_metadata(product_id, is_public, language_code) WHERE is_public = TRUE;

-- Product Metadata History Indexes
CREATE INDEX IF NOT EXISTS idx_product_metadata_history_metadata_id ON product_metadata_history(metadata_id);
CREATE INDEX IF NOT EXISTS idx_product_metadata_history_product_id ON product_metadata_history(product_id);
CREATE INDEX IF NOT EXISTS idx_product_metadata_history_change_type ON product_metadata_history(change_type);
CREATE INDEX IF NOT EXISTS idx_product_metadata_history_changed_at ON product_metadata_history(changed_at DESC);
CREATE INDEX IF NOT EXISTS idx_product_metadata_history_changed_by_user ON product_metadata_history(changed_by_user_id);

-- Product Metadata Templates Indexes
CREATE INDEX IF NOT EXISTS idx_product_metadata_templates_store_id ON product_metadata_templates(store_id);
CREATE INDEX IF NOT EXISTS idx_product_metadata_templates_category ON product_metadata_templates(category);
CREATE INDEX IF NOT EXISTS idx_product_metadata_templates_is_active ON product_metadata_templates(is_active);
CREATE INDEX IF NOT EXISTS idx_product_metadata_templates_is_default ON product_metadata_templates(is_default);
CREATE INDEX IF NOT EXISTS idx_product_metadata_templates_usage_count ON product_metadata_templates(usage_count DESC);
CREATE INDEX IF NOT EXISTS idx_product_metadata_templates_metadata_fields ON product_metadata_templates USING gin(metadata_fields);

-- =============================================================================
-- Triggers
-- =============================================================================

-- Auto-update updated_at timestamp for metadata
CREATE OR REPLACE FUNCTION update_product_metadata_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_product_metadata_updated_at
    BEFORE UPDATE ON product_metadata
    FOR EACH ROW
    EXECUTE FUNCTION update_product_metadata_updated_at();

-- Auto-update updated_at timestamp for templates
CREATE OR REPLACE FUNCTION update_product_metadata_templates_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_product_metadata_templates_updated_at
    BEFORE UPDATE ON product_metadata_templates
    FOR EACH ROW
    EXECUTE FUNCTION update_product_metadata_templates_updated_at();

-- Track metadata changes in history
CREATE OR REPLACE FUNCTION track_metadata_changes()
RETURNS TRIGGER AS $$
BEGIN
    -- Only track if track_changes is enabled
    IF (TG_OP = 'UPDATE' AND NEW.track_changes = TRUE) OR 
       (TG_OP = 'INSERT' AND NEW.track_changes = TRUE) OR
       (TG_OP = 'DELETE' AND OLD.track_changes = TRUE) THEN
        
        INSERT INTO product_metadata_history (
            metadata_id,
            product_id,
            old_value,
            new_value,
            change_type,
            changed_by_system
        ) VALUES (
            COALESCE(NEW.id, OLD.id),
            COALESCE(NEW.product_id, OLD.product_id),
            CASE WHEN TG_OP = 'DELETE' THEN OLD.meta_value ELSE OLD.meta_value END,
            CASE WHEN TG_OP = 'INSERT' THEN NEW.meta_value ELSE NEW.meta_value END,
            CASE 
                WHEN TG_OP = 'INSERT' THEN 'create'
                WHEN TG_OP = 'UPDATE' THEN 'update'
                WHEN TG_OP = 'DELETE' THEN 'delete'
            END,
            'system'
        );
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_track_metadata_changes
    AFTER INSERT OR UPDATE OR DELETE ON product_metadata
    FOR EACH ROW
    EXECUTE FUNCTION track_metadata_changes();

-- Update usage statistics
CREATE OR REPLACE FUNCTION update_metadata_usage()
RETURNS TRIGGER AS $$
BEGIN
    -- Update usage count and last used timestamp
    NEW.usage_count = COALESCE(NEW.usage_count, 0) + 1;
    NEW.last_used_at = CURRENT_TIMESTAMP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- This trigger would be called manually when metadata is accessed/used
-- CREATE TRIGGER trigger_update_metadata_usage
--     BEFORE UPDATE ON product_metadata
--     FOR EACH ROW
--     WHEN (NEW.usage_count != OLD.usage_count)
--     EXECUTE FUNCTION update_metadata_usage();

-- =============================================================================
-- Helper Functions
-- =============================================================================

/**
 * Get all metadata for a specific product
 * @param p_product_id UUID - Product ID
 * @param p_language_code VARCHAR - Language code (optional)
 * @param p_public_only BOOLEAN - Whether to return only public metadata
 * @return TABLE - Product metadata
 */
CREATE OR REPLACE FUNCTION get_product_metadata(
    p_product_id UUID,
    p_language_code VARCHAR DEFAULT 'en',
    p_public_only BOOLEAN DEFAULT TRUE
)
RETURNS TABLE (
    meta_key VARCHAR,
    meta_value TEXT,
    meta_type VARCHAR,
    display_name VARCHAR,
    description TEXT,
    group_name VARCHAR,
    sort_order INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pm.meta_key,
        pm.meta_value,
        pm.meta_type,
        pm.display_name,
        pm.description,
        pm.group_name,
        pm.sort_order
    FROM product_metadata pm
    WHERE pm.product_id = p_product_id
      AND pm.language_code = p_language_code
      AND (NOT p_public_only OR pm.is_public = TRUE)
    ORDER BY pm.group_name NULLS LAST, pm.sort_order ASC, pm.meta_key ASC;
END;
$$ LANGUAGE plpgsql;

/**
 * Get metadata value by key
 * @param p_product_id UUID - Product ID
 * @param p_meta_key VARCHAR - Metadata key
 * @param p_language_code VARCHAR - Language code
 * @return TEXT - Metadata value
 */
CREATE OR REPLACE FUNCTION get_metadata_value(
    p_product_id UUID,
    p_meta_key VARCHAR,
    p_language_code VARCHAR DEFAULT 'en'
)
RETURNS TEXT AS $$
DECLARE
    meta_value TEXT;
BEGIN
    SELECT pm.meta_value INTO meta_value
    FROM product_metadata pm
    WHERE pm.product_id = p_product_id
      AND pm.meta_key = p_meta_key
      AND pm.language_code = p_language_code
    LIMIT 1;
    
    RETURN meta_value;
END;
$$ LANGUAGE plpgsql;

/**
 * Set metadata value
 * @param p_product_id UUID - Product ID
 * @param p_meta_key VARCHAR - Metadata key
 * @param p_meta_value TEXT - Metadata value
 * @param p_meta_type VARCHAR - Metadata type
 * @param p_language_code VARCHAR - Language code
 * @return BOOLEAN - Success status
 */
CREATE OR REPLACE FUNCTION set_metadata_value(
    p_product_id UUID,
    p_meta_key VARCHAR,
    p_meta_value TEXT,
    p_meta_type VARCHAR DEFAULT 'string',
    p_language_code VARCHAR DEFAULT 'en'
)
RETURNS BOOLEAN AS $$
DECLARE
    store_id_val UUID;
BEGIN
    -- Get store_id from product
    SELECT store_id INTO store_id_val
    FROM products
    WHERE id = p_product_id;
    
    IF store_id_val IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Insert or update metadata
    INSERT INTO product_metadata (
        product_id,
        store_id,
        meta_key,
        meta_value,
        meta_type,
        language_code
    ) VALUES (
        p_product_id,
        store_id_val,
        p_meta_key,
        p_meta_value,
        p_meta_type,
        p_language_code
    )
    ON CONFLICT (product_id, meta_key, language_code)
    DO UPDATE SET
        meta_value = EXCLUDED.meta_value,
        meta_type = EXCLUDED.meta_type,
        updated_at = CURRENT_TIMESTAMP;
    
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

/**
 * Search products by metadata
 * @param p_store_id UUID - Store ID
 * @param p_search_criteria JSONB - Search criteria {"key": "value", ...}
 * @param p_language_code VARCHAR - Language code
 * @return TABLE - Matching products
 */
CREATE OR REPLACE FUNCTION search_products_by_metadata(
    p_store_id UUID,
    p_search_criteria JSONB,
    p_language_code VARCHAR DEFAULT 'en'
)
RETURNS TABLE (
    product_id UUID,
    matching_metadata JSONB
) AS $$
DECLARE
    criteria_key TEXT;
    criteria_value TEXT;
BEGIN
    RETURN QUERY
    SELECT 
        pm.product_id,
        jsonb_object_agg(pm.meta_key, pm.meta_value) as matching_metadata
    FROM product_metadata pm
    WHERE pm.store_id = p_store_id
      AND pm.language_code = p_language_code
      AND pm.is_searchable = TRUE
      AND EXISTS (
          SELECT 1
          FROM jsonb_each_text(p_search_criteria) as criteria(key, value)
          WHERE pm.meta_key = criteria.key
            AND pm.meta_value ILIKE '%' || criteria.value || '%'
      )
    GROUP BY pm.product_id;
END;
$$ LANGUAGE plpgsql;

/**
 * Apply metadata template to product
 * @param p_product_id UUID - Product ID
 * @param p_template_id UUID - Template ID
 * @param p_overwrite BOOLEAN - Whether to overwrite existing metadata
 * @return BOOLEAN - Success status
 */
CREATE OR REPLACE FUNCTION apply_metadata_template(
    p_product_id UUID,
    p_template_id UUID,
    p_overwrite BOOLEAN DEFAULT FALSE
)
RETURNS BOOLEAN AS $$
DECLARE
    template_record RECORD;
    field_def JSONB;
    store_id_val UUID;
BEGIN
    -- Get template and store_id
    SELECT pmt.*, p.store_id INTO template_record
    FROM product_metadata_templates pmt
    JOIN products p ON p.id = p_product_id
    WHERE pmt.id = p_template_id;
    
    IF template_record IS NULL THEN
        RETURN FALSE;
    END IF;
    
    store_id_val := template_record.store_id;
    
    -- Apply each field from template
    FOR field_def IN SELECT * FROM jsonb_array_elements(template_record.metadata_fields)
    LOOP
        -- Insert metadata if it doesn't exist or if overwrite is enabled
        INSERT INTO product_metadata (
            product_id,
            store_id,
            meta_key,
            meta_value,
            meta_type,
            display_name,
            description,
            group_name,
            sort_order,
            is_public,
            is_searchable,
            is_filterable,
            is_required,
            validation_rules,
            allowed_values
        ) VALUES (
            p_product_id,
            store_id_val,
            field_def->>'key',
            field_def->>'default_value',
            COALESCE(field_def->>'type', 'string'),
            field_def->>'display_name',
            field_def->>'description',
            field_def->>'group',
            COALESCE((field_def->>'sort_order')::INTEGER, 0),
            COALESCE((field_def->>'is_public')::BOOLEAN, TRUE),
            COALESCE((field_def->>'is_searchable')::BOOLEAN, FALSE),
            COALESCE((field_def->>'is_filterable')::BOOLEAN, FALSE),
            COALESCE((field_def->>'is_required')::BOOLEAN, FALSE),
            COALESCE(field_def->'validation_rules', '{}'),
            COALESCE(field_def->'allowed_values', '[]')
        )
        ON CONFLICT (product_id, meta_key, language_code)
        DO UPDATE SET
            meta_value = CASE WHEN p_overwrite THEN EXCLUDED.meta_value ELSE product_metadata.meta_value END,
            meta_type = CASE WHEN p_overwrite THEN EXCLUDED.meta_type ELSE product_metadata.meta_type END,
            display_name = CASE WHEN p_overwrite THEN EXCLUDED.display_name ELSE product_metadata.display_name END,
            updated_at = CURRENT_TIMESTAMP
        WHERE p_overwrite OR product_metadata.meta_value IS NULL;
    END LOOP;
    
    -- Update template usage
    UPDATE product_metadata_templates
    SET usage_count = usage_count + 1,
        last_used_at = CURRENT_TIMESTAMP
    WHERE id = p_template_id;
    
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

/**
 * Get metadata statistics for a product
 * @param p_product_id UUID - Product ID
 * @return JSONB - Metadata statistics
 */
CREATE OR REPLACE FUNCTION get_product_metadata_stats(
    p_product_id UUID
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_metadata', COUNT(*),
        'public_metadata', COUNT(*) FILTER (WHERE is_public = TRUE),
        'searchable_metadata', COUNT(*) FILTER (WHERE is_searchable = TRUE),
        'filterable_metadata', COUNT(*) FILTER (WHERE is_filterable = TRUE),
        'required_metadata', COUNT(*) FILTER (WHERE is_required = TRUE),
        'translatable_metadata', COUNT(*) FILTER (WHERE is_translatable = TRUE),
        'seo_affecting_metadata', COUNT(*) FILTER (WHERE affects_seo = TRUE),
        'languages', array_agg(DISTINCT language_code),
        'groups', array_agg(DISTINCT group_name) FILTER (WHERE group_name IS NOT NULL),
        'types_distribution', (
            SELECT jsonb_object_agg(meta_type, type_count)
            FROM (
                SELECT meta_type, COUNT(*) as type_count
                FROM product_metadata
                WHERE product_id = p_product_id
                GROUP BY meta_type
            ) type_stats
        ),
        'total_usage', COALESCE(SUM(usage_count), 0),
        'last_used', MAX(last_used_at)
    ) INTO result
    FROM product_metadata
    WHERE product_id = p_product_id;
    
    RETURN COALESCE(result, '{"error": "No metadata found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Comments
-- =============================================================================

COMMENT ON TABLE product_metadata IS 'Normalized table for product metadata, extracted from products.metadata JSONB column';
COMMENT ON TABLE product_metadata_history IS 'Audit trail for metadata changes';
COMMENT ON TABLE product_metadata_templates IS 'Reusable metadata templates for different product types';

COMMENT ON COLUMN product_metadata.meta_key IS 'Unique key for the metadata field';
COMMENT ON COLUMN product_metadata.meta_type IS 'Data type of the metadata value';
COMMENT ON COLUMN product_metadata.is_searchable IS 'Whether this metadata can be used in search queries';
COMMENT ON COLUMN product_metadata.is_filterable IS 'Whether this metadata can be used as a filter';
COMMENT ON COLUMN product_metadata.validation_rules IS 'JSON object containing validation rules';
COMMENT ON COLUMN product_metadata.seo_weight IS 'Weight of this metadata for SEO purposes (1-10)';

COMMENT ON FUNCTION get_product_metadata(UUID, VARCHAR, BOOLEAN) IS 'Get all metadata for a product with language and visibility filters';
COMMENT ON FUNCTION set_metadata_value(UUID, VARCHAR, TEXT, VARCHAR, VARCHAR) IS 'Set or update a metadata value for a product';
COMMENT ON FUNCTION search_products_by_metadata(UUID, JSONB, VARCHAR) IS 'Search products by metadata criteria';
COMMENT ON FUNCTION apply_metadata_template(UUID, UUID, BOOLEAN) IS 'Apply a metadata template to a product';
COMMENT ON FUNCTION get_product_metadata_stats(UUID) IS 'Get comprehensive statistics for product metadata';