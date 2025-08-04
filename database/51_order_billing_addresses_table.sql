-- =============================================================================
-- Order Billing Addresses Table
-- =============================================================================
-- This table normalizes the 'billing_address' JSONB column from the orders table
-- Stores billing address information for orders

CREATE TABLE IF NOT EXISTS order_billing_addresses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Address identification
    salla_address_id VARCHAR(100), -- From Salla API
    external_id VARCHAR(255), -- For external system integration
    
    -- Billing contact information
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    company VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(50),
    mobile VARCHAR(50),
    
    -- Location information
    address_line_1 VARCHAR(500) NOT NULL,
    address_line_2 VARCHAR(500),
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100),
    postal_code VARCHAR(20),
    country_code VARCHAR(3) NOT NULL DEFAULT 'SAU',
    country_name VARCHAR(100),
    
    -- Geographic coordinates
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    
    -- Tax and business information
    tax_number VARCHAR(100),
    vat_number VARCHAR(100),
    commercial_registration VARCHAR(100),
    business_license VARCHAR(100),
    
    -- Address properties
    is_default BOOLEAN DEFAULT FALSE,
    is_verified BOOLEAN DEFAULT FALSE,
    verification_method VARCHAR(50), -- 'manual', 'api', 'document'
    verification_date TIMESTAMPTZ,
    
    -- Address quality and validation
    quality_score DECIMAL(3,2) DEFAULT 0.00 CHECK (quality_score >= 0 AND quality_score <= 1),
    validation_status VARCHAR(20) DEFAULT 'pending' CHECK (validation_status IN (
        'pending', 'valid', 'invalid', 'partial', 'needs_review'
    )),
    validation_errors JSONB DEFAULT '[]',
    last_validated_at TIMESTAMPTZ,
    
    -- Delivery preferences
    delivery_instructions TEXT,
    access_code VARCHAR(50),
    building_type VARCHAR(50), -- 'residential', 'commercial', 'industrial'
    floor_number VARCHAR(10),
    apartment_number VARCHAR(20),
    
    -- Business hours (for commercial addresses)
    business_hours JSONB DEFAULT '{}', -- {"monday": {"open": "09:00", "close": "17:00"}}
    timezone VARCHAR(50) DEFAULT 'Asia/Riyadh',
    
    -- Usage statistics
    usage_count INTEGER DEFAULT 1,
    last_used_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    success_rate DECIMAL(5,2) DEFAULT 100.00, -- Successful delivery rate
    
    -- Shipping preferences
    preferred_delivery_time VARCHAR(50), -- 'morning', 'afternoon', 'evening', 'anytime'
    delivery_window_start TIME,
    delivery_window_end TIME,
    requires_appointment BOOLEAN DEFAULT FALSE,
    
    -- Tax calculation
    tax_zone VARCHAR(100),
    tax_rate DECIMAL(5,4) DEFAULT 0.0000,
    tax_exempt BOOLEAN DEFAULT FALSE,
    tax_exemption_reason VARCHAR(255),
    
    -- Address quality metrics
    completeness_score DECIMAL(3,2) DEFAULT 0.00, -- How complete is the address
    accuracy_score DECIMAL(3,2) DEFAULT 0.00, -- How accurate is the address
    deliverability_score DECIMAL(3,2) DEFAULT 0.00, -- How deliverable is the address
    
    -- External references
    external_references JSONB DEFAULT '{}',
    
    -- Sync information
    sync_status VARCHAR(20) DEFAULT 'synced' CHECK (sync_status IN ('pending', 'syncing', 'synced', 'error')),
    last_sync_at TIMESTAMPTZ,
    sync_errors JSONB DEFAULT '[]',
    
    -- Custom fields
    custom_fields JSONB DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- Order Billing Address History Table
-- =============================================================================
-- Track changes to billing addresses

CREATE TABLE IF NOT EXISTS order_billing_address_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    billing_address_id UUID REFERENCES order_billing_addresses(id) ON DELETE SET NULL,
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Change information
    change_type VARCHAR(20) NOT NULL CHECK (change_type IN (
        'created', 'updated', 'verified', 'invalidated', 'used'
    )),
    field_name VARCHAR(100),
    old_value TEXT,
    new_value TEXT,
    
    -- Change context
    changed_by_user_id UUID,
    change_reason VARCHAR(255),
    change_source VARCHAR(50) DEFAULT 'system',
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- Indexes
-- =============================================================================

-- Basic indexes
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_order_id ON order_billing_addresses(order_id);
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_store_id ON order_billing_addresses(store_id);
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_salla_address_id ON order_billing_addresses(salla_address_id);
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_external_id ON order_billing_addresses(external_id);

-- Contact information
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_full_name ON order_billing_addresses(first_name, last_name);
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_company ON order_billing_addresses(company);
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_email ON order_billing_addresses(email);
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_phone ON order_billing_addresses(phone);

-- Location
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_city ON order_billing_addresses(city);
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_state ON order_billing_addresses(state);
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_postal_code ON order_billing_addresses(postal_code);
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_country_code ON order_billing_addresses(country_code);
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_coordinates ON order_billing_addresses(latitude, longitude);

-- Tax and business information
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_tax_number ON order_billing_addresses(tax_number);
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_vat_number ON order_billing_addresses(vat_number);
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_commercial_registration ON order_billing_addresses(commercial_registration);

-- Address properties
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_is_default ON order_billing_addresses(is_default) WHERE is_default = TRUE;
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_is_verified ON order_billing_addresses(is_verified);
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_verification_method ON order_billing_addresses(verification_method);
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_verification_date ON order_billing_addresses(verification_date DESC);

-- Address quality
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_quality_score ON order_billing_addresses(quality_score DESC);
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_validation_status ON order_billing_addresses(validation_status);
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_last_validated_at ON order_billing_addresses(last_validated_at DESC);

-- Building information
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_building_type ON order_billing_addresses(building_type);
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_floor_number ON order_billing_addresses(floor_number);

-- Usage statistics
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_usage_count ON order_billing_addresses(usage_count DESC);
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_last_used_at ON order_billing_addresses(last_used_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_success_rate ON order_billing_addresses(success_rate DESC);

-- Delivery preferences
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_preferred_delivery_time ON order_billing_addresses(preferred_delivery_time);
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_requires_appointment ON order_billing_addresses(requires_appointment) WHERE requires_appointment = TRUE;

-- Tax information
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_tax_zone ON order_billing_addresses(tax_zone);
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_tax_rate ON order_billing_addresses(tax_rate);
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_tax_exempt ON order_billing_addresses(tax_exempt) WHERE tax_exempt = TRUE;

-- Quality metrics
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_completeness_score ON order_billing_addresses(completeness_score DESC);
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_accuracy_score ON order_billing_addresses(accuracy_score DESC);
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_deliverability_score ON order_billing_addresses(deliverability_score DESC);

-- Sync information
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_sync_status ON order_billing_addresses(sync_status);
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_last_sync_at ON order_billing_addresses(last_sync_at DESC);

-- Timestamps
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_created_at ON order_billing_addresses(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_updated_at ON order_billing_addresses(updated_at DESC);

-- JSONB indexes
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_business_hours ON order_billing_addresses USING gin(business_hours);
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_validation_errors ON order_billing_addresses USING gin(validation_errors);
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_external_references ON order_billing_addresses USING gin(external_references);
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_custom_fields ON order_billing_addresses USING gin(custom_fields);
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_sync_errors ON order_billing_addresses USING gin(sync_errors);

-- Text search indexes
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_full_address_text ON order_billing_addresses USING gin(to_tsvector('english', COALESCE(address_line_1, '') || ' ' || COALESCE(address_line_2, '') || ' ' || COALESCE(city, '') || ' ' || COALESCE(state, '')));
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_company_text ON order_billing_addresses USING gin(to_tsvector('english', COALESCE(company, '')));

-- Composite indexes
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_order_default ON order_billing_addresses(order_id, is_default);
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_location ON order_billing_addresses(country_code, state, city);
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_quality ON order_billing_addresses(quality_score DESC, validation_status, is_verified);
CREATE INDEX IF NOT EXISTS idx_order_billing_addresses_usage ON order_billing_addresses(usage_count DESC, success_rate DESC, last_used_at DESC);

-- History table indexes
CREATE INDEX IF NOT EXISTS idx_order_billing_address_history_billing_address_id ON order_billing_address_history(billing_address_id);
CREATE INDEX IF NOT EXISTS idx_order_billing_address_history_order_id ON order_billing_address_history(order_id);
CREATE INDEX IF NOT EXISTS idx_order_billing_address_history_store_id ON order_billing_address_history(store_id);
CREATE INDEX IF NOT EXISTS idx_order_billing_address_history_change_type ON order_billing_address_history(change_type);
CREATE INDEX IF NOT EXISTS idx_order_billing_address_history_created_at ON order_billing_address_history(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_billing_address_history_changed_by ON order_billing_address_history(changed_by_user_id);

-- =============================================================================
-- Triggers
-- =============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_order_billing_addresses_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_order_billing_addresses_updated_at
    BEFORE UPDATE ON order_billing_addresses
    FOR EACH ROW
    EXECUTE FUNCTION update_order_billing_addresses_updated_at();

-- Track address changes
CREATE OR REPLACE FUNCTION track_billing_address_changes()
RETURNS TRIGGER AS $$
DECLARE
    change_type_val VARCHAR(20);
BEGIN
    IF TG_OP = 'INSERT' THEN
        change_type_val := 'created';
        INSERT INTO order_billing_address_history (
            billing_address_id, order_id, store_id, change_type, change_source
        ) VALUES (
            NEW.id, NEW.order_id, NEW.store_id, change_type_val, 'system'
        );
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        change_type_val := 'updated';
        
        -- Track specific field changes
        IF OLD.is_verified != NEW.is_verified AND NEW.is_verified = TRUE THEN
            INSERT INTO order_billing_address_history (
                billing_address_id, order_id, store_id, change_type,
                field_name, old_value, new_value, change_source
            ) VALUES (
                NEW.id, NEW.order_id, NEW.store_id, 'verified',
                'is_verified', OLD.is_verified::text, NEW.is_verified::text, 'system'
            );
        END IF;
        
        -- Track address line changes
        IF OLD.address_line_1 IS DISTINCT FROM NEW.address_line_1 THEN
            INSERT INTO order_billing_address_history (
                billing_address_id, order_id, store_id, change_type,
                field_name, old_value, new_value, change_source
            ) VALUES (
                NEW.id, NEW.order_id, NEW.store_id, change_type_val,
                'address_line_1', OLD.address_line_1, NEW.address_line_1, 'system'
            );
        END IF;
        
        RETURN NEW;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_track_billing_address_changes
    AFTER INSERT OR UPDATE ON order_billing_addresses
    FOR EACH ROW
    EXECUTE FUNCTION track_billing_address_changes();

-- Update usage statistics
CREATE OR REPLACE FUNCTION update_billing_address_usage()
RETURNS TRIGGER AS $$
BEGIN
    -- Update usage count and last used timestamp
    UPDATE order_billing_addresses 
    SET 
        usage_count = usage_count + 1,
        last_used_at = CURRENT_TIMESTAMP
    WHERE id = NEW.id;
    
    -- Log usage
    INSERT INTO order_billing_address_history (
        billing_address_id, order_id, store_id, change_type, change_source
    ) VALUES (
        NEW.id, NEW.order_id, NEW.store_id, 'used', 'system'
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Calculate address quality score
CREATE OR REPLACE FUNCTION calculate_address_quality_score()
RETURNS TRIGGER AS $$
DECLARE
    completeness DECIMAL(3,2) := 0.00;
    accuracy DECIMAL(3,2) := 0.00;
    deliverability DECIMAL(3,2) := 0.00;
BEGIN
    -- Calculate completeness score (0.00 to 1.00)
    completeness := (
        CASE WHEN NEW.first_name IS NOT NULL AND LENGTH(NEW.first_name) > 0 THEN 0.1 ELSE 0 END +
        CASE WHEN NEW.last_name IS NOT NULL AND LENGTH(NEW.last_name) > 0 THEN 0.1 ELSE 0 END +
        CASE WHEN NEW.address_line_1 IS NOT NULL AND LENGTH(NEW.address_line_1) > 0 THEN 0.3 ELSE 0 END +
        CASE WHEN NEW.city IS NOT NULL AND LENGTH(NEW.city) > 0 THEN 0.2 ELSE 0 END +
        CASE WHEN NEW.postal_code IS NOT NULL AND LENGTH(NEW.postal_code) > 0 THEN 0.1 ELSE 0 END +
        CASE WHEN NEW.country_code IS NOT NULL AND LENGTH(NEW.country_code) > 0 THEN 0.1 ELSE 0 END +
        CASE WHEN NEW.phone IS NOT NULL AND LENGTH(NEW.phone) > 0 THEN 0.1 ELSE 0 END
    );
    
    -- Calculate accuracy score based on validation
    accuracy := CASE 
        WHEN NEW.validation_status = 'valid' THEN 1.00
        WHEN NEW.validation_status = 'partial' THEN 0.70
        WHEN NEW.validation_status = 'needs_review' THEN 0.50
        WHEN NEW.validation_status = 'invalid' THEN 0.20
        ELSE 0.30 -- pending
    END;
    
    -- Calculate deliverability score
    deliverability := LEAST(1.00, NEW.success_rate / 100.0);
    
    -- Update scores
    NEW.completeness_score := completeness;
    NEW.accuracy_score := accuracy;
    NEW.deliverability_score := deliverability;
    NEW.quality_score := (completeness + accuracy + deliverability) / 3.0;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_calculate_address_quality_score
    BEFORE INSERT OR UPDATE ON order_billing_addresses
    FOR EACH ROW
    EXECUTE FUNCTION calculate_address_quality_score();

-- =============================================================================
-- Helper Functions
-- =============================================================================

/**
 * Get billing address for order
 * @param p_order_id UUID - Order ID
 * @return TABLE - Billing address information
 */
CREATE OR REPLACE FUNCTION get_order_billing_address(
    p_order_id UUID
)
RETURNS TABLE (
    address_id UUID,
    full_name TEXT,
    company VARCHAR,
    full_address TEXT,
    city VARCHAR,
    state VARCHAR,
    postal_code VARCHAR,
    country_name VARCHAR,
    phone VARCHAR,
    email VARCHAR,
    is_verified BOOLEAN,
    quality_score DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        oba.id as address_id,
        CONCAT(oba.first_name, ' ', oba.last_name) as full_name,
        oba.company,
        CONCAT(
            oba.address_line_1,
            CASE WHEN oba.address_line_2 IS NOT NULL THEN ', ' || oba.address_line_2 ELSE '' END
        ) as full_address,
        oba.city,
        oba.state,
        oba.postal_code,
        oba.country_name,
        oba.phone,
        oba.email,
        oba.is_verified,
        oba.quality_score
    FROM order_billing_addresses oba
    WHERE oba.order_id = p_order_id;
END;
$$ LANGUAGE plpgsql;

/**
 * Validate billing address quality
 * @param p_address_id UUID - Address ID
 * @return JSONB - Validation results
 */
CREATE OR REPLACE FUNCTION validate_billing_address_quality(
    p_address_id UUID
)
RETURNS JSONB AS $$
DECLARE
    address_record order_billing_addresses;
    validation_result JSONB;
    errors JSONB := '[]'::jsonb;
BEGIN
    -- Get address record
    SELECT * INTO address_record 
    FROM order_billing_addresses 
    WHERE id = p_address_id;
    
    IF address_record.id IS NULL THEN
        RETURN '{"error": "Address not found"}'::jsonb;
    END IF;
    
    -- Validate required fields
    IF address_record.first_name IS NULL OR LENGTH(address_record.first_name) = 0 THEN
        errors := errors || '["First name is required"]'::jsonb;
    END IF;
    
    IF address_record.address_line_1 IS NULL OR LENGTH(address_record.address_line_1) < 5 THEN
        errors := errors || '["Address line 1 must be at least 5 characters"]'::jsonb;
    END IF;
    
    IF address_record.city IS NULL OR LENGTH(address_record.city) = 0 THEN
        errors := errors || '["City is required"]'::jsonb;
    END IF;
    
    IF address_record.postal_code IS NULL OR LENGTH(address_record.postal_code) = 0 THEN
        errors := errors || '["Postal code is required"]'::jsonb;
    END IF;
    
    -- Validate email format if provided
    IF address_record.email IS NOT NULL AND address_record.email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
        errors := errors || '["Invalid email format"]'::jsonb;
    END IF;
    
    -- Validate phone format if provided
    IF address_record.phone IS NOT NULL AND address_record.phone !~ '^[+]?[0-9\s\-\(\)]+$' THEN
        errors := errors || '["Invalid phone format"]'::jsonb;
    END IF;
    
    -- Build validation result
    validation_result := jsonb_build_object(
        'is_valid', jsonb_array_length(errors) = 0,
        'errors', errors,
        'quality_score', address_record.quality_score,
        'completeness_score', address_record.completeness_score,
        'accuracy_score', address_record.accuracy_score,
        'deliverability_score', address_record.deliverability_score,
        'validation_status', address_record.validation_status,
        'last_validated_at', address_record.last_validated_at
    );
    
    -- Update validation status
    UPDATE order_billing_addresses 
    SET 
        validation_status = CASE 
            WHEN jsonb_array_length(errors) = 0 THEN 'valid'
            WHEN jsonb_array_length(errors) <= 2 THEN 'partial'
            ELSE 'invalid'
        END,
        validation_errors = errors,
        last_validated_at = CURRENT_TIMESTAMP
    WHERE id = p_address_id;
    
    RETURN validation_result;
END;
$$ LANGUAGE plpgsql;

/**
 * Get billing address statistics for store
 * @param p_store_id UUID - Store ID
 * @return JSONB - Address statistics
 */
CREATE OR REPLACE FUNCTION get_billing_address_stats(
    p_store_id UUID
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_addresses', COUNT(*),
        'verified_addresses', COUNT(*) FILTER (WHERE is_verified = TRUE),
        'default_addresses', COUNT(*) FILTER (WHERE is_default = TRUE),
        'high_quality_addresses', COUNT(*) FILTER (WHERE quality_score >= 0.80),
        'valid_addresses', COUNT(*) FILTER (WHERE validation_status = 'valid'),
        'business_addresses', COUNT(*) FILTER (WHERE company IS NOT NULL),
        'avg_quality_score', AVG(quality_score),
        'avg_completeness_score', AVG(completeness_score),
        'avg_accuracy_score', AVG(accuracy_score),
        'avg_deliverability_score', AVG(deliverability_score),
        'avg_usage_count', AVG(usage_count),
        'avg_success_rate', AVG(success_rate),
        'validation_statuses', (
            SELECT jsonb_object_agg(validation_status, status_count)
            FROM (
                SELECT validation_status, COUNT(*) as status_count
                FROM order_billing_addresses
                WHERE store_id = p_store_id
                GROUP BY validation_status
            ) status_stats
        ),
        'countries', (
            SELECT jsonb_object_agg(country_code, country_count)
            FROM (
                SELECT country_code, COUNT(*) as country_count
                FROM order_billing_addresses
                WHERE store_id = p_store_id
                GROUP BY country_code
            ) country_stats
        ),
        'building_types', (
            SELECT jsonb_object_agg(building_type, type_count)
            FROM (
                SELECT building_type, COUNT(*) as type_count
                FROM order_billing_addresses
                WHERE store_id = p_store_id AND building_type IS NOT NULL
                GROUP BY building_type
            ) type_stats
        )
    ) INTO result
    FROM order_billing_addresses
    WHERE store_id = p_store_id;
    
    RETURN COALESCE(result, '{"error": "No addresses found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Comments
-- =============================================================================

COMMENT ON TABLE order_billing_addresses IS 'Normalized billing addresses from orders.billing_address JSONB column';
COMMENT ON TABLE order_billing_address_history IS 'Track changes to order billing addresses';

COMMENT ON COLUMN order_billing_addresses.salla_address_id IS 'Address ID from Salla platform';
COMMENT ON COLUMN order_billing_addresses.quality_score IS 'Overall address quality score (0.00 to 1.00)';
COMMENT ON COLUMN order_billing_addresses.validation_status IS 'Address validation status';
COMMENT ON COLUMN order_billing_addresses.success_rate IS 'Successful delivery rate for this address';
COMMENT ON COLUMN order_billing_addresses.tax_rate IS 'Tax rate for this address location';

COMMENT ON FUNCTION get_order_billing_address(UUID) IS 'Get billing address for order';
COMMENT ON FUNCTION validate_billing_address_quality(UUID) IS 'Validate billing address quality';
COMMENT ON FUNCTION get_billing_address_stats(UUID) IS 'Get billing address statistics for store';