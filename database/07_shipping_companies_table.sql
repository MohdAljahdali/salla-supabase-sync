-- =============================================
-- Shipping Companies Table
-- =============================================
-- This table stores information about shipping companies
-- that are available for each store

CREATE TABLE shipping_companies (
    -- Primary key
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Foreign key to stores table
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Salla API identifiers
    salla_shipping_company_id VARCHAR(255),
    
    -- Basic company information
    name VARCHAR(255) NOT NULL,
    name_ar VARCHAR(255),
    name_en VARCHAR(255),
    description TEXT,
    description_ar TEXT,
    description_en TEXT,
    
    -- Company details
    code VARCHAR(100) UNIQUE,
    logo_url TEXT,
    website_url TEXT,
    
    -- Contact information
    phone VARCHAR(50),
    email VARCHAR(255),
    
    -- Service areas and coverage
    coverage_areas JSONB DEFAULT '[]'::jsonb, -- Array of covered cities/regions
    international_shipping BOOLEAN DEFAULT false,
    domestic_shipping BOOLEAN DEFAULT true,
    
    -- Shipping options and services
    shipping_options JSONB DEFAULT '[]'::jsonb, -- Array of shipping service types
    delivery_time_min INTEGER, -- Minimum delivery time in days
    delivery_time_max INTEGER, -- Maximum delivery time in days
    
    -- Pricing information
    base_cost DECIMAL(10,2) DEFAULT 0.00,
    cost_per_kg DECIMAL(10,2) DEFAULT 0.00,
    free_shipping_threshold DECIMAL(10,2),
    
    -- Tracking and features
    supports_tracking BOOLEAN DEFAULT false,
    supports_cod BOOLEAN DEFAULT false, -- Cash on delivery
    supports_insurance BOOLEAN DEFAULT false,
    supports_fragile BOOLEAN DEFAULT false,
    
    -- Business settings
    is_active BOOLEAN DEFAULT true,
    is_default BOOLEAN DEFAULT false,
    sort_order INTEGER DEFAULT 0,
    
    -- API configuration
    api_endpoint TEXT,
    api_key TEXT,
    api_settings JSONB DEFAULT '{}'::jsonb,
    
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
CREATE INDEX idx_shipping_companies_store_id ON shipping_companies(store_id);

-- Index on salla_shipping_company_id for API sync
CREATE INDEX idx_shipping_companies_salla_id ON shipping_companies(salla_shipping_company_id);

-- Index on active companies
CREATE INDEX idx_shipping_companies_active ON shipping_companies(is_active);

-- Index on default company
CREATE INDEX idx_shipping_companies_default ON shipping_companies(is_default);

-- Index on sort order
CREATE INDEX idx_shipping_companies_sort ON shipping_companies(sort_order);

-- Index on code for unique lookups
CREATE INDEX idx_shipping_companies_code ON shipping_companies(code);

-- GIN index for coverage areas JSONB
CREATE INDEX idx_shipping_companies_coverage_gin ON shipping_companies USING GIN(coverage_areas);

-- GIN index for shipping options JSONB
CREATE INDEX idx_shipping_companies_options_gin ON shipping_companies USING GIN(shipping_options);

-- GIN index for metadata JSONB
CREATE INDEX idx_shipping_companies_metadata_gin ON shipping_companies USING GIN(metadata);

-- =============================================
-- Triggers
-- =============================================

-- Trigger to update updated_at column
CREATE TRIGGER trigger_shipping_companies_updated_at
    BEFORE UPDATE ON shipping_companies
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- Helper Functions
-- =============================================

-- Function to get active shipping companies for a store
CREATE OR REPLACE FUNCTION get_active_shipping_companies(p_store_id UUID)
RETURNS TABLE (
    id UUID,
    name VARCHAR(255),
    description TEXT,
    logo_url TEXT,
    delivery_time_min INTEGER,
    delivery_time_max INTEGER,
    base_cost DECIMAL(10,2),
    supports_tracking BOOLEAN,
    supports_cod BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        sc.id,
        sc.name,
        sc.description,
        sc.logo_url,
        sc.delivery_time_min,
        sc.delivery_time_max,
        sc.base_cost,
        sc.supports_tracking,
        sc.supports_cod
    FROM shipping_companies sc
    WHERE sc.store_id = p_store_id
      AND sc.is_active = true
    ORDER BY sc.sort_order ASC, sc.name ASC;
END;
$$ LANGUAGE plpgsql;

-- Function to check if shipping company covers a specific area
CREATE OR REPLACE FUNCTION check_shipping_coverage(
    p_company_id UUID,
    p_area VARCHAR(255)
)
RETURNS BOOLEAN AS $$
DECLARE
    coverage_found BOOLEAN := false;
BEGIN
    SELECT EXISTS(
        SELECT 1 
        FROM shipping_companies 
        WHERE id = p_company_id 
          AND (
              coverage_areas @> to_jsonb(ARRAY[p_area])
              OR international_shipping = true
          )
    ) INTO coverage_found;
    
    RETURN coverage_found;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- Comments
-- =============================================

COMMENT ON TABLE shipping_companies IS 'Stores information about shipping companies available for each store';
COMMENT ON COLUMN shipping_companies.store_id IS 'Reference to the store this shipping company belongs to';
COMMENT ON COLUMN shipping_companies.salla_shipping_company_id IS 'Salla API shipping company identifier';
COMMENT ON COLUMN shipping_companies.coverage_areas IS 'JSON array of cities/regions covered by this shipping company';
COMMENT ON COLUMN shipping_companies.shipping_options IS 'JSON array of available shipping service types (express, standard, etc.)';
COMMENT ON COLUMN shipping_companies.supports_cod IS 'Whether the company supports cash on delivery';
COMMENT ON COLUMN shipping_companies.api_settings IS 'JSON object containing API configuration for this shipping company';
COMMENT ON COLUMN shipping_companies.metadata IS 'Additional metadata in JSON format';