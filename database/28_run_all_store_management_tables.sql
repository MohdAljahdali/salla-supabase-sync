-- =====================================================
-- Store Management Tables Setup Script
-- =====================================================
-- This script sets up all store management tables including
-- branches, currencies, and countries with their relationships

-- Include individual table scripts
\i 25_branches_table.sql
\i 26_currencies_table.sql
\i 27_countries_table.sql

-- =====================================================
-- Cross-Table Indexes for Better Performance
-- =====================================================

-- Indexes for relationships between store management tables
CREATE INDEX IF NOT EXISTS idx_branches_countries_relation ON branches(store_id, country);
CREATE INDEX IF NOT EXISTS idx_currencies_countries_relation ON currencies(store_id, code);
CREATE INDEX IF NOT EXISTS idx_countries_currencies_relation ON countries(store_id, currency_code);

-- Performance indexes for common queries
CREATE INDEX IF NOT EXISTS idx_store_management_active_elements ON branches(store_id, is_active)
    WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_store_management_shipping_countries ON countries(store_id, is_shipping_available)
    WHERE is_shipping_available = TRUE;
CREATE INDEX IF NOT EXISTS idx_store_management_active_currencies ON currencies(store_id, is_active)
    WHERE is_active = TRUE;

-- Search optimization indexes
CREATE INDEX IF NOT EXISTS idx_store_management_search_branches ON branches 
    USING GIN(to_tsvector('english', name || ' ' || COALESCE(description, '')));
CREATE INDEX IF NOT EXISTS idx_store_management_search_countries ON countries 
    USING GIN(to_tsvector('english', name || ' ' || COALESCE(official_name, '')));

-- =====================================================
-- Store Management Views
-- =====================================================

-- View: Store Management Overview
CREATE OR REPLACE VIEW store_management_overview AS
SELECT 
    s.id as store_id,
    s.name as store_name,
    
    -- Branches summary
    COUNT(DISTINCT b.id) as total_branches,
    COUNT(DISTINCT b.id) FILTER (WHERE b.is_active = TRUE) as active_branches,
    COUNT(DISTINCT b.id) FILTER (WHERE b.is_main_branch = TRUE) as main_branches,
    COALESCE(SUM(b.total_sales), 0) as branches_total_sales,
    COALESCE(SUM(b.total_orders), 0) as branches_total_orders,
    
    -- Currencies summary
    COUNT(DISTINCT cur.id) as total_currencies,
    COUNT(DISTINCT cur.id) FILTER (WHERE cur.is_active = TRUE) as active_currencies,
    (SELECT cur2.code FROM currencies cur2 WHERE cur2.store_id = s.id AND cur2.is_default = TRUE LIMIT 1) as default_currency,
    (SELECT cur2.code FROM currencies cur2 WHERE cur2.store_id = s.id AND cur2.is_base_currency = TRUE LIMIT 1) as base_currency,
    COALESCE(SUM(cur.total_volume), 0) as currencies_total_volume,
    
    -- Countries summary
    COUNT(DISTINCT c.id) as total_countries,
    COUNT(DISTINCT c.id) FILTER (WHERE c.is_active = TRUE) as active_countries,
    COUNT(DISTINCT c.id) FILTER (WHERE c.shipping_enabled = TRUE) as shipping_enabled_countries,
    COUNT(DISTINCT c.id) FILTER (WHERE c.is_payment_available = TRUE) as payment_enabled_countries,
    COALESCE(SUM(c.total_sales), 0) as countries_total_sales,
    COALESCE(SUM(c.total_orders), 0) as countries_total_orders,
    
    -- Geographic coverage
    COUNT(DISTINCT c.continent) as covered_continents,
    COUNT(DISTINCT c.region) as covered_regions,
    
    -- Performance metrics
    CASE 
        WHEN SUM(b.total_orders + c.total_orders) > 0 THEN 
            SUM(b.total_sales + c.total_sales) / SUM(b.total_orders + c.total_orders)
        ELSE 0
    END as average_order_value,
    
    -- Last update
    GREATEST(
        COALESCE(MAX(b.updated_at), '1970-01-01'::timestamptz),
        COALESCE(MAX(cur.updated_at), '1970-01-01'::timestamptz),
        COALESCE(MAX(c.updated_at), '1970-01-01'::timestamptz)
    ) as last_updated
    
FROM stores s
LEFT JOIN branches b ON s.id = b.store_id
LEFT JOIN currencies cur ON s.id = cur.store_id
LEFT JOIN countries c ON s.id = c.store_id
GROUP BY s.id, s.name;

-- View: Active Store Management Elements
CREATE OR REPLACE VIEW active_store_management_elements AS
SELECT 
    'branch' as element_type,
    b.id as element_id,
    b.store_id,
    b.name as element_name,
    b.status,
    b.is_active,
    b.total_sales,
    b.total_orders,
    b.created_at,
    b.updated_at,
    jsonb_build_object(
        'branch_type', b.branch_type,
        'city', b.city,
        'country', b.country,
        'manages_inventory', b.manages_inventory
    ) as element_details
FROM branches b
WHERE b.is_active = TRUE

UNION ALL

SELECT 
    'currency' as element_type,
    cur.id as element_id,
    cur.store_id,
    cur.name as element_name,
    cur.status,
    cur.is_active,
    cur.total_volume as total_sales,
    cur.total_transactions as total_orders,
    cur.created_at,
    cur.updated_at,
    jsonb_build_object(
        'code', cur.code,
        'symbol', cur.symbol,
        'exchange_rate', cur.exchange_rate,
        'is_default', cur.is_default
    ) as element_details
FROM currencies cur
WHERE cur.is_active = TRUE

UNION ALL

SELECT 
    'country' as element_type,
    c.id as element_id,
    c.store_id,
    c.name as element_name,
    c.status,
    c.is_active,
    c.total_sales,
    c.total_orders,
    c.created_at,
    c.updated_at,
    jsonb_build_object(
        'code', c.code,
        'continent', c.continent,
        'region', c.region,
        'shipping_enabled', c.shipping_enabled
    ) as element_details
FROM countries c
WHERE c.is_active = TRUE

ORDER BY total_sales DESC, element_name;

-- View: Store Management Performance Report
CREATE OR REPLACE VIEW store_management_performance_report AS
SELECT 
    s.id as store_id,
    s.name as store_name,
    DATE_TRUNC('month', CURRENT_DATE) as report_month,
    
    -- Branches performance
    jsonb_build_object(
        'total_branches', COUNT(DISTINCT b.id),
        'active_branches', COUNT(DISTINCT b.id) FILTER (WHERE b.is_active = TRUE),
        'total_sales', COALESCE(SUM(b.total_sales), 0),
        'total_orders', COALESCE(SUM(b.total_orders), 0),
        'average_sales_per_branch', CASE 
            WHEN COUNT(DISTINCT b.id) FILTER (WHERE b.is_active = TRUE) > 0 THEN 
                COALESCE(SUM(b.total_sales), 0) / COUNT(DISTINCT b.id) FILTER (WHERE b.is_active = TRUE)
            ELSE 0
        END,
        'top_performing_branch', (
            SELECT jsonb_build_object('name', b2.name, 'sales', b2.total_sales)
            FROM branches b2 
            WHERE b2.store_id = s.id AND b2.is_active = TRUE
            ORDER BY b2.total_sales DESC 
            LIMIT 1
        )
    ) as branches_performance,
    
    -- Currencies performance
    jsonb_build_object(
        'total_currencies', COUNT(DISTINCT cur.id),
        'active_currencies', COUNT(DISTINCT cur.id) FILTER (WHERE cur.is_active = TRUE),
        'total_volume', COALESCE(SUM(cur.total_volume), 0),
        'total_transactions', COALESCE(SUM(cur.total_transactions), 0),
        'most_used_currency', (
            SELECT jsonb_build_object('code', cur2.code, 'volume', cur2.total_volume)
            FROM currencies cur2 
            WHERE cur2.store_id = s.id AND cur2.is_active = TRUE
            ORDER BY cur2.total_volume DESC 
            LIMIT 1
        )
    ) as currencies_performance,
    
    -- Countries performance
    jsonb_build_object(
        'total_countries', COUNT(DISTINCT c.id),
        'active_countries', COUNT(DISTINCT c.id) FILTER (WHERE c.is_active = TRUE),
        'shipping_countries', COUNT(DISTINCT c.id) FILTER (WHERE c.shipping_enabled = TRUE),
        'total_sales', COALESCE(SUM(c.total_sales), 0),
        'total_orders', COALESCE(SUM(c.total_orders), 0),
        'top_performing_country', (
            SELECT jsonb_build_object('name', c2.name, 'code', c2.code, 'sales', c2.total_sales)
            FROM countries c2 
            WHERE c2.store_id = s.id AND c2.is_active = TRUE
            ORDER BY c2.total_sales DESC 
            LIMIT 1
        ),
        'geographic_coverage', jsonb_build_object(
            'continents', COUNT(DISTINCT c.continent),
            'regions', COUNT(DISTINCT c.region)
        )
    ) as countries_performance,
    
    -- Overall metrics
    jsonb_build_object(
        'total_revenue', COALESCE(SUM(b.total_sales), 0) + COALESCE(SUM(c.total_sales), 0),
        'total_orders', COALESCE(SUM(b.total_orders), 0) + COALESCE(SUM(c.total_orders), 0),
        'average_order_value', CASE 
            WHEN (COALESCE(SUM(b.total_orders), 0) + COALESCE(SUM(c.total_orders), 0)) > 0 THEN 
                (COALESCE(SUM(b.total_sales), 0) + COALESCE(SUM(c.total_sales), 0)) / 
                (COALESCE(SUM(b.total_orders), 0) + COALESCE(SUM(c.total_orders), 0))
            ELSE 0
        END,
        'management_efficiency_score', CASE 
            WHEN COUNT(DISTINCT b.id) + COUNT(DISTINCT cur.id) + COUNT(DISTINCT c.id) > 0 THEN
                (COUNT(DISTINCT b.id) FILTER (WHERE b.is_active = TRUE) + 
                 COUNT(DISTINCT cur.id) FILTER (WHERE cur.is_active = TRUE) + 
                 COUNT(DISTINCT c.id) FILTER (WHERE c.is_active = TRUE))::DECIMAL / 
                (COUNT(DISTINCT b.id) + COUNT(DISTINCT cur.id) + COUNT(DISTINCT c.id))
            ELSE 0
        END
    ) as overall_metrics
    
FROM stores s
LEFT JOIN branches b ON s.id = b.store_id
LEFT JOIN currencies cur ON s.id = cur.store_id
LEFT JOIN countries c ON s.id = c.store_id
GROUP BY s.id, s.name;

-- =====================================================
-- Store Management Helper Functions
-- =====================================================

-- Function to get comprehensive store management dashboard
CREATE OR REPLACE FUNCTION get_store_management_dashboard(store_id_param BIGINT)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'store_id', store_id_param,
        'branches', get_store_branches_stats(store_id_param),
        'currencies', get_store_currencies_stats(store_id_param),
        'countries', get_store_countries_stats(store_id_param),
        'summary', (
            SELECT jsonb_build_object(
                'total_elements', 
                    (SELECT COUNT(*) FROM branches WHERE store_id = store_id_param) +
                    (SELECT COUNT(*) FROM currencies WHERE store_id = store_id_param) +
                    (SELECT COUNT(*) FROM countries WHERE store_id = store_id_param),
                'active_elements',
                    (SELECT COUNT(*) FROM branches WHERE store_id = store_id_param AND is_active = TRUE) +
                    (SELECT COUNT(*) FROM currencies WHERE store_id = store_id_param AND is_active = TRUE) +
                    (SELECT COUNT(*) FROM countries WHERE store_id = store_id_param AND is_active = TRUE),
                'total_revenue',
                    COALESCE((SELECT SUM(total_sales) FROM branches WHERE store_id = store_id_param), 0) +
                    COALESCE((SELECT SUM(total_sales) FROM countries WHERE store_id = store_id_param), 0),
                'setup_completion_percentage', (
                    CASE 
                        WHEN (SELECT COUNT(*) FROM branches WHERE store_id = store_id_param) > 0 THEN 33.33
                        ELSE 0
                    END +
                    CASE 
                        WHEN (SELECT COUNT(*) FROM currencies WHERE store_id = store_id_param) > 0 THEN 33.33
                        ELSE 0
                    END +
                    CASE 
                        WHEN (SELECT COUNT(*) FROM countries WHERE store_id = store_id_param) > 0 THEN 33.34
                        ELSE 0
                    END
                )
            )
        ),
        'generated_at', CURRENT_TIMESTAMP
    ) INTO result;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to search across all store management elements
CREATE OR REPLACE FUNCTION search_store_management_elements(
    search_term TEXT,
    store_id_param BIGINT DEFAULT NULL,
    element_type VARCHAR DEFAULT NULL, -- 'branch', 'currency', 'country'
    is_active_param BOOLEAN DEFAULT NULL,
    limit_param INTEGER DEFAULT 50,
    offset_param INTEGER DEFAULT 0
)
RETURNS TABLE (
    element_type VARCHAR,
    element_id BIGINT,
    element_name VARCHAR,
    store_id BIGINT,
    status VARCHAR,
    is_active BOOLEAN,
    total_value DECIMAL,
    details JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        'branch'::VARCHAR as element_type,
        b.id as element_id,
        b.name as element_name,
        b.store_id,
        b.status,
        b.is_active,
        b.total_sales as total_value,
        jsonb_build_object(
            'branch_type', b.branch_type,
            'city', b.city,
            'country', b.country,
            'total_orders', b.total_orders
        ) as details
    FROM branches b
    WHERE 
        (store_id_param IS NULL OR b.store_id = store_id_param)
        AND (element_type IS NULL OR element_type = 'branch')
        AND (is_active_param IS NULL OR b.is_active = is_active_param)
        AND (search_term IS NULL OR (
            b.name ILIKE '%' || search_term || '%' OR
            b.branch_code ILIKE '%' || search_term || '%' OR
            b.description ILIKE '%' || search_term || '%'
        ))
    
    UNION ALL
    
    SELECT 
        'currency'::VARCHAR as element_type,
        cur.id as element_id,
        cur.name as element_name,
        cur.store_id,
        cur.status,
        cur.is_active,
        cur.total_volume as total_value,
        jsonb_build_object(
            'code', cur.code,
            'symbol', cur.symbol,
            'exchange_rate', cur.exchange_rate,
            'total_transactions', cur.total_transactions
        ) as details
    FROM currencies cur
    WHERE 
        (store_id_param IS NULL OR cur.store_id = store_id_param)
        AND (element_type IS NULL OR element_type = 'currency')
        AND (is_active_param IS NULL OR cur.is_active = is_active_param)
        AND (search_term IS NULL OR (
            cur.name ILIKE '%' || search_term || '%' OR
            cur.code ILIKE '%' || search_term || '%'
        ))
    
    UNION ALL
    
    SELECT 
        'country'::VARCHAR as element_type,
        c.id as element_id,
        c.name as element_name,
        c.store_id,
        c.status,
        c.is_active,
        c.total_sales as total_value,
        jsonb_build_object(
            'code', c.code,
            'continent', c.continent,
            'region', c.region,
            'total_orders', c.total_orders
        ) as details
    FROM countries c
    WHERE 
        (store_id_param IS NULL OR c.store_id = store_id_param)
        AND (element_type IS NULL OR element_type = 'country')
        AND (is_active_param IS NULL OR c.is_active = is_active_param)
        AND (search_term IS NULL OR (
            c.name ILIKE '%' || search_term || '%' OR
            c.code ILIKE '%' || search_term || '%' OR
            c.official_name ILIKE '%' || search_term || '%'
        ))
    
    ORDER BY total_value DESC, element_name
    LIMIT limit_param OFFSET offset_param;
END;
$$ LANGUAGE plpgsql;

-- Function to generate store management reports
CREATE OR REPLACE FUNCTION generate_store_management_report(
    store_id_param BIGINT,
    report_type VARCHAR DEFAULT 'summary', -- 'summary', 'detailed', 'performance'
    date_from TIMESTAMPTZ DEFAULT NULL,
    date_to TIMESTAMPTZ DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
    date_filter_from TIMESTAMPTZ;
    date_filter_to TIMESTAMPTZ;
BEGIN
    -- Set default date range if not provided
    date_filter_from := COALESCE(date_from, CURRENT_TIMESTAMP - INTERVAL '30 days');
    date_filter_to := COALESCE(date_to, CURRENT_TIMESTAMP);
    
    IF report_type = 'summary' THEN
        SELECT jsonb_build_object(
            'report_type', 'summary',
            'store_id', store_id_param,
            'date_range', jsonb_build_object(
                'from', date_filter_from,
                'to', date_filter_to
            ),
            'branches_summary', (
                SELECT jsonb_build_object(
                    'total', COUNT(*),
                    'active', COUNT(*) FILTER (WHERE is_active = TRUE),
                    'total_sales', COALESCE(SUM(total_sales), 0)
                )
                FROM branches 
                WHERE store_id = store_id_param
            ),
            'currencies_summary', (
                SELECT jsonb_build_object(
                    'total', COUNT(*),
                    'active', COUNT(*) FILTER (WHERE is_active = TRUE),
                    'total_volume', COALESCE(SUM(total_volume), 0)
                )
                FROM currencies 
                WHERE store_id = store_id_param
            ),
            'countries_summary', (
                SELECT jsonb_build_object(
                    'total', COUNT(*),
                    'active', COUNT(*) FILTER (WHERE is_active = TRUE),
                    'shipping_enabled', COUNT(*) FILTER (WHERE shipping_enabled = TRUE),
                    'total_sales', COALESCE(SUM(total_sales), 0)
                )
                FROM countries 
                WHERE store_id = store_id_param
            ),
            'generated_at', CURRENT_TIMESTAMP
        ) INTO result;
        
    ELSIF report_type = 'detailed' THEN
        SELECT jsonb_build_object(
            'report_type', 'detailed',
            'store_id', store_id_param,
            'branches', get_store_branches_stats(store_id_param),
            'currencies', get_store_currencies_stats(store_id_param),
            'countries', get_store_countries_stats(store_id_param),
            'generated_at', CURRENT_TIMESTAMP
        ) INTO result;
        
    ELSIF report_type = 'performance' THEN
        SELECT jsonb_build_object(
            'report_type', 'performance',
            'store_id', store_id_param,
            'performance_data', (
                SELECT row_to_json(smp.*)
                FROM store_management_performance_report smp
                WHERE smp.store_id = store_id_param
                LIMIT 1
            ),
            'generated_at', CURRENT_TIMESTAMP
        ) INTO result;
    END IF;
    
    RETURN COALESCE(result, '{"error": "Invalid report type"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- Function to cleanup inactive store management elements
CREATE OR REPLACE FUNCTION cleanup_inactive_store_management_elements(
    store_id_param BIGINT DEFAULT NULL,
    days_inactive INTEGER DEFAULT 90
)
RETURNS JSONB AS $$
DECLARE
    cleanup_date TIMESTAMPTZ;
    branches_cleaned INTEGER := 0;
    currencies_cleaned INTEGER := 0;
    countries_cleaned INTEGER := 0;
BEGIN
    cleanup_date := CURRENT_TIMESTAMP - INTERVAL '1 day' * days_inactive;
    
    -- Cleanup inactive branches (mark as inactive, don't delete)
    UPDATE branches 
    SET 
        is_active = FALSE,
        status = 'inactive',
        updated_at = CURRENT_TIMESTAMP
    WHERE 
        (store_id_param IS NULL OR store_id = store_id_param)
        AND is_active = TRUE
        AND updated_at < cleanup_date
        AND total_orders = 0
        AND total_sales = 0;
    
    GET DIAGNOSTICS branches_cleaned = ROW_COUNT;
    
    -- Cleanup inactive currencies (mark as inactive)
    UPDATE currencies 
    SET 
        is_active = FALSE,
        status = 'inactive',
        updated_at = CURRENT_TIMESTAMP
    WHERE 
        (store_id_param IS NULL OR store_id = store_id_param)
        AND is_active = TRUE
        AND updated_at < cleanup_date
        AND total_transactions = 0
        AND total_volume = 0
        AND is_default = FALSE
        AND is_base_currency = FALSE;
    
    GET DIAGNOSTICS currencies_cleaned = ROW_COUNT;
    
    -- Cleanup inactive countries (mark as inactive)
    UPDATE countries 
    SET 
        is_active = FALSE,
        status = 'inactive',
        updated_at = CURRENT_TIMESTAMP
    WHERE 
        (store_id_param IS NULL OR store_id = store_id_param)
        AND is_active = TRUE
        AND updated_at < cleanup_date
        AND total_orders = 0
        AND total_sales = 0;
    
    GET DIAGNOSTICS countries_cleaned = ROW_COUNT;
    
    RETURN jsonb_build_object(
        'cleanup_date', cleanup_date,
        'store_id', store_id_param,
        'branches_deactivated', branches_cleaned,
        'currencies_deactivated', currencies_cleaned,
        'countries_deactivated', countries_cleaned,
        'total_elements_cleaned', branches_cleaned + currencies_cleaned + countries_cleaned,
        'cleanup_performed_at', CURRENT_TIMESTAMP
    );
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Comments for Documentation
-- =====================================================

COMMENT ON VIEW store_management_overview IS 'Comprehensive overview of store management elements per store';
COMMENT ON VIEW active_store_management_elements IS 'Unified view of all active store management elements';
COMMENT ON VIEW store_management_performance_report IS 'Performance metrics for store management elements';

COMMENT ON FUNCTION get_store_management_dashboard(BIGINT) IS 'Get comprehensive store management dashboard data';
COMMENT ON FUNCTION search_store_management_elements(TEXT, BIGINT, VARCHAR, BOOLEAN, INTEGER, INTEGER) IS 'Search across all store management elements';
COMMENT ON FUNCTION generate_store_management_report(BIGINT, VARCHAR, TIMESTAMPTZ, TIMESTAMPTZ) IS 'Generate various types of store management reports';
COMMENT ON FUNCTION cleanup_inactive_store_management_elements(BIGINT, INTEGER) IS 'Clean up inactive store management elements';