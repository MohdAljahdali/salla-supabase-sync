-- =============================================================================
-- Order Shipping Addresses Table
-- =============================================================================
-- This table normalizes the 'shipping_address' JSONB column from the orders table
-- Stores shipping address information for orders

CREATE TABLE IF NOT EXISTS order_shipping_addresses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Address identification
    salla_address_id VARCHAR(100), -- From Salla API
    external_id VARCHAR(255), -- For external system integration
    
    -- Shipping contact information
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
    
    -- Address properties
    is_default BOOLEAN DEFAULT FALSE,
    is_verified BOOLEAN DEFAULT FALSE,
    verification_method VARCHAR(50), -- 'manual', 'api', 'document', 'gps'
    verification_date TIMESTAMPTZ,
    
    -- Address quality and validation
    quality_score DECIMAL(3,2) DEFAULT 0.00 CHECK (quality_score >= 0 AND quality_score <= 1),
    validation_status VARCHAR(20) DEFAULT 'pending' CHECK (validation_status IN (
        'pending', 'valid', 'invalid', 'partial', 'needs_review'
    )),
    validation_errors JSONB DEFAULT '[]',
    last_validated_at TIMESTAMPTZ,
    
    -- Delivery preferences and instructions
    delivery_instructions TEXT,
    special_instructions TEXT,
    access_code VARCHAR(50),
    gate_code VARCHAR(50),
    building_type VARCHAR(50), -- 'residential', 'commercial', 'industrial', 'apartment', 'villa'
    floor_number VARCHAR(10),
    apartment_number VARCHAR(20),
    landmark VARCHAR(255),
    
    -- Delivery window preferences
    preferred_delivery_time VARCHAR(50), -- 'morning', 'afternoon', 'evening', 'anytime'
    delivery_window_start TIME,
    delivery_window_end TIME,
    requires_appointment BOOLEAN DEFAULT FALSE,
    
    -- Business hours (for commercial addresses)
    business_hours JSONB DEFAULT '{}', -- {"monday": {"open": "09:00", "close": "17:00"}}
    timezone VARCHAR(50) DEFAULT 'Asia/Riyadh',
    
    -- Shipping restrictions and capabilities
    allows_weekend_delivery BOOLEAN DEFAULT TRUE,
    allows_evening_delivery BOOLEAN DEFAULT TRUE,
    requires_signature BOOLEAN DEFAULT FALSE,
    requires_id_verification BOOLEAN DEFAULT FALSE,
    allows_safe_drop BOOLEAN DEFAULT FALSE,
    safe_drop_location VARCHAR(255),
    
    -- Address accessibility
    has_elevator BOOLEAN,
    wheelchair_accessible BOOLEAN,
    parking_available BOOLEAN,
    loading_dock_available BOOLEAN,
    
    -- Security and safety
    security_code VARCHAR(50),
    has_security_guard BOOLEAN DEFAULT FALSE,
    gated_community BOOLEAN DEFAULT FALSE,
    safe_neighborhood BOOLEAN DEFAULT TRUE,
    
    -- Usage statistics
    usage_count INTEGER DEFAULT 1,
    last_used_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    successful_deliveries INTEGER DEFAULT 0,
    failed_deliveries INTEGER DEFAULT 0,
    success_rate DECIMAL(5,2) DEFAULT 100.00,
    avg_delivery_time_hours DECIMAL(5,2),
    
    -- Shipping costs and zones
    shipping_zone VARCHAR(100),
    shipping_cost DECIMAL(10,2),
    express_shipping_available BOOLEAN DEFAULT TRUE,
    same_day_delivery_available BOOLEAN DEFAULT FALSE,
    
    -- Address quality metrics
    completeness_score DECIMAL(3,2) DEFAULT 0.00, -- How complete is the address
    accuracy_score DECIMAL(3,2) DEFAULT 0.00, -- How accurate is the address
    deliverability_score DECIMAL(3,2) DEFAULT 0.00, -- How deliverable is the address
    findability_score DECIMAL(3,2) DEFAULT 0.00, -- How easy to find
    
    -- Carrier preferences
    preferred_carrier VARCHAR(100),
    restricted_carriers JSONB DEFAULT '[]', -- List of carriers that cannot deliver here
    carrier_notes JSONB DEFAULT '{}', -- Carrier-specific delivery notes
    
    -- Environmental factors
    weather_sensitive BOOLEAN DEFAULT FALSE,
    flood_prone BOOLEAN DEFAULT FALSE,
    high_crime_area BOOLEAN DEFAULT FALSE,
    
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
-- Order Shipping Address History Table
-- =============================================================================
-- Track changes to shipping addresses

CREATE TABLE IF NOT EXISTS order_shipping_address_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shipping_address_id UUID REFERENCES order_shipping_addresses(id) ON DELETE SET NULL,
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Change information
    change_type VARCHAR(20) NOT NULL CHECK (change_type IN (
        'created', 'updated', 'verified', 'invalidated', 'used', 'delivery_attempted', 'delivery_successful', 'delivery_failed'
    )),
    field_name VARCHAR(100),
    old_value TEXT,
    new_value TEXT,
    
    -- Change context
    changed_by_user_id UUID,
    change_reason VARCHAR(255),
    change_source VARCHAR(50) DEFAULT 'system',
    delivery_attempt_id UUID, -- Reference to delivery attempt
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- Delivery Attempts Table
-- =============================================================================
-- Track delivery attempts for shipping addresses

CREATE TABLE IF NOT EXISTS order_delivery_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shipping_address_id UUID NOT NULL REFERENCES order_shipping_addresses(id) ON DELETE CASCADE,
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Attempt information
    attempt_number INTEGER NOT NULL DEFAULT 1,
    carrier VARCHAR(100),
    tracking_number VARCHAR(255),
    driver_name VARCHAR(100),
    driver_phone VARCHAR(50),
    
    -- Attempt status
    status VARCHAR(20) NOT NULL CHECK (status IN (
        'scheduled', 'in_transit', 'out_for_delivery', 'delivered', 'failed', 'returned'
    )),
    
    -- Timing
    scheduled_at TIMESTAMPTZ,
    attempted_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    
    -- Delivery details
    delivery_method VARCHAR(50), -- 'door_to_door', 'safe_drop', 'pickup_point', 'neighbor'
    received_by VARCHAR(100), -- Who received the package
    signature_required BOOLEAN DEFAULT FALSE,
    signature_obtained BOOLEAN DEFAULT FALSE,
    photo_proof_url VARCHAR(500),
    
    -- Failure information
    failure_reason VARCHAR(255),
    failure_code VARCHAR(50),
    retry_scheduled BOOLEAN DEFAULT FALSE,
    next_attempt_at TIMESTAMPTZ,
    
    -- Location verification
    gps_latitude DECIMAL(10, 8),
    gps_longitude DECIMAL(11, 8),
    location_verified BOOLEAN DEFAULT FALSE,
    
    -- Notes and feedback
    driver_notes TEXT,
    customer_feedback TEXT,
    internal_notes TEXT,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- Indexes
-- =============================================================================

-- Basic indexes
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_order_id ON order_shipping_addresses(order_id);
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_store_id ON order_shipping_addresses(store_id);
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_salla_address_id ON order_shipping_addresses(salla_address_id);
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_external_id ON order_shipping_addresses(external_id);

-- Contact information
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_full_name ON order_shipping_addresses(first_name, last_name);
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_company ON order_shipping_addresses(company);
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_email ON order_shipping_addresses(email);
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_phone ON order_shipping_addresses(phone);

-- Location
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_city ON order_shipping_addresses(city);
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_state ON order_shipping_addresses(state);
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_postal_code ON order_shipping_addresses(postal_code);
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_country_code ON order_shipping_addresses(country_code);
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_coordinates ON order_shipping_addresses(latitude, longitude);

-- Address properties
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_is_default ON order_shipping_addresses(is_default) WHERE is_default = TRUE;
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_is_verified ON order_shipping_addresses(is_verified);
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_verification_method ON order_shipping_addresses(verification_method);
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_verification_date ON order_shipping_addresses(verification_date DESC);

-- Address quality
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_quality_score ON order_shipping_addresses(quality_score DESC);
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_validation_status ON order_shipping_addresses(validation_status);
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_last_validated_at ON order_shipping_addresses(last_validated_at DESC);

-- Building information
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_building_type ON order_shipping_addresses(building_type);
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_floor_number ON order_shipping_addresses(floor_number);

-- Delivery preferences
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_preferred_delivery_time ON order_shipping_addresses(preferred_delivery_time);
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_requires_appointment ON order_shipping_addresses(requires_appointment) WHERE requires_appointment = TRUE;
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_requires_signature ON order_shipping_addresses(requires_signature) WHERE requires_signature = TRUE;
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_allows_safe_drop ON order_shipping_addresses(allows_safe_drop) WHERE allows_safe_drop = TRUE;

-- Accessibility
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_has_elevator ON order_shipping_addresses(has_elevator) WHERE has_elevator = TRUE;
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_wheelchair_accessible ON order_shipping_addresses(wheelchair_accessible) WHERE wheelchair_accessible = TRUE;
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_parking_available ON order_shipping_addresses(parking_available) WHERE parking_available = TRUE;

-- Security
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_has_security_guard ON order_shipping_addresses(has_security_guard) WHERE has_security_guard = TRUE;
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_gated_community ON order_shipping_addresses(gated_community) WHERE gated_community = TRUE;
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_safe_neighborhood ON order_shipping_addresses(safe_neighborhood);

-- Usage statistics
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_usage_count ON order_shipping_addresses(usage_count DESC);
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_last_used_at ON order_shipping_addresses(last_used_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_success_rate ON order_shipping_addresses(success_rate DESC);
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_avg_delivery_time ON order_shipping_addresses(avg_delivery_time_hours);

-- Shipping information
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_shipping_zone ON order_shipping_addresses(shipping_zone);
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_shipping_cost ON order_shipping_addresses(shipping_cost);
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_express_available ON order_shipping_addresses(express_shipping_available) WHERE express_shipping_available = TRUE;
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_same_day_available ON order_shipping_addresses(same_day_delivery_available) WHERE same_day_delivery_available = TRUE;

-- Quality metrics
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_completeness_score ON order_shipping_addresses(completeness_score DESC);
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_accuracy_score ON order_shipping_addresses(accuracy_score DESC);
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_deliverability_score ON order_shipping_addresses(deliverability_score DESC);
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_findability_score ON order_shipping_addresses(findability_score DESC);

-- Carrier information
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_preferred_carrier ON order_shipping_addresses(preferred_carrier);

-- Environmental factors
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_weather_sensitive ON order_shipping_addresses(weather_sensitive) WHERE weather_sensitive = TRUE;
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_flood_prone ON order_shipping_addresses(flood_prone) WHERE flood_prone = TRUE;
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_high_crime_area ON order_shipping_addresses(high_crime_area) WHERE high_crime_area = TRUE;

-- Sync information
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_sync_status ON order_shipping_addresses(sync_status);
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_last_sync_at ON order_shipping_addresses(last_sync_at DESC);

-- Timestamps
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_created_at ON order_shipping_addresses(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_updated_at ON order_shipping_addresses(updated_at DESC);

-- JSONB indexes
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_business_hours ON order_shipping_addresses USING gin(business_hours);
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_validation_errors ON order_shipping_addresses USING gin(validation_errors);
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_restricted_carriers ON order_shipping_addresses USING gin(restricted_carriers);
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_carrier_notes ON order_shipping_addresses USING gin(carrier_notes);
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_external_references ON order_shipping_addresses USING gin(external_references);
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_custom_fields ON order_shipping_addresses USING gin(custom_fields);
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_sync_errors ON order_shipping_addresses USING gin(sync_errors);

-- Text search indexes
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_full_address_text ON order_shipping_addresses USING gin(to_tsvector('english', COALESCE(address_line_1, '') || ' ' || COALESCE(address_line_2, '') || ' ' || COALESCE(city, '') || ' ' || COALESCE(state, '')));
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_company_text ON order_shipping_addresses USING gin(to_tsvector('english', COALESCE(company, '')));
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_landmark_text ON order_shipping_addresses USING gin(to_tsvector('english', COALESCE(landmark, '')));

-- Composite indexes
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_order_default ON order_shipping_addresses(order_id, is_default);
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_location ON order_shipping_addresses(country_code, state, city);
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_quality ON order_shipping_addresses(quality_score DESC, validation_status, is_verified);
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_delivery_performance ON order_shipping_addresses(success_rate DESC, avg_delivery_time_hours, usage_count DESC);
CREATE INDEX IF NOT EXISTS idx_order_shipping_addresses_shipping_options ON order_shipping_addresses(shipping_zone, express_shipping_available, same_day_delivery_available);

-- History table indexes
CREATE INDEX IF NOT EXISTS idx_order_shipping_address_history_shipping_address_id ON order_shipping_address_history(shipping_address_id);
CREATE INDEX IF NOT EXISTS idx_order_shipping_address_history_order_id ON order_shipping_address_history(order_id);
CREATE INDEX IF NOT EXISTS idx_order_shipping_address_history_store_id ON order_shipping_address_history(store_id);
CREATE INDEX IF NOT EXISTS idx_order_shipping_address_history_change_type ON order_shipping_address_history(change_type);
CREATE INDEX IF NOT EXISTS idx_order_shipping_address_history_created_at ON order_shipping_address_history(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_shipping_address_history_changed_by ON order_shipping_address_history(changed_by_user_id);
CREATE INDEX IF NOT EXISTS idx_order_shipping_address_history_delivery_attempt ON order_shipping_address_history(delivery_attempt_id);

-- Delivery attempts table indexes
CREATE INDEX IF NOT EXISTS idx_order_delivery_attempts_shipping_address_id ON order_delivery_attempts(shipping_address_id);
CREATE INDEX IF NOT EXISTS idx_order_delivery_attempts_order_id ON order_delivery_attempts(order_id);
CREATE INDEX IF NOT EXISTS idx_order_delivery_attempts_store_id ON order_delivery_attempts(store_id);
CREATE INDEX IF NOT EXISTS idx_order_delivery_attempts_status ON order_delivery_attempts(status);
CREATE INDEX IF NOT EXISTS idx_order_delivery_attempts_carrier ON order_delivery_attempts(carrier);
CREATE INDEX IF NOT EXISTS idx_order_delivery_attempts_tracking_number ON order_delivery_attempts(tracking_number);
CREATE INDEX IF NOT EXISTS idx_order_delivery_attempts_scheduled_at ON order_delivery_attempts(scheduled_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_delivery_attempts_attempted_at ON order_delivery_attempts(attempted_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_delivery_attempts_delivered_at ON order_delivery_attempts(delivered_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_delivery_attempts_next_attempt_at ON order_delivery_attempts(next_attempt_at);
CREATE INDEX IF NOT EXISTS idx_order_delivery_attempts_created_at ON order_delivery_attempts(created_at DESC);

-- =============================================================================
-- Triggers
-- =============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_order_shipping_addresses_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_order_shipping_addresses_updated_at
    BEFORE UPDATE ON order_shipping_addresses
    FOR EACH ROW
    EXECUTE FUNCTION update_order_shipping_addresses_updated_at();

CREATE TRIGGER trigger_update_order_delivery_attempts_updated_at
    BEFORE UPDATE ON order_delivery_attempts
    FOR EACH ROW
    EXECUTE FUNCTION update_order_shipping_addresses_updated_at();

-- Track address changes
CREATE OR REPLACE FUNCTION track_shipping_address_changes()
RETURNS TRIGGER AS $$
DECLARE
    change_type_val VARCHAR(20);
BEGIN
    IF TG_OP = 'INSERT' THEN
        change_type_val := 'created';
        INSERT INTO order_shipping_address_history (
            shipping_address_id, order_id, store_id, change_type, change_source
        ) VALUES (
            NEW.id, NEW.order_id, NEW.store_id, change_type_val, 'system'
        );
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        change_type_val := 'updated';
        
        -- Track specific field changes
        IF OLD.is_verified != NEW.is_verified AND NEW.is_verified = TRUE THEN
            INSERT INTO order_shipping_address_history (
                shipping_address_id, order_id, store_id, change_type,
                field_name, old_value, new_value, change_source
            ) VALUES (
                NEW.id, NEW.order_id, NEW.store_id, 'verified',
                'is_verified', OLD.is_verified::text, NEW.is_verified::text, 'system'
            );
        END IF;
        
        -- Track delivery statistics changes
        IF OLD.successful_deliveries != NEW.successful_deliveries THEN
            INSERT INTO order_shipping_address_history (
                shipping_address_id, order_id, store_id, change_type,
                field_name, old_value, new_value, change_source
            ) VALUES (
                NEW.id, NEW.order_id, NEW.store_id, 'delivery_successful',
                'successful_deliveries', OLD.successful_deliveries::text, NEW.successful_deliveries::text, 'system'
            );
        END IF;
        
        IF OLD.failed_deliveries != NEW.failed_deliveries THEN
            INSERT INTO order_shipping_address_history (
                shipping_address_id, order_id, store_id, change_type,
                field_name, old_value, new_value, change_source
            ) VALUES (
                NEW.id, NEW.order_id, NEW.store_id, 'delivery_failed',
                'failed_deliveries', OLD.failed_deliveries::text, NEW.failed_deliveries::text, 'system'
            );
        END IF;
        
        RETURN NEW;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_track_shipping_address_changes
    AFTER INSERT OR UPDATE ON order_shipping_addresses
    FOR EACH ROW
    EXECUTE FUNCTION track_shipping_address_changes();

-- Update delivery statistics
CREATE OR REPLACE FUNCTION update_delivery_statistics()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
        -- Update shipping address statistics based on delivery attempts
        UPDATE order_shipping_addresses 
        SET 
            successful_deliveries = (
                SELECT COUNT(*) 
                FROM order_delivery_attempts 
                WHERE shipping_address_id = NEW.shipping_address_id 
                AND status = 'delivered'
            ),
            failed_deliveries = (
                SELECT COUNT(*) 
                FROM order_delivery_attempts 
                WHERE shipping_address_id = NEW.shipping_address_id 
                AND status = 'failed'
            ),
            success_rate = (
                SELECT CASE 
                    WHEN COUNT(*) = 0 THEN 100.00
                    ELSE (COUNT(*) FILTER (WHERE status = 'delivered') * 100.0 / COUNT(*))
                END
                FROM order_delivery_attempts 
                WHERE shipping_address_id = NEW.shipping_address_id
            ),
            avg_delivery_time_hours = (
                SELECT AVG(EXTRACT(EPOCH FROM (delivered_at - scheduled_at)) / 3600)
                FROM order_delivery_attempts 
                WHERE shipping_address_id = NEW.shipping_address_id 
                AND status = 'delivered'
                AND delivered_at IS NOT NULL 
                AND scheduled_at IS NOT NULL
            )
        WHERE id = NEW.shipping_address_id;
        
        RETURN NEW;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_delivery_statistics
    AFTER INSERT OR UPDATE ON order_delivery_attempts
    FOR EACH ROW
    EXECUTE FUNCTION update_delivery_statistics();

-- Calculate address quality score
CREATE OR REPLACE FUNCTION calculate_shipping_address_quality_score()
RETURNS TRIGGER AS $$
DECLARE
    completeness DECIMAL(3,2) := 0.00;
    accuracy DECIMAL(3,2) := 0.00;
    deliverability DECIMAL(3,2) := 0.00;
    findability DECIMAL(3,2) := 0.00;
BEGIN
    -- Calculate completeness score (0.00 to 1.00)
    completeness := (
        CASE WHEN NEW.first_name IS NOT NULL AND LENGTH(NEW.first_name) > 0 THEN 0.1 ELSE 0 END +
        CASE WHEN NEW.last_name IS NOT NULL AND LENGTH(NEW.last_name) > 0 THEN 0.1 ELSE 0 END +
        CASE WHEN NEW.address_line_1 IS NOT NULL AND LENGTH(NEW.address_line_1) > 0 THEN 0.25 ELSE 0 END +
        CASE WHEN NEW.city IS NOT NULL AND LENGTH(NEW.city) > 0 THEN 0.15 ELSE 0 END +
        CASE WHEN NEW.postal_code IS NOT NULL AND LENGTH(NEW.postal_code) > 0 THEN 0.1 ELSE 0 END +
        CASE WHEN NEW.country_code IS NOT NULL AND LENGTH(NEW.country_code) > 0 THEN 0.05 ELSE 0 END +
        CASE WHEN NEW.phone IS NOT NULL AND LENGTH(NEW.phone) > 0 THEN 0.1 ELSE 0 END +
        CASE WHEN NEW.landmark IS NOT NULL AND LENGTH(NEW.landmark) > 0 THEN 0.05 ELSE 0 END +
        CASE WHEN NEW.delivery_instructions IS NOT NULL AND LENGTH(NEW.delivery_instructions) > 0 THEN 0.05 ELSE 0 END +
        CASE WHEN NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL THEN 0.05 ELSE 0 END
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
    
    -- Calculate findability score
    findability := (
        CASE WHEN NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL THEN 0.3 ELSE 0 END +
        CASE WHEN NEW.landmark IS NOT NULL AND LENGTH(NEW.landmark) > 0 THEN 0.2 ELSE 0 END +
        CASE WHEN NEW.delivery_instructions IS NOT NULL AND LENGTH(NEW.delivery_instructions) > 0 THEN 0.2 ELSE 0 END +
        CASE WHEN NEW.building_type IS NOT NULL THEN 0.1 ELSE 0 END +
        CASE WHEN NEW.floor_number IS NOT NULL THEN 0.1 ELSE 0 END +
        CASE WHEN NEW.apartment_number IS NOT NULL THEN 0.1 ELSE 0 END
    );
    
    -- Update scores
    NEW.completeness_score := completeness;
    NEW.accuracy_score := accuracy;
    NEW.deliverability_score := deliverability;
    NEW.findability_score := findability;
    NEW.quality_score := (completeness + accuracy + deliverability + findability) / 4.0;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_calculate_shipping_address_quality_score
    BEFORE INSERT OR UPDATE ON order_shipping_addresses
    FOR EACH ROW
    EXECUTE FUNCTION calculate_shipping_address_quality_score();

-- =============================================================================
-- Helper Functions
-- =============================================================================

/**
 * Get shipping address for order
 * @param p_order_id UUID - Order ID
 * @return TABLE - Shipping address information
 */
CREATE OR REPLACE FUNCTION get_order_shipping_address(
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
    delivery_instructions TEXT,
    is_verified BOOLEAN,
    quality_score DECIMAL,
    success_rate DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        osa.id as address_id,
        CONCAT(osa.first_name, ' ', osa.last_name) as full_name,
        osa.company,
        CONCAT(
            osa.address_line_1,
            CASE WHEN osa.address_line_2 IS NOT NULL THEN ', ' || osa.address_line_2 ELSE '' END,
            CASE WHEN osa.landmark IS NOT NULL THEN ' (' || osa.landmark || ')' ELSE '' END
        ) as full_address,
        osa.city,
        osa.state,
        osa.postal_code,
        osa.country_name,
        osa.phone,
        osa.email,
        osa.delivery_instructions,
        osa.is_verified,
        osa.quality_score,
        osa.success_rate
    FROM order_shipping_addresses osa
    WHERE osa.order_id = p_order_id;
END;
$$ LANGUAGE plpgsql;

/**
 * Record delivery attempt
 * @param p_shipping_address_id UUID - Shipping address ID
 * @param p_carrier VARCHAR - Carrier name
 * @param p_status VARCHAR - Attempt status
 * @param p_notes TEXT - Delivery notes
 * @return UUID - Delivery attempt ID
 */
CREATE OR REPLACE FUNCTION record_delivery_attempt(
    p_shipping_address_id UUID,
    p_carrier VARCHAR DEFAULT NULL,
    p_status VARCHAR DEFAULT 'scheduled',
    p_notes TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    attempt_id UUID;
    address_record order_shipping_addresses;
    next_attempt_number INTEGER;
BEGIN
    -- Get address record
    SELECT * INTO address_record 
    FROM order_shipping_addresses 
    WHERE id = p_shipping_address_id;
    
    IF address_record.id IS NULL THEN
        RAISE EXCEPTION 'Shipping address not found';
    END IF;
    
    -- Get next attempt number
    SELECT COALESCE(MAX(attempt_number), 0) + 1 INTO next_attempt_number
    FROM order_delivery_attempts
    WHERE shipping_address_id = p_shipping_address_id;
    
    -- Insert delivery attempt
    INSERT INTO order_delivery_attempts (
        shipping_address_id, order_id, store_id, attempt_number,
        carrier, status, driver_notes, attempted_at
    ) VALUES (
        p_shipping_address_id, address_record.order_id, address_record.store_id,
        next_attempt_number, p_carrier, p_status, p_notes,
        CASE WHEN p_status IN ('attempted', 'delivered', 'failed') THEN CURRENT_TIMESTAMP ELSE NULL END
    ) RETURNING id INTO attempt_id;
    
    -- Update address usage
    UPDATE order_shipping_addresses 
    SET 
        usage_count = usage_count + 1,
        last_used_at = CURRENT_TIMESTAMP
    WHERE id = p_shipping_address_id;
    
    RETURN attempt_id;
END;
$$ LANGUAGE plpgsql;

/**
 * Get delivery performance for address
 * @param p_shipping_address_id UUID - Shipping address ID
 * @return JSONB - Delivery performance metrics
 */
CREATE OR REPLACE FUNCTION get_delivery_performance(
    p_shipping_address_id UUID
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_attempts', COUNT(*),
        'successful_deliveries', COUNT(*) FILTER (WHERE status = 'delivered'),
        'failed_deliveries', COUNT(*) FILTER (WHERE status = 'failed'),
        'success_rate', CASE 
            WHEN COUNT(*) = 0 THEN 0
            ELSE (COUNT(*) FILTER (WHERE status = 'delivered') * 100.0 / COUNT(*))
        END,
        'avg_delivery_time_hours', AVG(
            EXTRACT(EPOCH FROM (delivered_at - scheduled_at)) / 3600
        ) FILTER (WHERE status = 'delivered' AND delivered_at IS NOT NULL AND scheduled_at IS NOT NULL),
        'carriers_used', (
            SELECT jsonb_agg(DISTINCT carrier)
            FROM order_delivery_attempts
            WHERE shipping_address_id = p_shipping_address_id
            AND carrier IS NOT NULL
        ),
        'common_failure_reasons', (
            SELECT jsonb_object_agg(failure_reason, reason_count)
            FROM (
                SELECT failure_reason, COUNT(*) as reason_count
                FROM order_delivery_attempts
                WHERE shipping_address_id = p_shipping_address_id
                AND status = 'failed'
                AND failure_reason IS NOT NULL
                GROUP BY failure_reason
                ORDER BY reason_count DESC
                LIMIT 5
            ) failure_stats
        ),
        'last_attempt_date', MAX(attempted_at),
        'last_successful_delivery', MAX(delivered_at) FILTER (WHERE status = 'delivered')
    ) INTO result
    FROM order_delivery_attempts
    WHERE shipping_address_id = p_shipping_address_id;
    
    RETURN COALESCE(result, '{"error": "No delivery attempts found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

/**
 * Get shipping address statistics for store
 * @param p_store_id UUID - Store ID
 * @return JSONB - Address statistics
 */
CREATE OR REPLACE FUNCTION get_shipping_address_stats(
    p_store_id UUID
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_addresses', COUNT(*),
        'verified_addresses', COUNT(*) FILTER (WHERE is_verified = TRUE),
        'high_quality_addresses', COUNT(*) FILTER (WHERE quality_score >= 0.80),
        'valid_addresses', COUNT(*) FILTER (WHERE validation_status = 'valid'),
        'business_addresses', COUNT(*) FILTER (WHERE company IS NOT NULL),
        'residential_addresses', COUNT(*) FILTER (WHERE building_type = 'residential'),
        'addresses_with_coordinates', COUNT(*) FILTER (WHERE latitude IS NOT NULL AND longitude IS NOT NULL),
        'addresses_requiring_appointment', COUNT(*) FILTER (WHERE requires_appointment = TRUE),
        'addresses_allowing_safe_drop', COUNT(*) FILTER (WHERE allows_safe_drop = TRUE),
        'avg_quality_score', AVG(quality_score),
        'avg_completeness_score', AVG(completeness_score),
        'avg_accuracy_score', AVG(accuracy_score),
        'avg_deliverability_score', AVG(deliverability_score),
        'avg_findability_score', AVG(findability_score),
        'avg_success_rate', AVG(success_rate),
        'avg_delivery_time_hours', AVG(avg_delivery_time_hours),
        'validation_statuses', (
            SELECT jsonb_object_agg(validation_status, status_count)
            FROM (
                SELECT validation_status, COUNT(*) as status_count
                FROM order_shipping_addresses
                WHERE store_id = p_store_id
                GROUP BY validation_status
            ) status_stats
        ),
        'countries', (
            SELECT jsonb_object_agg(country_code, country_count)
            FROM (
                SELECT country_code, COUNT(*) as country_count
                FROM order_shipping_addresses
                WHERE store_id = p_store_id
                GROUP BY country_code
            ) country_stats
        ),
        'building_types', (
            SELECT jsonb_object_agg(building_type, type_count)
            FROM (
                SELECT building_type, COUNT(*) as type_count
                FROM order_shipping_addresses
                WHERE store_id = p_store_id AND building_type IS NOT NULL
                GROUP BY building_type
            ) type_stats
        ),
        'shipping_zones', (
            SELECT jsonb_object_agg(shipping_zone, zone_count)
            FROM (
                SELECT shipping_zone, COUNT(*) as zone_count
                FROM order_shipping_addresses
                WHERE store_id = p_store_id AND shipping_zone IS NOT NULL
                GROUP BY shipping_zone
            ) zone_stats
        )
    ) INTO result
    FROM order_shipping_addresses
    WHERE store_id = p_store_id;
    
    RETURN COALESCE(result, '{"error": "No addresses found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Comments
-- =============================================================================

COMMENT ON TABLE order_shipping_addresses IS 'Normalized shipping addresses from orders.shipping_address JSONB column';
COMMENT ON TABLE order_shipping_address_history IS 'Track changes to order shipping addresses';
COMMENT ON TABLE order_delivery_attempts IS 'Track delivery attempts for shipping addresses';

COMMENT ON COLUMN order_shipping_addresses.salla_address_id IS 'Address ID from Salla platform';
COMMENT ON COLUMN order_shipping_addresses.quality_score IS 'Overall address quality score (0.00 to 1.00)';
COMMENT ON COLUMN order_shipping_addresses.validation_status IS 'Address validation status';
COMMENT ON COLUMN order_shipping_addresses.success_rate IS 'Successful delivery rate for this address';
COMMENT ON COLUMN order_shipping_addresses.findability_score IS 'How easy it is to find this address';

COMMENT ON FUNCTION get_order_shipping_address(UUID) IS 'Get shipping address for order';
COMMENT ON FUNCTION record_delivery_attempt(UUID, VARCHAR, VARCHAR, TEXT) IS 'Record delivery attempt';
COMMENT ON FUNCTION get_delivery_performance(UUID) IS 'Get delivery performance for address';
COMMENT ON FUNCTION get_shipping_address_stats(UUID) IS 'Get shipping address statistics for store';