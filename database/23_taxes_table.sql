-- =============================================================================
-- Taxes Table
-- =============================================================================
-- This table stores tax configurations, rates, and rules for different regions
-- Supports complex tax calculations including VAT, sales tax, and custom taxes

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create taxes table
CREATE TABLE IF NOT EXISTS taxes (
    -- Primary identification
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Salla API identifiers
    salla_tax_id VARCHAR(100) UNIQUE,
    salla_store_id VARCHAR(100),
    
    -- Store relationship
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Tax identification
    tax_name VARCHAR(255) NOT NULL,
    tax_code VARCHAR(100),
    tax_slug VARCHAR(255),
    tax_reference VARCHAR(100), -- External reference number
    
    -- Tax description and details
    tax_description TEXT,
    tax_purpose TEXT,
    tax_notes TEXT,
    
    -- Tax type and classification
    tax_type VARCHAR(50) DEFAULT 'sales_tax', -- sales_tax, vat, excise, customs, service_tax, luxury_tax, environmental_tax
    tax_category VARCHAR(100), -- federal, state, local, municipal, special
    tax_class VARCHAR(100), -- standard, reduced, zero, exempt, reverse_charge
    
    -- Tax rate configuration
    tax_rate DECIMAL(8,6) NOT NULL DEFAULT 0, -- Tax rate as percentage (e.g., 15.000000 for 15%)
    tax_amount DECIMAL(15,4), -- Fixed tax amount (alternative to percentage)
    minimum_tax_amount DECIMAL(15,4) DEFAULT 0,
    maximum_tax_amount DECIMAL(15,4),
    
    -- Tax calculation method
    calculation_method VARCHAR(50) DEFAULT 'percentage', -- percentage, fixed_amount, tiered, progressive
    calculation_base VARCHAR(50) DEFAULT 'subtotal', -- subtotal, total, item_price, quantity
    rounding_method VARCHAR(50) DEFAULT 'round', -- round, floor, ceil, no_rounding
    rounding_precision INTEGER DEFAULT 2,
    
    -- Tax applicability and scope
    applies_to VARCHAR(50) DEFAULT 'all', -- all, products, shipping, services, digital_goods
    product_types JSONB DEFAULT '[]', -- Array of product types this tax applies to
    excluded_product_types JSONB DEFAULT '[]', -- Array of product types excluded from this tax
    customer_types JSONB DEFAULT '[]', -- Array of customer types this tax applies to
    
    -- Geographic scope
    country_code VARCHAR(3),
    state_province VARCHAR(100),
    city VARCHAR(100),
    postal_codes JSONB DEFAULT '[]', -- Array of postal codes
    geographic_zones JSONB DEFAULT '[]', -- Array of zone IDs
    
    -- Tax status and validity
    is_active BOOLEAN DEFAULT TRUE,
    is_default BOOLEAN DEFAULT FALSE,
    is_inclusive BOOLEAN DEFAULT FALSE, -- Whether tax is included in price
    is_compound BOOLEAN DEFAULT FALSE, -- Whether this tax compounds on other taxes
    tax_status VARCHAR(50) DEFAULT 'active', -- active, inactive, suspended, archived
    
    -- Tax hierarchy and dependencies
    parent_tax_id UUID REFERENCES taxes(id) ON DELETE SET NULL,
    tax_group VARCHAR(100),
    tax_priority INTEGER DEFAULT 0, -- Order of tax calculation
    depends_on_taxes JSONB DEFAULT '[]', -- Array of tax IDs this tax depends on
    
    -- Date and time validity
    effective_from TIMESTAMPTZ,
    effective_until TIMESTAMPTZ,
    valid_days JSONB DEFAULT '[]', -- Array of valid days of week [1-7]
    valid_hours JSONB DEFAULT '{}', -- {"start": "09:00", "end": "17:00"}
    
    -- Tiered tax rates (for progressive taxation)
    tax_tiers JSONB DEFAULT '[]', -- [{"min": 0, "max": 1000, "rate": 5}, {"min": 1000, "max": null, "rate": 10}]
    
    -- Tax exemptions and conditions
    exemption_conditions JSONB DEFAULT '{}',
    minimum_order_amount DECIMAL(15,4) DEFAULT 0,
    maximum_order_amount DECIMAL(15,4),
    minimum_quantity INTEGER DEFAULT 0,
    maximum_quantity INTEGER,
    
    -- Tax registration and compliance
    tax_registration_number VARCHAR(100),
    tax_authority VARCHAR(255),
    compliance_requirements JSONB DEFAULT '{}',
    reporting_requirements JSONB DEFAULT '{}',
    
    -- Tax display and formatting
    display_name VARCHAR(255),
    display_format VARCHAR(100) DEFAULT 'percentage', -- percentage, amount, both
    display_on_invoice BOOLEAN DEFAULT TRUE,
    display_on_receipt BOOLEAN DEFAULT TRUE,
    display_separately BOOLEAN DEFAULT TRUE,
    
    -- Tax calculation settings
    calculation_settings JSONB DEFAULT '{}',
    rounding_settings JSONB DEFAULT '{}',
    precision_settings JSONB DEFAULT '{}',
    
    -- Integration and API settings
    external_tax_service VARCHAR(100), -- avalara, taxjar, vertex, etc.
    external_tax_id VARCHAR(100),
    api_settings JSONB DEFAULT '{}',
    sync_settings JSONB DEFAULT '{}',
    
    -- Tax reporting and analytics
    reporting_code VARCHAR(100),
    analytics_category VARCHAR(100),
    tracking_settings JSONB DEFAULT '{}',
    
    -- Tax performance metrics
    total_collected DECIMAL(15,4) DEFAULT 0,
    total_orders INTEGER DEFAULT 0,
    average_tax_amount DECIMAL(15,4) DEFAULT 0,
    collection_rate DECIMAL(5,4) DEFAULT 0,
    
    -- Tax audit and compliance
    audit_trail JSONB DEFAULT '[]',
    compliance_status VARCHAR(50) DEFAULT 'compliant', -- compliant, non_compliant, under_review
    last_audit_date TIMESTAMPTZ,
    next_audit_date TIMESTAMPTZ,
    
    -- Tax rules and automation
    auto_calculation BOOLEAN DEFAULT TRUE,
    calculation_rules JSONB DEFAULT '{}',
    validation_rules JSONB DEFAULT '{}',
    automation_settings JSONB DEFAULT '{}',
    
    -- Tax localization
    translations JSONB DEFAULT '{}', -- {"en": {"name": "...", "description": "..."}, "ar": {...}}
    default_language VARCHAR(5) DEFAULT 'en',
    currency_code VARCHAR(3) DEFAULT 'USD',
    
    -- Tax history and versioning
    version_number INTEGER DEFAULT 1,
    previous_version_id UUID REFERENCES taxes(id) ON DELETE SET NULL,
    change_reason TEXT,
    change_log JSONB DEFAULT '[]',
    
    -- Tax notifications and alerts
    notification_settings JSONB DEFAULT '{}',
    alert_thresholds JSONB DEFAULT '{}',
    
    -- Integration and sync
    integration_settings JSONB DEFAULT '{}',
    sync_status VARCHAR(50) DEFAULT 'pending',
    last_sync_at TIMESTAMPTZ,
    sync_errors JSONB DEFAULT '[]',
    
    -- API and external references
    external_references JSONB DEFAULT '{}',
    webhook_settings JSONB DEFAULT '{}',
    
    -- Metadata and custom fields
    metadata JSONB DEFAULT '{}',
    custom_fields JSONB DEFAULT '{}',
    attributes JSONB DEFAULT '{}',
    
    -- Internal management
    internal_notes TEXT,
    admin_comments TEXT,
    maintenance_notes TEXT,
    
    -- Approval and workflow
    approval_status VARCHAR(50) DEFAULT 'approved', -- pending, approved, rejected
    approved_by UUID REFERENCES users(id) ON DELETE SET NULL,
    approved_at TIMESTAMPTZ,
    rejection_reason TEXT,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    
    -- Constraints
    CONSTRAINT taxes_tax_name_store_unique UNIQUE(tax_name, store_id),
    CONSTRAINT taxes_tax_code_store_unique UNIQUE(tax_code, store_id),
    CONSTRAINT taxes_tax_slug_store_unique UNIQUE(tax_slug, store_id),
    CONSTRAINT taxes_tax_type_check CHECK (tax_type IN ('sales_tax', 'vat', 'excise', 'customs', 'service_tax', 'luxury_tax', 'environmental_tax')),
    CONSTRAINT taxes_tax_category_check CHECK (tax_category IN ('federal', 'state', 'local', 'municipal', 'special')),
    CONSTRAINT taxes_tax_class_check CHECK (tax_class IN ('standard', 'reduced', 'zero', 'exempt', 'reverse_charge')),
    CONSTRAINT taxes_calculation_method_check CHECK (calculation_method IN ('percentage', 'fixed_amount', 'tiered', 'progressive')),
    CONSTRAINT taxes_calculation_base_check CHECK (calculation_base IN ('subtotal', 'total', 'item_price', 'quantity')),
    CONSTRAINT taxes_rounding_method_check CHECK (rounding_method IN ('round', 'floor', 'ceil', 'no_rounding')),
    CONSTRAINT taxes_applies_to_check CHECK (applies_to IN ('all', 'products', 'shipping', 'services', 'digital_goods')),
    CONSTRAINT taxes_tax_status_check CHECK (tax_status IN ('active', 'inactive', 'suspended', 'archived')),
    CONSTRAINT taxes_display_format_check CHECK (display_format IN ('percentage', 'amount', 'both')),
    CONSTRAINT taxes_compliance_status_check CHECK (compliance_status IN ('compliant', 'non_compliant', 'under_review')),
    CONSTRAINT taxes_approval_status_check CHECK (approval_status IN ('pending', 'approved', 'rejected')),
    CONSTRAINT taxes_sync_status_check CHECK (sync_status IN ('pending', 'syncing', 'synced', 'error')),
    CONSTRAINT taxes_tax_rate_check CHECK (tax_rate >= 0 AND tax_rate <= 100),
    CONSTRAINT taxes_tax_amount_check CHECK (tax_amount IS NULL OR tax_amount >= 0),
    CONSTRAINT taxes_minimum_tax_amount_check CHECK (minimum_tax_amount >= 0),
    CONSTRAINT taxes_maximum_tax_amount_check CHECK (maximum_tax_amount IS NULL OR maximum_tax_amount >= minimum_tax_amount),
    CONSTRAINT taxes_rounding_precision_check CHECK (rounding_precision >= 0 AND rounding_precision <= 10),
    CONSTRAINT taxes_tax_priority_check CHECK (tax_priority >= 0),
    CONSTRAINT taxes_minimum_order_amount_check CHECK (minimum_order_amount >= 0),
    CONSTRAINT taxes_maximum_order_amount_check CHECK (maximum_order_amount IS NULL OR maximum_order_amount >= minimum_order_amount),
    CONSTRAINT taxes_minimum_quantity_check CHECK (minimum_quantity >= 0),
    CONSTRAINT taxes_maximum_quantity_check CHECK (maximum_quantity IS NULL OR maximum_quantity >= minimum_quantity),
    CONSTRAINT taxes_collection_rate_check CHECK (collection_rate >= 0 AND collection_rate <= 1),
    CONSTRAINT taxes_version_number_check CHECK (version_number > 0),
    CONSTRAINT taxes_effective_dates_check CHECK (effective_until IS NULL OR effective_until > effective_from)
);

-- =============================================================================
-- Indexes
-- =============================================================================

-- Primary indexes
CREATE INDEX IF NOT EXISTS idx_taxes_store_id ON taxes(store_id);
CREATE INDEX IF NOT EXISTS idx_taxes_salla_tax_id ON taxes(salla_tax_id);
CREATE INDEX IF NOT EXISTS idx_taxes_salla_store_id ON taxes(salla_store_id);

-- Search and filtering indexes
CREATE INDEX IF NOT EXISTS idx_taxes_tax_name ON taxes(tax_name);
CREATE INDEX IF NOT EXISTS idx_taxes_tax_code ON taxes(tax_code);
CREATE INDEX IF NOT EXISTS idx_taxes_tax_slug ON taxes(tax_slug);
CREATE INDEX IF NOT EXISTS idx_taxes_tax_type ON taxes(tax_type);
CREATE INDEX IF NOT EXISTS idx_taxes_tax_category ON taxes(tax_category);
CREATE INDEX IF NOT EXISTS idx_taxes_tax_class ON taxes(tax_class);
CREATE INDEX IF NOT EXISTS idx_taxes_tax_status ON taxes(tax_status);
CREATE INDEX IF NOT EXISTS idx_taxes_is_active ON taxes(is_active);
CREATE INDEX IF NOT EXISTS idx_taxes_is_default ON taxes(is_default);
CREATE INDEX IF NOT EXISTS idx_taxes_is_inclusive ON taxes(is_inclusive);

-- Geographic indexes
CREATE INDEX IF NOT EXISTS idx_taxes_country_code ON taxes(country_code);
CREATE INDEX IF NOT EXISTS idx_taxes_state_province ON taxes(state_province);
CREATE INDEX IF NOT EXISTS idx_taxes_city ON taxes(city);
CREATE INDEX IF NOT EXISTS idx_taxes_geographic_location ON taxes(country_code, state_province, city);

-- Rate and calculation indexes
CREATE INDEX IF NOT EXISTS idx_taxes_tax_rate ON taxes(tax_rate);
CREATE INDEX IF NOT EXISTS idx_taxes_calculation_method ON taxes(calculation_method);
CREATE INDEX IF NOT EXISTS idx_taxes_tax_priority ON taxes(tax_priority);

-- Hierarchy indexes
CREATE INDEX IF NOT EXISTS idx_taxes_parent_tax_id ON taxes(parent_tax_id);
CREATE INDEX IF NOT EXISTS idx_taxes_tax_group ON taxes(tax_group);

-- Date and validity indexes
CREATE INDEX IF NOT EXISTS idx_taxes_effective_from ON taxes(effective_from);
CREATE INDEX IF NOT EXISTS idx_taxes_effective_until ON taxes(effective_until);
CREATE INDEX IF NOT EXISTS idx_taxes_effective_period ON taxes(effective_from, effective_until);

-- Performance and metrics indexes
CREATE INDEX IF NOT EXISTS idx_taxes_total_collected ON taxes(total_collected DESC);
CREATE INDEX IF NOT EXISTS idx_taxes_total_orders ON taxes(total_orders DESC);
CREATE INDEX IF NOT EXISTS idx_taxes_collection_rate ON taxes(collection_rate DESC);

-- Compliance and audit indexes
CREATE INDEX IF NOT EXISTS idx_taxes_compliance_status ON taxes(compliance_status);
CREATE INDEX IF NOT EXISTS idx_taxes_approval_status ON taxes(approval_status);
CREATE INDEX IF NOT EXISTS idx_taxes_approved_by ON taxes(approved_by);
CREATE INDEX IF NOT EXISTS idx_taxes_last_audit_date ON taxes(last_audit_date);

-- Text search indexes
CREATE INDEX IF NOT EXISTS idx_taxes_name_search ON taxes USING gin(tax_name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_taxes_description_search ON taxes USING gin(tax_description gin_trgm_ops);

-- JSONB indexes
CREATE INDEX IF NOT EXISTS idx_taxes_product_types ON taxes USING gin(product_types);
CREATE INDEX IF NOT EXISTS idx_taxes_customer_types ON taxes USING gin(customer_types);
CREATE INDEX IF NOT EXISTS idx_taxes_postal_codes ON taxes USING gin(postal_codes);
CREATE INDEX IF NOT EXISTS idx_taxes_geographic_zones ON taxes USING gin(geographic_zones);
CREATE INDEX IF NOT EXISTS idx_taxes_tax_tiers ON taxes USING gin(tax_tiers);
CREATE INDEX IF NOT EXISTS idx_taxes_calculation_settings ON taxes USING gin(calculation_settings);
CREATE INDEX IF NOT EXISTS idx_taxes_metadata ON taxes USING gin(metadata);
CREATE INDEX IF NOT EXISTS idx_taxes_translations ON taxes USING gin(translations);

-- Composite indexes
CREATE INDEX IF NOT EXISTS idx_taxes_store_active_type ON taxes(store_id, is_active, tax_type);
CREATE INDEX IF NOT EXISTS idx_taxes_store_location ON taxes(store_id, country_code, state_province, is_active);
CREATE INDEX IF NOT EXISTS idx_taxes_store_priority ON taxes(store_id, tax_priority, is_active);
CREATE INDEX IF NOT EXISTS idx_taxes_calculation_active ON taxes(calculation_method, is_active, tax_status);
CREATE INDEX IF NOT EXISTS idx_taxes_sync_status ON taxes(sync_status, last_sync_at);

-- Timestamp indexes
CREATE INDEX IF NOT EXISTS idx_taxes_created_at ON taxes(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_taxes_updated_at ON taxes(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_taxes_deleted_at ON taxes(deleted_at) WHERE deleted_at IS NOT NULL;

-- =============================================================================
-- Triggers
-- =============================================================================

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_taxes_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_taxes_updated_at
    BEFORE UPDATE ON taxes
    FOR EACH ROW
    EXECUTE FUNCTION update_taxes_updated_at();

-- Trigger to generate tax slug
CREATE OR REPLACE FUNCTION generate_tax_slug()
RETURNS TRIGGER AS $$
BEGIN
    -- Generate slug from tax name if not provided
    IF NEW.tax_slug IS NULL OR NEW.tax_slug = '' THEN
        NEW.tax_slug = lower(regexp_replace(NEW.tax_name, '[^a-zA-Z0-9\s]', '', 'g'));
        NEW.tax_slug = regexp_replace(NEW.tax_slug, '\s+', '-', 'g');
        NEW.tax_slug = trim(both '-' from NEW.tax_slug);
    END IF;
    
    -- Ensure slug uniqueness within store
    DECLARE
        base_slug TEXT := NEW.tax_slug;
        counter INTEGER := 1;
    BEGIN
        WHILE EXISTS (
            SELECT 1 FROM taxes 
            WHERE tax_slug = NEW.tax_slug 
            AND store_id = NEW.store_id 
            AND id != COALESCE(NEW.id, uuid_generate_v4())
        ) LOOP
            NEW.tax_slug = base_slug || '-' || counter;
            counter = counter + 1;
        END LOOP;
    END;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_taxes_generate_slug
    BEFORE INSERT OR UPDATE ON taxes
    FOR EACH ROW
    EXECUTE FUNCTION generate_tax_slug();

-- Trigger to validate tax configuration
CREATE OR REPLACE FUNCTION validate_tax_configuration()
RETURNS TRIGGER AS $$
BEGIN
    -- Validate that only one default tax per type per store
    IF NEW.is_default = TRUE THEN
        UPDATE taxes 
        SET is_default = FALSE 
        WHERE store_id = NEW.store_id 
        AND tax_type = NEW.tax_type 
        AND id != NEW.id;
    END IF;
    
    -- Validate effective dates
    IF NEW.effective_from IS NOT NULL AND NEW.effective_until IS NOT NULL THEN
        IF NEW.effective_until <= NEW.effective_from THEN
            RAISE EXCEPTION 'Effective until date must be after effective from date';
        END IF;
    END IF;
    
    -- Validate tax rate for percentage calculation
    IF NEW.calculation_method = 'percentage' AND (NEW.tax_rate IS NULL OR NEW.tax_rate < 0) THEN
        RAISE EXCEPTION 'Tax rate must be specified and non-negative for percentage calculation';
    END IF;
    
    -- Validate tax amount for fixed amount calculation
    IF NEW.calculation_method = 'fixed_amount' AND (NEW.tax_amount IS NULL OR NEW.tax_amount < 0) THEN
        RAISE EXCEPTION 'Tax amount must be specified and non-negative for fixed amount calculation';
    END IF;
    
    -- Set display name if not provided
    IF NEW.display_name IS NULL OR NEW.display_name = '' THEN
        NEW.display_name = NEW.tax_name;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_taxes_validate_configuration
    BEFORE INSERT OR UPDATE ON taxes
    FOR EACH ROW
    EXECUTE FUNCTION validate_tax_configuration();

-- Trigger to update tax performance metrics
CREATE OR REPLACE FUNCTION update_tax_performance_metrics()
RETURNS TRIGGER AS $$
BEGIN
    -- Calculate average tax amount
    IF NEW.total_orders > 0 THEN
        NEW.average_tax_amount = NEW.total_collected / NEW.total_orders;
    ELSE
        NEW.average_tax_amount = 0;
    END IF;
    
    -- Calculate collection rate (assuming 100% for now, can be updated with actual logic)
    IF NEW.total_orders > 0 THEN
        NEW.collection_rate = 1.0; -- This should be calculated based on actual collection vs expected
    ELSE
        NEW.collection_rate = 0;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_taxes_performance_metrics
    BEFORE UPDATE ON taxes
    FOR EACH ROW
    EXECUTE FUNCTION update_tax_performance_metrics();

-- =============================================================================
-- Helper Functions
-- =============================================================================

-- Function: Calculate tax amount for an order
CREATE OR REPLACE FUNCTION calculate_tax_amount(
    p_tax_id UUID,
    p_base_amount DECIMAL(15,4),
    p_quantity INTEGER DEFAULT 1,
    p_customer_type VARCHAR(100) DEFAULT NULL,
    p_product_type VARCHAR(100) DEFAULT NULL
)
RETURNS DECIMAL(15,4) AS $$
DECLARE
    tax_record taxes%ROWTYPE;
    calculated_amount DECIMAL(15,4) := 0;
    tier_rate DECIMAL(8,6);
    tier_record JSONB;
BEGIN
    -- Get tax configuration
    SELECT * INTO tax_record FROM taxes WHERE id = p_tax_id AND is_active = TRUE;
    
    IF NOT FOUND THEN
        RETURN 0;
    END IF;
    
    -- Check if tax applies to this customer/product type
    IF tax_record.customer_types != '[]' AND 
       (p_customer_type IS NULL OR NOT (tax_record.customer_types ? p_customer_type)) THEN
        RETURN 0;
    END IF;
    
    IF tax_record.product_types != '[]' AND 
       (p_product_type IS NULL OR NOT (tax_record.product_types ? p_product_type)) THEN
        RETURN 0;
    END IF;
    
    -- Check excluded product types
    IF p_product_type IS NOT NULL AND (tax_record.excluded_product_types ? p_product_type) THEN
        RETURN 0;
    END IF;
    
    -- Calculate tax based on method
    CASE tax_record.calculation_method
        WHEN 'percentage' THEN
            calculated_amount = p_base_amount * (tax_record.tax_rate / 100);
            
        WHEN 'fixed_amount' THEN
            calculated_amount = tax_record.tax_amount * p_quantity;
            
        WHEN 'tiered' THEN
            -- Find applicable tier
            FOR tier_record IN SELECT * FROM jsonb_array_elements(tax_record.tax_tiers)
            LOOP
                IF (tier_record->>'min')::DECIMAL <= p_base_amount AND 
                   (tier_record->>'max' IS NULL OR (tier_record->>'max')::DECIMAL >= p_base_amount) THEN
                    tier_rate = (tier_record->>'rate')::DECIMAL;
                    calculated_amount = p_base_amount * (tier_rate / 100);
                    EXIT;
                END IF;
            END LOOP;
            
        WHEN 'progressive' THEN
            -- Progressive calculation (sum of all applicable tiers)
            FOR tier_record IN SELECT * FROM jsonb_array_elements(tax_record.tax_tiers)
            LOOP
                DECLARE
                    tier_min DECIMAL(15,4) := (tier_record->>'min')::DECIMAL;
                    tier_max DECIMAL(15,4) := COALESCE((tier_record->>'max')::DECIMAL, p_base_amount);
                    tier_amount DECIMAL(15,4);
                BEGIN
                    IF p_base_amount > tier_min THEN
                        tier_amount = LEAST(p_base_amount, tier_max) - tier_min;
                        tier_rate = (tier_record->>'rate')::DECIMAL;
                        calculated_amount = calculated_amount + (tier_amount * (tier_rate / 100));
                    END IF;
                END;
            END LOOP;
    END CASE;
    
    -- Apply minimum and maximum limits
    IF tax_record.minimum_tax_amount > 0 THEN
        calculated_amount = GREATEST(calculated_amount, tax_record.minimum_tax_amount);
    END IF;
    
    IF tax_record.maximum_tax_amount IS NOT NULL THEN
        calculated_amount = LEAST(calculated_amount, tax_record.maximum_tax_amount);
    END IF;
    
    -- Apply rounding
    CASE tax_record.rounding_method
        WHEN 'round' THEN
            calculated_amount = ROUND(calculated_amount, tax_record.rounding_precision);
        WHEN 'floor' THEN
            calculated_amount = FLOOR(calculated_amount * POWER(10, tax_record.rounding_precision)) / POWER(10, tax_record.rounding_precision);
        WHEN 'ceil' THEN
            calculated_amount = CEIL(calculated_amount * POWER(10, tax_record.rounding_precision)) / POWER(10, tax_record.rounding_precision);
        -- 'no_rounding' - do nothing
    END CASE;
    
    RETURN calculated_amount;
END;
$$ LANGUAGE plpgsql;

-- Function: Get applicable taxes for location
CREATE OR REPLACE FUNCTION get_applicable_taxes(
    p_store_id UUID,
    p_country_code VARCHAR(3) DEFAULT NULL,
    p_state_province VARCHAR(100) DEFAULT NULL,
    p_city VARCHAR(100) DEFAULT NULL,
    p_postal_code VARCHAR(20) DEFAULT NULL,
    p_customer_type VARCHAR(100) DEFAULT NULL,
    p_product_type VARCHAR(100) DEFAULT NULL
)
RETURNS TABLE (
    tax_id UUID,
    tax_name VARCHAR(255),
    tax_code VARCHAR(100),
    tax_type VARCHAR(50),
    tax_rate DECIMAL(8,6),
    tax_amount DECIMAL(15,4),
    calculation_method VARCHAR(50),
    is_inclusive BOOLEAN,
    tax_priority INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.id,
        t.tax_name,
        t.tax_code,
        t.tax_type,
        t.tax_rate,
        t.tax_amount,
        t.calculation_method,
        t.is_inclusive,
        t.tax_priority
    FROM taxes t
    WHERE t.store_id = p_store_id
    AND t.is_active = TRUE
    AND t.deleted_at IS NULL
    AND (t.effective_from IS NULL OR t.effective_from <= NOW())
    AND (t.effective_until IS NULL OR t.effective_until > NOW())
    AND (
        t.country_code IS NULL OR 
        t.country_code = p_country_code
    )
    AND (
        t.state_province IS NULL OR 
        t.state_province = p_state_province
    )
    AND (
        t.city IS NULL OR 
        t.city = p_city
    )
    AND (
        t.postal_codes = '[]' OR 
        p_postal_code IS NULL OR 
        t.postal_codes ? p_postal_code
    )
    AND (
        t.customer_types = '[]' OR 
        p_customer_type IS NULL OR 
        t.customer_types ? p_customer_type
    )
    AND (
        t.product_types = '[]' OR 
        p_product_type IS NULL OR 
        t.product_types ? p_product_type
    )
    AND (
        p_product_type IS NULL OR 
        NOT (t.excluded_product_types ? p_product_type)
    )
    ORDER BY t.tax_priority, t.tax_name;
END;
$$ LANGUAGE plpgsql;

-- Function: Get store tax statistics
CREATE OR REPLACE FUNCTION get_store_tax_stats(p_store_id UUID)
RETURNS TABLE (
    total_taxes BIGINT,
    active_taxes BIGINT,
    total_collected DECIMAL(15,4),
    average_tax_rate DECIMAL(8,6),
    most_used_tax_type VARCHAR(50)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::BIGINT as total_taxes,
        COUNT(*) FILTER (WHERE is_active = TRUE)::BIGINT as active_taxes,
        COALESCE(SUM(t.total_collected), 0) as total_collected,
        COALESCE(AVG(t.tax_rate), 0) as average_tax_rate,
        (
            SELECT tax_type 
            FROM taxes 
            WHERE store_id = p_store_id 
            AND deleted_at IS NULL 
            GROUP BY tax_type 
            ORDER BY COUNT(*) DESC 
            LIMIT 1
        ) as most_used_tax_type
    FROM taxes t
    WHERE t.store_id = p_store_id
    AND t.deleted_at IS NULL;
END;
$$ LANGUAGE plpgsql;

-- Function: Update tax collection metrics
CREATE OR REPLACE FUNCTION update_tax_collection_metrics(
    p_tax_id UUID,
    p_collected_amount DECIMAL(15,4)
)
RETURNS VOID AS $$
BEGIN
    UPDATE taxes
    SET 
        total_collected = total_collected + p_collected_amount,
        total_orders = total_orders + 1,
        updated_at = NOW()
    WHERE id = p_tax_id;
END;
$$ LANGUAGE plpgsql;

-- Function: Get tax compliance report
CREATE OR REPLACE FUNCTION get_tax_compliance_report(
    p_store_id UUID,
    p_start_date TIMESTAMPTZ DEFAULT NULL,
    p_end_date TIMESTAMPTZ DEFAULT NULL
)
RETURNS TABLE (
    tax_id UUID,
    tax_name VARCHAR(255),
    tax_type VARCHAR(50),
    compliance_status VARCHAR(50),
    total_collected DECIMAL(15,4),
    total_orders INTEGER,
    last_audit_date TIMESTAMPTZ,
    next_audit_date TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.id,
        t.tax_name,
        t.tax_type,
        t.compliance_status,
        t.total_collected,
        t.total_orders,
        t.last_audit_date,
        t.next_audit_date
    FROM taxes t
    WHERE t.store_id = p_store_id
    AND t.deleted_at IS NULL
    AND (p_start_date IS NULL OR t.created_at >= p_start_date)
    AND (p_end_date IS NULL OR t.created_at <= p_end_date)
    ORDER BY t.compliance_status, t.tax_name;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Comments
-- =============================================================================

COMMENT ON TABLE taxes IS 'Tax configurations, rates, and rules for different regions and products';
COMMENT ON COLUMN taxes.id IS 'Primary key for the tax';
COMMENT ON COLUMN taxes.salla_tax_id IS 'Unique identifier from Salla API';
COMMENT ON COLUMN taxes.store_id IS 'Reference to the store this tax belongs to';
COMMENT ON COLUMN taxes.tax_name IS 'Name of the tax';
COMMENT ON COLUMN taxes.tax_rate IS 'Tax rate as percentage (e.g., 15.000000 for 15%)';
COMMENT ON COLUMN taxes.tax_type IS 'Type of tax (sales_tax, vat, excise, etc.)';
COMMENT ON COLUMN taxes.calculation_method IS 'Method for calculating tax (percentage, fixed_amount, tiered, progressive)';
COMMENT ON COLUMN taxes.is_inclusive IS 'Whether tax is included in the displayed price';
COMMENT ON COLUMN taxes.tax_tiers IS 'Tiered tax rates for progressive taxation';
COMMENT ON COLUMN taxes.total_collected IS 'Total amount of tax collected';
COMMENT ON COLUMN taxes.compliance_status IS 'Tax compliance status';
COMMENT ON COLUMN taxes.metadata IS 'Additional metadata in JSON format';
COMMENT ON COLUMN taxes.created_at IS 'Timestamp when the tax was created';
COMMENT ON COLUMN taxes.updated_at IS 'Timestamp when the tax was last updated';

COMMENT ON FUNCTION calculate_tax_amount(UUID, DECIMAL, INTEGER, VARCHAR, VARCHAR) IS 'Calculates tax amount for given base amount and conditions';
COMMENT ON FUNCTION get_applicable_taxes(UUID, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR) IS 'Returns applicable taxes for a specific location and conditions';
COMMENT ON FUNCTION get_store_tax_stats(UUID) IS 'Returns tax statistics for a store';
COMMENT ON FUNCTION update_tax_collection_metrics(UUID, DECIMAL) IS 'Updates tax collection metrics';
COMMENT ON FUNCTION get_tax_compliance_report(UUID, TIMESTAMPTZ, TIMESTAMPTZ) IS 'Returns tax compliance report for a store';