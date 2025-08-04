-- =============================================================================
-- Tags Table
-- =============================================================================
-- This table stores tags for products, orders, and content classification
-- Tags help organize and categorize content for better searchability

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create tags table
CREATE TABLE IF NOT EXISTS tags (
    -- Primary identification
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Salla API identifiers
    salla_tag_id VARCHAR(100) UNIQUE,
    salla_store_id VARCHAR(100),
    
    -- Store relationship
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Tag identification
    tag_name VARCHAR(255) NOT NULL,
    tag_slug VARCHAR(255),
    tag_code VARCHAR(100),
    
    -- Tag description and details
    tag_description TEXT,
    tag_purpose TEXT,
    tag_usage_notes TEXT,
    
    -- Tag type and category
    tag_type VARCHAR(50) DEFAULT 'general', -- general, product, order, customer, content, marketing, system
    tag_category VARCHAR(100),
    tag_group VARCHAR(100),
    
    -- Tag hierarchy and relationships
    parent_tag_id UUID REFERENCES tags(id) ON DELETE SET NULL,
    tag_level INTEGER DEFAULT 0,
    tag_path TEXT, -- Hierarchical path like "parent/child/grandchild"
    
    -- Tag appearance and styling
    tag_color VARCHAR(7), -- Hex color code
    tag_background_color VARCHAR(7),
    tag_icon VARCHAR(100),
    tag_emoji VARCHAR(10),
    
    -- Tag status and visibility
    is_active BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    is_system BOOLEAN DEFAULT FALSE, -- System-generated tags
    tag_status VARCHAR(50) DEFAULT 'active', -- active, inactive, archived, deprecated
    visibility VARCHAR(50) DEFAULT 'public', -- public, private, internal
    
    -- Tag usage and statistics
    usage_count INTEGER DEFAULT 0,
    products_count INTEGER DEFAULT 0,
    orders_count INTEGER DEFAULT 0,
    customers_count INTEGER DEFAULT 0,
    content_count INTEGER DEFAULT 0,
    
    -- Tag performance metrics
    click_count INTEGER DEFAULT 0,
    search_count INTEGER DEFAULT 0,
    conversion_rate DECIMAL(5,4) DEFAULT 0,
    engagement_score DECIMAL(8,4) DEFAULT 0,
    
    -- Tag settings and configuration
    tag_settings JSONB DEFAULT '{}',
    display_settings JSONB DEFAULT '{}',
    search_settings JSONB DEFAULT '{}',
    
    -- Tag rules and automation
    auto_assignment_rules JSONB DEFAULT '[]',
    tag_conditions JSONB DEFAULT '{}',
    tag_triggers JSONB DEFAULT '[]',
    
    -- SEO and marketing
    meta_title VARCHAR(255),
    meta_description TEXT,
    meta_keywords TEXT,
    seo_url VARCHAR(500),
    
    -- Tag relationships and associations
    related_tags JSONB DEFAULT '[]', -- Array of related tag IDs
    synonym_tags JSONB DEFAULT '[]', -- Array of synonym tag names
    excluded_tags JSONB DEFAULT '[]', -- Tags that cannot be used together
    
    -- Tag content and media
    tag_image_url TEXT,
    tag_banner_url TEXT,
    tag_content TEXT,
    tag_summary TEXT,
    
    -- Tag localization
    translations JSONB DEFAULT '{}', -- {"en": {"name": "...", "description": "..."}, "ar": {...}}
    default_language VARCHAR(5) DEFAULT 'en',
    
    -- Tag analytics and tracking
    analytics_data JSONB DEFAULT '{}',
    tracking_settings JSONB DEFAULT '{}',
    performance_metrics JSONB DEFAULT '{}',
    
    -- Tag moderation and approval
    is_approved BOOLEAN DEFAULT TRUE,
    approval_status VARCHAR(50) DEFAULT 'approved', -- pending, approved, rejected
    approved_by UUID REFERENCES users(id) ON DELETE SET NULL,
    approved_at TIMESTAMPTZ,
    rejection_reason TEXT,
    
    -- Tag suggestions and recommendations
    suggested_by UUID REFERENCES users(id) ON DELETE SET NULL,
    suggestion_score DECIMAL(5,4) DEFAULT 0,
    auto_generated BOOLEAN DEFAULT FALSE,
    
    -- Tag lifecycle management
    first_used_at TIMESTAMPTZ,
    last_used_at TIMESTAMPTZ,
    peak_usage_date TIMESTAMPTZ,
    peak_usage_count INTEGER DEFAULT 0,
    
    -- Tag quality and validation
    quality_score DECIMAL(5,4) DEFAULT 0,
    validation_status VARCHAR(50) DEFAULT 'valid', -- valid, invalid, needs_review
    validation_errors JSONB DEFAULT '[]',
    
    -- Integration and sync
    integration_settings JSONB DEFAULT '{}',
    sync_status VARCHAR(50) DEFAULT 'pending',
    last_sync_at TIMESTAMPTZ,
    sync_errors JSONB DEFAULT '[]',
    
    -- API and external references
    external_references JSONB DEFAULT '{}',
    api_settings JSONB DEFAULT '{}',
    
    -- Metadata and custom fields
    metadata JSONB DEFAULT '{}',
    custom_fields JSONB DEFAULT '{}',
    attributes JSONB DEFAULT '{}',
    
    -- Internal management
    internal_notes TEXT,
    admin_comments TEXT,
    maintenance_notes TEXT,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    
    -- Constraints
    CONSTRAINT tags_tag_name_store_unique UNIQUE(tag_name, store_id),
    CONSTRAINT tags_tag_slug_store_unique UNIQUE(tag_slug, store_id),
    CONSTRAINT tags_tag_code_store_unique UNIQUE(tag_code, store_id),
    CONSTRAINT tags_tag_type_check CHECK (tag_type IN ('general', 'product', 'order', 'customer', 'content', 'marketing', 'system')),
    CONSTRAINT tags_tag_status_check CHECK (tag_status IN ('active', 'inactive', 'archived', 'deprecated')),
    CONSTRAINT tags_visibility_check CHECK (visibility IN ('public', 'private', 'internal')),
    CONSTRAINT tags_approval_status_check CHECK (approval_status IN ('pending', 'approved', 'rejected')),
    CONSTRAINT tags_validation_status_check CHECK (validation_status IN ('valid', 'invalid', 'needs_review')),
    CONSTRAINT tags_sync_status_check CHECK (sync_status IN ('pending', 'syncing', 'synced', 'error')),
    CONSTRAINT tags_tag_level_check CHECK (tag_level >= 0),
    CONSTRAINT tags_usage_count_check CHECK (usage_count >= 0),
    CONSTRAINT tags_conversion_rate_check CHECK (conversion_rate >= 0 AND conversion_rate <= 1),
    CONSTRAINT tags_quality_score_check CHECK (quality_score >= 0 AND quality_score <= 1),
    CONSTRAINT tags_suggestion_score_check CHECK (suggestion_score >= 0 AND suggestion_score <= 1)
);

-- =============================================================================
-- Indexes
-- =============================================================================

-- Primary indexes
CREATE INDEX IF NOT EXISTS idx_tags_store_id ON tags(store_id);
CREATE INDEX IF NOT EXISTS idx_tags_salla_tag_id ON tags(salla_tag_id);
CREATE INDEX IF NOT EXISTS idx_tags_salla_store_id ON tags(salla_store_id);

-- Search and filtering indexes
CREATE INDEX IF NOT EXISTS idx_tags_tag_name ON tags(tag_name);
CREATE INDEX IF NOT EXISTS idx_tags_tag_slug ON tags(tag_slug);
CREATE INDEX IF NOT EXISTS idx_tags_tag_code ON tags(tag_code);
CREATE INDEX IF NOT EXISTS idx_tags_tag_type ON tags(tag_type);
CREATE INDEX IF NOT EXISTS idx_tags_tag_category ON tags(tag_category);
CREATE INDEX IF NOT EXISTS idx_tags_tag_group ON tags(tag_group);
CREATE INDEX IF NOT EXISTS idx_tags_tag_status ON tags(tag_status);
CREATE INDEX IF NOT EXISTS idx_tags_visibility ON tags(visibility);
CREATE INDEX IF NOT EXISTS idx_tags_is_active ON tags(is_active);
CREATE INDEX IF NOT EXISTS idx_tags_is_featured ON tags(is_featured);
CREATE INDEX IF NOT EXISTS idx_tags_is_system ON tags(is_system);

-- Hierarchy indexes
CREATE INDEX IF NOT EXISTS idx_tags_parent_tag_id ON tags(parent_tag_id);
CREATE INDEX IF NOT EXISTS idx_tags_tag_level ON tags(tag_level);
CREATE INDEX IF NOT EXISTS idx_tags_tag_path ON tags(tag_path);

-- Usage and performance indexes
CREATE INDEX IF NOT EXISTS idx_tags_usage_count ON tags(usage_count DESC);
CREATE INDEX IF NOT EXISTS idx_tags_products_count ON tags(products_count DESC);
CREATE INDEX IF NOT EXISTS idx_tags_orders_count ON tags(orders_count DESC);
CREATE INDEX IF NOT EXISTS idx_tags_click_count ON tags(click_count DESC);
CREATE INDEX IF NOT EXISTS idx_tags_search_count ON tags(search_count DESC);
CREATE INDEX IF NOT EXISTS idx_tags_engagement_score ON tags(engagement_score DESC);

-- Quality and approval indexes
CREATE INDEX IF NOT EXISTS idx_tags_is_approved ON tags(is_approved);
CREATE INDEX IF NOT EXISTS idx_tags_approval_status ON tags(approval_status);
CREATE INDEX IF NOT EXISTS idx_tags_approved_by ON tags(approved_by);
CREATE INDEX IF NOT EXISTS idx_tags_quality_score ON tags(quality_score DESC);
CREATE INDEX IF NOT EXISTS idx_tags_validation_status ON tags(validation_status);

-- Text search indexes
CREATE INDEX IF NOT EXISTS idx_tags_name_search ON tags USING gin(tag_name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_tags_description_search ON tags USING gin(tag_description gin_trgm_ops);

-- JSONB indexes
CREATE INDEX IF NOT EXISTS idx_tags_tag_settings ON tags USING gin(tag_settings);
CREATE INDEX IF NOT EXISTS idx_tags_related_tags ON tags USING gin(related_tags);
CREATE INDEX IF NOT EXISTS idx_tags_synonym_tags ON tags USING gin(synonym_tags);
CREATE INDEX IF NOT EXISTS idx_tags_translations ON tags USING gin(translations);
CREATE INDEX IF NOT EXISTS idx_tags_metadata ON tags USING gin(metadata);
CREATE INDEX IF NOT EXISTS idx_tags_analytics_data ON tags USING gin(analytics_data);

-- Composite indexes
CREATE INDEX IF NOT EXISTS idx_tags_store_type_status ON tags(store_id, tag_type, tag_status, is_active);
CREATE INDEX IF NOT EXISTS idx_tags_store_featured ON tags(store_id, is_featured, is_active) WHERE is_featured = TRUE;
CREATE INDEX IF NOT EXISTS idx_tags_store_usage ON tags(store_id, usage_count DESC, is_active);
CREATE INDEX IF NOT EXISTS idx_tags_hierarchy ON tags(store_id, parent_tag_id, tag_level);
CREATE INDEX IF NOT EXISTS idx_tags_sync_status ON tags(sync_status, last_sync_at);

-- Timestamp indexes
CREATE INDEX IF NOT EXISTS idx_tags_created_at ON tags(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_tags_updated_at ON tags(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_tags_deleted_at ON tags(deleted_at) WHERE deleted_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_tags_last_used_at ON tags(last_used_at DESC);

-- =============================================================================
-- Triggers
-- =============================================================================

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_tags_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_tags_updated_at
    BEFORE UPDATE ON tags
    FOR EACH ROW
    EXECUTE FUNCTION update_tags_updated_at();

-- Trigger to generate tag slug
CREATE OR REPLACE FUNCTION generate_tag_slug()
RETURNS TRIGGER AS $$
BEGIN
    -- Generate slug from tag name if not provided
    IF NEW.tag_slug IS NULL OR NEW.tag_slug = '' THEN
        NEW.tag_slug = lower(regexp_replace(NEW.tag_name, '[^a-zA-Z0-9\s]', '', 'g'));
        NEW.tag_slug = regexp_replace(NEW.tag_slug, '\s+', '-', 'g');
        NEW.tag_slug = trim(both '-' from NEW.tag_slug);
    END IF;
    
    -- Ensure slug uniqueness within store
    DECLARE
        base_slug TEXT := NEW.tag_slug;
        counter INTEGER := 1;
    BEGIN
        WHILE EXISTS (
            SELECT 1 FROM tags 
            WHERE tag_slug = NEW.tag_slug 
            AND store_id = NEW.store_id 
            AND id != COALESCE(NEW.id, uuid_generate_v4())
        ) LOOP
            NEW.tag_slug = base_slug || '-' || counter;
            counter = counter + 1;
        END LOOP;
    END;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_tags_generate_slug
    BEFORE INSERT OR UPDATE ON tags
    FOR EACH ROW
    EXECUTE FUNCTION generate_tag_slug();

-- Trigger to update tag hierarchy
CREATE OR REPLACE FUNCTION update_tag_hierarchy()
RETURNS TRIGGER AS $$
DECLARE
    parent_path TEXT;
    parent_level INTEGER;
BEGIN
    -- Update tag level and path based on parent
    IF NEW.parent_tag_id IS NOT NULL THEN
        SELECT tag_level, tag_path INTO parent_level, parent_path
        FROM tags WHERE id = NEW.parent_tag_id;
        
        NEW.tag_level = COALESCE(parent_level, 0) + 1;
        NEW.tag_path = COALESCE(parent_path, '') || '/' || NEW.tag_slug;
    ELSE
        NEW.tag_level = 0;
        NEW.tag_path = NEW.tag_slug;
    END IF;
    
    -- Clean up path (remove leading slash)
    NEW.tag_path = ltrim(NEW.tag_path, '/');
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_tags_hierarchy
    BEFORE INSERT OR UPDATE ON tags
    FOR EACH ROW
    EXECUTE FUNCTION update_tag_hierarchy();

-- Trigger to update tag usage tracking
CREATE OR REPLACE FUNCTION update_tag_usage_tracking()
RETURNS TRIGGER AS $$
BEGIN
    -- Update first_used_at if this is the first usage
    IF NEW.usage_count > 0 AND OLD.usage_count = 0 THEN
        NEW.first_used_at = NOW();
    END IF;
    
    -- Always update last_used_at when usage increases
    IF NEW.usage_count > OLD.usage_count THEN
        NEW.last_used_at = NOW();
        
        -- Update peak usage if this is a new peak
        IF NEW.usage_count > NEW.peak_usage_count THEN
            NEW.peak_usage_count = NEW.usage_count;
            NEW.peak_usage_date = NOW();
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_tags_usage_tracking
    BEFORE UPDATE ON tags
    FOR EACH ROW
    EXECUTE FUNCTION update_tag_usage_tracking();

-- =============================================================================
-- Helper Functions
-- =============================================================================

-- Function: Get tag statistics
CREATE OR REPLACE FUNCTION get_tag_stats(p_tag_id UUID)
RETURNS TABLE (
    tag_id UUID,
    tag_name VARCHAR(255),
    tag_type VARCHAR(50),
    usage_count BIGINT,
    products_count BIGINT,
    orders_count BIGINT,
    customers_count BIGINT,
    click_count BIGINT,
    search_count BIGINT,
    engagement_score DECIMAL(8,4),
    quality_score DECIMAL(5,4)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.id,
        t.tag_name,
        t.tag_type,
        t.usage_count::BIGINT,
        t.products_count::BIGINT,
        t.orders_count::BIGINT,
        t.customers_count::BIGINT,
        t.click_count::BIGINT,
        t.search_count::BIGINT,
        t.engagement_score,
        t.quality_score
    FROM tags t
    WHERE t.id = p_tag_id;
END;
$$ LANGUAGE plpgsql;

-- Function: Get store tags with statistics
CREATE OR REPLACE FUNCTION get_store_tags_stats(p_store_id UUID)
RETURNS TABLE (
    tag_id UUID,
    tag_name VARCHAR(255),
    tag_slug VARCHAR(255),
    tag_type VARCHAR(50),
    tag_category VARCHAR(100),
    is_active BOOLEAN,
    is_featured BOOLEAN,
    usage_count INTEGER,
    products_count INTEGER,
    engagement_score DECIMAL(8,4),
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.id,
        t.tag_name,
        t.tag_slug,
        t.tag_type,
        t.tag_category,
        t.is_active,
        t.is_featured,
        t.usage_count,
        t.products_count,
        t.engagement_score,
        t.created_at
    FROM tags t
    WHERE t.store_id = p_store_id
    AND t.deleted_at IS NULL
    ORDER BY t.usage_count DESC, t.engagement_score DESC;
END;
$$ LANGUAGE plpgsql;

-- Function: Search tags
CREATE OR REPLACE FUNCTION search_tags(
    p_store_id UUID,
    p_search_term TEXT DEFAULT NULL,
    p_tag_type VARCHAR(50) DEFAULT NULL,
    p_tag_category VARCHAR(100) DEFAULT NULL,
    p_is_active BOOLEAN DEFAULT NULL,
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    tag_id UUID,
    tag_name VARCHAR(255),
    tag_slug VARCHAR(255),
    tag_type VARCHAR(50),
    tag_category VARCHAR(100),
    tag_description TEXT,
    tag_color VARCHAR(7),
    is_active BOOLEAN,
    is_featured BOOLEAN,
    usage_count INTEGER,
    engagement_score DECIMAL(8,4),
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.id,
        t.tag_name,
        t.tag_slug,
        t.tag_type,
        t.tag_category,
        t.tag_description,
        t.tag_color,
        t.is_active,
        t.is_featured,
        t.usage_count,
        t.engagement_score,
        t.created_at
    FROM tags t
    WHERE t.store_id = p_store_id
    AND t.deleted_at IS NULL
    AND (p_search_term IS NULL OR (
        t.tag_name ILIKE '%' || p_search_term || '%' OR
        t.tag_description ILIKE '%' || p_search_term || '%'
    ))
    AND (p_tag_type IS NULL OR t.tag_type = p_tag_type)
    AND (p_tag_category IS NULL OR t.tag_category = p_tag_category)
    AND (p_is_active IS NULL OR t.is_active = p_is_active)
    ORDER BY 
        CASE WHEN p_is_featured = TRUE THEN t.is_featured END DESC,
        t.usage_count DESC,
        t.engagement_score DESC,
        t.tag_name ASC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql;

-- Function: Get tag hierarchy
CREATE OR REPLACE FUNCTION get_tag_hierarchy(p_store_id UUID, p_parent_tag_id UUID DEFAULT NULL)
RETURNS TABLE (
    tag_id UUID,
    tag_name VARCHAR(255),
    tag_slug VARCHAR(255),
    tag_level INTEGER,
    tag_path TEXT,
    parent_tag_id UUID,
    children_count BIGINT,
    usage_count INTEGER,
    is_active BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    WITH RECURSIVE tag_tree AS (
        -- Base case: start with specified parent or root tags
        SELECT 
            t.id,
            t.tag_name,
            t.tag_slug,
            t.tag_level,
            t.tag_path,
            t.parent_tag_id,
            t.usage_count,
            t.is_active
        FROM tags t
        WHERE t.store_id = p_store_id
        AND t.deleted_at IS NULL
        AND (
            (p_parent_tag_id IS NULL AND t.parent_tag_id IS NULL) OR
            (p_parent_tag_id IS NOT NULL AND t.parent_tag_id = p_parent_tag_id)
        )
        
        UNION ALL
        
        -- Recursive case: get children
        SELECT 
            t.id,
            t.tag_name,
            t.tag_slug,
            t.tag_level,
            t.tag_path,
            t.parent_tag_id,
            t.usage_count,
            t.is_active
        FROM tags t
        INNER JOIN tag_tree tt ON t.parent_tag_id = tt.id
        WHERE t.store_id = p_store_id
        AND t.deleted_at IS NULL
    )
    SELECT 
        tt.id,
        tt.tag_name,
        tt.tag_slug,
        tt.tag_level,
        tt.tag_path,
        tt.parent_tag_id,
        COUNT(child.id)::BIGINT as children_count,
        tt.usage_count,
        tt.is_active
    FROM tag_tree tt
    LEFT JOIN tags child ON child.parent_tag_id = tt.id AND child.deleted_at IS NULL
    GROUP BY tt.id, tt.tag_name, tt.tag_slug, tt.tag_level, tt.tag_path, tt.parent_tag_id, tt.usage_count, tt.is_active
    ORDER BY tt.tag_level, tt.tag_name;
END;
$$ LANGUAGE plpgsql;

-- Function: Update tag usage count
CREATE OR REPLACE FUNCTION increment_tag_usage(p_tag_id UUID, p_increment INTEGER DEFAULT 1)
RETURNS VOID AS $$
BEGIN
    UPDATE tags
    SET 
        usage_count = usage_count + p_increment,
        updated_at = NOW()
    WHERE id = p_tag_id;
END;
$$ LANGUAGE plpgsql;

-- Function: Get popular tags
CREATE OR REPLACE FUNCTION get_popular_tags(
    p_store_id UUID,
    p_tag_type VARCHAR(50) DEFAULT NULL,
    p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
    tag_id UUID,
    tag_name VARCHAR(255),
    tag_type VARCHAR(50),
    usage_count INTEGER,
    engagement_score DECIMAL(8,4)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.id,
        t.tag_name,
        t.tag_type,
        t.usage_count,
        t.engagement_score
    FROM tags t
    WHERE t.store_id = p_store_id
    AND t.deleted_at IS NULL
    AND t.is_active = TRUE
    AND (p_tag_type IS NULL OR t.tag_type = p_tag_type)
    ORDER BY t.usage_count DESC, t.engagement_score DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Comments
-- =============================================================================

COMMENT ON TABLE tags IS 'Tags for products, orders, and content classification';
COMMENT ON COLUMN tags.id IS 'Primary key for the tag';
COMMENT ON COLUMN tags.salla_tag_id IS 'Unique identifier from Salla API';
COMMENT ON COLUMN tags.store_id IS 'Reference to the store this tag belongs to';
COMMENT ON COLUMN tags.tag_name IS 'Name of the tag';
COMMENT ON COLUMN tags.tag_slug IS 'URL-friendly version of tag name';
COMMENT ON COLUMN tags.tag_type IS 'Type of tag (general, product, order, etc.)';
COMMENT ON COLUMN tags.parent_tag_id IS 'Reference to parent tag for hierarchy';
COMMENT ON COLUMN tags.tag_level IS 'Hierarchical level of the tag';
COMMENT ON COLUMN tags.tag_path IS 'Full hierarchical path of the tag';
COMMENT ON COLUMN tags.usage_count IS 'Number of times this tag has been used';
COMMENT ON COLUMN tags.engagement_score IS 'Calculated engagement score based on usage';
COMMENT ON COLUMN tags.quality_score IS 'Quality score of the tag';
COMMENT ON COLUMN tags.metadata IS 'Additional metadata in JSON format';
COMMENT ON COLUMN tags.created_at IS 'Timestamp when the tag was created';
COMMENT ON COLUMN tags.updated_at IS 'Timestamp when the tag was last updated';

COMMENT ON FUNCTION get_tag_stats(UUID) IS 'Returns comprehensive statistics for a specific tag';
COMMENT ON FUNCTION get_store_tags_stats(UUID) IS 'Returns statistics for all tags in a store';
COMMENT ON FUNCTION search_tags(UUID, TEXT, VARCHAR, VARCHAR, BOOLEAN, INTEGER, INTEGER) IS 'Search tags with filters and pagination';
COMMENT ON FUNCTION get_tag_hierarchy(UUID, UUID) IS 'Returns hierarchical structure of tags';
COMMENT ON FUNCTION increment_tag_usage(UUID, INTEGER) IS 'Increments usage count for a tag';
COMMENT ON FUNCTION get_popular_tags(UUID, VARCHAR, INTEGER) IS 'Returns most popular tags by usage';