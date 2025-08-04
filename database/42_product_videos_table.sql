-- =============================================================================
-- Product Videos Table
-- =============================================================================
-- This table stores product videos separately from the main products table
-- Normalizes the 'videos' JSONB column from products table

CREATE TABLE IF NOT EXISTS product_videos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Video information
    video_url TEXT NOT NULL,
    title VARCHAR(255),
    description TEXT,
    
    -- Video properties
    video_type VARCHAR(20) DEFAULT 'mp4' CHECK (video_type IN ('mp4', 'webm', 'ogg', 'youtube', 'vimeo', 'embed')),
    duration_seconds INTEGER,
    file_size BIGINT, -- in bytes
    
    -- Video quality and dimensions
    width INTEGER,
    height INTEGER,
    resolution VARCHAR(20), -- 720p, 1080p, 4K, etc.
    bitrate INTEGER, -- in kbps
    frame_rate DECIMAL(5,2), -- fps
    
    -- Thumbnail and preview
    thumbnail_url TEXT,
    preview_url TEXT, -- Short preview/teaser
    poster_image_url TEXT,
    
    -- Video metadata
    is_main BOOLEAN DEFAULT FALSE,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    
    -- Video hosting
    hosting_platform VARCHAR(50), -- youtube, vimeo, self_hosted, cdn
    external_video_id VARCHAR(255), -- YouTube/Vimeo video ID
    embed_code TEXT,
    
    -- Video optimization
    is_optimized BOOLEAN DEFAULT FALSE,
    compression_ratio DECIMAL(5,2),
    optimization_score DECIMAL(3,2),
    
    -- Video analytics
    view_count INTEGER DEFAULT 0,
    play_count INTEGER DEFAULT 0,
    completion_rate DECIMAL(5,4) DEFAULT 0, -- Percentage of video watched
    engagement_score DECIMAL(5,4) DEFAULT 0,
    
    -- Video status and moderation
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'processing', 'failed', 'pending_review')),
    processing_status VARCHAR(20) DEFAULT 'completed' CHECK (processing_status IN ('pending', 'processing', 'completed', 'failed')),
    moderation_status VARCHAR(20) DEFAULT 'approved' CHECK (moderation_status IN ('pending', 'approved', 'rejected', 'flagged')),
    moderation_notes TEXT,
    
    -- Accessibility
    has_captions BOOLEAN DEFAULT FALSE,
    has_audio_description BOOLEAN DEFAULT FALSE,
    caption_languages TEXT[], -- Array of language codes
    
    -- SEO and marketing
    alt_text VARCHAR(255),
    caption TEXT,
    tags TEXT[],
    keywords TEXT[],
    
    -- Technical details
    original_filename VARCHAR(255),
    cdn_url TEXT,
    streaming_url TEXT,
    download_url TEXT,
    
    -- Video variants (different qualities)
    video_variants JSONB DEFAULT '[]', -- [{"quality": "720p", "url": "...", "size": 123456}]
    
    -- External references
    salla_video_id VARCHAR(100),
    external_id VARCHAR(100),
    
    -- Sync information
    sync_status VARCHAR(20) DEFAULT 'synced' CHECK (sync_status IN ('pending', 'syncing', 'synced', 'error')),
    last_sync_at TIMESTAMPTZ,
    sync_errors JSONB DEFAULT '[]',
    
    -- Custom fields
    custom_fields JSONB DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    uploaded_at TIMESTAMPTZ,
    published_at TIMESTAMPTZ,
    
    -- Constraints
    CONSTRAINT product_videos_sort_order_check CHECK (sort_order >= 0),
    CONSTRAINT product_videos_duration_check CHECK (duration_seconds IS NULL OR duration_seconds > 0),
    CONSTRAINT product_videos_dimensions_check CHECK (
        (width IS NULL AND height IS NULL) OR (width > 0 AND height > 0)
    ),
    CONSTRAINT product_videos_file_size_check CHECK (file_size IS NULL OR file_size > 0),
    CONSTRAINT product_videos_bitrate_check CHECK (bitrate IS NULL OR bitrate > 0),
    CONSTRAINT product_videos_frame_rate_check CHECK (frame_rate IS NULL OR frame_rate > 0),
    CONSTRAINT product_videos_completion_rate_check CHECK (completion_rate >= 0 AND completion_rate <= 1),
    CONSTRAINT product_videos_engagement_score_check CHECK (engagement_score >= 0 AND engagement_score <= 1),
    CONSTRAINT product_videos_optimization_score_check CHECK (optimization_score IS NULL OR (optimization_score >= 0 AND optimization_score <= 5))
);

-- =============================================================================
-- Indexes
-- =============================================================================

-- Primary indexes
CREATE INDEX IF NOT EXISTS idx_product_videos_product_id ON product_videos(product_id);
CREATE INDEX IF NOT EXISTS idx_product_videos_store_id ON product_videos(store_id);
CREATE INDEX IF NOT EXISTS idx_product_videos_salla_video_id ON product_videos(salla_video_id);
CREATE INDEX IF NOT EXISTS idx_product_videos_external_video_id ON product_videos(external_video_id);

-- Status and filtering indexes
CREATE INDEX IF NOT EXISTS idx_product_videos_status ON product_videos(status);
CREATE INDEX IF NOT EXISTS idx_product_videos_is_active ON product_videos(is_active);
CREATE INDEX IF NOT EXISTS idx_product_videos_is_main ON product_videos(is_main);
CREATE INDEX IF NOT EXISTS idx_product_videos_is_featured ON product_videos(is_featured);
CREATE INDEX IF NOT EXISTS idx_product_videos_processing_status ON product_videos(processing_status);
CREATE INDEX IF NOT EXISTS idx_product_videos_moderation_status ON product_videos(moderation_status);

-- Sorting and ordering indexes
CREATE INDEX IF NOT EXISTS idx_product_videos_sort_order ON product_videos(sort_order);
CREATE INDEX IF NOT EXISTS idx_product_videos_product_sort ON product_videos(product_id, sort_order);

-- Video properties indexes
CREATE INDEX IF NOT EXISTS idx_product_videos_video_type ON product_videos(video_type);
CREATE INDEX IF NOT EXISTS idx_product_videos_hosting_platform ON product_videos(hosting_platform);
CREATE INDEX IF NOT EXISTS idx_product_videos_duration ON product_videos(duration_seconds);
CREATE INDEX IF NOT EXISTS idx_product_videos_resolution ON product_videos(resolution);

-- Analytics indexes
CREATE INDEX IF NOT EXISTS idx_product_videos_view_count ON product_videos(view_count DESC);
CREATE INDEX IF NOT EXISTS idx_product_videos_play_count ON product_videos(play_count DESC);
CREATE INDEX IF NOT EXISTS idx_product_videos_completion_rate ON product_videos(completion_rate DESC);
CREATE INDEX IF NOT EXISTS idx_product_videos_engagement_score ON product_videos(engagement_score DESC);

-- Accessibility indexes
CREATE INDEX IF NOT EXISTS idx_product_videos_has_captions ON product_videos(has_captions);
CREATE INDEX IF NOT EXISTS idx_product_videos_caption_languages ON product_videos USING gin(caption_languages);

-- Sync indexes
CREATE INDEX IF NOT EXISTS idx_product_videos_sync_status ON product_videos(sync_status);
CREATE INDEX IF NOT EXISTS idx_product_videos_last_sync_at ON product_videos(last_sync_at);

-- Timestamp indexes
CREATE INDEX IF NOT EXISTS idx_product_videos_created_at ON product_videos(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_product_videos_updated_at ON product_videos(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_product_videos_published_at ON product_videos(published_at DESC);

-- JSONB indexes
CREATE INDEX IF NOT EXISTS idx_product_videos_video_variants ON product_videos USING gin(video_variants);
CREATE INDEX IF NOT EXISTS idx_product_videos_custom_fields ON product_videos USING gin(custom_fields);
CREATE INDEX IF NOT EXISTS idx_product_videos_sync_errors ON product_videos USING gin(sync_errors);

-- Array indexes
CREATE INDEX IF NOT EXISTS idx_product_videos_tags ON product_videos USING gin(tags);
CREATE INDEX IF NOT EXISTS idx_product_videos_keywords ON product_videos USING gin(keywords);

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_product_videos_product_active_sort ON product_videos(product_id, is_active, sort_order) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_product_videos_store_status ON product_videos(store_id, status, is_active);
CREATE INDEX IF NOT EXISTS idx_product_videos_main_videos ON product_videos(product_id, is_main) WHERE is_main = TRUE;
CREATE INDEX IF NOT EXISTS idx_product_videos_featured ON product_videos(is_featured, view_count DESC) WHERE is_featured = TRUE;

-- =============================================================================
-- Triggers
-- =============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_product_videos_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_product_videos_updated_at
    BEFORE UPDATE ON product_videos
    FOR EACH ROW
    EXECUTE FUNCTION update_product_videos_updated_at();

-- Ensure only one main video per product
CREATE OR REPLACE FUNCTION ensure_single_main_video()
RETURNS TRIGGER AS $$
BEGIN
    -- If setting this video as main, unset all other main videos for this product
    IF NEW.is_main = TRUE THEN
        UPDATE product_videos 
        SET is_main = FALSE 
        WHERE product_id = NEW.product_id 
          AND id != NEW.id 
          AND is_main = TRUE;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_ensure_single_main_video
    BEFORE INSERT OR UPDATE ON product_videos
    FOR EACH ROW
    EXECUTE FUNCTION ensure_single_main_video();

-- Auto-calculate video metrics
CREATE OR REPLACE FUNCTION calculate_video_metrics()
RETURNS TRIGGER AS $$
BEGIN
    -- Calculate completion rate
    IF NEW.view_count > 0 AND NEW.play_count > 0 THEN
        NEW.completion_rate = LEAST(1.0, NEW.play_count::DECIMAL / NEW.view_count);
    END IF;
    
    -- Calculate engagement score based on completion rate and view count
    IF NEW.completion_rate IS NOT NULL AND NEW.view_count > 0 THEN
        NEW.engagement_score = (NEW.completion_rate * 0.7) + 
                              (LEAST(1.0, NEW.view_count::DECIMAL / 1000) * 0.3);
    END IF;
    
    -- Calculate optimization score based on file size and quality
    IF NEW.file_size IS NOT NULL AND NEW.duration_seconds IS NOT NULL AND NEW.duration_seconds > 0 THEN
        -- Rough calculation: smaller file size per second is better
        NEW.optimization_score = GREATEST(1.0, 
            LEAST(5.0, 5.0 - (NEW.file_size::DECIMAL / (NEW.duration_seconds * 1000000))) -- MB per second
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_calculate_video_metrics
    BEFORE INSERT OR UPDATE ON product_videos
    FOR EACH ROW
    EXECUTE FUNCTION calculate_video_metrics();

-- Auto-set published_at when status becomes active
CREATE OR REPLACE FUNCTION set_video_published_at()
RETURNS TRIGGER AS $$
BEGIN
    -- Set published_at when video becomes active for the first time
    IF NEW.status = 'active' AND (OLD.status IS NULL OR OLD.status != 'active') AND NEW.published_at IS NULL THEN
        NEW.published_at = CURRENT_TIMESTAMP;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_set_video_published_at
    BEFORE INSERT OR UPDATE ON product_videos
    FOR EACH ROW
    EXECUTE FUNCTION set_video_published_at();

-- =============================================================================
-- Helper Functions
-- =============================================================================

/**
 * Get all videos for a specific product
 * @param p_product_id UUID - Product ID
 * @param p_active_only BOOLEAN - Whether to return only active videos
 * @return TABLE - Product videos ordered by sort_order
 */
CREATE OR REPLACE FUNCTION get_product_videos(
    p_product_id UUID,
    p_active_only BOOLEAN DEFAULT TRUE
)
RETURNS TABLE (
    id UUID,
    video_url TEXT,
    title VARCHAR,
    description TEXT,
    video_type VARCHAR,
    duration_seconds INTEGER,
    thumbnail_url TEXT,
    is_main BOOLEAN,
    sort_order INTEGER,
    status VARCHAR,
    view_count INTEGER,
    engagement_score DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pv.id,
        pv.video_url,
        pv.title,
        pv.description,
        pv.video_type,
        pv.duration_seconds,
        pv.thumbnail_url,
        pv.is_main,
        pv.sort_order,
        pv.status,
        pv.view_count,
        pv.engagement_score
    FROM product_videos pv
    WHERE pv.product_id = p_product_id
      AND (NOT p_active_only OR pv.is_active = TRUE)
    ORDER BY pv.is_main DESC, pv.sort_order ASC, pv.created_at ASC;
END;
$$ LANGUAGE plpgsql;

/**
 * Get main video for a product
 * @param p_product_id UUID - Product ID
 * @return TABLE - Main product video
 */
CREATE OR REPLACE FUNCTION get_product_main_video(
    p_product_id UUID
)
RETURNS TABLE (
    id UUID,
    video_url TEXT,
    title VARCHAR,
    description TEXT,
    video_type VARCHAR,
    duration_seconds INTEGER,
    thumbnail_url TEXT,
    poster_image_url TEXT,
    embed_code TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pv.id,
        pv.video_url,
        pv.title,
        pv.description,
        pv.video_type,
        pv.duration_seconds,
        pv.thumbnail_url,
        pv.poster_image_url,
        pv.embed_code
    FROM product_videos pv
    WHERE pv.product_id = p_product_id
      AND pv.is_main = TRUE
      AND pv.is_active = TRUE
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

/**
 * Update video sort order
 * @param p_product_id UUID - Product ID
 * @param p_video_orders JSONB - Array of {"id": "uuid", "sort_order": number}
 * @return BOOLEAN - Success status
 */
CREATE OR REPLACE FUNCTION update_video_sort_order(
    p_product_id UUID,
    p_video_orders JSONB
)
RETURNS BOOLEAN AS $$
DECLARE
    video_order JSONB;
BEGIN
    -- Update sort order for each video
    FOR video_order IN SELECT * FROM jsonb_array_elements(p_video_orders)
    LOOP
        UPDATE product_videos 
        SET sort_order = (video_order->>'sort_order')::INTEGER,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = (video_order->>'id')::UUID
          AND product_id = p_product_id;
    END LOOP;
    
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

/**
 * Record video view
 * @param p_video_id UUID - Video ID
 * @param p_completion_percentage DECIMAL - How much of the video was watched (0-1)
 * @return BOOLEAN - Success status
 */
CREATE OR REPLACE FUNCTION record_video_view(
    p_video_id UUID,
    p_completion_percentage DECIMAL DEFAULT 0
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE product_videos
    SET view_count = view_count + 1,
        play_count = play_count + CASE WHEN p_completion_percentage >= 0.1 THEN 1 ELSE 0 END,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_video_id;
    
    -- TODO: Log detailed view analytics in video_analytics table
    
    RETURN FOUND;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

/**
 * Get video statistics for a product
 * @param p_product_id UUID - Product ID
 * @return JSONB - Video statistics
 */
CREATE OR REPLACE FUNCTION get_product_video_stats(
    p_product_id UUID
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_videos', COUNT(*),
        'active_videos', COUNT(*) FILTER (WHERE is_active = TRUE),
        'main_video_set', COUNT(*) FILTER (WHERE is_main = TRUE) > 0,
        'total_duration', COALESCE(SUM(duration_seconds), 0),
        'total_file_size', COALESCE(SUM(file_size), 0),
        'average_duration', AVG(duration_seconds) FILTER (WHERE duration_seconds IS NOT NULL),
        'total_views', COALESCE(SUM(view_count), 0),
        'total_plays', COALESCE(SUM(play_count), 0),
        'average_completion_rate', AVG(completion_rate) FILTER (WHERE completion_rate > 0),
        'average_engagement_score', AVG(engagement_score) FILTER (WHERE engagement_score > 0),
        'video_types_distribution', (
            SELECT jsonb_object_agg(video_type, type_count)
            FROM (
                SELECT video_type, COUNT(*) as type_count
                FROM product_videos
                WHERE product_id = p_product_id
                GROUP BY video_type
            ) type_stats
        ),
        'hosting_platforms_distribution', (
            SELECT jsonb_object_agg(hosting_platform, platform_count)
            FROM (
                SELECT hosting_platform, COUNT(*) as platform_count
                FROM product_videos
                WHERE product_id = p_product_id AND hosting_platform IS NOT NULL
                GROUP BY hosting_platform
            ) platform_stats
        ),
        'accessibility_stats', jsonb_build_object(
            'videos_with_captions', COUNT(*) FILTER (WHERE has_captions = TRUE),
            'videos_with_audio_description', COUNT(*) FILTER (WHERE has_audio_description = TRUE),
            'caption_languages', (
                SELECT array_agg(DISTINCT lang)
                FROM product_videos pv, unnest(pv.caption_languages) as lang
                WHERE pv.product_id = p_product_id
            )
        )
    ) INTO result
    FROM product_videos
    WHERE product_id = p_product_id;
    
    RETURN COALESCE(result, '{"error": "No videos found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

/**
 * Get featured videos across all products
 * @param p_store_id UUID - Store ID (optional)
 * @param p_limit INTEGER - Maximum number of videos to return
 * @return TABLE - Featured videos
 */
CREATE OR REPLACE FUNCTION get_featured_videos(
    p_store_id UUID DEFAULT NULL,
    p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
    video_id UUID,
    product_id UUID,
    title VARCHAR,
    thumbnail_url TEXT,
    duration_seconds INTEGER,
    view_count INTEGER,
    engagement_score DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pv.id,
        pv.product_id,
        pv.title,
        pv.thumbnail_url,
        pv.duration_seconds,
        pv.view_count,
        pv.engagement_score
    FROM product_videos pv
    WHERE pv.is_featured = TRUE
      AND pv.is_active = TRUE
      AND pv.status = 'active'
      AND (p_store_id IS NULL OR pv.store_id = p_store_id)
    ORDER BY pv.engagement_score DESC, pv.view_count DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Comments
-- =============================================================================

COMMENT ON TABLE product_videos IS 'Normalized table for product videos, extracted from products.videos JSONB column';
COMMENT ON COLUMN product_videos.product_id IS 'Reference to the parent product';
COMMENT ON COLUMN product_videos.video_url IS 'Full URL to the video file or external video';
COMMENT ON COLUMN product_videos.video_type IS 'Type of video file or hosting platform';
COMMENT ON COLUMN product_videos.is_main IS 'Whether this is the main/primary video for the product';
COMMENT ON COLUMN product_videos.completion_rate IS 'Percentage of viewers who watch the entire video';
COMMENT ON COLUMN product_videos.engagement_score IS 'Calculated engagement score based on views and completion';
COMMENT ON COLUMN product_videos.video_variants IS 'Different quality versions of the same video';
COMMENT ON COLUMN product_videos.caption_languages IS 'Array of language codes for available captions';

COMMENT ON FUNCTION get_product_videos(UUID, BOOLEAN) IS 'Get all videos for a product with optional active filter';
COMMENT ON FUNCTION get_product_main_video(UUID) IS 'Get the main video for a product';
COMMENT ON FUNCTION update_video_sort_order(UUID, JSONB) IS 'Update sort order for multiple videos';
COMMENT ON FUNCTION record_video_view(UUID, DECIMAL) IS 'Record a video view with completion tracking';
COMMENT ON FUNCTION get_product_video_stats(UUID) IS 'Get comprehensive statistics for product videos';
COMMENT ON FUNCTION get_featured_videos(UUID, INTEGER) IS 'Get featured videos across products';