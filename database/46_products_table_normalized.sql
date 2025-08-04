-- =============================================================================
-- Products Table - Normalized Version
-- =============================================================================
-- This is the updated products table after normalizing JSONB columns
-- The following JSONB columns have been moved to separate tables:
-- - images -> product_images table
-- - videos -> product_videos table  
-- - options -> product_options and product_option_values tables
-- - variants -> product_variants table
-- - metadata -> product_metadata table
-- - category_ids -> product_categories table
-- - tag_ids -> product_tags table

-- Drop the old products table (use with caution in production)
-- DROP TABLE IF EXISTS products CASCADE;

CREATE TABLE IF NOT EXISTS products_normalized (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Salla API identifiers
    salla_product_id VARCHAR(100) NOT NULL,
    external_id VARCHAR(255), -- For external system integration
    
    -- Basic product information
    name VARCHAR(500) NOT NULL,
    description TEXT,
    short_description TEXT,
    
    -- Pricing information
    price DECIMAL(10,2) NOT NULL DEFAULT 0,
    sale_price DECIMAL(10,2),
    cost_price DECIMAL(10,2),
    currency VARCHAR(3) DEFAULT 'SAR',
    
    -- Pricing rules and discounts
    min_price DECIMAL(10,2), -- Minimum allowed price
    max_price DECIMAL(10,2), -- Maximum allowed price
    price_includes_tax BOOLEAN DEFAULT TRUE,
    tax_rate DECIMAL(5,2) DEFAULT 0,
    
    -- Inventory information
    sku VARCHAR(255),
    mpn VARCHAR(255), -- Manufacturer Part Number
    gtin VARCHAR(255), -- Global Trade Item Number
    barcode VARCHAR(255),
    quantity INTEGER DEFAULT 0,
    unlimited_quantity BOOLEAN DEFAULT FALSE,
    hide_quantity BOOLEAN DEFAULT FALSE,
    
    -- Inventory management
    low_stock_threshold INTEGER DEFAULT 5,
    track_quantity BOOLEAN DEFAULT TRUE,
    allow_backorders BOOLEAN DEFAULT FALSE,
    stock_status VARCHAR(20) DEFAULT 'in_stock' CHECK (stock_status IN (
        'in_stock', 'out_of_stock', 'on_backorder', 'discontinued'
    )),
    
    -- Product specifications
    weight DECIMAL(8,2),
    weight_type VARCHAR(10) DEFAULT 'kg' CHECK (weight_type IN ('kg', 'g', 'lb', 'oz')),
    dimensions_length DECIMAL(8,2),
    dimensions_width DECIMAL(8,2),
    dimensions_height DECIMAL(8,2),
    dimensions_unit VARCHAR(5) DEFAULT 'cm' CHECK (dimensions_unit IN ('cm', 'm', 'in', 'ft')),
    
    -- Shipping information
    requires_shipping BOOLEAN DEFAULT TRUE,
    shipping_class VARCHAR(100),
    shipping_weight DECIMAL(8,2), -- Can be different from actual weight
    free_shipping BOOLEAN DEFAULT FALSE,
    
    -- Product type and variants
    type VARCHAR(20) DEFAULT 'simple' CHECK (type IN ('simple', 'variable', 'digital', 'grouped', 'external')),
    has_variants BOOLEAN DEFAULT FALSE,
    has_options BOOLEAN DEFAULT FALSE,
    parent_product_id UUID REFERENCES products_normalized(id), -- For grouped products
    
    -- SEO information
    seo_title VARCHAR(255),
    seo_description TEXT,
    seo_keywords TEXT,
    slug VARCHAR(255),
    canonical_url TEXT,
    
    -- Product status and visibility
    status VARCHAR(20) DEFAULT 'available' CHECK (status IN (
        'available', 'hidden', 'out_of_stock', 'draft', 'pending', 'archived'
    )),
    visibility VARCHAR(20) DEFAULT 'public' CHECK (visibility IN (
        'public', 'private', 'password_protected', 'members_only'
    )),
    is_featured BOOLEAN DEFAULT FALSE,
    is_virtual BOOLEAN DEFAULT FALSE, -- Digital/virtual product
    is_downloadable BOOLEAN DEFAULT FALSE,
    
    -- Media references (main image only, others in separate tables)
    main_image_url TEXT,
    main_image_alt TEXT,
    
    -- Brand information
    brand_id UUID REFERENCES brands(id),
    manufacturer VARCHAR(255),
    
    -- Rating and reviews
    rating_average DECIMAL(3,2) DEFAULT 0 CHECK (rating_average >= 0 AND rating_average <= 5),
    rating_count INTEGER DEFAULT 0,
    review_count INTEGER DEFAULT 0,
    
    -- Sales and performance metrics
    sales_count INTEGER DEFAULT 0,
    view_count INTEGER DEFAULT 0,
    wishlist_count INTEGER DEFAULT 0,
    
    -- Dates and scheduling
    published_at TIMESTAMPTZ,
    sale_start_date TIMESTAMPTZ,
    sale_end_date TIMESTAMPTZ,
    
    -- External system integration
    source_system VARCHAR(100) DEFAULT 'salla',
    source_url TEXT,
    
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
    CONSTRAINT products_normalized_unique_salla_id UNIQUE(store_id, salla_product_id),
    CONSTRAINT products_normalized_unique_sku UNIQUE(store_id, sku),
    CONSTRAINT products_normalized_price_check CHECK (price >= 0),
    CONSTRAINT products_normalized_sale_price_check CHECK (sale_price IS NULL OR sale_price >= 0),
    CONSTRAINT products_normalized_quantity_check CHECK (quantity >= 0 OR unlimited_quantity = TRUE),
    CONSTRAINT products_normalized_weight_check CHECK (weight IS NULL OR weight >= 0),
    CONSTRAINT products_normalized_dimensions_check CHECK (
        (dimensions_length IS NULL OR dimensions_length >= 0) AND
        (dimensions_width IS NULL OR dimensions_width >= 0) AND
        (dimensions_height IS NULL OR dimensions_height >= 0)
    )
);

-- =============================================================================
-- Product Relationships Table
-- =============================================================================
-- This table handles product relationships (cross-sells, up-sells, related)

CREATE TABLE IF NOT EXISTS product_relationships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products_normalized(id) ON DELETE CASCADE,
    related_product_id UUID NOT NULL REFERENCES products_normalized(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Relationship type
    relationship_type VARCHAR(20) NOT NULL CHECK (relationship_type IN (
        'cross_sell', 'up_sell', 'related', 'alternative', 'accessory', 'bundle', 'replacement'
    )),
    
    -- Relationship properties
    priority INTEGER DEFAULT 0,
    is_bidirectional BOOLEAN DEFAULT FALSE,
    
    -- Performance tracking
    click_count INTEGER DEFAULT 0,
    conversion_count INTEGER DEFAULT 0,
    revenue_generated DECIMAL(10,2) DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT product_relationships_unique UNIQUE (product_id, related_product_id, relationship_type),
    CONSTRAINT product_relationships_no_self_reference CHECK (product_id != related_product_id)
);

-- =============================================================================
-- Indexes
-- =============================================================================

-- Basic indexes
CREATE INDEX IF NOT EXISTS idx_products_normalized_store_id ON products_normalized(store_id);
CREATE INDEX IF NOT EXISTS idx_products_normalized_salla_product_id ON products_normalized(salla_product_id);
CREATE INDEX IF NOT EXISTS idx_products_normalized_external_id ON products_normalized(external_id);
CREATE INDEX IF NOT EXISTS idx_products_normalized_sku ON products_normalized(sku);
CREATE INDEX IF NOT EXISTS idx_products_normalized_barcode ON products_normalized(barcode);

-- Product information indexes
CREATE INDEX IF NOT EXISTS idx_products_normalized_name ON products_normalized(name);
CREATE INDEX IF NOT EXISTS idx_products_normalized_name_text ON products_normalized USING gin(to_tsvector('english', name));
CREATE INDEX IF NOT EXISTS idx_products_normalized_description_text ON products_normalized USING gin(to_tsvector('english', description));

-- Pricing indexes
CREATE INDEX IF NOT EXISTS idx_products_normalized_price ON products_normalized(price);
CREATE INDEX IF NOT EXISTS idx_products_normalized_sale_price ON products_normalized(sale_price);
CREATE INDEX IF NOT EXISTS idx_products_normalized_currency ON products_normalized(currency);
CREATE INDEX IF NOT EXISTS idx_products_normalized_price_range ON products_normalized(price, sale_price);

-- Inventory indexes
CREATE INDEX IF NOT EXISTS idx_products_normalized_quantity ON products_normalized(quantity);
CREATE INDEX IF NOT EXISTS idx_products_normalized_stock_status ON products_normalized(stock_status);
CREATE INDEX IF NOT EXISTS idx_products_normalized_unlimited_quantity ON products_normalized(unlimited_quantity);
CREATE INDEX IF NOT EXISTS idx_products_normalized_low_stock ON products_normalized(quantity, low_stock_threshold) WHERE track_quantity = TRUE;

-- Product type and structure
CREATE INDEX IF NOT EXISTS idx_products_normalized_type ON products_normalized(type);
CREATE INDEX IF NOT EXISTS idx_products_normalized_has_variants ON products_normalized(has_variants);
CREATE INDEX IF NOT EXISTS idx_products_normalized_has_options ON products_normalized(has_options);
CREATE INDEX IF NOT EXISTS idx_products_normalized_parent_product_id ON products_normalized(parent_product_id);

-- Status and visibility
CREATE INDEX IF NOT EXISTS idx_products_normalized_status ON products_normalized(status);
CREATE INDEX IF NOT EXISTS idx_products_normalized_visibility ON products_normalized(visibility);
CREATE INDEX IF NOT EXISTS idx_products_normalized_is_featured ON products_normalized(is_featured);
CREATE INDEX IF NOT EXISTS idx_products_normalized_is_virtual ON products_normalized(is_virtual);
CREATE INDEX IF NOT EXISTS idx_products_normalized_is_downloadable ON products_normalized(is_downloadable);

-- Brand and manufacturer
CREATE INDEX IF NOT EXISTS idx_products_normalized_brand_id ON products_normalized(brand_id);
CREATE INDEX IF NOT EXISTS idx_products_normalized_manufacturer ON products_normalized(manufacturer);

-- Rating and performance
CREATE INDEX IF NOT EXISTS idx_products_normalized_rating_average ON products_normalized(rating_average DESC);
CREATE INDEX IF NOT EXISTS idx_products_normalized_rating_count ON products_normalized(rating_count DESC);
CREATE INDEX IF NOT EXISTS idx_products_normalized_sales_count ON products_normalized(sales_count DESC);
CREATE INDEX IF NOT EXISTS idx_products_normalized_view_count ON products_normalized(view_count DESC);
CREATE INDEX IF NOT EXISTS idx_products_normalized_wishlist_count ON products_normalized(wishlist_count DESC);

-- SEO indexes
CREATE INDEX IF NOT EXISTS idx_products_normalized_slug ON products_normalized(slug);
CREATE INDEX IF NOT EXISTS idx_products_normalized_seo_title ON products_normalized USING gin(to_tsvector('english', seo_title));

-- Date indexes
CREATE INDEX IF NOT EXISTS idx_products_normalized_created_at ON products_normalized(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_products_normalized_updated_at ON products_normalized(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_products_normalized_published_at ON products_normalized(published_at DESC);
CREATE INDEX IF NOT EXISTS idx_products_normalized_sale_dates ON products_normalized(sale_start_date, sale_end_date);

-- Sync indexes
CREATE INDEX IF NOT EXISTS idx_products_normalized_sync_status ON products_normalized(sync_status);
CREATE INDEX IF NOT EXISTS idx_products_normalized_last_sync_at ON products_normalized(last_sync_at DESC);
CREATE INDEX IF NOT EXISTS idx_products_normalized_source_system ON products_normalized(source_system);

-- JSONB indexes
CREATE INDEX IF NOT EXISTS idx_products_normalized_custom_fields ON products_normalized USING gin(custom_fields);
CREATE INDEX IF NOT EXISTS idx_products_normalized_sync_errors ON products_normalized USING gin(sync_errors);

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_products_normalized_store_status ON products_normalized(store_id, status, visibility);
CREATE INDEX IF NOT EXISTS idx_products_normalized_store_featured ON products_normalized(store_id, is_featured, status) WHERE is_featured = TRUE;
CREATE INDEX IF NOT EXISTS idx_products_normalized_store_price ON products_normalized(store_id, price, status) WHERE status = 'available';
CREATE INDEX IF NOT EXISTS idx_products_normalized_brand_status ON products_normalized(brand_id, status, visibility) WHERE brand_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_products_normalized_type_status ON products_normalized(type, status, has_variants);

-- Product Relationships Indexes
CREATE INDEX IF NOT EXISTS idx_product_relationships_product_id ON product_relationships(product_id);
CREATE INDEX IF NOT EXISTS idx_product_relationships_related_product_id ON product_relationships(related_product_id);
CREATE INDEX IF NOT EXISTS idx_product_relationships_store_id ON product_relationships(store_id);
CREATE INDEX IF NOT EXISTS idx_product_relationships_type ON product_relationships(relationship_type);
CREATE INDEX IF NOT EXISTS idx_product_relationships_priority ON product_relationships(priority DESC);
CREATE INDEX IF NOT EXISTS idx_product_relationships_performance ON product_relationships(conversion_count DESC, click_count DESC);

-- =============================================================================
-- Triggers
-- =============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_products_normalized_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_products_normalized_updated_at
    BEFORE UPDATE ON products_normalized
    FOR EACH ROW
    EXECUTE FUNCTION update_products_normalized_updated_at();

-- Auto-update updated_at timestamp for relationships
CREATE OR REPLACE FUNCTION update_product_relationships_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_product_relationships_updated_at
    BEFORE UPDATE ON product_relationships
    FOR EACH ROW
    EXECUTE FUNCTION update_product_relationships_updated_at();

-- Auto-update stock status based on quantity
CREATE OR REPLACE FUNCTION update_stock_status()
RETURNS TRIGGER AS $$
BEGIN
    -- Only update if tracking quantity
    IF NEW.track_quantity = TRUE AND NEW.unlimited_quantity = FALSE THEN
        IF NEW.quantity <= 0 THEN
            NEW.stock_status := 'out_of_stock';
        ELSIF NEW.quantity <= NEW.low_stock_threshold THEN
            -- Keep current status if it's already out_of_stock or on_backorder
            IF OLD.stock_status NOT IN ('out_of_stock', 'on_backorder') THEN
                NEW.stock_status := 'in_stock';
            END IF;
        ELSE
            NEW.stock_status := 'in_stock';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_stock_status
    BEFORE UPDATE ON products_normalized
    FOR EACH ROW
    WHEN (NEW.quantity != OLD.quantity OR NEW.track_quantity != OLD.track_quantity)
    EXECUTE FUNCTION update_stock_status();

-- Auto-set published_at when status changes to available
CREATE OR REPLACE FUNCTION set_published_at()
RETURNS TRIGGER AS $$
BEGIN
    -- Set published_at when product becomes available for the first time
    IF NEW.status = 'available' AND (OLD.status != 'available' OR OLD.published_at IS NULL) THEN
        NEW.published_at := CURRENT_TIMESTAMP;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_set_published_at
    BEFORE UPDATE ON products_normalized
    FOR EACH ROW
    WHEN (NEW.status != OLD.status)
    EXECUTE FUNCTION set_published_at();

-- Validate sale price
CREATE OR REPLACE FUNCTION validate_sale_price()
RETURNS TRIGGER AS $$
BEGIN
    -- Ensure sale price is less than regular price
    IF NEW.sale_price IS NOT NULL AND NEW.sale_price >= NEW.price THEN
        RAISE EXCEPTION 'Sale price must be less than regular price';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validate_sale_price
    BEFORE INSERT OR UPDATE ON products_normalized
    FOR EACH ROW
    WHEN (NEW.sale_price IS NOT NULL)
    EXECUTE FUNCTION validate_sale_price();

-- =============================================================================
-- Helper Functions
-- =============================================================================

/**
 * Get product with all related data
 * @param p_product_id UUID - Product ID
 * @return RECORD - Complete product information
 */
CREATE OR REPLACE FUNCTION get_complete_product(
    p_product_id UUID
)
RETURNS TABLE (
    product_data JSONB,
    images JSONB,
    videos JSONB,
    options JSONB,
    variants JSONB,
    categories JSONB,
    tags JSONB,
    metadata JSONB,
    relationships JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        to_jsonb(p.*) as product_data,
        COALESCE((
            SELECT jsonb_agg(to_jsonb(pi.*))
            FROM product_images pi
            WHERE pi.product_id = p.id
            ORDER BY pi.sort_order
        ), '[]'::jsonb) as images,
        COALESCE((
            SELECT jsonb_agg(to_jsonb(pv.*))
            FROM product_videos pv
            WHERE pv.product_id = p.id
            ORDER BY pv.sort_order
        ), '[]'::jsonb) as videos,
        COALESCE((
            SELECT jsonb_agg(to_jsonb(po.*))
            FROM product_options po
            WHERE po.product_id = p.id
            ORDER BY po.sort_order
        ), '[]'::jsonb) as options,
        COALESCE((
            SELECT jsonb_agg(to_jsonb(pvar.*))
            FROM product_variants pvar
            WHERE pvar.product_id = p.id
            ORDER BY pvar.sort_order
        ), '[]'::jsonb) as variants,
        COALESCE((
            SELECT jsonb_agg(jsonb_build_object(
                'category_id', pc.category_id,
                'is_primary', pc.is_primary,
                'category_name', c.name
            ))
            FROM product_categories pc
            JOIN categories c ON c.id = pc.category_id
            WHERE pc.product_id = p.id AND pc.is_visible = TRUE
            ORDER BY pc.is_primary DESC, pc.sort_order
        ), '[]'::jsonb) as categories,
        COALESCE((
            SELECT jsonb_agg(jsonb_build_object(
                'tag_id', pt.tag_id,
                'tag_name', t.name,
                'context_type', pt.context_type
            ))
            FROM product_tags pt
            JOIN tags t ON t.id = pt.tag_id
            WHERE pt.product_id = p.id AND pt.is_visible = TRUE
            ORDER BY pt.sort_order
        ), '[]'::jsonb) as tags,
        COALESCE((
            SELECT jsonb_object_agg(pm.meta_key, pm.meta_value)
            FROM product_metadata pm
            WHERE pm.product_id = p.id AND pm.is_public = TRUE
        ), '{}'::jsonb) as metadata,
        COALESCE((
            SELECT jsonb_agg(jsonb_build_object(
                'related_product_id', pr.related_product_id,
                'relationship_type', pr.relationship_type,
                'product_name', rp.name
            ))
            FROM product_relationships pr
            JOIN products_normalized rp ON rp.id = pr.related_product_id
            WHERE pr.product_id = p.id
            ORDER BY pr.priority DESC
        ), '[]'::jsonb) as relationships
    FROM products_normalized p
    WHERE p.id = p_product_id;
END;
$$ LANGUAGE plpgsql;

/**
 * Search products with filters
 * @param p_store_id UUID - Store ID
 * @param p_filters JSONB - Search filters
 * @param p_limit INTEGER - Limit results
 * @param p_offset INTEGER - Offset for pagination
 * @return TABLE - Filtered products
 */
CREATE OR REPLACE FUNCTION search_products(
    p_store_id UUID,
    p_filters JSONB DEFAULT '{}',
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    name VARCHAR,
    price DECIMAL,
    sale_price DECIMAL,
    main_image_url TEXT,
    rating_average DECIMAL,
    sales_count INTEGER
) AS $$
DECLARE
    where_clause TEXT := 'WHERE p.store_id = $1 AND p.status = ''available'' AND p.visibility = ''public''';
    order_clause TEXT := 'ORDER BY p.is_featured DESC, p.sales_count DESC, p.created_at DESC';
    query_text TEXT;
BEGIN
    -- Build dynamic WHERE clause based on filters
    IF p_filters ? 'category_id' THEN
        where_clause := where_clause || ' AND EXISTS (SELECT 1 FROM product_categories pc WHERE pc.product_id = p.id AND pc.category_id = ''' || (p_filters->>'category_id') || '''::uuid)';
    END IF;
    
    IF p_filters ? 'brand_id' THEN
        where_clause := where_clause || ' AND p.brand_id = ''' || (p_filters->>'brand_id') || '''::uuid';
    END IF;
    
    IF p_filters ? 'min_price' THEN
        where_clause := where_clause || ' AND p.price >= ' || (p_filters->>'min_price')::decimal;
    END IF;
    
    IF p_filters ? 'max_price' THEN
        where_clause := where_clause || ' AND p.price <= ' || (p_filters->>'max_price')::decimal;
    END IF;
    
    IF p_filters ? 'search_term' THEN
        where_clause := where_clause || ' AND (p.name ILIKE ''%' || (p_filters->>'search_term') || '%'' OR p.description ILIKE ''%' || (p_filters->>'search_term') || '%'')';
    END IF;
    
    -- Build complete query
    query_text := 'SELECT p.id, p.name, p.price, p.sale_price, p.main_image_url, p.rating_average, p.sales_count FROM products_normalized p ' || where_clause || ' ' || order_clause || ' LIMIT $2 OFFSET $3';
    
    RETURN QUERY EXECUTE query_text USING p_store_id, p_limit, p_offset;
END;
$$ LANGUAGE plpgsql;

/**
 * Get product statistics for a store
 * @param p_store_id UUID - Store ID
 * @return JSONB - Product statistics
 */
CREATE OR REPLACE FUNCTION get_product_stats(
    p_store_id UUID
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_products', COUNT(*),
        'available_products', COUNT(*) FILTER (WHERE status = 'available'),
        'featured_products', COUNT(*) FILTER (WHERE is_featured = TRUE),
        'out_of_stock_products', COUNT(*) FILTER (WHERE stock_status = 'out_of_stock'),
        'products_with_variants', COUNT(*) FILTER (WHERE has_variants = TRUE),
        'digital_products', COUNT(*) FILTER (WHERE is_virtual = TRUE),
        'avg_price', AVG(price),
        'total_inventory_value', SUM(price * quantity),
        'avg_rating', AVG(rating_average),
        'total_sales', SUM(sales_count),
        'product_types', (
            SELECT jsonb_object_agg(type, type_count)
            FROM (
                SELECT type, COUNT(*) as type_count
                FROM products_normalized
                WHERE store_id = p_store_id
                GROUP BY type
            ) type_stats
        )
    ) INTO result
    FROM products_normalized
    WHERE store_id = p_store_id;
    
    RETURN COALESCE(result, '{"error": "No products found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Comments
-- =============================================================================

COMMENT ON TABLE products_normalized IS 'Normalized products table with JSONB columns moved to separate tables';
COMMENT ON TABLE product_relationships IS 'Product relationships for cross-sells, up-sells, and related products';

COMMENT ON COLUMN products_normalized.salla_product_id IS 'Unique product identifier from Salla API';
COMMENT ON COLUMN products_normalized.type IS 'Product type: simple, variable, digital, grouped, or external';
COMMENT ON COLUMN products_normalized.stock_status IS 'Current stock status independent of quantity';
COMMENT ON COLUMN products_normalized.visibility IS 'Product visibility level';
COMMENT ON COLUMN products_normalized.sync_status IS 'Synchronization status with external systems';

COMMENT ON FUNCTION get_complete_product(UUID) IS 'Get product with all related data from normalized tables';
COMMENT ON FUNCTION search_products(UUID, JSONB, INTEGER, INTEGER) IS 'Search products with dynamic filters';
COMMENT ON FUNCTION get_product_stats(UUID) IS 'Get comprehensive product statistics for a store';