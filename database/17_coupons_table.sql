-- =============================================================================
-- Coupons Table
-- =============================================================================
-- This table stores coupon and discount information from Salla API
-- Includes usage conditions, expiry dates, and coupon codes
-- Links to stores for multi-store support

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create coupons table
CREATE TABLE IF NOT EXISTS coupons (
    -- Primary identification
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Salla API identifiers
    salla_coupon_id VARCHAR(255) UNIQUE,
    salla_store_id VARCHAR(255) NOT NULL,
    
    -- Store relationship
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Coupon identification
    coupon_code VARCHAR(100) NOT NULL,
    coupon_name VARCHAR(255) NOT NULL,
    coupon_description TEXT,
    
    -- Coupon type and discount details
    coupon_type VARCHAR(50) NOT NULL DEFAULT 'percentage', -- 'percentage', 'fixed_amount', 'free_shipping', 'buy_x_get_y'
    discount_type VARCHAR(50) NOT NULL DEFAULT 'percentage', -- 'percentage', 'fixed_amount'
    discount_value DECIMAL(15,4) NOT NULL DEFAULT 0,
    discount_percentage DECIMAL(5,2), -- For percentage discounts (0-100)
    max_discount_amount DECIMAL(15,4), -- Maximum discount for percentage coupons
    currency_code VARCHAR(3) DEFAULT 'SAR',
    
    -- Usage conditions
    minimum_order_amount DECIMAL(15,4) DEFAULT 0,
    maximum_order_amount DECIMAL(15,4),
    minimum_quantity INTEGER DEFAULT 1,
    maximum_quantity INTEGER,
    
    -- Usage limits
    usage_limit INTEGER, -- Total usage limit
    usage_limit_per_customer INTEGER DEFAULT 1,
    usage_count INTEGER DEFAULT 0,
    remaining_uses INTEGER,
    
    -- Date and time restrictions
    start_date TIMESTAMPTZ,
    end_date TIMESTAMPTZ,
    start_time TIME,
    end_time TIME,
    valid_days_of_week INTEGER[], -- Array of day numbers (1=Monday, 7=Sunday)
    
    -- Status and availability
    coupon_status VARCHAR(50) NOT NULL DEFAULT 'active', -- 'active', 'inactive', 'expired', 'used_up', 'scheduled'
    is_active BOOLEAN DEFAULT TRUE,
    is_public BOOLEAN DEFAULT TRUE, -- Public or private coupon
    is_featured BOOLEAN DEFAULT FALSE,
    
    -- Customer restrictions
    customer_eligibility VARCHAR(50) DEFAULT 'all', -- 'all', 'new_customers', 'existing_customers', 'specific_customers', 'customer_groups'
    eligible_customer_ids UUID[], -- Array of specific customer IDs
    eligible_customer_groups VARCHAR(100)[], -- Array of customer group names
    excluded_customer_ids UUID[], -- Array of excluded customer IDs
    
    -- Product and category restrictions
    applicable_to VARCHAR(50) DEFAULT 'all', -- 'all', 'specific_products', 'specific_categories', 'specific_brands'
    included_product_ids UUID[], -- Array of included product IDs
    excluded_product_ids UUID[], -- Array of excluded product IDs
    included_category_ids UUID[], -- Array of included category IDs
    excluded_category_ids UUID[], -- Array of excluded category IDs
    included_brand_names VARCHAR(255)[], -- Array of included brand names
    excluded_brand_names VARCHAR(255)[], -- Array of excluded brand names
    
    -- Geographic restrictions
    allowed_countries VARCHAR(2)[], -- Array of ISO country codes
    excluded_countries VARCHAR(2)[], -- Array of excluded country codes
    allowed_cities VARCHAR(255)[], -- Array of allowed city names
    excluded_cities VARCHAR(255)[], -- Array of excluded city names
    
    -- Buy X Get Y conditions (for BXGY coupons)
    buy_quantity INTEGER,
    get_quantity INTEGER,
    buy_product_ids UUID[], -- Products that must be bought
    get_product_ids UUID[], -- Products that will be given
    apply_to_cheapest BOOLEAN DEFAULT TRUE, -- Apply discount to cheapest items
    
    -- Free shipping conditions
    free_shipping_threshold DECIMAL(15,4),
    shipping_methods VARCHAR(100)[], -- Applicable shipping methods
    
    -- Combination rules
    can_combine_with_other_coupons BOOLEAN DEFAULT FALSE,
    can_combine_with_offers BOOLEAN DEFAULT TRUE,
    priority_level INTEGER DEFAULT 0, -- Higher number = higher priority
    
    -- Display and marketing
    display_name VARCHAR(255),
    marketing_message TEXT,
    terms_and_conditions TEXT,
    image_url VARCHAR(500),
    banner_url VARCHAR(500),
    
    -- Tracking and analytics
    source VARCHAR(100), -- 'manual', 'campaign', 'api', 'import'
    campaign_id VARCHAR(255),
    utm_source VARCHAR(255),
    utm_medium VARCHAR(255),
    utm_campaign VARCHAR(255),
    
    -- Performance metrics
    total_revenue_generated DECIMAL(15,4) DEFAULT 0,
    total_orders_count INTEGER DEFAULT 0,
    conversion_rate DECIMAL(5,4) DEFAULT 0, -- Percentage as decimal
    average_order_value DECIMAL(15,4) DEFAULT 0,
    
    -- Auto-generation settings
    is_auto_generated BOOLEAN DEFAULT FALSE,
    generation_rule JSONB, -- Rules for auto-generating similar coupons
    parent_coupon_id UUID REFERENCES coupons(id),
    
    -- Integration and sync
    last_sync_at TIMESTAMPTZ,
    sync_status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'synced', 'error'
    sync_error_message TEXT,
    
    -- Metadata and custom fields
    metadata JSONB DEFAULT '{}',
    custom_fields JSONB DEFAULT '{}',
    tags VARCHAR(100)[] DEFAULT '{}',
    
    -- Internal notes
    internal_notes TEXT,
    created_by_user_id UUID,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================================
-- Indexes for Performance
-- =============================================================================

-- Primary indexes
CREATE INDEX IF NOT EXISTS idx_coupons_store_id ON coupons(store_id);
CREATE INDEX IF NOT EXISTS idx_coupons_salla_coupon_id ON coupons(salla_coupon_id);
CREATE INDEX IF NOT EXISTS idx_coupons_salla_store_id ON coupons(salla_store_id);

-- Coupon lookup indexes
CREATE UNIQUE INDEX IF NOT EXISTS idx_coupons_store_code_unique ON coupons(store_id, coupon_code);
CREATE INDEX IF NOT EXISTS idx_coupons_code_active ON coupons(coupon_code) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_coupons_name_search ON coupons USING gin(coupon_name gin_trgm_ops);

-- Status and date indexes
CREATE INDEX IF NOT EXISTS idx_coupons_status ON coupons(coupon_status);
CREATE INDEX IF NOT EXISTS idx_coupons_active ON coupons(is_active);
CREATE INDEX IF NOT EXISTS idx_coupons_dates ON coupons(start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_coupons_active_dates ON coupons(start_date, end_date) WHERE is_active = TRUE;

-- Usage and performance indexes
CREATE INDEX IF NOT EXISTS idx_coupons_usage ON coupons(usage_count, usage_limit);
CREATE INDEX IF NOT EXISTS idx_coupons_remaining_uses ON coupons(remaining_uses) WHERE remaining_uses > 0;
CREATE INDEX IF NOT EXISTS idx_coupons_performance ON coupons(total_revenue_generated DESC, total_orders_count DESC);

-- Customer and product restriction indexes
CREATE INDEX IF NOT EXISTS idx_coupons_customer_eligibility ON coupons(customer_eligibility);
CREATE INDEX IF NOT EXISTS idx_coupons_applicable_to ON coupons(applicable_to);
CREATE INDEX IF NOT EXISTS idx_coupons_eligible_customers ON coupons USING gin(eligible_customer_ids);
CREATE INDEX IF NOT EXISTS idx_coupons_included_products ON coupons USING gin(included_product_ids);
CREATE INDEX IF NOT EXISTS idx_coupons_included_categories ON coupons USING gin(included_category_ids);

-- Geographic and marketing indexes
CREATE INDEX IF NOT EXISTS idx_coupons_countries ON coupons USING gin(allowed_countries);
CREATE INDEX IF NOT EXISTS idx_coupons_featured ON coupons(is_featured) WHERE is_featured = TRUE;
CREATE INDEX IF NOT EXISTS idx_coupons_public ON coupons(is_public);
CREATE INDEX IF NOT EXISTS idx_coupons_campaign ON coupons(campaign_id);

-- JSONB indexes
CREATE INDEX IF NOT EXISTS idx_coupons_metadata ON coupons USING gin(metadata);
CREATE INDEX IF NOT EXISTS idx_coupons_custom_fields ON coupons USING gin(custom_fields);
CREATE INDEX IF NOT EXISTS idx_coupons_generation_rule ON coupons USING gin(generation_rule);

-- Array indexes
CREATE INDEX IF NOT EXISTS idx_coupons_tags ON coupons USING gin(tags);
CREATE INDEX IF NOT EXISTS idx_coupons_valid_days ON coupons USING gin(valid_days_of_week);

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_coupons_store_active_dates ON coupons(store_id, is_active, start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_coupons_type_status ON coupons(coupon_type, coupon_status);
CREATE INDEX IF NOT EXISTS idx_coupons_sync_status ON coupons(sync_status, last_sync_at);

-- =============================================================================
-- Triggers
-- =============================================================================

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_coupons_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_coupons_updated_at
    BEFORE UPDATE ON coupons
    FOR EACH ROW
    EXECUTE FUNCTION update_coupons_updated_at();

-- Trigger to update remaining uses
CREATE OR REPLACE FUNCTION update_coupon_remaining_uses()
RETURNS TRIGGER AS $$
BEGIN
    -- Update remaining uses when usage_count changes
    IF NEW.usage_limit IS NOT NULL AND NEW.usage_count != OLD.usage_count THEN
        NEW.remaining_uses = GREATEST(0, NEW.usage_limit - NEW.usage_count);
    END IF;
    
    -- Update status based on usage and dates
    IF NEW.remaining_uses = 0 AND NEW.usage_limit IS NOT NULL THEN
        NEW.coupon_status = 'used_up';
        NEW.is_active = FALSE;
    ELSIF NEW.end_date IS NOT NULL AND NEW.end_date < NOW() THEN
        NEW.coupon_status = 'expired';
        NEW.is_active = FALSE;
    ELSIF NEW.start_date IS NOT NULL AND NEW.start_date > NOW() THEN
        NEW.coupon_status = 'scheduled';
    ELSIF NEW.is_active = TRUE THEN
        NEW.coupon_status = 'active';
    ELSE
        NEW.coupon_status = 'inactive';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_coupon_remaining_uses
    BEFORE UPDATE ON coupons
    FOR EACH ROW
    EXECUTE FUNCTION update_coupon_remaining_uses();

-- Trigger to set initial remaining uses
CREATE OR REPLACE FUNCTION set_initial_coupon_values()
RETURNS TRIGGER AS $$
BEGIN
    -- Set initial remaining uses
    IF NEW.usage_limit IS NOT NULL THEN
        NEW.remaining_uses = NEW.usage_limit;
    END IF;
    
    -- Set initial status based on dates
    IF NEW.end_date IS NOT NULL AND NEW.end_date < NOW() THEN
        NEW.coupon_status = 'expired';
        NEW.is_active = FALSE;
    ELSIF NEW.start_date IS NOT NULL AND NEW.start_date > NOW() THEN
        NEW.coupon_status = 'scheduled';
    ELSIF NEW.is_active = TRUE THEN
        NEW.coupon_status = 'active';
    ELSE
        NEW.coupon_status = 'inactive';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_set_initial_coupon_values
    BEFORE INSERT ON coupons
    FOR EACH ROW
    EXECUTE FUNCTION set_initial_coupon_values();

-- =============================================================================
-- Helper Functions
-- =============================================================================

-- Function: Check if coupon is valid for a specific order
CREATE OR REPLACE FUNCTION is_coupon_valid(
    p_coupon_id UUID,
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
    coupon_record coupons%ROWTYPE;
    calculated_discount DECIMAL(15,4) := 0;
BEGIN
    -- Get coupon details
    SELECT * INTO coupon_record FROM coupons WHERE id = p_coupon_id;
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Coupon not found', 0::DECIMAL(15,4);
        RETURN;
    END IF;
    
    -- Check if coupon is active
    IF NOT coupon_record.is_active THEN
        RETURN QUERY SELECT FALSE, 'Coupon is not active', 0::DECIMAL(15,4);
        RETURN;
    END IF;
    
    -- Check date validity
    IF coupon_record.start_date IS NOT NULL AND coupon_record.start_date > NOW() THEN
        RETURN QUERY SELECT FALSE, 'Coupon is not yet valid', 0::DECIMAL(15,4);
        RETURN;
    END IF;
    
    IF coupon_record.end_date IS NOT NULL AND coupon_record.end_date < NOW() THEN
        RETURN QUERY SELECT FALSE, 'Coupon has expired', 0::DECIMAL(15,4);
        RETURN;
    END IF;
    
    -- Check usage limits
    IF coupon_record.usage_limit IS NOT NULL AND coupon_record.usage_count >= coupon_record.usage_limit THEN
        RETURN QUERY SELECT FALSE, 'Coupon usage limit reached', 0::DECIMAL(15,4);
        RETURN;
    END IF;
    
    -- Check minimum order amount
    IF p_order_amount < coupon_record.minimum_order_amount THEN
        RETURN QUERY SELECT FALSE, 'Order amount below minimum required', 0::DECIMAL(15,4);
        RETURN;
    END IF;
    
    -- Check maximum order amount
    IF coupon_record.maximum_order_amount IS NOT NULL AND p_order_amount > coupon_record.maximum_order_amount THEN
        RETURN QUERY SELECT FALSE, 'Order amount exceeds maximum allowed', 0::DECIMAL(15,4);
        RETURN;
    END IF;
    
    -- Check customer eligibility
    IF p_customer_id IS NOT NULL THEN
        CASE coupon_record.customer_eligibility
            WHEN 'specific_customers' THEN
                IF NOT (p_customer_id = ANY(coupon_record.eligible_customer_ids)) THEN
                    RETURN QUERY SELECT FALSE, 'Customer not eligible for this coupon', 0::DECIMAL(15,4);
                    RETURN;
                END IF;
            WHEN 'new_customers' THEN
                -- Check if customer has previous orders (simplified check)
                IF EXISTS (SELECT 1 FROM orders WHERE customer_id = p_customer_id LIMIT 1) THEN
                    RETURN QUERY SELECT FALSE, 'Coupon only valid for new customers', 0::DECIMAL(15,4);
                    RETURN;
                END IF;
        END CASE;
        
        -- Check excluded customers
        IF p_customer_id = ANY(coupon_record.excluded_customer_ids) THEN
            RETURN QUERY SELECT FALSE, 'Customer is excluded from this coupon', 0::DECIMAL(15,4);
            RETURN;
        END IF;
    END IF;
    
    -- Check geographic restrictions
    IF p_country_code IS NOT NULL THEN
        IF array_length(coupon_record.allowed_countries, 1) > 0 AND NOT (p_country_code = ANY(coupon_record.allowed_countries)) THEN
            RETURN QUERY SELECT FALSE, 'Coupon not valid in this country', 0::DECIMAL(15,4);
            RETURN;
        END IF;
        
        IF p_country_code = ANY(coupon_record.excluded_countries) THEN
            RETURN QUERY SELECT FALSE, 'Coupon not valid in this country', 0::DECIMAL(15,4);
            RETURN;
        END IF;
    END IF;
    
    -- Calculate discount amount
    CASE coupon_record.discount_type
        WHEN 'percentage' THEN
            calculated_discount = p_order_amount * (coupon_record.discount_percentage / 100);
            IF coupon_record.max_discount_amount IS NOT NULL THEN
                calculated_discount = LEAST(calculated_discount, coupon_record.max_discount_amount);
            END IF;
        WHEN 'fixed_amount' THEN
            calculated_discount = coupon_record.discount_value;
    END CASE;
    
    -- Ensure discount doesn't exceed order amount
    calculated_discount = LEAST(calculated_discount, p_order_amount);
    
    RETURN QUERY SELECT TRUE, 'Coupon is valid', calculated_discount;
END;
$$ LANGUAGE plpgsql;

-- Function: Apply coupon to order (increment usage)
CREATE OR REPLACE FUNCTION apply_coupon(
    p_coupon_id UUID,
    p_order_id UUID,
    p_customer_id UUID,
    p_discount_amount DECIMAL(15,4)
)
RETURNS BOOLEAN AS $$
DECLARE
    coupon_record coupons%ROWTYPE;
BEGIN
    -- Get coupon details with row lock
    SELECT * INTO coupon_record FROM coupons WHERE id = p_coupon_id FOR UPDATE;
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Check usage limit one more time (race condition protection)
    IF coupon_record.usage_limit IS NOT NULL AND coupon_record.usage_count >= coupon_record.usage_limit THEN
        RETURN FALSE;
    END IF;
    
    -- Update coupon usage statistics
    UPDATE coupons
    SET 
        usage_count = usage_count + 1,
        total_orders_count = total_orders_count + 1,
        total_revenue_generated = total_revenue_generated + p_discount_amount,
        updated_at = NOW()
    WHERE id = p_coupon_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Function: Get store coupon statistics
CREATE OR REPLACE FUNCTION get_store_coupon_stats(p_store_id UUID)
RETURNS TABLE (
    total_coupons BIGINT,
    active_coupons BIGINT,
    expired_coupons BIGINT,
    used_up_coupons BIGINT,
    total_usage BIGINT,
    total_revenue_generated DECIMAL(15,4),
    average_discount_per_use DECIMAL(15,4),
    most_used_coupon_code VARCHAR(100)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::BIGINT as total_coupons,
        COUNT(CASE WHEN c.coupon_status = 'active' THEN 1 END)::BIGINT as active_coupons,
        COUNT(CASE WHEN c.coupon_status = 'expired' THEN 1 END)::BIGINT as expired_coupons,
        COUNT(CASE WHEN c.coupon_status = 'used_up' THEN 1 END)::BIGINT as used_up_coupons,
        COALESCE(SUM(c.usage_count), 0)::BIGINT as total_usage,
        COALESCE(SUM(c.total_revenue_generated), 0) as total_revenue_generated,
        CASE 
            WHEN SUM(c.usage_count) > 0 THEN SUM(c.total_revenue_generated) / SUM(c.usage_count)
            ELSE 0
        END as average_discount_per_use,
        (
            SELECT c2.coupon_code
            FROM coupons c2
            WHERE c2.store_id = p_store_id
            ORDER BY c2.usage_count DESC
            LIMIT 1
        ) as most_used_coupon_code
    FROM coupons c
    WHERE c.store_id = p_store_id;
END;
$$ LANGUAGE plpgsql;

-- Function: Get expiring coupons
CREATE OR REPLACE FUNCTION get_expiring_coupons(
    p_store_id UUID,
    p_days_ahead INTEGER DEFAULT 7
)
RETURNS TABLE (
    coupon_id UUID,
    coupon_code VARCHAR(100),
    coupon_name VARCHAR(255),
    end_date TIMESTAMPTZ,
    days_until_expiry INTEGER,
    usage_count INTEGER,
    remaining_uses INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.coupon_code,
        c.coupon_name,
        c.end_date,
        EXTRACT(DAY FROM c.end_date - NOW())::INTEGER as days_until_expiry,
        c.usage_count,
        c.remaining_uses
    FROM coupons c
    WHERE c.store_id = p_store_id
        AND c.is_active = TRUE
        AND c.end_date IS NOT NULL
        AND c.end_date BETWEEN NOW() AND NOW() + INTERVAL '%s days'
    ORDER BY c.end_date ASC;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Comments
-- =============================================================================

COMMENT ON TABLE coupons IS 'Stores coupon and discount information from Salla API';
COMMENT ON COLUMN coupons.id IS 'Primary key for the coupon';
COMMENT ON COLUMN coupons.salla_coupon_id IS 'Unique identifier from Salla API';
COMMENT ON COLUMN coupons.store_id IS 'Reference to the store this coupon belongs to';
COMMENT ON COLUMN coupons.coupon_code IS 'The actual coupon code customers enter';
COMMENT ON COLUMN coupons.coupon_type IS 'Type of coupon: percentage, fixed_amount, free_shipping, buy_x_get_y';
COMMENT ON COLUMN coupons.discount_value IS 'Fixed discount amount or percentage value';
COMMENT ON COLUMN coupons.usage_limit IS 'Maximum number of times this coupon can be used';
COMMENT ON COLUMN coupons.customer_eligibility IS 'Who can use this coupon: all, new_customers, existing_customers, etc.';
COMMENT ON COLUMN coupons.applicable_to IS 'What this coupon applies to: all, specific_products, specific_categories, etc.';
COMMENT ON COLUMN coupons.metadata IS 'Additional flexible data storage for coupon information';

COMMENT ON FUNCTION is_coupon_valid(UUID, UUID, DECIMAL, UUID[], UUID[], VARCHAR, VARCHAR) IS 'Validates if a coupon can be applied to a specific order';
COMMENT ON FUNCTION apply_coupon(UUID, UUID, UUID, DECIMAL) IS 'Applies a coupon to an order and updates usage statistics';
COMMENT ON FUNCTION get_store_coupon_stats(UUID) IS 'Returns comprehensive coupon statistics for a store';
COMMENT ON FUNCTION get_expiring_coupons(UUID, INTEGER) IS 'Returns coupons that are expiring within specified days';