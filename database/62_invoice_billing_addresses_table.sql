-- =============================================================================
-- Invoice Billing Addresses Table
-- =============================================================================
-- This file normalizes the billing_address JSONB column from the invoices table
-- into a separate table with proper structure and relationships

-- =============================================================================
-- Invoice Billing Addresses Table
-- =============================================================================

CREATE TABLE IF NOT EXISTS invoice_billing_addresses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Address identification
    address_type VARCHAR(50) DEFAULT 'billing' CHECK (address_type IN (
        'billing', 'invoice', 'company', 'registered'
    )),
    address_label VARCHAR(100), -- Custom label for address
    
    -- Basic address information
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    full_name VARCHAR(255),
    company_name VARCHAR(255),
    
    -- Address lines
    address_line_1 VARCHAR(255) NOT NULL,
    address_line_2 VARCHAR(255),
    address_line_3 VARCHAR(255),
    
    -- Geographic information
    city VARCHAR(100) NOT NULL,
    state_province VARCHAR(100),
    postal_code VARCHAR(20),
    country_code VARCHAR(2) NOT NULL, -- ISO 3166-1 alpha-2
    country_name VARCHAR(100),
    
    -- Regional information (for Middle East)
    region VARCHAR(100), -- Region within country
    district VARCHAR(100), -- District or area
    neighborhood VARCHAR(100), -- Neighborhood or locality
    
    -- Contact information
    phone VARCHAR(50),
    mobile VARCHAR(50),
    email VARCHAR(255),
    fax VARCHAR(50),
    
    -- Business information
    tax_number VARCHAR(100), -- VAT/Tax registration number
    commercial_registration VARCHAR(100), -- Commercial registration number
    business_license VARCHAR(100), -- Business license number
    
    -- Address validation and quality
    is_validated BOOLEAN DEFAULT FALSE,
    validation_status VARCHAR(30) DEFAULT 'pending' CHECK (validation_status IN (
        'pending', 'validating', 'valid', 'invalid', 'partial', 'failed'
    )),
    validation_score DECIMAL(3,2) CHECK (validation_score >= 0 AND validation_score <= 1),
    validation_errors JSONB DEFAULT '[]',
    validated_at TIMESTAMPTZ,
    
    -- Geocoding information
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    geocoding_accuracy VARCHAR(20), -- street, city, region, country
    geocoded_at TIMESTAMPTZ,
    
    -- Address formatting
    formatted_address TEXT, -- Complete formatted address
    address_format VARCHAR(20) DEFAULT 'local', -- local, international, postal
    
    -- Localization
    language_code VARCHAR(5) DEFAULT 'ar',
    locale VARCHAR(10) DEFAULT 'ar_SA',
    address_line_1_local VARCHAR(255), -- Address in local language
    address_line_2_local VARCHAR(255),
    city_local VARCHAR(100),
    state_province_local VARCHAR(100),
    
    -- Address usage and preferences
    is_primary BOOLEAN DEFAULT TRUE,
    is_default BOOLEAN DEFAULT FALSE,
    usage_frequency INTEGER DEFAULT 0,
    last_used_at TIMESTAMPTZ,
    
    -- Address verification
    is_verified BOOLEAN DEFAULT FALSE,
    verification_method VARCHAR(50), -- manual, api, document, phone
    verified_by_user_id UUID,
    verified_at TIMESTAMPTZ,
    verification_notes TEXT,
    
    -- Delivery and logistics
    is_deliverable BOOLEAN DEFAULT TRUE,
    delivery_instructions TEXT,
    access_code VARCHAR(50), -- Building or gate access code
    landmark VARCHAR(255), -- Nearby landmark
    delivery_zone VARCHAR(50), -- Delivery zone or area code
    
    -- Address source and history
    source VARCHAR(50) DEFAULT 'manual' CHECK (source IN (
        'manual', 'import', 'api', 'customer', 'admin', 'system', 'migration'
    )),
    source_reference VARCHAR(255), -- Reference to source system
    import_batch_id UUID, -- Batch ID for imported addresses
    
    -- Data quality and confidence
    data_quality_score DECIMAL(3,2) CHECK (data_quality_score >= 0 AND data_quality_score <= 1),
    confidence_level VARCHAR(20) DEFAULT 'medium' CHECK (confidence_level IN (
        'very_low', 'low', 'medium', 'high', 'very_high'
    )),
    completeness_score DECIMAL(3,2) CHECK (completeness_score >= 0 AND completeness_score <= 1),
    
    -- External references
    external_address_id VARCHAR(255), -- External system address ID
    google_place_id VARCHAR(255), -- Google Places API place ID
    postal_service_id VARCHAR(255), -- National postal service ID
    
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
    UNIQUE(invoice_id, address_type),
    CHECK (latitude IS NULL OR (latitude >= -90 AND latitude <= 90)),
    CHECK (longitude IS NULL OR (longitude >= -180 AND longitude <= 180))
);

-- =============================================================================
-- Invoice Billing Address History Table
-- =============================================================================
-- Track changes to billing addresses

CREATE TABLE IF NOT EXISTS invoice_billing_address_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    address_id UUID NOT NULL REFERENCES invoice_billing_addresses(id) ON DELETE CASCADE,
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Change tracking
    change_type VARCHAR(20) NOT NULL CHECK (change_type IN ('created', 'updated', 'deleted', 'merged')),
    changed_fields JSONB, -- Array of field names that changed
    old_values JSONB, -- Previous values of changed fields
    new_values JSONB, -- New values of changed fields
    
    -- Change context
    change_reason VARCHAR(255),
    change_source VARCHAR(50) DEFAULT 'manual' CHECK (change_source IN (
        'manual', 'api', 'import', 'system', 'migration', 'validation', 'correction'
    )),
    
    -- User context
    changed_by_user_id UUID,
    changed_by_user_type VARCHAR(20) DEFAULT 'admin' CHECK (changed_by_user_type IN (
        'admin', 'customer', 'system', 'api'
    )),
    
    -- Session and request context
    session_id VARCHAR(255),
    request_id VARCHAR(255),
    ip_address INET,
    user_agent TEXT,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- Invoice Address Validation Rules Table
-- =============================================================================
-- Define validation rules for different countries/regions

CREATE TABLE IF NOT EXISTS invoice_address_validation_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Rule identification
    rule_name VARCHAR(100) NOT NULL,
    rule_description TEXT,
    
    -- Geographic scope
    country_code VARCHAR(2), -- ISO 3166-1 alpha-2
    state_province VARCHAR(100),
    region VARCHAR(100),
    
    -- Rule configuration
    rule_type VARCHAR(50) NOT NULL CHECK (rule_type IN (
        'required_fields', 'format_validation', 'postal_code_format', 
        'phone_format', 'business_rules', 'custom_validation'
    )),
    rule_config JSONB NOT NULL, -- Rule configuration
    
    -- Rule properties
    is_active BOOLEAN DEFAULT TRUE,
    priority INTEGER DEFAULT 100, -- Higher number = higher priority
    error_message TEXT, -- Custom error message
    warning_message TEXT, -- Custom warning message
    
    -- Rule application
    applies_to_address_types TEXT[] DEFAULT ARRAY['billing'], -- Which address types this rule applies to
    applies_to_invoice_types TEXT[] DEFAULT ARRAY['sale'], -- Which invoice types this rule applies to
    
    -- Rule performance
    usage_count INTEGER DEFAULT 0,
    success_count INTEGER DEFAULT 0,
    failure_count INTEGER DEFAULT 0,
    last_used_at TIMESTAMPTZ,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    UNIQUE(store_id, rule_name, country_code)
);

-- =============================================================================
-- Indexes
-- =============================================================================

-- Primary indexes for invoice_billing_addresses
CREATE INDEX IF NOT EXISTS idx_invoice_billing_addresses_invoice_id ON invoice_billing_addresses(invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoice_billing_addresses_store_id ON invoice_billing_addresses(store_id);
CREATE INDEX IF NOT EXISTS idx_invoice_billing_addresses_address_type ON invoice_billing_addresses(address_type);
CREATE INDEX IF NOT EXISTS idx_invoice_billing_addresses_country_code ON invoice_billing_addresses(country_code);
CREATE INDEX IF NOT EXISTS idx_invoice_billing_addresses_postal_code ON invoice_billing_addresses(postal_code);
CREATE INDEX IF NOT EXISTS idx_invoice_billing_addresses_city ON invoice_billing_addresses(city);
CREATE INDEX IF NOT EXISTS idx_invoice_billing_addresses_state_province ON invoice_billing_addresses(state_province);
CREATE INDEX IF NOT EXISTS idx_invoice_billing_addresses_phone ON invoice_billing_addresses(phone);
CREATE INDEX IF NOT EXISTS idx_invoice_billing_addresses_email ON invoice_billing_addresses(email);
CREATE INDEX IF NOT EXISTS idx_invoice_billing_addresses_tax_number ON invoice_billing_addresses(tax_number);
CREATE INDEX IF NOT EXISTS idx_invoice_billing_addresses_is_validated ON invoice_billing_addresses(is_validated);
CREATE INDEX IF NOT EXISTS idx_invoice_billing_addresses_validation_status ON invoice_billing_addresses(validation_status);
CREATE INDEX IF NOT EXISTS idx_invoice_billing_addresses_is_primary ON invoice_billing_addresses(is_primary) WHERE is_primary = TRUE;
CREATE INDEX IF NOT EXISTS idx_invoice_billing_addresses_is_verified ON invoice_billing_addresses(is_verified);
CREATE INDEX IF NOT EXISTS idx_invoice_billing_addresses_source ON invoice_billing_addresses(source);
CREATE INDEX IF NOT EXISTS idx_invoice_billing_addresses_sync_status ON invoice_billing_addresses(sync_status);
CREATE INDEX IF NOT EXISTS idx_invoice_billing_addresses_created_at ON invoice_billing_addresses(created_at DESC);

-- Geographic indexes
CREATE INDEX IF NOT EXISTS idx_invoice_billing_addresses_location ON invoice_billing_addresses(latitude, longitude) WHERE latitude IS NOT NULL AND longitude IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_invoice_billing_addresses_country_city ON invoice_billing_addresses(country_code, city);
CREATE INDEX IF NOT EXISTS idx_invoice_billing_addresses_region_district ON invoice_billing_addresses(region, district);

-- JSONB indexes
CREATE INDEX IF NOT EXISTS idx_invoice_billing_addresses_validation_errors ON invoice_billing_addresses USING gin(validation_errors);
CREATE INDEX IF NOT EXISTS idx_invoice_billing_addresses_custom_fields ON invoice_billing_addresses USING gin(custom_fields);
CREATE INDEX IF NOT EXISTS idx_invoice_billing_addresses_sync_errors ON invoice_billing_addresses USING gin(sync_errors);

-- Text search indexes
CREATE INDEX IF NOT EXISTS idx_invoice_billing_addresses_full_name_trgm ON invoice_billing_addresses USING gin(full_name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_invoice_billing_addresses_company_name_trgm ON invoice_billing_addresses USING gin(company_name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_invoice_billing_addresses_formatted_address_trgm ON invoice_billing_addresses USING gin(formatted_address gin_trgm_ops);

-- History table indexes
CREATE INDEX IF NOT EXISTS idx_invoice_billing_address_history_address_id ON invoice_billing_address_history(address_id);
CREATE INDEX IF NOT EXISTS idx_invoice_billing_address_history_invoice_id ON invoice_billing_address_history(invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoice_billing_address_history_store_id ON invoice_billing_address_history(store_id);
CREATE INDEX IF NOT EXISTS idx_invoice_billing_address_history_change_type ON invoice_billing_address_history(change_type);
CREATE INDEX IF NOT EXISTS idx_invoice_billing_address_history_changed_by ON invoice_billing_address_history(changed_by_user_id);
CREATE INDEX IF NOT EXISTS idx_invoice_billing_address_history_created_at ON invoice_billing_address_history(created_at DESC);

-- Validation rules indexes
CREATE INDEX IF NOT EXISTS idx_invoice_address_validation_rules_store_id ON invoice_address_validation_rules(store_id);
CREATE INDEX IF NOT EXISTS idx_invoice_address_validation_rules_country_code ON invoice_address_validation_rules(country_code);
CREATE INDEX IF NOT EXISTS idx_invoice_address_validation_rules_rule_type ON invoice_address_validation_rules(rule_type);
CREATE INDEX IF NOT EXISTS idx_invoice_address_validation_rules_is_active ON invoice_address_validation_rules(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_invoice_address_validation_rules_priority ON invoice_address_validation_rules(priority DESC);

-- =============================================================================
-- Triggers
-- =============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_invoice_billing_addresses_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_invoice_billing_addresses_updated_at
    BEFORE UPDATE ON invoice_billing_addresses
    FOR EACH ROW
    EXECUTE FUNCTION update_invoice_billing_addresses_updated_at();

CREATE TRIGGER trigger_update_invoice_address_validation_rules_updated_at
    BEFORE UPDATE ON invoice_address_validation_rules
    FOR EACH ROW
    EXECUTE FUNCTION update_invoice_billing_addresses_updated_at();

-- Track address changes in history
CREATE OR REPLACE FUNCTION track_invoice_billing_address_changes()
RETURNS TRIGGER AS $$
DECLARE
    v_changed_fields TEXT[];
    v_old_values JSONB;
    v_new_values JSONB;
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO invoice_billing_address_history (
            address_id, invoice_id, store_id, change_type,
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
            AND old_record.key NOT IN ('updated_at', 'last_sync_at')
        ) changes;
        
        IF array_length(v_changed_fields, 1) > 0 THEN
            INSERT INTO invoice_billing_address_history (
                address_id, invoice_id, store_id, change_type,
                changed_fields, old_values, new_values, created_at
            ) VALUES (
                NEW.id, NEW.invoice_id, NEW.store_id, 'updated',
                v_changed_fields, v_old_values, v_new_values, CURRENT_TIMESTAMP
            );
        END IF;
        
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO invoice_billing_address_history (
            address_id, invoice_id, store_id, change_type,
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

CREATE TRIGGER trigger_track_invoice_billing_address_changes
    AFTER INSERT OR UPDATE OR DELETE ON invoice_billing_addresses
    FOR EACH ROW
    EXECUTE FUNCTION track_invoice_billing_address_changes();

-- Auto-format address when data changes
CREATE OR REPLACE FUNCTION format_invoice_billing_address()
RETURNS TRIGGER AS $$
BEGIN
    -- Generate full name if not provided
    IF NEW.full_name IS NULL OR NEW.full_name = '' THEN
        NEW.full_name = TRIM(COALESCE(NEW.first_name, '') || ' ' || COALESCE(NEW.last_name, ''));
    END IF;
    
    -- Generate formatted address
    NEW.formatted_address = TRIM(
        COALESCE(NEW.address_line_1, '') ||
        CASE WHEN NEW.address_line_2 IS NOT NULL THEN ', ' || NEW.address_line_2 ELSE '' END ||
        CASE WHEN NEW.address_line_3 IS NOT NULL THEN ', ' || NEW.address_line_3 ELSE '' END ||
        CASE WHEN NEW.city IS NOT NULL THEN ', ' || NEW.city ELSE '' END ||
        CASE WHEN NEW.state_province IS NOT NULL THEN ', ' || NEW.state_province ELSE '' END ||
        CASE WHEN NEW.postal_code IS NOT NULL THEN ' ' || NEW.postal_code ELSE '' END ||
        CASE WHEN NEW.country_name IS NOT NULL THEN ', ' || NEW.country_name ELSE '' END
    );
    
    -- Calculate completeness score
    NEW.completeness_score = (
        CASE WHEN NEW.address_line_1 IS NOT NULL THEN 0.3 ELSE 0 END +
        CASE WHEN NEW.city IS NOT NULL THEN 0.2 ELSE 0 END +
        CASE WHEN NEW.postal_code IS NOT NULL THEN 0.15 ELSE 0 END +
        CASE WHEN NEW.country_code IS NOT NULL THEN 0.15 ELSE 0 END +
        CASE WHEN NEW.phone IS NOT NULL OR NEW.mobile IS NOT NULL THEN 0.1 ELSE 0 END +
        CASE WHEN NEW.full_name IS NOT NULL THEN 0.1 ELSE 0 END
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_format_invoice_billing_address
    BEFORE INSERT OR UPDATE ON invoice_billing_addresses
    FOR EACH ROW
    EXECUTE FUNCTION format_invoice_billing_address();

-- Update validation rules usage statistics
CREATE OR REPLACE FUNCTION update_validation_rule_stats()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.validation_status != OLD.validation_status AND NEW.validation_status IN ('valid', 'invalid') THEN
        -- This is a simplified example - in practice, you'd need to track which rules were applied
        UPDATE invoice_address_validation_rules 
        SET usage_count = usage_count + 1,
            success_count = CASE WHEN NEW.validation_status = 'valid' THEN success_count + 1 ELSE success_count END,
            failure_count = CASE WHEN NEW.validation_status = 'invalid' THEN failure_count + 1 ELSE failure_count END,
            last_used_at = CURRENT_TIMESTAMP
        WHERE store_id = NEW.store_id
        AND country_code = NEW.country_code
        AND is_active = TRUE;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_validation_rule_stats
    AFTER UPDATE ON invoice_billing_addresses
    FOR EACH ROW
    EXECUTE FUNCTION update_validation_rule_stats();

-- =============================================================================
-- Helper Functions
-- =============================================================================

/**
 * Get invoice billing address with full details
 * @param p_invoice_id UUID - Invoice ID
 * @return JSONB - Complete billing address data
 */
CREATE OR REPLACE FUNCTION get_invoice_billing_address(
    p_invoice_id UUID
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'id', iba.id,
        'address_type', iba.address_type,
        'full_name', iba.full_name,
        'company_name', iba.company_name,
        'address_line_1', iba.address_line_1,
        'address_line_2', iba.address_line_2,
        'city', iba.city,
        'state_province', iba.state_province,
        'postal_code', iba.postal_code,
        'country_code', iba.country_code,
        'country_name', iba.country_name,
        'phone', iba.phone,
        'email', iba.email,
        'tax_number', iba.tax_number,
        'formatted_address', iba.formatted_address,
        'is_validated', iba.is_validated,
        'validation_status', iba.validation_status,
        'is_verified', iba.is_verified,
        'created_at', iba.created_at
    ) INTO result
    FROM invoice_billing_addresses iba
    WHERE iba.invoice_id = p_invoice_id
    AND iba.is_primary = TRUE
    LIMIT 1;
    
    RETURN COALESCE(result, '{"error": "Address not found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

/**
 * Validate invoice billing address
 * @param p_address_id UUID - Address ID
 * @return JSONB - Validation results
 */
CREATE OR REPLACE FUNCTION validate_invoice_billing_address(
    p_address_id UUID
)
RETURNS JSONB AS $$
DECLARE
    v_address RECORD;
    v_rules RECORD;
    v_validation_errors JSONB := '[]';
    v_validation_score DECIMAL := 1.0;
    result JSONB;
BEGIN
    -- Get address details
    SELECT * INTO v_address
    FROM invoice_billing_addresses
    WHERE id = p_address_id;
    
    IF NOT FOUND THEN
        RETURN '{"error": "Address not found"}'::jsonb;
    END IF;
    
    -- Apply validation rules
    FOR v_rules IN 
        SELECT * FROM invoice_address_validation_rules
        WHERE store_id = v_address.store_id
        AND (country_code IS NULL OR country_code = v_address.country_code)
        AND is_active = TRUE
        ORDER BY priority DESC
    LOOP
        -- This is a simplified validation - in practice, you'd implement
        -- specific validation logic based on rule_type and rule_config
        
        CASE v_rules.rule_type
            WHEN 'required_fields' THEN
                IF v_address.address_line_1 IS NULL OR v_address.city IS NULL THEN
                    v_validation_errors := v_validation_errors || jsonb_build_object(
                        'rule', v_rules.rule_name,
                        'error', 'Required fields missing',
                        'severity', 'error'
                    );
                    v_validation_score := v_validation_score - 0.3;
                END IF;
            WHEN 'postal_code_format' THEN
                -- Add postal code format validation logic here
                NULL;
            ELSE
                NULL;
        END CASE;
    END LOOP;
    
    -- Update address with validation results
    UPDATE invoice_billing_addresses
    SET validation_status = CASE 
            WHEN jsonb_array_length(v_validation_errors) = 0 THEN 'valid'
            WHEN v_validation_score > 0.7 THEN 'partial'
            ELSE 'invalid'
        END,
        validation_score = GREATEST(0, v_validation_score),
        validation_errors = v_validation_errors,
        validated_at = CURRENT_TIMESTAMP
    WHERE id = p_address_id;
    
    result := jsonb_build_object(
        'address_id', p_address_id,
        'validation_status', CASE 
            WHEN jsonb_array_length(v_validation_errors) = 0 THEN 'valid'
            WHEN v_validation_score > 0.7 THEN 'partial'
            ELSE 'invalid'
        END,
        'validation_score', GREATEST(0, v_validation_score),
        'errors', v_validation_errors,
        'validated_at', CURRENT_TIMESTAMP
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

/**
 * Search invoice billing addresses
 * @param p_store_id UUID - Store ID
 * @param p_search_term TEXT - Search term
 * @param p_country_code VARCHAR - Country filter
 * @param p_limit INTEGER - Result limit
 * @return JSONB - Search results
 */
CREATE OR REPLACE FUNCTION search_invoice_billing_addresses(
    p_store_id UUID,
    p_search_term TEXT DEFAULT NULL,
    p_country_code VARCHAR(2) DEFAULT NULL,
    p_limit INTEGER DEFAULT 50
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'addresses', jsonb_agg(
            jsonb_build_object(
                'id', iba.id,
                'invoice_id', iba.invoice_id,
                'full_name', iba.full_name,
                'company_name', iba.company_name,
                'formatted_address', iba.formatted_address,
                'country_code', iba.country_code,
                'phone', iba.phone,
                'email', iba.email,
                'is_validated', iba.is_validated,
                'created_at', iba.created_at
            )
            ORDER BY iba.created_at DESC
        ),
        'total_count', COUNT(*)
    ) INTO result
    FROM invoice_billing_addresses iba
    WHERE iba.store_id = p_store_id
    AND (p_search_term IS NULL OR (
        iba.full_name ILIKE '%' || p_search_term || '%' OR
        iba.company_name ILIKE '%' || p_search_term || '%' OR
        iba.formatted_address ILIKE '%' || p_search_term || '%' OR
        iba.email ILIKE '%' || p_search_term || '%' OR
        iba.phone ILIKE '%' || p_search_term || '%'
    ))
    AND (p_country_code IS NULL OR iba.country_code = p_country_code)
    LIMIT p_limit;
    
    RETURN COALESCE(result, '{"addresses": [], "total_count": 0}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Comments
-- =============================================================================

COMMENT ON TABLE invoice_billing_addresses IS 'Normalized billing addresses for invoices';
COMMENT ON TABLE invoice_billing_address_history IS 'Track changes to invoice billing addresses';
COMMENT ON TABLE invoice_address_validation_rules IS 'Validation rules for invoice addresses by country/region';

COMMENT ON COLUMN invoice_billing_addresses.formatted_address IS 'Complete formatted address string';
COMMENT ON COLUMN invoice_billing_addresses.validation_score IS 'Address validation score (0-1)';
COMMENT ON COLUMN invoice_billing_addresses.completeness_score IS 'Address completeness score (0-1)';
COMMENT ON COLUMN invoice_billing_addresses.data_quality_score IS 'Overall data quality score (0-1)';

COMMENT ON FUNCTION get_invoice_billing_address(UUID) IS 'Get complete billing address data for invoice';
COMMENT ON FUNCTION validate_invoice_billing_address(UUID) IS 'Validate invoice billing address against rules';
COMMENT ON FUNCTION search_invoice_billing_addresses(UUID, TEXT, VARCHAR, INTEGER) IS 'Search invoice billing addresses with filters';