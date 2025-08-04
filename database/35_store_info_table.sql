-- =====================================================
-- Store Info Table
-- =====================================================
-- This table stores comprehensive store information and metadata
-- for detailed store management and configuration

CREATE TABLE IF NOT EXISTS store_info (
    -- Primary identification
    id BIGSERIAL PRIMARY KEY,
    
    -- Store relationship (required)
    store_id BIGINT NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Basic store information
    store_name VARCHAR(255) NOT NULL,
    store_description TEXT,
    store_slogan VARCHAR(500),
    store_tagline VARCHAR(255),
    
    -- Store identification
    store_code VARCHAR(100),
    store_slug VARCHAR(255),
    store_uuid UUID DEFAULT gen_random_uuid(),
    external_store_id VARCHAR(255),
    
    -- Business information
    business_name VARCHAR(255),
    business_type VARCHAR(100), -- retail, wholesale, marketplace, service, etc.
    business_category VARCHAR(100),
    business_subcategory VARCHAR(100),
    industry VARCHAR(100),
    
    -- Legal and registration
    legal_name VARCHAR(255),
    registration_number VARCHAR(100),
    tax_id VARCHAR(100),
    vat_number VARCHAR(100),
    commercial_license VARCHAR(100),
    
    -- Contact information
    primary_email VARCHAR(255),
    secondary_email VARCHAR(255),
    support_email VARCHAR(255),
    primary_phone VARCHAR(50),
    secondary_phone VARCHAR(50),
    fax_number VARCHAR(50),
    
    -- Address information
    address_line_1 VARCHAR(255),
    address_line_2 VARCHAR(255),
    city VARCHAR(100),
    state_province VARCHAR(100),
    postal_code VARCHAR(20),
    country_code VARCHAR(3),
    country_name VARCHAR(100),
    
    -- Geographic coordinates
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    timezone VARCHAR(50) DEFAULT 'UTC',
    
    -- Website and online presence
    website_url VARCHAR(500),
    domain_name VARCHAR(255),
    subdomain VARCHAR(100),
    social_media_links JSONB,
    
    -- Store settings and preferences
    default_language VARCHAR(10) DEFAULT 'en',
    supported_languages TEXT[],
    default_currency VARCHAR(3) DEFAULT 'USD',
    supported_currencies TEXT[],
    
    -- Operating information
    operating_hours JSONB, -- Store operating hours by day
    timezone_offset INTEGER, -- Offset from UTC in minutes
    is_24_7 BOOLEAN NOT NULL DEFAULT FALSE,
    seasonal_hours JSONB,
    
    -- Store status and lifecycle
    store_status VARCHAR(50) NOT NULL DEFAULT 'active', -- active, inactive, suspended, closed, maintenance
    lifecycle_stage VARCHAR(50) DEFAULT 'operational', -- setup, testing, operational, migrating, closing
    launch_date DATE,
    closure_date DATE,
    
    -- Business metrics and KPIs
    total_products INTEGER DEFAULT 0,
    total_orders INTEGER DEFAULT 0,
    total_customers INTEGER DEFAULT 0,
    total_revenue DECIMAL(15, 2) DEFAULT 0.00,
    average_order_value DECIMAL(10, 2) DEFAULT 0.00,
    
    -- Store configuration
    store_theme VARCHAR(100),
    store_template VARCHAR(100),
    custom_css TEXT,
    custom_javascript TEXT,
    favicon_url VARCHAR(500),
    logo_url VARCHAR(500),
    banner_url VARCHAR(500),
    
    -- SEO and marketing
    meta_title VARCHAR(255),
    meta_description TEXT,
    meta_keywords TEXT,
    google_analytics_id VARCHAR(100),
    facebook_pixel_id VARCHAR(100),
    google_tag_manager_id VARCHAR(100),
    
    -- E-commerce platform integration
    platform_type VARCHAR(50) DEFAULT 'salla', -- salla, shopify, woocommerce, magento, etc.
    platform_version VARCHAR(50),
    platform_plan VARCHAR(100),
    platform_features TEXT[],
    
    -- API and integration settings
    api_version VARCHAR(20),
    webhook_endpoints JSONB,
    integration_settings JSONB,
    third_party_integrations TEXT[],
    
    -- Security and compliance
    ssl_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    security_level VARCHAR(50) DEFAULT 'standard', -- basic, standard, enhanced, enterprise
    compliance_certifications TEXT[],
    data_protection_level VARCHAR(50) DEFAULT 'standard',
    
    -- Payment and financial
    payment_methods TEXT[],
    default_payment_gateway VARCHAR(100),
    payment_currencies TEXT[],
    tax_calculation_method VARCHAR(50) DEFAULT 'inclusive',
    
    -- Shipping and fulfillment
    shipping_zones TEXT[],
    default_shipping_method VARCHAR(100),
    fulfillment_methods TEXT[],
    warehouse_locations JSONB,
    
    -- Customer service
    support_channels TEXT[], -- email, phone, chat, ticket, etc.
    support_hours JSONB,
    response_time_sla INTEGER, -- in hours
    customer_service_language TEXT[],
    
    -- Inventory and catalog
    inventory_tracking_method VARCHAR(50) DEFAULT 'automatic',
    catalog_size_category VARCHAR(50), -- small, medium, large, enterprise
    product_categories_count INTEGER DEFAULT 0,
    brand_count INTEGER DEFAULT 0,
    
    -- Performance metrics
    page_load_speed_score INTEGER, -- 0-100
    mobile_optimization_score INTEGER, -- 0-100
    seo_score INTEGER, -- 0-100
    conversion_rate DECIMAL(5, 4) DEFAULT 0.0000,
    
    -- Analytics and tracking
    analytics_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    tracking_codes JSONB,
    custom_events JSONB,
    data_retention_days INTEGER DEFAULT 365,
    
    -- Backup and disaster recovery
    backup_frequency VARCHAR(20) DEFAULT 'daily', -- never, daily, weekly, monthly
    last_backup_date TIMESTAMP WITH TIME ZONE,
    backup_retention_days INTEGER DEFAULT 30,
    disaster_recovery_plan BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- Maintenance and updates
    last_maintenance_date TIMESTAMP WITH TIME ZONE,
    next_maintenance_date TIMESTAMP WITH TIME ZONE,
    maintenance_window JSONB,
    auto_updates_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    
    -- Subscription and billing
    subscription_plan VARCHAR(100),
    subscription_status VARCHAR(50) DEFAULT 'active',
    billing_cycle VARCHAR(20) DEFAULT 'monthly',
    next_billing_date DATE,
    
    -- Resource usage and limits
    storage_used_mb BIGINT DEFAULT 0,
    storage_limit_mb BIGINT,
    bandwidth_used_mb BIGINT DEFAULT 0,
    bandwidth_limit_mb BIGINT,
    api_calls_used INTEGER DEFAULT 0,
    api_calls_limit INTEGER,
    
    -- Notifications and alerts
    notification_preferences JSONB,
    alert_thresholds JSONB,
    emergency_contacts JSONB,
    notification_channels TEXT[],
    
    -- Localization and internationalization
    locale_settings JSONB,
    date_format VARCHAR(50) DEFAULT 'YYYY-MM-DD',
    time_format VARCHAR(20) DEFAULT '24h',
    number_format JSONB,
    
    -- Mobile and app settings
    mobile_app_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    mobile_app_settings JSONB,
    pwa_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    app_store_links JSONB,
    
    -- Social commerce
    social_selling_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    social_platforms TEXT[],
    social_commerce_settings JSONB,
    influencer_program BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- AI and automation
    ai_features_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    automation_rules JSONB,
    chatbot_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    recommendation_engine BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- Environmental and sustainability
    sustainability_initiatives TEXT[],
    carbon_footprint_tracking BOOLEAN NOT NULL DEFAULT FALSE,
    eco_friendly_packaging BOOLEAN NOT NULL DEFAULT FALSE,
    green_certifications TEXT[],
    
    -- Custom fields for extensibility
    custom_attributes JSONB,
    tags TEXT[],
    metadata JSONB,
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by_user_id BIGINT,
    updated_by_user_id BIGINT
);

-- =====================================================
-- Indexes for Performance
-- =====================================================

-- Primary lookup indexes
CREATE UNIQUE INDEX IF NOT EXISTS idx_store_info_store_id 
    ON store_info(store_id);

CREATE INDEX IF NOT EXISTS idx_store_info_store_code 
    ON store_info(store_code)
    WHERE store_code IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_store_info_store_slug 
    ON store_info(store_slug)
    WHERE store_slug IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_store_info_store_uuid 
    ON store_info(store_uuid);

-- Business and identification indexes
CREATE INDEX IF NOT EXISTS idx_store_info_business_type 
    ON store_info(business_type, business_category);

CREATE INDEX IF NOT EXISTS idx_store_info_industry 
    ON store_info(industry, business_type);

CREATE INDEX IF NOT EXISTS idx_store_info_registration 
    ON store_info(registration_number)
    WHERE registration_number IS NOT NULL;

-- Status and lifecycle indexes
CREATE INDEX IF NOT EXISTS idx_store_info_status 
    ON store_info(store_status, lifecycle_stage);

CREATE INDEX IF NOT EXISTS idx_store_info_launch_date 
    ON store_info(launch_date)
    WHERE launch_date IS NOT NULL;

-- Geographic indexes
CREATE INDEX IF NOT EXISTS idx_store_info_location 
    ON store_info(country_code, state_province, city);

CREATE INDEX IF NOT EXISTS idx_store_info_coordinates 
    ON store_info(latitude, longitude)
    WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_store_info_timezone 
    ON store_info(timezone);

-- Platform and integration indexes
CREATE INDEX IF NOT EXISTS idx_store_info_platform 
    ON store_info(platform_type, platform_version);

CREATE INDEX IF NOT EXISTS idx_store_info_plan 
    ON store_info(platform_plan, subscription_plan);

-- Performance and metrics indexes
CREATE INDEX IF NOT EXISTS idx_store_info_metrics 
    ON store_info(total_revenue, total_orders, total_customers);

CREATE INDEX IF NOT EXISTS idx_store_info_performance 
    ON store_info(page_load_speed_score, conversion_rate)
    WHERE page_load_speed_score IS NOT NULL;

-- Resource usage indexes
CREATE INDEX IF NOT EXISTS idx_store_info_storage 
    ON store_info(storage_used_mb, storage_limit_mb)
    WHERE storage_limit_mb IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_store_info_api_usage 
    ON store_info(api_calls_used, api_calls_limit)
    WHERE api_calls_limit IS NOT NULL;

-- Subscription and billing indexes
CREATE INDEX IF NOT EXISTS idx_store_info_subscription 
    ON store_info(subscription_status, next_billing_date)
    WHERE subscription_status IS NOT NULL;

-- Time-based indexes
CREATE INDEX IF NOT EXISTS idx_store_info_created_at 
    ON store_info(created_at);

CREATE INDEX IF NOT EXISTS idx_store_info_updated_at 
    ON store_info(updated_at);

-- JSON indexes for flexible querying
CREATE INDEX IF NOT EXISTS idx_store_info_social_media 
    ON store_info USING GIN(social_media_links)
    WHERE social_media_links IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_store_info_custom_attributes 
    ON store_info USING GIN(custom_attributes)
    WHERE custom_attributes IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_store_info_tags 
    ON store_info USING GIN(tags)
    WHERE tags IS NOT NULL;

-- =====================================================
-- Unique Constraints
-- =====================================================

-- Ensure one store info record per store
ALTER TABLE store_info 
    ADD CONSTRAINT uk_store_info_store_id 
    UNIQUE (store_id);

-- Ensure unique store codes and slugs
CREATE UNIQUE INDEX IF NOT EXISTS idx_store_info_code_unique 
    ON store_info(store_code)
    WHERE store_code IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_store_info_slug_unique 
    ON store_info(store_slug)
    WHERE store_slug IS NOT NULL;

-- =====================================================
-- Triggers
-- =====================================================

-- Updated at trigger
CREATE OR REPLACE FUNCTION update_store_info_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_store_info_updated_at
    BEFORE UPDATE ON store_info
    FOR EACH ROW
    EXECUTE FUNCTION update_store_info_updated_at();

-- Store metrics calculation trigger
CREATE OR REPLACE FUNCTION calculate_store_metrics()
RETURNS TRIGGER AS $$
BEGIN
    -- Calculate average order value
    IF NEW.total_orders > 0 AND NEW.total_revenue > 0 THEN
        NEW.average_order_value = NEW.total_revenue / NEW.total_orders;
    ELSE
        NEW.average_order_value = 0.00;
    END IF;
    
    -- Update catalog size category based on product count
    CASE 
        WHEN NEW.total_products <= 100 THEN
            NEW.catalog_size_category = 'small';
        WHEN NEW.total_products <= 1000 THEN
            NEW.catalog_size_category = 'medium';
        WHEN NEW.total_products <= 10000 THEN
            NEW.catalog_size_category = 'large';
        ELSE
            NEW.catalog_size_category = 'enterprise';
    END CASE;
    
    -- Generate store slug if not provided
    IF NEW.store_slug IS NULL AND NEW.store_name IS NOT NULL THEN
        NEW.store_slug = LOWER(REGEXP_REPLACE(NEW.store_name, '[^a-zA-Z0-9]+', '-', 'g'));
    END IF;
    
    -- Generate store code if not provided
    IF NEW.store_code IS NULL THEN
        NEW.store_code = 'STORE_' || NEW.store_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_store_metrics
    BEFORE INSERT OR UPDATE ON store_info
    FOR EACH ROW
    EXECUTE FUNCTION calculate_store_metrics();

-- Resource usage monitoring trigger
CREATE OR REPLACE FUNCTION monitor_resource_usage()
RETURNS TRIGGER AS $$
BEGIN
    -- Check storage usage against limit
    IF NEW.storage_limit_mb IS NOT NULL AND NEW.storage_used_mb > NEW.storage_limit_mb THEN
        -- Could trigger an alert or notification here
        NEW.metadata = COALESCE(NEW.metadata, '{}'::jsonb) || 
                      jsonb_build_object('storage_exceeded', true, 'exceeded_at', CURRENT_TIMESTAMP);
    END IF;
    
    -- Check API usage against limit
    IF NEW.api_calls_limit IS NOT NULL AND NEW.api_calls_used > NEW.api_calls_limit THEN
        NEW.metadata = COALESCE(NEW.metadata, '{}'::jsonb) || 
                      jsonb_build_object('api_limit_exceeded', true, 'exceeded_at', CURRENT_TIMESTAMP);
    END IF;
    
    -- Check bandwidth usage against limit
    IF NEW.bandwidth_limit_mb IS NOT NULL AND NEW.bandwidth_used_mb > NEW.bandwidth_limit_mb THEN
        NEW.metadata = COALESCE(NEW.metadata, '{}'::jsonb) || 
                      jsonb_build_object('bandwidth_exceeded', true, 'exceeded_at', CURRENT_TIMESTAMP);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_resource_monitoring
    BEFORE UPDATE ON store_info
    FOR EACH ROW
    EXECUTE FUNCTION monitor_resource_usage();

-- =====================================================
-- Helper Functions
-- =====================================================

-- Function to get store information
CREATE OR REPLACE FUNCTION get_store_info(
    store_id_param BIGINT
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT to_jsonb(si.*) INTO result
    FROM store_info si
    WHERE si.store_id = store_id_param;
    
    IF result IS NULL THEN
        RETURN '{"error": "Store info not found"}'::jsonb;
    END IF;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to update store metrics
CREATE OR REPLACE FUNCTION update_store_metrics(
    store_id_param BIGINT,
    products_count INTEGER DEFAULT NULL,
    orders_count INTEGER DEFAULT NULL,
    customers_count INTEGER DEFAULT NULL,
    revenue_amount DECIMAL DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    success BOOLEAN := FALSE;
BEGIN
    UPDATE store_info
    SET total_products = COALESCE(products_count, total_products),
        total_orders = COALESCE(orders_count, total_orders),
        total_customers = COALESCE(customers_count, total_customers),
        total_revenue = COALESCE(revenue_amount, total_revenue),
        updated_at = CURRENT_TIMESTAMP
    WHERE store_id = store_id_param
    RETURNING TRUE INTO success;
    
    RETURN COALESCE(success, FALSE);
END;
$$ LANGUAGE plpgsql;

-- Function to update resource usage
CREATE OR REPLACE FUNCTION update_resource_usage(
    store_id_param BIGINT,
    storage_used INTEGER DEFAULT NULL,
    bandwidth_used INTEGER DEFAULT NULL,
    api_calls_used INTEGER DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    success BOOLEAN := FALSE;
BEGIN
    UPDATE store_info
    SET storage_used_mb = COALESCE(storage_used, storage_used_mb),
        bandwidth_used_mb = COALESCE(bandwidth_used, bandwidth_used_mb),
        api_calls_used = COALESCE(api_calls_used, api_calls_used),
        updated_at = CURRENT_TIMESTAMP
    WHERE store_id = store_id_param
    RETURNING TRUE INTO success;
    
    RETURN COALESCE(success, FALSE);
END;
$$ LANGUAGE plpgsql;

-- Function to get stores by criteria
CREATE OR REPLACE FUNCTION search_stores(
    search_term VARCHAR DEFAULT NULL,
    business_type_filter VARCHAR DEFAULT NULL,
    country_filter VARCHAR DEFAULT NULL,
    status_filter VARCHAR DEFAULT NULL,
    platform_filter VARCHAR DEFAULT NULL,
    limit_param INTEGER DEFAULT 50
)
RETURNS TABLE (
    store_id BIGINT,
    store_name VARCHAR,
    business_type VARCHAR,
    store_status VARCHAR,
    country_name VARCHAR,
    platform_type VARCHAR,
    total_products INTEGER,
    total_orders INTEGER,
    total_revenue DECIMAL,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        si.store_id,
        si.store_name,
        si.business_type,
        si.store_status,
        si.country_name,
        si.platform_type,
        si.total_products,
        si.total_orders,
        si.total_revenue,
        si.created_at
    FROM store_info si
    WHERE (
            search_term IS NULL 
            OR si.store_name ILIKE '%' || search_term || '%'
            OR si.business_name ILIKE '%' || search_term || '%'
            OR si.store_code ILIKE '%' || search_term || '%'
        )
        AND (business_type_filter IS NULL OR si.business_type = business_type_filter)
        AND (country_filter IS NULL OR si.country_code = country_filter)
        AND (status_filter IS NULL OR si.store_status = status_filter)
        AND (platform_filter IS NULL OR si.platform_type = platform_filter)
    ORDER BY si.total_revenue DESC, si.created_at DESC
    LIMIT limit_param;
END;
$$ LANGUAGE plpgsql;

-- Function to get store statistics
CREATE OR REPLACE FUNCTION get_stores_statistics()
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_stores', COUNT(*),
        'active_stores', COUNT(*) FILTER (WHERE store_status = 'active'),
        'inactive_stores', COUNT(*) FILTER (WHERE store_status = 'inactive'),
        'total_products', SUM(total_products),
        'total_orders', SUM(total_orders),
        'total_customers', SUM(total_customers),
        'total_revenue', SUM(total_revenue),
        'average_products_per_store', AVG(total_products),
        'average_revenue_per_store', AVG(total_revenue),
        'business_types', (
            SELECT jsonb_object_agg(business_type, type_count)
            FROM (
                SELECT business_type, COUNT(*) as type_count
                FROM store_info
                WHERE business_type IS NOT NULL
                GROUP BY business_type
            ) bt_stats
        ),
        'countries_distribution', (
            SELECT jsonb_object_agg(country_name, country_count)
            FROM (
                SELECT country_name, COUNT(*) as country_count
                FROM store_info
                WHERE country_name IS NOT NULL
                GROUP BY country_name
                ORDER BY country_count DESC
                LIMIT 10
            ) country_stats
        ),
        'platforms_distribution', (
            SELECT jsonb_object_agg(platform_type, platform_count)
            FROM (
                SELECT platform_type, COUNT(*) as platform_count
                FROM store_info
                WHERE platform_type IS NOT NULL
                GROUP BY platform_type
            ) platform_stats
        ),
        'last_updated', MAX(updated_at)
    ) INTO result
    FROM store_info;
    
    RETURN COALESCE(result, '{"error": "No stores found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- Function to get store performance metrics
CREATE OR REPLACE FUNCTION get_store_performance(
    store_id_param BIGINT
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'store_id', store_id,
        'store_name', store_name,
        'performance_scores', jsonb_build_object(
            'page_load_speed', page_load_speed_score,
            'mobile_optimization', mobile_optimization_score,
            'seo_score', seo_score,
            'conversion_rate', conversion_rate
        ),
        'business_metrics', jsonb_build_object(
            'total_products', total_products,
            'total_orders', total_orders,
            'total_customers', total_customers,
            'total_revenue', total_revenue,
            'average_order_value', average_order_value
        ),
        'resource_usage', jsonb_build_object(
            'storage_used_mb', storage_used_mb,
            'storage_limit_mb', storage_limit_mb,
            'storage_usage_percentage', CASE 
                WHEN storage_limit_mb > 0 THEN (storage_used_mb::DECIMAL / storage_limit_mb) * 100
                ELSE NULL
            END,
            'api_calls_used', api_calls_used,
            'api_calls_limit', api_calls_limit,
            'api_usage_percentage', CASE 
                WHEN api_calls_limit > 0 THEN (api_calls_used::DECIMAL / api_calls_limit) * 100
                ELSE NULL
            END
        ),
        'status_info', jsonb_build_object(
            'store_status', store_status,
            'lifecycle_stage', lifecycle_stage,
            'platform_type', platform_type,
            'subscription_status', subscription_status
        )
    ) INTO result
    FROM store_info
    WHERE store_id = store_id_param;
    
    IF result IS NULL THEN
        RETURN '{"error": "Store not found"}'::jsonb;
    END IF;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Comments for Documentation
-- =====================================================

COMMENT ON TABLE store_info IS 'Comprehensive store information and metadata for detailed store management';
COMMENT ON COLUMN store_info.store_id IS 'Reference to the main stores table';
COMMENT ON COLUMN store_info.store_uuid IS 'Unique UUID identifier for external integrations';
COMMENT ON COLUMN store_info.business_type IS 'Type of business (retail, wholesale, marketplace, etc.)';
COMMENT ON COLUMN store_info.store_status IS 'Current operational status of the store';
COMMENT ON COLUMN store_info.lifecycle_stage IS 'Current stage in the store lifecycle';
COMMENT ON COLUMN store_info.platform_type IS 'E-commerce platform being used';
COMMENT ON COLUMN store_info.total_revenue IS 'Total revenue generated by the store';
COMMENT ON COLUMN store_info.conversion_rate IS 'Store conversion rate as a decimal (0.0250 = 2.5%)';
COMMENT ON COLUMN store_info.storage_used_mb IS 'Current storage usage in megabytes';
COMMENT ON COLUMN store_info.api_calls_used IS 'Number of API calls used in current billing period';

COMMENT ON FUNCTION get_store_info(BIGINT) IS 'Get complete store information as JSON';
COMMENT ON FUNCTION update_store_metrics(BIGINT, INTEGER, INTEGER, INTEGER, DECIMAL) IS 'Update store business metrics';
COMMENT ON FUNCTION update_resource_usage(BIGINT, INTEGER, INTEGER, INTEGER) IS 'Update store resource usage statistics';
COMMENT ON FUNCTION search_stores(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, INTEGER) IS 'Search stores with advanced filtering options';
COMMENT ON FUNCTION get_stores_statistics() IS 'Get comprehensive statistics across all stores';
COMMENT ON FUNCTION get_store_performance(BIGINT) IS 'Get detailed performance metrics for a specific store';