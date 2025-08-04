-- =============================================
-- Shipping and Delivery Tables - Complete Setup
-- =============================================
-- This script creates all shipping and delivery related tables
-- for the Salla-Supabase sync project

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Include all shipping table creation scripts
\i 07_shipping_companies_table.sql
\i 08_shipping_zones_table.sql
\i 09_shipping_rules_table.sql
\i 10_shipments_table.sql

-- =============================================
-- Additional Cross-Table Indexes
-- =============================================

-- Index for finding zones by company
CREATE INDEX idx_zones_companies_cross ON shipping_zones USING GIN(shipping_companies);

-- Index for finding rules by zone and company
CREATE INDEX idx_rules_zone_company ON shipping_rules(shipping_zone_id, shipping_company_id);

-- Index for finding shipments by company and zone
CREATE INDEX idx_shipments_company_zone ON shipments(shipping_company_id, store_id);

-- =============================================
-- Useful Views for Shipping Management
-- =============================================

-- View: Complete shipping options for a store
CREATE OR REPLACE VIEW shipping_options_complete AS
SELECT 
    sc.store_id,
    sc.id as company_id,
    sc.name as company_name,
    sc.logo_url as company_logo,
    sz.id as zone_id,
    sz.name as zone_name,
    sz.base_cost as zone_base_cost,
    sz.delivery_time_min,
    sz.delivery_time_max,
    sc.supports_tracking,
    sc.supports_cod,
    sc.is_active as company_active,
    sz.is_active as zone_active
FROM shipping_companies sc
JOIN shipping_zones sz ON sz.store_id = sc.store_id
    AND sc.id::text = ANY(SELECT jsonb_array_elements_text(sz.shipping_companies))
WHERE sc.is_active = true 
  AND sz.is_active = true;

-- View: Shipment tracking summary
CREATE OR REPLACE VIEW shipment_tracking_summary AS
SELECT 
    s.id,
    s.store_id,
    s.order_id,
    s.shipment_number,
    s.tracking_number,
    s.status,
    s.shipping_company_name,
    s.created_date,
    s.pickup_date,
    s.estimated_delivery_date,
    s.actual_delivery_date,
    CASE 
        WHEN s.status = 'delivered' THEN 'Completed'
        WHEN s.status IN ('failed', 'returned') THEN 'Failed'
        WHEN s.estimated_delivery_date < CURRENT_TIMESTAMP AND s.status NOT IN ('delivered', 'failed', 'returned') THEN 'Overdue'
        ELSE 'In Progress'
    END as delivery_status,
    CASE 
        WHEN s.actual_delivery_date IS NOT NULL THEN 
            EXTRACT(DAYS FROM (s.actual_delivery_date - s.created_date))
        WHEN s.estimated_delivery_date IS NOT NULL THEN 
            EXTRACT(DAYS FROM (s.estimated_delivery_date - s.created_date))
        ELSE NULL
    END as delivery_days,
    jsonb_array_length(s.tracking_events) as tracking_events_count,
    s.has_issues,
    s.customer_rating
FROM shipments s;

-- View: Shipping performance by company
CREATE OR REPLACE VIEW shipping_company_performance AS
SELECT 
    sc.store_id,
    sc.id as company_id,
    sc.name as company_name,
    COUNT(s.id) as total_shipments,
    COUNT(CASE WHEN s.status = 'delivered' THEN 1 END) as delivered_shipments,
    COUNT(CASE WHEN s.status IN ('failed', 'returned') THEN 1 END) as failed_shipments,
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
    ) as avg_delivery_days,
    AVG(s.customer_rating) as avg_rating,
    CASE 
        WHEN COUNT(s.id) > 0 THEN 
            (COUNT(CASE WHEN s.status = 'delivered' THEN 1 END) * 100.0 / COUNT(s.id))
        ELSE 0
    END as success_rate
FROM shipping_companies sc
LEFT JOIN shipments s ON s.shipping_company_id = sc.id
WHERE sc.is_active = true
GROUP BY sc.store_id, sc.id, sc.name;

-- =============================================
-- Comprehensive Helper Functions
-- =============================================

-- Function to get complete shipping quote
CREATE OR REPLACE FUNCTION get_shipping_quote(
    p_store_id UUID,
    p_country VARCHAR(255),
    p_city VARCHAR(255) DEFAULT NULL,
    p_order_total DECIMAL(10,2) DEFAULT 0,
    p_total_weight DECIMAL(10,2) DEFAULT 0,
    p_item_count INTEGER DEFAULT 0
)
RETURNS TABLE (
    company_id UUID,
    company_name VARCHAR(255),
    company_logo TEXT,
    zone_id UUID,
    zone_name VARCHAR(255),
    shipping_cost DECIMAL(10,2),
    delivery_time_min INTEGER,
    delivery_time_max INTEGER,
    supports_tracking BOOLEAN,
    supports_cod BOOLEAN,
    is_free_shipping BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        soc.company_id,
        soc.company_name,
        soc.company_logo,
        soc.zone_id,
        soc.zone_name,
        CASE 
            WHEN check_free_shipping_eligibility(p_store_id, soc.zone_id, p_order_total, p_total_weight, p_item_count) THEN 0.00
            ELSE calculate_zone_shipping_cost(soc.zone_id, p_order_total, p_total_weight, p_item_count)
        END as shipping_cost,
        soc.delivery_time_min,
        soc.delivery_time_max,
        soc.supports_tracking,
        soc.supports_cod,
        check_free_shipping_eligibility(p_store_id, soc.zone_id, p_order_total, p_total_weight, p_item_count) as is_free_shipping
    FROM shipping_options_complete soc
    WHERE soc.store_id = p_store_id
      AND soc.company_active = true
      AND soc.zone_active = true
      AND EXISTS (
          SELECT 1 FROM find_shipping_zone(p_store_id, p_country, p_city) fz
          WHERE fz.zone_id = soc.zone_id
      )
    ORDER BY shipping_cost ASC, soc.delivery_time_min ASC;
END;
$$ LANGUAGE plpgsql;

-- Function to create shipment from order
CREATE OR REPLACE FUNCTION create_shipment_from_order(
    p_order_id UUID,
    p_shipping_company_id UUID,
    p_tracking_number VARCHAR(255) DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    order_record orders%ROWTYPE;
    company_record shipping_companies%ROWTYPE;
    new_shipment_id UUID;
    shipment_number VARCHAR(255);
BEGIN
    -- Get order details
    SELECT * INTO order_record FROM orders WHERE id = p_order_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Order not found: %', p_order_id;
    END IF;
    
    -- Get shipping company details
    SELECT * INTO company_record FROM shipping_companies WHERE id = p_shipping_company_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Shipping company not found: %', p_shipping_company_id;
    END IF;
    
    -- Generate shipment number
    shipment_number := 'SH-' || TO_CHAR(CURRENT_TIMESTAMP, 'YYYYMMDD') || '-' || LPAD(nextval('shipments_id_seq')::text, 6, '0');
    
    -- Create shipment
    INSERT INTO shipments (
        store_id,
        order_id,
        shipping_company_id,
        shipment_number,
        tracking_number,
        shipping_company_name,
        shipping_company_code,
        delivery_address,
        shipping_cost,
        cod_amount,
        currency,
        recipient_name,
        recipient_phone
    ) VALUES (
        order_record.store_id,
        p_order_id,
        p_shipping_company_id,
        shipment_number,
        p_tracking_number,
        company_record.name,
        company_record.code,
        order_record.shipping_address,
        order_record.shipping_amount,
        CASE WHEN order_record.payment_method = 'cod' THEN order_record.total_amount ELSE 0 END,
        order_record.currency,
        order_record.shipping_address->>'name',
        order_record.shipping_address->>'phone'
    ) RETURNING id INTO new_shipment_id;
    
    RETURN new_shipment_id;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- Comments for Views
-- =============================================

COMMENT ON VIEW shipping_options_complete IS 'Complete view of all shipping options available for each store';
COMMENT ON VIEW shipment_tracking_summary IS 'Summary view of shipment tracking information with calculated status';
COMMENT ON VIEW shipping_company_performance IS 'Performance metrics for shipping companies by store';

-- =============================================
-- Success Message
-- =============================================

-- Log successful completion
DO $$
BEGIN
    RAISE NOTICE 'Shipping and Delivery tables created successfully!';
    RAISE NOTICE 'Tables created: shipping_companies, shipping_zones, shipping_rules, shipments';
    RAISE NOTICE 'Views created: shipping_options_complete, shipment_tracking_summary, shipping_company_performance';
    RAISE NOTICE 'Helper functions created for shipping quotes, cost calculations, and shipment management';
END $$;