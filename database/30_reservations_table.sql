-- =====================================================
-- Reservations Table
-- =====================================================
-- This table stores product reservations and booking information
-- for services, appointments, and time-sensitive products

CREATE TABLE IF NOT EXISTS reservations (
    -- Primary identification
    id BIGSERIAL PRIMARY KEY,
    salla_reservation_id VARCHAR UNIQUE, -- Salla reservation ID if available
    
    -- Store relationship
    store_id BIGINT NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Customer information
    customer_id BIGINT REFERENCES customers(id) ON DELETE SET NULL,
    customer_name VARCHAR(255) NOT NULL,
    customer_email VARCHAR(255),
    customer_phone VARCHAR(50),
    customer_notes TEXT,
    
    -- Product/Service information
    product_id BIGINT REFERENCES products(id) ON DELETE SET NULL,
    product_name VARCHAR(255) NOT NULL,
    product_sku VARCHAR(255),
    service_type VARCHAR(100), -- appointment, booking, rental, event
    category_id BIGINT REFERENCES categories(id) ON DELETE SET NULL,
    
    -- Reservation details
    reservation_number VARCHAR(100) UNIQUE NOT NULL,
    reservation_status VARCHAR(50) DEFAULT 'pending' CHECK (reservation_status IN (
        'pending', 'confirmed', 'cancelled', 'completed', 'no_show', 'rescheduled'
    )),
    
    -- Time and duration
    reservation_date DATE NOT NULL,
    reservation_time TIME,
    start_datetime TIMESTAMPTZ,
    end_datetime TIMESTAMPTZ,
    duration_minutes INTEGER,
    timezone VARCHAR(100) DEFAULT 'Asia/Riyadh',
    
    -- Capacity and quantity
    reserved_quantity INTEGER DEFAULT 1,
    max_capacity INTEGER,
    available_spots INTEGER,
    group_size INTEGER DEFAULT 1,
    
    -- Pricing information
    unit_price DECIMAL(15,2) NOT NULL,
    total_price DECIMAL(15,2) NOT NULL,
    deposit_amount DECIMAL(15,2) DEFAULT 0,
    remaining_amount DECIMAL(15,2),
    currency_code VARCHAR(3) DEFAULT 'SAR',
    
    -- Payment information
    payment_status VARCHAR(50) DEFAULT 'pending' CHECK (payment_status IN (
        'pending', 'partial', 'paid', 'refunded', 'failed'
    )),
    payment_method VARCHAR(100),
    payment_reference VARCHAR(255),
    paid_amount DECIMAL(15,2) DEFAULT 0,
    refund_amount DECIMAL(15,2) DEFAULT 0,
    
    -- Location information
    location_type VARCHAR(50) DEFAULT 'physical', -- physical, virtual, hybrid
    venue_name VARCHAR(255),
    venue_address TEXT,
    venue_city VARCHAR(100),
    venue_country VARCHAR(100),
    venue_coordinates POINT,
    virtual_meeting_link TEXT,
    virtual_meeting_id VARCHAR(255),
    room_number VARCHAR(50),
    
    -- Staff assignment
    assigned_staff_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
    staff_name VARCHAR(255),
    staff_email VARCHAR(255),
    staff_phone VARCHAR(50),
    staff_notes TEXT,
    
    -- Booking rules and policies
    cancellation_policy TEXT,
    rescheduling_policy TEXT,
    no_show_policy TEXT,
    advance_booking_hours INTEGER DEFAULT 24,
    cancellation_deadline_hours INTEGER DEFAULT 24,
    
    -- Confirmation and notifications
    confirmation_sent_at TIMESTAMPTZ,
    reminder_sent_at TIMESTAMPTZ,
    follow_up_sent_at TIMESTAMPTZ,
    confirmation_method VARCHAR(50), -- email, sms, phone
    reminder_preferences JSONB DEFAULT '{"email": true, "sms": false}'::jsonb,
    
    -- Recurring reservations
    is_recurring BOOLEAN DEFAULT FALSE,
    recurrence_pattern VARCHAR(50), -- daily, weekly, monthly, custom
    recurrence_interval INTEGER DEFAULT 1,
    recurrence_end_date DATE,
    parent_reservation_id BIGINT REFERENCES reservations(id) ON DELETE SET NULL,
    
    -- Special requirements
    special_requests TEXT,
    accessibility_needs TEXT,
    dietary_restrictions TEXT,
    equipment_needed JSONB DEFAULT '[]'::jsonb,
    additional_services JSONB DEFAULT '[]'::jsonb,
    
    -- Check-in/Check-out
    check_in_time TIMESTAMPTZ,
    check_out_time TIMESTAMPTZ,
    actual_start_time TIMESTAMPTZ,
    actual_end_time TIMESTAMPTZ,
    check_in_method VARCHAR(50), -- qr_code, manual, app
    
    -- Rating and feedback
    customer_rating INTEGER CHECK (customer_rating >= 1 AND customer_rating <= 5),
    customer_feedback TEXT,
    staff_rating INTEGER CHECK (staff_rating >= 1 AND staff_rating <= 5),
    staff_feedback TEXT,
    service_quality_score DECIMAL(3,2),
    
    -- Marketing and attribution
    booking_source VARCHAR(100), -- website, app, phone, walk_in, partner
    utm_source VARCHAR(255),
    utm_medium VARCHAR(255),
    utm_campaign VARCHAR(255),
    referral_code VARCHAR(100),
    affiliate_id BIGINT REFERENCES affiliates(id) ON DELETE SET NULL,
    
    -- Inventory and resources
    reserved_resources JSONB DEFAULT '[]'::jsonb,
    equipment_assigned JSONB DEFAULT '[]'::jsonb,
    inventory_items JSONB DEFAULT '[]'::jsonb,
    resource_cost DECIMAL(15,2) DEFAULT 0,
    
    -- Weather and external factors (for outdoor services)
    weather_dependent BOOLEAN DEFAULT FALSE,
    weather_conditions VARCHAR(100),
    backup_plan TEXT,
    
    -- Communication history
    communication_log JSONB DEFAULT '[]'::jsonb,
    last_contact_at TIMESTAMPTZ,
    contact_attempts INTEGER DEFAULT 0,
    
    -- Business metrics
    lead_time_hours INTEGER, -- Hours between booking and service
    preparation_time_minutes INTEGER,
    cleanup_time_minutes INTEGER,
    utilization_rate DECIMAL(5,2),
    
    -- Risk and compliance
    risk_level VARCHAR(20) DEFAULT 'low' CHECK (risk_level IN ('low', 'medium', 'high')),
    insurance_required BOOLEAN DEFAULT FALSE,
    liability_waiver_signed BOOLEAN DEFAULT FALSE,
    age_restriction INTEGER,
    health_requirements TEXT,
    
    -- Integration and sync
    external_reservation_id VARCHAR(255),
    calendar_event_id VARCHAR(255),
    sync_status VARCHAR(50) DEFAULT 'synced',
    last_sync_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Analytics and insights
    customer_segment VARCHAR(100),
    booking_value_segment VARCHAR(50), -- low, medium, high, premium
    seasonal_demand_factor DECIMAL(3,2),
    peak_time_booking BOOLEAN DEFAULT FALSE,
    
    -- Custom fields for extensibility
    custom_fields JSONB DEFAULT '{}'::jsonb,
    tags JSONB DEFAULT '[]'::jsonb,
    internal_notes TEXT,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    confirmed_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ
);

-- =====================================================
-- Indexes for Performance
-- =====================================================

-- Primary indexes
CREATE INDEX IF NOT EXISTS idx_reservations_store_id ON reservations(store_id);
CREATE INDEX IF NOT EXISTS idx_reservations_salla_reservation_id ON reservations(salla_reservation_id);
CREATE INDEX IF NOT EXISTS idx_reservations_customer_id ON reservations(customer_id);
CREATE INDEX IF NOT EXISTS idx_reservations_product_id ON reservations(product_id);
CREATE INDEX IF NOT EXISTS idx_reservations_number ON reservations(reservation_number);

-- Status indexes
CREATE INDEX IF NOT EXISTS idx_reservations_status ON reservations(reservation_status);
CREATE INDEX IF NOT EXISTS idx_reservations_payment_status ON reservations(payment_status);
CREATE INDEX IF NOT EXISTS idx_reservations_service_type ON reservations(service_type);

-- Time-based indexes
CREATE INDEX IF NOT EXISTS idx_reservations_date ON reservations(reservation_date);
CREATE INDEX IF NOT EXISTS idx_reservations_start_datetime ON reservations(start_datetime);
CREATE INDEX IF NOT EXISTS idx_reservations_end_datetime ON reservations(end_datetime);
CREATE INDEX IF NOT EXISTS idx_reservations_created_at ON reservations(created_at);

-- Staff and location indexes
CREATE INDEX IF NOT EXISTS idx_reservations_assigned_staff ON reservations(assigned_staff_id);
CREATE INDEX IF NOT EXISTS idx_reservations_venue_city ON reservations(venue_city);
CREATE INDEX IF NOT EXISTS idx_reservations_location_type ON reservations(location_type);

-- Customer contact indexes
CREATE INDEX IF NOT EXISTS idx_reservations_customer_email ON reservations(customer_email);
CREATE INDEX IF NOT EXISTS idx_reservations_customer_phone ON reservations(customer_phone);

-- Business metrics indexes
CREATE INDEX IF NOT EXISTS idx_reservations_total_price ON reservations(total_price);
CREATE INDEX IF NOT EXISTS idx_reservations_booking_source ON reservations(booking_source);
CREATE INDEX IF NOT EXISTS idx_reservations_customer_rating ON reservations(customer_rating);

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_reservations_store_date ON reservations(store_id, reservation_date);
CREATE INDEX IF NOT EXISTS idx_reservations_store_status ON reservations(store_id, reservation_status);
CREATE INDEX IF NOT EXISTS idx_reservations_staff_date ON reservations(assigned_staff_id, reservation_date);
CREATE INDEX IF NOT EXISTS idx_reservations_customer_status ON reservations(customer_id, reservation_status);
CREATE INDEX IF NOT EXISTS idx_reservations_product_date ON reservations(product_id, reservation_date);

-- Time range queries
CREATE INDEX IF NOT EXISTS idx_reservations_datetime_range ON reservations(start_datetime, end_datetime);
CREATE INDEX IF NOT EXISTS idx_reservations_store_datetime_range ON reservations(store_id, start_datetime, end_datetime);

-- JSONB indexes
CREATE INDEX IF NOT EXISTS idx_reservations_custom_fields_gin ON reservations USING GIN(custom_fields);
CREATE INDEX IF NOT EXISTS idx_reservations_tags_gin ON reservations USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_reservations_equipment_gin ON reservations USING GIN(equipment_needed);
CREATE INDEX IF NOT EXISTS idx_reservations_communication_gin ON reservations USING GIN(communication_log);

-- Spatial index for location-based queries
CREATE INDEX IF NOT EXISTS idx_reservations_venue_coordinates ON reservations USING GIST(venue_coordinates);

-- =====================================================
-- Unique Constraints
-- =====================================================

-- Ensure unique reservation numbers per store
CREATE UNIQUE INDEX IF NOT EXISTS idx_reservations_unique_number_store 
    ON reservations(store_id, reservation_number);

-- Prevent double booking for same resource at same time
CREATE UNIQUE INDEX IF NOT EXISTS idx_reservations_unique_resource_time 
    ON reservations(store_id, assigned_staff_id, start_datetime, end_datetime)
    WHERE reservation_status IN ('confirmed', 'pending') AND assigned_staff_id IS NOT NULL;

-- =====================================================
-- Triggers
-- =====================================================

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_reservations_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_reservations_updated_at
    BEFORE UPDATE ON reservations
    FOR EACH ROW
    EXECUTE FUNCTION update_reservations_updated_at();

-- Trigger to generate reservation number
CREATE OR REPLACE FUNCTION generate_reservation_number()
RETURNS TRIGGER AS $$
DECLARE
    new_number VARCHAR(100);
    counter INTEGER;
BEGIN
    IF NEW.reservation_number IS NULL OR NEW.reservation_number = '' THEN
        -- Generate reservation number: RES-YYYYMMDD-NNNN
        SELECT COALESCE(MAX(CAST(SUBSTRING(reservation_number FROM 'RES-\d{8}-(\d+)') AS INTEGER)), 0) + 1
        INTO counter
        FROM reservations 
        WHERE store_id = NEW.store_id 
            AND reservation_number LIKE 'RES-' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '-%';
        
        new_number := 'RES-' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '-' || LPAD(counter::TEXT, 4, '0');
        NEW.reservation_number := new_number;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_generate_reservation_number
    BEFORE INSERT ON reservations
    FOR EACH ROW
    EXECUTE FUNCTION generate_reservation_number();

-- Trigger to set status timestamps
CREATE OR REPLACE FUNCTION set_reservation_status_timestamps()
RETURNS TRIGGER AS $$
BEGIN
    -- Set confirmed_at when status changes to confirmed
    IF NEW.reservation_status = 'confirmed' AND OLD.reservation_status != 'confirmed' THEN
        NEW.confirmed_at = CURRENT_TIMESTAMP;
    END IF;
    
    -- Set cancelled_at when status changes to cancelled
    IF NEW.reservation_status = 'cancelled' AND OLD.reservation_status != 'cancelled' THEN
        NEW.cancelled_at = CURRENT_TIMESTAMP;
    END IF;
    
    -- Set completed_at when status changes to completed
    IF NEW.reservation_status = 'completed' AND OLD.reservation_status != 'completed' THEN
        NEW.completed_at = CURRENT_TIMESTAMP;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_reservation_status_timestamps
    BEFORE UPDATE ON reservations
    FOR EACH ROW
    EXECUTE FUNCTION set_reservation_status_timestamps();

-- Trigger to calculate remaining amount
CREATE OR REPLACE FUNCTION calculate_reservation_amounts()
RETURNS TRIGGER AS $$
BEGIN
    -- Calculate remaining amount
    NEW.remaining_amount = NEW.total_price - COALESCE(NEW.paid_amount, 0) - COALESCE(NEW.deposit_amount, 0);
    
    -- Calculate lead time
    IF NEW.start_datetime IS NOT NULL THEN
        NEW.lead_time_hours = EXTRACT(EPOCH FROM (NEW.start_datetime - NEW.created_at)) / 3600;
    END IF;
    
    -- Set peak time booking flag
    IF NEW.start_datetime IS NOT NULL THEN
        NEW.peak_time_booking = (
            EXTRACT(HOUR FROM NEW.start_datetime) BETWEEN 9 AND 17 AND
            EXTRACT(DOW FROM NEW.start_datetime) BETWEEN 1 AND 5
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_calculate_reservation_amounts
    BEFORE INSERT OR UPDATE ON reservations
    FOR EACH ROW
    EXECUTE FUNCTION calculate_reservation_amounts();

-- =====================================================
-- Helper Functions
-- =====================================================

-- Function to get reservation statistics for a store
CREATE OR REPLACE FUNCTION get_reservation_stats(store_id_param BIGINT)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'store_id', store_id_param,
        'total_reservations', COUNT(*),
        'total_revenue', COALESCE(SUM(total_price), 0),
        'average_booking_value', COALESCE(AVG(total_price), 0),
        'completion_rate', CASE 
            WHEN COUNT(*) > 0 THEN 
                (COUNT(*) FILTER (WHERE reservation_status = 'completed')::DECIMAL / COUNT(*)) * 100
            ELSE 0
        END,
        'no_show_rate', CASE 
            WHEN COUNT(*) > 0 THEN 
                (COUNT(*) FILTER (WHERE reservation_status = 'no_show')::DECIMAL / COUNT(*)) * 100
            ELSE 0
        END,
        'cancellation_rate', CASE 
            WHEN COUNT(*) > 0 THEN 
                (COUNT(*) FILTER (WHERE reservation_status = 'cancelled')::DECIMAL / COUNT(*)) * 100
            ELSE 0
        END,
        'reservations_by_status', jsonb_object_agg(reservation_status, status_count),
        'reservations_by_service_type', (
            SELECT jsonb_object_agg(service_type, type_count)
            FROM (
                SELECT service_type, COUNT(*) as type_count
                FROM reservations 
                WHERE store_id = store_id_param AND service_type IS NOT NULL
                GROUP BY service_type
            ) type_stats
        ),
        'average_lead_time_hours', COALESCE(AVG(lead_time_hours), 0),
        'peak_time_bookings_percentage', CASE 
            WHEN COUNT(*) > 0 THEN 
                (COUNT(*) FILTER (WHERE peak_time_booking = TRUE)::DECIMAL / COUNT(*)) * 100
            ELSE 0
        END,
        'average_customer_rating', COALESCE(AVG(customer_rating), 0),
        'monthly_trend', (
            SELECT jsonb_agg(jsonb_build_object(
                'month', booking_month,
                'count', monthly_count,
                'revenue', monthly_revenue
            ))
            FROM (
                SELECT 
                    TO_CHAR(reservation_date, 'YYYY-MM') as booking_month,
                    COUNT(*) as monthly_count,
                    SUM(total_price) as monthly_revenue
                FROM reservations 
                WHERE store_id = store_id_param 
                    AND reservation_date >= CURRENT_DATE - INTERVAL '12 months'
                GROUP BY TO_CHAR(reservation_date, 'YYYY-MM')
                ORDER BY booking_month DESC
                LIMIT 12
            ) trend_data
        )
    ) INTO result
    FROM (
        SELECT reservation_status, COUNT(*) as status_count
        FROM reservations 
        WHERE store_id = store_id_param
        GROUP BY reservation_status
    ) status_stats;
    
    RETURN COALESCE(result, '{"error": "No data found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- Function to search reservations with filters
CREATE OR REPLACE FUNCTION search_reservations(
    store_id_param BIGINT DEFAULT NULL,
    reservation_status_param VARCHAR DEFAULT NULL,
    service_type_param VARCHAR DEFAULT NULL,
    customer_email_param VARCHAR DEFAULT NULL,
    staff_id_param BIGINT DEFAULT NULL,
    date_from DATE DEFAULT NULL,
    date_to DATE DEFAULT NULL,
    limit_param INTEGER DEFAULT 50,
    offset_param INTEGER DEFAULT 0
)
RETURNS TABLE (
    reservation_id BIGINT,
    reservation_number VARCHAR,
    customer_name VARCHAR,
    customer_email VARCHAR,
    product_name VARCHAR,
    reservation_date DATE,
    reservation_time TIME,
    total_price DECIMAL,
    reservation_status VARCHAR,
    staff_name VARCHAR,
    reservation_details JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.id as reservation_id,
        r.reservation_number,
        r.customer_name,
        r.customer_email,
        r.product_name,
        r.reservation_date,
        r.reservation_time,
        r.total_price,
        r.reservation_status,
        r.staff_name,
        jsonb_build_object(
            'service_type', r.service_type,
            'duration_minutes', r.duration_minutes,
            'venue_name', r.venue_name,
            'payment_status', r.payment_status,
            'special_requests', r.special_requests,
            'customer_rating', r.customer_rating
        ) as reservation_details
    FROM reservations r
    WHERE 
        (store_id_param IS NULL OR r.store_id = store_id_param)
        AND (reservation_status_param IS NULL OR r.reservation_status = reservation_status_param)
        AND (service_type_param IS NULL OR r.service_type = service_type_param)
        AND (customer_email_param IS NULL OR r.customer_email ILIKE '%' || customer_email_param || '%')
        AND (staff_id_param IS NULL OR r.assigned_staff_id = staff_id_param)
        AND (date_from IS NULL OR r.reservation_date >= date_from)
        AND (date_to IS NULL OR r.reservation_date <= date_to)
    ORDER BY r.reservation_date DESC, r.reservation_time DESC
    LIMIT limit_param OFFSET offset_param;
END;
$$ LANGUAGE plpgsql;

-- Function to get staff schedule
CREATE OR REPLACE FUNCTION get_staff_schedule(
    staff_id_param BIGINT,
    date_from DATE DEFAULT CURRENT_DATE,
    date_to DATE DEFAULT CURRENT_DATE + INTERVAL '7 days'
)
RETURNS TABLE (
    reservation_id BIGINT,
    reservation_number VARCHAR,
    customer_name VARCHAR,
    service_type VARCHAR,
    start_datetime TIMESTAMPTZ,
    end_datetime TIMESTAMPTZ,
    duration_minutes INTEGER,
    status VARCHAR,
    venue_name VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.id as reservation_id,
        r.reservation_number,
        r.customer_name,
        r.service_type,
        r.start_datetime,
        r.end_datetime,
        r.duration_minutes,
        r.reservation_status as status,
        r.venue_name
    FROM reservations r
    WHERE 
        r.assigned_staff_id = staff_id_param
        AND r.reservation_date BETWEEN date_from AND date_to
        AND r.reservation_status IN ('confirmed', 'pending')
    ORDER BY r.start_datetime;
END;
$$ LANGUAGE plpgsql;

-- Function to check availability
CREATE OR REPLACE FUNCTION check_availability(
    store_id_param BIGINT,
    staff_id_param BIGINT DEFAULT NULL,
    start_datetime_param TIMESTAMPTZ,
    end_datetime_param TIMESTAMPTZ
)
RETURNS BOOLEAN AS $$
DECLARE
    conflict_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO conflict_count
    FROM reservations
    WHERE 
        store_id = store_id_param
        AND (staff_id_param IS NULL OR assigned_staff_id = staff_id_param)
        AND reservation_status IN ('confirmed', 'pending')
        AND (
            (start_datetime <= start_datetime_param AND end_datetime > start_datetime_param) OR
            (start_datetime < end_datetime_param AND end_datetime >= end_datetime_param) OR
            (start_datetime >= start_datetime_param AND end_datetime <= end_datetime_param)
        );
    
    RETURN conflict_count = 0;
END;
$$ LANGUAGE plpgsql;

-- Function to update reservation status
CREATE OR REPLACE FUNCTION update_reservation_status(
    reservation_id_param BIGINT,
    new_status VARCHAR,
    notes TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE reservations 
    SET 
        reservation_status = new_status,
        internal_notes = CASE 
            WHEN notes IS NOT NULL THEN 
                COALESCE(internal_notes, '') || '\n' || TO_CHAR(CURRENT_TIMESTAMP, 'YYYY-MM-DD HH24:MI') || ': ' || notes
            ELSE internal_notes
        END,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = reservation_id_param;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Comments for Documentation
-- =====================================================

COMMENT ON TABLE reservations IS 'Stores product reservations and booking information for services and appointments';
COMMENT ON COLUMN reservations.salla_reservation_id IS 'Unique reservation identifier from Salla platform';
COMMENT ON COLUMN reservations.reservation_number IS 'Human-readable reservation number for customer reference';
COMMENT ON COLUMN reservations.service_type IS 'Type of service being reserved (appointment, booking, rental, event)';
COMMENT ON COLUMN reservations.location_type IS 'Whether the service is physical, virtual, or hybrid';
COMMENT ON COLUMN reservations.recurrence_pattern IS 'Pattern for recurring reservations';
COMMENT ON COLUMN reservations.custom_fields IS 'Additional custom data in JSON format';

COMMENT ON FUNCTION get_reservation_stats(BIGINT) IS 'Get comprehensive reservation statistics for a store';
COMMENT ON FUNCTION search_reservations(BIGINT, VARCHAR, VARCHAR, VARCHAR, BIGINT, DATE, DATE, INTEGER, INTEGER) IS 'Search reservations with various filters';
COMMENT ON FUNCTION get_staff_schedule(BIGINT, DATE, DATE) IS 'Get staff schedule for a date range';
COMMENT ON FUNCTION check_availability(BIGINT, BIGINT, TIMESTAMPTZ, TIMESTAMPTZ) IS 'Check if a time slot is available for booking';
COMMENT ON FUNCTION update_reservation_status(BIGINT, VARCHAR, TEXT) IS 'Update reservation status with optional notes';

RAISE NOTICE 'Reservations table created successfully!';