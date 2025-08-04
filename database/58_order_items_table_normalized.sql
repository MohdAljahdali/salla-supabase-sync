-- =============================================================================
-- Order Items Table Normalized
-- =============================================================================
-- This table normalizes the order_items table by removing JSONB columns
-- and replacing them with references to separate normalized tables

CREATE TABLE IF NOT EXISTS order_items_normalized (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Product information
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    variant_id UUID REFERENCES product_variants(id) ON DELETE SET NULL,
    sku VARCHAR(100),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Quantity and pricing
    quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),
    total_price DECIMAL(10,2) NOT NULL CHECK (total_price >= 0),
    
    -- Discounts
    discount_amount DECIMAL(10,2) DEFAULT 0.00 CHECK (discount_amount >= 0),
    discount_percentage DECIMAL(5,2) DEFAULT 0.00 CHECK (discount_percentage >= 0 AND discount_percentage <= 100),
    
    -- Tax information
    tax_amount DECIMAL(10,2) DEFAULT 0.00 CHECK (tax_amount >= 0),
    tax_rate DECIMAL(5,2) DEFAULT 0.00 CHECK (tax_rate >= 0),
    
    -- Weight and dimensions
    weight DECIMAL(8,2) DEFAULT 0.00 CHECK (weight >= 0),
    length DECIMAL(8,2) DEFAULT 0.00 CHECK (length >= 0),
    width DECIMAL(8,2) DEFAULT 0.00 CHECK (width >= 0),
    height DECIMAL(8,2) DEFAULT 0.00 CHECK (height >= 0),
    
    -- Product details
    image_url TEXT,
    product_url TEXT,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    brand_id UUID REFERENCES brands(id) ON DELETE SET NULL,
    
    -- Inventory tracking
    requires_shipping BOOLEAN DEFAULT TRUE,
    is_digital BOOLEAN DEFAULT FALSE,
    is_gift_card BOOLEAN DEFAULT FALSE,
    
    -- Fulfillment status
    fulfillment_status VARCHAR(20) DEFAULT 'pending' CHECK (fulfillment_status IN (
        'pending', 'processing', 'shipped', 'delivered', 'cancelled', 'returned', 'refunded'
    )),
    fulfillment_date TIMESTAMPTZ,
    tracking_number VARCHAR(100),
    tracking_url TEXT,
    
    -- Return information
    is_returnable BOOLEAN DEFAULT TRUE,
    return_deadline TIMESTAMPTZ,
    return_reason VARCHAR(255),
    
    -- Quality and compliance
    quality_grade VARCHAR(10) DEFAULT 'A' CHECK (quality_grade IN ('A', 'B', 'C', 'D', 'F')),
    compliance_status VARCHAR(20) DEFAULT 'compliant' CHECK (compliance_status IN (
        'compliant', 'non_compliant', 'pending_review', 'exempt'
    )),
    safety_warnings JSONB DEFAULT '[]',
    
    -- External references
    external_item_id VARCHAR(255),
    external_product_id VARCHAR(255),
    external_variant_id VARCHAR(255),
    external_references JSONB DEFAULT '{}',
    
    -- Sync information
    sync_status VARCHAR(20) DEFAULT 'synced' CHECK (sync_status IN ('pending', 'syncing', 'synced', 'error')),
    last_sync_at TIMESTAMPTZ,
    sync_errors JSONB DEFAULT '[]',
    
    -- Custom fields
    custom_fields JSONB DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- Order Item Relationships Table
-- =============================================================================
-- Track relationships between order items and their normalized data

CREATE TABLE IF NOT EXISTS order_item_relationships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_item_id UUID NOT NULL REFERENCES order_items_normalized(id) ON DELETE CASCADE,
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Relationship types
    relationship_type VARCHAR(50) NOT NULL CHECK (relationship_type IN (
        'options', 'metadata', 'bundle_item', 'addon', 'replacement', 'upgrade', 'downgrade'
    )),
    
    -- Related entity information
    related_entity_type VARCHAR(50) NOT NULL CHECK (related_entity_type IN (
        'order_item_options', 'order_item_metadata', 'order_item', 'product', 'variant'
    )),
    related_entity_id UUID NOT NULL,
    
    -- Relationship properties
    relationship_strength DECIMAL(3,2) DEFAULT 1.00 CHECK (relationship_strength >= 0 AND relationship_strength <= 1),
    is_primary BOOLEAN DEFAULT FALSE,
    is_required BOOLEAN DEFAULT FALSE,
    
    -- Relationship context
    context_data JSONB DEFAULT '{}',
    relationship_notes TEXT,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    UNIQUE(order_item_id, relationship_type, related_entity_type, related_entity_id)
);

-- =============================================================================
-- Indexes
-- =============================================================================

-- Basic indexes
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_order_id ON order_items_normalized(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_store_id ON order_items_normalized(store_id);
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_product_id ON order_items_normalized(product_id);
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_variant_id ON order_items_normalized(variant_id);
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_sku ON order_items_normalized(sku);
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_external_item_id ON order_items_normalized(external_item_id);

-- Product information
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_name ON order_items_normalized(name);
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_category_id ON order_items_normalized(category_id);
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_brand_id ON order_items_normalized(brand_id);

-- Quantity and pricing
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_quantity ON order_items_normalized(quantity DESC);
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_unit_price ON order_items_normalized(unit_price DESC);
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_total_price ON order_items_normalized(total_price DESC);

-- Discounts
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_discount_amount ON order_items_normalized(discount_amount DESC) WHERE discount_amount > 0;
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_discount_percentage ON order_items_normalized(discount_percentage DESC) WHERE discount_percentage > 0;

-- Tax information
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_tax_amount ON order_items_normalized(tax_amount DESC) WHERE tax_amount > 0;
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_tax_rate ON order_items_normalized(tax_rate DESC) WHERE tax_rate > 0;

-- Weight and dimensions
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_weight ON order_items_normalized(weight DESC) WHERE weight > 0;

-- Product details
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_requires_shipping ON order_items_normalized(requires_shipping) WHERE requires_shipping = TRUE;
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_is_digital ON order_items_normalized(is_digital) WHERE is_digital = TRUE;
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_is_gift_card ON order_items_normalized(is_gift_card) WHERE is_gift_card = TRUE;

-- Fulfillment status
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_fulfillment_status ON order_items_normalized(fulfillment_status);
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_fulfillment_date ON order_items_normalized(fulfillment_date DESC);
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_tracking_number ON order_items_normalized(tracking_number);

-- Return information
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_is_returnable ON order_items_normalized(is_returnable) WHERE is_returnable = TRUE;
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_return_deadline ON order_items_normalized(return_deadline) WHERE return_deadline IS NOT NULL;

-- Quality and compliance
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_quality_grade ON order_items_normalized(quality_grade);
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_compliance_status ON order_items_normalized(compliance_status);

-- External references
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_external_product_id ON order_items_normalized(external_product_id);
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_external_variant_id ON order_items_normalized(external_variant_id);

-- Sync information
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_sync_status ON order_items_normalized(sync_status);
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_last_sync_at ON order_items_normalized(last_sync_at DESC);

-- Timestamps
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_created_at ON order_items_normalized(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_updated_at ON order_items_normalized(updated_at DESC);

-- JSONB indexes
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_safety_warnings ON order_items_normalized USING gin(safety_warnings);
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_external_references ON order_items_normalized USING gin(external_references);
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_custom_fields ON order_items_normalized USING gin(custom_fields);
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_sync_errors ON order_items_normalized USING gin(sync_errors);

-- Text search indexes
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_name_text ON order_items_normalized USING gin(to_tsvector('english', name));
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_description_text ON order_items_normalized USING gin(to_tsvector('english', COALESCE(description, '')));

-- Composite indexes
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_order_product ON order_items_normalized(order_id, product_id);
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_store_product ON order_items_normalized(store_id, product_id);
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_product_variant ON order_items_normalized(product_id, variant_id);
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_pricing ON order_items_normalized(unit_price DESC, total_price DESC, discount_amount DESC);
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_fulfillment ON order_items_normalized(fulfillment_status, fulfillment_date DESC);
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_returns ON order_items_normalized(is_returnable, return_deadline) WHERE is_returnable = TRUE;
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_digital_products ON order_items_normalized(is_digital, is_gift_card, requires_shipping);
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_quality ON order_items_normalized(quality_grade, compliance_status);
CREATE INDEX IF NOT EXISTS idx_order_items_normalized_external_refs ON order_items_normalized(external_item_id, external_product_id, external_variant_id);

-- Relationships table indexes
CREATE INDEX IF NOT EXISTS idx_order_item_relationships_order_item_id ON order_item_relationships(order_item_id);
CREATE INDEX IF NOT EXISTS idx_order_item_relationships_order_id ON order_item_relationships(order_id);
CREATE INDEX IF NOT EXISTS idx_order_item_relationships_store_id ON order_item_relationships(store_id);
CREATE INDEX IF NOT EXISTS idx_order_item_relationships_relationship_type ON order_item_relationships(relationship_type);
CREATE INDEX IF NOT EXISTS idx_order_item_relationships_related_entity_type ON order_item_relationships(related_entity_type);
CREATE INDEX IF NOT EXISTS idx_order_item_relationships_related_entity_id ON order_item_relationships(related_entity_id);
CREATE INDEX IF NOT EXISTS idx_order_item_relationships_is_primary ON order_item_relationships(is_primary) WHERE is_primary = TRUE;
CREATE INDEX IF NOT EXISTS idx_order_item_relationships_is_required ON order_item_relationships(is_required) WHERE is_required = TRUE;
CREATE INDEX IF NOT EXISTS idx_order_item_relationships_relationship_strength ON order_item_relationships(relationship_strength DESC);
CREATE INDEX IF NOT EXISTS idx_order_item_relationships_created_at ON order_item_relationships(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_item_relationships_context_data ON order_item_relationships USING gin(context_data);

-- =============================================================================
-- Triggers
-- =============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_order_items_normalized_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_order_items_normalized_updated_at
    BEFORE UPDATE ON order_items_normalized
    FOR EACH ROW
    EXECUTE FUNCTION update_order_items_normalized_updated_at();

CREATE TRIGGER trigger_update_order_item_relationships_updated_at
    BEFORE UPDATE ON order_item_relationships
    FOR EACH ROW
    EXECUTE FUNCTION update_order_items_normalized_updated_at();

-- Validate total price calculation
CREATE OR REPLACE FUNCTION validate_order_item_total_price()
RETURNS TRIGGER AS $$
DECLARE
    calculated_total DECIMAL(10,2);
    options_impact DECIMAL(10,2) := 0.00;
BEGIN
    -- Get options price impact if available
    SELECT COALESCE(calculate_option_price_impact(NEW.id), 0.00) INTO options_impact;
    
    -- Calculate expected total
    calculated_total := (NEW.unit_price + options_impact) * NEW.quantity - NEW.discount_amount + NEW.tax_amount;
    
    -- Allow small rounding differences (up to 0.01)
    IF ABS(NEW.total_price - calculated_total) > 0.01 THEN
        RAISE EXCEPTION 'Total price (%) does not match calculated total (%). Difference: %', 
            NEW.total_price, calculated_total, ABS(NEW.total_price - calculated_total);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validate_order_item_total_price
    BEFORE INSERT OR UPDATE ON order_items_normalized
    FOR EACH ROW
    EXECUTE FUNCTION validate_order_item_total_price();

-- Update fulfillment date when status changes
CREATE OR REPLACE FUNCTION update_order_item_fulfillment_date()
RETURNS TRIGGER AS $$
BEGIN
    -- Set fulfillment date when status changes to shipped or delivered
    IF OLD.fulfillment_status IS DISTINCT FROM NEW.fulfillment_status THEN
        CASE NEW.fulfillment_status
            WHEN 'shipped', 'delivered' THEN
                IF NEW.fulfillment_date IS NULL THEN
                    NEW.fulfillment_date := CURRENT_TIMESTAMP;
                END IF;
            WHEN 'cancelled', 'returned', 'refunded' THEN
                -- Keep the original fulfillment date for audit purposes
                NULL;
        END CASE;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_order_item_fulfillment_date
    BEFORE UPDATE ON order_items_normalized
    FOR EACH ROW
    EXECUTE FUNCTION update_order_item_fulfillment_date();

-- Validate relationship constraints
CREATE OR REPLACE FUNCTION validate_order_item_relationships()
RETURNS TRIGGER AS $$
BEGIN
    -- Ensure only one primary relationship per type
    IF NEW.is_primary = TRUE THEN
        UPDATE order_item_relationships
        SET is_primary = FALSE
        WHERE order_item_id = NEW.order_item_id
        AND relationship_type = NEW.relationship_type
        AND id != COALESCE(NEW.id, gen_random_uuid());
    END IF;
    
    -- Validate related entity exists
    CASE NEW.related_entity_type
        WHEN 'order_item_options' THEN
            IF NOT EXISTS (SELECT 1 FROM order_item_options WHERE id = NEW.related_entity_id) THEN
                RAISE EXCEPTION 'Related order item option does not exist';
            END IF;
        WHEN 'order_item_metadata' THEN
            IF NOT EXISTS (SELECT 1 FROM order_item_metadata WHERE id = NEW.related_entity_id) THEN
                RAISE EXCEPTION 'Related order item metadata does not exist';
            END IF;
        WHEN 'order_item' THEN
            IF NOT EXISTS (SELECT 1 FROM order_items_normalized WHERE id = NEW.related_entity_id) THEN
                RAISE EXCEPTION 'Related order item does not exist';
            END IF;
        WHEN 'product' THEN
            IF NOT EXISTS (SELECT 1 FROM products WHERE id = NEW.related_entity_id) THEN
                RAISE EXCEPTION 'Related product does not exist';
            END IF;
        WHEN 'variant' THEN
            IF NOT EXISTS (SELECT 1 FROM product_variants WHERE id = NEW.related_entity_id) THEN
                RAISE EXCEPTION 'Related product variant does not exist';
            END IF;
    END CASE;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validate_order_item_relationships
    BEFORE INSERT OR UPDATE ON order_item_relationships
    FOR EACH ROW
    EXECUTE FUNCTION validate_order_item_relationships();

-- =============================================================================
-- Helper Functions
-- =============================================================================

/**
 * Get complete order item data with all related information
 * @param p_order_item_id UUID - Order item ID
 * @param p_language_code VARCHAR - Language code (optional)
 * @return JSONB - Complete order item data
 */
CREATE OR REPLACE FUNCTION get_complete_order_item_data(
    p_order_item_id UUID,
    p_language_code VARCHAR DEFAULT 'en'
)
RETURNS JSONB AS $$
DECLARE
    item_data JSONB;
    options_data JSONB;
    metadata_data JSONB;
    relationships_data JSONB;
BEGIN
    -- Get basic order item data
    SELECT to_jsonb(oin.*) INTO item_data
    FROM order_items_normalized oin
    WHERE oin.id = p_order_item_id;
    
    IF item_data IS NULL THEN
        RETURN '{"error": "Order item not found"}'::jsonb;
    END IF;
    
    -- Get options data
    SELECT jsonb_agg(
        jsonb_build_object(
            'option_id', option_id,
            'option_name', option_name,
            'option_value', option_value,
            'option_type', option_type,
            'display_name', display_name,
            'display_value', display_value,
            'price_modifier', price_modifier,
            'weight_modifier', weight_modifier,
            'is_required', is_required
        )
    ) INTO options_data
    FROM get_order_item_options(p_order_item_id, p_language_code);
    
    -- Get metadata
    SELECT jsonb_agg(
        jsonb_build_object(
            'metadata_id', metadata_id,
            'metadata_key', metadata_key,
            'metadata_value', metadata_value,
            'metadata_type', metadata_type,
            'display_name', display_name,
            'display_value', display_value,
            'is_visible', is_visible,
            'is_editable', is_editable
        )
    ) INTO metadata_data
    FROM get_order_item_metadata(p_order_item_id, p_language_code);
    
    -- Get relationships
    SELECT jsonb_agg(
        jsonb_build_object(
            'relationship_id', oir.id,
            'relationship_type', oir.relationship_type,
            'related_entity_type', oir.related_entity_type,
            'related_entity_id', oir.related_entity_id,
            'relationship_strength', oir.relationship_strength,
            'is_primary', oir.is_primary,
            'is_required', oir.is_required,
            'context_data', oir.context_data,
            'relationship_notes', oir.relationship_notes
        )
    ) INTO relationships_data
    FROM order_item_relationships oir
    WHERE oir.order_item_id = p_order_item_id;
    
    -- Combine all data
    RETURN item_data || jsonb_build_object(
        'options', COALESCE(options_data, '[]'::jsonb),
        'metadata', COALESCE(metadata_data, '[]'::jsonb),
        'relationships', COALESCE(relationships_data, '[]'::jsonb)
    );
END;
$$ LANGUAGE plpgsql;

/**
 * Search order items with filters
 * @param p_store_id UUID - Store ID
 * @param p_filters JSONB - Search filters
 * @param p_language_code VARCHAR - Language code (optional)
 * @return TABLE - Search results
 */
CREATE OR REPLACE FUNCTION search_order_items_normalized(
    p_store_id UUID,
    p_filters JSONB DEFAULT '{}',
    p_language_code VARCHAR DEFAULT 'en'
)
RETURNS TABLE (
    order_item_id UUID,
    order_id UUID,
    product_id UUID,
    name VARCHAR,
    sku VARCHAR,
    quantity INTEGER,
    unit_price DECIMAL,
    total_price DECIMAL,
    fulfillment_status VARCHAR,
    created_at TIMESTAMPTZ
) AS $$
DECLARE
    where_clause TEXT := 'WHERE oin.store_id = $1';
    order_clause TEXT := 'ORDER BY oin.created_at DESC';
    limit_clause TEXT := 'LIMIT 100';
BEGIN
    -- Build dynamic WHERE clause based on filters
    IF p_filters ? 'order_id' THEN
        where_clause := where_clause || ' AND oin.order_id = ''' || (p_filters ->> 'order_id') || '''::uuid';
    END IF;
    
    IF p_filters ? 'product_id' THEN
        where_clause := where_clause || ' AND oin.product_id = ''' || (p_filters ->> 'product_id') || '''::uuid';
    END IF;
    
    IF p_filters ? 'fulfillment_status' THEN
        where_clause := where_clause || ' AND oin.fulfillment_status = ''' || (p_filters ->> 'fulfillment_status') || '''';
    END IF;
    
    IF p_filters ? 'search_term' THEN
        where_clause := where_clause || ' AND (oin.name ILIKE ''%' || (p_filters ->> 'search_term') || '%'' OR oin.sku ILIKE ''%' || (p_filters ->> 'search_term') || '%'')';
    END IF;
    
    IF p_filters ? 'min_price' THEN
        where_clause := where_clause || ' AND oin.total_price >= ' || (p_filters ->> 'min_price')::decimal;
    END IF;
    
    IF p_filters ? 'max_price' THEN
        where_clause := where_clause || ' AND oin.total_price <= ' || (p_filters ->> 'max_price')::decimal;
    END IF;
    
    IF p_filters ? 'date_from' THEN
        where_clause := where_clause || ' AND oin.created_at >= ''' || (p_filters ->> 'date_from') || '''::timestamptz';
    END IF;
    
    IF p_filters ? 'date_to' THEN
        where_clause := where_clause || ' AND oin.created_at <= ''' || (p_filters ->> 'date_to') || '''::timestamptz';
    END IF;
    
    IF p_filters ? 'limit' THEN
        limit_clause := 'LIMIT ' || (p_filters ->> 'limit')::integer;
    END IF;
    
    -- Execute dynamic query
    RETURN QUERY EXECUTE '
        SELECT 
            oin.id as order_item_id,
            oin.order_id,
            oin.product_id,
            oin.name,
            oin.sku,
            oin.quantity,
            oin.unit_price,
            oin.total_price,
            oin.fulfillment_status,
            oin.created_at
        FROM order_items_normalized oin
        ' || where_clause || ' ' || order_clause || ' ' || limit_clause
    USING p_store_id;
END;
$$ LANGUAGE plpgsql;

/**
 * Get order item statistics for store
 * @param p_store_id UUID - Store ID
 * @return JSONB - Order item statistics
 */
CREATE OR REPLACE FUNCTION get_order_item_stats(
    p_store_id UUID
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_items', COUNT(*),
        'total_quantity', SUM(quantity),
        'total_value', SUM(total_price),
        'avg_item_price', AVG(unit_price),
        'avg_item_value', AVG(total_price),
        'avg_quantity_per_item', AVG(quantity),
        'total_discount', SUM(discount_amount),
        'total_tax', SUM(tax_amount),
        'digital_items', COUNT(*) FILTER (WHERE is_digital = TRUE),
        'gift_card_items', COUNT(*) FILTER (WHERE is_gift_card = TRUE),
        'returnable_items', COUNT(*) FILTER (WHERE is_returnable = TRUE),
        'fulfillment_status_breakdown', (
            SELECT jsonb_object_agg(fulfillment_status, status_count)
            FROM (
                SELECT fulfillment_status, COUNT(*) as status_count
                FROM order_items_normalized
                WHERE store_id = p_store_id
                GROUP BY fulfillment_status
            ) status_stats
        ),
        'quality_grade_breakdown', (
            SELECT jsonb_object_agg(quality_grade, grade_count)
            FROM (
                SELECT quality_grade, COUNT(*) as grade_count
                FROM order_items_normalized
                WHERE store_id = p_store_id
                GROUP BY quality_grade
            ) grade_stats
        ),
        'compliance_status_breakdown', (
            SELECT jsonb_object_agg(compliance_status, compliance_count)
            FROM (
                SELECT compliance_status, COUNT(*) as compliance_count
                FROM order_items_normalized
                WHERE store_id = p_store_id
                GROUP BY compliance_status
            ) compliance_stats
        ),
        'top_products', (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'product_id', product_id,
                    'product_name', name,
                    'total_quantity', SUM(quantity),
                    'total_value', SUM(total_price),
                    'order_count', COUNT(DISTINCT order_id)
                )
            )
            FROM (
                SELECT 
                    product_id,
                    name,
                    SUM(quantity) as total_qty,
                    SUM(total_price) as total_val,
                    COUNT(DISTINCT order_id) as order_cnt
                FROM order_items_normalized
                WHERE store_id = p_store_id
                AND product_id IS NOT NULL
                GROUP BY product_id, name
                ORDER BY SUM(quantity) DESC, SUM(total_price) DESC
                LIMIT 10
            ) top_products_stats
        )
    ) INTO result
    FROM order_items_normalized
    WHERE store_id = p_store_id;
    
    RETURN COALESCE(result, '{"error": "No order items found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Comments
-- =============================================================================

COMMENT ON TABLE order_items_normalized IS 'Normalized order items table without JSONB columns';
COMMENT ON TABLE order_item_relationships IS 'Track relationships between order items and their normalized data';

COMMENT ON COLUMN order_items_normalized.total_price IS 'Total price including options, discounts, and tax';
COMMENT ON COLUMN order_items_normalized.fulfillment_status IS 'Current fulfillment status of the item';
COMMENT ON COLUMN order_items_normalized.quality_grade IS 'Quality grade for the item';
COMMENT ON COLUMN order_items_normalized.compliance_status IS 'Compliance status for regulations';

COMMENT ON FUNCTION get_complete_order_item_data(UUID, VARCHAR) IS 'Get complete order item data with all related information';
COMMENT ON FUNCTION search_order_items_normalized(UUID, JSONB, VARCHAR) IS 'Search order items with dynamic filters';
COMMENT ON FUNCTION get_order_item_stats(UUID) IS 'Get order item statistics for store';