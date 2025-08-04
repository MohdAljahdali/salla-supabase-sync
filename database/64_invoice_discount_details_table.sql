-- =============================================================================
-- Invoice Discount Details Table
-- =============================================================================
-- This file normalizes the discount_details JSONB column from the invoices table
-- into a separate table with proper structure and relationships

-- =============================================================================
-- Invoice Discount Details Table
-- =============================================================================

CREATE TABLE IF NOT EXISTS invoice_discount_details (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Discount identification
    discount_type VARCHAR(50) NOT NULL CHECK (discount_type IN (
        'percentage', 'fixed_amount', 'buy_x_get_y', 'tiered', 'bulk', 'loyalty', 
        'coupon', 'promotional', 'seasonal', 'clearance', 'employee', 'student', 
        'senior', 'military', 'first_time', 'referral', 'bundle', 'shipping', 'other'
    )),
    discount_name VARCHAR(100) NOT NULL, -- Display name for discount
    discount_code VARCHAR(50), -- Discount/coupon code used
    discount_description TEXT,
    
    -- Discount source and campaign
    discount_source VARCHAR(50) DEFAULT 'manual' CHECK (discount_source IN (
        'manual', 'coupon', 'promotion', 'loyalty_program', 'referral', 'api', 
        'bulk_pricing', 'seasonal', 'clearance', 'employee', 'system', 'migration'
    )),
    campaign_id VARCHAR(255), -- Marketing campaign ID
    campaign_name VARCHAR(255), -- Marketing campaign name
    promotion_id VARCHAR(255), -- Promotion ID
    
    -- Discount calculation
    discount_method VARCHAR(30) DEFAULT 'subtotal' CHECK (discount_method IN (
        'subtotal', 'line_item', 'shipping', 'tax', 'total', 'custom'
    )),
    calculation_basis DECIMAL(15,4) NOT NULL CHECK (calculation_basis >= 0), -- Amount discount is calculated on
    
    -- Discount value
    discount_value DECIMAL(15,4) NOT NULL CHECK (discount_value >= 0), -- Discount rate or fixed amount
    discount_amount DECIMAL(15,4) NOT NULL CHECK (discount_amount >= 0), -- Actual discount amount applied
    discount_percentage DECIMAL(5,2), -- Discount as percentage (for display)
    
    -- Discount limits and caps
    minimum_amount DECIMAL(15,4), -- Minimum order amount for discount
    maximum_discount DECIMAL(15,4), -- Maximum discount amount
    discount_cap_reached BOOLEAN DEFAULT FALSE, -- Whether discount cap was reached
    
    -- Discount application scope
    applies_to_line_items JSONB DEFAULT '[]', -- Array of line item IDs discount applies to
    line_item_discount_amounts JSONB DEFAULT '{}', -- Discount amount per line item
    applies_to_shipping BOOLEAN DEFAULT FALSE,
    applies_to_tax BOOLEAN DEFAULT FALSE,
    
    -- Quantity-based discounts
    required_quantity INTEGER, -- Required quantity for discount
    free_quantity INTEGER, -- Free quantity given
    buy_quantity INTEGER, -- Buy X quantity
    get_quantity INTEGER, -- Get Y quantity
    
    -- Tiered discount information
    tier_level INTEGER, -- Tier level for tiered discounts
    tier_threshold DECIMAL(15,4), -- Threshold amount for this tier
    tier_discount_rate DECIMAL(5,4), -- Discount rate for this tier
    
    -- Discount validity and timing
    valid_from TIMESTAMPTZ,
    valid_until TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE,
    is_expired BOOLEAN DEFAULT FALSE,
    
    -- Usage tracking
    usage_count INTEGER DEFAULT 1, -- How many times this discount was used
    usage_limit INTEGER, -- Maximum usage limit
    usage_limit_per_customer INTEGER, -- Usage limit per customer
    is_single_use BOOLEAN DEFAULT FALSE, -- Whether discount is single use
    
    -- Customer eligibility
    customer_eligibility VARCHAR(30) DEFAULT 'all' CHECK (customer_eligibility IN (
        'all', 'new_customers', 'existing_customers', 'vip', 'loyalty_members', 
        'specific_customers', 'customer_groups', 'geographic', 'demographic'
    )),
    eligible_customer_groups TEXT[], -- Customer groups eligible for discount
    excluded_customer_groups TEXT[], -- Customer groups excluded from discount
    
    -- Product eligibility
    product_eligibility VARCHAR(30) DEFAULT 'all' CHECK (product_eligibility IN (
        'all', 'specific_products', 'categories', 'brands', 'collections', 
        'tags', 'price_range', 'new_products', 'sale_products', 'featured'
    )),
    eligible_product_ids TEXT[], -- Specific product IDs eligible
    eligible_categories TEXT[], -- Product categories eligible
    eligible_brands TEXT[], -- Product brands eligible
    excluded_product_ids TEXT[], -- Products excluded from discount
    
    -- Geographic restrictions
    geographic_restrictions JSONB DEFAULT '{}', -- Countries, states, cities where discount applies
    shipping_zone_restrictions TEXT[], -- Shipping zones where discount applies
    
    -- Discount combination rules
    can_combine_with_other_discounts BOOLEAN DEFAULT TRUE,
    cannot_combine_with TEXT[], -- Discount types that cannot be combined
    combination_priority INTEGER DEFAULT 100, -- Priority when combining discounts
    
    -- Loyalty and referral
    loyalty_points_required INTEGER, -- Loyalty points required for discount
    loyalty_points_earned INTEGER, -- Loyalty points earned from this discount
    referral_code VARCHAR(100), -- Referral code used
    referrer_customer_id UUID, -- Customer who made the referral
    
    -- A/B testing and personalization
    ab_test_group VARCHAR(50), -- A/B test group
    personalization_score DECIMAL(3,2), -- Personalization relevance score
    recommendation_engine VARCHAR(50), -- Which engine recommended this discount
    
    -- Discount performance tracking
    conversion_attributed BOOLEAN DEFAULT FALSE, -- Whether discount led to conversion
    revenue_impact DECIMAL(15,4), -- Revenue impact of discount
    margin_impact DECIMAL(15,4), -- Margin impact of discount
    customer_acquisition_cost DECIMAL(10,2), -- Cost to acquire customer with this discount
    
    -- Fraud and abuse prevention
    fraud_score DECIMAL(3,2) CHECK (fraud_score >= 0 AND fraud_score <= 1),
    is_suspicious BOOLEAN DEFAULT FALSE,
    abuse_flags TEXT[], -- Flags for potential abuse
    verification_required BOOLEAN DEFAULT FALSE,
    verification_status VARCHAR(20) DEFAULT 'not_required' CHECK (verification_status IN (
        'not_required', 'pending', 'verified', 'failed', 'manual_review'
    )),
    
    -- Approval workflow
    approval_status VARCHAR(20) DEFAULT 'auto_approved' CHECK (approval_status IN (
        'auto_approved', 'pending_approval', 'approved', 'rejected', 'expired'
    )),
    approved_by_user_id UUID,
    approved_at TIMESTAMPTZ,
    rejection_reason TEXT,
    
    -- Tax implications
    affects_tax_calculation BOOLEAN DEFAULT FALSE,
    tax_treatment VARCHAR(30) DEFAULT 'after_tax' CHECK (tax_treatment IN (
        'before_tax', 'after_tax', 'tax_inclusive', 'tax_exempt'
    )),
    
    -- Accounting and reporting
    accounting_code VARCHAR(50), -- Accounting code for discount
    cost_center VARCHAR(50), -- Cost center for discount
    budget_allocation VARCHAR(50), -- Budget allocation for discount
    
    -- External integrations
    external_discount_id VARCHAR(255), -- External system discount ID
    external_campaign_id VARCHAR(255), -- External campaign ID
    affiliate_id VARCHAR(255), -- Affiliate ID if applicable
    partner_id VARCHAR(255), -- Partner ID if applicable
    
    -- Data source and quality
    data_source VARCHAR(50) DEFAULT 'manual' CHECK (data_source IN (
        'manual', 'api', 'import', 'calculation', 'system', 'migration'
    )),
    data_quality_score DECIMAL(3,2) CHECK (data_quality_score >= 0 AND data_quality_score <= 1),
    confidence_level VARCHAR(20) DEFAULT 'high' CHECK (confidence_level IN (
        'very_low', 'low', 'medium', 'high', 'very_high'
    )),
    
    -- Sync information
    sync_status VARCHAR(20) DEFAULT 'synced' CHECK (sync_status IN ('pending', 'syncing', 'synced', 'error')),
    last_sync_at TIMESTAMPTZ,
    sync_errors JSONB DEFAULT '[]',
    
    -- Custom fields for extensibility
    custom_fields JSONB DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CHECK (valid_until IS NULL OR valid_until >= valid_from),
    CHECK (maximum_discount IS NULL OR discount_amount <= maximum_discount),
    CHECK (minimum_amount IS NULL OR calculation_basis >= minimum_amount),
    CHECK (usage_limit IS NULL OR usage_count <= usage_limit)
);

-- =============================================================================
-- Invoice Discount Detail History Table
-- =============================================================================
-- Track changes to discount details

CREATE TABLE IF NOT EXISTS invoice_discount_detail_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    discount_detail_id UUID NOT NULL REFERENCES invoice_discount_details(id) ON DELETE CASCADE,
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Change tracking
    change_type VARCHAR(20) NOT NULL CHECK (change_type IN ('created', 'updated', 'deleted', 'applied', 'revoked')),
    changed_fields JSONB, -- Array of field names that changed
    old_values JSONB, -- Previous values of changed fields
    new_values JSONB, -- New values of changed fields
    
    -- Change context
    change_reason VARCHAR(255),
    change_source VARCHAR(50) DEFAULT 'manual' CHECK (change_source IN (
        'manual', 'api', 'import', 'system', 'recalculation', 'correction', 'audit'
    )),
    
    -- Discount application context
    application_engine VARCHAR(50), -- Which engine applied the discount
    application_version VARCHAR(20), -- Version of discount rules
    discount_rules_applied JSONB, -- Which discount rules were applied
    
    -- User context
    changed_by_user_id UUID,
    changed_by_user_type VARCHAR(20) DEFAULT 'admin' CHECK (changed_by_user_type IN (
        'admin', 'system', 'api', 'discount_engine', 'customer'
    )),
    
    -- Session context
    session_id VARCHAR(255),
    request_id VARCHAR(255),
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- Discount Rules Table
-- =============================================================================
-- Define discount calculation rules and campaigns

CREATE TABLE IF NOT EXISTS invoice_discount_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Rule identification
    rule_name VARCHAR(100) NOT NULL,
    rule_description TEXT,
    rule_code VARCHAR(50), -- Internal rule code
    
    -- Discount configuration
    discount_type VARCHAR(50) NOT NULL,
    discount_method VARCHAR(30) NOT NULL,
    discount_value DECIMAL(15,4) NOT NULL CHECK (discount_value >= 0),
    
    -- Rule conditions
    minimum_order_amount DECIMAL(15,4),
    maximum_discount_amount DECIMAL(15,4),
    required_quantity INTEGER,
    
    -- Eligibility criteria
    customer_eligibility VARCHAR(30) DEFAULT 'all',
    product_eligibility VARCHAR(30) DEFAULT 'all',
    eligible_customer_groups TEXT[],
    eligible_product_categories TEXT[],
    
    -- Date range
    effective_from TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    effective_until TIMESTAMPTZ,
    
    -- Usage limits
    usage_limit INTEGER, -- Total usage limit
    usage_limit_per_customer INTEGER, -- Per customer usage limit
    current_usage_count INTEGER DEFAULT 0,
    
    -- Rule priority and application
    priority INTEGER DEFAULT 100, -- Higher number = higher priority
    is_active BOOLEAN DEFAULT TRUE,
    is_automatic BOOLEAN DEFAULT FALSE, -- Whether rule is applied automatically
    requires_code BOOLEAN DEFAULT FALSE, -- Whether discount code is required
    
    -- Combination rules
    can_combine BOOLEAN DEFAULT TRUE,
    combination_restrictions TEXT[],
    
    -- Performance tracking
    application_count INTEGER DEFAULT 0,
    total_discount_given DECIMAL(15,4) DEFAULT 0,
    revenue_impact DECIMAL(15,4) DEFAULT 0,
    last_used_at TIMESTAMPTZ,
    
    -- External references
    external_rule_id VARCHAR(255), -- External system rule ID
    campaign_reference VARCHAR(255), -- Campaign reference
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    UNIQUE(store_id, rule_code),
    CHECK (effective_until IS NULL OR effective_until >= effective_from),
    CHECK (usage_limit IS NULL OR current_usage_count <= usage_limit)
);

-- =============================================================================
-- Discount Performance Analytics Table
-- =============================================================================
-- Track discount performance metrics

CREATE TABLE IF NOT EXISTS invoice_discount_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Time period
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    period_type VARCHAR(20) DEFAULT 'daily' CHECK (period_type IN (
        'hourly', 'daily', 'weekly', 'monthly', 'quarterly', 'yearly'
    )),
    
    -- Discount metrics
    discount_type VARCHAR(50),
    discount_code VARCHAR(50),
    campaign_id VARCHAR(255),
    
    -- Usage statistics
    total_applications INTEGER DEFAULT 0,
    unique_customers INTEGER DEFAULT 0,
    total_discount_amount DECIMAL(15,4) DEFAULT 0,
    average_discount_amount DECIMAL(15,4) DEFAULT 0,
    
    -- Revenue impact
    gross_revenue DECIMAL(15,4) DEFAULT 0, -- Revenue before discount
    net_revenue DECIMAL(15,4) DEFAULT 0, -- Revenue after discount
    revenue_impact_percentage DECIMAL(5,2), -- Percentage impact on revenue
    
    -- Conversion metrics
    conversion_rate DECIMAL(5,4), -- Conversion rate with discount
    baseline_conversion_rate DECIMAL(5,4), -- Baseline conversion rate
    conversion_lift DECIMAL(5,4), -- Lift in conversion rate
    
    -- Customer metrics
    new_customers_acquired INTEGER DEFAULT 0,
    returning_customers INTEGER DEFAULT 0,
    customer_acquisition_cost DECIMAL(10,2),
    customer_lifetime_value_impact DECIMAL(15,4),
    
    -- Product metrics
    products_sold INTEGER DEFAULT 0,
    average_order_value DECIMAL(15,4),
    units_per_transaction DECIMAL(8,2),
    
    -- Performance scores
    roi_score DECIMAL(8,4), -- Return on investment
    effectiveness_score DECIMAL(3,2), -- Overall effectiveness (0-1)
    profitability_score DECIMAL(3,2), -- Profitability score (0-1)
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CHECK (period_end >= period_start),
    UNIQUE(store_id, period_start, period_end, period_type, discount_type, discount_code)
);

-- =============================================================================
-- Indexes
-- =============================================================================

-- Primary indexes for invoice_discount_details
CREATE INDEX IF NOT EXISTS idx_invoice_discount_details_invoice_id ON invoice_discount_details(invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoice_discount_details_store_id ON invoice_discount_details(store_id);
CREATE INDEX IF NOT EXISTS idx_invoice_discount_details_discount_type ON invoice_discount_details(discount_type);
CREATE INDEX IF NOT EXISTS idx_invoice_discount_details_discount_code ON invoice_discount_details(discount_code);
CREATE INDEX IF NOT EXISTS idx_invoice_discount_details_discount_source ON invoice_discount_details(discount_source);
CREATE INDEX IF NOT EXISTS idx_invoice_discount_details_campaign_id ON invoice_discount_details(campaign_id);
CREATE INDEX IF NOT EXISTS idx_invoice_discount_details_promotion_id ON invoice_discount_details(promotion_id);
CREATE INDEX IF NOT EXISTS idx_invoice_discount_details_is_active ON invoice_discount_details(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_invoice_discount_details_valid_dates ON invoice_discount_details(valid_from, valid_until);
CREATE INDEX IF NOT EXISTS idx_invoice_discount_details_customer_eligibility ON invoice_discount_details(customer_eligibility);
CREATE INDEX IF NOT EXISTS idx_invoice_discount_details_approval_status ON invoice_discount_details(approval_status);
CREATE INDEX IF NOT EXISTS idx_invoice_discount_details_verification_status ON invoice_discount_details(verification_status);
CREATE INDEX IF NOT EXISTS idx_invoice_discount_details_sync_status ON invoice_discount_details(sync_status);
CREATE INDEX IF NOT EXISTS idx_invoice_discount_details_created_at ON invoice_discount_details(created_at DESC);

-- Composite indexes
CREATE INDEX IF NOT EXISTS idx_invoice_discount_details_store_type_code ON invoice_discount_details(store_id, discount_type, discount_code);
CREATE INDEX IF NOT EXISTS idx_invoice_discount_details_campaign_dates ON invoice_discount_details(campaign_id, valid_from, valid_until);
CREATE INDEX IF NOT EXISTS idx_invoice_discount_details_amount_range ON invoice_discount_details(discount_amount, minimum_amount, maximum_discount);
CREATE INDEX IF NOT EXISTS idx_invoice_discount_details_usage_tracking ON invoice_discount_details(usage_count, usage_limit, is_single_use);

-- JSONB indexes
CREATE INDEX IF NOT EXISTS idx_invoice_discount_details_line_items ON invoice_discount_details USING gin(applies_to_line_items);
CREATE INDEX IF NOT EXISTS idx_invoice_discount_details_line_item_amounts ON invoice_discount_details USING gin(line_item_discount_amounts);
CREATE INDEX IF NOT EXISTS idx_invoice_discount_details_geographic ON invoice_discount_details USING gin(geographic_restrictions);
CREATE INDEX IF NOT EXISTS idx_invoice_discount_details_custom_fields ON invoice_discount_details USING gin(custom_fields);
CREATE INDEX IF NOT EXISTS idx_invoice_discount_details_sync_errors ON invoice_discount_details USING gin(sync_errors);

-- Array indexes
CREATE INDEX IF NOT EXISTS idx_invoice_discount_details_customer_groups ON invoice_discount_details USING gin(eligible_customer_groups);
CREATE INDEX IF NOT EXISTS idx_invoice_discount_details_product_ids ON invoice_discount_details USING gin(eligible_product_ids);
CREATE INDEX IF NOT EXISTS idx_invoice_discount_details_categories ON invoice_discount_details USING gin(eligible_categories);
CREATE INDEX IF NOT EXISTS idx_invoice_discount_details_brands ON invoice_discount_details USING gin(eligible_brands);
CREATE INDEX IF NOT EXISTS idx_invoice_discount_details_abuse_flags ON invoice_discount_details USING gin(abuse_flags);

-- History table indexes
CREATE INDEX IF NOT EXISTS idx_invoice_discount_detail_history_discount_id ON invoice_discount_detail_history(discount_detail_id);
CREATE INDEX IF NOT EXISTS idx_invoice_discount_detail_history_invoice_id ON invoice_discount_detail_history(invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoice_discount_detail_history_store_id ON invoice_discount_detail_history(store_id);
CREATE INDEX IF NOT EXISTS idx_invoice_discount_detail_history_change_type ON invoice_discount_detail_history(change_type);
CREATE INDEX IF NOT EXISTS idx_invoice_discount_detail_history_change_source ON invoice_discount_detail_history(change_source);
CREATE INDEX IF NOT EXISTS idx_invoice_discount_detail_history_created_at ON invoice_discount_detail_history(created_at DESC);

-- Discount rules indexes
CREATE INDEX IF NOT EXISTS idx_invoice_discount_rules_store_id ON invoice_discount_rules(store_id);
CREATE INDEX IF NOT EXISTS idx_invoice_discount_rules_discount_type ON invoice_discount_rules(discount_type);
CREATE INDEX IF NOT EXISTS idx_invoice_discount_rules_is_active ON invoice_discount_rules(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_invoice_discount_rules_effective_dates ON invoice_discount_rules(effective_from, effective_until);
CREATE INDEX IF NOT EXISTS idx_invoice_discount_rules_priority ON invoice_discount_rules(priority DESC);
CREATE INDEX IF NOT EXISTS idx_invoice_discount_rules_usage ON invoice_discount_rules(current_usage_count, usage_limit);

-- Analytics indexes
CREATE INDEX IF NOT EXISTS idx_invoice_discount_analytics_store_id ON invoice_discount_analytics(store_id);
CREATE INDEX IF NOT EXISTS idx_invoice_discount_analytics_period ON invoice_discount_analytics(period_start, period_end, period_type);
CREATE INDEX IF NOT EXISTS idx_invoice_discount_analytics_discount_type ON invoice_discount_analytics(discount_type);
CREATE INDEX IF NOT EXISTS idx_invoice_discount_analytics_campaign ON invoice_discount_analytics(campaign_id);
CREATE INDEX IF NOT EXISTS idx_invoice_discount_analytics_created_at ON invoice_discount_analytics(created_at DESC);

-- =============================================================================
-- Triggers
-- =============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_invoice_discount_details_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_invoice_discount_details_updated_at
    BEFORE UPDATE ON invoice_discount_details
    FOR EACH ROW
    EXECUTE FUNCTION update_invoice_discount_details_updated_at();

CREATE TRIGGER trigger_update_invoice_discount_rules_updated_at
    BEFORE UPDATE ON invoice_discount_rules
    FOR EACH ROW
    EXECUTE FUNCTION update_invoice_discount_details_updated_at();

CREATE TRIGGER trigger_update_invoice_discount_analytics_updated_at
    BEFORE UPDATE ON invoice_discount_analytics
    FOR EACH ROW
    EXECUTE FUNCTION update_invoice_discount_details_updated_at();

-- Track discount detail changes in history
CREATE OR REPLACE FUNCTION track_invoice_discount_detail_changes()
RETURNS TRIGGER AS $$
DECLARE
    v_changed_fields TEXT[];
    v_old_values JSONB;
    v_new_values JSONB;
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO invoice_discount_detail_history (
            discount_detail_id, invoice_id, store_id, change_type,
            new_values, created_at
        ) VALUES (
            NEW.id, NEW.invoice_id, NEW.store_id, 'created',
            to_jsonb(NEW), CURRENT_TIMESTAMP
        );
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        -- Detect changed fields
        SELECT array_agg(key), 
               jsonb_object_agg(key, old_value),
               jsonb_object_agg(key, new_value)
        INTO v_changed_fields, v_old_values, v_new_values
        FROM (
            SELECT key, 
                   old_record.value as old_value,
                   new_record.value as new_value
            FROM jsonb_each(to_jsonb(OLD)) old_record
            JOIN jsonb_each(to_jsonb(NEW)) new_record ON old_record.key = new_record.key
            WHERE old_record.value IS DISTINCT FROM new_record.value
            AND old_record.key NOT IN ('updated_at', 'last_sync_at', 'usage_count')
        ) changes;
        
        IF array_length(v_changed_fields, 1) > 0 THEN
            INSERT INTO invoice_discount_detail_history (
                discount_detail_id, invoice_id, store_id, change_type,
                changed_fields, old_values, new_values, created_at
            ) VALUES (
                NEW.id, NEW.invoice_id, NEW.store_id, 'updated',
                v_changed_fields, v_old_values, v_new_values, CURRENT_TIMESTAMP
            );
        END IF;
        
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO invoice_discount_detail_history (
            discount_detail_id, invoice_id, store_id, change_type,
            old_values, created_at
        ) VALUES (
            OLD.id, OLD.invoice_id, OLD.store_id, 'deleted',
            to_jsonb(OLD), CURRENT_TIMESTAMP
        );
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_track_invoice_discount_detail_changes
    AFTER INSERT OR UPDATE OR DELETE ON invoice_discount_details
    FOR EACH ROW
    EXECUTE FUNCTION track_invoice_discount_detail_changes();

-- Validate discount calculations
CREATE OR REPLACE FUNCTION validate_discount_calculation()
RETURNS TRIGGER AS $$
BEGIN
    -- Validate discount amount for percentage discounts
    IF NEW.discount_type = 'percentage' THEN
        IF NEW.discount_value > 1 THEN
            RAISE EXCEPTION 'Percentage discount value (%) cannot exceed 1 (100%%)', NEW.discount_value;
        END IF;
        
        IF ABS(NEW.discount_amount - (NEW.calculation_basis * NEW.discount_value)) > 0.01 THEN
            RAISE EXCEPTION 'Discount amount (%) does not match calculated amount (%) for percentage discount', 
                NEW.discount_amount, (NEW.calculation_basis * NEW.discount_value);
        END IF;
    END IF;
    
    -- Validate fixed amount discounts
    IF NEW.discount_type = 'fixed_amount' THEN
        IF NEW.discount_amount > NEW.calculation_basis THEN
            RAISE EXCEPTION 'Fixed discount amount (%) cannot exceed calculation basis (%)', 
                NEW.discount_amount, NEW.calculation_basis;
        END IF;
    END IF;
    
    -- Validate minimum amount requirements
    IF NEW.minimum_amount IS NOT NULL AND NEW.calculation_basis < NEW.minimum_amount THEN
        RAISE EXCEPTION 'Calculation basis (%) does not meet minimum amount requirement (%)', 
            NEW.calculation_basis, NEW.minimum_amount;
    END IF;
    
    -- Validate maximum discount cap
    IF NEW.maximum_discount IS NOT NULL AND NEW.discount_amount > NEW.maximum_discount THEN
        NEW.discount_amount := NEW.maximum_discount;
        NEW.discount_cap_reached := TRUE;
    END IF;
    
    -- Validate usage limits
    IF NEW.usage_limit IS NOT NULL AND NEW.usage_count > NEW.usage_limit THEN
        RAISE EXCEPTION 'Usage count (%) exceeds usage limit (%)', NEW.usage_count, NEW.usage_limit;
    END IF;
    
    -- Validate date ranges
    IF NEW.valid_from IS NOT NULL AND NEW.valid_until IS NOT NULL THEN
        IF CURRENT_TIMESTAMP < NEW.valid_from OR CURRENT_TIMESTAMP > NEW.valid_until THEN
            NEW.is_expired := TRUE;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validate_discount_calculation
    BEFORE INSERT OR UPDATE ON invoice_discount_details
    FOR EACH ROW
    EXECUTE FUNCTION validate_discount_calculation();

-- Update discount rule usage statistics
CREATE OR REPLACE FUNCTION update_discount_rule_usage()
RETURNS TRIGGER AS $$
BEGIN
    -- Update usage statistics for applicable discount rules
    UPDATE invoice_discount_rules 
    SET application_count = application_count + 1,
        current_usage_count = current_usage_count + 1,
        total_discount_given = total_discount_given + NEW.discount_amount,
        last_used_at = CURRENT_TIMESTAMP
    WHERE store_id = NEW.store_id
    AND discount_type = NEW.discount_type
    AND (rule_code IS NULL OR rule_code = NEW.discount_code)
    AND is_active = TRUE
    AND effective_from <= CURRENT_TIMESTAMP
    AND (effective_until IS NULL OR effective_until >= CURRENT_TIMESTAMP);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_discount_rule_usage
    AFTER INSERT ON invoice_discount_details
    FOR EACH ROW
    EXECUTE FUNCTION update_discount_rule_usage();

-- =============================================================================
-- Helper Functions
-- =============================================================================

/**
 * Get invoice discount details with breakdown
 * @param p_invoice_id UUID - Invoice ID
 * @return JSONB - Complete discount details
 */
CREATE OR REPLACE FUNCTION get_invoice_discount_details(
    p_invoice_id UUID
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'discount_details', jsonb_agg(
            jsonb_build_object(
                'id', idd.id,
                'discount_type', idd.discount_type,
                'discount_name', idd.discount_name,
                'discount_code', idd.discount_code,
                'discount_value', idd.discount_value,
                'discount_amount', idd.discount_amount,
                'discount_percentage', idd.discount_percentage,
                'calculation_basis', idd.calculation_basis,
                'discount_source', idd.discount_source,
                'campaign_name', idd.campaign_name,
                'is_active', idd.is_active,
                'applies_to_shipping', idd.applies_to_shipping,
                'applies_to_tax', idd.applies_to_tax
            )
            ORDER BY idd.combination_priority DESC, idd.discount_amount DESC
        ),
        'discount_summary', jsonb_build_object(
            'total_discount_amount', COALESCE(SUM(idd.discount_amount), 0),
            'total_calculation_basis', COALESCE(SUM(idd.calculation_basis), 0),
            'average_discount_rate', CASE 
                WHEN SUM(idd.calculation_basis) > 0 THEN SUM(idd.discount_amount) / SUM(idd.calculation_basis)
                ELSE 0 
            END,
            'discount_count', COUNT(*),
            'active_discount_count', COUNT(*) FILTER (WHERE idd.is_active = TRUE),
            'coupon_count', COUNT(*) FILTER (WHERE idd.discount_code IS NOT NULL),
            'automatic_discount_count', COUNT(*) FILTER (WHERE idd.discount_code IS NULL)
        )
    ) INTO result
    FROM invoice_discount_details idd
    WHERE idd.invoice_id = p_invoice_id;
    
    RETURN COALESCE(result, '{"discount_details": [], "discount_summary": {"total_discount_amount": 0}}'::jsonb);
END;
$$ LANGUAGE plpgsql;

/**
 * Apply discount to invoice based on rules
 * @param p_invoice_id UUID - Invoice ID
 * @param p_discount_code VARCHAR - Discount code (optional)
 * @param p_customer_id UUID - Customer ID (optional)
 * @return JSONB - Application results
 */
CREATE OR REPLACE FUNCTION apply_invoice_discount(
    p_invoice_id UUID,
    p_discount_code VARCHAR DEFAULT NULL,
    p_customer_id UUID DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_invoice RECORD;
    v_rule RECORD;
    v_discount_amount DECIMAL(15,4);
    v_calculation_basis DECIMAL(15,4);
    result JSONB;
    v_total_discount DECIMAL(15,4) := 0;
    v_applied_count INTEGER := 0;
BEGIN
    -- Get invoice details
    SELECT * INTO v_invoice
    FROM invoices
    WHERE id = p_invoice_id;
    
    IF NOT FOUND THEN
        RETURN '{"error": "Invoice not found"}'::jsonb;
    END IF;
    
    -- Get applicable discount rules
    FOR v_rule IN 
        SELECT * FROM invoice_discount_rules
        WHERE store_id = v_invoice.store_id
        AND is_active = TRUE
        AND effective_from <= CURRENT_TIMESTAMP
        AND (effective_until IS NULL OR effective_until >= CURRENT_TIMESTAMP)
        AND (minimum_order_amount IS NULL OR v_invoice.subtotal >= minimum_order_amount)
        AND (usage_limit IS NULL OR current_usage_count < usage_limit)
        AND (p_discount_code IS NULL OR NOT requires_code OR rule_code = p_discount_code)
        ORDER BY priority DESC, discount_value DESC
    LOOP
        -- Calculate basis amount based on discount method
        CASE v_rule.discount_method
            WHEN 'subtotal' THEN
                v_calculation_basis := v_invoice.subtotal;
            WHEN 'total' THEN
                v_calculation_basis := v_invoice.total;
            ELSE
                v_calculation_basis := v_invoice.subtotal; -- Default to subtotal
        END CASE;
        
        -- Calculate discount amount
        IF v_rule.discount_type = 'percentage' THEN
            v_discount_amount := ROUND(v_calculation_basis * v_rule.discount_value, 4);
        ELSIF v_rule.discount_type = 'fixed_amount' THEN
            v_discount_amount := LEAST(v_rule.discount_value, v_calculation_basis);
        ELSE
            v_discount_amount := ROUND(v_calculation_basis * v_rule.discount_value, 4);
        END IF;
        
        -- Apply maximum discount cap
        IF v_rule.maximum_discount_amount IS NOT NULL THEN
            v_discount_amount := LEAST(v_discount_amount, v_rule.maximum_discount_amount);
        END IF;
        
        v_total_discount := v_total_discount + v_discount_amount;
        v_applied_count := v_applied_count + 1;
        
        -- Insert discount detail
        INSERT INTO invoice_discount_details (
            invoice_id, store_id, discount_type, discount_name, discount_code,
            discount_source, discount_method, discount_value, discount_amount,
            calculation_basis, minimum_amount, maximum_discount,
            campaign_id, promotion_id, is_active,
            data_source, created_at
        ) VALUES (
            p_invoice_id, v_invoice.store_id, v_rule.discount_type, v_rule.rule_name, v_rule.rule_code,
            'automatic', v_rule.discount_method, v_rule.discount_value, v_discount_amount,
            v_calculation_basis, v_rule.minimum_order_amount, v_rule.maximum_discount_amount,
            NULL, NULL, TRUE,
            'calculation', CURRENT_TIMESTAMP
        );
        
        -- Break if single discount rule or cannot combine
        IF NOT v_rule.can_combine THEN
            EXIT;
        END IF;
    END LOOP;
    
    result := jsonb_build_object(
        'invoice_id', p_invoice_id,
        'total_discount_applied', v_total_discount,
        'discounts_applied', v_applied_count,
        'discount_code_used', p_discount_code,
        'application_timestamp', CURRENT_TIMESTAMP
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

/**
 * Get discount performance report for store
 * @param p_store_id UUID - Store ID
 * @param p_start_date DATE - Start date
 * @param p_end_date DATE - End date
 * @return JSONB - Performance report
 */
CREATE OR REPLACE FUNCTION get_discount_performance_report(
    p_store_id UUID,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'report_period', jsonb_build_object(
            'start_date', COALESCE(p_start_date, DATE_TRUNC('month', CURRENT_DATE)),
            'end_date', COALESCE(p_end_date, CURRENT_DATE)
        ),
        'discount_summary', jsonb_build_object(
            'total_discount_given', COALESCE(SUM(idd.discount_amount), 0),
            'total_calculation_basis', COALESCE(SUM(idd.calculation_basis), 0),
            'average_discount_rate', CASE 
                WHEN SUM(idd.calculation_basis) > 0 THEN SUM(idd.discount_amount) / SUM(idd.calculation_basis)
                ELSE 0 
            END,
            'invoice_count', COUNT(DISTINCT idd.invoice_id),
            'discount_application_count', COUNT(*)
        ),
        'discount_by_type', (
            SELECT jsonb_object_agg(discount_type, type_data)
            FROM (
                SELECT 
                    idd.discount_type,
                    jsonb_build_object(
                        'total_amount', SUM(idd.discount_amount),
                        'total_basis', SUM(idd.calculation_basis),
                        'average_value', AVG(idd.discount_value),
                        'application_count', COUNT(*),
                        'unique_invoices', COUNT(DISTINCT idd.invoice_id)
                    ) as type_data
                FROM invoice_discount_details idd
                JOIN invoices i ON i.id = idd.invoice_id
                WHERE idd.store_id = p_store_id
                AND (p_start_date IS NULL OR i.invoice_date >= p_start_date)
                AND (p_end_date IS NULL OR i.invoice_date <= p_end_date)
                GROUP BY idd.discount_type
            ) discount_types
        ),
        'top_discount_codes', (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'discount_code', discount_code,
                    'usage_count', usage_count,
                    'total_discount', total_discount,
                    'average_discount', average_discount
                )
                ORDER BY usage_count DESC
            )
            FROM (
                SELECT 
                    idd.discount_code,
                    COUNT(*) as usage_count,
                    SUM(idd.discount_amount) as total_discount,
                    AVG(idd.discount_amount) as average_discount
                FROM invoice_discount_details idd
                JOIN invoices i ON i.id = idd.invoice_id
                WHERE idd.store_id = p_store_id
                AND idd.discount_code IS NOT NULL
                AND (p_start_date IS NULL OR i.invoice_date >= p_start_date)
                AND (p_end_date IS NULL OR i.invoice_date <= p_end_date)
                GROUP BY idd.discount_code
                ORDER BY COUNT(*) DESC
                LIMIT 10
            ) top_codes
        ),
        'campaign_performance', (
            SELECT jsonb_object_agg(campaign_id, campaign_data)
            FROM (
                SELECT 
                    idd.campaign_id,
                    jsonb_build_object(
                        'total_discount', SUM(idd.discount_amount),
                        'application_count', COUNT(*),
                        'unique_customers', COUNT(DISTINCT i.customer_id),
                        'revenue_impact', SUM(idd.revenue_impact)
                    ) as campaign_data
                FROM invoice_discount_details idd
                JOIN invoices i ON i.id = idd.invoice_id
                WHERE idd.store_id = p_store_id
                AND idd.campaign_id IS NOT NULL
                AND (p_start_date IS NULL OR i.invoice_date >= p_start_date)
                AND (p_end_date IS NULL OR i.invoice_date <= p_end_date)
                GROUP BY idd.campaign_id
            ) campaigns
        )
    ) INTO result
    FROM invoice_discount_details idd
    JOIN invoices i ON i.id = idd.invoice_id
    WHERE idd.store_id = p_store_id
    AND (p_start_date IS NULL OR i.invoice_date >= p_start_date)
    AND (p_end_date IS NULL OR i.invoice_date <= p_end_date);
    
    RETURN COALESCE(result, '{"error": "No discount data found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Comments
-- =============================================================================

COMMENT ON TABLE invoice_discount_details IS 'Normalized discount details for invoices with comprehensive discount information';
COMMENT ON TABLE invoice_discount_detail_history IS 'Track changes to invoice discount details';
COMMENT ON TABLE invoice_discount_rules IS 'Discount calculation rules and campaigns';
COMMENT ON TABLE invoice_discount_analytics IS 'Discount performance analytics and metrics';

COMMENT ON COLUMN invoice_discount_details.discount_value IS 'Discount rate (for percentage) or fixed amount';
COMMENT ON COLUMN invoice_discount_details.discount_amount IS 'Actual discount amount applied to invoice';
COMMENT ON COLUMN invoice_discount_details.calculation_basis IS 'Amount on which discount is calculated';
COMMENT ON COLUMN invoice_discount_details.applies_to_line_items IS 'JSON array of line item IDs this discount applies to';
COMMENT ON COLUMN invoice_discount_details.can_combine_with_other_discounts IS 'Whether this discount can be combined with others';

COMMENT ON FUNCTION get_invoice_discount_details(UUID) IS 'Get complete discount details and summary for invoice';
COMMENT ON FUNCTION apply_invoice_discount(UUID, VARCHAR, UUID) IS 'Apply discount to invoice based on rules and codes';
COMMENT ON FUNCTION get_discount_performance_report(UUID, DATE, DATE) IS 'Generate discount performance report for store';