-- =============================================================================
-- Affiliates Table
-- =============================================================================
-- This table stores affiliate partners and commission tracking from Salla API
-- Includes affiliate registration, commission rates, performance tracking
-- Links to stores for multi-store support

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create affiliates table
CREATE TABLE IF NOT EXISTS affiliates (
    -- Primary identification
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Salla API identifiers
    salla_affiliate_id VARCHAR(255) UNIQUE,
    salla_store_id VARCHAR(255) NOT NULL,
    
    -- Store relationship
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Affiliate identification
    affiliate_code VARCHAR(100) NOT NULL,
    affiliate_name VARCHAR(255) NOT NULL,
    affiliate_slug VARCHAR(255),
    display_name VARCHAR(255),
    
    -- Personal/Company information
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    company_name VARCHAR(255),
    business_type VARCHAR(50), -- 'individual', 'company', 'influencer', 'blogger', 'agency'
    tax_number VARCHAR(100),
    commercial_registration VARCHAR(100),
    
    -- Contact information
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    mobile VARCHAR(20),
    website_url VARCHAR(500),
    social_media_links JSONB DEFAULT '{}', -- {"instagram": "@username", "twitter": "@username"}
    
    -- Address information
    address_line_1 VARCHAR(255),
    address_line_2 VARCHAR(255),
    city VARCHAR(100),
    state_province VARCHAR(100),
    postal_code VARCHAR(20),
    country_code VARCHAR(2),
    
    -- Affiliate status and type
    affiliate_status VARCHAR(50) NOT NULL DEFAULT 'pending', -- 'pending', 'active', 'inactive', 'suspended', 'rejected', 'terminated'
    affiliate_type VARCHAR(50) DEFAULT 'standard', -- 'standard', 'premium', 'vip', 'influencer', 'corporate'
    tier_level VARCHAR(50) DEFAULT 'bronze', -- 'bronze', 'silver', 'gold', 'platinum', 'diamond'
    is_active BOOLEAN DEFAULT TRUE,
    is_verified BOOLEAN DEFAULT FALSE,
    
    -- Commission structure
    commission_type VARCHAR(50) DEFAULT 'percentage', -- 'percentage', 'fixed_amount', 'tiered', 'hybrid'
    commission_rate DECIMAL(5,4) DEFAULT 0, -- Percentage as decimal (e.g., 0.05 for 5%)
    commission_amount DECIMAL(15,4), -- Fixed commission amount
    minimum_commission DECIMAL(15,4) DEFAULT 0,
    maximum_commission DECIMAL(15,4),
    
    -- Tiered commission rates (JSONB for flexibility)
    tiered_rates JSONB DEFAULT '{}', -- {"0-1000": 0.05, "1001-5000": 0.07, "5001+": 0.10}
    
    -- Performance thresholds
    monthly_sales_target DECIMAL(15,4),
    quarterly_sales_target DECIMAL(15,4),
    annual_sales_target DECIMAL(15,4),
    minimum_monthly_sales DECIMAL(15,4) DEFAULT 0,
    
    -- Payment information
    payment_method VARCHAR(50) DEFAULT 'bank_transfer', -- 'bank_transfer', 'paypal', 'stripe', 'check', 'crypto'
    bank_name VARCHAR(255),
    bank_account_number VARCHAR(100),
    bank_iban VARCHAR(50),
    bank_swift_code VARCHAR(20),
    paypal_email VARCHAR(255),
    payment_schedule VARCHAR(50) DEFAULT 'monthly', -- 'weekly', 'bi_weekly', 'monthly', 'quarterly'
    minimum_payout_amount DECIMAL(15,4) DEFAULT 50,
    
    -- Tracking and attribution
    tracking_code VARCHAR(100) UNIQUE,
    referral_url VARCHAR(500),
    utm_source VARCHAR(255),
    utm_medium VARCHAR(255),
    utm_campaign VARCHAR(255),
    cookie_duration_days INTEGER DEFAULT 30,
    
    -- Performance metrics
    total_clicks INTEGER DEFAULT 0,
    total_conversions INTEGER DEFAULT 0,
    total_sales_amount DECIMAL(15,4) DEFAULT 0,
    total_commission_earned DECIMAL(15,4) DEFAULT 0,
    total_commission_paid DECIMAL(15,4) DEFAULT 0,
    pending_commission DECIMAL(15,4) DEFAULT 0,
    
    -- Conversion metrics
    conversion_rate DECIMAL(5,4) DEFAULT 0, -- Percentage as decimal
    average_order_value DECIMAL(15,4) DEFAULT 0,
    customer_lifetime_value DECIMAL(15,4) DEFAULT 0,
    return_customer_rate DECIMAL(5,4) DEFAULT 0,
    
    -- Time-based performance
    last_30_days_sales DECIMAL(15,4) DEFAULT 0,
    last_30_days_commission DECIMAL(15,4) DEFAULT 0,
    current_month_sales DECIMAL(15,4) DEFAULT 0,
    current_month_commission DECIMAL(15,4) DEFAULT 0,
    last_sale_date TIMESTAMPTZ,
    last_commission_date TIMESTAMPTZ,
    
    -- Product and category restrictions
    allowed_product_categories UUID[], -- Array of category IDs
    excluded_product_categories UUID[], -- Array of excluded category IDs
    allowed_product_ids UUID[], -- Array of specific product IDs
    excluded_product_ids UUID[], -- Array of excluded product IDs
    allowed_brands VARCHAR(255)[], -- Array of allowed brand names
    
    -- Geographic restrictions
    allowed_countries VARCHAR(2)[], -- Array of ISO country codes
    excluded_countries VARCHAR(2)[], -- Array of excluded country codes
    target_regions VARCHAR(100)[], -- Array of target region names
    
    -- Marketing materials and resources
    marketing_materials JSONB DEFAULT '{}', -- Links to banners, images, videos, etc.
    promotional_codes VARCHAR(100)[], -- Array of promotional codes for this affiliate
    custom_landing_pages JSONB DEFAULT '{}', -- Custom landing page URLs
    
    -- Agreement and legal
    agreement_signed BOOLEAN DEFAULT FALSE,
    agreement_date TIMESTAMPTZ,
    agreement_version VARCHAR(20),
    terms_accepted BOOLEAN DEFAULT FALSE,
    privacy_policy_accepted BOOLEAN DEFAULT FALSE,
    
    -- Recruitment and referrals
    recruited_by_affiliate_id UUID REFERENCES affiliates(id),
    recruitment_commission_rate DECIMAL(5,4) DEFAULT 0,
    total_recruited_affiliates INTEGER DEFAULT 0,
    recruitment_bonus_earned DECIMAL(15,4) DEFAULT 0,
    
    -- Communication preferences
    email_notifications BOOLEAN DEFAULT TRUE,
    sms_notifications BOOLEAN DEFAULT FALSE,
    newsletter_subscription BOOLEAN DEFAULT TRUE,
    performance_reports BOOLEAN DEFAULT TRUE,
    marketing_updates BOOLEAN DEFAULT TRUE,
    
    -- Application and approval
    application_date TIMESTAMPTZ DEFAULT NOW(),
    application_source VARCHAR(100), -- 'website', 'referral', 'social_media', 'email', 'phone'
    application_notes TEXT,
    approved_by_user_id UUID,
    approved_at TIMESTAMPTZ,
    rejection_reason TEXT,
    
    -- Account management
    account_manager_id UUID, -- Reference to staff member managing this affiliate
    priority_level INTEGER DEFAULT 0, -- Higher number = higher priority
    special_instructions TEXT,
    internal_notes TEXT,
    
    -- Fraud prevention
    risk_score INTEGER DEFAULT 0, -- 0-100, higher = more risky
    fraud_flags VARCHAR(100)[] DEFAULT '{}', -- Array of fraud indicators
    last_activity_check TIMESTAMPTZ,
    suspicious_activity_count INTEGER DEFAULT 0,
    
    -- Integration and sync
    last_sync_at TIMESTAMPTZ,
    sync_status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'synced', 'error'
    sync_error_message TEXT,
    external_affiliate_id VARCHAR(255), -- ID from external affiliate platforms
    
    -- API access
    api_access_enabled BOOLEAN DEFAULT FALSE,
    api_key VARCHAR(255),
    api_secret VARCHAR(255),
    api_rate_limit INTEGER DEFAULT 1000, -- Requests per hour
    last_api_access TIMESTAMPTZ,
    
    -- Metadata and custom fields
    metadata JSONB DEFAULT '{}',
    custom_fields JSONB DEFAULT '{}',
    tags VARCHAR(100)[] DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_login_at TIMESTAMPTZ,
    last_activity_at TIMESTAMPTZ
);

-- =============================================================================
-- Indexes for Performance
-- =============================================================================

-- Primary indexes
CREATE INDEX IF NOT EXISTS idx_affiliates_store_id ON affiliates(store_id);
CREATE INDEX IF NOT EXISTS idx_affiliates_salla_affiliate_id ON affiliates(salla_affiliate_id);
CREATE INDEX IF NOT EXISTS idx_affiliates_salla_store_id ON affiliates(salla_store_id);

-- Affiliate lookup indexes
CREATE UNIQUE INDEX IF NOT EXISTS idx_affiliates_store_code_unique ON affiliates(store_id, affiliate_code);
CREATE UNIQUE INDEX IF NOT EXISTS idx_affiliates_tracking_code ON affiliates(tracking_code);
CREATE INDEX IF NOT EXISTS idx_affiliates_email ON affiliates(email);
CREATE INDEX IF NOT EXISTS idx_affiliates_slug ON affiliates(affiliate_slug);
CREATE INDEX IF NOT EXISTS idx_affiliates_name_search ON affiliates USING gin(affiliate_name gin_trgm_ops);

-- Status and type indexes
CREATE INDEX IF NOT EXISTS idx_affiliates_status ON affiliates(affiliate_status);
CREATE INDEX IF NOT EXISTS idx_affiliates_active ON affiliates(is_active);
CREATE INDEX IF NOT EXISTS idx_affiliates_verified ON affiliates(is_verified);
CREATE INDEX IF NOT EXISTS idx_affiliates_type ON affiliates(affiliate_type);
CREATE INDEX IF NOT EXISTS idx_affiliates_tier ON affiliates(tier_level);

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_affiliates_total_sales ON affiliates(total_sales_amount DESC);
CREATE INDEX IF NOT EXISTS idx_affiliates_total_commission ON affiliates(total_commission_earned DESC);
CREATE INDEX IF NOT EXISTS idx_affiliates_conversion_rate ON affiliates(conversion_rate DESC);
CREATE INDEX IF NOT EXISTS idx_affiliates_last_sale ON affiliates(last_sale_date DESC);

-- Commission and payment indexes
CREATE INDEX IF NOT EXISTS idx_affiliates_pending_commission ON affiliates(pending_commission) WHERE pending_commission > 0;
CREATE INDEX IF NOT EXISTS idx_affiliates_payment_method ON affiliates(payment_method);
CREATE INDEX IF NOT EXISTS idx_affiliates_payment_schedule ON affiliates(payment_schedule);

-- Geographic and targeting indexes
CREATE INDEX IF NOT EXISTS idx_affiliates_country ON affiliates(country_code);
CREATE INDEX IF NOT EXISTS idx_affiliates_allowed_countries ON affiliates USING gin(allowed_countries);
CREATE INDEX IF NOT EXISTS idx_affiliates_target_regions ON affiliates USING gin(target_regions);

-- Product and category restrictions
CREATE INDEX IF NOT EXISTS idx_affiliates_allowed_categories ON affiliates USING gin(allowed_product_categories);
CREATE INDEX IF NOT EXISTS idx_affiliates_allowed_products ON affiliates USING gin(allowed_product_ids);
CREATE INDEX IF NOT EXISTS idx_affiliates_allowed_brands ON affiliates USING gin(allowed_brands);

-- Recruitment and referral indexes
CREATE INDEX IF NOT EXISTS idx_affiliates_recruited_by ON affiliates(recruited_by_affiliate_id);
CREATE INDEX IF NOT EXISTS idx_affiliates_recruitment_count ON affiliates(total_recruited_affiliates DESC);

-- Application and approval indexes
CREATE INDEX IF NOT EXISTS idx_affiliates_application_date ON affiliates(application_date DESC);
CREATE INDEX IF NOT EXISTS idx_affiliates_approved_by ON affiliates(approved_by_user_id);
CREATE INDEX IF NOT EXISTS idx_affiliates_approved_at ON affiliates(approved_at DESC);

-- Management and priority indexes
CREATE INDEX IF NOT EXISTS idx_affiliates_account_manager ON affiliates(account_manager_id);
CREATE INDEX IF NOT EXISTS idx_affiliates_priority ON affiliates(priority_level DESC);
CREATE INDEX IF NOT EXISTS idx_affiliates_risk_score ON affiliates(risk_score DESC);

-- Activity and engagement indexes
CREATE INDEX IF NOT EXISTS idx_affiliates_last_login ON affiliates(last_login_at DESC);
CREATE INDEX IF NOT EXISTS idx_affiliates_last_activity ON affiliates(last_activity_at DESC);
CREATE INDEX IF NOT EXISTS idx_affiliates_api_access ON affiliates(api_access_enabled) WHERE api_access_enabled = TRUE;

-- JSONB indexes
CREATE INDEX IF NOT EXISTS idx_affiliates_metadata ON affiliates USING gin(metadata);
CREATE INDEX IF NOT EXISTS idx_affiliates_custom_fields ON affiliates USING gin(custom_fields);
CREATE INDEX IF NOT EXISTS idx_affiliates_social_media ON affiliates USING gin(social_media_links);
CREATE INDEX IF NOT EXISTS idx_affiliates_tiered_rates ON affiliates USING gin(tiered_rates);
CREATE INDEX IF NOT EXISTS idx_affiliates_marketing_materials ON affiliates USING gin(marketing_materials);

-- Array indexes
CREATE INDEX IF NOT EXISTS idx_affiliates_tags ON affiliates USING gin(tags);
CREATE INDEX IF NOT EXISTS idx_affiliates_promotional_codes ON affiliates USING gin(promotional_codes);
CREATE INDEX IF NOT EXISTS idx_affiliates_fraud_flags ON affiliates USING gin(fraud_flags);

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_affiliates_store_active_status ON affiliates(store_id, is_active, affiliate_status);
CREATE INDEX IF NOT EXISTS idx_affiliates_type_tier_performance ON affiliates(affiliate_type, tier_level, total_sales_amount DESC);
CREATE INDEX IF NOT EXISTS idx_affiliates_sync_status ON affiliates(sync_status, last_sync_at);
CREATE INDEX IF NOT EXISTS idx_affiliates_commission_pending ON affiliates(pending_commission DESC, payment_schedule) WHERE pending_commission > 0;

-- =============================================================================
-- Triggers
-- =============================================================================

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_affiliates_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_affiliates_updated_at
    BEFORE UPDATE ON affiliates
    FOR EACH ROW
    EXECUTE FUNCTION update_affiliates_updated_at();

-- Trigger to calculate performance metrics
CREATE OR REPLACE FUNCTION update_affiliate_metrics()
RETURNS TRIGGER AS $$
BEGIN
    -- Calculate conversion rate
    IF NEW.total_clicks > 0 THEN
        NEW.conversion_rate = NEW.total_conversions::DECIMAL / NEW.total_clicks;
    ELSE
        NEW.conversion_rate = 0;
    END IF;
    
    -- Calculate average order value
    IF NEW.total_conversions > 0 THEN
        NEW.average_order_value = NEW.total_sales_amount / NEW.total_conversions;
    ELSE
        NEW.average_order_value = 0;
    END IF;
    
    -- Update pending commission
    NEW.pending_commission = NEW.total_commission_earned - NEW.total_commission_paid;
    
    -- Update tier level based on performance
    IF NEW.total_sales_amount >= 100000 THEN
        NEW.tier_level = 'diamond';
    ELSIF NEW.total_sales_amount >= 50000 THEN
        NEW.tier_level = 'platinum';
    ELSIF NEW.total_sales_amount >= 25000 THEN
        NEW.tier_level = 'gold';
    ELSIF NEW.total_sales_amount >= 10000 THEN
        NEW.tier_level = 'silver';
    ELSE
        NEW.tier_level = 'bronze';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_affiliate_metrics
    BEFORE UPDATE ON affiliates
    FOR EACH ROW
    EXECUTE FUNCTION update_affiliate_metrics();

-- Trigger to set initial values
CREATE OR REPLACE FUNCTION set_initial_affiliate_values()
RETURNS TRIGGER AS $$
BEGIN
    -- Generate tracking code if not provided
    IF NEW.tracking_code IS NULL OR NEW.tracking_code = '' THEN
        NEW.tracking_code = 'AFF_' || upper(substring(NEW.affiliate_code from 1 for 10)) || '_' || extract(epoch from now())::text;
    END IF;
    
    -- Generate slug if not provided
    IF NEW.affiliate_slug IS NULL OR NEW.affiliate_slug = '' THEN
        NEW.affiliate_slug = lower(regexp_replace(NEW.affiliate_name, '[^a-zA-Z0-9]+', '-', 'g'));
    END IF;
    
    -- Generate API key if API access is enabled
    IF NEW.api_access_enabled AND (NEW.api_key IS NULL OR NEW.api_key = '') THEN
        NEW.api_key = 'ak_' || encode(gen_random_bytes(32), 'hex');
        NEW.api_secret = 'as_' || encode(gen_random_bytes(32), 'hex');
    END IF;
    
    -- Set display name if not provided
    IF NEW.display_name IS NULL OR NEW.display_name = '' THEN
        NEW.display_name = COALESCE(NEW.company_name, NEW.first_name || ' ' || NEW.last_name, NEW.affiliate_name);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_set_initial_affiliate_values
    BEFORE INSERT ON affiliates
    FOR EACH ROW
    EXECUTE FUNCTION set_initial_affiliate_values();

-- =============================================================================
-- Helper Functions
-- =============================================================================

-- Function: Calculate commission for a sale
CREATE OR REPLACE FUNCTION calculate_affiliate_commission(
    p_affiliate_id UUID,
    p_sale_amount DECIMAL(15,4),
    p_product_ids UUID[] DEFAULT '{}'
)
RETURNS DECIMAL(15,4) AS $$
DECLARE
    affiliate_record affiliates%ROWTYPE;
    commission_amount DECIMAL(15,4) := 0;
    tier_rate DECIMAL(5,4);
BEGIN
    -- Get affiliate details
    SELECT * INTO affiliate_record FROM affiliates WHERE id = p_affiliate_id;
    
    IF NOT FOUND OR NOT affiliate_record.is_active THEN
        RETURN 0;
    END IF;
    
    -- Calculate commission based on type
    CASE affiliate_record.commission_type
        WHEN 'percentage' THEN
            commission_amount = p_sale_amount * affiliate_record.commission_rate;
        WHEN 'fixed_amount' THEN
            commission_amount = affiliate_record.commission_amount;
        WHEN 'tiered' THEN
            -- Get appropriate tier rate based on total sales
            SELECT 
                CASE 
                    WHEN affiliate_record.total_sales_amount >= 50000 THEN 0.10
                    WHEN affiliate_record.total_sales_amount >= 25000 THEN 0.08
                    WHEN affiliate_record.total_sales_amount >= 10000 THEN 0.06
                    ELSE 0.05
                END INTO tier_rate;
            commission_amount = p_sale_amount * tier_rate;
        WHEN 'hybrid' THEN
            -- Combination of fixed amount and percentage
            commission_amount = COALESCE(affiliate_record.commission_amount, 0) + 
                               (p_sale_amount * COALESCE(affiliate_record.commission_rate, 0));
    END CASE;
    
    -- Apply minimum and maximum limits
    IF affiliate_record.minimum_commission IS NOT NULL THEN
        commission_amount = GREATEST(commission_amount, affiliate_record.minimum_commission);
    END IF;
    
    IF affiliate_record.maximum_commission IS NOT NULL THEN
        commission_amount = LEAST(commission_amount, affiliate_record.maximum_commission);
    END IF;
    
    RETURN commission_amount;
END;
$$ LANGUAGE plpgsql;

-- Function: Record affiliate sale
CREATE OR REPLACE FUNCTION record_affiliate_sale(
    p_affiliate_id UUID,
    p_order_id UUID,
    p_sale_amount DECIMAL(15,4),
    p_commission_amount DECIMAL(15,4)
)
RETURNS BOOLEAN AS $$
BEGIN
    -- Update affiliate statistics
    UPDATE affiliates
    SET 
        total_conversions = total_conversions + 1,
        total_sales_amount = total_sales_amount + p_sale_amount,
        total_commission_earned = total_commission_earned + p_commission_amount,
        last_sale_date = NOW(),
        last_commission_date = NOW(),
        last_activity_at = NOW(),
        current_month_sales = current_month_sales + p_sale_amount,
        current_month_commission = current_month_commission + p_commission_amount,
        updated_at = NOW()
    WHERE id = p_affiliate_id;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- Function: Get affiliate performance summary
CREATE OR REPLACE FUNCTION get_affiliate_performance(
    p_affiliate_id UUID,
    p_start_date TIMESTAMPTZ DEFAULT NULL,
    p_end_date TIMESTAMPTZ DEFAULT NULL
)
RETURNS TABLE (
    total_clicks BIGINT,
    total_conversions BIGINT,
    total_sales DECIMAL(15,4),
    total_commission DECIMAL(15,4),
    conversion_rate DECIMAL(5,4),
    average_order_value DECIMAL(15,4),
    commission_rate DECIMAL(5,4)
) AS $$
DECLARE
    start_filter TIMESTAMPTZ := COALESCE(p_start_date, date_trunc('month', NOW()));
    end_filter TIMESTAMPTZ := COALESCE(p_end_date, NOW());
BEGIN
    RETURN QUERY
    SELECT 
        a.total_clicks::BIGINT,
        a.total_conversions::BIGINT,
        a.total_sales_amount,
        a.total_commission_earned,
        a.conversion_rate,
        a.average_order_value,
        a.commission_rate
    FROM affiliates a
    WHERE a.id = p_affiliate_id;
END;
$$ LANGUAGE plpgsql;

-- Function: Get top performing affiliates
CREATE OR REPLACE FUNCTION get_top_affiliates(
    p_store_id UUID,
    p_metric VARCHAR(50) DEFAULT 'sales', -- 'sales', 'commission', 'conversions', 'conversion_rate'
    p_limit INTEGER DEFAULT 10,
    p_days_back INTEGER DEFAULT 30
)
RETURNS TABLE (
    affiliate_id UUID,
    affiliate_name VARCHAR(255),
    affiliate_code VARCHAR(100),
    tier_level VARCHAR(50),
    metric_value DECIMAL(15,4)
) AS $$
BEGIN
    RETURN QUERY
    EXECUTE format('
        SELECT 
            a.id,
            a.affiliate_name,
            a.affiliate_code,
            a.tier_level,
            a.%I as metric_value
        FROM affiliates a
        WHERE a.store_id = $1
            AND a.is_active = TRUE
            AND a.last_activity_at >= NOW() - INTERVAL ''%s days''
        ORDER BY a.%I DESC
        LIMIT $2
    ', 
    CASE p_metric
        WHEN 'sales' THEN 'total_sales_amount'
        WHEN 'commission' THEN 'total_commission_earned'
        WHEN 'conversions' THEN 'total_conversions'
        WHEN 'conversion_rate' THEN 'conversion_rate'
        ELSE 'total_sales_amount'
    END,
    p_days_back,
    CASE p_metric
        WHEN 'sales' THEN 'total_sales_amount'
        WHEN 'commission' THEN 'total_commission_earned'
        WHEN 'conversions' THEN 'total_conversions'
        WHEN 'conversion_rate' THEN 'conversion_rate'
        ELSE 'total_sales_amount'
    END
    ) USING p_store_id, p_limit;
END;
$$ LANGUAGE plpgsql;

-- Function: Get affiliates due for payment
CREATE OR REPLACE FUNCTION get_affiliates_due_payment(
    p_store_id UUID,
    p_minimum_amount DECIMAL(15,4) DEFAULT 50
)
RETURNS TABLE (
    affiliate_id UUID,
    affiliate_name VARCHAR(255),
    email VARCHAR(255),
    pending_commission DECIMAL(15,4),
    payment_method VARCHAR(50),
    payment_schedule VARCHAR(50),
    last_payment_date TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.id,
        a.affiliate_name,
        a.email,
        a.pending_commission,
        a.payment_method,
        a.payment_schedule,
        a.last_commission_date
    FROM affiliates a
    WHERE a.store_id = p_store_id
        AND a.is_active = TRUE
        AND a.pending_commission >= p_minimum_amount
        AND a.pending_commission >= a.minimum_payout_amount
    ORDER BY a.pending_commission DESC;
END;
$$ LANGUAGE plpgsql;

-- Function: Get store affiliate statistics
CREATE OR REPLACE FUNCTION get_store_affiliate_stats(p_store_id UUID)
RETURNS TABLE (
    total_affiliates BIGINT,
    active_affiliates BIGINT,
    pending_affiliates BIGINT,
    total_sales_generated DECIMAL(15,4),
    total_commission_paid DECIMAL(15,4),
    pending_commission_total DECIMAL(15,4),
    average_conversion_rate DECIMAL(5,4),
    top_affiliate_name VARCHAR(255)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::BIGINT as total_affiliates,
        COUNT(CASE WHEN a.affiliate_status = 'active' THEN 1 END)::BIGINT as active_affiliates,
        COUNT(CASE WHEN a.affiliate_status = 'pending' THEN 1 END)::BIGINT as pending_affiliates,
        COALESCE(SUM(a.total_sales_amount), 0) as total_sales_generated,
        COALESCE(SUM(a.total_commission_paid), 0) as total_commission_paid,
        COALESCE(SUM(a.pending_commission), 0) as pending_commission_total,
        COALESCE(AVG(a.conversion_rate), 0) as average_conversion_rate,
        (
            SELECT a2.affiliate_name
            FROM affiliates a2
            WHERE a2.store_id = p_store_id
            ORDER BY a2.total_sales_amount DESC
            LIMIT 1
        ) as top_affiliate_name
    FROM affiliates a
    WHERE a.store_id = p_store_id;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Comments
-- =============================================================================

COMMENT ON TABLE affiliates IS 'Stores affiliate partners and commission tracking from Salla API';
COMMENT ON COLUMN affiliates.id IS 'Primary key for the affiliate';
COMMENT ON COLUMN affiliates.salla_affiliate_id IS 'Unique identifier from Salla API';
COMMENT ON COLUMN affiliates.store_id IS 'Reference to the store this affiliate belongs to';
COMMENT ON COLUMN affiliates.affiliate_code IS 'Unique affiliate code for tracking';
COMMENT ON COLUMN affiliates.commission_type IS 'Type of commission: percentage, fixed_amount, tiered, hybrid';
COMMENT ON COLUMN affiliates.tracking_code IS 'Unique tracking code for attribution';
COMMENT ON COLUMN affiliates.tier_level IS 'Affiliate tier based on performance: bronze, silver, gold, platinum, diamond';
COMMENT ON COLUMN affiliates.pending_commission IS 'Commission earned but not yet paid';
COMMENT ON COLUMN affiliates.metadata IS 'Additional flexible data storage for affiliate information';

COMMENT ON FUNCTION calculate_affiliate_commission(UUID, DECIMAL, UUID[]) IS 'Calculates commission amount for an affiliate sale';
COMMENT ON FUNCTION record_affiliate_sale(UUID, UUID, DECIMAL, DECIMAL) IS 'Records a sale and updates affiliate statistics';
COMMENT ON FUNCTION get_affiliate_performance(UUID, TIMESTAMPTZ, TIMESTAMPTZ) IS 'Returns performance metrics for an affiliate';
COMMENT ON FUNCTION get_top_affiliates(UUID, VARCHAR, INTEGER, INTEGER) IS 'Returns top performing affiliates by specified metric';
COMMENT ON FUNCTION get_affiliates_due_payment(UUID, DECIMAL) IS 'Returns affiliates with pending commission above threshold';
COMMENT ON FUNCTION get_store_affiliate_stats(UUID) IS 'Returns comprehensive affiliate statistics for a store';