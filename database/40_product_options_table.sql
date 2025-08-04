-- =============================================================================
-- Product Options Table
-- =============================================================================
-- This table stores product options separately from the main products table
-- Normalizes the 'options' JSONB column from products table

CREATE TABLE IF NOT EXISTS product_options (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Option basic information
    name VARCHAR(255) NOT NULL,
    display_name VARCHAR(255),
    description TEXT,
    
    -- Option type and behavior
    option_type VARCHAR(50) NOT NULL CHECK (option_type IN (
        'text', 'textarea', 'number', 'select', 'radio', 'checkbox', 
        'color', 'image', 'file', 'date', 'datetime', 'time',
        'range', 'email', 'url', 'phone'
    )),
    input_type VARCHAR(50) DEFAULT 'text',
    
    -- Option properties
    is_required BOOLEAN DEFAULT FALSE,
    is_multiple BOOLEAN DEFAULT FALSE,
    is_global BOOLEAN DEFAULT FALSE, -- Can be used across multiple products
    
    -- Display and ordering
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    is_visible BOOLEAN DEFAULT TRUE,
    
    -- Validation rules
    min_length INTEGER,
    max_length INTEGER,
    min_value DECIMAL(15,4),
    max_value DECIMAL(15,4),
    pattern VARCHAR(500), -- Regex pattern for validation
    allowed_extensions TEXT[], -- For file uploads
    max_file_size BIGINT, -- In bytes
    
    -- Pricing impact
    price_modifier_type VARCHAR(20) DEFAULT 'none' CHECK (price_modifier_type IN ('none', 'fixed', 'percentage')),
    price_modifier DECIMAL(15,4) DEFAULT 0,
    weight_modifier DECIMAL(10,3) DEFAULT 0,
    
    -- Inventory impact
    affects_inventory BOOLEAN DEFAULT FALSE,
    inventory_tracking VARCHAR(20) DEFAULT 'none' CHECK (inventory_tracking IN ('none', 'option', 'variant')),
    
    -- Display customization
    placeholder_text VARCHAR(255),
    help_text TEXT,
    error_message VARCHAR(255),
    css_class VARCHAR(100),
    
    -- Conditional logic
    depends_on_option_id UUID REFERENCES product_options(id),
    depends_on_value TEXT,
    conditional_logic JSONB DEFAULT '{}',
    
    -- SEO and metadata
    slug VARCHAR(255),
    meta_title VARCHAR(255),
    meta_description TEXT,
    
    -- External references
    salla_option_id VARCHAR(100),
    external_id VARCHAR(100),
    
    -- Analytics
    selection_count INTEGER DEFAULT 0,
    conversion_impact DECIMAL(5,4) DEFAULT 0,
    
    -- Sync information
    sync_status VARCHAR(20) DEFAULT 'synced' CHECK (sync_status IN ('pending', 'syncing', 'synced', 'error')),
    last_sync_at TIMESTAMPTZ,
    sync_errors JSONB DEFAULT '[]',
    
    -- Custom attributes
    custom_attributes JSONB DEFAULT '{}',
    tags JSONB DEFAULT '[]',
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT product_options_sort_order_check CHECK (sort_order >= 0),
    CONSTRAINT product_options_length_check CHECK (min_length IS NULL OR max_length IS NULL OR min_length <= max_length),
    CONSTRAINT product_options_value_check CHECK (min_value IS NULL OR max_value IS NULL OR min_value <= max_value),
    CONSTRAINT product_options_price_modifier_check CHECK (price_modifier_type = 'none' OR price_modifier IS NOT NULL),
    CONSTRAINT product_options_file_size_check CHECK (max_file_size IS NULL OR max_file_size > 0)
);

-- =============================================================================
-- Product Option Values Table
-- =============================================================================
-- This table stores predefined values for select/radio/checkbox options

CREATE TABLE IF NOT EXISTS product_option_values (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    option_id UUID NOT NULL REFERENCES product_options(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Value information
    value VARCHAR(500) NOT NULL,
    display_value VARCHAR(500),
    description TEXT,
    
    -- Value properties
    is_default BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    sort_order INTEGER DEFAULT 0,
    
    -- Visual representation
    color_code VARCHAR(7), -- Hex color code
    image_url TEXT,
    icon VARCHAR(100),
    
    -- Pricing impact
    price_modifier_type VARCHAR(20) DEFAULT 'none' CHECK (price_modifier_type IN ('none', 'fixed', 'percentage')),
    price_modifier DECIMAL(15,4) DEFAULT 0,
    weight_modifier DECIMAL(10,3) DEFAULT 0,
    
    -- Inventory
    sku_suffix VARCHAR(50),
    stock_quantity INTEGER DEFAULT 0,
    low_stock_threshold INTEGER DEFAULT 0,
    
    -- External references
    salla_value_id VARCHAR(100),
    external_id VARCHAR(100),
    
    -- Analytics
    selection_count INTEGER DEFAULT 0,
    conversion_rate DECIMAL(5,4) DEFAULT 0,
    
    -- Custom attributes
    custom_attributes JSONB DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT product_option_values_sort_order_check CHECK (sort_order >= 0),
    CONSTRAINT product_option_values_stock_check CHECK (stock_quantity >= 0),
    CONSTRAINT product_option_values_color_check CHECK (color_code IS NULL OR color_code ~ '^#[0-9A-Fa-f]{6}$')
);

-- =============================================================================
-- Indexes
-- =============================================================================

-- Product Options Indexes
CREATE INDEX IF NOT EXISTS idx_product_options_product_id ON product_options(product_id);
CREATE INDEX IF NOT EXISTS idx_product_options_store_id ON product_options(store_id);
CREATE INDEX IF NOT EXISTS idx_product_options_salla_option_id ON product_options(salla_option_id);
CREATE INDEX IF NOT EXISTS idx_product_options_slug ON product_options(slug);

-- Status and filtering indexes
CREATE INDEX IF NOT EXISTS idx_product_options_is_active ON product_options(is_active);
CREATE INDEX IF NOT EXISTS idx_product_options_is_required ON product_options(is_required);
CREATE INDEX IF NOT EXISTS idx_product_options_option_type ON product_options(option_type);
CREATE INDEX IF NOT EXISTS idx_product_options_is_global ON product_options(is_global);

-- Sorting and ordering
CREATE INDEX IF NOT EXISTS idx_product_options_sort_order ON product_options(sort_order);
CREATE INDEX IF NOT EXISTS idx_product_options_product_sort ON product_options(product_id, sort_order);

-- Dependencies
CREATE INDEX IF NOT EXISTS idx_product_options_depends_on ON product_options(depends_on_option_id);

-- Sync indexes
CREATE INDEX IF NOT EXISTS idx_product_options_sync_status ON product_options(sync_status);
CREATE INDEX IF NOT EXISTS idx_product_options_last_sync_at ON product_options(last_sync_at);

-- JSONB indexes
CREATE INDEX IF NOT EXISTS idx_product_options_conditional_logic ON product_options USING gin(conditional_logic);
CREATE INDEX IF NOT EXISTS idx_product_options_custom_attributes ON product_options USING gin(custom_attributes);
CREATE INDEX IF NOT EXISTS idx_product_options_tags ON product_options USING gin(tags);
CREATE INDEX IF NOT EXISTS idx_product_options_sync_errors ON product_options USING gin(sync_errors);

-- Product Option Values Indexes
CREATE INDEX IF NOT EXISTS idx_product_option_values_option_id ON product_option_values(option_id);
CREATE INDEX IF NOT EXISTS idx_product_option_values_store_id ON product_option_values(store_id);
CREATE INDEX IF NOT EXISTS idx_product_option_values_salla_value_id ON product_option_values(salla_value_id);

-- Status and filtering
CREATE INDEX IF NOT EXISTS idx_product_option_values_is_active ON product_option_values(is_active);
CREATE INDEX IF NOT EXISTS idx_product_option_values_is_default ON product_option_values(is_default);

-- Sorting
CREATE INDEX IF NOT EXISTS idx_product_option_values_sort_order ON product_option_values(sort_order);
CREATE INDEX IF NOT EXISTS idx_product_option_values_option_sort ON product_option_values(option_id, sort_order);

-- Analytics
CREATE INDEX IF NOT EXISTS idx_product_option_values_selection_count ON product_option_values(selection_count DESC);
CREATE INDEX IF NOT EXISTS idx_product_option_values_conversion_rate ON product_option_values(conversion_rate DESC);

-- JSONB indexes
CREATE INDEX IF NOT EXISTS idx_product_option_values_custom_attributes ON product_option_values USING gin(custom_attributes);

-- Composite indexes
CREATE INDEX IF NOT EXISTS idx_product_options_active_sort ON product_options(product_id, is_active, sort_order) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_product_option_values_active_sort ON product_option_values(option_id, is_active, sort_order) WHERE is_active = TRUE;

-- =============================================================================
-- Triggers
-- =============================================================================

-- Auto-update updated_at timestamp for options
CREATE OR REPLACE FUNCTION update_product_options_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_product_options_updated_at
    BEFORE UPDATE ON product_options
    FOR EACH ROW
    EXECUTE FUNCTION update_product_options_updated_at();

-- Auto-update updated_at timestamp for option values
CREATE OR REPLACE FUNCTION update_product_option_values_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_product_option_values_updated_at
    BEFORE UPDATE ON product_option_values
    FOR EACH ROW
    EXECUTE FUNCTION update_product_option_values_updated_at();

-- Generate slug for options
CREATE OR REPLACE FUNCTION generate_option_slug()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.slug IS NULL OR NEW.slug = '' THEN
        NEW.slug = lower(regexp_replace(NEW.name, '[^a-zA-Z0-9]+', '-', 'g'));
        NEW.slug = trim(both '-' from NEW.slug);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_generate_option_slug
    BEFORE INSERT OR UPDATE ON product_options
    FOR EACH ROW
    EXECUTE FUNCTION generate_option_slug();

-- Validate option dependencies
CREATE OR REPLACE FUNCTION validate_option_dependencies()
RETURNS TRIGGER AS $$
BEGIN
    -- Prevent circular dependencies
    IF NEW.depends_on_option_id IS NOT NULL THEN
        IF NEW.depends_on_option_id = NEW.id THEN
            RAISE EXCEPTION 'Option cannot depend on itself';
        END IF;
        
        -- Check if the dependency exists and belongs to the same product
        IF NOT EXISTS (
            SELECT 1 FROM product_options 
            WHERE id = NEW.depends_on_option_id 
            AND product_id = NEW.product_id
        ) THEN
            RAISE EXCEPTION 'Dependency option must belong to the same product';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validate_option_dependencies
    BEFORE INSERT OR UPDATE ON product_options
    FOR EACH ROW
    EXECUTE FUNCTION validate_option_dependencies();

-- =============================================================================
-- Helper Functions
-- =============================================================================

/**
 * Get all options for a specific product
 * @param p_product_id UUID - Product ID
 * @param p_active_only BOOLEAN - Whether to return only active options
 * @return TABLE - Product options with their values
 */
CREATE OR REPLACE FUNCTION get_product_options(
    p_product_id UUID,
    p_active_only BOOLEAN DEFAULT TRUE
)
RETURNS TABLE (
    option_id UUID,
    option_name VARCHAR,
    display_name VARCHAR,
    option_type VARCHAR,
    is_required BOOLEAN,
    sort_order INTEGER,
    values JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        po.id,
        po.name,
        po.display_name,
        po.option_type,
        po.is_required,
        po.sort_order,
        COALESCE(
            jsonb_agg(
                jsonb_build_object(
                    'id', pov.id,
                    'value', pov.value,
                    'display_value', pov.display_value,
                    'is_default', pov.is_default,
                    'price_modifier_type', pov.price_modifier_type,
                    'price_modifier', pov.price_modifier,
                    'color_code', pov.color_code,
                    'image_url', pov.image_url,
                    'sort_order', pov.sort_order
                ) ORDER BY pov.sort_order, pov.created_at
            ) FILTER (WHERE pov.id IS NOT NULL),
            '[]'::jsonb
        ) as values
    FROM product_options po
    LEFT JOIN product_option_values pov ON po.id = pov.option_id 
        AND (NOT p_active_only OR pov.is_active = TRUE)
    WHERE po.product_id = p_product_id
      AND (NOT p_active_only OR po.is_active = TRUE)
    GROUP BY po.id, po.name, po.display_name, po.option_type, po.is_required, po.sort_order
    ORDER BY po.sort_order, po.created_at;
END;
$$ LANGUAGE plpgsql;

/**
 * Get option by slug
 * @param p_product_id UUID - Product ID
 * @param p_slug VARCHAR - Option slug
 * @return TABLE - Option details
 */
CREATE OR REPLACE FUNCTION get_option_by_slug(
    p_product_id UUID,
    p_slug VARCHAR
)
RETURNS TABLE (
    option_id UUID,
    option_name VARCHAR,
    display_name VARCHAR,
    option_type VARCHAR,
    is_required BOOLEAN,
    validation_rules JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        po.id,
        po.name,
        po.display_name,
        po.option_type,
        po.is_required,
        jsonb_build_object(
            'min_length', po.min_length,
            'max_length', po.max_length,
            'min_value', po.min_value,
            'max_value', po.max_value,
            'pattern', po.pattern,
            'allowed_extensions', po.allowed_extensions,
            'max_file_size', po.max_file_size
        ) as validation_rules
    FROM product_options po
    WHERE po.product_id = p_product_id
      AND po.slug = p_slug
      AND po.is_active = TRUE
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

/**
 * Calculate option price impact
 * @param p_option_selections JSONB - Array of {"option_id": "uuid", "value_id": "uuid"}
 * @return DECIMAL - Total price modifier
 */
CREATE OR REPLACE FUNCTION calculate_options_price_impact(
    p_option_selections JSONB
)
RETURNS DECIMAL(15,4) AS $$
DECLARE
    total_modifier DECIMAL(15,4) := 0;
    selection JSONB;
    option_modifier DECIMAL(15,4);
    value_modifier DECIMAL(15,4);
BEGIN
    FOR selection IN SELECT * FROM jsonb_array_elements(p_option_selections)
    LOOP
        -- Get option-level price modifier
        SELECT 
            CASE 
                WHEN price_modifier_type = 'fixed' THEN price_modifier
                ELSE 0
            END
        INTO option_modifier
        FROM product_options
        WHERE id = (selection->>'option_id')::UUID;
        
        -- Get value-level price modifier if value_id is provided
        IF selection ? 'value_id' THEN
            SELECT 
                CASE 
                    WHEN price_modifier_type = 'fixed' THEN price_modifier
                    ELSE 0
                END
            INTO value_modifier
            FROM product_option_values
            WHERE id = (selection->>'value_id')::UUID;
        ELSE
            value_modifier := 0;
        END IF;
        
        total_modifier := total_modifier + COALESCE(option_modifier, 0) + COALESCE(value_modifier, 0);
    END LOOP;
    
    RETURN total_modifier;
END;
$$ LANGUAGE plpgsql;

/**
 * Get option statistics
 * @param p_product_id UUID - Product ID
 * @return JSONB - Option statistics
 */
CREATE OR REPLACE FUNCTION get_product_option_stats(
    p_product_id UUID
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_options', COUNT(*),
        'active_options', COUNT(*) FILTER (WHERE is_active = TRUE),
        'required_options', COUNT(*) FILTER (WHERE is_required = TRUE),
        'global_options', COUNT(*) FILTER (WHERE is_global = TRUE),
        'options_with_dependencies', COUNT(*) FILTER (WHERE depends_on_option_id IS NOT NULL),
        'total_selections', COALESCE(SUM(selection_count), 0),
        'average_conversion_impact', AVG(conversion_impact) FILTER (WHERE conversion_impact > 0),
        'option_types', (
            SELECT jsonb_object_agg(option_type, type_count)
            FROM (
                SELECT option_type, COUNT(*) as type_count
                FROM product_options
                WHERE product_id = p_product_id
                GROUP BY option_type
            ) type_stats
        ),
        'total_option_values', (
            SELECT COUNT(*)
            FROM product_option_values pov
            JOIN product_options po ON pov.option_id = po.id
            WHERE po.product_id = p_product_id
        )
    ) INTO result
    FROM product_options
    WHERE product_id = p_product_id;
    
    RETURN COALESCE(result, '{"error": "No options found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Comments
-- =============================================================================

COMMENT ON TABLE product_options IS 'Normalized table for product options, extracted from products.options JSONB column';
COMMENT ON TABLE product_option_values IS 'Predefined values for select/radio/checkbox type options';

COMMENT ON COLUMN product_options.option_type IS 'Type of input control (text, select, radio, etc.)';
COMMENT ON COLUMN product_options.is_global IS 'Whether this option can be reused across multiple products';
COMMENT ON COLUMN product_options.price_modifier_type IS 'How this option affects product price';
COMMENT ON COLUMN product_options.depends_on_option_id IS 'Option dependency for conditional display';
COMMENT ON COLUMN product_options.conditional_logic IS 'Complex conditional rules in JSON format';

COMMENT ON COLUMN product_option_values.color_code IS 'Hex color code for color swatches';
COMMENT ON COLUMN product_option_values.sku_suffix IS 'SKU suffix when this value is selected';

COMMENT ON FUNCTION get_product_options(UUID, BOOLEAN) IS 'Get all options for a product with their values';
COMMENT ON FUNCTION calculate_options_price_impact(JSONB) IS 'Calculate total price impact of selected options';
COMMENT ON FUNCTION get_product_option_stats(UUID) IS 'Get comprehensive statistics for product options';