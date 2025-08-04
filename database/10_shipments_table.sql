-- =============================================
-- Shipments Table
-- =============================================
-- This table stores information about actual shipments
-- and tracks their delivery status

CREATE TABLE shipments (
    -- Primary key
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Foreign key to stores table
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Foreign key to orders table
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    
    -- Foreign key to shipping company
    shipping_company_id UUID REFERENCES shipping_companies(id) ON DELETE SET NULL,
    
    -- Salla API identifiers
    salla_shipment_id VARCHAR(255),
    
    -- Shipment identification
    shipment_number VARCHAR(255) UNIQUE,
    tracking_number VARCHAR(255),
    reference_number VARCHAR(255),
    
    -- Shipping company details (snapshot at time of shipment)
    shipping_company_name VARCHAR(255),
    shipping_company_code VARCHAR(100),
    shipping_service_type VARCHAR(100), -- express, standard, economy
    
    -- Shipment status
    status VARCHAR(50) DEFAULT 'pending', -- pending, picked_up, in_transit, out_for_delivery, delivered, failed, returned
    sub_status VARCHAR(100), -- More detailed status from shipping company
    
    -- Important dates
    created_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    pickup_date TIMESTAMP WITH TIME ZONE,
    shipped_date TIMESTAMP WITH TIME ZONE,
    estimated_delivery_date TIMESTAMP WITH TIME ZONE,
    actual_delivery_date TIMESTAMP WITH TIME ZONE,
    
    -- Addresses (snapshots at time of shipment)
    pickup_address JSONB DEFAULT '{}'::jsonb,
    delivery_address JSONB DEFAULT '{}'::jsonb,
    
    -- Package details
    package_count INTEGER DEFAULT 1,
    total_weight DECIMAL(10,2),
    total_volume DECIMAL(10,2),
    dimensions JSONB DEFAULT '{}'::jsonb, -- {"length": 30, "width": 20, "height": 10}
    
    -- Items in shipment
    items JSONB DEFAULT '[]'::jsonb, -- Array of {"product_id": "...", "quantity": 2, "sku": "..."}
    
    -- Shipping costs
    shipping_cost DECIMAL(10,2) DEFAULT 0.00,
    insurance_cost DECIMAL(10,2) DEFAULT 0.00,
    cod_amount DECIMAL(10,2) DEFAULT 0.00, -- Cash on delivery amount
    currency VARCHAR(3) DEFAULT 'SAR',
    
    -- Delivery details
    delivery_instructions TEXT,
    delivery_notes TEXT,
    recipient_name VARCHAR(255),
    recipient_phone VARCHAR(50),
    signature_required BOOLEAN DEFAULT false,
    
    -- Delivery confirmation
    delivered_to VARCHAR(255), -- Name of person who received
    delivery_signature TEXT, -- Base64 encoded signature or signature URL
    delivery_photo_url TEXT, -- Photo proof of delivery
    
    -- Tracking and updates
    tracking_url TEXT,
    last_tracking_update TIMESTAMP WITH TIME ZONE,
    tracking_events JSONB DEFAULT '[]'::jsonb, -- Array of tracking events
    
    -- Return and exchange
    is_return BOOLEAN DEFAULT false,
    return_reason VARCHAR(255),
    original_shipment_id UUID REFERENCES shipments(id),
    
    -- Special handling
    is_fragile BOOLEAN DEFAULT false,
    is_perishable BOOLEAN DEFAULT false,
    requires_signature BOOLEAN DEFAULT false,
    requires_id_check BOOLEAN DEFAULT false,
    
    -- Notifications
    customer_notified BOOLEAN DEFAULT false,
    notification_sent_at TIMESTAMP WITH TIME ZONE,
    sms_notifications_enabled BOOLEAN DEFAULT true,
    email_notifications_enabled BOOLEAN DEFAULT true,
    
    -- Issues and problems
    has_issues BOOLEAN DEFAULT false,
    issues JSONB DEFAULT '[]'::jsonb, -- Array of issue descriptions
    resolution_notes TEXT,
    
    -- Rating and feedback
    customer_rating INTEGER CHECK (customer_rating >= 1 AND customer_rating <= 5),
    customer_feedback TEXT,
    
    -- Internal notes
    internal_notes TEXT,
    
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
CREATE INDEX idx_shipments_store_id ON shipments(store_id);

-- Index on order_id for finding shipments by order
CREATE INDEX idx_shipments_order_id ON shipments(order_id);

-- Index on shipping_company_id
CREATE INDEX idx_shipments_company_id ON shipments(shipping_company_id);

-- Index on salla_shipment_id for API sync
CREATE INDEX idx_shipments_salla_id ON shipments(salla_shipment_id);

-- Index on shipment_number for unique lookups
CREATE UNIQUE INDEX idx_shipments_number ON shipments(shipment_number);

-- Index on tracking_number for tracking lookups
CREATE INDEX idx_shipments_tracking_number ON shipments(tracking_number);

-- Index on status for filtering
CREATE INDEX idx_shipments_status ON shipments(status);

-- Index on important dates
CREATE INDEX idx_shipments_created_date ON shipments(created_date);
CREATE INDEX idx_shipments_pickup_date ON shipments(pickup_date);
CREATE INDEX idx_shipments_delivery_date ON shipments(actual_delivery_date);

-- Index on return shipments
CREATE INDEX idx_shipments_returns ON shipments(is_return);
CREATE INDEX idx_shipments_original ON shipments(original_shipment_id);

-- Index on issues
CREATE INDEX idx_shipments_issues ON shipments(has_issues);

-- Composite indexes for common queries
CREATE INDEX idx_shipments_store_status ON shipments(store_id, status);
CREATE INDEX idx_shipments_company_status ON shipments(shipping_company_id, status);
CREATE INDEX idx_shipments_date_status ON shipments(created_date, status);

-- GIN indexes for JSONB columns
CREATE INDEX idx_shipments_items_gin ON shipments USING GIN(items);
CREATE INDEX idx_shipments_tracking_events_gin ON shipments USING GIN(tracking_events);
CREATE INDEX idx_shipments_issues_gin ON shipments USING GIN(issues);
CREATE INDEX idx_shipments_metadata_gin ON shipments USING GIN(metadata);

-- =============================================
-- Triggers
-- =============================================

-- Trigger to update updated_at column
CREATE TRIGGER trigger_shipments_updated_at
    BEFORE UPDATE ON shipments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger to automatically update dates based on status changes
CREATE OR REPLACE FUNCTION update_shipment_dates()
RETURNS TRIGGER AS $$
BEGIN
    -- Update pickup_date when status changes to picked_up
    IF NEW.status = 'picked_up' AND OLD.status != 'picked_up' AND NEW.pickup_date IS NULL THEN
        NEW.pickup_date := CURRENT_TIMESTAMP;
    END IF;
    
    -- Update shipped_date when status changes to in_transit
    IF NEW.status = 'in_transit' AND OLD.status != 'in_transit' AND NEW.shipped_date IS NULL THEN
        NEW.shipped_date := CURRENT_TIMESTAMP;
    END IF;
    
    -- Update actual_delivery_date when status changes to delivered
    IF NEW.status = 'delivered' AND OLD.status != 'delivered' AND NEW.actual_delivery_date IS NULL THEN
        NEW.actual_delivery_date := CURRENT_TIMESTAMP;
    END IF;
    
    -- Update last_tracking_update when tracking_events changes
    IF NEW.tracking_events != OLD.tracking_events THEN
        NEW.last_tracking_update := CURRENT_TIMESTAMP;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_shipments_auto_dates
    BEFORE UPDATE ON shipments
    FOR EACH ROW
    EXECUTE FUNCTION update_shipment_dates();

-- =============================================
-- Helper Functions
-- =============================================

-- Function to get shipment summary
CREATE OR REPLACE FUNCTION get_shipment_summary(p_shipment_id UUID)
RETURNS TABLE (
    shipment_number VARCHAR(255),
    tracking_number VARCHAR(255),
    status VARCHAR(50),
    shipping_company VARCHAR(255),
    created_date TIMESTAMP WITH TIME ZONE,
    estimated_delivery TIMESTAMP WITH TIME ZONE,
    actual_delivery TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.shipment_number,
        s.tracking_number,
        s.status,
        s.shipping_company_name,
        s.created_date,
        s.estimated_delivery_date,
        s.actual_delivery_date
    FROM shipments s
    WHERE s.id = p_shipment_id;
END;
$$ LANGUAGE plpgsql;

-- Function to add tracking event
CREATE OR REPLACE FUNCTION add_tracking_event(
    p_shipment_id UUID,
    p_event_date TIMESTAMP WITH TIME ZONE,
    p_status VARCHAR(100),
    p_location VARCHAR(255),
    p_description TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    new_event JSONB;
BEGIN
    -- Create new tracking event
    new_event := jsonb_build_object(
        'date', p_event_date,
        'status', p_status,
        'location', p_location,
        'description', p_description,
        'timestamp', EXTRACT(EPOCH FROM p_event_date)
    );
    
    -- Add event to tracking_events array
    UPDATE shipments 
    SET 
        tracking_events = tracking_events || new_event,
        last_tracking_update = CURRENT_TIMESTAMP,
        status = CASE 
            WHEN p_status IN ('delivered', 'failed', 'returned') THEN p_status
            ELSE status
        END
    WHERE id = p_shipment_id;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- Function to get shipments by status
CREATE OR REPLACE FUNCTION get_shipments_by_status(
    p_store_id UUID,
    p_status VARCHAR(50)
)
RETURNS TABLE (
    id UUID,
    shipment_number VARCHAR(255),
    order_id UUID,
    tracking_number VARCHAR(255),
    shipping_company VARCHAR(255),
    created_date TIMESTAMP WITH TIME ZONE,
    estimated_delivery TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id,
        s.shipment_number,
        s.order_id,
        s.tracking_number,
        s.shipping_company_name,
        s.created_date,
        s.estimated_delivery_date
    FROM shipments s
    WHERE s.store_id = p_store_id
      AND s.status = p_status
    ORDER BY s.created_date DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate delivery performance
CREATE OR REPLACE FUNCTION calculate_delivery_performance(
    p_store_id UUID,
    p_company_id UUID DEFAULT NULL,
    p_days_back INTEGER DEFAULT 30
)
RETURNS TABLE (
    total_shipments BIGINT,
    delivered_shipments BIGINT,
    on_time_deliveries BIGINT,
    average_delivery_days NUMERIC,
    delivery_success_rate NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) as total_shipments,
        COUNT(CASE WHEN s.status = 'delivered' THEN 1 END) as delivered_shipments,
        COUNT(CASE 
            WHEN s.status = 'delivered' 
                AND s.actual_delivery_date <= s.estimated_delivery_date 
            THEN 1 
        END) as on_time_deliveries,
        AVG(
            CASE 
                WHEN s.status = 'delivered' AND s.actual_delivery_date IS NOT NULL 
                THEN EXTRACT(DAYS FROM (s.actual_delivery_date - s.created_date))
            END
        ) as average_delivery_days,
        CASE 
            WHEN COUNT(*) > 0 THEN 
                (COUNT(CASE WHEN s.status = 'delivered' THEN 1 END) * 100.0 / COUNT(*))
            ELSE 0
        END as delivery_success_rate
    FROM shipments s
    WHERE s.store_id = p_store_id
      AND (p_company_id IS NULL OR s.shipping_company_id = p_company_id)
      AND s.created_date >= CURRENT_DATE - INTERVAL '%s days' % p_days_back;
END;
$$ LANGUAGE plpgsql;

-- Function to get overdue shipments
CREATE OR REPLACE FUNCTION get_overdue_shipments(p_store_id UUID)
RETURNS TABLE (
    id UUID,
    shipment_number VARCHAR(255),
    order_id UUID,
    tracking_number VARCHAR(255),
    estimated_delivery TIMESTAMP WITH TIME ZONE,
    days_overdue INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id,
        s.shipment_number,
        s.order_id,
        s.tracking_number,
        s.estimated_delivery_date,
        EXTRACT(DAYS FROM (CURRENT_TIMESTAMP - s.estimated_delivery_date))::INTEGER
    FROM shipments s
    WHERE s.store_id = p_store_id
      AND s.status NOT IN ('delivered', 'failed', 'returned')
      AND s.estimated_delivery_date < CURRENT_TIMESTAMP
    ORDER BY s.estimated_delivery_date ASC;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- Comments
-- =============================================

COMMENT ON TABLE shipments IS 'Stores information about actual shipments and tracks their delivery status';
COMMENT ON COLUMN shipments.store_id IS 'Reference to the store this shipment belongs to';
COMMENT ON COLUMN shipments.order_id IS 'Reference to the order being shipped';
COMMENT ON COLUMN shipments.shipping_company_id IS 'Reference to the shipping company handling this shipment';
COMMENT ON COLUMN shipments.salla_shipment_id IS 'Salla API shipment identifier';
COMMENT ON COLUMN shipments.status IS 'Current shipment status: pending, picked_up, in_transit, out_for_delivery, delivered, failed, returned';
COMMENT ON COLUMN shipments.items IS 'JSON array of items included in this shipment';
COMMENT ON COLUMN shipments.tracking_events IS 'JSON array of tracking events and status updates';
COMMENT ON COLUMN shipments.cod_amount IS 'Cash on delivery amount to be collected';
COMMENT ON COLUMN shipments.is_return IS 'Whether this is a return shipment';
COMMENT ON COLUMN shipments.original_shipment_id IS 'Reference to original shipment if this is a return';
COMMENT ON COLUMN shipments.issues IS 'JSON array of issues encountered during shipping';
COMMENT ON COLUMN shipments.metadata IS 'Additional metadata in JSON format';