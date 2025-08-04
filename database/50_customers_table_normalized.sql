-- =============================================================================
-- Normalized Customers Table
-- =============================================================================
-- This is the normalized version of the customers table with JSONB columns
-- moved to separate tables: customer_addresses, customer_tags, customer_metadata

CREATE TABLE IF NOT EXISTS customers_normalized (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Salla integration
    salla_customer_id VARCHAR(255) UNIQUE,
    
    -- Basic customer information
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(50),
    mobile VARCHAR(50),
    
    -- Authentication
    password_hash VARCHAR(255),
    email_verified_at TIMESTAMPTZ,
    phone_verified_at TIMESTAMPTZ,
    
    -- Customer status
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended', 'pending', 'blocked')),
    is_verified BOOLEAN DEFAULT FALSE,
    
    -- Customer type and classification
    customer_type VARCHAR(50) DEFAULT 'individual' CHECK (customer_type IN ('individual', 'business', 'vip', 'wholesale')),
    customer_group VARCHAR(100),
    loyalty_tier VARCHAR(50),
    
    -- Personal information
    gender VARCHAR(10) CHECK (gender IN ('male', 'female', 'other')),
    date_of_birth DATE,
    nationality VARCHAR(100),
    language_preference VARCHAR(10) DEFAULT 'ar',
    timezone VARCHAR(50) DEFAULT 'Asia/Riyadh',
    
    -- Business information (for business customers)
    company_name VARCHAR(255),
    tax_number VARCHAR(100),
    commercial_registration VARCHAR(100),
    
    -- Marketing preferences
    accepts_marketing BOOLEAN DEFAULT TRUE,
    marketing_opt_in_at TIMESTAMPTZ,
    marketing_opt_out_at TIMESTAMPTZ,
    email_marketing_consent BOOLEAN DEFAULT TRUE,
    sms_marketing_consent BOOLEAN DEFAULT TRUE,
    
    -- Customer statistics
    total_orders INTEGER DEFAULT 0,
    total_spent DECIMAL(15,2) DEFAULT 0.00,
    average_order_value DECIMAL(15,2) DEFAULT 0.00,
    last_order_at TIMESTAMPTZ,
    first_order_at TIMESTAMPTZ,
    
    -- Loyalty and rewards
    loyalty_points INTEGER DEFAULT 0,
    lifetime_value DECIMAL(15,2) DEFAULT 0.00,
    referral_code VARCHAR(50) UNIQUE,
    referred_by_customer_id UUID REFERENCES customers_normalized(id),
    
    -- Customer behavior
    last_login_at TIMESTAMPTZ,
    login_count INTEGER DEFAULT 0,
    last_activity_at TIMESTAMPTZ,
    
    -- Risk and fraud
    risk_score DECIMAL(5,2) DEFAULT 0.00 CHECK (risk_score >= 0 AND risk_score <= 100),
    is_flagged BOOLEAN DEFAULT FALSE,
    fraud_alerts_count INTEGER DEFAULT 0,
    
    -- Customer service
    support_priority VARCHAR(20) DEFAULT 'normal' CHECK (support_priority IN ('low', 'normal', 'high', 'urgent')),
    notes TEXT,
    internal_notes TEXT, -- Staff-only notes
    
    -- Social media
    social_profiles JSONB DEFAULT '{}', -- {"facebook": "url", "twitter": "handle"}
    
    -- Preferences
    communication_preferences JSONB DEFAULT '{}', -- Email, SMS, push notification preferences
    privacy_settings JSONB DEFAULT '{}', -- Privacy and data sharing preferences
    
    -- External integrations
    external_customer_id VARCHAR(255),
    external_references JSONB DEFAULT '{}',
    
    -- Sync information
    sync_status VARCHAR(20) DEFAULT 'synced' CHECK (sync_status IN ('pending', 'syncing', 'synced', 'error')),
    last_sync_at TIMESTAMPTZ,
    sync_errors JSONB DEFAULT '[]',
    
    -- Custom fields
    custom_fields JSONB DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ,
    
    -- Constraints
    CONSTRAINT customers_normalized_risk_score_check CHECK (risk_score >= 0 AND risk_score <= 100)
);

-- =============================================================================
-- Customer Relationships Table
-- =============================================================================
-- Track relationships between customers (family, business partners, etc.)

CREATE TABLE IF NOT EXISTS customer_relationships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Relationship participants
    customer_id UUID NOT NULL REFERENCES customers_normalized(id) ON DELETE CASCADE,
    related_customer_id UUID NOT NULL REFERENCES customers_normalized(id) ON DELETE CASCADE,
    
    -- Relationship details
    relationship_type VARCHAR(50) NOT NULL CHECK (relationship_type IN (
        'family', 'spouse', 'parent', 'child', 'sibling', 'business_partner', 
        'colleague', 'friend', 'referral', 'household', 'corporate_group'
    )),
    relationship_status VARCHAR(20) DEFAULT 'active' CHECK (relationship_status IN ('active', 'inactive', 'pending')),
    
    -- Relationship properties
    is_primary BOOLEAN DEFAULT FALSE, -- Primary relationship of this type
    is_bidirectional BOOLEAN DEFAULT TRUE, -- Whether relationship applies both ways
    strength_score DECIMAL(3,2) DEFAULT 0.50 CHECK (strength_score >= 0 AND strength_score <= 1), -- Relationship strength
    
    -- Business context
    shared_billing BOOLEAN DEFAULT FALSE,
    shared_shipping BOOLEAN DEFAULT FALSE,
    joint_purchases BOOLEAN DEFAULT FALSE,
    
    -- Metadata
    description TEXT,
    notes TEXT,
    
    -- External references
    external_id VARCHAR(255),
    external_references JSONB DEFAULT '{}',
    
    -- Timestamps
    established_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMPTZ,
    
    -- Constraints
    CONSTRAINT customer_relationships_no_self_reference CHECK (customer_id != related_customer_id),
    CONSTRAINT customer_relationships_unique_pair UNIQUE(customer_id, related_customer_id, relationship_type)
);

-- =============================================================================
-- Indexes
-- =============================================================================

-- Basic indexes
CREATE INDEX IF NOT EXISTS idx_customers_normalized_store_id ON customers_normalized(store_id);
CREATE INDEX IF NOT EXISTS idx_customers_normalized_salla_customer_id ON customers_normalized(salla_customer_id);
CREATE INDEX IF NOT EXISTS idx_customers_normalized_email ON customers_normalized(email);
CREATE INDEX IF NOT EXISTS idx_customers_normalized_phone ON customers_normalized(phone);
CREATE INDEX IF NOT EXISTS idx_customers_normalized_mobile ON customers_normalized(mobile);
CREATE INDEX IF NOT EXISTS idx_customers_normalized_external_customer_id ON customers_normalized(external_customer_id);

-- Customer identification
CREATE INDEX IF NOT EXISTS idx_customers_normalized_full_name ON customers_normalized(first_name, last_name);
CREATE INDEX IF NOT EXISTS idx_customers_normalized_company_name ON customers_normalized(company_name);
CREATE INDEX IF NOT EXISTS idx_customers_normalized_tax_number ON customers_normalized(tax_number);
CREATE INDEX IF NOT EXISTS idx_customers_normalized_referral_code ON customers_normalized(referral_code);

-- Customer status and classification
CREATE INDEX IF NOT EXISTS idx_customers_normalized_status ON customers_normalized(status);
CREATE INDEX IF NOT EXISTS idx_customers_normalized_is_verified ON customers_normalized(is_verified);
CREATE INDEX IF NOT EXISTS idx_customers_normalized_customer_type ON customers_normalized(customer_type);
CREATE INDEX IF NOT EXISTS idx_customers_normalized_customer_group ON customers_normalized(customer_group);
CREATE INDEX IF NOT EXISTS idx_customers_normalized_loyalty_tier ON customers_normalized(loyalty_tier);

-- Personal information
CREATE INDEX IF NOT EXISTS idx_customers_normalized_gender ON customers_normalized(gender);
CREATE INDEX IF NOT EXISTS idx_customers_normalized_date_of_birth ON customers_normalized(date_of_birth);
CREATE INDEX IF NOT EXISTS idx_customers_normalized_nationality ON customers_normalized(nationality);
CREATE INDEX IF NOT EXISTS idx_customers_normalized_language_preference ON customers_normalized(language_preference);

-- Marketing preferences
CREATE INDEX IF NOT EXISTS idx_customers_normalized_accepts_marketing ON customers_normalized(accepts_marketing);
CREATE INDEX IF NOT EXISTS idx_customers_normalized_email_marketing_consent ON customers_normalized(email_marketing_consent);
CREATE INDEX IF NOT EXISTS idx_customers_normalized_sms_marketing_consent ON customers_normalized(sms_marketing_consent);

-- Customer statistics
CREATE INDEX IF NOT EXISTS idx_customers_normalized_total_orders ON customers_normalized(total_orders DESC);
CREATE INDEX IF NOT EXISTS idx_customers_normalized_total_spent ON customers_normalized(total_spent DESC);
CREATE INDEX IF NOT EXISTS idx_customers_normalized_average_order_value ON customers_normalized(average_order_value DESC);
CREATE INDEX IF NOT EXISTS idx_customers_normalized_last_order_at ON customers_normalized(last_order_at DESC);
CREATE INDEX IF NOT EXISTS idx_customers_normalized_first_order_at ON customers_normalized(first_order_at DESC);

-- Loyalty and rewards
CREATE INDEX IF NOT EXISTS idx_customers_normalized_loyalty_points ON customers_normalized(loyalty_points DESC);
CREATE INDEX IF NOT EXISTS idx_customers_normalized_lifetime_value ON customers_normalized(lifetime_value DESC);
CREATE INDEX IF NOT EXISTS idx_customers_normalized_referred_by ON customers_normalized(referred_by_customer_id);

-- Customer behavior
CREATE INDEX IF NOT EXISTS idx_customers_normalized_last_login_at ON customers_normalized(last_login_at DESC);
CREATE INDEX IF NOT EXISTS idx_customers_normalized_login_count ON customers_normalized(login_count DESC);
CREATE INDEX IF NOT EXISTS idx_customers_normalized_last_activity_at ON customers_normalized(last_activity_at DESC);

-- Risk and fraud
CREATE INDEX IF NOT EXISTS idx_customers_normalized_risk_score ON customers_normalized(risk_score DESC);
CREATE INDEX IF NOT EXISTS idx_customers_normalized_is_flagged ON customers_normalized(is_flagged) WHERE is_flagged = TRUE;
CREATE INDEX IF NOT EXISTS idx_customers_normalized_fraud_alerts_count ON customers_normalized(fraud_alerts_count DESC);

-- Customer service
CREATE INDEX IF NOT EXISTS idx_customers_normalized_support_priority ON customers_normalized(support_priority);

-- Sync information
CREATE INDEX IF NOT EXISTS idx_customers_normalized_sync_status ON customers_normalized(sync_status);
CREATE INDEX IF NOT EXISTS idx_customers_normalized_last_sync_at ON customers_normalized(last_sync_at DESC);

-- Timestamps
CREATE INDEX IF NOT EXISTS idx_customers_normalized_created_at ON customers_normalized(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_customers_normalized_updated_at ON customers_normalized(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_customers_normalized_deleted_at ON customers_normalized(deleted_at) WHERE deleted_at IS NOT NULL;

-- JSONB indexes
CREATE INDEX IF NOT EXISTS idx_customers_normalized_social_profiles ON customers_normalized USING gin(social_profiles);
CREATE INDEX IF NOT EXISTS idx_customers_normalized_communication_preferences ON customers_normalized USING gin(communication_preferences);
CREATE INDEX IF NOT EXISTS idx_customers_normalized_privacy_settings ON customers_normalized USING gin(privacy_settings);
CREATE INDEX IF NOT EXISTS idx_customers_normalized_external_references ON customers_normalized USING gin(external_references);
CREATE INDEX IF NOT EXISTS idx_customers_normalized_custom_fields ON customers_normalized USING gin(custom_fields);
CREATE INDEX IF NOT EXISTS idx_customers_normalized_sync_errors ON customers_normalized USING gin(sync_errors);

-- Text search indexes
CREATE INDEX IF NOT EXISTS idx_customers_normalized_full_name_text ON customers_normalized USING gin(to_tsvector('english', COALESCE(first_name, '') || ' ' || COALESCE(last_name, '')));
CREATE INDEX IF NOT EXISTS idx_customers_normalized_company_name_text ON customers_normalized USING gin(to_tsvector('english', COALESCE(company_name, '')));
CREATE INDEX IF NOT EXISTS idx_customers_normalized_notes_text ON customers_normalized USING gin(to_tsvector('english', COALESCE(notes, '')));

-- Composite indexes
CREATE INDEX IF NOT EXISTS idx_customers_normalized_active_customers ON customers_normalized(store_id, status, is_verified) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_customers_normalized_marketing_eligible ON customers_normalized(store_id, accepts_marketing, email_marketing_consent) WHERE accepts_marketing = TRUE;
CREATE INDEX IF NOT EXISTS idx_customers_normalized_high_value ON customers_normalized(store_id, lifetime_value DESC, loyalty_tier) WHERE lifetime_value > 1000;
CREATE INDEX IF NOT EXISTS idx_customers_normalized_at_risk ON customers_normalized(store_id, risk_score DESC, is_flagged) WHERE risk_score > 50 OR is_flagged = TRUE;
CREATE INDEX IF NOT EXISTS idx_customers_normalized_recent_activity ON customers_normalized(store_id, last_activity_at DESC) WHERE last_activity_at > CURRENT_TIMESTAMP - INTERVAL '30 days';

-- Customer relationships indexes
CREATE INDEX IF NOT EXISTS idx_customer_relationships_customer_id ON customer_relationships(customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_relationships_related_customer_id ON customer_relationships(related_customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_relationships_store_id ON customer_relationships(store_id);
CREATE INDEX IF NOT EXISTS idx_customer_relationships_type ON customer_relationships(relationship_type);
CREATE INDEX IF NOT EXISTS idx_customer_relationships_status ON customer_relationships(relationship_status);
CREATE INDEX IF NOT EXISTS idx_customer_relationships_is_primary ON customer_relationships(is_primary) WHERE is_primary = TRUE;
CREATE INDEX IF NOT EXISTS idx_customer_relationships_strength_score ON customer_relationships(strength_score DESC);
CREATE INDEX IF NOT EXISTS idx_customer_relationships_established_at ON customer_relationships(established_at DESC);
CREATE INDEX IF NOT EXISTS idx_customer_relationships_external_id ON customer_relationships(external_id);

-- =============================================================================
-- Triggers
-- =============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_customers_normalized_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_customers_normalized_updated_at
    BEFORE UPDATE ON customers_normalized
    FOR EACH ROW
    EXECUTE FUNCTION update_customers_normalized_updated_at();

CREATE TRIGGER trigger_update_customer_relationships_updated_at
    BEFORE UPDATE ON customer_relationships
    FOR EACH ROW
    EXECUTE FUNCTION update_customers_normalized_updated_at();

-- Update customer statistics
CREATE OR REPLACE FUNCTION update_customer_statistics()
RETURNS TRIGGER AS $$
BEGIN
    -- This would be triggered by order changes
    -- Implementation depends on orders table structure
    
    -- Update total orders and spending
    UPDATE customers_normalized 
    SET 
        total_orders = (
            SELECT COUNT(*) 
            FROM orders 
            WHERE customer_id = NEW.customer_id 
            AND status NOT IN ('cancelled', 'refunded')
        ),
        total_spent = (
            SELECT COALESCE(SUM(total_amount), 0) 
            FROM orders 
            WHERE customer_id = NEW.customer_id 
            AND status = 'completed'
        ),
        last_order_at = (
            SELECT MAX(created_at) 
            FROM orders 
            WHERE customer_id = NEW.customer_id
        ),
        first_order_at = (
            SELECT MIN(created_at) 
            FROM orders 
            WHERE customer_id = NEW.customer_id
        )
    WHERE id = NEW.customer_id;
    
    -- Update average order value
    UPDATE customers_normalized 
    SET average_order_value = CASE 
        WHEN total_orders > 0 THEN total_spent / total_orders 
        ELSE 0 
    END
    WHERE id = NEW.customer_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Update last activity timestamp
CREATE OR REPLACE FUNCTION update_customer_last_activity()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE customers_normalized 
    SET last_activity_at = CURRENT_TIMESTAMP
    WHERE id = NEW.customer_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Validate customer relationships
CREATE OR REPLACE FUNCTION validate_customer_relationship()
RETURNS TRIGGER AS $$
BEGIN
    -- Ensure customers are from the same store
    IF NOT EXISTS (
        SELECT 1 FROM customers_normalized c1, customers_normalized c2
        WHERE c1.id = NEW.customer_id 
        AND c2.id = NEW.related_customer_id
        AND c1.store_id = c2.store_id
        AND c1.store_id = NEW.store_id
    ) THEN
        RAISE EXCEPTION 'Customers must be from the same store';
    END IF;
    
    -- Create bidirectional relationship if specified
    IF NEW.is_bidirectional = TRUE AND TG_OP = 'INSERT' THEN
        INSERT INTO customer_relationships (
            store_id, customer_id, related_customer_id, relationship_type,
            relationship_status, is_primary, is_bidirectional, strength_score
        ) VALUES (
            NEW.store_id, NEW.related_customer_id, NEW.customer_id, NEW.relationship_type,
            NEW.relationship_status, FALSE, FALSE, NEW.strength_score
        )
        ON CONFLICT (customer_id, related_customer_id, relationship_type) DO NOTHING;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validate_customer_relationship
    BEFORE INSERT OR UPDATE ON customer_relationships
    FOR EACH ROW
    EXECUTE FUNCTION validate_customer_relationship();

-- =============================================================================
-- Helper Functions
-- =============================================================================

/**
 * Get complete customer data with related information
 * @param p_customer_id UUID - Customer ID
 * @return JSONB - Complete customer data
 */
CREATE OR REPLACE FUNCTION get_complete_customer_data(
    p_customer_id UUID
)
RETURNS JSONB AS $$
DECLARE
    customer_data JSONB;
    addresses_data JSONB;
    tags_data JSONB;
    metadata_data JSONB;
    relationships_data JSONB;
BEGIN
    -- Get basic customer data
    SELECT to_jsonb(c.*) INTO customer_data
    FROM customers_normalized c
    WHERE c.id = p_customer_id;
    
    IF customer_data IS NULL THEN
        RETURN '{"error": "Customer not found"}'::jsonb;
    END IF;
    
    -- Get addresses
    SELECT jsonb_agg(to_jsonb(ca.*)) INTO addresses_data
    FROM customer_addresses ca
    WHERE ca.customer_id = p_customer_id;
    
    -- Get tags
    SELECT jsonb_agg(to_jsonb(ct.*)) INTO tags_data
    FROM customer_tags ct
    WHERE ct.customer_id = p_customer_id;
    
    -- Get metadata
    SELECT jsonb_agg(to_jsonb(cm.*)) INTO metadata_data
    FROM customer_metadata cm
    WHERE cm.customer_id = p_customer_id;
    
    -- Get relationships
    SELECT jsonb_agg(to_jsonb(cr.*)) INTO relationships_data
    FROM customer_relationships cr
    WHERE cr.customer_id = p_customer_id OR cr.related_customer_id = p_customer_id;
    
    -- Combine all data
    RETURN customer_data || jsonb_build_object(
        'addresses', COALESCE(addresses_data, '[]'::jsonb),
        'tags', COALESCE(tags_data, '[]'::jsonb),
        'metadata', COALESCE(metadata_data, '[]'::jsonb),
        'relationships', COALESCE(relationships_data, '[]'::jsonb)
    );
END;
$$ LANGUAGE plpgsql;

/**
 * Search customers with filters
 * @param p_store_id UUID - Store ID
 * @param p_filters JSONB - Search filters
 * @param p_limit INTEGER - Result limit
 * @param p_offset INTEGER - Result offset
 * @return TABLE - Matching customers
 */
CREATE OR REPLACE FUNCTION search_customers_normalized(
    p_store_id UUID,
    p_filters JSONB DEFAULT '{}',
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    customer_id UUID,
    full_name TEXT,
    email VARCHAR,
    phone VARCHAR,
    customer_type VARCHAR,
    status VARCHAR,
    total_orders INTEGER,
    total_spent DECIMAL,
    last_order_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id as customer_id,
        CONCAT(c.first_name, ' ', c.last_name) as full_name,
        c.email,
        c.phone,
        c.customer_type,
        c.status,
        c.total_orders,
        c.total_spent,
        c.last_order_at,
        c.created_at
    FROM customers_normalized c
    WHERE c.store_id = p_store_id
    AND (NOT p_filters ? 'status' OR c.status = (p_filters->>'status'))
    AND (NOT p_filters ? 'customer_type' OR c.customer_type = (p_filters->>'customer_type'))
    AND (NOT p_filters ? 'is_verified' OR c.is_verified = (p_filters->>'is_verified')::boolean)
    AND (NOT p_filters ? 'accepts_marketing' OR c.accepts_marketing = (p_filters->>'accepts_marketing')::boolean)
    AND (NOT p_filters ? 'min_total_spent' OR c.total_spent >= (p_filters->>'min_total_spent')::decimal)
    AND (NOT p_filters ? 'max_total_spent' OR c.total_spent <= (p_filters->>'max_total_spent')::decimal)
    AND (NOT p_filters ? 'min_orders' OR c.total_orders >= (p_filters->>'min_orders')::integer)
    AND (NOT p_filters ? 'search_term' OR (
        CONCAT(c.first_name, ' ', c.last_name) ILIKE '%' || (p_filters->>'search_term') || '%'
        OR c.email ILIKE '%' || (p_filters->>'search_term') || '%'
        OR c.phone ILIKE '%' || (p_filters->>'search_term') || '%'
        OR c.company_name ILIKE '%' || (p_filters->>'search_term') || '%'
    ))
    ORDER BY 
        CASE WHEN p_filters->>'sort_by' = 'name' THEN CONCAT(c.first_name, ' ', c.last_name) END,
        CASE WHEN p_filters->>'sort_by' = 'total_spent' THEN c.total_spent END DESC,
        CASE WHEN p_filters->>'sort_by' = 'total_orders' THEN c.total_orders END DESC,
        CASE WHEN p_filters->>'sort_by' = 'last_order' THEN c.last_order_at END DESC,
        c.created_at DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql;

/**
 * Get customer statistics for store
 * @param p_store_id UUID - Store ID
 * @return JSONB - Customer statistics
 */
CREATE OR REPLACE FUNCTION get_customers_normalized_stats(
    p_store_id UUID
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_customers', COUNT(*),
        'active_customers', COUNT(*) FILTER (WHERE status = 'active'),
        'verified_customers', COUNT(*) FILTER (WHERE is_verified = TRUE),
        'business_customers', COUNT(*) FILTER (WHERE customer_type = 'business'),
        'vip_customers', COUNT(*) FILTER (WHERE customer_type = 'vip'),
        'marketing_subscribers', COUNT(*) FILTER (WHERE accepts_marketing = TRUE),
        'customers_with_orders', COUNT(*) FILTER (WHERE total_orders > 0),
        'high_value_customers', COUNT(*) FILTER (WHERE lifetime_value > 1000),
        'at_risk_customers', COUNT(*) FILTER (WHERE risk_score > 50 OR is_flagged = TRUE),
        'avg_lifetime_value', AVG(lifetime_value),
        'avg_total_spent', AVG(total_spent),
        'avg_total_orders', AVG(total_orders),
        'total_loyalty_points', SUM(loyalty_points),
        'customer_types', (
            SELECT jsonb_object_agg(customer_type, type_count)
            FROM (
                SELECT customer_type, COUNT(*) as type_count
                FROM customers_normalized
                WHERE store_id = p_store_id
                GROUP BY customer_type
            ) type_stats
        ),
        'customer_statuses', (
            SELECT jsonb_object_agg(status, status_count)
            FROM (
                SELECT status, COUNT(*) as status_count
                FROM customers_normalized
                WHERE store_id = p_store_id
                GROUP BY status
            ) status_stats
        ),
        'loyalty_tiers', (
            SELECT jsonb_object_agg(loyalty_tier, tier_count)
            FROM (
                SELECT loyalty_tier, COUNT(*) as tier_count
                FROM customers_normalized
                WHERE store_id = p_store_id AND loyalty_tier IS NOT NULL
                GROUP BY loyalty_tier
            ) tier_stats
        ),
        'new_customers_this_month', (
            SELECT COUNT(*)
            FROM customers_normalized
            WHERE store_id = p_store_id
            AND created_at >= date_trunc('month', CURRENT_TIMESTAMP)
        ),
        'active_customers_this_month', (
            SELECT COUNT(*)
            FROM customers_normalized
            WHERE store_id = p_store_id
            AND last_activity_at >= date_trunc('month', CURRENT_TIMESTAMP)
        )
    ) INTO result
    FROM customers_normalized
    WHERE store_id = p_store_id;
    
    RETURN COALESCE(result, '{"error": "No customers found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Comments
-- =============================================================================

COMMENT ON TABLE customers_normalized IS 'Normalized customers table with JSONB columns moved to separate tables';
COMMENT ON TABLE customer_relationships IS 'Track relationships between customers';

COMMENT ON COLUMN customers_normalized.salla_customer_id IS 'Customer ID from Salla platform';
COMMENT ON COLUMN customers_normalized.customer_type IS 'Type of customer: individual, business, vip, wholesale';
COMMENT ON COLUMN customers_normalized.risk_score IS 'Customer risk score (0-100)';
COMMENT ON COLUMN customers_normalized.lifetime_value IS 'Calculated customer lifetime value';
COMMENT ON COLUMN customers_normalized.referral_code IS 'Unique referral code for this customer';

COMMENT ON COLUMN customer_relationships.relationship_type IS 'Type of relationship between customers';
COMMENT ON COLUMN customer_relationships.strength_score IS 'Relationship strength (0.00 to 1.00)';
COMMENT ON COLUMN customer_relationships.is_bidirectional IS 'Whether relationship applies both ways';

COMMENT ON FUNCTION get_complete_customer_data(UUID) IS 'Get complete customer data with related information';
COMMENT ON FUNCTION search_customers_normalized(UUID, JSONB, INTEGER, INTEGER) IS 'Search customers with filters';
COMMENT ON FUNCTION get_customers_normalized_stats(UUID) IS 'Get customer statistics for store';