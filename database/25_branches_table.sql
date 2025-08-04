-- =====================================================
-- Branches Table for Salla-Supabase Integration
-- =====================================================
-- This table stores information about store branches
-- including inventory management and product allocation

CREATE TABLE IF NOT EXISTS branches (
    -- Primary identification
    id BIGSERIAL PRIMARY KEY,
    salla_branch_id VARCHAR(255) UNIQUE, -- Salla API branch identifier
    
    -- Store relationship (required)
    store_id BIGINT NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Basic branch information
    name VARCHAR(255) NOT NULL,
    name_ar VARCHAR(255), -- Arabic name
    name_en VARCHAR(255), -- English name
    branch_code VARCHAR(100) UNIQUE, -- Internal branch code
    branch_slug VARCHAR(255), -- URL-friendly identifier
    
    -- Branch description and details
    description TEXT,
    description_ar TEXT, -- Arabic description
    description_en TEXT, -- English description
    short_description VARCHAR(500),
    
    -- Location and contact information
    address JSONB, -- Full address object
    city VARCHAR(255),
    state VARCHAR(255),
    country VARCHAR(255),
    postal_code VARCHAR(20),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    timezone VARCHAR(100),
    
    -- Contact details
    phone VARCHAR(50),
    mobile VARCHAR(50),
    email VARCHAR(255),
    website VARCHAR(500),
    
    -- Branch type and classification
    branch_type VARCHAR(100) DEFAULT 'physical', -- physical, virtual, warehouse, showroom
    branch_category VARCHAR(100), -- main, secondary, outlet, franchise
    branch_size VARCHAR(50), -- small, medium, large, xl
    
    -- Operating information
    operating_hours JSONB, -- Weekly schedule
    is_24_hours BOOLEAN DEFAULT FALSE,
    special_hours JSONB, -- Holiday/special operating hours
    
    -- Status and visibility
    status VARCHAR(50) DEFAULT 'active', -- active, inactive, maintenance, closed
    is_active BOOLEAN DEFAULT TRUE,
    is_visible BOOLEAN DEFAULT TRUE,
    is_main_branch BOOLEAN DEFAULT FALSE,
    
    -- Inventory management
    manages_inventory BOOLEAN DEFAULT TRUE,
    inventory_method VARCHAR(50) DEFAULT 'fifo', -- fifo, lifo, weighted_average
    low_stock_threshold INTEGER DEFAULT 10,
    auto_reorder BOOLEAN DEFAULT FALSE,
    reorder_point INTEGER,
    max_stock_level INTEGER,
    
    -- Product allocation settings
    allocation_method VARCHAR(50) DEFAULT 'manual', -- manual, automatic, priority_based
    allocation_priority INTEGER DEFAULT 1,
    allocation_percentage DECIMAL(5,2), -- Percentage of total inventory
    
    -- Services and capabilities
    services JSONB, -- Available services (pickup, delivery, returns, etc.)
    payment_methods JSONB, -- Accepted payment methods
    shipping_methods JSONB, -- Available shipping options
    
    -- Staff and management
    manager_name VARCHAR(255),
    manager_email VARCHAR(255),
    manager_phone VARCHAR(50),
    staff_count INTEGER DEFAULT 0,
    
    -- Performance metrics
    total_sales DECIMAL(15,2) DEFAULT 0,
    total_orders INTEGER DEFAULT 0,
    total_customers INTEGER DEFAULT 0,
    average_order_value DECIMAL(10,2) DEFAULT 0,
    customer_satisfaction_score DECIMAL(3,2), -- 1.00 to 5.00
    
    -- Inventory metrics
    total_products INTEGER DEFAULT 0,
    total_stock_value DECIMAL(15,2) DEFAULT 0,
    stock_turnover_rate DECIMAL(5,2),
    inventory_accuracy_percentage DECIMAL(5,2),
    
    -- Financial information
    monthly_rent DECIMAL(10,2),
    monthly_utilities DECIMAL(10,2),
    monthly_staff_cost DECIMAL(10,2),
    monthly_operating_cost DECIMAL(10,2),
    
    -- Settings and preferences
    settings JSONB, -- Branch-specific settings
    preferences JSONB, -- User preferences
    notifications JSONB, -- Notification settings
    
    -- SEO and marketing
    meta_title VARCHAR(255),
    meta_description TEXT,
    meta_keywords TEXT,
    social_media JSONB, -- Social media links
    
    -- Integration and sync
    sync_status VARCHAR(50) DEFAULT 'pending',
    last_sync_at TIMESTAMPTZ,
    sync_errors JSONB,
    external_ids JSONB, -- External system identifiers
    
    -- API and webhook information
    api_settings JSONB,
    webhook_url VARCHAR(500),
    webhook_events JSONB,
    
    -- Compliance and certifications
    licenses JSONB, -- Business licenses
    certifications JSONB, -- Quality certifications
    compliance_status VARCHAR(100),
    
    -- Analytics and reporting
    analytics_enabled BOOLEAN DEFAULT TRUE,
    reporting_frequency VARCHAR(50) DEFAULT 'daily',
    kpi_targets JSONB, -- Key performance indicators
    
    -- Custom fields and metadata
    custom_fields JSONB,
    tags JSONB, -- Branch tags for categorization
    metadata JSONB, -- Additional metadata
    
    -- Internal management
    notes TEXT, -- Internal notes
    priority INTEGER DEFAULT 1,
    sort_order INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    opened_at TIMESTAMPTZ, -- Branch opening date
    closed_at TIMESTAMPTZ -- Branch closing date (if applicable)
);

-- =====================================================
-- Indexes for Performance Optimization
-- =====================================================

-- Primary indexes
CREATE INDEX IF NOT EXISTS idx_branches_store_id ON branches(store_id);
CREATE INDEX IF NOT EXISTS idx_branches_salla_branch_id ON branches(salla_branch_id);
CREATE INDEX IF NOT EXISTS idx_branches_branch_code ON branches(branch_code);
CREATE INDEX IF NOT EXISTS idx_branches_branch_slug ON branches(branch_slug);

-- Status and visibility indexes
CREATE INDEX IF NOT EXISTS idx_branches_status ON branches(status);
CREATE INDEX IF NOT EXISTS idx_branches_is_active ON branches(is_active);
CREATE INDEX IF NOT EXISTS idx_branches_is_visible ON branches(is_visible);
CREATE INDEX IF NOT EXISTS idx_branches_is_main_branch ON branches(is_main_branch);

-- Location indexes
CREATE INDEX IF NOT EXISTS idx_branches_city ON branches(city);
CREATE INDEX IF NOT EXISTS idx_branches_country ON branches(country);
CREATE INDEX IF NOT EXISTS idx_branches_location ON branches(latitude, longitude);

-- Type and category indexes
CREATE INDEX IF NOT EXISTS idx_branches_type ON branches(branch_type);
CREATE INDEX IF NOT EXISTS idx_branches_category ON branches(branch_category);

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_branches_total_sales ON branches(total_sales);
CREATE INDEX IF NOT EXISTS idx_branches_total_orders ON branches(total_orders);

-- Timestamp indexes
CREATE INDEX IF NOT EXISTS idx_branches_created_at ON branches(created_at);
CREATE INDEX IF NOT EXISTS idx_branches_updated_at ON branches(updated_at);

-- Composite indexes
CREATE INDEX IF NOT EXISTS idx_branches_store_status ON branches(store_id, status);
CREATE INDEX IF NOT EXISTS idx_branches_store_active ON branches(store_id, is_active);
CREATE INDEX IF NOT EXISTS idx_branches_store_type ON branches(store_id, branch_type);

-- JSONB indexes for better performance
CREATE INDEX IF NOT EXISTS idx_branches_address_gin ON branches USING GIN(address);
CREATE INDEX IF NOT EXISTS idx_branches_services_gin ON branches USING GIN(services);
CREATE INDEX IF NOT EXISTS idx_branches_settings_gin ON branches USING GIN(settings);

-- =====================================================
-- Triggers for Automatic Updates
-- =====================================================

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_branches_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_branches_updated_at
    BEFORE UPDATE ON branches
    FOR EACH ROW
    EXECUTE FUNCTION update_branches_updated_at();

-- Trigger to generate branch slug
CREATE OR REPLACE FUNCTION generate_branch_slug()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.branch_slug IS NULL OR NEW.branch_slug = '' THEN
        NEW.branch_slug = LOWER(REGEXP_REPLACE(NEW.name, '[^a-zA-Z0-9]+', '-', 'g'));
        NEW.branch_slug = TRIM(BOTH '-' FROM NEW.branch_slug);
        
        -- Ensure uniqueness
        WHILE EXISTS (SELECT 1 FROM branches WHERE branch_slug = NEW.branch_slug AND id != COALESCE(NEW.id, 0)) LOOP
            NEW.branch_slug = NEW.branch_slug || '-' || EXTRACT(EPOCH FROM CURRENT_TIMESTAMP)::INTEGER;
        END LOOP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_generate_branch_slug
    BEFORE INSERT OR UPDATE ON branches
    FOR EACH ROW
    EXECUTE FUNCTION generate_branch_slug();

-- Trigger to update performance metrics
CREATE OR REPLACE FUNCTION update_branch_performance_metrics()
RETURNS TRIGGER AS $$
BEGIN
    -- Update average order value when sales or orders change
    IF NEW.total_orders > 0 THEN
        NEW.average_order_value = NEW.total_sales / NEW.total_orders;
    ELSE
        NEW.average_order_value = 0;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_branch_performance_metrics
    BEFORE UPDATE ON branches
    FOR EACH ROW
    WHEN (OLD.total_sales IS DISTINCT FROM NEW.total_sales OR OLD.total_orders IS DISTINCT FROM NEW.total_orders)
    EXECUTE FUNCTION update_branch_performance_metrics();

-- =====================================================
-- Helper Functions
-- =====================================================

-- Function to get branch statistics
CREATE OR REPLACE FUNCTION get_branch_stats(branch_id BIGINT)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'branch_id', b.id,
        'branch_name', b.name,
        'total_sales', COALESCE(b.total_sales, 0),
        'total_orders', COALESCE(b.total_orders, 0),
        'total_customers', COALESCE(b.total_customers, 0),
        'average_order_value', COALESCE(b.average_order_value, 0),
        'total_products', COALESCE(b.total_products, 0),
        'stock_value', COALESCE(b.total_stock_value, 0),
        'customer_satisfaction', COALESCE(b.customer_satisfaction_score, 0),
        'staff_count', COALESCE(b.staff_count, 0),
        'status', b.status,
        'is_active', b.is_active
    ) INTO result
    FROM branches b
    WHERE b.id = branch_id;
    
    RETURN COALESCE(result, '{}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- Function to get store branches statistics
CREATE OR REPLACE FUNCTION get_store_branches_stats(store_id_param BIGINT)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'store_id', store_id_param,
        'total_branches', COUNT(*),
        'active_branches', COUNT(*) FILTER (WHERE is_active = TRUE),
        'main_branches', COUNT(*) FILTER (WHERE is_main_branch = TRUE),
        'total_sales', COALESCE(SUM(total_sales), 0),
        'total_orders', COALESCE(SUM(total_orders), 0),
        'total_customers', COALESCE(SUM(total_customers), 0),
        'average_order_value', CASE 
            WHEN SUM(total_orders) > 0 THEN SUM(total_sales) / SUM(total_orders)
            ELSE 0
        END,
        'total_stock_value', COALESCE(SUM(total_stock_value), 0),
        'total_staff', COALESCE(SUM(staff_count), 0),
        'branch_types', jsonb_agg(DISTINCT branch_type) FILTER (WHERE branch_type IS NOT NULL)
    ) INTO result
    FROM branches
    WHERE store_id = store_id_param;
    
    RETURN COALESCE(result, '{}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- Function to search branches
CREATE OR REPLACE FUNCTION search_branches(
    search_term TEXT DEFAULT NULL,
    store_id_param BIGINT DEFAULT NULL,
    branch_type_param VARCHAR DEFAULT NULL,
    city_param VARCHAR DEFAULT NULL,
    country_param VARCHAR DEFAULT NULL,
    is_active_param BOOLEAN DEFAULT NULL,
    limit_param INTEGER DEFAULT 50,
    offset_param INTEGER DEFAULT 0
)
RETURNS TABLE (
    id BIGINT,
    name VARCHAR,
    branch_code VARCHAR,
    branch_type VARCHAR,
    city VARCHAR,
    country VARCHAR,
    status VARCHAR,
    is_active BOOLEAN,
    total_sales DECIMAL,
    total_orders INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        b.id,
        b.name,
        b.branch_code,
        b.branch_type,
        b.city,
        b.country,
        b.status,
        b.is_active,
        b.total_sales,
        b.total_orders
    FROM branches b
    WHERE 
        (store_id_param IS NULL OR b.store_id = store_id_param)
        AND (search_term IS NULL OR (
            b.name ILIKE '%' || search_term || '%' OR
            b.branch_code ILIKE '%' || search_term || '%' OR
            b.description ILIKE '%' || search_term || '%'
        ))
        AND (branch_type_param IS NULL OR b.branch_type = branch_type_param)
        AND (city_param IS NULL OR b.city ILIKE '%' || city_param || '%')
        AND (country_param IS NULL OR b.country ILIKE '%' || country_param || '%')
        AND (is_active_param IS NULL OR b.is_active = is_active_param)
    ORDER BY b.is_main_branch DESC, b.total_sales DESC, b.name
    LIMIT limit_param OFFSET offset_param;
END;
$$ LANGUAGE plpgsql;

-- Function to update branch metrics from orders
CREATE OR REPLACE FUNCTION update_branch_metrics_from_orders(branch_id_param BIGINT)
RETURNS VOID AS $$
DECLARE
    sales_total DECIMAL;
    orders_count INTEGER;
    customers_count INTEGER;
BEGIN
    -- Calculate metrics from orders (assuming orders table has branch_id)
    SELECT 
        COALESCE(SUM(total), 0),
        COUNT(*),
        COUNT(DISTINCT customer_id)
    INTO sales_total, orders_count, customers_count
    FROM orders 
    WHERE branch_id = branch_id_param;
    
    -- Update branch metrics
    UPDATE branches 
    SET 
        total_sales = sales_total,
        total_orders = orders_count,
        total_customers = customers_count,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = branch_id_param;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Comments for Documentation
-- =====================================================

COMMENT ON TABLE branches IS 'Store branches with inventory management and product allocation';
COMMENT ON COLUMN branches.id IS 'Primary key for branch';
COMMENT ON COLUMN branches.salla_branch_id IS 'Unique identifier from Salla API';
COMMENT ON COLUMN branches.store_id IS 'Reference to parent store';
COMMENT ON COLUMN branches.name IS 'Branch display name';
COMMENT ON COLUMN branches.branch_code IS 'Internal branch code for identification';
COMMENT ON COLUMN branches.branch_slug IS 'URL-friendly branch identifier';
COMMENT ON COLUMN branches.address IS 'Complete address information in JSON format';
COMMENT ON COLUMN branches.branch_type IS 'Type of branch (physical, virtual, warehouse, showroom)';
COMMENT ON COLUMN branches.operating_hours IS 'Weekly operating schedule in JSON format';
COMMENT ON COLUMN branches.manages_inventory IS 'Whether this branch manages its own inventory';
COMMENT ON COLUMN branches.allocation_method IS 'Method for product allocation (manual, automatic, priority_based)';
COMMENT ON COLUMN branches.services IS 'Available services in JSON format';
COMMENT ON COLUMN branches.total_sales IS 'Total sales amount for this branch';
COMMENT ON COLUMN branches.total_orders IS 'Total number of orders for this branch';
COMMENT ON COLUMN branches.settings IS 'Branch-specific settings in JSON format';
COMMENT ON COLUMN branches.created_at IS 'Timestamp when branch was created';
COMMENT ON COLUMN branches.updated_at IS 'Timestamp when branch was last updated';

-- Function comments
COMMENT ON FUNCTION get_branch_stats(BIGINT) IS 'Get comprehensive statistics for a specific branch';
COMMENT ON FUNCTION get_store_branches_stats(BIGINT) IS 'Get aggregated statistics for all branches of a store';
COMMENT ON FUNCTION search_branches(TEXT, BIGINT, VARCHAR, VARCHAR, VARCHAR, BOOLEAN, INTEGER, INTEGER) IS 'Search branches with various filters and pagination';
COMMENT ON FUNCTION update_branch_metrics_from_orders(BIGINT) IS 'Update branch performance metrics based on order data';