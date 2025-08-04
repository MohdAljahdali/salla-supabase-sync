-- =====================================================
-- Abandoned Carts Table
-- =====================================================
-- This table stores information about abandoned shopping carts
-- to help with cart recovery campaigns and analytics

CREATE TABLE IF NOT EXISTS abandoned_carts (
    -- Primary identification
    id BIGSERIAL PRIMARY KEY,
    salla_cart_id VARCHAR UNIQUE, -- Salla cart ID if available
    
    -- Store relationship
    store_id BIGINT NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Customer information
    customer_id BIGINT REFERENCES customers(id) ON DELETE SET NULL,
    customer_email VARCHAR(255),
    customer_phone VARCHAR(50),
    customer_name VARCHAR(255),
    guest_session_id VARCHAR(255), -- For guest users
    
    -- Cart details
    cart_token VARCHAR(255) UNIQUE,
    cart_status VARCHAR(50) DEFAULT 'abandoned' CHECK (cart_status IN (
        'active', 'abandoned', 'recovered', 'expired', 'converted'
    )),
    
    -- Cart contents
    total_items INTEGER DEFAULT 0,
    total_quantity INTEGER DEFAULT 0,
    subtotal DECIMAL(15,2) DEFAULT 0,
    tax_amount DECIMAL(15,2) DEFAULT 0,
    shipping_amount DECIMAL(15,2) DEFAULT 0,
    discount_amount DECIMAL(15,2) DEFAULT 0,
    total_amount DECIMAL(15,2) DEFAULT 0,
    currency_code VARCHAR(3) DEFAULT 'SAR',
    
    -- Cart items (JSON array of cart items)
    cart_items JSONB DEFAULT '[]'::jsonb,
    
    -- Abandonment tracking
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    last_activity_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    abandoned_at TIMESTAMPTZ,
    abandonment_stage VARCHAR(100), -- checkout, shipping, payment, etc.
    abandonment_reason VARCHAR(255),
    
    -- Recovery tracking
    recovery_attempts INTEGER DEFAULT 0,
    last_recovery_attempt_at TIMESTAMPTZ,
    recovered_at TIMESTAMPTZ,
    recovery_method VARCHAR(100), -- email, sms, push, retargeting
    recovery_campaign_id VARCHAR(255),
    
    -- Conversion tracking
    converted_to_order_id BIGINT REFERENCES orders(id) ON DELETE SET NULL,
    converted_at TIMESTAMPTZ,
    conversion_value DECIMAL(15,2),
    
    -- Customer behavior
    page_views INTEGER DEFAULT 0,
    session_duration INTEGER, -- in seconds
    device_type VARCHAR(50),
    browser VARCHAR(100),
    operating_system VARCHAR(100),
    referrer_url TEXT,
    landing_page TEXT,
    exit_page TEXT,
    
    -- Geographic information
    country VARCHAR(100),
    region VARCHAR(100),
    city VARCHAR(100),
    ip_address INET,
    timezone VARCHAR(100),
    
    -- Marketing attribution
    utm_source VARCHAR(255),
    utm_medium VARCHAR(255),
    utm_campaign VARCHAR(255),
    utm_term VARCHAR(255),
    utm_content VARCHAR(255),
    affiliate_id BIGINT REFERENCES affiliates(id) ON DELETE SET NULL,
    
    -- Discount and promotion tracking
    applied_coupons JSONB DEFAULT '[]'::jsonb,
    applied_offers JSONB DEFAULT '[]'::jsonb,
    available_discounts JSONB DEFAULT '[]'::jsonb,
    
    -- Cart characteristics
    is_guest_cart BOOLEAN DEFAULT FALSE,
    is_mobile_cart BOOLEAN DEFAULT FALSE,
    has_high_value_items BOOLEAN DEFAULT FALSE,
    has_sale_items BOOLEAN DEFAULT FALSE,
    has_new_products BOOLEAN DEFAULT FALSE,
    
    -- Recovery potential
    recovery_score DECIMAL(5,2), -- 0-100 score
    recovery_priority VARCHAR(20) DEFAULT 'medium' CHECK (recovery_priority IN (
        'low', 'medium', 'high', 'urgent'
    )),
    next_recovery_action VARCHAR(100),
    next_recovery_scheduled_at TIMESTAMPTZ,
    
    -- Performance metrics
    cart_completion_percentage DECIMAL(5,2), -- How far through checkout
    time_to_abandonment INTEGER, -- seconds from creation to abandonment
    product_view_count INTEGER DEFAULT 0,
    category_interest JSONB DEFAULT '{}'::jsonb,
    
    -- Seasonal and timing
    day_of_week INTEGER, -- 1-7
    hour_of_day INTEGER, -- 0-23
    is_weekend BOOLEAN DEFAULT FALSE,
    is_holiday BOOLEAN DEFAULT FALSE,
    season VARCHAR(20),
    
    -- Communication preferences
    email_notifications_enabled BOOLEAN DEFAULT TRUE,
    sms_notifications_enabled BOOLEAN DEFAULT FALSE,
    push_notifications_enabled BOOLEAN DEFAULT FALSE,
    preferred_contact_method VARCHAR(50),
    
    -- Risk and fraud
    risk_score DECIMAL(5,2), -- 0-100
    is_suspicious BOOLEAN DEFAULT FALSE,
    fraud_indicators JSONB DEFAULT '[]'::jsonb,
    
    -- Integration data
    external_cart_id VARCHAR(255),
    sync_status VARCHAR(50) DEFAULT 'synced',
    last_sync_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Analytics and insights
    customer_segment VARCHAR(100),
    cart_value_segment VARCHAR(50), -- low, medium, high
    likelihood_to_convert DECIMAL(5,2), -- 0-100
    predicted_conversion_date TIMESTAMPTZ,
    
    -- Custom fields for extensibility
    custom_fields JSONB DEFAULT '{}'::jsonb,
    tags JSONB DEFAULT '[]'::jsonb,
    notes TEXT,
    
    -- Timestamps
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMPTZ
);

-- =====================================================
-- Indexes for Performance
-- =====================================================

-- Primary indexes
CREATE INDEX IF NOT EXISTS idx_abandoned_carts_store_id ON abandoned_carts(store_id);
CREATE INDEX IF NOT EXISTS idx_abandoned_carts_salla_cart_id ON abandoned_carts(salla_cart_id);
CREATE INDEX IF NOT EXISTS idx_abandoned_carts_customer_id ON abandoned_carts(customer_id);
CREATE INDEX IF NOT EXISTS idx_abandoned_carts_cart_token ON abandoned_carts(cart_token);

-- Status and tracking indexes
CREATE INDEX IF NOT EXISTS idx_abandoned_carts_status ON abandoned_carts(cart_status);
CREATE INDEX IF NOT EXISTS idx_abandoned_carts_recovery_priority ON abandoned_carts(recovery_priority);
CREATE INDEX IF NOT EXISTS idx_abandoned_carts_abandonment_stage ON abandoned_carts(abandonment_stage);

-- Time-based indexes
CREATE INDEX IF NOT EXISTS idx_abandoned_carts_created_at ON abandoned_carts(created_at);
CREATE INDEX IF NOT EXISTS idx_abandoned_carts_abandoned_at ON abandoned_carts(abandoned_at);
CREATE INDEX IF NOT EXISTS idx_abandoned_carts_last_activity ON abandoned_carts(last_activity_at);
CREATE INDEX IF NOT EXISTS idx_abandoned_carts_next_recovery ON abandoned_carts(next_recovery_scheduled_at);

-- Value and performance indexes
CREATE INDEX IF NOT EXISTS idx_abandoned_carts_total_amount ON abandoned_carts(total_amount);
CREATE INDEX IF NOT EXISTS idx_abandoned_carts_recovery_score ON abandoned_carts(recovery_score);
CREATE INDEX IF NOT EXISTS idx_abandoned_carts_conversion_likelihood ON abandoned_carts(likelihood_to_convert);

-- Customer behavior indexes
CREATE INDEX IF NOT EXISTS idx_abandoned_carts_customer_email ON abandoned_carts(customer_email);
CREATE INDEX IF NOT EXISTS idx_abandoned_carts_device_type ON abandoned_carts(device_type);
CREATE INDEX IF NOT EXISTS idx_abandoned_carts_country ON abandoned_carts(country);

-- Marketing indexes
CREATE INDEX IF NOT EXISTS idx_abandoned_carts_utm_campaign ON abandoned_carts(utm_campaign);
CREATE INDEX IF NOT EXISTS idx_abandoned_carts_affiliate_id ON abandoned_carts(affiliate_id);
CREATE INDEX IF NOT EXISTS idx_abandoned_carts_recovery_campaign ON abandoned_carts(recovery_campaign_id);

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_abandoned_carts_store_status ON abandoned_carts(store_id, cart_status);
CREATE INDEX IF NOT EXISTS idx_abandoned_carts_store_priority ON abandoned_carts(store_id, recovery_priority);
CREATE INDEX IF NOT EXISTS idx_abandoned_carts_customer_status ON abandoned_carts(customer_id, cart_status);
CREATE INDEX IF NOT EXISTS idx_abandoned_carts_recovery_due ON abandoned_carts(store_id, next_recovery_scheduled_at)
    WHERE next_recovery_scheduled_at IS NOT NULL;

-- JSONB indexes for cart items and custom fields
CREATE INDEX IF NOT EXISTS idx_abandoned_carts_cart_items_gin ON abandoned_carts USING GIN(cart_items);
CREATE INDEX IF NOT EXISTS idx_abandoned_carts_custom_fields_gin ON abandoned_carts USING GIN(custom_fields);
CREATE INDEX IF NOT EXISTS idx_abandoned_carts_tags_gin ON abandoned_carts USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_abandoned_carts_applied_coupons_gin ON abandoned_carts USING GIN(applied_coupons);

-- =====================================================
-- Unique Constraints
-- =====================================================

-- Ensure unique cart tokens per store
CREATE UNIQUE INDEX IF NOT EXISTS idx_abandoned_carts_unique_token_store 
    ON abandoned_carts(store_id, cart_token) 
    WHERE cart_token IS NOT NULL;

-- =====================================================
-- Triggers
-- =====================================================

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_abandoned_carts_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_abandoned_carts_updated_at
    BEFORE UPDATE ON abandoned_carts
    FOR EACH ROW
    EXECUTE FUNCTION update_abandoned_carts_updated_at();

-- Trigger to automatically set abandonment timestamp
CREATE OR REPLACE FUNCTION set_cart_abandonment_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    -- Set abandoned_at when status changes to abandoned
    IF NEW.cart_status = 'abandoned' AND OLD.cart_status != 'abandoned' THEN
        NEW.abandoned_at = CURRENT_TIMESTAMP;
        
        -- Calculate time to abandonment
        IF NEW.created_at IS NOT NULL THEN
            NEW.time_to_abandonment = EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - NEW.created_at));
        END IF;
    END IF;
    
    -- Set recovered_at when status changes to recovered
    IF NEW.cart_status = 'recovered' AND OLD.cart_status != 'recovered' THEN
        NEW.recovered_at = CURRENT_TIMESTAMP;
    END IF;
    
    -- Set converted_at when status changes to converted
    IF NEW.cart_status = 'converted' AND OLD.cart_status != 'converted' THEN
        NEW.converted_at = CURRENT_TIMESTAMP;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_cart_abandonment_timestamp
    BEFORE UPDATE ON abandoned_carts
    FOR EACH ROW
    EXECUTE FUNCTION set_cart_abandonment_timestamp();

-- Trigger to update recovery metrics
CREATE OR REPLACE FUNCTION update_cart_recovery_metrics()
RETURNS TRIGGER AS $$
BEGIN
    -- Increment recovery attempts when last_recovery_attempt_at is updated
    IF NEW.last_recovery_attempt_at IS NOT NULL AND 
       (OLD.last_recovery_attempt_at IS NULL OR NEW.last_recovery_attempt_at > OLD.last_recovery_attempt_at) THEN
        NEW.recovery_attempts = COALESCE(OLD.recovery_attempts, 0) + 1;
    END IF;
    
    -- Update recovery score based on various factors
    NEW.recovery_score = LEAST(100, GREATEST(0, 
        CASE 
            WHEN NEW.total_amount > 500 THEN 80
            WHEN NEW.total_amount > 200 THEN 60
            WHEN NEW.total_amount > 100 THEN 40
            ELSE 20
        END +
        CASE 
            WHEN NEW.customer_id IS NOT NULL THEN 20
            ELSE 0
        END +
        CASE 
            WHEN NEW.recovery_attempts = 0 THEN 10
            WHEN NEW.recovery_attempts <= 2 THEN 5
            ELSE -10
        END
    ));
    
    -- Set recovery priority based on score and value
    NEW.recovery_priority = CASE 
        WHEN NEW.recovery_score >= 80 OR NEW.total_amount >= 500 THEN 'urgent'
        WHEN NEW.recovery_score >= 60 OR NEW.total_amount >= 200 THEN 'high'
        WHEN NEW.recovery_score >= 40 OR NEW.total_amount >= 100 THEN 'medium'
        ELSE 'low'
    END;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_cart_recovery_metrics
    BEFORE INSERT OR UPDATE ON abandoned_carts
    FOR EACH ROW
    EXECUTE FUNCTION update_cart_recovery_metrics();

-- =====================================================
-- Helper Functions
-- =====================================================

-- Function to get abandoned cart statistics for a store
CREATE OR REPLACE FUNCTION get_abandoned_cart_stats(store_id_param BIGINT)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'store_id', store_id_param,
        'total_abandoned_carts', COUNT(*),
        'total_abandoned_value', COALESCE(SUM(total_amount), 0),
        'average_cart_value', COALESCE(AVG(total_amount), 0),
        'recovery_rate', CASE 
            WHEN COUNT(*) > 0 THEN 
                (COUNT(*) FILTER (WHERE cart_status IN ('recovered', 'converted'))::DECIMAL / COUNT(*)) * 100
            ELSE 0
        END,
        'total_recovered_value', COALESCE(SUM(total_amount) FILTER (WHERE cart_status IN ('recovered', 'converted')), 0),
        'carts_by_status', jsonb_object_agg(cart_status, status_count),
        'carts_by_priority', (
            SELECT jsonb_object_agg(recovery_priority, priority_count)
            FROM (
                SELECT recovery_priority, COUNT(*) as priority_count
                FROM abandoned_carts 
                WHERE store_id = store_id_param
                GROUP BY recovery_priority
            ) priority_stats
        ),
        'average_recovery_score', COALESCE(AVG(recovery_score), 0),
        'abandonment_stages', (
            SELECT jsonb_object_agg(abandonment_stage, stage_count)
            FROM (
                SELECT abandonment_stage, COUNT(*) as stage_count
                FROM abandoned_carts 
                WHERE store_id = store_id_param AND abandonment_stage IS NOT NULL
                GROUP BY abandonment_stage
            ) stage_stats
        ),
        'recent_abandonment_trend', (
            SELECT jsonb_agg(jsonb_build_object(
                'date', abandonment_date,
                'count', daily_count,
                'value', daily_value
            ))
            FROM (
                SELECT 
                    DATE(abandoned_at) as abandonment_date,
                    COUNT(*) as daily_count,
                    SUM(total_amount) as daily_value
                FROM abandoned_carts 
                WHERE store_id = store_id_param 
                    AND abandoned_at >= CURRENT_DATE - INTERVAL '30 days'
                GROUP BY DATE(abandoned_at)
                ORDER BY abandonment_date DESC
                LIMIT 30
            ) trend_data
        )
    ) INTO result
    FROM (
        SELECT cart_status, COUNT(*) as status_count
        FROM abandoned_carts 
        WHERE store_id = store_id_param
        GROUP BY cart_status
    ) status_stats;
    
    RETURN COALESCE(result, '{"error": "No data found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- Function to search abandoned carts with filters
CREATE OR REPLACE FUNCTION search_abandoned_carts(
    store_id_param BIGINT DEFAULT NULL,
    cart_status_param VARCHAR DEFAULT NULL,
    recovery_priority_param VARCHAR DEFAULT NULL,
    customer_email_param VARCHAR DEFAULT NULL,
    min_amount DECIMAL DEFAULT NULL,
    max_amount DECIMAL DEFAULT NULL,
    abandoned_after TIMESTAMPTZ DEFAULT NULL,
    abandoned_before TIMESTAMPTZ DEFAULT NULL,
    limit_param INTEGER DEFAULT 50,
    offset_param INTEGER DEFAULT 0
)
RETURNS TABLE (
    cart_id BIGINT,
    cart_token VARCHAR,
    customer_email VARCHAR,
    total_amount DECIMAL,
    cart_status VARCHAR,
    recovery_priority VARCHAR,
    recovery_score DECIMAL,
    abandoned_at TIMESTAMPTZ,
    recovery_attempts INTEGER,
    cart_details JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ac.id as cart_id,
        ac.cart_token,
        ac.customer_email,
        ac.total_amount,
        ac.cart_status,
        ac.recovery_priority,
        ac.recovery_score,
        ac.abandoned_at,
        ac.recovery_attempts,
        jsonb_build_object(
            'total_items', ac.total_items,
            'currency_code', ac.currency_code,
            'abandonment_stage', ac.abandonment_stage,
            'device_type', ac.device_type,
            'country', ac.country,
            'utm_campaign', ac.utm_campaign,
            'cart_items', ac.cart_items
        ) as cart_details
    FROM abandoned_carts ac
    WHERE 
        (store_id_param IS NULL OR ac.store_id = store_id_param)
        AND (cart_status_param IS NULL OR ac.cart_status = cart_status_param)
        AND (recovery_priority_param IS NULL OR ac.recovery_priority = recovery_priority_param)
        AND (customer_email_param IS NULL OR ac.customer_email ILIKE '%' || customer_email_param || '%')
        AND (min_amount IS NULL OR ac.total_amount >= min_amount)
        AND (max_amount IS NULL OR ac.total_amount <= max_amount)
        AND (abandoned_after IS NULL OR ac.abandoned_at >= abandoned_after)
        AND (abandoned_before IS NULL OR ac.abandoned_at <= abandoned_before)
    ORDER BY ac.recovery_score DESC, ac.total_amount DESC, ac.abandoned_at DESC
    LIMIT limit_param OFFSET offset_param;
END;
$$ LANGUAGE plpgsql;

-- Function to get carts ready for recovery
CREATE OR REPLACE FUNCTION get_carts_for_recovery(
    store_id_param BIGINT DEFAULT NULL,
    recovery_method_param VARCHAR DEFAULT NULL,
    limit_param INTEGER DEFAULT 100
)
RETURNS TABLE (
    cart_id BIGINT,
    customer_email VARCHAR,
    recovery_priority VARCHAR,
    recovery_score DECIMAL,
    total_amount DECIMAL,
    days_since_abandonment INTEGER,
    recommended_action VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ac.id as cart_id,
        ac.customer_email,
        ac.recovery_priority,
        ac.recovery_score,
        ac.total_amount,
        EXTRACT(DAY FROM (CURRENT_TIMESTAMP - ac.abandoned_at))::INTEGER as days_since_abandonment,
        CASE 
            WHEN ac.recovery_attempts = 0 THEN 'send_first_reminder'
            WHEN ac.recovery_attempts = 1 AND EXTRACT(DAY FROM (CURRENT_TIMESTAMP - ac.last_recovery_attempt_at)) >= 3 THEN 'send_second_reminder'
            WHEN ac.recovery_attempts = 2 AND EXTRACT(DAY FROM (CURRENT_TIMESTAMP - ac.last_recovery_attempt_at)) >= 7 THEN 'send_final_offer'
            WHEN ac.recovery_attempts >= 3 AND EXTRACT(DAY FROM (CURRENT_TIMESTAMP - ac.last_recovery_attempt_at)) >= 30 THEN 'reactivation_campaign'
            ELSE 'no_action_needed'
        END as recommended_action
    FROM abandoned_carts ac
    WHERE 
        ac.cart_status = 'abandoned'
        AND (store_id_param IS NULL OR ac.store_id = store_id_param)
        AND ac.customer_email IS NOT NULL
        AND ac.email_notifications_enabled = TRUE
        AND (
            (ac.recovery_attempts = 0) OR
            (ac.recovery_attempts = 1 AND ac.last_recovery_attempt_at <= CURRENT_TIMESTAMP - INTERVAL '3 days') OR
            (ac.recovery_attempts = 2 AND ac.last_recovery_attempt_at <= CURRENT_TIMESTAMP - INTERVAL '7 days') OR
            (ac.recovery_attempts >= 3 AND ac.last_recovery_attempt_at <= CURRENT_TIMESTAMP - INTERVAL '30 days')
        )
        AND (recovery_method_param IS NULL OR recovery_method_param = 'email')
    ORDER BY ac.recovery_priority DESC, ac.recovery_score DESC, ac.total_amount DESC
    LIMIT limit_param;
END;
$$ LANGUAGE plpgsql;

-- Function to update cart recovery attempt
CREATE OR REPLACE FUNCTION record_recovery_attempt(
    cart_id_param BIGINT,
    recovery_method_param VARCHAR,
    campaign_id_param VARCHAR DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE abandoned_carts 
    SET 
        last_recovery_attempt_at = CURRENT_TIMESTAMP,
        recovery_method = recovery_method_param,
        recovery_campaign_id = COALESCE(campaign_id_param, recovery_campaign_id),
        updated_at = CURRENT_TIMESTAMP
    WHERE id = cart_id_param;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- Function to mark cart as recovered
CREATE OR REPLACE FUNCTION mark_cart_recovered(
    cart_id_param BIGINT,
    order_id_param BIGINT DEFAULT NULL,
    conversion_value_param DECIMAL DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE abandoned_carts 
    SET 
        cart_status = 'recovered',
        recovered_at = CURRENT_TIMESTAMP,
        converted_to_order_id = order_id_param,
        conversion_value = COALESCE(conversion_value_param, total_amount),
        updated_at = CURRENT_TIMESTAMP
    WHERE id = cart_id_param;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Comments for Documentation
-- =====================================================

COMMENT ON TABLE abandoned_carts IS 'Stores information about abandoned shopping carts for recovery campaigns and analytics';
COMMENT ON COLUMN abandoned_carts.salla_cart_id IS 'Unique cart identifier from Salla platform';
COMMENT ON COLUMN abandoned_carts.cart_token IS 'Unique token for cart identification and recovery links';
COMMENT ON COLUMN abandoned_carts.cart_status IS 'Current status of the abandoned cart';
COMMENT ON COLUMN abandoned_carts.cart_items IS 'JSON array containing details of items in the cart';
COMMENT ON COLUMN abandoned_carts.abandonment_stage IS 'Stage where customer abandoned the cart (checkout, shipping, payment)';
COMMENT ON COLUMN abandoned_carts.recovery_score IS 'Calculated score (0-100) indicating likelihood of successful recovery';
COMMENT ON COLUMN abandoned_carts.recovery_priority IS 'Priority level for recovery campaigns';
COMMENT ON COLUMN abandoned_carts.custom_fields IS 'Additional custom data in JSON format';

COMMENT ON FUNCTION get_abandoned_cart_stats(BIGINT) IS 'Get comprehensive abandoned cart statistics for a store';
COMMENT ON FUNCTION search_abandoned_carts(BIGINT, VARCHAR, VARCHAR, VARCHAR, DECIMAL, DECIMAL, TIMESTAMPTZ, TIMESTAMPTZ, INTEGER, INTEGER) IS 'Search abandoned carts with various filters';
COMMENT ON FUNCTION get_carts_for_recovery(BIGINT, VARCHAR, INTEGER) IS 'Get abandoned carts ready for recovery campaigns';
COMMENT ON FUNCTION record_recovery_attempt(BIGINT, VARCHAR, VARCHAR) IS 'Record a recovery attempt for an abandoned cart';
COMMENT ON FUNCTION mark_cart_recovered(BIGINT, BIGINT, DECIMAL) IS 'Mark an abandoned cart as successfully recovered';

RAISE NOTICE 'Abandoned Carts table created successfully!';