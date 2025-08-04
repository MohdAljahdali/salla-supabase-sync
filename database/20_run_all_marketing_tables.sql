-- =============================================================================
-- Marketing and Offers Tables - Complete Setup
-- =============================================================================
-- This script sets up all marketing and offers related tables:
-- 1. Coupons
-- 2. Special Offers
-- 3. Affiliates
-- 
-- Includes all tables, indexes, triggers, and helper functions
-- Run this script to set up the complete marketing system

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- =============================================================================
-- Run Individual Table Scripts
-- =============================================================================

-- Create Coupons Table
\i 17_coupons_table.sql

-- Create Special Offers Table
\i 18_special_offers_table.sql

-- Create Affiliates Table
\i 19_affiliates_table.sql

-- =============================================================================
-- Additional Cross-Table Indexes
-- =============================================================================

-- Cross-table performance indexes
CREATE INDEX IF NOT EXISTS idx_marketing_store_performance ON coupons(store_id, usage_count DESC, total_revenue_generated DESC);
CREATE INDEX IF NOT EXISTS idx_offers_store_performance ON special_offers(store_id, usage_count DESC, total_revenue_generated DESC);
CREATE INDEX IF NOT EXISTS idx_affiliates_store_performance ON affiliates(store_id, total_sales_amount DESC, total_commission_earned DESC);

-- Marketing campaign tracking indexes
CREATE INDEX IF NOT EXISTS idx_coupons_campaign_tracking ON coupons(campaign_id, utm_source, utm_campaign) WHERE campaign_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_offers_campaign_tracking ON special_offers(campaign_id, utm_source, utm_campaign) WHERE campaign_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_affiliates_campaign_tracking ON affiliates(utm_source, utm_campaign) WHERE utm_source IS NOT NULL;

-- Active marketing elements indexes
CREATE INDEX IF NOT EXISTS idx_active_marketing_coupons ON coupons(store_id, is_active, start_date, end_date) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_active_marketing_offers ON special_offers(store_id, is_active, start_date, end_date) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_active_marketing_affiliates ON affiliates(store_id, is_active, affiliate_status) WHERE is_active = TRUE;

-- =============================================================================
-- Useful Views for Marketing Management
-- =============================================================================

-- Marketing Overview View
CREATE OR REPLACE VIEW marketing_overview AS
SELECT 
    s.id as store_id,
    s.store_name,
    
    -- Coupons metrics
    COUNT(DISTINCT c.id) as total_coupons,
    COUNT(DISTINCT CASE WHEN c.is_active = TRUE THEN c.id END) as active_coupons,
    COALESCE(SUM(c.usage_count), 0) as total_coupon_usage,
    COALESCE(SUM(c.total_revenue_generated), 0) as coupon_revenue_generated,
    
    -- Special offers metrics
    COUNT(DISTINCT so.id) as total_special_offers,
    COUNT(DISTINCT CASE WHEN so.is_active = TRUE THEN so.id END) as active_special_offers,
    COUNT(DISTINCT CASE WHEN so.is_flash_sale = TRUE AND so.is_active = TRUE THEN so.id END) as active_flash_sales,
    COALESCE(SUM(so.usage_count), 0) as total_offer_usage,
    COALESCE(SUM(so.total_revenue_generated), 0) as offer_revenue_generated,
    
    -- Affiliates metrics
    COUNT(DISTINCT a.id) as total_affiliates,
    COUNT(DISTINCT CASE WHEN a.affiliate_status = 'active' THEN a.id END) as active_affiliates,
    COALESCE(SUM(a.total_sales_amount), 0) as affiliate_sales_generated,
    COALESCE(SUM(a.total_commission_earned), 0) as affiliate_commission_earned,
    COALESCE(SUM(a.pending_commission), 0) as affiliate_pending_commission,
    
    -- Overall marketing performance
    COALESCE(SUM(c.total_revenue_generated), 0) + 
    COALESCE(SUM(so.total_revenue_generated), 0) + 
    COALESCE(SUM(a.total_sales_amount), 0) as total_marketing_revenue,
    
    -- Last activity dates
    GREATEST(
        COALESCE(MAX(c.updated_at), '1970-01-01'::timestamptz),
        COALESCE(MAX(so.updated_at), '1970-01-01'::timestamptz),
        COALESCE(MAX(a.last_activity_at), '1970-01-01'::timestamptz)
    ) as last_marketing_activity
    
FROM stores s
LEFT JOIN coupons c ON s.id = c.store_id
LEFT JOIN special_offers so ON s.id = so.store_id
LEFT JOIN affiliates a ON s.id = a.store_id
GROUP BY s.id, s.store_name;

-- Active Marketing Campaigns View
CREATE OR REPLACE VIEW active_marketing_campaigns AS
SELECT 
    'coupon' as campaign_type,
    c.id as campaign_id,
    c.store_id,
    c.coupon_name as campaign_name,
    c.coupon_code as campaign_code,
    c.start_date,
    c.end_date,
    c.usage_count,
    c.usage_limit,
    c.total_revenue_generated as revenue_generated,
    c.is_active,
    c.created_at
FROM coupons c
WHERE c.is_active = TRUE
    AND (c.start_date IS NULL OR c.start_date <= NOW())
    AND (c.end_date IS NULL OR c.end_date >= NOW())

UNION ALL

SELECT 
    'special_offer' as campaign_type,
    so.id as campaign_id,
    so.store_id,
    so.offer_name as campaign_name,
    so.offer_code as campaign_code,
    so.start_date,
    so.end_date,
    so.usage_count,
    so.usage_limit,
    so.total_revenue_generated as revenue_generated,
    so.is_active,
    so.created_at
FROM special_offers so
WHERE so.is_active = TRUE
    AND (so.start_date IS NULL OR so.start_date <= NOW())
    AND (so.end_date IS NULL OR so.end_date >= NOW())

ORDER BY created_at DESC;

-- Marketing Performance Report View
CREATE OR REPLACE VIEW marketing_performance_report AS
SELECT 
    store_id,
    DATE_TRUNC('month', created_at) as report_month,
    
    -- Coupons performance
    COUNT(CASE WHEN campaign_type = 'coupon' THEN 1 END) as coupons_created,
    SUM(CASE WHEN campaign_type = 'coupon' THEN usage_count ELSE 0 END) as coupon_usage_total,
    SUM(CASE WHEN campaign_type = 'coupon' THEN revenue_generated ELSE 0 END) as coupon_revenue_total,
    
    -- Special offers performance
    COUNT(CASE WHEN campaign_type = 'special_offer' THEN 1 END) as offers_created,
    SUM(CASE WHEN campaign_type = 'special_offer' THEN usage_count ELSE 0 END) as offer_usage_total,
    SUM(CASE WHEN campaign_type = 'special_offer' THEN revenue_generated ELSE 0 END) as offer_revenue_total,
    
    -- Combined metrics
    COUNT(*) as total_campaigns_created,
    SUM(usage_count) as total_usage,
    SUM(revenue_generated) as total_revenue_generated,
    
    -- Performance ratios
    CASE 
        WHEN COUNT(*) > 0 THEN SUM(usage_count)::DECIMAL / COUNT(*)
        ELSE 0
    END as average_usage_per_campaign,
    
    CASE 
        WHEN SUM(usage_count) > 0 THEN SUM(revenue_generated) / SUM(usage_count)
        ELSE 0
    END as average_revenue_per_use
    
FROM active_marketing_campaigns
GROUP BY store_id, DATE_TRUNC('month', created_at)
ORDER BY store_id, report_month DESC;

-- =============================================================================
-- Comprehensive Helper Functions
-- =============================================================================

-- Function: Get marketing dashboard data
CREATE OR REPLACE FUNCTION get_marketing_dashboard(p_store_id UUID)
RETURNS TABLE (
    -- Coupons summary
    total_coupons BIGINT,
    active_coupons BIGINT,
    expired_coupons BIGINT,
    coupon_usage_total BIGINT,
    coupon_revenue_total DECIMAL(15,4),
    
    -- Special offers summary
    total_offers BIGINT,
    active_offers BIGINT,
    flash_sales_active BIGINT,
    offer_usage_total BIGINT,
    offer_revenue_total DECIMAL(15,4),
    
    -- Affiliates summary
    total_affiliates BIGINT,
    active_affiliates BIGINT,
    affiliate_sales_total DECIMAL(15,4),
    affiliate_commission_total DECIMAL(15,4),
    affiliate_pending_commission DECIMAL(15,4),
    
    -- Overall performance
    total_marketing_revenue DECIMAL(15,4),
    marketing_roi DECIMAL(10,4),
    top_performing_campaign_type VARCHAR(50),
    top_performing_campaign_name VARCHAR(255)
) AS $$
DECLARE
    coupon_stats RECORD;
    offer_stats RECORD;
    affiliate_stats RECORD;
    top_campaign RECORD;
BEGIN
    -- Get coupon statistics
    SELECT * INTO coupon_stats FROM get_store_coupon_stats(p_store_id);
    
    -- Get special offer statistics
    SELECT * INTO offer_stats FROM get_store_special_offers_stats(p_store_id);
    
    -- Get affiliate statistics
    SELECT * INTO affiliate_stats FROM get_store_affiliate_stats(p_store_id);
    
    -- Get top performing campaign
    SELECT 
        campaign_type,
        campaign_name,
        revenue_generated
    INTO top_campaign
    FROM active_marketing_campaigns
    WHERE store_id = p_store_id
    ORDER BY revenue_generated DESC
    LIMIT 1;
    
    RETURN QUERY
    SELECT 
        -- Coupons
        coupon_stats.total_coupons,
        coupon_stats.active_coupons,
        coupon_stats.expired_coupons,
        coupon_stats.total_usage,
        coupon_stats.total_revenue_generated,
        
        -- Special offers
        offer_stats.total_offers,
        offer_stats.active_offers,
        offer_stats.flash_sales,
        offer_stats.total_usage,
        offer_stats.total_revenue_generated,
        
        -- Affiliates
        affiliate_stats.total_affiliates,
        affiliate_stats.active_affiliates,
        affiliate_stats.total_sales_generated,
        affiliate_stats.total_commission_paid,
        affiliate_stats.pending_commission_total,
        
        -- Overall
        (coupon_stats.total_revenue_generated + 
         offer_stats.total_revenue_generated + 
         affiliate_stats.total_sales_generated) as total_marketing_revenue,
        
        -- Simple ROI calculation (revenue / investment, assuming 10% marketing cost)
        CASE 
            WHEN (coupon_stats.total_revenue_generated + offer_stats.total_revenue_generated) > 0 THEN
                (coupon_stats.total_revenue_generated + offer_stats.total_revenue_generated + affiliate_stats.total_sales_generated) / 
                ((coupon_stats.total_revenue_generated + offer_stats.total_revenue_generated) * 0.1)
            ELSE 0
        END as marketing_roi,
        
        COALESCE(top_campaign.campaign_type, 'none') as top_performing_campaign_type,
        COALESCE(top_campaign.campaign_name, 'No campaigns') as top_performing_campaign_name;
END;
$$ LANGUAGE plpgsql;

-- Function: Apply best marketing offer to order
CREATE OR REPLACE FUNCTION apply_best_marketing_offer(
    p_store_id UUID,
    p_customer_id UUID,
    p_order_amount DECIMAL(15,4),
    p_product_ids UUID[] DEFAULT '{}',
    p_category_ids UUID[] DEFAULT '{}',
    p_country_code VARCHAR(2) DEFAULT NULL,
    p_coupon_code VARCHAR(100) DEFAULT NULL
)
RETURNS TABLE (
    offer_type VARCHAR(50),
    offer_id UUID,
    offer_name VARCHAR(255),
    discount_amount DECIMAL(15,4),
    applied BOOLEAN,
    error_message TEXT
) AS $$
DECLARE
    best_coupon RECORD;
    best_offer RECORD;
    coupon_discount DECIMAL(15,4) := 0;
    offer_discount DECIMAL(15,4) := 0;
BEGIN
    -- Check specific coupon if provided
    IF p_coupon_code IS NOT NULL THEN
        SELECT 
            c.id,
            c.coupon_name,
            (SELECT discount_amount FROM is_coupon_valid(c.id, p_customer_id, p_order_amount, p_product_ids, p_category_ids, p_country_code) LIMIT 1) as discount
        INTO best_coupon
        FROM coupons c
        WHERE c.store_id = p_store_id 
            AND c.coupon_code = p_coupon_code
            AND c.is_active = TRUE;
        
        IF FOUND AND best_coupon.discount > 0 THEN
            RETURN QUERY SELECT 'coupon'::VARCHAR(50), best_coupon.id, best_coupon.coupon_name, best_coupon.discount, TRUE, 'Coupon applied successfully';
            RETURN;
        END IF;
    END IF;
    
    -- Find best available coupon
    SELECT 
        c.id,
        c.coupon_name,
        (SELECT discount_amount FROM is_coupon_valid(c.id, p_customer_id, p_order_amount, p_product_ids, p_category_ids, p_country_code) LIMIT 1) as discount
    INTO best_coupon
    FROM coupons c
    WHERE c.store_id = p_store_id 
        AND c.is_active = TRUE
        AND (c.start_date IS NULL OR c.start_date <= NOW())
        AND (c.end_date IS NULL OR c.end_date >= NOW())
        AND (c.usage_limit IS NULL OR c.usage_count < c.usage_limit)
    ORDER BY 
        (SELECT discount_amount FROM is_coupon_valid(c.id, p_customer_id, p_order_amount, p_product_ids, p_category_ids, p_country_code) LIMIT 1) DESC
    LIMIT 1;
    
    -- Find best available special offer
    SELECT 
        so.id,
        so.offer_name,
        (SELECT discount_amount FROM is_special_offer_valid(so.id, p_customer_id, p_order_amount, p_product_ids, p_category_ids, p_country_code) LIMIT 1) as discount
    INTO best_offer
    FROM special_offers so
    WHERE so.store_id = p_store_id 
        AND so.is_active = TRUE
        AND so.approval_status = 'approved'
        AND (so.start_date IS NULL OR so.start_date <= NOW())
        AND (so.end_date IS NULL OR so.end_date >= NOW())
        AND (so.usage_limit IS NULL OR so.usage_count < so.usage_limit)
    ORDER BY 
        (SELECT discount_amount FROM is_special_offer_valid(so.id, p_customer_id, p_order_amount, p_product_ids, p_category_ids, p_country_code) LIMIT 1) DESC
    LIMIT 1;
    
    -- Compare and return best option
    coupon_discount := COALESCE(best_coupon.discount, 0);
    offer_discount := COALESCE(best_offer.discount, 0);
    
    IF coupon_discount >= offer_discount AND coupon_discount > 0 THEN
        RETURN QUERY SELECT 'coupon'::VARCHAR(50), best_coupon.id, best_coupon.coupon_name, coupon_discount, TRUE, 'Best coupon applied';
    ELSIF offer_discount > 0 THEN
        RETURN QUERY SELECT 'special_offer'::VARCHAR(50), best_offer.id, best_offer.offer_name, offer_discount, TRUE, 'Best special offer applied';
    ELSE
        RETURN QUERY SELECT 'none'::VARCHAR(50), NULL::UUID, 'No applicable offers', 0::DECIMAL(15,4), FALSE, 'No valid offers found';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function: Generate marketing report
CREATE OR REPLACE FUNCTION generate_marketing_report(
    p_store_id UUID,
    p_start_date TIMESTAMPTZ DEFAULT NULL,
    p_end_date TIMESTAMPTZ DEFAULT NULL,
    p_report_type VARCHAR(50) DEFAULT 'summary' -- 'summary', 'detailed', 'performance'
)
RETURNS TABLE (
    report_section VARCHAR(100),
    metric_name VARCHAR(100),
    metric_value DECIMAL(15,4),
    metric_text VARCHAR(500)
) AS $$
DECLARE
    start_filter TIMESTAMPTZ := COALESCE(p_start_date, date_trunc('month', NOW()));
    end_filter TIMESTAMPTZ := COALESCE(p_end_date, NOW());
    dashboard_data RECORD;
BEGIN
    -- Get dashboard data
    SELECT * INTO dashboard_data FROM get_marketing_dashboard(p_store_id);
    
    -- Return summary metrics
    RETURN QUERY
    SELECT 'Coupons'::VARCHAR(100), 'Total Coupons'::VARCHAR(100), dashboard_data.total_coupons::DECIMAL(15,4), dashboard_data.total_coupons::TEXT || ' coupons created';
    
    RETURN QUERY
    SELECT 'Coupons'::VARCHAR(100), 'Active Coupons'::VARCHAR(100), dashboard_data.active_coupons::DECIMAL(15,4), dashboard_data.active_coupons::TEXT || ' coupons currently active';
    
    RETURN QUERY
    SELECT 'Coupons'::VARCHAR(100), 'Coupon Revenue'::VARCHAR(100), dashboard_data.coupon_revenue_total, 'SAR ' || dashboard_data.coupon_revenue_total::TEXT || ' generated from coupons';
    
    RETURN QUERY
    SELECT 'Special Offers'::VARCHAR(100), 'Total Offers'::VARCHAR(100), dashboard_data.total_offers::DECIMAL(15,4), dashboard_data.total_offers::TEXT || ' special offers created';
    
    RETURN QUERY
    SELECT 'Special Offers'::VARCHAR(100), 'Active Offers'::VARCHAR(100), dashboard_data.active_offers::DECIMAL(15,4), dashboard_data.active_offers::TEXT || ' offers currently active';
    
    RETURN QUERY
    SELECT 'Special Offers'::VARCHAR(100), 'Offer Revenue'::VARCHAR(100), dashboard_data.offer_revenue_total, 'SAR ' || dashboard_data.offer_revenue_total::TEXT || ' generated from offers';
    
    RETURN QUERY
    SELECT 'Affiliates'::VARCHAR(100), 'Total Affiliates'::VARCHAR(100), dashboard_data.total_affiliates::DECIMAL(15,4), dashboard_data.total_affiliates::TEXT || ' affiliate partners';
    
    RETURN QUERY
    SELECT 'Affiliates'::VARCHAR(100), 'Active Affiliates'::VARCHAR(100), dashboard_data.active_affiliates::DECIMAL(15,4), dashboard_data.active_affiliates::TEXT || ' affiliates currently active';
    
    RETURN QUERY
    SELECT 'Affiliates'::VARCHAR(100), 'Affiliate Sales'::VARCHAR(100), dashboard_data.affiliate_sales_total, 'SAR ' || dashboard_data.affiliate_sales_total::TEXT || ' generated through affiliates';
    
    RETURN QUERY
    SELECT 'Overall'::VARCHAR(100), 'Total Marketing Revenue'::VARCHAR(100), dashboard_data.total_marketing_revenue, 'SAR ' || dashboard_data.total_marketing_revenue::TEXT || ' total marketing revenue';
    
    RETURN QUERY
    SELECT 'Overall'::VARCHAR(100), 'Marketing ROI'::VARCHAR(100), dashboard_data.marketing_roi, dashboard_data.marketing_roi::TEXT || 'x return on investment';
END;
$$ LANGUAGE plpgsql;

-- Function: Clean up expired marketing campaigns
CREATE OR REPLACE FUNCTION cleanup_expired_marketing_campaigns(p_store_id UUID DEFAULT NULL)
RETURNS TABLE (
    cleanup_type VARCHAR(50),
    items_updated INTEGER,
    message TEXT
) AS $$
DECLARE
    coupons_updated INTEGER := 0;
    offers_updated INTEGER := 0;
    store_filter UUID := p_store_id;
BEGIN
    -- Update expired coupons
    UPDATE coupons
    SET 
        is_active = FALSE,
        coupon_status = 'expired',
        updated_at = NOW()
    WHERE (store_filter IS NULL OR store_id = store_filter)
        AND is_active = TRUE
        AND end_date IS NOT NULL
        AND end_date < NOW();
    
    GET DIAGNOSTICS coupons_updated = ROW_COUNT;
    
    -- Update expired special offers
    UPDATE special_offers
    SET 
        is_active = FALSE,
        offer_status = 'expired',
        updated_at = NOW()
    WHERE (store_filter IS NULL OR store_id = store_filter)
        AND is_active = TRUE
        AND end_date IS NOT NULL
        AND end_date < NOW();
    
    GET DIAGNOSTICS offers_updated = ROW_COUNT;
    
    -- Return results
    RETURN QUERY SELECT 'coupons'::VARCHAR(50), coupons_updated, coupons_updated::TEXT || ' expired coupons deactivated';
    RETURN QUERY SELECT 'special_offers'::VARCHAR(50), offers_updated, offers_updated::TEXT || ' expired special offers deactivated';
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Comments
-- =============================================================================

COMMENT ON VIEW marketing_overview IS 'Comprehensive overview of all marketing activities per store';
COMMENT ON VIEW active_marketing_campaigns IS 'Currently active marketing campaigns across all types';
COMMENT ON VIEW marketing_performance_report IS 'Monthly performance report for marketing campaigns';

COMMENT ON FUNCTION get_marketing_dashboard(UUID) IS 'Returns comprehensive marketing dashboard data for a store';
COMMENT ON FUNCTION apply_best_marketing_offer(UUID, UUID, DECIMAL, UUID[], UUID[], VARCHAR, VARCHAR) IS 'Finds and applies the best available marketing offer for an order';
COMMENT ON FUNCTION generate_marketing_report(UUID, TIMESTAMPTZ, TIMESTAMPTZ, VARCHAR) IS 'Generates detailed marketing performance reports';
COMMENT ON FUNCTION cleanup_expired_marketing_campaigns(UUID) IS 'Automatically deactivates expired marketing campaigns';

-- =============================================================================
-- Setup Complete
-- =============================================================================

-- Display completion message
DO $$
BEGIN
    RAISE NOTICE 'Marketing and Offers Tables setup completed successfully!';
    RAISE NOTICE 'Created tables: coupons, special_offers, affiliates';
    RAISE NOTICE 'Created views: marketing_overview, active_marketing_campaigns, marketing_performance_report';
    RAISE NOTICE 'Created functions: get_marketing_dashboard, apply_best_marketing_offer, generate_marketing_report, cleanup_expired_marketing_campaigns';
END $$;