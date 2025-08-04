-- =============================================================================
-- Product Variants Table
-- =============================================================================
-- This table stores product variants separately from the main products table
-- Normalizes the 'variants' JSONB column from products table

CREATE TABLE IF NOT EXISTS product_variants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Variant identification
    sku VARCHAR(255) UNIQUE,
    barcode VARCHAR(255),
    variant_name VARCHAR(255),
    display_name VARCHAR(255),
    
    -- Pricing
    price DECIMAL(15,4) NOT NULL DEFAULT 0,
    compare_price DECIMAL(15,4), -- Original price for discount display
    cost_price DECIMAL(15,4), -- Cost to merchant
    
    -- Inventory
    quantity INTEGER DEFAULT 0,
    reserved_quantity INTEGER DEFAULT 0,
    available_quantity INTEGER GENERATED ALWAYS AS (quantity - reserved_quantity) STORED,
    low_stock_threshold INTEGER DEFAULT 0,
    track_inventory BOOLEAN DEFAULT TRUE,
    allow_backorder BOOLEAN DEFAULT FALSE,
    
    -- Physical properties
    weight DECIMAL(10,3), -- in kg
    length DECIMAL(10,2), -- in cm
    width DECIMAL(10,2), -- in cm
    height DECIMAL(10,2), -- in cm
    volume DECIMAL(15,6) GENERATED ALWAYS AS (length * width * height / 1000000) STORED, -- in cubic meters
    
    -- Variant status
    is_active BOOLEAN DEFAULT TRUE,
    is_default BOOLEAN DEFAULT FALSE,
    is_digital BOOLEAN DEFAULT FALSE,
    requires_shipping BOOLEAN DEFAULT TRUE,
    
    -- Variant attributes (option combinations)
    option_values JSONB DEFAULT '{}', -- {"color": "red", "size": "large"}
    
    -- Images specific to this variant
    image_url TEXT,
    image_alt TEXT,
    gallery_images JSONB DEFAULT '[]',
    
    -- SEO and marketing
    meta_title VARCHAR(255),
    meta_description TEXT,
    search_keywords TEXT[],
    
    -- Shipping
    shipping_class VARCHAR(100),
    shipping_weight DECIMAL(10,3),
    shipping_dimensions JSONB, -- {"length": 10, "width": 5, "height": 3}
    
    -- Tax and legal
    tax_class VARCHAR(100),
    harmonized_code VARCHAR(50), -- HS code for international shipping
    country_of_origin VARCHAR(2), -- ISO country code
    
    -- Supplier information
    supplier_id UUID,
    supplier_sku VARCHAR(255),
    supplier_cost DECIMAL(15,4),
    lead_time_days INTEGER,
    
    -- Analytics and performance
    view_count INTEGER DEFAULT 0,
    order_count INTEGER DEFAULT 0,
    revenue_total DECIMAL(15,4) DEFAULT 0,
    conversion_rate DECIMAL(5,4) DEFAULT 0,
    
    -- Inventory management
    reorder_point INTEGER DEFAULT 0,
    reorder_quantity INTEGER DEFAULT 0,
    max_stock_level INTEGER,
    abc_classification VARCHAR(1) CHECK (abc_classification IN ('A', 'B', 'C')),
    
    -- Quality and compliance
    quality_score DECIMAL(3,2),
    compliance_status VARCHAR(20) DEFAULT 'compliant' CHECK (compliance_status IN ('compliant', 'non_compliant', 'pending_review')),
    expiry_date DATE,
    batch_number VARCHAR(100),
    
    -- External references
    salla_variant_id VARCHAR(100),
    external_id VARCHAR(100),
    
    -- Sync information
    sync_status VARCHAR(20) DEFAULT 'synced' CHECK (sync_status IN ('pending', 'syncing', 'synced', 'error')),
    last_sync_at TIMESTAMPTZ,
    sync_errors JSONB DEFAULT '[]',
    
    -- Custom fields
    custom_fields JSONB DEFAULT '{}',
    tags JSONB DEFAULT '[]',
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT product_variants_price_check CHECK (price >= 0),
    CONSTRAINT product_variants_compare_price_check CHECK (compare_price IS NULL OR compare_price >= price),
    CONSTRAINT product_variants_cost_price_check CHECK (cost_price IS NULL OR cost_price >= 0),
    CONSTRAINT product_variants_quantity_check CHECK (quantity >= 0),
    CONSTRAINT product_variants_reserved_quantity_check CHECK (reserved_quantity >= 0 AND reserved_quantity <= quantity),
    CONSTRAINT product_variants_weight_check CHECK (weight IS NULL OR weight >= 0),
    CONSTRAINT product_variants_dimensions_check CHECK (
        (length IS NULL AND width IS NULL AND height IS NULL) OR
        (length > 0 AND width > 0 AND height > 0)
    ),
    CONSTRAINT product_variants_reorder_check CHECK (reorder_point >= 0 AND reorder_quantity >= 0),
    CONSTRAINT product_variants_quality_score_check CHECK (quality_score IS NULL OR (quality_score >= 0 AND quality_score <= 5))
);

-- =============================================================================
-- Product Variant Option Values Table
-- =============================================================================
-- This table links variants to their specific option value combinations

CREATE TABLE IF NOT EXISTS product_variant_option_values (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    variant_id UUID NOT NULL REFERENCES product_variants(id) ON DELETE CASCADE,
    option_id UUID NOT NULL REFERENCES product_options(id) ON DELETE CASCADE,
    option_value_id UUID REFERENCES product_option_values(id) ON DELETE CASCADE,
    custom_value TEXT, -- For text inputs or custom values
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT variant_option_values_unique UNIQUE (variant_id, option_id),
    CONSTRAINT variant_option_values_value_check CHECK (
        (option_value_id IS NOT NULL AND custom_value IS NULL) OR
        (option_value_id IS NULL AND custom_value IS NOT NULL)
    )
);

-- =============================================================================
-- Indexes
-- =============================================================================

-- Product Variants Indexes
CREATE INDEX IF NOT EXISTS idx_product_variants_product_id ON product_variants(product_id);
CREATE INDEX IF NOT EXISTS idx_product_variants_store_id ON product_variants(store_id);
CREATE INDEX IF NOT EXISTS idx_product_variants_sku ON product_variants(sku);
CREATE INDEX IF NOT EXISTS idx_product_variants_barcode ON product_variants(barcode);
CREATE INDEX IF NOT EXISTS idx_product_variants_salla_variant_id ON product_variants(salla_variant_id);

-- Status and filtering indexes
CREATE INDEX IF NOT EXISTS idx_product_variants_is_active ON product_variants(is_active);
CREATE INDEX IF NOT EXISTS idx_product_variants_is_default ON product_variants(is_default);
CREATE INDEX IF NOT EXISTS idx_product_variants_track_inventory ON product_variants(track_inventory);

-- Pricing indexes
CREATE INDEX IF NOT EXISTS idx_product_variants_price ON product_variants(price);
CREATE INDEX IF NOT EXISTS idx_product_variants_compare_price ON product_variants(compare_price);
CREATE INDEX IF NOT EXISTS idx_product_variants_cost_price ON product_variants(cost_price);

-- Inventory indexes
CREATE INDEX IF NOT EXISTS idx_product_variants_quantity ON product_variants(quantity);
CREATE INDEX IF NOT EXISTS idx_product_variants_available_quantity ON product_variants(available_quantity);
CREATE INDEX IF NOT EXISTS idx_product_variants_low_stock ON product_variants(low_stock_threshold) WHERE quantity <= low_stock_threshold;
CREATE INDEX IF NOT EXISTS idx_product_variants_reorder_point ON product_variants(reorder_point) WHERE quantity <= reorder_point;

-- Physical properties
CREATE INDEX IF NOT EXISTS idx_product_variants_weight ON product_variants(weight);
CREATE INDEX IF NOT EXISTS idx_product_variants_volume ON product_variants(volume);

-- Analytics indexes
CREATE INDEX IF NOT EXISTS idx_product_variants_view_count ON product_variants(view_count DESC);
CREATE INDEX IF NOT EXISTS idx_product_variants_order_count ON product_variants(order_count DESC);
CREATE INDEX IF NOT EXISTS idx_product_variants_revenue_total ON product_variants(revenue_total DESC);
CREATE INDEX IF NOT EXISTS idx_product_variants_conversion_rate ON product_variants(conversion_rate DESC);

-- Classification and compliance
CREATE INDEX IF NOT EXISTS idx_product_variants_abc_classification ON product_variants(abc_classification);
CREATE INDEX IF NOT EXISTS idx_product_variants_compliance_status ON product_variants(compliance_status);
CREATE INDEX IF NOT EXISTS idx_product_variants_expiry_date ON product_variants(expiry_date);

-- Supplier indexes
CREATE INDEX IF NOT EXISTS idx_product_variants_supplier_id ON product_variants(supplier_id);
CREATE INDEX IF NOT EXISTS idx_product_variants_supplier_sku ON product_variants(supplier_sku);

-- Sync indexes
CREATE INDEX IF NOT EXISTS idx_product_variants_sync_status ON product_variants(sync_status);
CREATE INDEX IF NOT EXISTS idx_product_variants_last_sync_at ON product_variants(last_sync_at);

-- JSONB indexes
CREATE INDEX IF NOT EXISTS idx_product_variants_option_values ON product_variants USING gin(option_values);
CREATE INDEX IF NOT EXISTS idx_product_variants_gallery_images ON product_variants USING gin(gallery_images);
CREATE INDEX IF NOT EXISTS idx_product_variants_shipping_dimensions ON product_variants USING gin(shipping_dimensions);
CREATE INDEX IF NOT EXISTS idx_product_variants_custom_fields ON product_variants USING gin(custom_fields);
CREATE INDEX IF NOT EXISTS idx_product_variants_tags ON product_variants USING gin(tags);
CREATE INDEX IF NOT EXISTS idx_product_variants_sync_errors ON product_variants USING gin(sync_errors);

-- Array indexes
CREATE INDEX IF NOT EXISTS idx_product_variants_search_keywords ON product_variants USING gin(search_keywords);

-- Composite indexes
CREATE INDEX IF NOT EXISTS idx_product_variants_product_active ON product_variants(product_id, is_active);
CREATE INDEX IF NOT EXISTS idx_product_variants_product_default ON product_variants(product_id, is_default) WHERE is_default = TRUE;
CREATE INDEX IF NOT EXISTS idx_product_variants_store_active ON product_variants(store_id, is_active, price);
CREATE INDEX IF NOT EXISTS idx_product_variants_inventory_status ON product_variants(track_inventory, quantity, low_stock_threshold);

-- Product Variant Option Values Indexes
CREATE INDEX IF NOT EXISTS idx_variant_option_values_variant_id ON product_variant_option_values(variant_id);
CREATE INDEX IF NOT EXISTS idx_variant_option_values_option_id ON product_variant_option_values(option_id);
CREATE INDEX IF NOT EXISTS idx_variant_option_values_option_value_id ON product_variant_option_values(option_value_id);

-- =============================================================================
-- Triggers
-- =============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_product_variants_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_product_variants_updated_at
    BEFORE UPDATE ON product_variants
    FOR EACH ROW
    EXECUTE FUNCTION update_product_variants_updated_at();

-- Ensure only one default variant per product
CREATE OR REPLACE FUNCTION ensure_single_default_variant()
RETURNS TRIGGER AS $$
BEGIN
    -- If setting this variant as default, unset all other default variants for this product
    IF NEW.is_default = TRUE THEN
        UPDATE product_variants 
        SET is_default = FALSE 
        WHERE product_id = NEW.product_id 
          AND id != NEW.id 
          AND is_default = TRUE;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_ensure_single_default_variant
    BEFORE INSERT OR UPDATE ON product_variants
    FOR EACH ROW
    EXECUTE FUNCTION ensure_single_default_variant();

-- Auto-calculate ABC classification based on revenue
CREATE OR REPLACE FUNCTION calculate_abc_classification()
RETURNS TRIGGER AS $$
DECLARE
    total_revenue DECIMAL(15,4);
    revenue_percentile DECIMAL(5,4);
BEGIN
    -- Calculate total revenue for all variants of this product
    SELECT SUM(revenue_total) INTO total_revenue
    FROM product_variants
    WHERE product_id = NEW.product_id;
    
    -- Calculate this variant's revenue percentile
    IF total_revenue > 0 THEN
        revenue_percentile = NEW.revenue_total / total_revenue;
        
        -- Assign ABC classification
        IF revenue_percentile >= 0.8 THEN
            NEW.abc_classification = 'A';
        ELSIF revenue_percentile >= 0.15 THEN
            NEW.abc_classification = 'B';
        ELSE
            NEW.abc_classification = 'C';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_calculate_abc_classification
    BEFORE INSERT OR UPDATE ON product_variants
    FOR EACH ROW
    WHEN (NEW.revenue_total IS NOT NULL)
    EXECUTE FUNCTION calculate_abc_classification();

-- Update conversion rate
CREATE OR REPLACE FUNCTION update_variant_conversion_rate()
RETURNS TRIGGER AS $$
BEGIN
    -- Calculate conversion rate
    IF NEW.view_count > 0 THEN
        NEW.conversion_rate = NEW.order_count::DECIMAL / NEW.view_count;
    ELSE
        NEW.conversion_rate = 0;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_variant_conversion_rate
    BEFORE INSERT OR UPDATE ON product_variants
    FOR EACH ROW
    WHEN (NEW.view_count IS NOT NULL OR NEW.order_count IS NOT NULL)
    EXECUTE FUNCTION update_variant_conversion_rate();

-- =============================================================================
-- Helper Functions
-- =============================================================================

/**
 * Get all variants for a specific product
 * @param p_product_id UUID - Product ID
 * @param p_active_only BOOLEAN - Whether to return only active variants
 * @return TABLE - Product variants with option combinations
 */
CREATE OR REPLACE FUNCTION get_product_variants(
    p_product_id UUID,
    p_active_only BOOLEAN DEFAULT TRUE
)
RETURNS TABLE (
    variant_id UUID,
    sku VARCHAR,
    variant_name VARCHAR,
    price DECIMAL,
    compare_price DECIMAL,
    quantity INTEGER,
    available_quantity INTEGER,
    is_default BOOLEAN,
    option_combinations JSONB,
    image_url TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pv.id,
        pv.sku,
        pv.variant_name,
        pv.price,
        pv.compare_price,
        pv.quantity,
        pv.available_quantity,
        pv.is_default,
        pv.option_values,
        pv.image_url
    FROM product_variants pv
    WHERE pv.product_id = p_product_id
      AND (NOT p_active_only OR pv.is_active = TRUE)
    ORDER BY pv.is_default DESC, pv.price ASC, pv.created_at ASC;
END;
$$ LANGUAGE plpgsql;

/**
 * Find variant by option combination
 * @param p_product_id UUID - Product ID
 * @param p_option_values JSONB - Option value combinations
 * @return UUID - Variant ID if found
 */
CREATE OR REPLACE FUNCTION find_variant_by_options(
    p_product_id UUID,
    p_option_values JSONB
)
RETURNS UUID AS $$
DECLARE
    variant_id UUID;
BEGIN
    SELECT id INTO variant_id
    FROM product_variants
    WHERE product_id = p_product_id
      AND option_values @> p_option_values
      AND p_option_values @> option_values
      AND is_active = TRUE
    LIMIT 1;
    
    RETURN variant_id;
END;
$$ LANGUAGE plpgsql;

/**
 * Get low stock variants
 * @param p_store_id UUID - Store ID (optional)
 * @return TABLE - Variants with low stock
 */
CREATE OR REPLACE FUNCTION get_low_stock_variants(
    p_store_id UUID DEFAULT NULL
)
RETURNS TABLE (
    variant_id UUID,
    product_id UUID,
    sku VARCHAR,
    variant_name VARCHAR,
    current_quantity INTEGER,
    low_stock_threshold INTEGER,
    reorder_point INTEGER,
    reorder_quantity INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pv.id,
        pv.product_id,
        pv.sku,
        pv.variant_name,
        pv.quantity,
        pv.low_stock_threshold,
        pv.reorder_point,
        pv.reorder_quantity
    FROM product_variants pv
    WHERE pv.track_inventory = TRUE
      AND pv.is_active = TRUE
      AND pv.quantity <= pv.low_stock_threshold
      AND (p_store_id IS NULL OR pv.store_id = p_store_id)
    ORDER BY (pv.quantity::DECIMAL / NULLIF(pv.low_stock_threshold, 0)) ASC;
END;
$$ LANGUAGE plpgsql;

/**
 * Update variant inventory
 * @param p_variant_id UUID - Variant ID
 * @param p_quantity_change INTEGER - Quantity change (positive or negative)
 * @param p_reason VARCHAR - Reason for inventory change
 * @return BOOLEAN - Success status
 */
CREATE OR REPLACE FUNCTION update_variant_inventory(
    p_variant_id UUID,
    p_quantity_change INTEGER,
    p_reason VARCHAR DEFAULT 'manual_adjustment'
)
RETURNS BOOLEAN AS $$
DECLARE
    current_quantity INTEGER;
    new_quantity INTEGER;
BEGIN
    -- Get current quantity
    SELECT quantity INTO current_quantity
    FROM product_variants
    WHERE id = p_variant_id;
    
    IF current_quantity IS NULL THEN
        RETURN FALSE;
    END IF;
    
    new_quantity := current_quantity + p_quantity_change;
    
    -- Ensure quantity doesn't go below 0
    IF new_quantity < 0 THEN
        new_quantity := 0;
    END IF;
    
    -- Update quantity
    UPDATE product_variants
    SET quantity = new_quantity,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_variant_id;
    
    -- TODO: Log inventory change in inventory_logs table
    
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

/**
 * Get variant performance statistics
 * @param p_variant_id UUID - Variant ID
 * @return JSONB - Performance statistics
 */
CREATE OR REPLACE FUNCTION get_variant_performance_stats(
    p_variant_id UUID
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'variant_id', id,
        'sku', sku,
        'view_count', view_count,
        'order_count', order_count,
        'conversion_rate', conversion_rate,
        'revenue_total', revenue_total,
        'average_order_value', CASE WHEN order_count > 0 THEN revenue_total / order_count ELSE 0 END,
        'inventory_status', CASE 
            WHEN NOT track_inventory THEN 'not_tracked'
            WHEN quantity <= 0 THEN 'out_of_stock'
            WHEN quantity <= low_stock_threshold THEN 'low_stock'
            WHEN quantity <= reorder_point THEN 'reorder_needed'
            ELSE 'in_stock'
        END,
        'inventory_turnover', CASE 
            WHEN quantity > 0 THEN order_count::DECIMAL / quantity 
            ELSE NULL 
        END,
        'abc_classification', abc_classification,
        'quality_score', quality_score,
        'compliance_status', compliance_status
    ) INTO result
    FROM product_variants
    WHERE id = p_variant_id;
    
    RETURN COALESCE(result, '{"error": "Variant not found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

/**
 * Get product variant summary
 * @param p_product_id UUID - Product ID
 * @return JSONB - Variant summary statistics
 */
CREATE OR REPLACE FUNCTION get_product_variant_summary(
    p_product_id UUID
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_variants', COUNT(*),
        'active_variants', COUNT(*) FILTER (WHERE is_active = TRUE),
        'in_stock_variants', COUNT(*) FILTER (WHERE quantity > 0),
        'low_stock_variants', COUNT(*) FILTER (WHERE quantity <= low_stock_threshold AND track_inventory = TRUE),
        'out_of_stock_variants', COUNT(*) FILTER (WHERE quantity = 0 AND track_inventory = TRUE),
        'price_range', jsonb_build_object(
            'min_price', MIN(price) FILTER (WHERE is_active = TRUE),
            'max_price', MAX(price) FILTER (WHERE is_active = TRUE),
            'average_price', AVG(price) FILTER (WHERE is_active = TRUE)
        ),
        'total_inventory_value', SUM(quantity * cost_price) FILTER (WHERE cost_price IS NOT NULL),
        'total_revenue', SUM(revenue_total),
        'total_orders', SUM(order_count),
        'average_conversion_rate', AVG(conversion_rate) FILTER (WHERE conversion_rate > 0),
        'abc_distribution', (
            SELECT jsonb_object_agg(abc_classification, classification_count)
            FROM (
                SELECT abc_classification, COUNT(*) as classification_count
                FROM product_variants
                WHERE product_id = p_product_id AND abc_classification IS NOT NULL
                GROUP BY abc_classification
            ) abc_stats
        )
    ) INTO result
    FROM product_variants
    WHERE product_id = p_product_id;
    
    RETURN COALESCE(result, '{"error": "No variants found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Comments
-- =============================================================================

COMMENT ON TABLE product_variants IS 'Normalized table for product variants, extracted from products.variants JSONB column';
COMMENT ON TABLE product_variant_option_values IS 'Links variants to their specific option value combinations';

COMMENT ON COLUMN product_variants.available_quantity IS 'Computed column: quantity - reserved_quantity';
COMMENT ON COLUMN product_variants.volume IS 'Computed column: length * width * height in cubic meters';
COMMENT ON COLUMN product_variants.option_values IS 'JSON object containing option-value pairs for this variant';
COMMENT ON COLUMN product_variants.abc_classification IS 'ABC analysis classification based on revenue contribution';
COMMENT ON COLUMN product_variants.harmonized_code IS 'HS code for international shipping and customs';

COMMENT ON FUNCTION get_product_variants(UUID, BOOLEAN) IS 'Get all variants for a product with option combinations';
COMMENT ON FUNCTION find_variant_by_options(UUID, JSONB) IS 'Find variant by exact option value combination';
COMMENT ON FUNCTION get_low_stock_variants(UUID) IS 'Get variants that need restocking';
COMMENT ON FUNCTION update_variant_inventory(UUID, INTEGER, VARCHAR) IS 'Update variant inventory with change tracking';
COMMENT ON FUNCTION get_variant_performance_stats(UUID) IS 'Get comprehensive performance statistics for a variant';
COMMENT ON FUNCTION get_product_variant_summary(UUID) IS 'Get summary statistics for all variants of a product';