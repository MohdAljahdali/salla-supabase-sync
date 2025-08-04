-- =====================================================
-- Run All Analytics and Reports Tables
-- =====================================================
-- This script creates all analytics and reports tables
-- for comprehensive data analysis and business intelligence

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "btree_gin";
CREATE EXTENSION IF NOT EXISTS "btree_gist";

RAISE NOTICE 'Starting Analytics and Reports Tables creation...';

-- =====================================================
-- Include Individual Table Scripts
-- =====================================================

-- Abandoned Carts Table
\i 29_abandoned_carts_table.sql

-- Reservations Table
\i 30_reservations_table.sql

-- Product Quantities Table
\i 31_product_quantities_table.sql

-- =====================================================
-- Cross-Table Indexes for Analytics Performance
-- =====================================================

RAISE NOTICE 'Creating cross-table analytics indexes...';

-- Customer behavior analysis indexes
CREATE INDEX IF NOT EXISTS idx_analytics_customer_behavior 
    ON abandoned_carts(customer_id, created_at, total_amount)
    WHERE customer_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_analytics_customer_reservations 
    ON reservations(customer_id, reservation_date, total_price)
    WHERE customer_id IS NOT NULL;

-- Product performance analysis indexes
CREATE INDEX IF NOT EXISTS idx_analytics_product_abandonment 
    ON abandoned_carts USING GIN(cart_items)
    WHERE cart_items IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_analytics_product_reservations 
    ON reservations(product_id, reservation_date, total_price)
    WHERE product_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_analytics_product_inventory 
    ON product_quantities(product_id, current_quantity, availability_status, last_movement_at);

-- Time-based analytics indexes
CREATE INDEX IF NOT EXISTS idx_analytics_daily_abandonment 
    ON abandoned_carts(store_id, DATE(abandoned_at), cart_status)
    WHERE abandoned_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_analytics_daily_reservations 
    ON reservations(store_id, reservation_date, reservation_status);

CREATE INDEX IF NOT EXISTS idx_analytics_inventory_movements 
    ON product_quantities(store_id, DATE(last_movement_at), last_movement_type)
    WHERE last_movement_at IS NOT NULL;

-- Revenue and value analysis indexes
CREATE INDEX IF NOT EXISTS idx_analytics_cart_value_segments 
    ON abandoned_carts(store_id, cart_value_segment, total_amount)
    WHERE cart_value_segment IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_analytics_reservation_value 
    ON reservations(store_id, booking_value_segment, total_price)
    WHERE booking_value_segment IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_analytics_inventory_value 
    ON product_quantities(store_id, total_value, abc_classification)
    WHERE total_value IS NOT NULL;

-- Geographic analysis indexes
CREATE INDEX IF NOT EXISTS idx_analytics_cart_geography 
    ON abandoned_carts(store_id, country, region, total_amount)
    WHERE country IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_analytics_reservation_geography 
    ON reservations(store_id, venue_country, venue_city, total_price)
    WHERE venue_country IS NOT NULL;

-- Marketing attribution indexes
CREATE INDEX IF NOT EXISTS idx_analytics_cart_attribution 
    ON abandoned_carts(store_id, utm_campaign, utm_source, total_amount)
    WHERE utm_campaign IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_analytics_reservation_attribution 
    ON reservations(store_id, utm_campaign, booking_source, total_price)
    WHERE utm_campaign IS NOT NULL;

-- =====================================================
-- Analytics Views
-- =====================================================

RAISE NOTICE 'Creating analytics views...';

-- Comprehensive analytics overview
CREATE OR REPLACE VIEW analytics_overview AS
SELECT 
    s.id as store_id,
    s.name as store_name,
    
    -- Abandoned carts metrics
    ac_stats.total_abandoned_carts,
    ac_stats.total_abandoned_value,
    ac_stats.average_cart_value,
    ac_stats.cart_recovery_rate,
    
    -- Reservations metrics
    res_stats.total_reservations,
    res_stats.total_reservation_revenue,
    res_stats.average_reservation_value,
    res_stats.reservation_completion_rate,
    
    -- Inventory metrics
    inv_stats.total_products_tracked,
    inv_stats.total_inventory_value,
    inv_stats.products_in_stock,
    inv_stats.products_low_stock,
    inv_stats.average_turnover_rate,
    
    -- Combined metrics
    (COALESCE(ac_stats.total_abandoned_value, 0) + COALESCE(res_stats.total_reservation_revenue, 0)) as total_potential_revenue,
    
    CURRENT_TIMESTAMP as calculated_at
FROM stores s
LEFT JOIN (
    SELECT 
        store_id,
        COUNT(*) as total_abandoned_carts,
        SUM(total_amount) as total_abandoned_value,
        AVG(total_amount) as average_cart_value,
        (COUNT(*) FILTER (WHERE cart_status IN ('recovered', 'converted'))::DECIMAL / NULLIF(COUNT(*), 0)) * 100 as cart_recovery_rate
    FROM abandoned_carts 
    WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY store_id
) ac_stats ON s.id = ac_stats.store_id
LEFT JOIN (
    SELECT 
        store_id,
        COUNT(*) as total_reservations,
        SUM(total_price) as total_reservation_revenue,
        AVG(total_price) as average_reservation_value,
        (COUNT(*) FILTER (WHERE reservation_status = 'completed')::DECIMAL / NULLIF(COUNT(*), 0)) * 100 as reservation_completion_rate
    FROM reservations 
    WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY store_id
) res_stats ON s.id = res_stats.store_id
LEFT JOIN (
    SELECT 
        store_id,
        COUNT(*) as total_products_tracked,
        SUM(total_value) as total_inventory_value,
        COUNT(*) FILTER (WHERE availability_status = 'in_stock') as products_in_stock,
        COUNT(*) FILTER (WHERE availability_status = 'low_stock') as products_low_stock,
        AVG(turnover_rate) as average_turnover_rate
    FROM product_quantities
    GROUP BY store_id
) inv_stats ON s.id = inv_stats.store_id;

-- Daily analytics summary
CREATE OR REPLACE VIEW daily_analytics_summary AS
SELECT 
    analysis_date,
    store_id,
    
    -- Abandoned carts daily metrics
    abandoned_carts_count,
    abandoned_carts_value,
    recovered_carts_count,
    recovered_carts_value,
    
    -- Reservations daily metrics
    new_reservations_count,
    new_reservations_value,
    completed_reservations_count,
    completed_reservations_value,
    
    -- Inventory daily metrics
    inventory_movements_count,
    stock_adjustments_value,
    low_stock_alerts_count,
    
    -- Performance indicators
    CASE 
        WHEN abandoned_carts_count > 0 THEN 
            (recovered_carts_count::DECIMAL / abandoned_carts_count) * 100
        ELSE 0
    END as daily_recovery_rate,
    
    CASE 
        WHEN new_reservations_count > 0 THEN 
            (completed_reservations_count::DECIMAL / new_reservations_count) * 100
        ELSE 0
    END as daily_completion_rate
    
FROM (
    SELECT 
        CURRENT_DATE - generate_series(0, 29) as analysis_date,
        s.id as store_id,
        
        -- Abandoned carts metrics
        COALESCE(ac.abandoned_count, 0) as abandoned_carts_count,
        COALESCE(ac.abandoned_value, 0) as abandoned_carts_value,
        COALESCE(ac.recovered_count, 0) as recovered_carts_count,
        COALESCE(ac.recovered_value, 0) as recovered_carts_value,
        
        -- Reservations metrics
        COALESCE(res.new_count, 0) as new_reservations_count,
        COALESCE(res.new_value, 0) as new_reservations_value,
        COALESCE(res.completed_count, 0) as completed_reservations_count,
        COALESCE(res.completed_value, 0) as completed_reservations_value,
        
        -- Inventory metrics
        COALESCE(inv.movements_count, 0) as inventory_movements_count,
        COALESCE(inv.adjustments_value, 0) as stock_adjustments_value,
        COALESCE(inv.low_stock_count, 0) as low_stock_alerts_count
        
    FROM stores s
    CROSS JOIN generate_series(0, 29) as days_back
    LEFT JOIN (
        SELECT 
            store_id,
            DATE(abandoned_at) as abandon_date,
            COUNT(*) as abandoned_count,
            SUM(total_amount) as abandoned_value,
            COUNT(*) FILTER (WHERE cart_status IN ('recovered', 'converted')) as recovered_count,
            SUM(total_amount) FILTER (WHERE cart_status IN ('recovered', 'converted')) as recovered_value
        FROM abandoned_carts
        WHERE abandoned_at >= CURRENT_DATE - INTERVAL '30 days'
        GROUP BY store_id, DATE(abandoned_at)
    ) ac ON s.id = ac.store_id AND (CURRENT_DATE - days_back) = ac.abandon_date
    LEFT JOIN (
        SELECT 
            store_id,
            reservation_date,
            COUNT(*) as new_count,
            SUM(total_price) as new_value,
            COUNT(*) FILTER (WHERE reservation_status = 'completed') as completed_count,
            SUM(total_price) FILTER (WHERE reservation_status = 'completed') as completed_value
        FROM reservations
        WHERE reservation_date >= CURRENT_DATE - INTERVAL '30 days'
        GROUP BY store_id, reservation_date
    ) res ON s.id = res.store_id AND (CURRENT_DATE - days_back) = res.reservation_date
    LEFT JOIN (
        SELECT 
            store_id,
            DATE(last_movement_at) as movement_date,
            COUNT(*) as movements_count,
            SUM(ABS(last_movement_quantity * COALESCE(unit_cost, 0))) as adjustments_value,
            COUNT(*) FILTER (WHERE availability_status = 'low_stock') as low_stock_count
        FROM product_quantities
        WHERE last_movement_at >= CURRENT_DATE - INTERVAL '30 days'
        GROUP BY store_id, DATE(last_movement_at)
    ) inv ON s.id = inv.store_id AND (CURRENT_DATE - days_back) = inv.movement_date
) daily_data
ORDER BY analysis_date DESC, store_id;

-- Product performance analytics
CREATE OR REPLACE VIEW product_performance_analytics AS
SELECT 
    p.id as product_id,
    p.name as product_name,
    p.sku as product_sku,
    p.store_id,
    
    -- Inventory metrics
    pq.current_quantity,
    pq.available_quantity,
    pq.velocity_category,
    pq.turnover_rate,
    pq.abc_classification,
    pq.total_value as inventory_value,
    
    -- Abandonment metrics
    COALESCE(abandon_stats.abandonment_count, 0) as times_abandoned,
    COALESCE(abandon_stats.abandonment_value, 0) as total_abandonment_value,
    COALESCE(abandon_stats.average_abandon_quantity, 0) as avg_abandon_quantity,
    
    -- Reservation metrics
    COALESCE(reservation_stats.reservation_count, 0) as times_reserved,
    COALESCE(reservation_stats.reservation_revenue, 0) as total_reservation_revenue,
    COALESCE(reservation_stats.completion_rate, 0) as reservation_completion_rate,
    
    -- Performance indicators
    CASE 
        WHEN COALESCE(abandon_stats.abandonment_count, 0) > 0 THEN 'high_abandonment'
        WHEN COALESCE(reservation_stats.reservation_count, 0) > 0 THEN 'popular_reservations'
        WHEN pq.velocity_category = 'fast' THEN 'fast_moving'
        WHEN pq.availability_status = 'low_stock' THEN 'needs_attention'
        ELSE 'normal'
    END as performance_category,
    
    CURRENT_TIMESTAMP as calculated_at
    
FROM products p
LEFT JOIN product_quantities pq ON p.id = pq.product_id
LEFT JOIN (
    SELECT 
        product_id,
        COUNT(*) as abandonment_count,
        SUM(total_amount) as abandonment_value,
        AVG(total_items) as average_abandon_quantity
    FROM abandoned_carts ac
    CROSS JOIN LATERAL (
        SELECT (item->>'product_id')::BIGINT as product_id
        FROM jsonb_array_elements(ac.cart_items) as item
        WHERE item->>'product_id' IS NOT NULL
    ) cart_products
    WHERE ac.created_at >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY product_id
) abandon_stats ON p.id = abandon_stats.product_id
LEFT JOIN (
    SELECT 
        product_id,
        COUNT(*) as reservation_count,
        SUM(total_price) as reservation_revenue,
        (COUNT(*) FILTER (WHERE reservation_status = 'completed')::DECIMAL / NULLIF(COUNT(*), 0)) * 100 as completion_rate
    FROM reservations
    WHERE created_at >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY product_id
) reservation_stats ON p.id = reservation_stats.product_id
WHERE p.is_active = TRUE;

-- Customer analytics view
CREATE OR REPLACE VIEW customer_analytics AS
SELECT 
    c.id as customer_id,
    c.email as customer_email,
    c.name as customer_name,
    c.store_id,
    
    -- Abandoned cart behavior
    COALESCE(ac_stats.total_abandoned_carts, 0) as total_abandoned_carts,
    COALESCE(ac_stats.total_abandoned_value, 0) as total_abandoned_value,
    COALESCE(ac_stats.recovered_carts, 0) as recovered_carts,
    COALESCE(ac_stats.recovery_rate, 0) as cart_recovery_rate,
    
    -- Reservation behavior
    COALESCE(res_stats.total_reservations, 0) as total_reservations,
    COALESCE(res_stats.total_reservation_value, 0) as total_reservation_value,
    COALESCE(res_stats.completed_reservations, 0) as completed_reservations,
    COALESCE(res_stats.completion_rate, 0) as reservation_completion_rate,
    
    -- Customer segmentation
    CASE 
        WHEN COALESCE(ac_stats.total_abandoned_value, 0) + COALESCE(res_stats.total_reservation_value, 0) >= 1000 THEN 'high_value'
        WHEN COALESCE(ac_stats.total_abandoned_value, 0) + COALESCE(res_stats.total_reservation_value, 0) >= 500 THEN 'medium_value'
        WHEN COALESCE(ac_stats.total_abandoned_value, 0) + COALESCE(res_stats.total_reservation_value, 0) > 0 THEN 'low_value'
        ELSE 'inactive'
    END as customer_segment,
    
    -- Engagement metrics
    GREATEST(
        COALESCE(ac_stats.last_activity, '1900-01-01'::DATE),
        COALESCE(res_stats.last_activity, '1900-01-01'::DATE)
    ) as last_activity_date,
    
    CURRENT_TIMESTAMP as calculated_at
    
FROM customers c
LEFT JOIN (
    SELECT 
        customer_id,
        COUNT(*) as total_abandoned_carts,
        SUM(total_amount) as total_abandoned_value,
        COUNT(*) FILTER (WHERE cart_status IN ('recovered', 'converted')) as recovered_carts,
        (COUNT(*) FILTER (WHERE cart_status IN ('recovered', 'converted'))::DECIMAL / NULLIF(COUNT(*), 0)) * 100 as recovery_rate,
        MAX(DATE(last_activity_at)) as last_activity
    FROM abandoned_carts
    WHERE customer_id IS NOT NULL
        AND created_at >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY customer_id
) ac_stats ON c.id = ac_stats.customer_id
LEFT JOIN (
    SELECT 
        customer_id,
        COUNT(*) as total_reservations,
        SUM(total_price) as total_reservation_value,
        COUNT(*) FILTER (WHERE reservation_status = 'completed') as completed_reservations,
        (COUNT(*) FILTER (WHERE reservation_status = 'completed')::DECIMAL / NULLIF(COUNT(*), 0)) * 100 as completion_rate,
        MAX(reservation_date) as last_activity
    FROM reservations
    WHERE customer_id IS NOT NULL
        AND created_at >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY customer_id
) res_stats ON c.id = res_stats.customer_id;

-- =====================================================
-- Analytics Helper Functions
-- =====================================================

RAISE NOTICE 'Creating analytics helper functions...';

-- Function to get comprehensive analytics dashboard
CREATE OR REPLACE FUNCTION get_analytics_dashboard(
    store_id_param BIGINT DEFAULT NULL,
    date_from DATE DEFAULT CURRENT_DATE - INTERVAL '30 days',
    date_to DATE DEFAULT CURRENT_DATE
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'period', jsonb_build_object(
            'from', date_from,
            'to', date_to,
            'days', date_to - date_from + 1
        ),
        'abandoned_carts', (
            SELECT jsonb_build_object(
                'total_carts', COUNT(*),
                'total_value', COALESCE(SUM(total_amount), 0),
                'recovery_rate', CASE 
                    WHEN COUNT(*) > 0 THEN 
                        (COUNT(*) FILTER (WHERE cart_status IN ('recovered', 'converted'))::DECIMAL / COUNT(*)) * 100
                    ELSE 0
                END,
                'average_cart_value', COALESCE(AVG(total_amount), 0),
                'top_abandonment_stages', (
                    SELECT jsonb_object_agg(abandonment_stage, stage_count)
                    FROM (
                        SELECT abandonment_stage, COUNT(*) as stage_count
                        FROM abandoned_carts
                        WHERE (store_id_param IS NULL OR store_id = store_id_param)
                            AND DATE(abandoned_at) BETWEEN date_from AND date_to
                            AND abandonment_stage IS NOT NULL
                        GROUP BY abandonment_stage
                        ORDER BY stage_count DESC
                        LIMIT 5
                    ) stages
                )
            )
            FROM abandoned_carts
            WHERE (store_id_param IS NULL OR store_id = store_id_param)
                AND DATE(abandoned_at) BETWEEN date_from AND date_to
        ),
        'reservations', (
            SELECT jsonb_build_object(
                'total_reservations', COUNT(*),
                'total_revenue', COALESCE(SUM(total_price), 0),
                'completion_rate', CASE 
                    WHEN COUNT(*) > 0 THEN 
                        (COUNT(*) FILTER (WHERE reservation_status = 'completed')::DECIMAL / COUNT(*)) * 100
                    ELSE 0
                END,
                'average_booking_value', COALESCE(AVG(total_price), 0),
                'popular_services', (
                    SELECT jsonb_object_agg(service_type, service_count)
                    FROM (
                        SELECT service_type, COUNT(*) as service_count
                        FROM reservations
                        WHERE (store_id_param IS NULL OR store_id = store_id_param)
                            AND reservation_date BETWEEN date_from AND date_to
                            AND service_type IS NOT NULL
                        GROUP BY service_type
                        ORDER BY service_count DESC
                        LIMIT 5
                    ) services
                )
            )
            FROM reservations
            WHERE (store_id_param IS NULL OR store_id = store_id_param)
                AND reservation_date BETWEEN date_from AND date_to
        ),
        'inventory', (
            SELECT jsonb_build_object(
                'total_products', COUNT(*),
                'total_value', COALESCE(SUM(total_value), 0),
                'in_stock_products', COUNT(*) FILTER (WHERE availability_status = 'in_stock'),
                'low_stock_products', COUNT(*) FILTER (WHERE availability_status = 'low_stock'),
                'out_of_stock_products', COUNT(*) FILTER (WHERE availability_status = 'out_of_stock'),
                'average_turnover', COALESCE(AVG(turnover_rate), 0),
                'top_movers', (
                    SELECT jsonb_agg(jsonb_build_object(
                        'product_id', product_id,
                        'velocity_category', velocity_category,
                        'turnover_rate', turnover_rate
                    ))
                    FROM (
                        SELECT product_id, velocity_category, turnover_rate
                        FROM product_quantities
                        WHERE (store_id_param IS NULL OR store_id = store_id_param)
                            AND velocity_category = 'fast'
                        ORDER BY turnover_rate DESC NULLS LAST
                        LIMIT 10
                    ) top_products
                )
            )
            FROM product_quantities
            WHERE (store_id_param IS NULL OR store_id = store_id_param)
        ),
        'trends', (
            SELECT jsonb_agg(jsonb_build_object(
                'date', trend_date,
                'abandoned_carts', daily_abandoned,
                'reservations', daily_reservations,
                'inventory_movements', daily_movements
            ))
            FROM (
                SELECT 
                    analysis_date as trend_date,
                    SUM(abandoned_carts_count) as daily_abandoned,
                    SUM(new_reservations_count) as daily_reservations,
                    SUM(inventory_movements_count) as daily_movements
                FROM daily_analytics_summary
                WHERE (store_id_param IS NULL OR store_id = store_id_param)
                    AND analysis_date BETWEEN date_from AND date_to
                GROUP BY analysis_date
                ORDER BY analysis_date
            ) daily_trends
        ),
        'generated_at', CURRENT_TIMESTAMP
    ) INTO result;
    
    RETURN COALESCE(result, '{"error": "No data found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- Function to generate analytics report
CREATE OR REPLACE FUNCTION generate_analytics_report(
    store_id_param BIGINT DEFAULT NULL,
    report_type VARCHAR DEFAULT 'summary', -- summary, detailed, trends
    date_from DATE DEFAULT CURRENT_DATE - INTERVAL '30 days',
    date_to DATE DEFAULT CURRENT_DATE
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    CASE report_type
        WHEN 'summary' THEN
            result := get_analytics_dashboard(store_id_param, date_from, date_to);
            
        WHEN 'detailed' THEN
            SELECT jsonb_build_object(
                'report_type', 'detailed',
                'period', jsonb_build_object('from', date_from, 'to', date_to),
                'abandoned_carts_detailed', (
                    SELECT jsonb_agg(jsonb_build_object(
                        'cart_id', id,
                        'customer_email', customer_email,
                        'total_amount', total_amount,
                        'abandonment_stage', abandonment_stage,
                        'recovery_score', recovery_score,
                        'abandoned_at', abandoned_at
                    ))
                    FROM abandoned_carts
                    WHERE (store_id_param IS NULL OR store_id = store_id_param)
                        AND DATE(abandoned_at) BETWEEN date_from AND date_to
                    ORDER BY recovery_score DESC, total_amount DESC
                    LIMIT 100
                ),
                'reservations_detailed', (
                    SELECT jsonb_agg(jsonb_build_object(
                        'reservation_id', id,
                        'customer_name', customer_name,
                        'service_type', service_type,
                        'total_price', total_price,
                        'reservation_status', reservation_status,
                        'reservation_date', reservation_date
                    ))
                    FROM reservations
                    WHERE (store_id_param IS NULL OR store_id = store_id_param)
                        AND reservation_date BETWEEN date_from AND date_to
                    ORDER BY total_price DESC
                    LIMIT 100
                ),
                'inventory_detailed', (
                    SELECT jsonb_agg(jsonb_build_object(
                        'product_id', product_id,
                        'current_quantity', current_quantity,
                        'availability_status', availability_status,
                        'velocity_category', velocity_category,
                        'total_value', total_value
                    ))
                    FROM product_quantities
                    WHERE (store_id_param IS NULL OR store_id = store_id_param)
                    ORDER BY total_value DESC NULLS LAST
                    LIMIT 100
                )
            ) INTO result;
            
        WHEN 'trends' THEN
            SELECT jsonb_build_object(
                'report_type', 'trends',
                'period', jsonb_build_object('from', date_from, 'to', date_to),
                'daily_trends', (
                    SELECT jsonb_agg(jsonb_build_object(
                        'date', analysis_date,
                        'metrics', jsonb_build_object(
                            'abandoned_carts', abandoned_carts_count,
                            'abandoned_value', abandoned_carts_value,
                            'recovery_rate', daily_recovery_rate,
                            'reservations', new_reservations_count,
                            'reservation_value', new_reservations_value,
                            'completion_rate', daily_completion_rate
                        )
                    ))
                    FROM daily_analytics_summary
                    WHERE (store_id_param IS NULL OR store_id = store_id_param)
                        AND analysis_date BETWEEN date_from AND date_to
                    ORDER BY analysis_date
                )
            ) INTO result;
            
        ELSE
            result := '{"error": "Invalid report type"}'::jsonb;
    END CASE;
    
    RETURN COALESCE(result, '{"error": "No data found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- Function to get top performing products
CREATE OR REPLACE FUNCTION get_top_performing_products(
    store_id_param BIGINT DEFAULT NULL,
    metric VARCHAR DEFAULT 'revenue', -- revenue, quantity, abandonment
    limit_param INTEGER DEFAULT 10
)
RETURNS TABLE (
    product_id BIGINT,
    product_name VARCHAR,
    metric_value DECIMAL,
    performance_category VARCHAR,
    additional_info JSONB
) AS $$
BEGIN
    CASE metric
        WHEN 'revenue' THEN
            RETURN QUERY
            SELECT 
                ppa.product_id,
                ppa.product_name,
                ppa.total_reservation_revenue as metric_value,
                ppa.performance_category,
                jsonb_build_object(
                    'times_reserved', ppa.times_reserved,
                    'completion_rate', ppa.reservation_completion_rate,
                    'inventory_value', ppa.inventory_value
                ) as additional_info
            FROM product_performance_analytics ppa
            WHERE (store_id_param IS NULL OR ppa.store_id = store_id_param)
            ORDER BY ppa.total_reservation_revenue DESC NULLS LAST
            LIMIT limit_param;
            
        WHEN 'abandonment' THEN
            RETURN QUERY
            SELECT 
                ppa.product_id,
                ppa.product_name,
                ppa.total_abandonment_value as metric_value,
                ppa.performance_category,
                jsonb_build_object(
                    'times_abandoned', ppa.times_abandoned,
                    'avg_abandon_quantity', ppa.avg_abandon_quantity,
                    'velocity_category', ppa.velocity_category
                ) as additional_info
            FROM product_performance_analytics ppa
            WHERE (store_id_param IS NULL OR ppa.store_id = store_id_param)
            ORDER BY ppa.total_abandonment_value DESC NULLS LAST
            LIMIT limit_param;
            
        ELSE -- Default to inventory value
            RETURN QUERY
            SELECT 
                ppa.product_id,
                ppa.product_name,
                ppa.inventory_value as metric_value,
                ppa.performance_category,
                jsonb_build_object(
                    'current_quantity', ppa.current_quantity,
                    'turnover_rate', ppa.turnover_rate,
                    'abc_classification', ppa.abc_classification
                ) as additional_info
            FROM product_performance_analytics ppa
            WHERE (store_id_param IS NULL OR ppa.store_id = store_id_param)
            ORDER BY ppa.inventory_value DESC NULLS LAST
            LIMIT limit_param;
    END CASE;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Comments for Documentation
-- =====================================================

COMMENT ON VIEW analytics_overview IS 'Comprehensive analytics overview combining abandoned carts, reservations, and inventory metrics';
COMMENT ON VIEW daily_analytics_summary IS 'Daily summary of key analytics metrics for trend analysis';
COMMENT ON VIEW product_performance_analytics IS 'Product-level performance analytics combining multiple data sources';
COMMENT ON VIEW customer_analytics IS 'Customer behavior analytics based on abandoned carts and reservations';

COMMENT ON FUNCTION get_analytics_dashboard(BIGINT, DATE, DATE) IS 'Get comprehensive analytics dashboard data for a store and date range';
COMMENT ON FUNCTION generate_analytics_report(BIGINT, VARCHAR, DATE, DATE) IS 'Generate various types of analytics reports';
COMMENT ON FUNCTION get_top_performing_products(BIGINT, VARCHAR, INTEGER) IS 'Get top performing products based on different metrics';

RAISE NOTICE 'Analytics and Reports Tables setup completed successfully!';
RAISE NOTICE 'Created tables: abandoned_carts, reservations, product_quantities';
RAISE NOTICE 'Created views: analytics_overview, daily_analytics_summary, product_performance_analytics, customer_analytics';
RAISE NOTICE 'Created functions: get_analytics_dashboard, generate_analytics_report, get_top_performing_products';