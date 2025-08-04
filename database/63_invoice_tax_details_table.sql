-- =============================================================================
-- Invoice Tax Details Table
-- =============================================================================
-- This file normalizes the tax_details JSONB column from the invoices table
-- into a separate table with proper structure and relationships

-- =============================================================================
-- Invoice Tax Details Table
-- =============================================================================

CREATE TABLE IF NOT EXISTS invoice_tax_details (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Tax identification
    tax_type VARCHAR(50) NOT NULL CHECK (tax_type IN (
        'vat', 'sales_tax', 'gst', 'hst', 'pst', 'excise', 'customs', 'service_tax', 'other'
    )),
    tax_name VARCHAR(100) NOT NULL, -- Display name for tax
    tax_code VARCHAR(50), -- Tax authority code
    tax_authority VARCHAR(100), -- Tax authority name
    
    -- Tax rate information
    tax_rate DECIMAL(8,6) NOT NULL CHECK (tax_rate >= 0), -- Tax rate as decimal (e.g., 0.15 for 15%)
    tax_rate_percentage DECIMAL(5,2) GENERATED ALWAYS AS (tax_rate * 100) STORED,
    
    -- Tax calculation basis
    calculation_basis VARCHAR(50) DEFAULT 'subtotal' CHECK (calculation_basis IN (
        'subtotal', 'total', 'item_price', 'shipping', 'custom'
    )),
    basis_amount DECIMAL(15,4) NOT NULL CHECK (basis_amount >= 0), -- Amount tax is calculated on
    
    -- Tax amounts
    tax_amount DECIMAL(15,4) NOT NULL CHECK (tax_amount >= 0), -- Calculated tax amount
    tax_amount_rounded DECIMAL(15,4), -- Rounded tax amount if different
    rounding_difference DECIMAL(15,4) DEFAULT 0, -- Difference due to rounding
    
    -- Tax inclusion/exclusion
    is_inclusive BOOLEAN DEFAULT FALSE, -- Whether tax is included in price
    is_compound BOOLEAN DEFAULT FALSE, -- Whether this is a compound tax
    compound_order INTEGER, -- Order for compound tax calculation
    
    -- Tax exemption information
    is_exempt BOOLEAN DEFAULT FALSE,
    exemption_reason VARCHAR(255),
    exemption_code VARCHAR(50),
    exemption_certificate VARCHAR(255), -- Exemption certificate number
    exemption_valid_until DATE,
    
    -- Tax jurisdiction
    jurisdiction_level VARCHAR(50) CHECK (jurisdiction_level IN (
        'federal', 'national', 'state', 'province', 'city', 'local', 'regional'
    )),
    jurisdiction_name VARCHAR(100),
    jurisdiction_code VARCHAR(50),
    
    -- Geographic information
    country_code VARCHAR(2), -- ISO 3166-1 alpha-2
    state_province_code VARCHAR(10),
    city_code VARCHAR(20),
    postal_code VARCHAR(20),
    
    -- Tax registration information
    tax_registration_number VARCHAR(100), -- Business tax registration
    tax_registration_type VARCHAR(50), -- Type of registration
    tax_registration_valid BOOLEAN DEFAULT TRUE,
    
    -- Tax period and reporting
    tax_period_start DATE,
    tax_period_end DATE,
    reporting_period VARCHAR(20), -- monthly, quarterly, annually
    tax_return_due_date DATE,
    
    -- Tax compliance
    compliance_status VARCHAR(30) DEFAULT 'compliant' CHECK (compliance_status IN (
        'compliant', 'non_compliant', 'pending', 'under_review', 'disputed'
    )),
    compliance_notes TEXT,
    last_compliance_check TIMESTAMPTZ,
    
    -- Tax calculation details
    calculation_method VARCHAR(50) DEFAULT 'standard' CHECK (calculation_method IN (
        'standard', 'reverse_charge', 'split_payment', 'margin_scheme', 'cash_accounting'
    )),
    calculation_formula TEXT, -- Formula used for calculation
    calculation_notes TEXT,
    
    -- Tax line item details
    applies_to_line_items JSONB DEFAULT '[]', -- Array of line item IDs this tax applies to
    line_item_tax_amounts JSONB DEFAULT '{}', -- Tax amount per line item
    
    -- Tax category and classification
    tax_category VARCHAR(100), -- Product/service tax category
    tax_classification_code VARCHAR(50), -- Standard classification code
    harmonized_code VARCHAR(20), -- Harmonized System code
    
    -- Digital tax information
    is_digital_service BOOLEAN DEFAULT FALSE,
    digital_service_type VARCHAR(50), -- Type of digital service
    place_of_supply VARCHAR(100), -- Place of supply for digital services
    
    -- Reverse charge mechanism
    is_reverse_charge BOOLEAN DEFAULT FALSE,
    reverse_charge_reason VARCHAR(255),
    customer_tax_liable BOOLEAN DEFAULT FALSE, -- Whether customer is liable for tax
    
    -- Tax invoice requirements
    requires_tax_invoice BOOLEAN DEFAULT TRUE,
    tax_invoice_number VARCHAR(100),
    tax_invoice_date DATE,
    tax_invoice_url VARCHAR(500),
    
    -- Withholding tax
    is_withholding_tax BOOLEAN DEFAULT FALSE,
    withholding_rate DECIMAL(5,4),
    withholding_amount DECIMAL(15,4),
    withholding_certificate VARCHAR(255),
    
    -- Tax audit and verification
    is_audited BOOLEAN DEFAULT FALSE,
    audit_status VARCHAR(30) CHECK (audit_status IN (
        'not_audited', 'pending', 'in_progress', 'completed', 'disputed'
    )),
    audited_by VARCHAR(255),
    audit_date DATE,
    audit_notes TEXT,
    
    -- Tax refund information
    is_refundable BOOLEAN DEFAULT TRUE,
    refund_status VARCHAR(30) DEFAULT 'not_refunded' CHECK (refund_status IN (
        'not_refunded', 'pending', 'processing', 'refunded', 'rejected'
    )),
    refunded_amount DECIMAL(15,4) DEFAULT 0,
    refund_date DATE,
    refund_reference VARCHAR(255),
    
    -- External references
    external_tax_id VARCHAR(255), -- External system tax ID
    tax_authority_reference VARCHAR(255), -- Tax authority reference number
    government_portal_id VARCHAR(255), -- Government portal transaction ID
    
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
    CHECK (tax_amount = ROUND(basis_amount * tax_rate, 4) OR calculation_method != 'standard'),
    CHECK (exemption_valid_until IS NULL OR exemption_valid_until >= CURRENT_DATE OR is_exempt = FALSE)
);

-- =============================================================================
-- Invoice Tax Detail History Table
-- =============================================================================
-- Track changes to tax details

CREATE TABLE IF NOT EXISTS invoice_tax_detail_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tax_detail_id UUID NOT NULL REFERENCES invoice_tax_details(id) ON DELETE CASCADE,
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Change tracking
    change_type VARCHAR(20) NOT NULL CHECK (change_type IN ('created', 'updated', 'deleted', 'recalculated')),
    changed_fields JSONB, -- Array of field names that changed
    old_values JSONB, -- Previous values of changed fields
    new_values JSONB, -- New values of changed fields
    
    -- Change context
    change_reason VARCHAR(255),
    change_source VARCHAR(50) DEFAULT 'manual' CHECK (change_source IN (
        'manual', 'api', 'import', 'system', 'recalculation', 'correction', 'audit'
    )),
    
    -- Tax calculation context
    calculation_engine VARCHAR(50), -- Which engine calculated the tax
    calculation_version VARCHAR(20), -- Version of calculation rules
    tax_rules_applied JSONB, -- Which tax rules were applied
    
    -- User context
    changed_by_user_id UUID,
    changed_by_user_type VARCHAR(20) DEFAULT 'admin' CHECK (changed_by_user_type IN (
        'admin', 'system', 'api', 'tax_engine'
    )),
    
    -- Session context
    session_id VARCHAR(255),
    request_id VARCHAR(255),
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- Tax Rules Table
-- =============================================================================
-- Define tax calculation rules for different jurisdictions

CREATE TABLE IF NOT EXISTS invoice_tax_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Rule identification
    rule_name VARCHAR(100) NOT NULL,
    rule_description TEXT,
    rule_code VARCHAR(50), -- Internal rule code
    
    -- Geographic scope
    country_code VARCHAR(2), -- ISO 3166-1 alpha-2
    state_province_code VARCHAR(10),
    city_code VARCHAR(20),
    postal_code_pattern VARCHAR(50), -- Regex pattern for postal codes
    
    -- Tax type and configuration
    tax_type VARCHAR(50) NOT NULL,
    tax_name VARCHAR(100) NOT NULL,
    tax_rate DECIMAL(8,6) NOT NULL CHECK (tax_rate >= 0),
    
    -- Rule conditions
    applies_to_product_types TEXT[] DEFAULT ARRAY['all'], -- Product types this rule applies to
    applies_to_customer_types TEXT[] DEFAULT ARRAY['all'], -- Customer types this rule applies to
    minimum_amount DECIMAL(15,4), -- Minimum amount for tax to apply
    maximum_amount DECIMAL(15,4), -- Maximum amount for tax calculation
    
    -- Date range
    effective_from DATE NOT NULL DEFAULT CURRENT_DATE,
    effective_until DATE,
    
    -- Rule priority and application
    priority INTEGER DEFAULT 100, -- Higher number = higher priority
    is_active BOOLEAN DEFAULT TRUE,
    is_default BOOLEAN DEFAULT FALSE, -- Default rule for jurisdiction
    
    -- Calculation settings
    calculation_method VARCHAR(50) DEFAULT 'standard',
    is_inclusive BOOLEAN DEFAULT FALSE,
    is_compound BOOLEAN DEFAULT FALSE,
    compound_order INTEGER,
    rounding_method VARCHAR(20) DEFAULT 'round' CHECK (rounding_method IN (
        'round', 'floor', 'ceiling', 'truncate'
    )),
    rounding_precision INTEGER DEFAULT 2,
    
    -- Exemption rules
    exemption_conditions JSONB DEFAULT '{}', -- Conditions for exemption
    exemption_codes TEXT[], -- Valid exemption codes
    
    -- Rule performance tracking
    usage_count INTEGER DEFAULT 0,
    last_used_at TIMESTAMPTZ,
    calculation_errors INTEGER DEFAULT 0,
    
    -- External references
    tax_authority_rule_id VARCHAR(255), -- Tax authority rule reference
    legal_reference VARCHAR(500), -- Legal reference for the rule
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    UNIQUE(store_id, rule_code),
    CHECK (effective_until IS NULL OR effective_until >= effective_from),
    CHECK (maximum_amount IS NULL OR minimum_amount IS NULL OR maximum_amount >= minimum_amount)
);

-- =============================================================================
-- Tax Rate History Table
-- =============================================================================
-- Track historical tax rates for compliance and reporting

CREATE TABLE IF NOT EXISTS invoice_tax_rate_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Tax identification
    tax_type VARCHAR(50) NOT NULL,
    tax_name VARCHAR(100) NOT NULL,
    jurisdiction_code VARCHAR(50),
    
    -- Rate information
    old_rate DECIMAL(8,6),
    new_rate DECIMAL(8,6) NOT NULL,
    rate_change_percentage DECIMAL(8,4), -- Percentage change
    
    -- Effective dates
    effective_from DATE NOT NULL,
    effective_until DATE,
    announced_date DATE, -- When the change was announced
    
    -- Change context
    change_reason VARCHAR(255),
    change_source VARCHAR(100), -- Government announcement, law change, etc.
    legal_reference VARCHAR(500),
    
    -- Impact assessment
    estimated_impact_amount DECIMAL(15,4), -- Estimated financial impact
    affected_invoices_count INTEGER, -- Number of invoices affected
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- Indexes
-- =============================================================================

-- Primary indexes for invoice_tax_details
CREATE INDEX IF NOT EXISTS idx_invoice_tax_details_invoice_id ON invoice_tax_details(invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoice_tax_details_store_id ON invoice_tax_details(store_id);
CREATE INDEX IF NOT EXISTS idx_invoice_tax_details_tax_type ON invoice_tax_details(tax_type);
CREATE INDEX IF NOT EXISTS idx_invoice_tax_details_tax_code ON invoice_tax_details(tax_code);
CREATE INDEX IF NOT EXISTS idx_invoice_tax_details_tax_rate ON invoice_tax_details(tax_rate);
CREATE INDEX IF NOT EXISTS idx_invoice_tax_details_jurisdiction_level ON invoice_tax_details(jurisdiction_level);
CREATE INDEX IF NOT EXISTS idx_invoice_tax_details_country_code ON invoice_tax_details(country_code);
CREATE INDEX IF NOT EXISTS idx_invoice_tax_details_is_exempt ON invoice_tax_details(is_exempt);
CREATE INDEX IF NOT EXISTS idx_invoice_tax_details_is_inclusive ON invoice_tax_details(is_inclusive);
CREATE INDEX IF NOT EXISTS idx_invoice_tax_details_compliance_status ON invoice_tax_details(compliance_status);
CREATE INDEX IF NOT EXISTS idx_invoice_tax_details_calculation_method ON invoice_tax_details(calculation_method);
CREATE INDEX IF NOT EXISTS idx_invoice_tax_details_is_reverse_charge ON invoice_tax_details(is_reverse_charge);
CREATE INDEX IF NOT EXISTS idx_invoice_tax_details_audit_status ON invoice_tax_details(audit_status);
CREATE INDEX IF NOT EXISTS idx_invoice_tax_details_refund_status ON invoice_tax_details(refund_status);
CREATE INDEX IF NOT EXISTS idx_invoice_tax_details_sync_status ON invoice_tax_details(sync_status);
CREATE INDEX IF NOT EXISTS idx_invoice_tax_details_created_at ON invoice_tax_details(created_at DESC);

-- Composite indexes
CREATE INDEX IF NOT EXISTS idx_invoice_tax_details_store_type_rate ON invoice_tax_details(store_id, tax_type, tax_rate);
CREATE INDEX IF NOT EXISTS idx_invoice_tax_details_jurisdiction_type ON invoice_tax_details(jurisdiction_code, tax_type);
CREATE INDEX IF NOT EXISTS idx_invoice_tax_details_country_state_type ON invoice_tax_details(country_code, state_province_code, tax_type);
CREATE INDEX IF NOT EXISTS idx_invoice_tax_details_period_compliance ON invoice_tax_details(tax_period_start, tax_period_end, compliance_status);

-- JSONB indexes
CREATE INDEX IF NOT EXISTS idx_invoice_tax_details_line_items ON invoice_tax_details USING gin(applies_to_line_items);
CREATE INDEX IF NOT EXISTS idx_invoice_tax_details_line_item_amounts ON invoice_tax_details USING gin(line_item_tax_amounts);
CREATE INDEX IF NOT EXISTS idx_invoice_tax_details_custom_fields ON invoice_tax_details USING gin(custom_fields);
CREATE INDEX IF NOT EXISTS idx_invoice_tax_details_sync_errors ON invoice_tax_details USING gin(sync_errors);

-- History table indexes
CREATE INDEX IF NOT EXISTS idx_invoice_tax_detail_history_tax_detail_id ON invoice_tax_detail_history(tax_detail_id);
CREATE INDEX IF NOT EXISTS idx_invoice_tax_detail_history_invoice_id ON invoice_tax_detail_history(invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoice_tax_detail_history_store_id ON invoice_tax_detail_history(store_id);
CREATE INDEX IF NOT EXISTS idx_invoice_tax_detail_history_change_type ON invoice_tax_detail_history(change_type);
CREATE INDEX IF NOT EXISTS idx_invoice_tax_detail_history_change_source ON invoice_tax_detail_history(change_source);
CREATE INDEX IF NOT EXISTS idx_invoice_tax_detail_history_created_at ON invoice_tax_detail_history(created_at DESC);

-- Tax rules indexes
CREATE INDEX IF NOT EXISTS idx_invoice_tax_rules_store_id ON invoice_tax_rules(store_id);
CREATE INDEX IF NOT EXISTS idx_invoice_tax_rules_country_code ON invoice_tax_rules(country_code);
CREATE INDEX IF NOT EXISTS idx_invoice_tax_rules_tax_type ON invoice_tax_rules(tax_type);
CREATE INDEX IF NOT EXISTS idx_invoice_tax_rules_is_active ON invoice_tax_rules(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_invoice_tax_rules_effective_dates ON invoice_tax_rules(effective_from, effective_until);
CREATE INDEX IF NOT EXISTS idx_invoice_tax_rules_priority ON invoice_tax_rules(priority DESC);

-- Tax rate history indexes
CREATE INDEX IF NOT EXISTS idx_invoice_tax_rate_history_store_id ON invoice_tax_rate_history(store_id);
CREATE INDEX IF NOT EXISTS idx_invoice_tax_rate_history_tax_type ON invoice_tax_rate_history(tax_type);
CREATE INDEX IF NOT EXISTS idx_invoice_tax_rate_history_jurisdiction ON invoice_tax_rate_history(jurisdiction_code);
CREATE INDEX IF NOT EXISTS idx_invoice_tax_rate_history_effective_dates ON invoice_tax_rate_history(effective_from, effective_until);
CREATE INDEX IF NOT EXISTS idx_invoice_tax_rate_history_created_at ON invoice_tax_rate_history(created_at DESC);

-- =============================================================================
-- Triggers
-- =============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_invoice_tax_details_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_invoice_tax_details_updated_at
    BEFORE UPDATE ON invoice_tax_details
    FOR EACH ROW
    EXECUTE FUNCTION update_invoice_tax_details_updated_at();

CREATE TRIGGER trigger_update_invoice_tax_rules_updated_at
    BEFORE UPDATE ON invoice_tax_rules
    FOR EACH ROW
    EXECUTE FUNCTION update_invoice_tax_details_updated_at();

-- Track tax detail changes in history
CREATE OR REPLACE FUNCTION track_invoice_tax_detail_changes()
RETURNS TRIGGER AS $$
DECLARE
    v_changed_fields TEXT[];
    v_old_values JSONB;
    v_new_values JSONB;
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO invoice_tax_detail_history (
            tax_detail_id, invoice_id, store_id, change_type,
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
            AND old_record.key NOT IN ('updated_at', 'last_sync_at', 'last_compliance_check')
        ) changes;
        
        IF array_length(v_changed_fields, 1) > 0 THEN
            INSERT INTO invoice_tax_detail_history (
                tax_detail_id, invoice_id, store_id, change_type,
                changed_fields, old_values, new_values, created_at
            ) VALUES (
                NEW.id, NEW.invoice_id, NEW.store_id, 'updated',
                v_changed_fields, v_old_values, v_new_values, CURRENT_TIMESTAMP
            );
        END IF;
        
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO invoice_tax_detail_history (
            tax_detail_id, invoice_id, store_id, change_type,
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

CREATE TRIGGER trigger_track_invoice_tax_detail_changes
    AFTER INSERT OR UPDATE OR DELETE ON invoice_tax_details
    FOR EACH ROW
    EXECUTE FUNCTION track_invoice_tax_detail_changes();

-- Validate tax calculations
CREATE OR REPLACE FUNCTION validate_tax_calculation()
RETURNS TRIGGER AS $$
BEGIN
    -- Validate tax amount calculation for standard method
    IF NEW.calculation_method = 'standard' THEN
        IF ABS(NEW.tax_amount - ROUND(NEW.basis_amount * NEW.tax_rate, 4)) > 0.01 THEN
            RAISE EXCEPTION 'Tax amount (%) does not match calculated amount (%) for standard calculation', 
                NEW.tax_amount, ROUND(NEW.basis_amount * NEW.tax_rate, 4);
        END IF;
    END IF;
    
    -- Validate exemption logic
    IF NEW.is_exempt = TRUE AND NEW.tax_amount != 0 THEN
        RAISE EXCEPTION 'Tax amount must be zero for exempt transactions';
    END IF;
    
    -- Validate compound tax order
    IF NEW.is_compound = TRUE AND NEW.compound_order IS NULL THEN
        RAISE EXCEPTION 'Compound order must be specified for compound taxes';
    END IF;
    
    -- Validate refund amounts
    IF NEW.refunded_amount > NEW.tax_amount THEN
        RAISE EXCEPTION 'Refunded amount (%) cannot exceed tax amount (%)', 
            NEW.refunded_amount, NEW.tax_amount;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validate_tax_calculation
    BEFORE INSERT OR UPDATE ON invoice_tax_details
    FOR EACH ROW
    EXECUTE FUNCTION validate_tax_calculation();

-- Update tax rule usage statistics
CREATE OR REPLACE FUNCTION update_tax_rule_usage()
RETURNS TRIGGER AS $$
BEGIN
    -- Update usage statistics for applicable tax rules
    UPDATE invoice_tax_rules 
    SET usage_count = usage_count + 1,
        last_used_at = CURRENT_TIMESTAMP
    WHERE store_id = NEW.store_id
    AND tax_type = NEW.tax_type
    AND (country_code IS NULL OR country_code = NEW.country_code)
    AND (state_province_code IS NULL OR state_province_code = NEW.state_province_code)
    AND is_active = TRUE
    AND effective_from <= CURRENT_DATE
    AND (effective_until IS NULL OR effective_until >= CURRENT_DATE);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_tax_rule_usage
    AFTER INSERT ON invoice_tax_details
    FOR EACH ROW
    EXECUTE FUNCTION update_tax_rule_usage();

-- =============================================================================
-- Helper Functions
-- =============================================================================

/**
 * Get invoice tax details with breakdown
 * @param p_invoice_id UUID - Invoice ID
 * @return JSONB - Complete tax details
 */
CREATE OR REPLACE FUNCTION get_invoice_tax_details(
    p_invoice_id UUID
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'tax_details', jsonb_agg(
            jsonb_build_object(
                'id', itd.id,
                'tax_type', itd.tax_type,
                'tax_name', itd.tax_name,
                'tax_rate', itd.tax_rate,
                'tax_rate_percentage', itd.tax_rate_percentage,
                'basis_amount', itd.basis_amount,
                'tax_amount', itd.tax_amount,
                'is_inclusive', itd.is_inclusive,
                'is_exempt', itd.is_exempt,
                'jurisdiction_name', itd.jurisdiction_name,
                'calculation_method', itd.calculation_method,
                'compliance_status', itd.compliance_status
            )
            ORDER BY itd.compound_order NULLS LAST, itd.tax_type
        ),
        'tax_summary', jsonb_build_object(
            'total_tax_amount', COALESCE(SUM(itd.tax_amount), 0),
            'total_basis_amount', COALESCE(SUM(itd.basis_amount), 0),
            'average_tax_rate', CASE 
                WHEN SUM(itd.basis_amount) > 0 THEN SUM(itd.tax_amount) / SUM(itd.basis_amount)
                ELSE 0 
            END,
            'tax_count', COUNT(*),
            'exempt_count', COUNT(*) FILTER (WHERE itd.is_exempt = TRUE),
            'inclusive_count', COUNT(*) FILTER (WHERE itd.is_inclusive = TRUE)
        )
    ) INTO result
    FROM invoice_tax_details itd
    WHERE itd.invoice_id = p_invoice_id;
    
    RETURN COALESCE(result, '{"tax_details": [], "tax_summary": {"total_tax_amount": 0}}'::jsonb);
END;
$$ LANGUAGE plpgsql;

/**
 * Calculate tax for invoice based on rules
 * @param p_invoice_id UUID - Invoice ID
 * @param p_recalculate BOOLEAN - Whether to recalculate existing taxes
 * @return JSONB - Calculation results
 */
CREATE OR REPLACE FUNCTION calculate_invoice_tax(
    p_invoice_id UUID,
    p_recalculate BOOLEAN DEFAULT FALSE
)
RETURNS JSONB AS $$
DECLARE
    v_invoice RECORD;
    v_rule RECORD;
    v_tax_amount DECIMAL(15,4);
    v_basis_amount DECIMAL(15,4);
    result JSONB;
    v_total_tax DECIMAL(15,4) := 0;
BEGIN
    -- Get invoice details
    SELECT * INTO v_invoice
    FROM invoices
    WHERE id = p_invoice_id;
    
    IF NOT FOUND THEN
        RETURN '{"error": "Invoice not found"}'::jsonb;
    END IF;
    
    -- Clear existing tax details if recalculating
    IF p_recalculate THEN
        DELETE FROM invoice_tax_details WHERE invoice_id = p_invoice_id;
    END IF;
    
    -- Get applicable tax rules
    FOR v_rule IN 
        SELECT * FROM invoice_tax_rules
        WHERE store_id = v_invoice.store_id
        AND is_active = TRUE
        AND effective_from <= CURRENT_DATE
        AND (effective_until IS NULL OR effective_until >= CURRENT_DATE)
        AND (minimum_amount IS NULL OR v_invoice.subtotal >= minimum_amount)
        AND (maximum_amount IS NULL OR v_invoice.subtotal <= maximum_amount)
        ORDER BY priority DESC, tax_type
    LOOP
        -- Calculate basis amount based on calculation method
        CASE v_rule.calculation_method
            WHEN 'standard' THEN
                v_basis_amount := v_invoice.subtotal;
            ELSE
                v_basis_amount := v_invoice.subtotal; -- Default to subtotal
        END CASE;
        
        -- Calculate tax amount
        v_tax_amount := ROUND(v_basis_amount * v_rule.tax_rate, 4);
        v_total_tax := v_total_tax + v_tax_amount;
        
        -- Insert tax detail
        INSERT INTO invoice_tax_details (
            invoice_id, store_id, tax_type, tax_name, tax_code,
            tax_rate, basis_amount, tax_amount,
            calculation_method, is_inclusive, is_compound,
            jurisdiction_name, country_code,
            data_source, created_at
        ) VALUES (
            p_invoice_id, v_invoice.store_id, v_rule.tax_type, v_rule.tax_name, v_rule.rule_code,
            v_rule.tax_rate, v_basis_amount, v_tax_amount,
            v_rule.calculation_method, v_rule.is_inclusive, v_rule.is_compound,
            'Auto-calculated', v_rule.country_code,
            'calculation', CURRENT_TIMESTAMP
        );
    END LOOP;
    
    result := jsonb_build_object(
        'invoice_id', p_invoice_id,
        'total_tax_calculated', v_total_tax,
        'rules_applied', (
            SELECT COUNT(*) FROM invoice_tax_details 
            WHERE invoice_id = p_invoice_id 
            AND data_source = 'calculation'
        ),
        'calculation_timestamp', CURRENT_TIMESTAMP
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

/**
 * Get tax compliance report for store
 * @param p_store_id UUID - Store ID
 * @param p_start_date DATE - Start date
 * @param p_end_date DATE - End date
 * @return JSONB - Compliance report
 */
CREATE OR REPLACE FUNCTION get_tax_compliance_report(
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
        'tax_summary', jsonb_build_object(
            'total_tax_collected', COALESCE(SUM(itd.tax_amount), 0),
            'total_basis_amount', COALESCE(SUM(itd.basis_amount), 0),
            'invoice_count', COUNT(DISTINCT itd.invoice_id),
            'tax_detail_count', COUNT(*)
        ),
        'tax_by_type', (
            SELECT jsonb_object_agg(tax_type, type_data)
            FROM (
                SELECT 
                    itd.tax_type,
                    jsonb_build_object(
                        'total_amount', SUM(itd.tax_amount),
                        'total_basis', SUM(itd.basis_amount),
                        'average_rate', AVG(itd.tax_rate),
                        'transaction_count', COUNT(*)
                    ) as type_data
                FROM invoice_tax_details itd
                JOIN invoices i ON i.id = itd.invoice_id
                WHERE itd.store_id = p_store_id
                AND (p_start_date IS NULL OR i.invoice_date >= p_start_date)
                AND (p_end_date IS NULL OR i.invoice_date <= p_end_date)
                GROUP BY itd.tax_type
            ) tax_types
        ),
        'compliance_status', jsonb_build_object(
            'compliant', COUNT(*) FILTER (WHERE itd.compliance_status = 'compliant'),
            'non_compliant', COUNT(*) FILTER (WHERE itd.compliance_status = 'non_compliant'),
            'pending', COUNT(*) FILTER (WHERE itd.compliance_status = 'pending'),
            'under_review', COUNT(*) FILTER (WHERE itd.compliance_status = 'under_review')
        ),
        'exemptions', jsonb_build_object(
            'exempt_transactions', COUNT(*) FILTER (WHERE itd.is_exempt = TRUE),
            'exempt_amount', COALESCE(SUM(itd.basis_amount) FILTER (WHERE itd.is_exempt = TRUE), 0)
        ),
        'refunds', jsonb_build_object(
            'refunded_tax', COALESCE(SUM(itd.refunded_amount), 0),
            'refund_count', COUNT(*) FILTER (WHERE itd.refunded_amount > 0)
        )
    ) INTO result
    FROM invoice_tax_details itd
    JOIN invoices i ON i.id = itd.invoice_id
    WHERE itd.store_id = p_store_id
    AND (p_start_date IS NULL OR i.invoice_date >= p_start_date)
    AND (p_end_date IS NULL OR i.invoice_date <= p_end_date);
    
    RETURN COALESCE(result, '{"error": "No tax data found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Comments
-- =============================================================================

COMMENT ON TABLE invoice_tax_details IS 'Normalized tax details for invoices with comprehensive tax information';
COMMENT ON TABLE invoice_tax_detail_history IS 'Track changes to invoice tax details';
COMMENT ON TABLE invoice_tax_rules IS 'Tax calculation rules for different jurisdictions';
COMMENT ON TABLE invoice_tax_rate_history IS 'Historical tax rates for compliance and reporting';

COMMENT ON COLUMN invoice_tax_details.tax_rate IS 'Tax rate as decimal (e.g., 0.15 for 15%)';
COMMENT ON COLUMN invoice_tax_details.tax_rate_percentage IS 'Tax rate as percentage (generated from tax_rate)';
COMMENT ON COLUMN invoice_tax_details.basis_amount IS 'Amount on which tax is calculated';
COMMENT ON COLUMN invoice_tax_details.is_inclusive IS 'Whether tax is included in the price';
COMMENT ON COLUMN invoice_tax_details.is_compound IS 'Whether this is a compound tax (tax on tax)';
COMMENT ON COLUMN invoice_tax_details.is_reverse_charge IS 'Whether reverse charge mechanism applies';

COMMENT ON FUNCTION get_invoice_tax_details(UUID) IS 'Get complete tax details and summary for invoice';
COMMENT ON FUNCTION calculate_invoice_tax(UUID, BOOLEAN) IS 'Calculate tax for invoice based on applicable rules';
COMMENT ON FUNCTION get_tax_compliance_report(UUID, DATE, DATE) IS 'Generate tax compliance report for store';