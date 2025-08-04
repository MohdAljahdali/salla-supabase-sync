-- =============================================
-- Shipping Zones Table
-- =============================================
-- This table defines shipping zones and their rules
-- for different geographical areas

CREATE TABLE shipping_zones (
    -- Primary key
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Foreign key to stores table
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Salla API identifiers
    salla_zone_id VARCHAR(255),
    
    -- Basic zone information
    name VARCHAR(255) NOT NULL,
    name_ar VARCHAR(255),
    name_en VARCHAR(255),
    description TEXT,
    description_ar TEXT,
    description_en TEXT,
    
    -- Zone configuration
    zone_type VARCHAR(50) DEFAULT 'geographic', -- geographic, postal_code, weight_based
    
    -- Geographic coverage
    countries JSONB DEFAULT '[]'::jsonb, -- Array of country codes
    cities JSONB DEFAULT '[]'::jsonb, -- Array of city names
    regions JSONB DEFAULT '[]'::jsonb, -- Array of region/state names
    postal_codes JSONB DEFAULT '[]'::jsonb, -- Array of postal code patterns
    
    -- Zone boundaries (for advanced geographic zones)
    coordinates JSONB DEFAULT '{}'::jsonb, -- Geographic coordinates for polygon zones
    
    -- Shipping costs and rules
    base_cost DECIMAL(10,2) DEFAULT 0.00,
    cost_per_kg DECIMAL(10,2) DEFAULT 0.00,
    cost_per_item DECIMAL(10,2) DEFAULT 0.00,
    
    -- Free shipping rules
    free_shipping_enabled BOOLEAN DEFAULT false,
    free_shipping_threshold DECIMAL(10,2),
    
    -- Weight and size limits
    max_weight DECIMAL(10,2), -- Maximum weight in kg
    max_dimensions JSONB DEFAULT '{}'::jsonb, -- {"length": 100, "width": 50, "height": 30}
    
    -- Delivery time
    delivery_time_min INTEGER, -- Minimum delivery time in days
    delivery_time_max INTEGER, -- Maximum delivery time in days
    
    -- Available shipping companies for this zone
    shipping_companies JSONB DEFAULT '[]'::jsonb, -- Array of shipping company IDs
    
    -- Zone settings
    is_active BOOLEAN DEFAULT true,
    is_default BOOLEAN DEFAULT false,
    sort_order INTEGER DEFAULT 0,
    
    -- Restrictions
    restricted_products JSONB DEFAULT '[]'::jsonb, -- Array of restricted product categories/types
    cod_available BOOLEAN DEFAULT true, -- Cash on delivery availability
    
    -- Pricing tiers based on order value
    pricing_tiers JSONB DEFAULT '[]'::jsonb, -- Array of {"min_amount": 100, "cost": 10}
    
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
CREATE INDEX idx_shipping_zones_store_id ON shipping_zones(store_id);

-- Index on salla_zone_id for API sync
CREATE INDEX idx_shipping_zones_salla_id ON shipping_zones(salla_zone_id);

-- Index on active zones
CREATE INDEX idx_shipping_zones_active ON shipping_zones(is_active);

-- Index on default zone
CREATE INDEX idx_shipping_zones_default ON shipping_zones(is_default);

-- Index on zone type
CREATE INDEX idx_shipping_zones_type ON shipping_zones(zone_type);

-- Index on sort order
CREATE INDEX idx_shipping_zones_sort ON shipping_zones(sort_order);

-- GIN indexes for JSONB columns
CREATE INDEX idx_shipping_zones_countries_gin ON shipping_zones USING GIN(countries);
CREATE INDEX idx_shipping_zones_cities_gin ON shipping_zones USING GIN(cities);
CREATE INDEX idx_shipping_zones_regions_gin ON shipping_zones USING GIN(regions);
CREATE INDEX idx_shipping_zones_postal_codes_gin ON shipping_zones USING GIN(postal_codes);
CREATE INDEX idx_shipping_zones_companies_gin ON shipping_zones USING GIN(shipping_companies);
CREATE INDEX idx_shipping_zones_pricing_tiers_gin ON shipping_zones USING GIN(pricing_tiers);
CREATE INDEX idx_shipping_zones_metadata_gin ON shipping_zones USING GIN(metadata);

-- =============================================
-- Triggers
-- =============================================

-- Trigger to update updated_at column
CREATE TRIGGER trigger_shipping_zones_updated_at
    BEFORE UPDATE ON shipping_zones
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- Helper Functions
-- =============================================

-- Function to find shipping zone for a given address
CREATE OR REPLACE FUNCTION find_shipping_zone(
    p_store_id UUID,
    p_country VARCHAR(255),
    p_city VARCHAR(255) DEFAULT NULL,
    p_region VARCHAR(255) DEFAULT NULL,
    p_postal_code VARCHAR(20) DEFAULT NULL
)
RETURNS TABLE (
    zone_id UUID,
    zone_name VARCHAR(255),
    base_cost DECIMAL(10,2),
    cost_per_kg DECIMAL(10,2),
    delivery_time_min INTEGER,
    delivery_time_max INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        sz.id,
        sz.name,
        sz.base_cost,
        sz.cost_per_kg,
        sz.delivery_time_min,
        sz.delivery_time_max
    FROM shipping_zones sz
    WHERE sz.store_id = p_store_id
      AND sz.is_active = true
      AND (
          -- Check country match
          sz.countries @> to_jsonb(ARRAY[p_country])
          OR
          -- Check city match (if provided)
          (p_city IS NOT NULL AND sz.cities @> to_jsonb(ARRAY[p_city]))
          OR
          -- Check region match (if provided)
          (p_region IS NOT NULL AND sz.regions @> to_jsonb(ARRAY[p_region]))
          OR
          -- Check postal code match (if provided)
          (p_postal_code IS NOT NULL AND sz.postal_codes @> to_jsonb(ARRAY[p_postal_code]))
      )
    ORDER BY 
        -- Prioritize more specific matches
        CASE 
            WHEN sz.cities @> to_jsonb(ARRAY[p_city]) THEN 1
            WHEN sz.regions @> to_jsonb(ARRAY[p_region]) THEN 2
            WHEN sz.postal_codes @> to_jsonb(ARRAY[p_postal_code]) THEN 3
            WHEN sz.countries @> to_jsonb(ARRAY[p_country]) THEN 4
            ELSE 5
        END,
        sz.sort_order ASC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate shipping cost for a zone
CREATE OR REPLACE FUNCTION calculate_zone_shipping_cost(
    p_zone_id UUID,
    p_order_total DECIMAL(10,2),
    p_total_weight DECIMAL(10,2),
    p_item_count INTEGER
)
RETURNS DECIMAL(10,2) AS $$
DECLARE
    zone_record shipping_zones%ROWTYPE;
    calculated_cost DECIMAL(10,2) := 0;
    tier_cost DECIMAL(10,2);
BEGIN
    -- Get zone details
    SELECT * INTO zone_record FROM shipping_zones WHERE id = p_zone_id;
    
    IF NOT FOUND THEN
        RETURN 0;
    END IF;
    
    -- Check for free shipping
    IF zone_record.free_shipping_enabled AND 
       zone_record.free_shipping_threshold IS NOT NULL AND 
       p_order_total >= zone_record.free_shipping_threshold THEN
        RETURN 0;
    END IF;
    
    -- Check pricing tiers first
    IF zone_record.pricing_tiers IS NOT NULL AND jsonb_array_length(zone_record.pricing_tiers) > 0 THEN
        SELECT 
            COALESCE((tier->>'cost')::DECIMAL(10,2), zone_record.base_cost)
        INTO tier_cost
        FROM jsonb_array_elements(zone_record.pricing_tiers) AS tier
        WHERE (tier->>'min_amount')::DECIMAL(10,2) <= p_order_total
        ORDER BY (tier->>'min_amount')::DECIMAL(10,2) DESC
        LIMIT 1;
        
        IF tier_cost IS NOT NULL THEN
            calculated_cost := tier_cost;
        ELSE
            calculated_cost := zone_record.base_cost;
        END IF;
    ELSE
        -- Use base cost calculation
        calculated_cost := zone_record.base_cost;
    END IF;
    
    -- Add weight-based cost
    IF zone_record.cost_per_kg > 0 AND p_total_weight > 0 THEN
        calculated_cost := calculated_cost + (zone_record.cost_per_kg * p_total_weight);
    END IF;
    
    -- Add item-based cost
    IF zone_record.cost_per_item > 0 AND p_item_count > 0 THEN
        calculated_cost := calculated_cost + (zone_record.cost_per_item * p_item_count);
    END IF;
    
    RETURN GREATEST(calculated_cost, 0);
END;
$$ LANGUAGE plpgsql;

-- Function to get available shipping companies for a zone
CREATE OR REPLACE FUNCTION get_zone_shipping_companies(p_zone_id UUID)
RETURNS TABLE (
    company_id UUID,
    company_name VARCHAR(255),
    company_logo TEXT,
    supports_tracking BOOLEAN,
    supports_cod BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        sc.id,
        sc.name,
        sc.logo_url,
        sc.supports_tracking,
        sc.supports_cod
    FROM shipping_zones sz
    JOIN shipping_companies sc ON sc.id::text = ANY(
        SELECT jsonb_array_elements_text(sz.shipping_companies)
    )
    WHERE sz.id = p_zone_id
      AND sz.is_active = true
      AND sc.is_active = true
    ORDER BY sc.sort_order ASC, sc.name ASC;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- Comments
-- =============================================

COMMENT ON TABLE shipping_zones IS 'Defines shipping zones and their rules for different geographical areas';
COMMENT ON COLUMN shipping_zones.store_id IS 'Reference to the store this shipping zone belongs to';
COMMENT ON COLUMN shipping_zones.salla_zone_id IS 'Salla API zone identifier';
COMMENT ON COLUMN shipping_zones.zone_type IS 'Type of zone: geographic, postal_code, weight_based';
COMMENT ON COLUMN shipping_zones.countries IS 'JSON array of country codes covered by this zone';
COMMENT ON COLUMN shipping_zones.cities IS 'JSON array of city names covered by this zone';
COMMENT ON COLUMN shipping_zones.regions IS 'JSON array of region/state names covered by this zone';
COMMENT ON COLUMN shipping_zones.postal_codes IS 'JSON array of postal code patterns covered by this zone';
COMMENT ON COLUMN shipping_zones.coordinates IS 'Geographic coordinates for polygon-based zones';
COMMENT ON COLUMN shipping_zones.shipping_companies IS 'JSON array of shipping company IDs available for this zone';
COMMENT ON COLUMN shipping_zones.pricing_tiers IS 'JSON array of pricing tiers based on order value';
COMMENT ON COLUMN shipping_zones.restricted_products IS 'JSON array of restricted product categories/types for this zone';
COMMENT ON COLUMN shipping_zones.metadata IS 'Additional metadata in JSON format';