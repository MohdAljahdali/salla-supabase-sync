-- =====================================================
-- Product Quantities Table
-- =====================================================
-- This table stores detailed product quantity information
-- including inventory tracking, stock movements, and availability

CREATE TABLE IF NOT EXISTS product_quantities (
    -- Primary identification
    id BIGSERIAL PRIMARY KEY,
    salla_quantity_id VARCHAR UNIQUE, -- Salla quantity record ID if available
    
    -- Store and product relationship
    store_id BIGINT NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    product_id BIGINT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    variant_id BIGINT REFERENCES product_variants(id) ON DELETE CASCADE,
    
    -- Basic quantity information
    current_quantity INTEGER NOT NULL DEFAULT 0,
    available_quantity INTEGER NOT NULL DEFAULT 0,
    reserved_quantity INTEGER NOT NULL DEFAULT 0,
    committed_quantity INTEGER NOT NULL DEFAULT 0,
    damaged_quantity INTEGER NOT NULL DEFAULT 0,
    
    -- Stock levels and thresholds
    minimum_stock_level INTEGER DEFAULT 0,
    maximum_stock_level INTEGER,
    reorder_point INTEGER DEFAULT 0,
    reorder_quantity INTEGER DEFAULT 0,
    safety_stock INTEGER DEFAULT 0,
    
    -- Location and warehouse information
    warehouse_id BIGINT REFERENCES warehouses(id) ON DELETE SET NULL,
    location_code VARCHAR(100),
    bin_location VARCHAR(100),
    zone VARCHAR(50),
    aisle VARCHAR(50),
    shelf VARCHAR(50),
    
    -- Inventory tracking
    last_counted_at TIMESTAMPTZ,
    last_counted_quantity INTEGER,
    cycle_count_frequency INTEGER DEFAULT 90, -- days
    next_count_due_date DATE,
    count_variance INTEGER DEFAULT 0,
    
    -- Stock movement tracking
    last_stock_in_date TIMESTAMPTZ,
    last_stock_out_date TIMESTAMPTZ,
    last_movement_type VARCHAR(50), -- in, out, adjustment, transfer
    last_movement_quantity INTEGER,
    last_movement_reference VARCHAR(255),
    
    -- Supplier and procurement
    primary_supplier_id BIGINT REFERENCES suppliers(id) ON DELETE SET NULL,
    supplier_sku VARCHAR(255),
    lead_time_days INTEGER DEFAULT 7,
    last_purchase_date DATE,
    last_purchase_price DECIMAL(15,2),
    last_purchase_quantity INTEGER,
    
    -- Cost information
    unit_cost DECIMAL(15,2),
    average_cost DECIMAL(15,2),
    last_cost DECIMAL(15,2),
    standard_cost DECIMAL(15,2),
    total_value DECIMAL(15,2),
    currency_code VARCHAR(3) DEFAULT 'SAR',
    
    -- Expiry and batch tracking
    has_expiry BOOLEAN DEFAULT FALSE,
    expiry_date DATE,
    batch_number VARCHAR(100),
    lot_number VARCHAR(100),
    manufacturing_date DATE,
    shelf_life_days INTEGER,
    
    -- Quality and condition
    quality_grade VARCHAR(20) DEFAULT 'A', -- A, B, C, D
    condition_status VARCHAR(50) DEFAULT 'new', -- new, used, refurbished, damaged
    quality_notes TEXT,
    inspection_date DATE,
    inspector_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
    
    -- Availability and status
    is_available BOOLEAN DEFAULT TRUE,
    is_sellable BOOLEAN DEFAULT TRUE,
    is_backorderable BOOLEAN DEFAULT FALSE,
    availability_status VARCHAR(50) DEFAULT 'in_stock' CHECK (availability_status IN (
        'in_stock', 'low_stock', 'out_of_stock', 'discontinued', 'pre_order', 'backorder'
    )),
    
    -- Reservations and allocations
    pending_orders_quantity INTEGER DEFAULT 0,
    allocated_quantity INTEGER DEFAULT 0,
    quarantine_quantity INTEGER DEFAULT 0,
    return_quantity INTEGER DEFAULT 0,
    
    -- Seasonal and demand patterns
    seasonal_item BOOLEAN DEFAULT FALSE,
    peak_season_start DATE,
    peak_season_end DATE,
    demand_pattern VARCHAR(50), -- steady, seasonal, trending, declining
    velocity_category VARCHAR(20) DEFAULT 'medium', -- fast, medium, slow, dead
    
    -- Sales performance
    units_sold_last_30_days INTEGER DEFAULT 0,
    units_sold_last_90_days INTEGER DEFAULT 0,
    units_sold_last_year INTEGER DEFAULT 0,
    average_daily_sales DECIMAL(10,2) DEFAULT 0,
    days_of_supply DECIMAL(10,2),
    
    -- Forecasting and planning
    forecasted_demand_30_days INTEGER DEFAULT 0,
    forecasted_demand_90_days INTEGER DEFAULT 0,
    planned_receipts JSONB DEFAULT '[]'::jsonb,
    planned_shipments JSONB DEFAULT '[]'::jsonb,
    
    -- Physical characteristics
    weight_per_unit DECIMAL(10,3),
    volume_per_unit DECIMAL(10,3),
    dimensions JSONB, -- {"length": 10, "width": 5, "height": 3}
    storage_requirements TEXT,
    handling_instructions TEXT,
    
    -- Compliance and regulations
    requires_license BOOLEAN DEFAULT FALSE,
    hazardous_material BOOLEAN DEFAULT FALSE,
    restricted_item BOOLEAN DEFAULT FALSE,
    compliance_notes TEXT,
    regulatory_codes JSONB DEFAULT '[]'::jsonb,
    
    -- Temperature and environment
    temperature_controlled BOOLEAN DEFAULT FALSE,
    min_temperature DECIMAL(5,2),
    max_temperature DECIMAL(5,2),
    humidity_requirements VARCHAR(100),
    storage_conditions TEXT,
    
    -- Tracking and serialization
    is_serialized BOOLEAN DEFAULT FALSE,
    serial_numbers JSONB DEFAULT '[]'::jsonb,
    tracking_method VARCHAR(50), -- barcode, rfid, qr_code, manual
    barcode VARCHAR(255),
    rfid_tag VARCHAR(255),
    
    -- Multi-location inventory
    total_quantity_all_locations INTEGER,
    locations_breakdown JSONB DEFAULT '{}'::jsonb,
    transfer_in_transit INTEGER DEFAULT 0,
    
    -- Pricing and margins
    selling_price DECIMAL(15,2),
    margin_percentage DECIMAL(5,2),
    markup_percentage DECIMAL(5,2),
    discount_applicable BOOLEAN DEFAULT TRUE,
    price_last_updated TIMESTAMPTZ,
    
    -- Returns and exchanges
    return_rate_percentage DECIMAL(5,2) DEFAULT 0,
    exchange_rate_percentage DECIMAL(5,2) DEFAULT 0,
    defect_rate_percentage DECIMAL(5,2) DEFAULT 0,
    customer_satisfaction_score DECIMAL(3,2),
    
    -- Automation and alerts
    auto_reorder_enabled BOOLEAN DEFAULT FALSE,
    low_stock_alert_sent BOOLEAN DEFAULT FALSE,
    out_of_stock_alert_sent BOOLEAN DEFAULT FALSE,
    last_alert_sent_at TIMESTAMPTZ,
    alert_recipients JSONB DEFAULT '[]'::jsonb,
    
    -- Integration and sync
    external_quantity_id VARCHAR(255),
    sync_status VARCHAR(50) DEFAULT 'synced',
    last_sync_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    sync_errors JSONB DEFAULT '[]'::jsonb,
    
    -- Analytics and insights
    abc_classification VARCHAR(1), -- A, B, C (based on value/volume)
    xyz_classification VARCHAR(1), -- X, Y, Z (based on demand variability)
    turnover_rate DECIMAL(10,2),
    stock_age_days INTEGER,
    obsolescence_risk VARCHAR(20) DEFAULT 'low', -- low, medium, high
    
    -- Custom fields for extensibility
    custom_fields JSONB DEFAULT '{}'::jsonb,
    tags JSONB DEFAULT '[]'::jsonb,
    notes TEXT,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    last_movement_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- Indexes for Performance
-- =====================================================

-- Primary indexes
CREATE INDEX IF NOT EXISTS idx_product_quantities_store_id ON product_quantities(store_id);
CREATE INDEX IF NOT EXISTS idx_product_quantities_product_id ON product_quantities(product_id);
CREATE INDEX IF NOT EXISTS idx_product_quantities_variant_id ON product_quantities(variant_id);
CREATE INDEX IF NOT EXISTS idx_product_quantities_warehouse_id ON product_quantities(warehouse_id);
CREATE INDEX IF NOT EXISTS idx_product_quantities_salla_quantity_id ON product_quantities(salla_quantity_id);

-- Quantity and availability indexes
CREATE INDEX IF NOT EXISTS idx_product_quantities_current_quantity ON product_quantities(current_quantity);
CREATE INDEX IF NOT EXISTS idx_product_quantities_available_quantity ON product_quantities(available_quantity);
CREATE INDEX IF NOT EXISTS idx_product_quantities_availability_status ON product_quantities(availability_status);
CREATE INDEX IF NOT EXISTS idx_product_quantities_is_available ON product_quantities(is_available);

-- Stock level indexes
CREATE INDEX IF NOT EXISTS idx_product_quantities_reorder_point ON product_quantities(reorder_point);
CREATE INDEX IF NOT EXISTS idx_product_quantities_minimum_stock ON product_quantities(minimum_stock_level);
CREATE INDEX IF NOT EXISTS idx_product_quantities_velocity_category ON product_quantities(velocity_category);

-- Location indexes
CREATE INDEX IF NOT EXISTS idx_product_quantities_location_code ON product_quantities(location_code);
CREATE INDEX IF NOT EXISTS idx_product_quantities_bin_location ON product_quantities(bin_location);
CREATE INDEX IF NOT EXISTS idx_product_quantities_zone ON product_quantities(zone);

-- Time-based indexes
CREATE INDEX IF NOT EXISTS idx_product_quantities_last_counted ON product_quantities(last_counted_at);
CREATE INDEX IF NOT EXISTS idx_product_quantities_next_count_due ON product_quantities(next_count_due_date);
CREATE INDEX IF NOT EXISTS idx_product_quantities_expiry_date ON product_quantities(expiry_date);
CREATE INDEX IF NOT EXISTS idx_product_quantities_created_at ON product_quantities(created_at);

-- Supplier and cost indexes
CREATE INDEX IF NOT EXISTS idx_product_quantities_supplier_id ON product_quantities(primary_supplier_id);
CREATE INDEX IF NOT EXISTS idx_product_quantities_supplier_sku ON product_quantities(supplier_sku);
CREATE INDEX IF NOT EXISTS idx_product_quantities_unit_cost ON product_quantities(unit_cost);

-- Quality and condition indexes
CREATE INDEX IF NOT EXISTS idx_product_quantities_quality_grade ON product_quantities(quality_grade);
CREATE INDEX IF NOT EXISTS idx_product_quantities_condition_status ON product_quantities(condition_status);
CREATE INDEX IF NOT EXISTS idx_product_quantities_batch_number ON product_quantities(batch_number);

-- Performance and classification indexes
CREATE INDEX IF NOT EXISTS idx_product_quantities_abc_classification ON product_quantities(abc_classification);
CREATE INDEX IF NOT EXISTS idx_product_quantities_xyz_classification ON product_quantities(xyz_classification);
CREATE INDEX IF NOT EXISTS idx_product_quantities_turnover_rate ON product_quantities(turnover_rate);

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_product_quantities_store_product ON product_quantities(store_id, product_id);
CREATE INDEX IF NOT EXISTS idx_product_quantities_store_warehouse ON product_quantities(store_id, warehouse_id);
CREATE INDEX IF NOT EXISTS idx_product_quantities_product_warehouse ON product_quantities(product_id, warehouse_id);
CREATE INDEX IF NOT EXISTS idx_product_quantities_store_availability ON product_quantities(store_id, availability_status);
CREATE INDEX IF NOT EXISTS idx_product_quantities_low_stock ON product_quantities(store_id, current_quantity, minimum_stock_level)
    WHERE current_quantity <= minimum_stock_level;

-- Alert and automation indexes
CREATE INDEX IF NOT EXISTS idx_product_quantities_reorder_needed ON product_quantities(store_id, auto_reorder_enabled, current_quantity, reorder_point)
    WHERE auto_reorder_enabled = TRUE AND current_quantity <= reorder_point;

-- JSONB indexes
CREATE INDEX IF NOT EXISTS idx_product_quantities_custom_fields_gin ON product_quantities USING GIN(custom_fields);
CREATE INDEX IF NOT EXISTS idx_product_quantities_tags_gin ON product_quantities USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_product_quantities_serial_numbers_gin ON product_quantities USING GIN(serial_numbers);
CREATE INDEX IF NOT EXISTS idx_product_quantities_planned_receipts_gin ON product_quantities USING GIN(planned_receipts);

-- =====================================================
-- Unique Constraints
-- =====================================================

-- Ensure unique product-warehouse combination
CREATE UNIQUE INDEX IF NOT EXISTS idx_product_quantities_unique_product_warehouse 
    ON product_quantities(store_id, product_id, warehouse_id, variant_id)
    WHERE variant_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_product_quantities_unique_product_warehouse_no_variant 
    ON product_quantities(store_id, product_id, warehouse_id)
    WHERE variant_id IS NULL;

-- =====================================================
-- Triggers
-- =====================================================

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_product_quantities_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_product_quantities_updated_at
    BEFORE UPDATE ON product_quantities
    FOR EACH ROW
    EXECUTE FUNCTION update_product_quantities_updated_at();

-- Trigger to calculate derived quantities
CREATE OR REPLACE FUNCTION calculate_quantity_metrics()
RETURNS TRIGGER AS $$
BEGIN
    -- Calculate available quantity
    NEW.available_quantity = GREATEST(0, 
        NEW.current_quantity - NEW.reserved_quantity - NEW.committed_quantity - NEW.quarantine_quantity
    );
    
    -- Calculate total value
    IF NEW.unit_cost IS NOT NULL THEN
        NEW.total_value = NEW.current_quantity * NEW.unit_cost;
    END IF;
    
    -- Set availability status based on quantity
    NEW.availability_status = CASE 
        WHEN NEW.current_quantity <= 0 THEN 'out_of_stock'
        WHEN NEW.current_quantity <= NEW.minimum_stock_level THEN 'low_stock'
        WHEN NEW.current_quantity <= NEW.reorder_point THEN 'low_stock'
        ELSE 'in_stock'
    END;
    
    -- Calculate days of supply
    IF NEW.average_daily_sales > 0 THEN
        NEW.days_of_supply = NEW.current_quantity / NEW.average_daily_sales;
    END IF;
    
    -- Calculate stock age
    IF NEW.last_stock_in_date IS NOT NULL THEN
        NEW.stock_age_days = EXTRACT(DAY FROM (CURRENT_TIMESTAMP - NEW.last_stock_in_date));
    END IF;
    
    -- Set next count due date
    IF NEW.cycle_count_frequency IS NOT NULL AND NEW.last_counted_at IS NOT NULL THEN
        NEW.next_count_due_date = (NEW.last_counted_at + (NEW.cycle_count_frequency || ' days')::INTERVAL)::DATE;
    END IF;
    
    -- Update movement timestamp if quantity changed
    IF TG_OP = 'UPDATE' AND OLD.current_quantity != NEW.current_quantity THEN
        NEW.last_movement_at = CURRENT_TIMESTAMP;
        
        -- Determine movement type
        IF NEW.current_quantity > OLD.current_quantity THEN
            NEW.last_movement_type = 'in';
            NEW.last_stock_in_date = CURRENT_TIMESTAMP;
        ELSE
            NEW.last_movement_type = 'out';
            NEW.last_stock_out_date = CURRENT_TIMESTAMP;
        END IF;
        
        NEW.last_movement_quantity = ABS(NEW.current_quantity - OLD.current_quantity);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_calculate_quantity_metrics
    BEFORE INSERT OR UPDATE ON product_quantities
    FOR EACH ROW
    EXECUTE FUNCTION calculate_quantity_metrics();

-- Trigger to send alerts for low stock
CREATE OR REPLACE FUNCTION check_stock_alerts()
RETURNS TRIGGER AS $$
BEGIN
    -- Reset alert flags when stock is replenished
    IF NEW.current_quantity > NEW.minimum_stock_level THEN
        NEW.low_stock_alert_sent = FALSE;
        NEW.out_of_stock_alert_sent = FALSE;
    END IF;
    
    -- Set alert flags for low stock (actual alert sending would be handled by application)
    IF NEW.current_quantity <= 0 AND NOT NEW.out_of_stock_alert_sent THEN
        NEW.out_of_stock_alert_sent = TRUE;
        NEW.last_alert_sent_at = CURRENT_TIMESTAMP;
    ELSIF NEW.current_quantity <= NEW.minimum_stock_level AND NOT NEW.low_stock_alert_sent THEN
        NEW.low_stock_alert_sent = TRUE;
        NEW.last_alert_sent_at = CURRENT_TIMESTAMP;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_stock_alerts
    BEFORE INSERT OR UPDATE ON product_quantities
    FOR EACH ROW
    EXECUTE FUNCTION check_stock_alerts();

-- =====================================================
-- Helper Functions
-- =====================================================

-- Function to get inventory statistics for a store
CREATE OR REPLACE FUNCTION get_inventory_stats(store_id_param BIGINT)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'store_id', store_id_param,
        'total_products', COUNT(*),
        'total_quantity', COALESCE(SUM(current_quantity), 0),
        'total_value', COALESCE(SUM(total_value), 0),
        'average_unit_cost', COALESCE(AVG(unit_cost), 0),
        'products_in_stock', COUNT(*) FILTER (WHERE availability_status = 'in_stock'),
        'products_low_stock', COUNT(*) FILTER (WHERE availability_status = 'low_stock'),
        'products_out_of_stock', COUNT(*) FILTER (WHERE availability_status = 'out_of_stock'),
        'products_need_reorder', COUNT(*) FILTER (WHERE current_quantity <= reorder_point),
        'inventory_by_status', jsonb_object_agg(availability_status, status_count),
        'inventory_by_velocity', (
            SELECT jsonb_object_agg(velocity_category, velocity_count)
            FROM (
                SELECT velocity_category, COUNT(*) as velocity_count
                FROM product_quantities 
                WHERE store_id = store_id_param
                GROUP BY velocity_category
            ) velocity_stats
        ),
        'inventory_by_abc', (
            SELECT jsonb_object_agg(abc_classification, abc_count)
            FROM (
                SELECT abc_classification, COUNT(*) as abc_count
                FROM product_quantities 
                WHERE store_id = store_id_param AND abc_classification IS NOT NULL
                GROUP BY abc_classification
            ) abc_stats
        ),
        'average_turnover_rate', COALESCE(AVG(turnover_rate), 0),
        'products_with_expiry', COUNT(*) FILTER (WHERE has_expiry = TRUE),
        'products_expiring_soon', COUNT(*) FILTER (WHERE expiry_date <= CURRENT_DATE + INTERVAL '30 days'),
        'total_reserved_quantity', COALESCE(SUM(reserved_quantity), 0),
        'total_available_quantity', COALESCE(SUM(available_quantity), 0)
    ) INTO result
    FROM (
        SELECT availability_status, COUNT(*) as status_count
        FROM product_quantities 
        WHERE store_id = store_id_param
        GROUP BY availability_status
    ) status_stats
    CROSS JOIN product_quantities pq
    WHERE pq.store_id = store_id_param;
    
    RETURN COALESCE(result, '{"error": "No data found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- Function to search product quantities with filters
CREATE OR REPLACE FUNCTION search_product_quantities(
    store_id_param BIGINT DEFAULT NULL,
    availability_status_param VARCHAR DEFAULT NULL,
    warehouse_id_param BIGINT DEFAULT NULL,
    velocity_category_param VARCHAR DEFAULT NULL,
    low_stock_only BOOLEAN DEFAULT FALSE,
    expiring_soon BOOLEAN DEFAULT FALSE,
    limit_param INTEGER DEFAULT 50,
    offset_param INTEGER DEFAULT 0
)
RETURNS TABLE (
    quantity_id BIGINT,
    product_name VARCHAR,
    product_sku VARCHAR,
    current_quantity INTEGER,
    available_quantity INTEGER,
    minimum_stock_level INTEGER,
    availability_status VARCHAR,
    unit_cost DECIMAL,
    total_value DECIMAL,
    warehouse_name VARCHAR,
    location_details JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pq.id as quantity_id,
        p.name as product_name,
        p.sku as product_sku,
        pq.current_quantity,
        pq.available_quantity,
        pq.minimum_stock_level,
        pq.availability_status,
        pq.unit_cost,
        pq.total_value,
        w.name as warehouse_name,
        jsonb_build_object(
            'location_code', pq.location_code,
            'bin_location', pq.bin_location,
            'zone', pq.zone,
            'velocity_category', pq.velocity_category,
            'last_movement_at', pq.last_movement_at,
            'expiry_date', pq.expiry_date
        ) as location_details
    FROM product_quantities pq
    JOIN products p ON pq.product_id = p.id
    LEFT JOIN warehouses w ON pq.warehouse_id = w.id
    WHERE 
        (store_id_param IS NULL OR pq.store_id = store_id_param)
        AND (availability_status_param IS NULL OR pq.availability_status = availability_status_param)
        AND (warehouse_id_param IS NULL OR pq.warehouse_id = warehouse_id_param)
        AND (velocity_category_param IS NULL OR pq.velocity_category = velocity_category_param)
        AND (NOT low_stock_only OR pq.current_quantity <= pq.minimum_stock_level)
        AND (NOT expiring_soon OR pq.expiry_date <= CURRENT_DATE + INTERVAL '30 days')
    ORDER BY pq.availability_status, pq.current_quantity, p.name
    LIMIT limit_param OFFSET offset_param;
END;
$$ LANGUAGE plpgsql;

-- Function to update product quantity
CREATE OR REPLACE FUNCTION update_product_quantity(
    product_id_param BIGINT,
    warehouse_id_param BIGINT DEFAULT NULL,
    quantity_change INTEGER,
    movement_type VARCHAR DEFAULT 'adjustment',
    reference VARCHAR DEFAULT NULL,
    notes TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    current_record RECORD;
BEGIN
    -- Get current quantity record
    SELECT * INTO current_record
    FROM product_quantities 
    WHERE product_id = product_id_param 
        AND (warehouse_id_param IS NULL OR warehouse_id = warehouse_id_param)
    LIMIT 1;
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Update quantity
    UPDATE product_quantities 
    SET 
        current_quantity = GREATEST(0, current_quantity + quantity_change),
        last_movement_type = movement_type,
        last_movement_quantity = ABS(quantity_change),
        last_movement_reference = reference,
        notes = CASE 
            WHEN notes IS NOT NULL THEN 
                COALESCE(notes, '') || '\n' || TO_CHAR(CURRENT_TIMESTAMP, 'YYYY-MM-DD HH24:MI') || ': ' || notes
            ELSE notes
        END,
        updated_at = CURRENT_TIMESTAMP
    WHERE product_id = product_id_param 
        AND (warehouse_id_param IS NULL OR warehouse_id = warehouse_id_param);
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- Function to get products needing reorder
CREATE OR REPLACE FUNCTION get_reorder_list(store_id_param BIGINT DEFAULT NULL)
RETURNS TABLE (
    product_id BIGINT,
    product_name VARCHAR,
    product_sku VARCHAR,
    current_quantity INTEGER,
    reorder_point INTEGER,
    reorder_quantity INTEGER,
    supplier_name VARCHAR,
    lead_time_days INTEGER,
    last_purchase_price DECIMAL,
    suggested_order_quantity INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id as product_id,
        p.name as product_name,
        p.sku as product_sku,
        pq.current_quantity,
        pq.reorder_point,
        pq.reorder_quantity,
        s.name as supplier_name,
        pq.lead_time_days,
        pq.last_purchase_price,
        GREATEST(pq.reorder_quantity, 
                CEIL(pq.average_daily_sales * (pq.lead_time_days + 7))) as suggested_order_quantity
    FROM product_quantities pq
    JOIN products p ON pq.product_id = p.id
    LEFT JOIN suppliers s ON pq.primary_supplier_id = s.id
    WHERE 
        (store_id_param IS NULL OR pq.store_id = store_id_param)
        AND pq.current_quantity <= pq.reorder_point
        AND pq.is_available = TRUE
    ORDER BY 
        (pq.reorder_point - pq.current_quantity) DESC,
        pq.velocity_category DESC,
        p.name;
END;
$$ LANGUAGE plpgsql;

-- Function to reserve quantity
CREATE OR REPLACE FUNCTION reserve_quantity(
    product_id_param BIGINT,
    warehouse_id_param BIGINT DEFAULT NULL,
    quantity_to_reserve INTEGER,
    reservation_reference VARCHAR DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    available_qty INTEGER;
BEGIN
    -- Check available quantity
    SELECT available_quantity INTO available_qty
    FROM product_quantities 
    WHERE product_id = product_id_param 
        AND (warehouse_id_param IS NULL OR warehouse_id = warehouse_id_param)
    LIMIT 1;
    
    IF available_qty IS NULL OR available_qty < quantity_to_reserve THEN
        RETURN FALSE;
    END IF;
    
    -- Reserve quantity
    UPDATE product_quantities 
    SET 
        reserved_quantity = reserved_quantity + quantity_to_reserve,
        last_movement_reference = reservation_reference,
        updated_at = CURRENT_TIMESTAMP
    WHERE product_id = product_id_param 
        AND (warehouse_id_param IS NULL OR warehouse_id = warehouse_id_param);
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Comments for Documentation
-- =====================================================

COMMENT ON TABLE product_quantities IS 'Stores detailed product quantity information including inventory tracking and stock movements';
COMMENT ON COLUMN product_quantities.salla_quantity_id IS 'Unique quantity record identifier from Salla platform';
COMMENT ON COLUMN product_quantities.current_quantity IS 'Current physical quantity in stock';
COMMENT ON COLUMN product_quantities.available_quantity IS 'Quantity available for sale (current - reserved - committed)';
COMMENT ON COLUMN product_quantities.velocity_category IS 'Sales velocity classification (fast, medium, slow, dead)';
COMMENT ON COLUMN product_quantities.abc_classification IS 'ABC analysis classification based on value/volume';
COMMENT ON COLUMN product_quantities.custom_fields IS 'Additional custom data in JSON format';

COMMENT ON FUNCTION get_inventory_stats(BIGINT) IS 'Get comprehensive inventory statistics for a store';
COMMENT ON FUNCTION search_product_quantities(BIGINT, VARCHAR, BIGINT, VARCHAR, BOOLEAN, BOOLEAN, INTEGER, INTEGER) IS 'Search product quantities with various filters';
COMMENT ON FUNCTION update_product_quantity(BIGINT, BIGINT, INTEGER, VARCHAR, VARCHAR, TEXT) IS 'Update product quantity with movement tracking';
COMMENT ON FUNCTION get_reorder_list(BIGINT) IS 'Get list of products that need to be reordered';
COMMENT ON FUNCTION reserve_quantity(BIGINT, BIGINT, INTEGER, VARCHAR) IS 'Reserve quantity for orders or allocations';

RAISE NOTICE 'Product Quantities table created successfully!';