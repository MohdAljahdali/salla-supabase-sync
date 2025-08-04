-- =============================================================================
-- Customer Addresses Table
-- =============================================================================
-- This table normalizes the 'addresses' JSONB column from the customers table
-- Stores detailed address information for customers

CREATE TABLE IF NOT EXISTS customer_addresses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Address identification
    salla_address_id VARCHAR(100), -- From Salla API
    external_id VARCHAR(255), -- For external system integration
    address_type VARCHAR(20) DEFAULT 'shipping' CHECK (address_type IN (
        'shipping', 'billing', 'both', 'pickup', 'return', 'office', 'warehouse'
    )),
    
    -- Address details
    title VARCHAR(100), -- e.g., "Home", "Office", "Warehouse"
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    company VARCHAR(255),
    
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
    
    -- Contact information
    phone VARCHAR(50),
    mobile VARCHAR(50),
    email VARCHAR(255),
    
    -- Address properties
    is_default BOOLEAN DEFAULT FALSE,
    is_primary BOOLEAN DEFAULT FALSE, -- Primary address for this type
    is_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Delivery preferences
    delivery_instructions TEXT,
    access_code VARCHAR(50),
    building_number VARCHAR(50),
    floor_number VARCHAR(10),
    apartment_number VARCHAR(50),
    
    -- Business hours (for business addresses)
    business_hours JSONB DEFAULT '{}', -- {"monday": "9:00-17:00", ...}
    
    -- Address validation
    validation_status VARCHAR(20) DEFAULT 'pending' CHECK (validation_status IN (
        'pending', 'valid', 'invalid', 'needs_review', 'corrected'
    )),
    validation_score DECIMAL(3,2), -- 0.00 to 1.00
    validation_errors JSONB DEFAULT '[]',
    validated_at TIMESTAMPTZ,
    
    -- Usage statistics
    usage_count INTEGER DEFAULT 0,
    last_used_at TIMESTAMPTZ,
    
    -- Shipping zones and costs
    shipping_zone_id UUID,
    shipping_cost DECIMAL(8,2),
    free_shipping_threshold DECIMAL(10,2),
    
    -- Tax information
    tax_zone VARCHAR(100),
    tax_rate DECIMAL(5,2),
    
    -- Address quality and completeness
    completeness_score DECIMAL(3,2) DEFAULT 0, -- 0.00 to 1.00
    quality_flags JSONB DEFAULT '[]', -- ["missing_postal_code", "invalid_phone"]
    
    -- External references
    google_place_id VARCHAR(255),
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
    
    -- Constraints
    CONSTRAINT customer_addresses_unique_salla_id UNIQUE(customer_id, salla_address_id),
    CONSTRAINT customer_addresses_coordinates_check CHECK (
        (latitude IS NULL AND longitude IS NULL) OR 
        (latitude IS NOT NULL AND longitude IS NOT NULL AND 
         latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180)
    ),
    CONSTRAINT customer_addresses_validation_score_check CHECK (
        validation_score IS NULL OR (validation_score >= 0 AND validation_score <= 1)
    ),
    CONSTRAINT customer_addresses_completeness_score_check CHECK (
        completeness_score >= 0 AND completeness_score <= 1
    )
);

-- =============================================================================
-- Customer Address History Table
-- =============================================================================
-- Track changes to customer addresses

CREATE TABLE IF NOT EXISTS customer_address_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    address_id UUID NOT NULL REFERENCES customer_addresses(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Change information
    change_type VARCHAR(20) NOT NULL CHECK (change_type IN (
        'created', 'updated', 'deleted', 'verified', 'corrected', 'merged'
    )),
    changed_fields JSONB DEFAULT '[]', -- List of changed field names
    old_values JSONB DEFAULT '{}', -- Previous values
    new_values JSONB DEFAULT '{}', -- New values
    
    -- Change context
    changed_by_user_id UUID,
    change_reason VARCHAR(255),
    change_source VARCHAR(50) DEFAULT 'system', -- 'user', 'system', 'api', 'import'
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- Indexes
-- =============================================================================

-- Basic indexes
CREATE INDEX IF NOT EXISTS idx_customer_addresses_customer_id ON customer_addresses(customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_addresses_store_id ON customer_addresses(store_id);
CREATE INDEX IF NOT EXISTS idx_customer_addresses_salla_address_id ON customer_addresses(salla_address_id);
CREATE INDEX IF NOT EXISTS idx_customer_addresses_external_id ON customer_addresses(external_id);

-- Address type and properties
CREATE INDEX IF NOT EXISTS idx_customer_addresses_type ON customer_addresses(address_type);
CREATE INDEX IF NOT EXISTS idx_customer_addresses_is_default ON customer_addresses(is_default) WHERE is_default = TRUE;
CREATE INDEX IF NOT EXISTS idx_customer_addresses_is_primary ON customer_addresses(is_primary) WHERE is_primary = TRUE;
CREATE INDEX IF NOT EXISTS idx_customer_addresses_is_active ON customer_addresses(is_active);

-- Location indexes
CREATE INDEX IF NOT EXISTS idx_customer_addresses_country_code ON customer_addresses(country_code);
CREATE INDEX IF NOT EXISTS idx_customer_addresses_city ON customer_addresses(city);
CREATE INDEX IF NOT EXISTS idx_customer_addresses_state ON customer_addresses(state);
CREATE INDEX IF NOT EXISTS idx_customer_addresses_postal_code ON customer_addresses(postal_code);
CREATE INDEX IF NOT EXISTS idx_customer_addresses_coordinates ON customer_addresses(latitude, longitude) WHERE latitude IS NOT NULL;

-- Contact information
CREATE INDEX IF NOT EXISTS idx_customer_addresses_phone ON customer_addresses(phone);
CREATE INDEX IF NOT EXISTS idx_customer_addresses_mobile ON customer_addresses(mobile);
CREATE INDEX IF NOT EXISTS idx_customer_addresses_email ON customer_addresses(email);

-- Validation and quality
CREATE INDEX IF NOT EXISTS idx_customer_addresses_validation_status ON customer_addresses(validation_status);
CREATE INDEX IF NOT EXISTS idx_customer_addresses_validation_score ON customer_addresses(validation_score DESC);
CREATE INDEX IF NOT EXISTS idx_customer_addresses_completeness_score ON customer_addresses(completeness_score DESC);
CREATE INDEX IF NOT EXISTS idx_customer_addresses_is_verified ON customer_addresses(is_verified);

-- Usage and performance
CREATE INDEX IF NOT EXISTS idx_customer_addresses_usage_count ON customer_addresses(usage_count DESC);
CREATE INDEX IF NOT EXISTS idx_customer_addresses_last_used_at ON customer_addresses(last_used_at DESC);

-- Shipping information
CREATE INDEX IF NOT EXISTS idx_customer_addresses_shipping_zone_id ON customer_addresses(shipping_zone_id);
CREATE INDEX IF NOT EXISTS idx_customer_addresses_shipping_cost ON customer_addresses(shipping_cost);

-- Sync information
CREATE INDEX IF NOT EXISTS idx_customer_addresses_sync_status ON customer_addresses(sync_status);
CREATE INDEX IF NOT EXISTS idx_customer_addresses_last_sync_at ON customer_addresses(last_sync_at DESC);

-- Timestamps
CREATE INDEX IF NOT EXISTS idx_customer_addresses_created_at ON customer_addresses(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_customer_addresses_updated_at ON customer_addresses(updated_at DESC);

-- JSONB indexes
CREATE INDEX IF NOT EXISTS idx_customer_addresses_business_hours ON customer_addresses USING gin(business_hours);
CREATE INDEX IF NOT EXISTS idx_customer_addresses_validation_errors ON customer_addresses USING gin(validation_errors);
CREATE INDEX IF NOT EXISTS idx_customer_addresses_quality_flags ON customer_addresses USING gin(quality_flags);
CREATE INDEX IF NOT EXISTS idx_customer_addresses_external_references ON customer_addresses USING gin(external_references);
CREATE INDEX IF NOT EXISTS idx_customer_addresses_custom_fields ON customer_addresses USING gin(custom_fields);
CREATE INDEX IF NOT EXISTS idx_customer_addresses_sync_errors ON customer_addresses USING gin(sync_errors);

-- Composite indexes
CREATE INDEX IF NOT EXISTS idx_customer_addresses_customer_type ON customer_addresses(customer_id, address_type, is_active);
CREATE INDEX IF NOT EXISTS idx_customer_addresses_customer_default ON customer_addresses(customer_id, is_default, is_active) WHERE is_default = TRUE;
CREATE INDEX IF NOT EXISTS idx_customer_addresses_location ON customer_addresses(country_code, state, city);
CREATE INDEX IF NOT EXISTS idx_customer_addresses_validation ON customer_addresses(validation_status, validation_score DESC);

-- History table indexes
CREATE INDEX IF NOT EXISTS idx_customer_address_history_address_id ON customer_address_history(address_id);
CREATE INDEX IF NOT EXISTS idx_customer_address_history_customer_id ON customer_address_history(customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_address_history_store_id ON customer_address_history(store_id);
CREATE INDEX IF NOT EXISTS idx_customer_address_history_change_type ON customer_address_history(change_type);
CREATE INDEX IF NOT EXISTS idx_customer_address_history_created_at ON customer_address_history(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_customer_address_history_changed_by ON customer_address_history(changed_by_user_id);

-- =============================================================================
-- Triggers
-- =============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_customer_addresses_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_customer_addresses_updated_at
    BEFORE UPDATE ON customer_addresses
    FOR EACH ROW
    EXECUTE FUNCTION update_customer_addresses_updated_at();

-- Ensure only one default address per customer
CREATE OR REPLACE FUNCTION ensure_single_default_address()
RETURNS TRIGGER AS $$
BEGIN
    -- If setting this address as default, unset others
    IF NEW.is_default = TRUE THEN
        UPDATE customer_addresses 
        SET is_default = FALSE 
        WHERE customer_id = NEW.customer_id 
        AND id != NEW.id 
        AND is_default = TRUE;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_ensure_single_default_address
    BEFORE INSERT OR UPDATE ON customer_addresses
    FOR EACH ROW
    WHEN (NEW.is_default = TRUE)
    EXECUTE FUNCTION ensure_single_default_address();

-- Ensure only one primary address per type per customer
CREATE OR REPLACE FUNCTION ensure_single_primary_address_per_type()
RETURNS TRIGGER AS $$
BEGIN
    -- If setting this address as primary, unset others of same type
    IF NEW.is_primary = TRUE THEN
        UPDATE customer_addresses 
        SET is_primary = FALSE 
        WHERE customer_id = NEW.customer_id 
        AND address_type = NEW.address_type
        AND id != NEW.id 
        AND is_primary = TRUE;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_ensure_single_primary_address_per_type
    BEFORE INSERT OR UPDATE ON customer_addresses
    FOR EACH ROW
    WHEN (NEW.is_primary = TRUE)
    EXECUTE FUNCTION ensure_single_primary_address_per_type();

-- Track address changes
CREATE OR REPLACE FUNCTION track_address_changes()
RETURNS TRIGGER AS $$
DECLARE
    changed_fields TEXT[];
    old_vals JSONB;
    new_vals JSONB;
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO customer_address_history (
            address_id, customer_id, store_id, change_type, 
            new_values, change_source
        ) VALUES (
            NEW.id, NEW.customer_id, NEW.store_id, 'created',
            to_jsonb(NEW), 'system'
        );
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        -- Detect changed fields
        changed_fields := ARRAY[]::TEXT[];
        old_vals := '{}'::jsonb;
        new_vals := '{}'::jsonb;
        
        -- Check each field for changes
        IF OLD.title IS DISTINCT FROM NEW.title THEN
            changed_fields := array_append(changed_fields, 'title');
            old_vals := old_vals || jsonb_build_object('title', OLD.title);
            new_vals := new_vals || jsonb_build_object('title', NEW.title);
        END IF;
        
        IF OLD.address_line_1 IS DISTINCT FROM NEW.address_line_1 THEN
            changed_fields := array_append(changed_fields, 'address_line_1');
            old_vals := old_vals || jsonb_build_object('address_line_1', OLD.address_line_1);
            new_vals := new_vals || jsonb_build_object('address_line_1', NEW.address_line_1);
        END IF;
        
        -- Add more field checks as needed...
        
        -- Only log if there are actual changes
        IF array_length(changed_fields, 1) > 0 THEN
            INSERT INTO customer_address_history (
                address_id, customer_id, store_id, change_type,
                changed_fields, old_values, new_values, change_source
            ) VALUES (
                NEW.id, NEW.customer_id, NEW.store_id, 'updated',
                to_jsonb(changed_fields), old_vals, new_vals, 'system'
            );
        END IF;
        
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO customer_address_history (
            address_id, customer_id, store_id, change_type,
            old_values, change_source
        ) VALUES (
            OLD.id, OLD.customer_id, OLD.store_id, 'deleted',
            to_jsonb(OLD), 'system'
        );
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_track_address_changes
    AFTER INSERT OR UPDATE OR DELETE ON customer_addresses
    FOR EACH ROW
    EXECUTE FUNCTION track_address_changes();

-- Update usage statistics
CREATE OR REPLACE FUNCTION update_address_usage()
RETURNS TRIGGER AS $$
BEGIN
    -- This would be called when an address is used in an order
    UPDATE customer_addresses 
    SET 
        usage_count = usage_count + 1,
        last_used_at = CURRENT_TIMESTAMP
    WHERE id = NEW.shipping_address_id OR id = NEW.billing_address_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Calculate completeness score
CREATE OR REPLACE FUNCTION calculate_address_completeness()
RETURNS TRIGGER AS $$
DECLARE
    score DECIMAL(3,2) := 0;
    total_fields INTEGER := 10; -- Total number of important fields
BEGIN
    -- Calculate completeness based on filled fields
    IF NEW.address_line_1 IS NOT NULL AND NEW.address_line_1 != '' THEN score := score + 0.20; END IF;
    IF NEW.city IS NOT NULL AND NEW.city != '' THEN score := score + 0.15; END IF;
    IF NEW.state IS NOT NULL AND NEW.state != '' THEN score := score + 0.10; END IF;
    IF NEW.postal_code IS NOT NULL AND NEW.postal_code != '' THEN score := score + 0.15; END IF;
    IF NEW.country_code IS NOT NULL AND NEW.country_code != '' THEN score := score + 0.10; END IF;
    IF NEW.phone IS NOT NULL AND NEW.phone != '' THEN score := score + 0.10; END IF;
    IF NEW.first_name IS NOT NULL AND NEW.first_name != '' THEN score := score + 0.05; END IF;
    IF NEW.last_name IS NOT NULL AND NEW.last_name != '' THEN score := score + 0.05; END IF;
    IF NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL THEN score := score + 0.05; END IF;
    IF NEW.building_number IS NOT NULL AND NEW.building_number != '' THEN score := score + 0.05; END IF;
    
    NEW.completeness_score := score;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_calculate_address_completeness
    BEFORE INSERT OR UPDATE ON customer_addresses
    FOR EACH ROW
    EXECUTE FUNCTION calculate_address_completeness();

-- =============================================================================
-- Helper Functions
-- =============================================================================

/**
 * Get customer addresses by type
 * @param p_customer_id UUID - Customer ID
 * @param p_address_type VARCHAR - Address type filter
 * @return TABLE - Customer addresses
 */
CREATE OR REPLACE FUNCTION get_customer_addresses(
    p_customer_id UUID,
    p_address_type VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    address_type VARCHAR,
    title VARCHAR,
    full_address TEXT,
    is_default BOOLEAN,
    is_primary BOOLEAN,
    is_verified BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ca.id,
        ca.address_type,
        ca.title,
        CONCAT_WS(', ', 
            ca.address_line_1,
            ca.address_line_2,
            ca.city,
            ca.state,
            ca.postal_code,
            ca.country_name
        ) as full_address,
        ca.is_default,
        ca.is_primary,
        ca.is_verified
    FROM customer_addresses ca
    WHERE ca.customer_id = p_customer_id
    AND ca.is_active = TRUE
    AND (p_address_type IS NULL OR ca.address_type = p_address_type)
    ORDER BY ca.is_default DESC, ca.is_primary DESC, ca.created_at DESC;
END;
$$ LANGUAGE plpgsql;

/**
 * Get default address for customer
 * @param p_customer_id UUID - Customer ID
 * @param p_address_type VARCHAR - Address type
 * @return RECORD - Default address
 */
CREATE OR REPLACE FUNCTION get_default_address(
    p_customer_id UUID,
    p_address_type VARCHAR DEFAULT 'shipping'
)
RETURNS customer_addresses AS $$
DECLARE
    result customer_addresses;
BEGIN
    -- First try to get default address
    SELECT * INTO result
    FROM customer_addresses
    WHERE customer_id = p_customer_id
    AND address_type = p_address_type
    AND is_default = TRUE
    AND is_active = TRUE
    LIMIT 1;
    
    -- If no default, get primary address of that type
    IF result.id IS NULL THEN
        SELECT * INTO result
        FROM customer_addresses
        WHERE customer_id = p_customer_id
        AND address_type = p_address_type
        AND is_primary = TRUE
        AND is_active = TRUE
        LIMIT 1;
    END IF;
    
    -- If still no address, get any address of that type
    IF result.id IS NULL THEN
        SELECT * INTO result
        FROM customer_addresses
        WHERE customer_id = p_customer_id
        AND address_type = p_address_type
        AND is_active = TRUE
        ORDER BY created_at DESC
        LIMIT 1;
    END IF;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

/**
 * Validate address completeness and quality
 * @param p_address_id UUID - Address ID
 * @return JSONB - Validation results
 */
CREATE OR REPLACE FUNCTION validate_address_quality(
    p_address_id UUID
)
RETURNS JSONB AS $$
DECLARE
    addr customer_addresses;
    issues TEXT[] := ARRAY[]::TEXT[];
    score DECIMAL(3,2) := 1.0;
BEGIN
    SELECT * INTO addr FROM customer_addresses WHERE id = p_address_id;
    
    IF addr.id IS NULL THEN
        RETURN jsonb_build_object('error', 'Address not found');
    END IF;
    
    -- Check for missing required fields
    IF addr.address_line_1 IS NULL OR addr.address_line_1 = '' THEN
        issues := array_append(issues, 'missing_address_line_1');
        score := score - 0.3;
    END IF;
    
    IF addr.city IS NULL OR addr.city = '' THEN
        issues := array_append(issues, 'missing_city');
        score := score - 0.2;
    END IF;
    
    IF addr.postal_code IS NULL OR addr.postal_code = '' THEN
        issues := array_append(issues, 'missing_postal_code');
        score := score - 0.15;
    END IF;
    
    IF addr.phone IS NULL OR addr.phone = '' THEN
        issues := array_append(issues, 'missing_phone');
        score := score - 0.1;
    END IF;
    
    -- Validate phone format (basic check)
    IF addr.phone IS NOT NULL AND NOT addr.phone ~ '^[+]?[0-9\s\-\(\)]+$' THEN
        issues := array_append(issues, 'invalid_phone_format');
        score := score - 0.05;
    END IF;
    
    -- Ensure score doesn't go below 0
    score := GREATEST(score, 0.0);
    
    -- Update the address with validation results
    UPDATE customer_addresses 
    SET 
        validation_score = score,
        quality_flags = to_jsonb(issues),
        validation_status = CASE 
            WHEN score >= 0.8 THEN 'valid'
            WHEN score >= 0.6 THEN 'needs_review'
            ELSE 'invalid'
        END,
        validated_at = CURRENT_TIMESTAMP
    WHERE id = p_address_id;
    
    RETURN jsonb_build_object(
        'score', score,
        'status', CASE 
            WHEN score >= 0.8 THEN 'valid'
            WHEN score >= 0.6 THEN 'needs_review'
            ELSE 'invalid'
        END,
        'issues', to_jsonb(issues)
    );
END;
$$ LANGUAGE plpgsql;

/**
 * Get address statistics for a customer
 * @param p_customer_id UUID - Customer ID
 * @return JSONB - Address statistics
 */
CREATE OR REPLACE FUNCTION get_customer_address_stats(
    p_customer_id UUID
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_addresses', COUNT(*),
        'active_addresses', COUNT(*) FILTER (WHERE is_active = TRUE),
        'verified_addresses', COUNT(*) FILTER (WHERE is_verified = TRUE),
        'default_addresses', COUNT(*) FILTER (WHERE is_default = TRUE),
        'address_types', (
            SELECT jsonb_object_agg(address_type, type_count)
            FROM (
                SELECT address_type, COUNT(*) as type_count
                FROM customer_addresses
                WHERE customer_id = p_customer_id AND is_active = TRUE
                GROUP BY address_type
            ) type_stats
        ),
        'avg_completeness_score', AVG(completeness_score),
        'avg_validation_score', AVG(validation_score)
    ) INTO result
    FROM customer_addresses
    WHERE customer_id = p_customer_id;
    
    RETURN COALESCE(result, '{"error": "No addresses found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Comments
-- =============================================================================

COMMENT ON TABLE customer_addresses IS 'Normalized customer addresses from customers.addresses JSONB column';
COMMENT ON TABLE customer_address_history IS 'Track changes to customer addresses';

COMMENT ON COLUMN customer_addresses.salla_address_id IS 'Address identifier from Salla API';
COMMENT ON COLUMN customer_addresses.address_type IS 'Type of address: shipping, billing, both, etc.';
COMMENT ON COLUMN customer_addresses.is_default IS 'Default address for customer (only one per customer)';
COMMENT ON COLUMN customer_addresses.is_primary IS 'Primary address for this type (only one per type per customer)';
COMMENT ON COLUMN customer_addresses.validation_status IS 'Address validation status';
COMMENT ON COLUMN customer_addresses.completeness_score IS 'Address completeness score (0.00 to 1.00)';
COMMENT ON COLUMN customer_addresses.usage_count IS 'Number of times this address has been used';

COMMENT ON FUNCTION get_customer_addresses(UUID, VARCHAR) IS 'Get customer addresses by type';
COMMENT ON FUNCTION get_default_address(UUID, VARCHAR) IS 'Get default address for customer and type';
COMMENT ON FUNCTION validate_address_quality(UUID) IS 'Validate address completeness and quality';
COMMENT ON FUNCTION get_customer_address_stats(UUID) IS 'Get address statistics for a customer';