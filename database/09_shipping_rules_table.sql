-- =============================================
-- Shipping Rules Table
-- =============================================
-- This table stores shipping cost calculation rules,
-- free shipping conditions, and shipping restrictions

CREATE TABLE shipping_rules (
    -- Primary key
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Foreign key to stores table
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Foreign key to shipping zones (optional)
    shipping_zone_id UUID REFERENCES shipping_zones(id) ON DELETE CASCADE,
    
    -- Foreign key to shipping companies (optional)
    shipping_company_id UUID REFERENCES shipping_companies(id) ON DELETE CASCADE,
    
    -- Salla API identifiers
    salla_rule_id VARCHAR(255),
    
    -- Basic rule information
    name VARCHAR(255) NOT NULL,
    name_ar VARCHAR(255),
    name_en VARCHAR(255),
    description TEXT,
    description_ar TEXT,
    description_en TEXT,
    
    -- Rule type and category
    rule_type VARCHAR(50) NOT NULL, -- 'cost_calculation', 'free_shipping', 'restriction', 'discount'
    rule_category VARCHAR(50), -- 'weight_based', 'value_based', 'quantity_based', 'product_based'
    
    -- Rule conditions
    conditions JSONB DEFAULT '{}'::jsonb, -- Complex conditions in JSON format
    
    -- Cost calculation rules
    calculation_method VARCHAR(50), -- 'fixed', 'percentage', 'weight_based', 'tiered', 'formula'
    base_cost DECIMAL(10,2) DEFAULT 0.00,
    cost_per_unit DECIMAL(10,2) DEFAULT 0.00, -- per kg, per item, etc.
    percentage_rate DECIMAL(5,2) DEFAULT 0.00, -- for percentage-based calculations
    
    -- Free shipping conditions
    free_shipping_enabled BOOLEAN DEFAULT false,
    min_order_amount DECIMAL(10,2), -- Minimum order value for free shipping
    min_quantity INTEGER, -- Minimum quantity for free shipping
    min_weight DECIMAL(10,2), -- Minimum weight for free shipping
    
    -- Product-based conditions
    applicable_products JSONB DEFAULT '[]'::jsonb, -- Array of product IDs
    applicable_categories JSONB DEFAULT '[]'::jsonb, -- Array of category IDs
    excluded_products JSONB DEFAULT '[]'::jsonb, -- Array of excluded product IDs
    excluded_categories JSONB DEFAULT '[]'::jsonb, -- Array of excluded category IDs
    
    -- Weight and size restrictions
    min_weight_limit DECIMAL(10,2),
    max_weight_limit DECIMAL(10,2),
    max_dimensions JSONB DEFAULT '{}'::jsonb, -- {"length": 100, "width": 50, "height": 30}
    
    -- Value restrictions
    min_order_value DECIMAL(10,2),
    max_order_value DECIMAL(10,2),
    
    -- Quantity restrictions
    min_quantity_limit INTEGER,
    max_quantity_limit INTEGER,
    
    -- Time-based restrictions
    valid_from TIMESTAMP WITH TIME ZONE,
    valid_until TIMESTAMP WITH TIME ZONE,
    
    -- Day/time restrictions
    valid_days JSONB DEFAULT '[]'::jsonb, -- Array of day numbers (0=Sunday, 1=Monday, etc.)
    valid_hours JSONB DEFAULT '{}'::jsonb, -- {"start": "09:00", "end": "17:00"}
    
    -- Customer-based conditions
    customer_groups JSONB DEFAULT '[]'::jsonb, -- Array of customer group IDs
    customer_types JSONB DEFAULT '[]'::jsonb, -- Array of customer types
    new_customers_only BOOLEAN DEFAULT false,
    
    -- Geographic restrictions
    restricted_countries JSONB DEFAULT '[]'::jsonb,
    restricted_cities JSONB DEFAULT '[]'::jsonb,
    restricted_postal_codes JSONB DEFAULT '[]'::jsonb,
    
    -- Coupon and promotion integration
    requires_coupon BOOLEAN DEFAULT false,
    compatible_coupons JSONB DEFAULT '[]'::jsonb, -- Array of coupon codes
    
    -- Rule priority and stacking
    priority INTEGER DEFAULT 0, -- Higher number = higher priority
    stackable BOOLEAN DEFAULT true, -- Can be combined with other rules
    max_applications INTEGER DEFAULT 1, -- Maximum times this rule can be applied
    
    -- Rule settings
    is_active BOOLEAN DEFAULT true,
    is_automatic BOOLEAN DEFAULT true, -- Automatically applied or requires manual selection
    
    -- Usage tracking
    usage_count INTEGER DEFAULT 0,
    usage_limit INTEGER, -- Maximum number of times this rule can be used
    
    -- Custom formula for complex calculations
    custom_formula TEXT, -- SQL-like formula for complex cost calculations
    
    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- Indexes for Performance
-- =============================================

-- Index on store_id for filtering by store
CREATE INDEX idx_shipping_rules_store_id ON shipping_rules(store_id);

-- Index on shipping_zone_id
CREATE INDEX idx_shipping_rules_zone_id ON shipping_rules(shipping_zone_id);

-- Index on shipping_company_id
CREATE INDEX idx_shipping_rules_company_id ON shipping_rules(shipping_company_id);

-- Index on salla_rule_id for API sync
CREATE INDEX idx_shipping_rules_salla_id ON shipping_rules(salla_rule_id);

-- Index on rule type and category
CREATE INDEX idx_shipping_rules_type ON shipping_rules(rule_type);
CREATE INDEX idx_shipping_rules_category ON shipping_rules(rule_category);

-- Index on active rules
CREATE INDEX idx_shipping_rules_active ON shipping_rules(is_active);

-- Index on automatic rules
CREATE INDEX idx_shipping_rules_automatic ON shipping_rules(is_automatic);

-- Index on priority
CREATE INDEX idx_shipping_rules_priority ON shipping_rules(priority DESC);

-- Index on valid date range
CREATE INDEX idx_shipping_rules_valid_dates ON shipping_rules(valid_from, valid_until);

-- Composite index for rule matching
CREATE INDEX idx_shipping_rules_matching ON shipping_rules(store_id, rule_type, is_active, priority DESC);

-- GIN indexes for JSONB columns
CREATE INDEX idx_shipping_rules_conditions_gin ON shipping_rules USING GIN(conditions);
CREATE INDEX idx_shipping_rules_products_gin ON shipping_rules USING GIN(applicable_products);
CREATE INDEX idx_shipping_rules_categories_gin ON shipping_rules USING GIN(applicable_categories);
CREATE INDEX idx_shipping_rules_customer_groups_gin ON shipping_rules USING GIN(customer_groups);
CREATE INDEX idx_shipping_rules_metadata_gin ON shipping_rules USING GIN(metadata);

-- =============================================
-- Triggers
-- =============================================

-- Trigger to update updated_at column
CREATE TRIGGER trigger_shipping_rules_updated_at
    BEFORE UPDATE ON shipping_rules
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger to increment usage count
CREATE OR REPLACE FUNCTION increment_rule_usage()
RETURNS TRIGGER AS $$
BEGIN
    -- This would be called when a rule is applied to an order
    UPDATE shipping_rules 
    SET usage_count = usage_count + 1
    WHERE id = NEW.shipping_rule_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- Helper Functions
-- =============================================

-- Function to find applicable shipping rules
CREATE OR REPLACE FUNCTION find_applicable_shipping_rules(
    p_store_id UUID,
    p_zone_id UUID DEFAULT NULL,
    p_company_id UUID DEFAULT NULL,
    p_order_total DECIMAL(10,2) DEFAULT 0,
    p_total_weight DECIMAL(10,2) DEFAULT 0,
    p_item_count INTEGER DEFAULT 0,
    p_customer_group VARCHAR(50) DEFAULT NULL
)
RETURNS TABLE (
    rule_id UUID,
    rule_name VARCHAR(255),
    rule_type VARCHAR(50),
    calculation_method VARCHAR(50),
    base_cost DECIMAL(10,2),
    priority INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        sr.id,
        sr.name,
        sr.rule_type,
        sr.calculation_method,
        sr.base_cost,
        sr.priority
    FROM shipping_rules sr
    WHERE sr.store_id = p_store_id
      AND sr.is_active = true
      AND (sr.shipping_zone_id IS NULL OR sr.shipping_zone_id = p_zone_id)
      AND (sr.shipping_company_id IS NULL OR sr.shipping_company_id = p_company_id)
      AND (sr.min_order_value IS NULL OR p_order_total >= sr.min_order_value)
      AND (sr.max_order_value IS NULL OR p_order_total <= sr.max_order_value)
      AND (sr.min_weight_limit IS NULL OR p_total_weight >= sr.min_weight_limit)
      AND (sr.max_weight_limit IS NULL OR p_total_weight <= sr.max_weight_limit)
      AND (sr.min_quantity_limit IS NULL OR p_item_count >= sr.min_quantity_limit)
      AND (sr.max_quantity_limit IS NULL OR p_item_count <= sr.max_quantity_limit)
      AND (sr.valid_from IS NULL OR sr.valid_from <= CURRENT_TIMESTAMP)
      AND (sr.valid_until IS NULL OR sr.valid_until >= CURRENT_TIMESTAMP)
      AND (sr.usage_limit IS NULL OR sr.usage_count < sr.usage_limit)
    ORDER BY sr.priority DESC, sr.created_at ASC;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate shipping cost using rules
CREATE OR REPLACE FUNCTION calculate_shipping_with_rules(
    p_store_id UUID,
    p_zone_id UUID,
    p_company_id UUID,
    p_order_total DECIMAL(10,2),
    p_total_weight DECIMAL(10,2),
    p_item_count INTEGER
)
RETURNS DECIMAL(10,2) AS $$
DECLARE
    rule_record shipping_rules%ROWTYPE;
    total_cost DECIMAL(10,2) := 0;
    rule_cost DECIMAL(10,2);
    free_shipping_applied BOOLEAN := false;
BEGIN
    -- Check for free shipping rules first
    FOR rule_record IN 
        SELECT * FROM shipping_rules 
        WHERE store_id = p_store_id 
          AND rule_type = 'free_shipping'
          AND is_active = true
          AND (shipping_zone_id IS NULL OR shipping_zone_id = p_zone_id)
          AND (shipping_company_id IS NULL OR shipping_company_id = p_company_id)
          AND (min_order_amount IS NULL OR p_order_total >= min_order_amount)
          AND (min_quantity IS NULL OR p_item_count >= min_quantity)
          AND (min_weight IS NULL OR p_total_weight >= min_weight)
        ORDER BY priority DESC
    LOOP
        free_shipping_applied := true;
        EXIT; -- First matching free shipping rule wins
    END LOOP;
    
    IF free_shipping_applied THEN
        RETURN 0;
    END IF;
    
    -- Apply cost calculation rules
    FOR rule_record IN 
        SELECT * FROM shipping_rules 
        WHERE store_id = p_store_id 
          AND rule_type = 'cost_calculation'
          AND is_active = true
          AND (shipping_zone_id IS NULL OR shipping_zone_id = p_zone_id)
          AND (shipping_company_id IS NULL OR shipping_company_id = p_company_id)
        ORDER BY priority DESC
    LOOP
        rule_cost := 0;
        
        CASE rule_record.calculation_method
            WHEN 'fixed' THEN
                rule_cost := rule_record.base_cost;
            WHEN 'weight_based' THEN
                rule_cost := rule_record.base_cost + (rule_record.cost_per_unit * p_total_weight);
            WHEN 'percentage' THEN
                rule_cost := p_order_total * (rule_record.percentage_rate / 100);
            ELSE
                rule_cost := rule_record.base_cost;
        END CASE;
        
        IF rule_record.stackable THEN
            total_cost := total_cost + rule_cost;
        ELSE
            total_cost := GREATEST(total_cost, rule_cost);
        END IF;
    END LOOP;
    
    RETURN GREATEST(total_cost, 0);
END;
$$ LANGUAGE plpgsql;

-- Function to check if free shipping is available
CREATE OR REPLACE FUNCTION check_free_shipping_eligibility(
    p_store_id UUID,
    p_zone_id UUID,
    p_order_total DECIMAL(10,2),
    p_total_weight DECIMAL(10,2),
    p_item_count INTEGER
)
RETURNS BOOLEAN AS $$
DECLARE
    eligible BOOLEAN := false;
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM shipping_rules 
        WHERE store_id = p_store_id 
          AND rule_type = 'free_shipping'
          AND is_active = true
          AND (shipping_zone_id IS NULL OR shipping_zone_id = p_zone_id)
          AND (min_order_amount IS NULL OR p_order_total >= min_order_amount)
          AND (min_quantity IS NULL OR p_item_count >= min_quantity)
          AND (min_weight IS NULL OR p_total_weight >= min_weight)
          AND (valid_from IS NULL OR valid_from <= CURRENT_TIMESTAMP)
          AND (valid_until IS NULL OR valid_until >= CURRENT_TIMESTAMP)
    ) INTO eligible;
    
    RETURN eligible;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- Comments
-- =============================================

COMMENT ON TABLE shipping_rules IS 'Stores shipping cost calculation rules, free shipping conditions, and restrictions';
COMMENT ON COLUMN shipping_rules.store_id IS 'Reference to the store this rule belongs to';
COMMENT ON COLUMN shipping_rules.shipping_zone_id IS 'Optional reference to specific shipping zone';
COMMENT ON COLUMN shipping_rules.shipping_company_id IS 'Optional reference to specific shipping company';
COMMENT ON COLUMN shipping_rules.rule_type IS 'Type of rule: cost_calculation, free_shipping, restriction, discount';
COMMENT ON COLUMN shipping_rules.rule_category IS 'Category: weight_based, value_based, quantity_based, product_based';
COMMENT ON COLUMN shipping_rules.conditions IS 'Complex rule conditions in JSON format';
COMMENT ON COLUMN shipping_rules.calculation_method IS 'Method: fixed, percentage, weight_based, tiered, formula';
COMMENT ON COLUMN shipping_rules.applicable_products IS 'JSON array of product IDs this rule applies to';
COMMENT ON COLUMN shipping_rules.applicable_categories IS 'JSON array of category IDs this rule applies to';
COMMENT ON COLUMN shipping_rules.stackable IS 'Whether this rule can be combined with other rules';
COMMENT ON COLUMN shipping_rules.custom_formula IS 'Custom SQL-like formula for complex calculations';
COMMENT ON COLUMN shipping_rules.metadata IS 'Additional metadata in JSON format';