-- =============================================================================
-- Brands Table
-- =============================================================================
-- This table stores brand information for products
-- Brands help organize products and provide brand-specific marketing

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create brands table
CREATE TABLE IF NOT EXISTS brands (
    -- Primary identification
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Salla API identifiers
    salla_brand_id VARCHAR(100) UNIQUE,
    salla_store_id VARCHAR(100),
    
    -- Store relationship
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Brand identification
    brand_name VARCHAR(255) NOT NULL,
    brand_slug VARCHAR(255),
    brand_code VARCHAR(100),
    
    -- Brand description and details
    brand_description TEXT,
    brand_story TEXT,
    brand_mission TEXT,
    brand_vision TEXT,
    
    -- Brand media and assets
    brand_logo_url TEXT,
    brand_logo_alt TEXT,
    brand_banner_url TEXT,
    brand_banner_alt TEXT,
    brand_favicon_url TEXT,
    brand_watermark_url TEXT,
    
    -- Brand images gallery
    brand_images JSONB DEFAULT '[]',
    brand_videos JSONB DEFAULT '[]',
    
    -- Brand contact and social
    brand_website VARCHAR(500),
    brand_email VARCHAR(255),
    brand_phone VARCHAR(50),
    brand_address TEXT,
    
    -- Social media links
    social_media JSONB DEFAULT '{}', -- {"facebook": "url", "instagram": "url", "twitter": "url"}
    
    -- Brand status and visibility
    is_active BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    is_verified BOOLEAN DEFAULT FALSE,
    brand_status VARCHAR(50) DEFAULT 'active', -- active, inactive, pending, suspended
    visibility VARCHAR(50) DEFAULT 'public', -- public, private, hidden
    
    -- Brand metrics and statistics
    products_count INTEGER DEFAULT 0,
    total_sales_amount DECIMAL(15,4) DEFAULT 0,
    total_orders_count INTEGER DEFAULT 0,
    average_rating DECIMAL(3,2) DEFAULT 0,
    reviews_count INTEGER DEFAULT 0,
    
    -- Brand performance metrics
    monthly_sales DECIMAL(15,4) DEFAULT 0,
    monthly_orders INTEGER DEFAULT 0,
    conversion_rate DECIMAL(5,4) DEFAULT 0,
    return_rate DECIMAL(5,4) DEFAULT 0,
    
    -- Brand settings and preferences
    brand_settings JSONB DEFAULT '{}',
    brand_preferences JSONB DEFAULT '{}',
    
    -- SEO and marketing
    meta_title VARCHAR(255),
    meta_description TEXT,
    meta_keywords TEXT,
    seo_url VARCHAR(500),
    
    -- Marketing and promotion
    marketing_budget DECIMAL(15,4) DEFAULT 0,
    promotion_settings JSONB DEFAULT '{}',
    brand_campaigns JSONB DEFAULT '[]',
    
    -- Brand categories and tags
    brand_categories JSONB DEFAULT '[]', -- Array of category IDs
    brand_tags JSONB DEFAULT '[]', -- Array of tag names
    
    -- Geographic and market information
    target_markets JSONB DEFAULT '[]', -- Array of country codes
    available_countries JSONB DEFAULT '[]',
    shipping_countries JSONB DEFAULT '[]',
    
    -- Brand quality and certifications
    certifications JSONB DEFAULT '[]',
    quality_standards JSONB DEFAULT '[]',
    awards JSONB DEFAULT '[]',
    
    -- Brand partnerships and collaborations
    partnerships JSONB DEFAULT '[]',
    collaborations JSONB DEFAULT '[]',
    
    -- Brand policies
    return_policy TEXT,
    warranty_policy TEXT,
    privacy_policy TEXT,
    terms_of_service TEXT,
    
    -- Brand analytics and tracking
    analytics_settings JSONB DEFAULT '{}',
    tracking_codes JSONB DEFAULT '{}',
    
    -- Brand customization
    brand_colors JSONB DEFAULT '{}', -- {"primary": "#color", "secondary": "#color"}
    brand_fonts JSONB DEFAULT '{}',
    brand_theme JSONB DEFAULT '{}',
    
    -- Integration and sync
    integration_settings JSONB DEFAULT '{}',
    sync_status VARCHAR(50) DEFAULT 'pending',
    last_sync_at TIMESTAMPTZ,
    sync_errors JSONB DEFAULT '[]',
    
    -- API and webhook settings
    api_settings JSONB DEFAULT '{}',
    webhook_settings JSONB DEFAULT '{}',
    
    -- Metadata and custom fields
    metadata JSONB DEFAULT '{}',
    custom_fields JSONB DEFAULT '{}',
    tags_array TEXT[] DEFAULT '{}',
    
    -- Internal notes and comments
    internal_notes TEXT,
    admin_comments TEXT,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    
    -- Constraints
    CONSTRAINT brands_brand_name_store_unique UNIQUE(brand_name, store_id),
    CONSTRAINT brands_brand_slug_store_unique UNIQUE(brand_slug, store_id),
    CONSTRAINT brands_brand_code_store_unique UNIQUE(brand_code, store_id),
    CONSTRAINT brands_brand_status_check CHECK (brand_status IN ('active', 'inactive', 'pending', 'suspended')),
    CONSTRAINT brands_visibility_check CHECK (visibility IN ('public', 'private', 'hidden')),
    CONSTRAINT brands_sync_status_check CHECK (sync_status IN ('pending', 'syncing', 'synced', 'error')),
    CONSTRAINT brands_average_rating_check CHECK (average_rating >= 0 AND average_rating <= 5),
    CONSTRAINT brands_conversion_rate_check CHECK (conversion_rate >= 0 AND conversion_rate <= 1),
    CONSTRAINT brands_return_rate_check CHECK (return_rate >= 0 AND return_rate <= 1)
);

-- =============================================================================
-- Indexes
-- =============================================================================

-- Primary indexes
CREATE INDEX IF NOT EXISTS idx_brands_store_id ON brands(store_id);
CREATE INDEX IF NOT EXISTS idx_brands_salla_brand_id ON brands(salla_brand_id);
CREATE INDEX IF NOT EXISTS idx_brands_salla_store_id ON brands(salla_store_id);

-- Search and filtering indexes
CREATE INDEX IF NOT EXISTS idx_brands_brand_name ON brands(brand_name);
CREATE INDEX IF NOT EXISTS idx_brands_brand_slug ON brands(brand_slug);
CREATE INDEX IF NOT EXISTS idx_brands_brand_code ON brands(brand_code);
CREATE INDEX IF NOT EXISTS idx_brands_brand_status ON brands(brand_status);
CREATE INDEX IF NOT EXISTS idx_brands_visibility ON brands(visibility);
CREATE INDEX IF NOT EXISTS idx_brands_is_active ON brands(is_active);
CREATE INDEX IF NOT EXISTS idx_brands_is_featured ON brands(is_featured);
CREATE INDEX IF NOT EXISTS idx_brands_is_verified ON brands(is_verified);

-- Performance and analytics indexes
CREATE INDEX IF NOT EXISTS idx_brands_products_count ON brands(products_count DESC);
CREATE INDEX IF NOT EXISTS idx_brands_total_sales ON brands(total_sales_amount DESC);
CREATE INDEX IF NOT EXISTS idx_brands_average_rating ON brands(average_rating DESC);
CREATE INDEX IF NOT EXISTS idx_brands_monthly_sales ON brands(monthly_sales DESC);

-- Text search indexes
CREATE INDEX IF NOT EXISTS idx_brands_name_search ON brands USING gin(brand_name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_brands_description_search ON brands USING gin(brand_description gin_trgm_ops);

-- JSONB indexes
CREATE INDEX IF NOT EXISTS idx_brands_social_media ON brands USING gin(social_media);
CREATE INDEX IF NOT EXISTS idx_brands_brand_settings ON brands USING gin(brand_settings);
CREATE INDEX IF NOT EXISTS idx_brands_brand_categories ON brands USING gin(brand_categories);
CREATE INDEX IF NOT EXISTS idx_brands_brand_tags ON brands USING gin(brand_tags);
CREATE INDEX IF NOT EXISTS idx_brands_target_markets ON brands USING gin(target_markets);
CREATE INDEX IF NOT EXISTS idx_brands_metadata ON brands USING gin(metadata);

-- Array indexes
CREATE INDEX IF NOT EXISTS idx_brands_tags_array ON brands USING gin(tags_array);

-- Composite indexes
CREATE INDEX IF NOT EXISTS idx_brands_store_status ON brands(store_id, brand_status, is_active);
CREATE INDEX IF NOT EXISTS idx_brands_store_featured ON brands(store_id, is_featured, is_active) WHERE is_featured = TRUE;
CREATE INDEX IF NOT EXISTS idx_brands_store_performance ON brands(store_id, total_sales_amount DESC, products_count DESC);
CREATE INDEX IF NOT EXISTS idx_brands_sync_status ON brands(sync_status, last_sync_at);

-- Timestamp indexes
CREATE INDEX IF NOT EXISTS idx_brands_created_at ON brands(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_brands_updated_at ON brands(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_brands_deleted_at ON brands(deleted_at) WHERE deleted_at IS NOT NULL;

-- =============================================================================
-- Triggers
-- =============================================================================

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_brands_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_brands_updated_at
    BEFORE UPDATE ON brands
    FOR EACH ROW
    EXECUTE FUNCTION update_brands_updated_at();

-- Trigger to generate brand slug
CREATE OR REPLACE FUNCTION generate_brand_slug()
RETURNS TRIGGER AS $$
BEGIN
    -- Generate slug from brand name if not provided
    IF NEW.brand_slug IS NULL OR NEW.brand_slug = '' THEN
        NEW.brand_slug = lower(regexp_replace(NEW.brand_name, '[^a-zA-Z0-9\s]', '', 'g'));
        NEW.brand_slug = regexp_replace(NEW.brand_slug, '\s+', '-', 'g');
        NEW.brand_slug = trim(both '-' from NEW.brand_slug);
    END IF;
    
    -- Ensure slug uniqueness within store
    DECLARE
        base_slug TEXT := NEW.brand_slug;
        counter INTEGER := 1;
    BEGIN
        WHILE EXISTS (
            SELECT 1 FROM brands 
            WHERE brand_slug = NEW.brand_slug 
            AND store_id = NEW.store_id 
            AND id != COALESCE(NEW.id, uuid_generate_v4())
        ) LOOP
            NEW.brand_slug = base_slug || '-' || counter;
            counter = counter + 1;
        END LOOP;
    END;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_brands_generate_slug
    BEFORE INSERT OR UPDATE ON brands
    FOR EACH ROW
    EXECUTE FUNCTION generate_brand_slug();

-- Trigger to update brand performance metrics
CREATE OR REPLACE FUNCTION update_brand_performance_metrics()
RETURNS TRIGGER AS $$
BEGIN
    -- Update products count
    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
        NEW.products_count = (
            SELECT COUNT(*)
            FROM products p
            WHERE p.brand_id = NEW.id
            AND p.deleted_at IS NULL
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_brands_performance_metrics
    BEFORE INSERT OR UPDATE ON brands
    FOR EACH ROW
    EXECUTE FUNCTION update_brand_performance_metrics();

-- =============================================================================
-- Helper Functions
-- =============================================================================

-- Function: Get brand statistics
CREATE OR REPLACE FUNCTION get_brand_stats(p_brand_id UUID)
RETURNS TABLE (
    brand_id UUID,
    brand_name VARCHAR(255),
    products_count BIGINT,
    total_sales DECIMAL(15,4),
    total_orders BIGINT,
    average_rating DECIMAL(3,2),
    reviews_count BIGINT,
    monthly_sales DECIMAL(15,4),
    monthly_orders BIGINT,
    conversion_rate DECIMAL(5,4),
    return_rate DECIMAL(5,4)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        b.id,
        b.brand_name,
        COUNT(DISTINCT p.id)::BIGINT as products_count,
        COALESCE(SUM(oi.total_amount), 0) as total_sales,
        COUNT(DISTINCT o.id)::BIGINT as total_orders,
        COALESCE(AVG(pr.rating), 0)::DECIMAL(3,2) as average_rating,
        COUNT(DISTINCT pr.id)::BIGINT as reviews_count,
        COALESCE(SUM(CASE 
            WHEN o.created_at >= date_trunc('month', NOW()) 
            THEN oi.total_amount 
            ELSE 0 
        END), 0) as monthly_sales,
        COUNT(DISTINCT CASE 
            WHEN o.created_at >= date_trunc('month', NOW()) 
            THEN o.id 
        END)::BIGINT as monthly_orders,
        CASE 
            WHEN COUNT(DISTINCT c.id) > 0 THEN 
                COUNT(DISTINCT o.id)::DECIMAL / COUNT(DISTINCT c.id)::DECIMAL
            ELSE 0
        END as conversion_rate,
        CASE 
            WHEN COUNT(DISTINCT o.id) > 0 THEN 
                COUNT(DISTINCT CASE WHEN o.order_status = 'returned' THEN o.id END)::DECIMAL / COUNT(DISTINCT o.id)::DECIMAL
            ELSE 0
        END as return_rate
    FROM brands b
    LEFT JOIN products p ON b.id = p.brand_id AND p.deleted_at IS NULL
    LEFT JOIN order_items oi ON p.id = oi.product_id
    LEFT JOIN orders o ON oi.order_id = o.id
    LEFT JOIN customers c ON o.customer_id = c.id
    LEFT JOIN product_reviews pr ON p.id = pr.product_id
    WHERE b.id = p_brand_id
    GROUP BY b.id, b.brand_name;
END;
$$ LANGUAGE plpgsql;

-- Function: Get store brands with statistics
CREATE OR REPLACE FUNCTION get_store_brands_stats(p_store_id UUID)
RETURNS TABLE (
    brand_id UUID,
    brand_name VARCHAR(255),
    brand_slug VARCHAR(255),
    is_active BOOLEAN,
    is_featured BOOLEAN,
    products_count BIGINT,
    total_sales DECIMAL(15,4),
    average_rating DECIMAL(3,2),
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        b.id,
        b.brand_name,
        b.brand_slug,
        b.is_active,
        b.is_featured,
        COUNT(DISTINCT p.id)::BIGINT as products_count,
        COALESCE(SUM(oi.total_amount), 0) as total_sales,
        COALESCE(AVG(pr.rating), 0)::DECIMAL(3,2) as average_rating,
        b.created_at
    FROM brands b
    LEFT JOIN products p ON b.id = p.brand_id AND p.deleted_at IS NULL
    LEFT JOIN order_items oi ON p.id = oi.product_id
    LEFT JOIN product_reviews pr ON p.id = pr.product_id
    WHERE b.store_id = p_store_id
    AND b.deleted_at IS NULL
    GROUP BY b.id, b.brand_name, b.brand_slug, b.is_active, b.is_featured, b.created_at
    ORDER BY total_sales DESC, products_count DESC;
END;
$$ LANGUAGE plpgsql;

-- Function: Search brands
CREATE OR REPLACE FUNCTION search_brands(
    p_store_id UUID,
    p_search_term TEXT DEFAULT NULL,
    p_is_active BOOLEAN DEFAULT NULL,
    p_is_featured BOOLEAN DEFAULT NULL,
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    brand_id UUID,
    brand_name VARCHAR(255),
    brand_slug VARCHAR(255),
    brand_description TEXT,
    brand_logo_url TEXT,
    is_active BOOLEAN,
    is_featured BOOLEAN,
    products_count INTEGER,
    total_sales_amount DECIMAL(15,4),
    average_rating DECIMAL(3,2),
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        b.id,
        b.brand_name,
        b.brand_slug,
        b.brand_description,
        b.brand_logo_url,
        b.is_active,
        b.is_featured,
        b.products_count,
        b.total_sales_amount,
        b.average_rating,
        b.created_at
    FROM brands b
    WHERE b.store_id = p_store_id
    AND b.deleted_at IS NULL
    AND (p_search_term IS NULL OR (
        b.brand_name ILIKE '%' || p_search_term || '%' OR
        b.brand_description ILIKE '%' || p_search_term || '%' OR
        p_search_term = ANY(b.tags_array)
    ))
    AND (p_is_active IS NULL OR b.is_active = p_is_active)
    AND (p_is_featured IS NULL OR b.is_featured = p_is_featured)
    ORDER BY 
        CASE WHEN p_is_featured = TRUE THEN b.is_featured END DESC,
        b.total_sales_amount DESC,
        b.products_count DESC,
        b.brand_name ASC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql;

-- Function: Update brand metrics from products
CREATE OR REPLACE FUNCTION update_brand_metrics_from_products(p_brand_id UUID)
RETURNS VOID AS $$
DECLARE
    brand_stats RECORD;
BEGIN
    -- Get calculated statistics
    SELECT * INTO brand_stats FROM get_brand_stats(p_brand_id);
    
    -- Update brand with calculated metrics
    UPDATE brands
    SET 
        products_count = brand_stats.products_count,
        total_sales_amount = brand_stats.total_sales,
        total_orders_count = brand_stats.total_orders,
        average_rating = brand_stats.average_rating,
        reviews_count = brand_stats.reviews_count,
        monthly_sales = brand_stats.monthly_sales,
        monthly_orders = brand_stats.monthly_orders,
        conversion_rate = brand_stats.conversion_rate,
        return_rate = brand_stats.return_rate,
        updated_at = NOW()
    WHERE id = p_brand_id;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Comments
-- =============================================================================

COMMENT ON TABLE brands IS 'Brand information and management for products';
COMMENT ON COLUMN brands.id IS 'Primary key for the brand';
COMMENT ON COLUMN brands.salla_brand_id IS 'Unique identifier from Salla API';
COMMENT ON COLUMN brands.store_id IS 'Reference to the store this brand belongs to';
COMMENT ON COLUMN brands.brand_name IS 'Name of the brand';
COMMENT ON COLUMN brands.brand_slug IS 'URL-friendly version of brand name';
COMMENT ON COLUMN brands.brand_description IS 'Detailed description of the brand';
COMMENT ON COLUMN brands.brand_logo_url IS 'URL to the brand logo image';
COMMENT ON COLUMN brands.social_media IS 'JSON object containing social media links';
COMMENT ON COLUMN brands.is_active IS 'Whether the brand is currently active';
COMMENT ON COLUMN brands.is_featured IS 'Whether the brand is featured';
COMMENT ON COLUMN brands.products_count IS 'Number of products associated with this brand';
COMMENT ON COLUMN brands.total_sales_amount IS 'Total sales amount for this brand';
COMMENT ON COLUMN brands.average_rating IS 'Average rating of products from this brand';
COMMENT ON COLUMN brands.metadata IS 'Additional metadata in JSON format';
COMMENT ON COLUMN brands.created_at IS 'Timestamp when the brand was created';
COMMENT ON COLUMN brands.updated_at IS 'Timestamp when the brand was last updated';

COMMENT ON FUNCTION get_brand_stats(UUID) IS 'Returns comprehensive statistics for a specific brand';
COMMENT ON FUNCTION get_store_brands_stats(UUID) IS 'Returns statistics for all brands in a store';
COMMENT ON FUNCTION search_brands(UUID, TEXT, BOOLEAN, BOOLEAN, INTEGER, INTEGER) IS 'Search brands with filters and pagination';
COMMENT ON FUNCTION update_brand_metrics_from_products(UUID) IS 'Updates brand metrics based on associated products and orders';