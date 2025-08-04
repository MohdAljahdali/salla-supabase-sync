-- =============================================================================
-- Special Offers Table
-- =============================================================================
-- This table stores special offers and promotional campaigns from Salla API
-- Includes flash sales, seasonal offers, bundle deals, and promotional campaigns
-- Links to stores for multi-store support

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create special_offers table
CREATE TABLE IF NOT EXISTS special_offers (
    -- Primary identification
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Salla API identifiers
    salla_offer_id VARCHAR(255) UNIQUE,
    salla_store_id VARCHAR(255) NOT NULL,
    
    -- Store relationship
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Offer identification
    offer_code VARCHAR(100),
    offer_name VARCHAR(255) NOT NULL,
    offer_description TEXT,
    offer_slug VARCHAR(255),
    
    -- Offer type and category
    offer_type VARCHAR(50) NOT NULL DEFAULT 'discount', -- 'discount', 'flash_sale', 'bundle', 'bogo', 'seasonal', 'clearance', 'loyalty'
    offer_category VARCHAR(100), -- 'electronics', 'fashion', 'home', 'beauty', etc.
    campaign_type VARCHAR(50) DEFAULT 'standard', -- 'standard', 'flash', 'limited_time', 'recurring'
    
    -- Discount details
    discount_type VARCHAR(50) NOT NULL DEFAULT 'percentage', -- 'percentage', 'fixed_amount', 'buy_x_get_y', 'free_shipping'
    discount_value DECIMAL(15,4) NOT NULL DEFAULT 0,
    discount_percentage DECIMAL(5,2), -- For percentage discounts (0-100)
    max_discount_amount DECIMAL(15,4), -- Maximum discount for percentage offers
    currency_code VARCHAR(3) DEFAULT 'SAR',
    
    -- Bundle and BOGO settings
    bundle_type VARCHAR(50), -- 'fixed_bundle', 'mix_and_match', 'tiered_pricing'
    buy_quantity INTEGER,
    get_quantity INTEGER,
    get_discount_percentage DECIMAL(5,2),
    bundle_price DECIMAL(15,4),
    
    -- Conditions and restrictions
    minimum_order_amount DECIMAL(15,4) DEFAULT 0,
    maximum_order_amount DECIMAL(15,4),
    minimum_quantity INTEGER DEFAULT 1,
    maximum_quantity INTEGER,
    minimum_items_in_cart INTEGER DEFAULT 1,
    
    -- Date and time settings
    start_date TIMESTAMPTZ,
    end_date TIMESTAMPTZ,
    start_time TIME,
    end_time TIME,
    timezone VARCHAR(50) DEFAULT 'Asia/Riyadh',
    valid_days_of_week INTEGER[], -- Array of day numbers (1=Monday, 7=Sunday)
    
    -- Flash sale specific settings
    is_flash_sale BOOLEAN DEFAULT FALSE,
    flash_sale_duration_minutes INTEGER,
    countdown_timer BOOLEAN DEFAULT FALSE,
    stock_limit INTEGER,
    stock_remaining INTEGER,
    
    -- Status and availability
    offer_status VARCHAR(50) NOT NULL DEFAULT 'active', -- 'active', 'inactive', 'expired', 'scheduled', 'sold_out', 'paused'
    is_active BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    is_exclusive BOOLEAN DEFAULT FALSE,
    priority_level INTEGER DEFAULT 0, -- Higher number = higher priority
    
    -- Visibility and display
    is_public BOOLEAN DEFAULT TRUE,
    show_on_homepage BOOLEAN DEFAULT FALSE,
    show_in_category BOOLEAN DEFAULT TRUE,
    show_in_search BOOLEAN DEFAULT TRUE,
    display_badge VARCHAR(100), -- 'HOT', 'NEW', 'LIMITED', 'SALE', etc.
    badge_color VARCHAR(7), -- Hex color code
    
    -- Customer targeting
    customer_eligibility VARCHAR(50) DEFAULT 'all', -- 'all', 'new_customers', 'vip_customers', 'specific_groups'
    eligible_customer_groups VARCHAR(100)[], -- Array of customer group names
    eligible_customer_ids UUID[], -- Array of specific customer IDs
    excluded_customer_ids UUID[], -- Array of excluded customer IDs
    loyalty_points_required INTEGER,
    
    -- Product and category targeting
    applicable_to VARCHAR(50) DEFAULT 'all', -- 'all', 'specific_products', 'specific_categories', 'specific_brands', 'collections'
    included_product_ids UUID[], -- Array of included product IDs
    excluded_product_ids UUID[], -- Array of excluded product IDs
    included_category_ids UUID[], -- Array of included category IDs
    excluded_category_ids UUID[], -- Array of excluded category IDs
    included_brand_names VARCHAR(255)[], -- Array of included brand names
    excluded_brand_names VARCHAR(255)[], -- Array of excluded brand names
    collection_ids UUID[], -- Array of product collection IDs
    
    -- Geographic targeting
    allowed_countries VARCHAR(2)[], -- Array of ISO country codes
    excluded_countries VARCHAR(2)[], -- Array of excluded country codes
    allowed_cities VARCHAR(255)[], -- Array of allowed city names
    excluded_cities VARCHAR(255)[], -- Array of excluded city names
    shipping_zones VARCHAR(100)[], -- Array of shipping zone names
    
    -- Usage and limits
    usage_limit INTEGER, -- Total usage limit for the offer
    usage_limit_per_customer INTEGER DEFAULT 1,
    usage_count INTEGER DEFAULT 0,
    remaining_uses INTEGER,
    max_redemptions_per_day INTEGER,
    daily_usage_count INTEGER DEFAULT 0,
    
    -- Combination rules
    can_combine_with_coupons BOOLEAN DEFAULT TRUE,
    can_combine_with_other_offers BOOLEAN DEFAULT FALSE,
    stackable_offers UUID[], -- Array of offer IDs that can be stacked
    
    -- Display and marketing
    display_name VARCHAR(255),
    short_description VARCHAR(500),
    marketing_message TEXT,
    terms_and_conditions TEXT,
    banner_image_url VARCHAR(500),
    thumbnail_image_url VARCHAR(500),
    hero_image_url VARCHAR(500),
    
    -- SEO and marketing
    meta_title VARCHAR(255),
    meta_description TEXT,
    keywords VARCHAR(500)[],
    social_media_message TEXT,
    hashtags VARCHAR(100)[],
    
    -- Tracking and analytics
    source VARCHAR(100), -- 'manual', 'campaign', 'api', 'import', 'automated'
    campaign_id VARCHAR(255),
    utm_source VARCHAR(255),
    utm_medium VARCHAR(255),
    utm_campaign VARCHAR(255),
    affiliate_tracking_code VARCHAR(255),
    
    -- Performance metrics
    total_revenue_generated DECIMAL(15,4) DEFAULT 0,
    total_orders_count INTEGER DEFAULT 0,
    total_items_sold INTEGER DEFAULT 0,
    conversion_rate DECIMAL(5,4) DEFAULT 0, -- Percentage as decimal
    average_order_value DECIMAL(15,4) DEFAULT 0,
    click_through_rate DECIMAL(5,4) DEFAULT 0,
    view_count INTEGER DEFAULT 0,
    
    -- Notification settings
    notify_on_start BOOLEAN DEFAULT FALSE,
    notify_on_end BOOLEAN DEFAULT FALSE,
    notify_on_low_stock BOOLEAN DEFAULT FALSE,
    low_stock_threshold INTEGER DEFAULT 10,
    notification_emails VARCHAR(255)[],
    
    -- Auto-management
    auto_activate BOOLEAN DEFAULT FALSE,
    auto_deactivate BOOLEAN DEFAULT TRUE,
    auto_extend_if_successful BOOLEAN DEFAULT FALSE,
    success_threshold_orders INTEGER,
    success_threshold_revenue DECIMAL(15,4),
    
    -- Related offers
    parent_offer_id UUID REFERENCES special_offers(id),
    related_offer_ids UUID[], -- Array of related offer IDs
    alternative_offer_ids UUID[], -- Array of alternative offer IDs
    
    -- Integration and sync
    last_sync_at TIMESTAMPTZ,
    sync_status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'synced', 'error'
    sync_error_message TEXT,
    external_offer_id VARCHAR(255), -- ID from external marketing platforms
    
    -- Approval workflow
    approval_status VARCHAR(50) DEFAULT 'approved', -- 'pending', 'approved', 'rejected', 'needs_review'
    approved_by_user_id UUID,
    approved_at TIMESTAMPTZ,
    rejection_reason TEXT,
    
    -- Metadata and custom fields
    metadata JSONB DEFAULT '{}',
    custom_fields JSONB DEFAULT '{}',
    tags VARCHAR(100)[] DEFAULT '{}',
    
    -- Internal management
    internal_notes TEXT,
    created_by_user_id UUID,
    last_modified_by_user_id UUID,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================================
-- Indexes for Performance
-- =============================================================================

-- Primary indexes
CREATE INDEX IF NOT EXISTS idx_special_offers_store_id ON special_offers(store_id);
CREATE INDEX IF NOT EXISTS idx_special_offers_salla_offer_id ON special_offers(salla_offer_id);
CREATE INDEX IF NOT EXISTS idx_special_offers_salla_store_id ON special_offers(salla_store_id);

-- Offer lookup indexes
CREATE INDEX IF NOT EXISTS idx_special_offers_code ON special_offers(offer_code);
CREATE INDEX IF NOT EXISTS idx_special_offers_slug ON special_offers(offer_slug);
CREATE UNIQUE INDEX IF NOT EXISTS idx_special_offers_store_code_unique ON special_offers(store_id, offer_code) WHERE offer_code IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_special_offers_name_search ON special_offers USING gin(offer_name gin_trgm_ops);

-- Status and type indexes
CREATE INDEX IF NOT EXISTS idx_special_offers_status ON special_offers(offer_status);
CREATE INDEX IF NOT EXISTS idx_special_offers_active ON special_offers(is_active);
CREATE INDEX IF NOT EXISTS idx_special_offers_type ON special_offers(offer_type);
CREATE INDEX IF NOT EXISTS idx_special_offers_category ON special_offers(offer_category);
CREATE INDEX IF NOT EXISTS idx_special_offers_campaign_type ON special_offers(campaign_type);

-- Date and time indexes
CREATE INDEX IF NOT EXISTS idx_special_offers_dates ON special_offers(start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_special_offers_active_dates ON special_offers(start_date, end_date) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_special_offers_current ON special_offers(start_date, end_date) WHERE start_date <= NOW() AND (end_date IS NULL OR end_date >= NOW());

-- Flash sale and featured indexes
CREATE INDEX IF NOT EXISTS idx_special_offers_flash_sale ON special_offers(is_flash_sale) WHERE is_flash_sale = TRUE;
CREATE INDEX IF NOT EXISTS idx_special_offers_featured ON special_offers(is_featured) WHERE is_featured = TRUE;
CREATE INDEX IF NOT EXISTS idx_special_offers_exclusive ON special_offers(is_exclusive) WHERE is_exclusive = TRUE;
CREATE INDEX IF NOT EXISTS idx_special_offers_homepage ON special_offers(show_on_homepage) WHERE show_on_homepage = TRUE;

-- Usage and performance indexes
CREATE INDEX IF NOT EXISTS idx_special_offers_usage ON special_offers(usage_count, usage_limit);
CREATE INDEX IF NOT EXISTS idx_special_offers_remaining_uses ON special_offers(remaining_uses) WHERE remaining_uses > 0;
CREATE INDEX IF NOT EXISTS idx_special_offers_performance ON special_offers(total_revenue_generated DESC, total_orders_count DESC);
CREATE INDEX IF NOT EXISTS idx_special_offers_conversion ON special_offers(conversion_rate DESC);

-- Customer and product targeting indexes
CREATE INDEX IF NOT EXISTS idx_special_offers_customer_eligibility ON special_offers(customer_eligibility);
CREATE INDEX IF NOT EXISTS idx_special_offers_applicable_to ON special_offers(applicable_to);
CREATE INDEX IF NOT EXISTS idx_special_offers_eligible_customers ON special_offers USING gin(eligible_customer_ids);
CREATE INDEX IF NOT EXISTS idx_special_offers_included_products ON special_offers USING gin(included_product_ids);
CREATE INDEX IF NOT EXISTS idx_special_offers_included_categories ON special_offers USING gin(included_category_ids);
CREATE INDEX IF NOT EXISTS idx_special_offers_collections ON special_offers USING gin(collection_ids);

-- Geographic and marketing indexes
CREATE INDEX IF NOT EXISTS idx_special_offers_countries ON special_offers USING gin(allowed_countries);
CREATE INDEX IF NOT EXISTS idx_special_offers_campaign ON special_offers(campaign_id);
CREATE INDEX IF NOT EXISTS idx_special_offers_priority ON special_offers(priority_level DESC);
CREATE INDEX IF NOT EXISTS idx_special_offers_approval ON special_offers(approval_status);

-- JSONB indexes
CREATE INDEX IF NOT EXISTS idx_special_offers_metadata ON special_offers USING gin(metadata);
CREATE INDEX IF NOT EXISTS idx_special_offers_custom_fields ON special_offers USING gin(custom_fields);

-- Array indexes
CREATE INDEX IF NOT EXISTS idx_special_offers_tags ON special_offers USING gin(tags);
CREATE INDEX IF NOT EXISTS idx_special_offers_keywords ON special_offers USING gin(keywords);
CREATE INDEX IF NOT EXISTS idx_special_offers_hashtags ON special_offers USING gin(hashtags);
CREATE INDEX IF NOT EXISTS idx_special_offers_valid_days ON special_offers USING gin(valid_days_of_week);

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_special_offers_store_active_dates ON special_offers(store_id, is_active, start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_special_offers_type_status_dates ON special_offers(offer_type, offer_status, start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_special_offers_sync_status ON special_offers(sync_status, last_sync_at);
CREATE INDEX IF NOT EXISTS idx_special_offers_flash_active ON special_offers(is_flash_sale, is_active, end_date) WHERE is_flash_sale = TRUE;

-- =============================================================================
-- Triggers
-- =============================================================================

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_special_offers_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_special_offers_updated_at
    BEFORE UPDATE ON special_offers
    FOR EACH ROW
    EXECUTE FUNCTION update_special_offers_updated_at();

-- Trigger to update remaining uses and status
CREATE OR REPLACE FUNCTION update_special_offer_status()
RETURNS TRIGGER AS $$
BEGIN
    -- Update remaining uses when usage_count changes
    IF NEW.usage_limit IS NOT NULL AND NEW.usage_count != OLD.usage_count THEN
        NEW.remaining_uses = GREATEST(0, NEW.usage_limit - NEW.usage_count);
    END IF;
    
    -- Update stock remaining for flash sales
    IF NEW.is_flash_sale AND NEW.stock_limit IS NOT NULL THEN
        NEW.stock_remaining = GREATEST(0, NEW.stock_limit - NEW.usage_count);
    END IF;
    
    -- Update status based on various conditions
    IF NEW.remaining_uses = 0 AND NEW.usage_limit IS NOT NULL THEN
        NEW.offer_status = 'sold_out';
        NEW.is_active = FALSE;
    ELSIF NEW.is_flash_sale AND NEW.stock_remaining = 0 THEN
        NEW.offer_status = 'sold_out';
        NEW.is_active = FALSE;
    ELSIF NEW.end_date IS NOT NULL AND NEW.end_date < NOW() THEN
        NEW.offer_status = 'expired';
        NEW.is_active = FALSE;
    ELSIF NEW.start_date IS NOT NULL AND NEW.start_date > NOW() THEN
        NEW.offer_status = 'scheduled';
    ELSIF NEW.is_active = TRUE THEN
        NEW.offer_status = 'active';
    ELSE
        NEW.offer_status = 'inactive';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_special_offer_status
    BEFORE UPDATE ON special_offers
    FOR EACH ROW
    EXECUTE FUNCTION update_special_offer_status();

-- Trigger to set initial values
CREATE OR REPLACE FUNCTION set_initial_special_offer_values()
RETURNS TRIGGER AS $$
BEGIN
    -- Set initial remaining uses
    IF NEW.usage_limit IS NOT NULL THEN
        NEW.remaining_uses = NEW.usage_limit;
    END IF;
    
    -- Set initial stock remaining for flash sales
    IF NEW.is_flash_sale AND NEW.stock_limit IS NOT NULL THEN
        NEW.stock_remaining = NEW.stock_limit;
    END IF;
    
    -- Generate slug if not provided
    IF NEW.offer_slug IS NULL OR NEW.offer_slug = '' THEN
        NEW.offer_slug = lower(regexp_replace(NEW.offer_name, '[^a-zA-Z0-9]+', '-', 'g'));
    END IF;
    
    -- Set initial status based on dates
    IF NEW.end_date IS NOT NULL AND NEW.end_date < NOW() THEN
        NEW.offer_status = 'expired';
        NEW.is_active = FALSE;
    ELSIF NEW.start_date IS NOT NULL AND NEW.start_date > NOW() THEN
        NEW.offer_status = 'scheduled';
    ELSIF NEW.is_active = TRUE THEN
        NEW.offer_status = 'active';
    ELSE
        NEW.offer_status = 'inactive';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_set_initial_special_offer_values
    BEFORE INSERT ON special_offers
    FOR EACH ROW
    EXECUTE FUNCTION set_initial_special_offer_values();

-- =============================================================================
-- Helper Functions
-- =============================================================================

-- Function: Check if special offer is valid for a specific order
CREATE OR REPLACE FUNCTION is_special_offer_valid(
    p_offer_id UUID,
    p_customer_id UUID DEFAULT NULL,
    p_order_amount DECIMAL(15,4) DEFAULT 0,
    p_product_ids UUID[] DEFAULT '{}',
    p_category_ids UUID[] DEFAULT '{}',
    p_country_code VARCHAR(2) DEFAULT NULL,
    p_city VARCHAR(255) DEFAULT NULL
)
RETURNS TABLE (
    is_valid BOOLEAN,
    error_message TEXT,
    discount_amount DECIMAL(15,4)
) AS $$
DECLARE
    offer_record special_offers%ROWTYPE;
    calculated_discount DECIMAL(15,4) := 0;
    applicable_products_count INTEGER := 0;
BEGIN
    -- Get offer details
    SELECT * INTO offer_record FROM special_offers WHERE id = p_offer_id;
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Special offer not found', 0::DECIMAL(15,4);
        RETURN;
    END IF;
    
    -- Check if offer is active
    IF NOT offer_record.is_active THEN
        RETURN QUERY SELECT FALSE, 'Special offer is not active', 0::DECIMAL(15,4);
        RETURN;
    END IF;
    
    -- Check approval status
    IF offer_record.approval_status != 'approved' THEN
        RETURN QUERY SELECT FALSE, 'Special offer is not approved', 0::DECIMAL(15,4);
        RETURN;
    END IF;
    
    -- Check date validity
    IF offer_record.start_date IS NOT NULL AND offer_record.start_date > NOW() THEN
        RETURN QUERY SELECT FALSE, 'Special offer is not yet valid', 0::DECIMAL(15,4);
        RETURN;
    END IF;
    
    IF offer_record.end_date IS NOT NULL AND offer_record.end_date < NOW() THEN
        RETURN QUERY SELECT FALSE, 'Special offer has expired', 0::DECIMAL(15,4);
        RETURN;
    END IF;
    
    -- Check usage limits
    IF offer_record.usage_limit IS NOT NULL AND offer_record.usage_count >= offer_record.usage_limit THEN
        RETURN QUERY SELECT FALSE, 'Special offer usage limit reached', 0::DECIMAL(15,4);
        RETURN;
    END IF;
    
    -- Check stock for flash sales
    IF offer_record.is_flash_sale AND offer_record.stock_remaining IS NOT NULL AND offer_record.stock_remaining <= 0 THEN
        RETURN QUERY SELECT FALSE, 'Special offer is sold out', 0::DECIMAL(15,4);
        RETURN;
    END IF;
    
    -- Check minimum order amount
    IF p_order_amount < offer_record.minimum_order_amount THEN
        RETURN QUERY SELECT FALSE, 'Order amount below minimum required', 0::DECIMAL(15,4);
        RETURN;
    END IF;
    
    -- Check maximum order amount
    IF offer_record.maximum_order_amount IS NOT NULL AND p_order_amount > offer_record.maximum_order_amount THEN
        RETURN QUERY SELECT FALSE, 'Order amount exceeds maximum allowed', 0::DECIMAL(15,4);
        RETURN;
    END IF;
    
    -- Check customer eligibility
    IF p_customer_id IS NOT NULL THEN
        CASE offer_record.customer_eligibility
            WHEN 'new_customers' THEN
                IF EXISTS (SELECT 1 FROM orders WHERE customer_id = p_customer_id LIMIT 1) THEN
                    RETURN QUERY SELECT FALSE, 'Offer only valid for new customers', 0::DECIMAL(15,4);
                    RETURN;
                END IF;
            WHEN 'vip_customers' THEN
                -- Check if customer is VIP (simplified check)
                IF NOT EXISTS (SELECT 1 FROM customers WHERE id = p_customer_id AND customer_type = 'vip') THEN
                    RETURN QUERY SELECT FALSE, 'Offer only valid for VIP customers', 0::DECIMAL(15,4);
                    RETURN;
                END IF;
        END CASE;
        
        -- Check excluded customers
        IF p_customer_id = ANY(offer_record.excluded_customer_ids) THEN
            RETURN QUERY SELECT FALSE, 'Customer is excluded from this offer', 0::DECIMAL(15,4);
            RETURN;
        END IF;
    END IF;
    
    -- Check product applicability
    IF offer_record.applicable_to = 'specific_products' THEN
        SELECT COUNT(*) INTO applicable_products_count
        FROM unnest(p_product_ids) AS pid
        WHERE pid = ANY(offer_record.included_product_ids);
        
        IF applicable_products_count = 0 THEN
            RETURN QUERY SELECT FALSE, 'No applicable products in order', 0::DECIMAL(15,4);
            RETURN;
        END IF;
    END IF;
    
    -- Check geographic restrictions
    IF p_country_code IS NOT NULL THEN
        IF array_length(offer_record.allowed_countries, 1) > 0 AND NOT (p_country_code = ANY(offer_record.allowed_countries)) THEN
            RETURN QUERY SELECT FALSE, 'Offer not valid in this country', 0::DECIMAL(15,4);
            RETURN;
        END IF;
        
        IF p_country_code = ANY(offer_record.excluded_countries) THEN
            RETURN QUERY SELECT FALSE, 'Offer not valid in this country', 0::DECIMAL(15,4);
            RETURN;
        END IF;
    END IF;
    
    -- Calculate discount amount
    CASE offer_record.discount_type
        WHEN 'percentage' THEN
            calculated_discount = p_order_amount * (offer_record.discount_percentage / 100);
            IF offer_record.max_discount_amount IS NOT NULL THEN
                calculated_discount = LEAST(calculated_discount, offer_record.max_discount_amount);
            END IF;
        WHEN 'fixed_amount' THEN
            calculated_discount = offer_record.discount_value;
        WHEN 'free_shipping' THEN
            -- For free shipping, return a symbolic amount
            calculated_discount = 0;
    END CASE;
    
    -- Ensure discount doesn't exceed order amount
    calculated_discount = LEAST(calculated_discount, p_order_amount);
    
    RETURN QUERY SELECT TRUE, 'Special offer is valid', calculated_discount;
END;
$$ LANGUAGE plpgsql;

-- Function: Apply special offer to order
CREATE OR REPLACE FUNCTION apply_special_offer(
    p_offer_id UUID,
    p_order_id UUID,
    p_customer_id UUID,
    p_discount_amount DECIMAL(15,4),
    p_items_count INTEGER DEFAULT 1
)
RETURNS BOOLEAN AS $$
DECLARE
    offer_record special_offers%ROWTYPE;
BEGIN
    -- Get offer details with row lock
    SELECT * INTO offer_record FROM special_offers WHERE id = p_offer_id FOR UPDATE;
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Check usage limit one more time (race condition protection)
    IF offer_record.usage_limit IS NOT NULL AND offer_record.usage_count >= offer_record.usage_limit THEN
        RETURN FALSE;
    END IF;
    
    -- Check stock for flash sales
    IF offer_record.is_flash_sale AND offer_record.stock_remaining IS NOT NULL AND offer_record.stock_remaining <= 0 THEN
        RETURN FALSE;
    END IF;
    
    -- Update offer usage statistics
    UPDATE special_offers
    SET 
        usage_count = usage_count + 1,
        total_orders_count = total_orders_count + 1,
        total_items_sold = total_items_sold + p_items_count,
        total_revenue_generated = total_revenue_generated + p_discount_amount,
        view_count = view_count + 1,
        updated_at = NOW()
    WHERE id = p_offer_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Function: Get store special offers statistics
CREATE OR REPLACE FUNCTION get_store_special_offers_stats(p_store_id UUID)
RETURNS TABLE (
    total_offers BIGINT,
    active_offers BIGINT,
    expired_offers BIGINT,
    scheduled_offers BIGINT,
    flash_sales BIGINT,
    total_usage BIGINT,
    total_revenue_generated DECIMAL(15,4),
    average_conversion_rate DECIMAL(5,4),
    best_performing_offer_name VARCHAR(255)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::BIGINT as total_offers,
        COUNT(CASE WHEN so.offer_status = 'active' THEN 1 END)::BIGINT as active_offers,
        COUNT(CASE WHEN so.offer_status = 'expired' THEN 1 END)::BIGINT as expired_offers,
        COUNT(CASE WHEN so.offer_status = 'scheduled' THEN 1 END)::BIGINT as scheduled_offers,
        COUNT(CASE WHEN so.is_flash_sale = TRUE THEN 1 END)::BIGINT as flash_sales,
        COALESCE(SUM(so.usage_count), 0)::BIGINT as total_usage,
        COALESCE(SUM(so.total_revenue_generated), 0) as total_revenue_generated,
        COALESCE(AVG(so.conversion_rate), 0) as average_conversion_rate,
        (
            SELECT so2.offer_name
            FROM special_offers so2
            WHERE so2.store_id = p_store_id
            ORDER BY so2.total_revenue_generated DESC
            LIMIT 1
        ) as best_performing_offer_name
    FROM special_offers so
    WHERE so.store_id = p_store_id;
END;
$$ LANGUAGE plpgsql;

-- Function: Get active flash sales
CREATE OR REPLACE FUNCTION get_active_flash_sales(p_store_id UUID)
RETURNS TABLE (
    offer_id UUID,
    offer_name VARCHAR(255),
    discount_percentage DECIMAL(5,2),
    stock_remaining INTEGER,
    end_date TIMESTAMPTZ,
    minutes_remaining INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        so.id,
        so.offer_name,
        so.discount_percentage,
        so.stock_remaining,
        so.end_date,
        CASE 
            WHEN so.end_date IS NOT NULL THEN
                EXTRACT(EPOCH FROM (so.end_date - NOW()))::INTEGER / 60
            ELSE NULL
        END as minutes_remaining
    FROM special_offers so
    WHERE so.store_id = p_store_id
        AND so.is_flash_sale = TRUE
        AND so.is_active = TRUE
        AND so.offer_status = 'active'
        AND (so.end_date IS NULL OR so.end_date > NOW())
        AND (so.stock_remaining IS NULL OR so.stock_remaining > 0)
    ORDER BY so.end_date ASC NULLS LAST;
END;
$$ LANGUAGE plpgsql;

-- Function: Get trending offers
CREATE OR REPLACE FUNCTION get_trending_offers(
    p_store_id UUID,
    p_days_back INTEGER DEFAULT 7,
    p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
    offer_id UUID,
    offer_name VARCHAR(255),
    offer_type VARCHAR(50),
    usage_count INTEGER,
    conversion_rate DECIMAL(5,4),
    revenue_generated DECIMAL(15,4)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        so.id,
        so.offer_name,
        so.offer_type,
        so.usage_count,
        so.conversion_rate,
        so.total_revenue_generated
    FROM special_offers so
    WHERE so.store_id = p_store_id
        AND so.created_at >= NOW() - INTERVAL '%s days'
        AND so.usage_count > 0
    ORDER BY 
        so.conversion_rate DESC,
        so.total_revenue_generated DESC,
        so.usage_count DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Comments
-- =============================================================================

COMMENT ON TABLE special_offers IS 'Stores special offers and promotional campaigns from Salla API';
COMMENT ON COLUMN special_offers.id IS 'Primary key for the special offer';
COMMENT ON COLUMN special_offers.salla_offer_id IS 'Unique identifier from Salla API';
COMMENT ON COLUMN special_offers.store_id IS 'Reference to the store this offer belongs to';
COMMENT ON COLUMN special_offers.offer_type IS 'Type of offer: discount, flash_sale, bundle, bogo, seasonal, etc.';
COMMENT ON COLUMN special_offers.is_flash_sale IS 'Whether this is a time-limited flash sale';
COMMENT ON COLUMN special_offers.customer_eligibility IS 'Who can use this offer: all, new_customers, vip_customers, etc.';
COMMENT ON COLUMN special_offers.applicable_to IS 'What this offer applies to: all, specific_products, specific_categories, etc.';
COMMENT ON COLUMN special_offers.metadata IS 'Additional flexible data storage for offer information';

COMMENT ON FUNCTION is_special_offer_valid(UUID, UUID, DECIMAL, UUID[], UUID[], VARCHAR, VARCHAR) IS 'Validates if a special offer can be applied to a specific order';
COMMENT ON FUNCTION apply_special_offer(UUID, UUID, UUID, DECIMAL, INTEGER) IS 'Applies a special offer to an order and updates usage statistics';
COMMENT ON FUNCTION get_store_special_offers_stats(UUID) IS 'Returns comprehensive special offers statistics for a store';
COMMENT ON FUNCTION get_active_flash_sales(UUID) IS 'Returns currently active flash sales for a store';
COMMENT ON FUNCTION get_trending_offers(UUID, INTEGER, INTEGER) IS 'Returns trending offers based on performance metrics';