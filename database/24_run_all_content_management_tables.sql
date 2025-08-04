-- =============================================================================
-- Content Management Tables Setup Script
-- =============================================================================
-- This script sets up all content management related tables:
-- 1. Brands Table
-- 2. Tags Table  
-- 3. Taxes Table
-- Plus additional indexes, views, and helper functions

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- =============================================================================
-- Run Individual Table Scripts
-- =============================================================================

-- Create Brands Table
\i 21_brands_table.sql

-- Create Tags Table
\i 22_tags_table.sql

-- Create Taxes Table
\i 23_taxes_table.sql

-- =============================================================================
-- Additional Cross-Table Indexes
-- =============================================================================

-- Cross-reference indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_brands_tags_cross_reference ON brands USING gin(tags);
CREATE INDEX IF NOT EXISTS idx_products_brands_tags ON products(brand_id, tags) WHERE brand_id IS NOT NULL;

-- Content management performance indexes
CREATE INDEX IF NOT EXISTS idx_content_management_store_active ON brands(store_id, is_active, brand_status);
CREATE INDEX IF NOT EXISTS idx_content_tags_store_active ON tags(store_id, is_active, tag_status);
CREATE INDEX IF NOT EXISTS idx_content_taxes_store_active ON taxes(store_id, is_active, tax_status);

-- Search optimization indexes
CREATE INDEX IF NOT EXISTS idx_brands_search_optimization ON brands(store_id, is_active) 
    WHERE brand_name IS NOT NULL AND brand_description IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_tags_search_optimization ON tags(store_id, is_active) 
    WHERE tag_name IS NOT NULL AND tag_description IS NOT NULL;

-- =============================================================================
-- Useful Views for Content Management
-- =============================================================================

-- View: Content Management Overview
CREATE OR REPLACE VIEW content_management_overview AS
SELECT 
    s.id as store_id,
    s.store_name,
    -- Brands statistics
    COUNT(DISTINCT b.id) as total_brands,
    COUNT(DISTINCT b.id) FILTER (WHERE b.is_active = TRUE) as active_brands,
    COUNT(DISTINCT b.id) FILTER (WHERE b.is_featured = TRUE) as featured_brands,
    -- Tags statistics
    COUNT(DISTINCT t.id) as total_tags,
    COUNT(DISTINCT t.id) FILTER (WHERE t.is_active = TRUE) as active_tags,
    COUNT(DISTINCT t.id) FILTER (WHERE t.is_featured = TRUE) as featured_tags,
    -- Taxes statistics
    COUNT(DISTINCT tx.id) as total_taxes,
    COUNT(DISTINCT tx.id) FILTER (WHERE tx.is_active = TRUE) as active_taxes,
    COUNT(DISTINCT tx.id) FILTER (WHERE tx.is_default = TRUE) as default_taxes,
    -- Performance metrics
    COALESCE(AVG(b.brand_score), 0) as avg_brand_score,
    COALESCE(AVG(t.engagement_score), 0) as avg_tag_engagement,
    COALESCE(SUM(tx.total_collected), 0) as total_tax_collected
FROM stores s
LEFT JOIN brands b ON s.id = b.store_id AND b.deleted_at IS NULL
LEFT JOIN tags t ON s.id = t.store_id AND t.deleted_at IS NULL
LEFT JOIN taxes tx ON s.id = tx.store_id AND tx.deleted_at IS NULL
GROUP BY s.id, s.store_name;

COMMENT ON VIEW content_management_overview IS 'Overview of content management elements (brands, tags, taxes) per store';

-- View: Active Content Elements
CREATE OR REPLACE VIEW active_content_elements AS
SELECT 
    'brand' as content_type,
    b.id as content_id,
    b.store_id,
    b.brand_name as content_name,
    b.brand_slug as content_slug,
    b.brand_description as content_description,
    b.is_active,
    b.is_featured,
    b.created_at,
    b.updated_at
FROM brands b
WHERE b.is_active = TRUE AND b.deleted_at IS NULL

UNION ALL

SELECT 
    'tag' as content_type,
    t.id as content_id,
    t.store_id,
    t.tag_name as content_name,
    t.tag_slug as content_slug,
    t.tag_description as content_description,
    t.is_active,
    t.is_featured,
    t.created_at,
    t.updated_at
FROM tags t
WHERE t.is_active = TRUE AND t.deleted_at IS NULL

UNION ALL

SELECT 
    'tax' as content_type,
    tx.id as content_id,
    tx.store_id,
    tx.tax_name as content_name,
    tx.tax_slug as content_slug,
    tx.tax_description as content_description,
    tx.is_active,
    FALSE as is_featured, -- taxes don't have featured flag
    tx.created_at,
    tx.updated_at
FROM taxes tx
WHERE tx.is_active = TRUE AND tx.deleted_at IS NULL;

COMMENT ON VIEW active_content_elements IS 'Unified view of all active content management elements';

-- View: Content Performance Report
CREATE OR REPLACE VIEW content_performance_report AS
SELECT 
    s.id as store_id,
    s.store_name,
    -- Brand performance
    COUNT(DISTINCT b.id) as total_brands,
    COALESCE(AVG(b.brand_score), 0) as avg_brand_score,
    COALESCE(SUM(b.products_count), 0) as total_brand_products,
    COALESCE(SUM(b.total_sales), 0) as total_brand_sales,
    -- Tag performance
    COUNT(DISTINCT t.id) as total_tags,
    COALESCE(AVG(t.engagement_score), 0) as avg_tag_engagement,
    COALESCE(SUM(t.usage_count), 0) as total_tag_usage,
    COALESCE(SUM(t.click_count), 0) as total_tag_clicks,
    -- Tax performance
    COUNT(DISTINCT tx.id) as total_taxes,
    COALESCE(SUM(tx.total_collected), 0) as total_tax_collected,
    COALESCE(SUM(tx.total_orders), 0) as total_tax_orders,
    COALESCE(AVG(tx.collection_rate), 0) as avg_collection_rate,
    -- Overall metrics
    NOW() as report_generated_at
FROM stores s
LEFT JOIN brands b ON s.id = b.store_id AND b.deleted_at IS NULL AND b.is_active = TRUE
LEFT JOIN tags t ON s.id = t.store_id AND t.deleted_at IS NULL AND t.is_active = TRUE
LEFT JOIN taxes tx ON s.id = tx.store_id AND tx.deleted_at IS NULL AND tx.is_active = TRUE
GROUP BY s.id, s.store_name;

COMMENT ON VIEW content_performance_report IS 'Performance metrics for content management elements';

-- =============================================================================
-- Comprehensive Helper Functions
-- =============================================================================

-- Function: Get Content Management Dashboard
CREATE OR REPLACE FUNCTION get_content_management_dashboard(p_store_id UUID)
RETURNS TABLE (
    -- Brand metrics
    total_brands BIGINT,
    active_brands BIGINT,
    featured_brands BIGINT,
    avg_brand_score DECIMAL(8,4),
    top_brand_name VARCHAR(255),
    -- Tag metrics
    total_tags BIGINT,
    active_tags BIGINT,
    most_used_tag VARCHAR(255),
    avg_tag_engagement DECIMAL(8,4),
    total_tag_usage BIGINT,
    -- Tax metrics
    total_taxes BIGINT,
    active_taxes BIGINT,
    total_tax_collected DECIMAL(15,4),
    avg_tax_rate DECIMAL(8,6),
    most_used_tax_type VARCHAR(50),
    -- Performance indicators
    content_health_score DECIMAL(5,4),
    last_updated TIMESTAMPTZ
) AS $$
DECLARE
    brand_metrics RECORD;
    tag_metrics RECORD;
    tax_metrics RECORD;
    health_score DECIMAL(5,4) := 0;
BEGIN
    -- Get brand metrics
    SELECT 
        COUNT(*)::BIGINT as total,
        COUNT(*) FILTER (WHERE is_active = TRUE)::BIGINT as active,
        COUNT(*) FILTER (WHERE is_featured = TRUE)::BIGINT as featured,
        COALESCE(AVG(brand_score), 0) as avg_score,
        (
            SELECT brand_name 
            FROM brands 
            WHERE store_id = p_store_id AND deleted_at IS NULL 
            ORDER BY brand_score DESC, products_count DESC 
            LIMIT 1
        ) as top_name
    INTO brand_metrics
    FROM brands 
    WHERE store_id = p_store_id AND deleted_at IS NULL;
    
    -- Get tag metrics
    SELECT 
        COUNT(*)::BIGINT as total,
        COUNT(*) FILTER (WHERE is_active = TRUE)::BIGINT as active,
        COALESCE(SUM(usage_count), 0)::BIGINT as total_usage,
        COALESCE(AVG(engagement_score), 0) as avg_engagement,
        (
            SELECT tag_name 
            FROM tags 
            WHERE store_id = p_store_id AND deleted_at IS NULL 
            ORDER BY usage_count DESC 
            LIMIT 1
        ) as most_used
    INTO tag_metrics
    FROM tags 
    WHERE store_id = p_store_id AND deleted_at IS NULL;
    
    -- Get tax metrics
    SELECT 
        COUNT(*)::BIGINT as total,
        COUNT(*) FILTER (WHERE is_active = TRUE)::BIGINT as active,
        COALESCE(SUM(total_collected), 0) as collected,
        COALESCE(AVG(tax_rate), 0) as avg_rate,
        (
            SELECT tax_type 
            FROM taxes 
            WHERE store_id = p_store_id AND deleted_at IS NULL 
            GROUP BY tax_type 
            ORDER BY COUNT(*) DESC 
            LIMIT 1
        ) as most_used_type
    INTO tax_metrics
    FROM taxes 
    WHERE store_id = p_store_id AND deleted_at IS NULL;
    
    -- Calculate content health score (0-1)
    health_score = (
        CASE WHEN brand_metrics.total > 0 THEN 
            (brand_metrics.active::DECIMAL / brand_metrics.total) * 0.3 
        ELSE 0 END +
        CASE WHEN tag_metrics.total > 0 THEN 
            (tag_metrics.active::DECIMAL / tag_metrics.total) * 0.3 
        ELSE 0 END +
        CASE WHEN tax_metrics.total > 0 THEN 
            (tax_metrics.active::DECIMAL / tax_metrics.total) * 0.4 
        ELSE 0 END
    );
    
    RETURN QUERY
    SELECT 
        brand_metrics.total,
        brand_metrics.active,
        brand_metrics.featured,
        brand_metrics.avg_score,
        brand_metrics.top_name,
        tag_metrics.total,
        tag_metrics.active,
        tag_metrics.most_used,
        tag_metrics.avg_engagement,
        tag_metrics.total_usage,
        tax_metrics.total,
        tax_metrics.active,
        tax_metrics.collected,
        tax_metrics.avg_rate,
        tax_metrics.most_used_type,
        health_score,
        NOW();
END;
$$ LANGUAGE plpgsql;

-- Function: Search Content Elements
CREATE OR REPLACE FUNCTION search_content_elements(
    p_store_id UUID,
    p_search_term TEXT DEFAULT NULL,
    p_content_type VARCHAR(20) DEFAULT NULL, -- 'brand', 'tag', 'tax', or NULL for all
    p_is_active BOOLEAN DEFAULT NULL,
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    content_type VARCHAR(20),
    content_id UUID,
    content_name VARCHAR(255),
    content_slug VARCHAR(255),
    content_description TEXT,
    is_active BOOLEAN,
    is_featured BOOLEAN,
    usage_metric INTEGER,
    performance_score DECIMAL(8,4),
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    (
        SELECT 
            'brand'::VARCHAR(20) as content_type,
            b.id as content_id,
            b.brand_name as content_name,
            b.brand_slug as content_slug,
            b.brand_description as content_description,
            b.is_active,
            b.is_featured,
            b.products_count as usage_metric,
            b.brand_score as performance_score,
            b.created_at
        FROM brands b
        WHERE b.store_id = p_store_id
        AND b.deleted_at IS NULL
        AND (p_content_type IS NULL OR p_content_type = 'brand')
        AND (p_search_term IS NULL OR (
            b.brand_name ILIKE '%' || p_search_term || '%' OR
            b.brand_description ILIKE '%' || p_search_term || '%'
        ))
        AND (p_is_active IS NULL OR b.is_active = p_is_active)
    )
    UNION ALL
    (
        SELECT 
            'tag'::VARCHAR(20) as content_type,
            t.id as content_id,
            t.tag_name as content_name,
            t.tag_slug as content_slug,
            t.tag_description as content_description,
            t.is_active,
            t.is_featured,
            t.usage_count as usage_metric,
            t.engagement_score as performance_score,
            t.created_at
        FROM tags t
        WHERE t.store_id = p_store_id
        AND t.deleted_at IS NULL
        AND (p_content_type IS NULL OR p_content_type = 'tag')
        AND (p_search_term IS NULL OR (
            t.tag_name ILIKE '%' || p_search_term || '%' OR
            t.tag_description ILIKE '%' || p_search_term || '%'
        ))
        AND (p_is_active IS NULL OR t.is_active = p_is_active)
    )
    UNION ALL
    (
        SELECT 
            'tax'::VARCHAR(20) as content_type,
            tx.id as content_id,
            tx.tax_name as content_name,
            tx.tax_slug as content_slug,
            tx.tax_description as content_description,
            tx.is_active,
            FALSE as is_featured,
            tx.total_orders as usage_metric,
            tx.collection_rate * 100 as performance_score,
            tx.created_at
        FROM taxes tx
        WHERE tx.store_id = p_store_id
        AND tx.deleted_at IS NULL
        AND (p_content_type IS NULL OR p_content_type = 'tax')
        AND (p_search_term IS NULL OR (
            tx.tax_name ILIKE '%' || p_search_term || '%' OR
            tx.tax_description ILIKE '%' || p_search_term || '%'
        ))
        AND (p_is_active IS NULL OR tx.is_active = p_is_active)
    )
    ORDER BY performance_score DESC, usage_metric DESC, content_name ASC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql;

-- Function: Generate Content Management Report
CREATE OR REPLACE FUNCTION generate_content_management_report(
    p_store_id UUID,
    p_report_type VARCHAR(50) DEFAULT 'summary', -- summary, detailed, performance, compliance
    p_start_date TIMESTAMPTZ DEFAULT NULL,
    p_end_date TIMESTAMPTZ DEFAULT NULL
)
RETURNS TABLE (
    report_type VARCHAR(50),
    section VARCHAR(100),
    metric_name VARCHAR(255),
    metric_value TEXT,
    metric_description TEXT,
    generated_at TIMESTAMPTZ
) AS $$
BEGIN
    -- Set default dates if not provided
    p_start_date := COALESCE(p_start_date, NOW() - INTERVAL '30 days');
    p_end_date := COALESCE(p_end_date, NOW());
    
    IF p_report_type = 'summary' OR p_report_type = 'detailed' THEN
        -- Brand summary metrics
        RETURN QUERY
        SELECT 
            p_report_type,
            'brands'::VARCHAR(100),
            'total_brands'::VARCHAR(255),
            COUNT(*)::TEXT,
            'Total number of brands'::TEXT,
            NOW()
        FROM brands 
        WHERE store_id = p_store_id AND deleted_at IS NULL;
        
        RETURN QUERY
        SELECT 
            p_report_type,
            'brands'::VARCHAR(100),
            'active_brands'::VARCHAR(255),
            COUNT(*) FILTER (WHERE is_active = TRUE)::TEXT,
            'Number of active brands'::TEXT,
            NOW()
        FROM brands 
        WHERE store_id = p_store_id AND deleted_at IS NULL;
        
        -- Tag summary metrics
        RETURN QUERY
        SELECT 
            p_report_type,
            'tags'::VARCHAR(100),
            'total_tags'::VARCHAR(255),
            COUNT(*)::TEXT,
            'Total number of tags'::TEXT,
            NOW()
        FROM tags 
        WHERE store_id = p_store_id AND deleted_at IS NULL;
        
        RETURN QUERY
        SELECT 
            p_report_type,
            'tags'::VARCHAR(100),
            'total_tag_usage'::VARCHAR(255),
            COALESCE(SUM(usage_count), 0)::TEXT,
            'Total tag usage count'::TEXT,
            NOW()
        FROM tags 
        WHERE store_id = p_store_id AND deleted_at IS NULL;
        
        -- Tax summary metrics
        RETURN QUERY
        SELECT 
            p_report_type,
            'taxes'::VARCHAR(100),
            'total_taxes'::VARCHAR(255),
            COUNT(*)::TEXT,
            'Total number of tax configurations'::TEXT,
            NOW()
        FROM taxes 
        WHERE store_id = p_store_id AND deleted_at IS NULL;
        
        RETURN QUERY
        SELECT 
            p_report_type,
            'taxes'::VARCHAR(100),
            'total_tax_collected'::VARCHAR(255),
            COALESCE(SUM(total_collected), 0)::TEXT,
            'Total tax amount collected'::TEXT,
            NOW()
        FROM taxes 
        WHERE store_id = p_store_id AND deleted_at IS NULL;
    END IF;
    
    IF p_report_type = 'performance' OR p_report_type = 'detailed' THEN
        -- Performance metrics
        RETURN QUERY
        SELECT 
            p_report_type,
            'performance'::VARCHAR(100),
            'avg_brand_score'::VARCHAR(255),
            COALESCE(AVG(brand_score), 0)::TEXT,
            'Average brand performance score'::TEXT,
            NOW()
        FROM brands 
        WHERE store_id = p_store_id AND deleted_at IS NULL AND is_active = TRUE;
        
        RETURN QUERY
        SELECT 
            p_report_type,
            'performance'::VARCHAR(100),
            'avg_tag_engagement'::VARCHAR(255),
            COALESCE(AVG(engagement_score), 0)::TEXT,
            'Average tag engagement score'::TEXT,
            NOW()
        FROM tags 
        WHERE store_id = p_store_id AND deleted_at IS NULL AND is_active = TRUE;
        
        RETURN QUERY
        SELECT 
            p_report_type,
            'performance'::VARCHAR(100),
            'avg_tax_collection_rate'::VARCHAR(255),
            COALESCE(AVG(collection_rate), 0)::TEXT,
            'Average tax collection rate'::TEXT,
            NOW()
        FROM taxes 
        WHERE store_id = p_store_id AND deleted_at IS NULL AND is_active = TRUE;
    END IF;
    
    IF p_report_type = 'compliance' OR p_report_type = 'detailed' THEN
        -- Compliance metrics
        RETURN QUERY
        SELECT 
            p_report_type,
            'compliance'::VARCHAR(100),
            'compliant_taxes'::VARCHAR(255),
            COUNT(*) FILTER (WHERE compliance_status = 'compliant')::TEXT,
            'Number of compliant tax configurations'::TEXT,
            NOW()
        FROM taxes 
        WHERE store_id = p_store_id AND deleted_at IS NULL;
        
        RETURN QUERY
        SELECT 
            p_report_type,
            'compliance'::VARCHAR(100),
            'non_compliant_taxes'::VARCHAR(255),
            COUNT(*) FILTER (WHERE compliance_status = 'non_compliant')::TEXT,
            'Number of non-compliant tax configurations'::TEXT,
            NOW()
        FROM taxes 
        WHERE store_id = p_store_id AND deleted_at IS NULL;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function: Cleanup Inactive Content Elements
CREATE OR REPLACE FUNCTION cleanup_inactive_content_elements(
    p_store_id UUID DEFAULT NULL,
    p_days_inactive INTEGER DEFAULT 90,
    p_dry_run BOOLEAN DEFAULT TRUE
)
RETURNS TABLE (
    content_type VARCHAR(20),
    content_id UUID,
    content_name VARCHAR(255),
    last_activity TIMESTAMPTZ,
    action_taken VARCHAR(50)
) AS $$
DECLARE
    cutoff_date TIMESTAMPTZ := NOW() - (p_days_inactive || ' days')::INTERVAL;
BEGIN
    -- Find inactive brands
    RETURN QUERY
    SELECT 
        'brand'::VARCHAR(20),
        b.id,
        b.brand_name,
        GREATEST(b.updated_at, COALESCE(b.last_product_added, b.created_at)),
        CASE WHEN p_dry_run THEN 'would_deactivate'::VARCHAR(50) ELSE 'deactivated'::VARCHAR(50) END
    FROM brands b
    WHERE (p_store_id IS NULL OR b.store_id = p_store_id)
    AND b.is_active = TRUE
    AND b.deleted_at IS NULL
    AND b.products_count = 0
    AND GREATEST(b.updated_at, COALESCE(b.last_product_added, b.created_at)) < cutoff_date;
    
    -- Find inactive tags
    RETURN QUERY
    SELECT 
        'tag'::VARCHAR(20),
        t.id,
        t.tag_name,
        GREATEST(t.updated_at, COALESCE(t.last_used_at, t.created_at)),
        CASE WHEN p_dry_run THEN 'would_deactivate'::VARCHAR(50) ELSE 'deactivated'::VARCHAR(50) END
    FROM tags t
    WHERE (p_store_id IS NULL OR t.store_id = p_store_id)
    AND t.is_active = TRUE
    AND t.deleted_at IS NULL
    AND t.usage_count = 0
    AND GREATEST(t.updated_at, COALESCE(t.last_used_at, t.created_at)) < cutoff_date;
    
    -- Actually perform cleanup if not dry run
    IF NOT p_dry_run THEN
        -- Deactivate inactive brands
        UPDATE brands 
        SET is_active = FALSE, updated_at = NOW()
        WHERE (p_store_id IS NULL OR store_id = p_store_id)
        AND is_active = TRUE
        AND deleted_at IS NULL
        AND products_count = 0
        AND GREATEST(updated_at, COALESCE(last_product_added, created_at)) < cutoff_date;
        
        -- Deactivate inactive tags
        UPDATE tags 
        SET is_active = FALSE, updated_at = NOW()
        WHERE (p_store_id IS NULL OR store_id = p_store_id)
        AND is_active = TRUE
        AND deleted_at IS NULL
        AND usage_count = 0
        AND GREATEST(updated_at, COALESCE(last_used_at, created_at)) < cutoff_date;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Comments for New Functions
-- =============================================================================

COMMENT ON FUNCTION get_content_management_dashboard(UUID) IS 'Returns comprehensive dashboard metrics for content management';
COMMENT ON FUNCTION search_content_elements(UUID, TEXT, VARCHAR, BOOLEAN, INTEGER, INTEGER) IS 'Search across all content management elements with unified results';
COMMENT ON FUNCTION generate_content_management_report(UUID, VARCHAR, TIMESTAMPTZ, TIMESTAMPTZ) IS 'Generate various types of content management reports';
COMMENT ON FUNCTION cleanup_inactive_content_elements(UUID, INTEGER, BOOLEAN) IS 'Cleanup inactive content elements with dry run option';

-- =============================================================================
-- Final Success Message
-- =============================================================================

DO $$
BEGIN
    RAISE NOTICE 'Content Management Tables setup completed successfully!';
    RAISE NOTICE 'Created tables: brands, tags, taxes';
    RAISE NOTICE 'Created views: content_management_overview, active_content_elements, content_performance_report';
    RAISE NOTICE 'Created functions: get_content_management_dashboard, search_content_elements, generate_content_management_report, cleanup_inactive_content_elements';
END $$;