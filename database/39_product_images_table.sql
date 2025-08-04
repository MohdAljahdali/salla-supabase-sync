-- =============================================================================
-- Product Images Table
-- =============================================================================
-- This table stores product images separately from the main products table
-- Normalizes the 'images' JSONB column from products table

CREATE TABLE IF NOT EXISTS product_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Image information
    image_url TEXT NOT NULL,
    alt_text VARCHAR(255),
    title VARCHAR(255),
    
    -- Image properties
    width INTEGER,
    height INTEGER,
    file_size BIGINT, -- in bytes
    file_format VARCHAR(10), -- jpg, png, webp, etc.
    
    -- Image metadata
    is_main BOOLEAN DEFAULT FALSE,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- SEO and accessibility
    caption TEXT,
    description TEXT,
    
    -- Technical details
    original_filename VARCHAR(255),
    cdn_url TEXT,
    thumbnail_url TEXT,
    medium_url TEXT,
    large_url TEXT,
    
    -- Image optimization
    is_optimized BOOLEAN DEFAULT FALSE,
    optimization_score DECIMAL(3,2),
    compression_ratio DECIMAL(5,2),
    
    -- Image analytics
    view_count INTEGER DEFAULT 0,
    click_count INTEGER DEFAULT 0,
    conversion_rate DECIMAL(5,4) DEFAULT 0,
    
    -- Image status and moderation
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'processing', 'failed', 'pending_review')),
    moderation_status VARCHAR(20) DEFAULT 'approved' CHECK (moderation_status IN ('pending', 'approved', 'rejected', 'flagged')),
    moderation_notes TEXT,
    
    -- External references
    salla_image_id VARCHAR(100),
    external_id VARCHAR(100),
    
    -- Sync information
    sync_status VARCHAR(20) DEFAULT 'synced' CHECK (sync_status IN ('pending', 'syncing', 'synced', 'error')),
    last_sync_at TIMESTAMPTZ,
    sync_errors JSONB DEFAULT '[]',
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    uploaded_at TIMESTAMPTZ,
    
    -- Constraints
    CONSTRAINT product_images_sort_order_check CHECK (sort_order >= 0),
    CONSTRAINT product_images_dimensions_check CHECK (width > 0 AND height > 0),
    CONSTRAINT product_images_file_size_check CHECK (file_size > 0),
    CONSTRAINT product_images_optimization_score_check CHECK (optimization_score >= 0 AND optimization_score <= 1),
    CONSTRAINT product_images_conversion_rate_check CHECK (conversion_rate >= 0 AND conversion_rate <= 1)
);

-- =============================================================================
-- Indexes
-- =============================================================================

-- Primary indexes
CREATE INDEX IF NOT EXISTS idx_product_images_product_id ON product_images(product_id);
CREATE INDEX IF NOT EXISTS idx_product_images_store_id ON product_images(store_id);
CREATE INDEX IF NOT EXISTS idx_product_images_salla_image_id ON product_images(salla_image_id);

-- Status and filtering indexes
CREATE INDEX IF NOT EXISTS idx_product_images_status ON product_images(status);
CREATE INDEX IF NOT EXISTS idx_product_images_is_active ON product_images(is_active);
CREATE INDEX IF NOT EXISTS idx_product_images_is_main ON product_images(is_main);
CREATE INDEX IF NOT EXISTS idx_product_images_moderation_status ON product_images(moderation_status);

-- Sorting and ordering indexes
CREATE INDEX IF NOT EXISTS idx_product_images_sort_order ON product_images(sort_order);
CREATE INDEX IF NOT EXISTS idx_product_images_product_sort ON product_images(product_id, sort_order);

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_product_images_file_format ON product_images(file_format);
CREATE INDEX IF NOT EXISTS idx_product_images_file_size ON product_images(file_size);
CREATE INDEX IF NOT EXISTS idx_product_images_dimensions ON product_images(width, height);

-- Analytics indexes
CREATE INDEX IF NOT EXISTS idx_product_images_view_count ON product_images(view_count DESC);
CREATE INDEX IF NOT EXISTS idx_product_images_conversion_rate ON product_images(conversion_rate DESC);

-- Sync indexes
CREATE INDEX IF NOT EXISTS idx_product_images_sync_status ON product_images(sync_status);
CREATE INDEX IF NOT EXISTS idx_product_images_last_sync_at ON product_images(last_sync_at);

-- Timestamp indexes
CREATE INDEX IF NOT EXISTS idx_product_images_created_at ON product_images(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_product_images_updated_at ON product_images(updated_at DESC);

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_product_images_product_active_sort ON product_images(product_id, is_active, sort_order) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_product_images_store_status ON product_images(store_id, status, is_active);
CREATE INDEX IF NOT EXISTS idx_product_images_main_images ON product_images(product_id, is_main) WHERE is_main = TRUE;

-- JSONB indexes
CREATE INDEX IF NOT EXISTS idx_product_images_sync_errors ON product_images USING gin(sync_errors);

-- =============================================================================
-- Triggers
-- =============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_product_images_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_product_images_updated_at
    BEFORE UPDATE ON product_images
    FOR EACH ROW
    EXECUTE FUNCTION update_product_images_updated_at();

-- Ensure only one main image per product
CREATE OR REPLACE FUNCTION ensure_single_main_image()
RETURNS TRIGGER AS $$
BEGIN
    -- If setting this image as main, unset all other main images for this product
    IF NEW.is_main = TRUE THEN
        UPDATE product_images 
        SET is_main = FALSE 
        WHERE product_id = NEW.product_id 
          AND id != NEW.id 
          AND is_main = TRUE;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_ensure_single_main_image
    BEFORE INSERT OR UPDATE ON product_images
    FOR EACH ROW
    EXECUTE FUNCTION ensure_single_main_image();

-- Auto-calculate optimization metrics
CREATE OR REPLACE FUNCTION calculate_image_metrics()
RETURNS TRIGGER AS $$
BEGIN
    -- Calculate optimization score based on file size and dimensions
    IF NEW.file_size IS NOT NULL AND NEW.width IS NOT NULL AND NEW.height IS NOT NULL THEN
        NEW.optimization_score = LEAST(1.0, 
            GREATEST(0.0, 1.0 - (NEW.file_size::DECIMAL / (NEW.width * NEW.height * 3)))  -- Rough calculation
        );
    END IF;
    
    -- Calculate conversion rate if we have click and view data
    IF NEW.view_count > 0 THEN
        NEW.conversion_rate = NEW.click_count::DECIMAL / NEW.view_count;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_calculate_image_metrics
    BEFORE INSERT OR UPDATE ON product_images
    FOR EACH ROW
    EXECUTE FUNCTION calculate_image_metrics();

-- =============================================================================
-- Helper Functions
-- =============================================================================

/**
 * Get all images for a specific product
 * @param p_product_id UUID - Product ID
 * @param p_active_only BOOLEAN - Whether to return only active images
 * @return TABLE - Product images ordered by sort_order
 */
CREATE OR REPLACE FUNCTION get_product_images(
    p_product_id UUID,
    p_active_only BOOLEAN DEFAULT TRUE
)
RETURNS TABLE (
    id UUID,
    image_url TEXT,
    alt_text VARCHAR,
    title VARCHAR,
    width INTEGER,
    height INTEGER,
    is_main BOOLEAN,
    sort_order INTEGER,
    status VARCHAR,
    thumbnail_url TEXT,
    medium_url TEXT,
    large_url TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pi.id,
        pi.image_url,
        pi.alt_text,
        pi.title,
        pi.width,
        pi.height,
        pi.is_main,
        pi.sort_order,
        pi.status,
        pi.thumbnail_url,
        pi.medium_url,
        pi.large_url
    FROM product_images pi
    WHERE pi.product_id = p_product_id
      AND (NOT p_active_only OR pi.is_active = TRUE)
    ORDER BY pi.is_main DESC, pi.sort_order ASC, pi.created_at ASC;
END;
$$ LANGUAGE plpgsql;

/**
 * Get main image for a product
 * @param p_product_id UUID - Product ID
 * @return TABLE - Main product image
 */
CREATE OR REPLACE FUNCTION get_product_main_image(
    p_product_id UUID
)
RETURNS TABLE (
    id UUID,
    image_url TEXT,
    alt_text VARCHAR,
    title VARCHAR,
    width INTEGER,
    height INTEGER,
    thumbnail_url TEXT,
    medium_url TEXT,
    large_url TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pi.id,
        pi.image_url,
        pi.alt_text,
        pi.title,
        pi.width,
        pi.height,
        pi.thumbnail_url,
        pi.medium_url,
        pi.large_url
    FROM product_images pi
    WHERE pi.product_id = p_product_id
      AND pi.is_main = TRUE
      AND pi.is_active = TRUE
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

/**
 * Update image sort order
 * @param p_product_id UUID - Product ID
 * @param p_image_orders JSONB - Array of {"id": "uuid", "sort_order": number}
 * @return BOOLEAN - Success status
 */
CREATE OR REPLACE FUNCTION update_image_sort_order(
    p_product_id UUID,
    p_image_orders JSONB
)
RETURNS BOOLEAN AS $$
DECLARE
    image_order JSONB;
BEGIN
    -- Update sort order for each image
    FOR image_order IN SELECT * FROM jsonb_array_elements(p_image_orders)
    LOOP
        UPDATE product_images 
        SET sort_order = (image_order->>'sort_order')::INTEGER,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = (image_order->>'id')::UUID
          AND product_id = p_product_id;
    END LOOP;
    
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

/**
 * Get image statistics for a product
 * @param p_product_id UUID - Product ID
 * @return JSONB - Image statistics
 */
CREATE OR REPLACE FUNCTION get_product_image_stats(
    p_product_id UUID
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_images', COUNT(*),
        'active_images', COUNT(*) FILTER (WHERE is_active = TRUE),
        'main_image_set', COUNT(*) FILTER (WHERE is_main = TRUE) > 0,
        'total_file_size', COALESCE(SUM(file_size), 0),
        'average_optimization_score', AVG(optimization_score) FILTER (WHERE optimization_score IS NOT NULL),
        'total_views', COALESCE(SUM(view_count), 0),
        'total_clicks', COALESCE(SUM(click_count), 0),
        'average_conversion_rate', AVG(conversion_rate) FILTER (WHERE conversion_rate > 0),
        'formats_distribution', (
            SELECT jsonb_object_agg(file_format, format_count)
            FROM (
                SELECT file_format, COUNT(*) as format_count
                FROM product_images
                WHERE product_id = p_product_id AND file_format IS NOT NULL
                GROUP BY file_format
            ) format_stats
        )
    ) INTO result
    FROM product_images
    WHERE product_id = p_product_id;
    
    RETURN COALESCE(result, '{"error": "No images found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Comments
-- =============================================================================

COMMENT ON TABLE product_images IS 'Normalized table for product images, extracted from products.images JSONB column';
COMMENT ON COLUMN product_images.product_id IS 'Reference to the parent product';
COMMENT ON COLUMN product_images.image_url IS 'Full URL to the image file';
COMMENT ON COLUMN product_images.is_main IS 'Whether this is the main/primary image for the product';
COMMENT ON COLUMN product_images.sort_order IS 'Display order of images (0 = first)';
COMMENT ON COLUMN product_images.optimization_score IS 'Image optimization score (0-1, higher is better)';
COMMENT ON COLUMN product_images.conversion_rate IS 'Click-through rate for this image';
COMMENT ON COLUMN product_images.sync_status IS 'Synchronization status with external systems';

COMMENT ON FUNCTION get_product_images(UUID, BOOLEAN) IS 'Get all images for a product with optional active filter';
COMMENT ON FUNCTION get_product_main_image(UUID) IS 'Get the main image for a product';
COMMENT ON FUNCTION update_image_sort_order(UUID, JSONB) IS 'Update sort order for multiple images';
COMMENT ON FUNCTION get_product_image_stats(UUID) IS 'Get comprehensive statistics for product images';