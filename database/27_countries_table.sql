-- =====================================================
-- Countries Table for Salla-Supabase Integration
-- =====================================================
-- This table stores supported countries with shipping
-- and regional information for international commerce

CREATE TABLE IF NOT EXISTS countries (
    -- Primary identification
    id BIGSERIAL PRIMARY KEY,
    salla_country_id VARCHAR(255) UNIQUE, -- Salla API country identifier
    
    -- Store relationship (required)
    store_id BIGINT NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Basic country information
    code VARCHAR(2) NOT NULL, -- ISO 3166-1 alpha-2 country code
    code_alpha3 VARCHAR(3), -- ISO 3166-1 alpha-3 country code
    numeric_code VARCHAR(3), -- ISO 3166-1 numeric country code
    name VARCHAR(255) NOT NULL,
    name_ar VARCHAR(255), -- Arabic name
    name_en VARCHAR(255), -- English name
    official_name VARCHAR(255), -- Official country name
    
    -- Geographic information
    continent VARCHAR(100),
    region VARCHAR(100), -- Geographic region
    subregion VARCHAR(100), -- Geographic subregion
    capital VARCHAR(255), -- Capital city
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    area_km2 DECIMAL(12, 2), -- Area in square kilometers
    
    -- Political and administrative
    government_type VARCHAR(100),
    independence_date DATE,
    national_day DATE,
    head_of_state VARCHAR(255),
    
    -- Economic information
    currency_code VARCHAR(3), -- Primary currency code
    currencies JSONB, -- All supported currencies
    gdp_usd DECIMAL(15, 2), -- GDP in USD
    gdp_per_capita_usd DECIMAL(10, 2),
    economic_status VARCHAR(100), -- developed, developing, least_developed
    
    -- Demographics
    population BIGINT,
    population_density DECIMAL(10, 2), -- People per km²
    life_expectancy DECIMAL(4, 1),
    literacy_rate DECIMAL(5, 2), -- Percentage
    
    -- Languages and localization
    languages JSONB, -- Supported languages with codes
    primary_language VARCHAR(10), -- Primary language code
    rtl_languages JSONB, -- Right-to-left languages
    locale_code VARCHAR(10), -- Default locale (en_US, ar_SA, etc.)
    
    -- Time and calendar
    timezones JSONB, -- All timezones in the country
    primary_timezone VARCHAR(100), -- Primary timezone
    dst_observed BOOLEAN DEFAULT FALSE, -- Daylight saving time
    calendar_type VARCHAR(50) DEFAULT 'gregorian', -- gregorian, hijri, etc.
    weekend_days JSONB, -- Weekend days (0=Sunday, 6=Saturday)
    
    -- Contact and communication
    phone_code VARCHAR(10), -- International dialing code
    phone_format VARCHAR(100), -- Phone number format
    postal_code_format VARCHAR(100), -- Postal code format
    postal_code_regex VARCHAR(255), -- Regex for postal code validation
    
    -- Internet and technology
    internet_tld VARCHAR(10), -- Top-level domain (.sa, .ae, etc.)
    internet_users_percentage DECIMAL(5, 2),
    mobile_penetration_percentage DECIMAL(5, 2),
    
    -- Shipping and logistics
    shipping_enabled BOOLEAN DEFAULT TRUE,
    shipping_zones JSONB, -- Shipping zone configurations
    shipping_restrictions JSONB, -- Shipping restrictions and prohibited items
    customs_info JSONB, -- Customs and duties information
    
    -- Shipping costs and delivery
    base_shipping_cost DECIMAL(10, 2),
    express_shipping_cost DECIMAL(10, 2),
    free_shipping_threshold DECIMAL(10, 2),
    average_delivery_days INTEGER,
    express_delivery_days INTEGER,
    
    -- Payment and financial
    payment_methods JSONB, -- Supported payment methods
    banking_system VARCHAR(100),
    credit_card_usage_percentage DECIMAL(5, 2),
    digital_wallet_usage_percentage DECIMAL(5, 2),
    
    -- Tax and legal
    tax_system VARCHAR(100),
    vat_rate DECIMAL(5, 4), -- VAT/GST rate as decimal (0.15 for 15%)
    tax_number_format VARCHAR(100),
    legal_business_types JSONB, -- Supported business entity types
    
    -- Compliance and regulations
    data_protection_laws JSONB, -- GDPR, PDPL, etc.
    ecommerce_regulations JSONB,
    import_restrictions JSONB,
    export_restrictions JSONB,
    
    -- Status and availability
    status VARCHAR(50) DEFAULT 'active', -- active, inactive, restricted
    is_active BOOLEAN DEFAULT TRUE,
    is_shipping_available BOOLEAN DEFAULT TRUE,
    is_payment_available BOOLEAN DEFAULT TRUE,
    availability_notes TEXT,
    
    -- Risk and security
    risk_level VARCHAR(50) DEFAULT 'low', -- low, medium, high
    fraud_risk_score DECIMAL(3, 2), -- 1.00 to 5.00
    security_requirements JSONB,
    
    -- Performance metrics
    total_orders INTEGER DEFAULT 0,
    total_sales DECIMAL(15, 2) DEFAULT 0,
    total_customers INTEGER DEFAULT 0,
    average_order_value DECIMAL(10, 2) DEFAULT 0,
    conversion_rate DECIMAL(5, 4), -- Conversion rate percentage
    
    -- Shipping performance
    successful_deliveries INTEGER DEFAULT 0,
    failed_deliveries INTEGER DEFAULT 0,
    average_delivery_time_days DECIMAL(4, 1),
    delivery_success_rate DECIMAL(5, 4),
    
    -- Customer satisfaction
    customer_satisfaction_score DECIMAL(3, 2), -- 1.00 to 5.00
    return_rate DECIMAL(5, 4), -- Return rate percentage
    complaint_rate DECIMAL(5, 4), -- Complaint rate percentage
    
    -- Seasonal and cultural
    holidays JSONB, -- National and religious holidays
    shopping_seasons JSONB, -- Peak shopping periods
    cultural_preferences JSONB, -- Cultural shopping preferences
    
    -- Integration and API
    api_settings JSONB,
    webhook_events JSONB,
    sync_status VARCHAR(50) DEFAULT 'pending',
    last_sync_at TIMESTAMPTZ,
    sync_errors JSONB,
    
    -- Localization settings
    date_format VARCHAR(50), -- Date display format
    time_format VARCHAR(50), -- Time display format
    number_format JSONB, -- Number formatting preferences
    address_format JSONB, -- Address formatting rules
    
    -- Custom fields and metadata
    custom_fields JSONB,
    tags JSONB, -- Country tags for categorization
    metadata JSONB, -- Additional metadata
    
    -- Internal management
    notes TEXT, -- Internal notes
    priority INTEGER DEFAULT 1,
    sort_order INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    activated_at TIMESTAMPTZ,
    deactivated_at TIMESTAMPTZ
);

-- =====================================================
-- Indexes for Performance Optimization
-- =====================================================

-- Primary indexes
CREATE INDEX IF NOT EXISTS idx_countries_store_id ON countries(store_id);
CREATE INDEX IF NOT EXISTS idx_countries_salla_country_id ON countries(salla_country_id);
CREATE INDEX IF NOT EXISTS idx_countries_code ON countries(code);
CREATE INDEX IF NOT EXISTS idx_countries_code_alpha3 ON countries(code_alpha3);

-- Status and availability indexes
CREATE INDEX IF NOT EXISTS idx_countries_status ON countries(status);
CREATE INDEX IF NOT EXISTS idx_countries_is_active ON countries(is_active);
CREATE INDEX IF NOT EXISTS idx_countries_shipping_available ON countries(is_shipping_available);
CREATE INDEX IF NOT EXISTS idx_countries_payment_available ON countries(is_payment_available);

-- Geographic indexes
CREATE INDEX IF NOT EXISTS idx_countries_continent ON countries(continent);
CREATE INDEX IF NOT EXISTS idx_countries_region ON countries(region);
CREATE INDEX IF NOT EXISTS idx_countries_location ON countries(latitude, longitude);

-- Economic and currency indexes
CREATE INDEX IF NOT EXISTS idx_countries_currency_code ON countries(currency_code);
CREATE INDEX IF NOT EXISTS idx_countries_economic_status ON countries(economic_status);

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_countries_total_sales ON countries(total_sales);
CREATE INDEX IF NOT EXISTS idx_countries_total_orders ON countries(total_orders);
CREATE INDEX IF NOT EXISTS idx_countries_conversion_rate ON countries(conversion_rate);

-- Risk and security indexes
CREATE INDEX IF NOT EXISTS idx_countries_risk_level ON countries(risk_level);
CREATE INDEX IF NOT EXISTS idx_countries_fraud_risk_score ON countries(fraud_risk_score);

-- Timestamp indexes
CREATE INDEX IF NOT EXISTS idx_countries_created_at ON countries(created_at);
CREATE INDEX IF NOT EXISTS idx_countries_updated_at ON countries(updated_at);

-- Composite indexes
CREATE INDEX IF NOT EXISTS idx_countries_store_code ON countries(store_id, code);
CREATE INDEX IF NOT EXISTS idx_countries_store_active ON countries(store_id, is_active);
CREATE INDEX IF NOT EXISTS idx_countries_store_shipping ON countries(store_id, is_shipping_available);
CREATE INDEX IF NOT EXISTS idx_countries_region_active ON countries(region, is_active);

-- JSONB indexes for better performance
CREATE INDEX IF NOT EXISTS idx_countries_languages_gin ON countries USING GIN(languages);
CREATE INDEX IF NOT EXISTS idx_countries_currencies_gin ON countries USING GIN(currencies);
CREATE INDEX IF NOT EXISTS idx_countries_payment_methods_gin ON countries USING GIN(payment_methods);
CREATE INDEX IF NOT EXISTS idx_countries_shipping_zones_gin ON countries USING GIN(shipping_zones);

-- Unique constraints
CREATE UNIQUE INDEX IF NOT EXISTS idx_countries_store_code_unique ON countries(store_id, code);

-- =====================================================
-- Triggers for Automatic Updates
-- =====================================================

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_countries_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_countries_updated_at
    BEFORE UPDATE ON countries
    FOR EACH ROW
    EXECUTE FUNCTION update_countries_updated_at();

-- Trigger to validate country settings
CREATE OR REPLACE FUNCTION validate_country_settings()
RETURNS TRIGGER AS $$
BEGIN
    -- Validate country code format (2 characters, uppercase)
    IF NEW.code !~ '^[A-Z]{2}$' THEN
        RAISE EXCEPTION 'Country code must be 2 uppercase letters (ISO 3166-1 alpha-2 format)';
    END IF;
    
    -- Validate alpha-3 code if provided
    IF NEW.code_alpha3 IS NOT NULL AND NEW.code_alpha3 !~ '^[A-Z]{3}$' THEN
        RAISE EXCEPTION 'Alpha-3 country code must be 3 uppercase letters';
    END IF;
    
    -- Validate currency code if provided
    IF NEW.currency_code IS NOT NULL AND NEW.currency_code !~ '^[A-Z]{3}$' THEN
        RAISE EXCEPTION 'Currency code must be 3 uppercase letters (ISO 4217 format)';
    END IF;
    
    -- Validate VAT rate
    IF NEW.vat_rate IS NOT NULL AND (NEW.vat_rate < 0 OR NEW.vat_rate > 1) THEN
        RAISE EXCEPTION 'VAT rate must be between 0 and 1 (0% to 100%)';
    END IF;
    
    -- Set activated_at when country becomes active
    IF NEW.is_active = TRUE AND (OLD IS NULL OR OLD.is_active = FALSE) THEN
        NEW.activated_at = CURRENT_TIMESTAMP;
    END IF;
    
    -- Set deactivated_at when country becomes inactive
    IF NEW.is_active = FALSE AND OLD IS NOT NULL AND OLD.is_active = TRUE THEN
        NEW.deactivated_at = CURRENT_TIMESTAMP;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validate_country_settings
    BEFORE INSERT OR UPDATE ON countries
    FOR EACH ROW
    EXECUTE FUNCTION validate_country_settings();

-- Trigger to update performance metrics
CREATE OR REPLACE FUNCTION update_country_performance_metrics()
RETURNS TRIGGER AS $$
BEGIN
    -- Update average order value
    IF NEW.total_orders > 0 THEN
        NEW.average_order_value = NEW.total_sales / NEW.total_orders;
    ELSE
        NEW.average_order_value = 0;
    END IF;
    
    -- Update delivery success rate
    IF (NEW.successful_deliveries + NEW.failed_deliveries) > 0 THEN
        NEW.delivery_success_rate = NEW.successful_deliveries::DECIMAL / 
                                   (NEW.successful_deliveries + NEW.failed_deliveries);
    ELSE
        NEW.delivery_success_rate = 0;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_country_performance_metrics
    BEFORE UPDATE ON countries
    FOR EACH ROW
    WHEN (OLD.total_sales IS DISTINCT FROM NEW.total_sales OR 
          OLD.total_orders IS DISTINCT FROM NEW.total_orders OR
          OLD.successful_deliveries IS DISTINCT FROM NEW.successful_deliveries OR
          OLD.failed_deliveries IS DISTINCT FROM NEW.failed_deliveries)
    EXECUTE FUNCTION update_country_performance_metrics();

-- =====================================================
-- Helper Functions
-- =====================================================

-- Function to get country statistics
CREATE OR REPLACE FUNCTION get_country_stats(country_id BIGINT)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'country_id', c.id,
        'code', c.code,
        'name', c.name,
        'continent', c.continent,
        'region', c.region,
        'currency_code', c.currency_code,
        'total_sales', COALESCE(c.total_sales, 0),
        'total_orders', COALESCE(c.total_orders, 0),
        'total_customers', COALESCE(c.total_customers, 0),
        'average_order_value', COALESCE(c.average_order_value, 0),
        'conversion_rate', COALESCE(c.conversion_rate, 0),
        'delivery_success_rate', COALESCE(c.delivery_success_rate, 0),
        'customer_satisfaction_score', COALESCE(c.customer_satisfaction_score, 0),
        'shipping_enabled', c.shipping_enabled,
        'payment_available', c.is_payment_available,
        'risk_level', c.risk_level,
        'status', c.status,
        'is_active', c.is_active
    ) INTO result
    FROM countries c
    WHERE c.id = country_id;
    
    RETURN COALESCE(result, '{}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- Function to get store countries statistics
CREATE OR REPLACE FUNCTION get_store_countries_stats(store_id_param BIGINT)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'store_id', store_id_param,
        'total_countries', COUNT(*),
        'active_countries', COUNT(*) FILTER (WHERE is_active = TRUE),
        'shipping_enabled_countries', COUNT(*) FILTER (WHERE shipping_enabled = TRUE),
        'payment_enabled_countries', COUNT(*) FILTER (WHERE is_payment_available = TRUE),
        'total_sales', COALESCE(SUM(total_sales), 0),
        'total_orders', COALESCE(SUM(total_orders), 0),
        'total_customers', COALESCE(SUM(total_customers), 0),
        'average_order_value', CASE 
            WHEN SUM(total_orders) > 0 THEN SUM(total_sales) / SUM(total_orders)
            ELSE 0
        END,
        'continents', jsonb_agg(DISTINCT continent) FILTER (WHERE continent IS NOT NULL),
        'regions', jsonb_agg(DISTINCT region) FILTER (WHERE region IS NOT NULL),
        'currencies', jsonb_agg(DISTINCT currency_code) FILTER (WHERE currency_code IS NOT NULL),
        'top_performing_countries', (
            SELECT jsonb_agg(jsonb_build_object('code', code, 'name', name, 'sales', total_sales))
            FROM (
                SELECT code, name, total_sales
                FROM countries
                WHERE store_id = store_id_param AND is_active = TRUE
                ORDER BY total_sales DESC
                LIMIT 5
            ) top_countries
        )
    ) INTO result
    FROM countries
    WHERE store_id = store_id_param;
    
    RETURN COALESCE(result, '{}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- Function to search countries
CREATE OR REPLACE FUNCTION search_countries(
    search_term TEXT DEFAULT NULL,
    store_id_param BIGINT DEFAULT NULL,
    continent_param VARCHAR DEFAULT NULL,
    region_param VARCHAR DEFAULT NULL,
    currency_code_param VARCHAR DEFAULT NULL,
    shipping_enabled_param BOOLEAN DEFAULT NULL,
    is_active_param BOOLEAN DEFAULT NULL,
    limit_param INTEGER DEFAULT 50,
    offset_param INTEGER DEFAULT 0
)
RETURNS TABLE (
    id BIGINT,
    code VARCHAR,
    name VARCHAR,
    continent VARCHAR,
    region VARCHAR,
    currency_code VARCHAR,
    shipping_enabled BOOLEAN,
    is_active BOOLEAN,
    total_sales DECIMAL,
    total_orders INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.code,
        c.name,
        c.continent,
        c.region,
        c.currency_code,
        c.shipping_enabled,
        c.is_active,
        c.total_sales,
        c.total_orders
    FROM countries c
    WHERE 
        (store_id_param IS NULL OR c.store_id = store_id_param)
        AND (search_term IS NULL OR (
            c.name ILIKE '%' || search_term || '%' OR
            c.code ILIKE '%' || search_term || '%' OR
            c.official_name ILIKE '%' || search_term || '%'
        ))
        AND (continent_param IS NULL OR c.continent = continent_param)
        AND (region_param IS NULL OR c.region = region_param)
        AND (currency_code_param IS NULL OR c.currency_code = currency_code_param)
        AND (shipping_enabled_param IS NULL OR c.shipping_enabled = shipping_enabled_param)
        AND (is_active_param IS NULL OR c.is_active = is_active_param)
    ORDER BY c.total_sales DESC, c.name
    LIMIT limit_param OFFSET offset_param;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate shipping cost for country
CREATE OR REPLACE FUNCTION calculate_country_shipping_cost(
    country_code_param VARCHAR,
    store_id_param BIGINT,
    weight_kg DECIMAL DEFAULT 1.0,
    is_express BOOLEAN DEFAULT FALSE
)
RETURNS DECIMAL AS $$
DECLARE
    base_cost DECIMAL;
    express_cost DECIMAL;
    final_cost DECIMAL;
BEGIN
    SELECT 
        base_shipping_cost,
        express_shipping_cost
    INTO base_cost, express_cost
    FROM countries
    WHERE code = country_code_param 
      AND store_id = store_id_param 
      AND is_active = TRUE 
      AND shipping_enabled = TRUE;
    
    IF base_cost IS NULL THEN
        RAISE EXCEPTION 'Country not found or shipping not available';
    END IF;
    
    IF is_express AND express_cost IS NOT NULL THEN
        final_cost = express_cost;
    ELSE
        final_cost = base_cost;
    END IF;
    
    -- Apply weight multiplier (simple calculation)
    final_cost = final_cost * weight_kg;
    
    RETURN final_cost;
END;
$$ LANGUAGE plpgsql;

-- Function to update country metrics from orders
CREATE OR REPLACE FUNCTION update_country_metrics_from_orders(country_code_param VARCHAR, store_id_param BIGINT)
RETURNS VOID AS $$
DECLARE
    sales_total DECIMAL;
    orders_count INTEGER;
    customers_count INTEGER;
BEGIN
    -- Calculate metrics from orders (assuming orders table has shipping_country)
    SELECT 
        COALESCE(SUM(total), 0),
        COUNT(*),
        COUNT(DISTINCT customer_id)
    INTO sales_total, orders_count, customers_count
    FROM orders 
    WHERE shipping_country = country_code_param
      AND store_id = store_id_param;
    
    -- Update country metrics
    UPDATE countries 
    SET 
        total_sales = sales_total,
        total_orders = orders_count,
        total_customers = customers_count,
        updated_at = CURRENT_TIMESTAMP
    WHERE code = country_code_param 
      AND store_id = store_id_param;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Comments for Documentation
-- =====================================================

COMMENT ON TABLE countries IS 'Supported countries with shipping and regional information';
COMMENT ON COLUMN countries.id IS 'Primary key for country';
COMMENT ON COLUMN countries.salla_country_id IS 'Unique identifier from Salla API';
COMMENT ON COLUMN countries.store_id IS 'Reference to parent store';
COMMENT ON COLUMN countries.code IS 'ISO 3166-1 alpha-2 country code (2 letters)';
COMMENT ON COLUMN countries.name IS 'Country display name';
COMMENT ON COLUMN countries.currency_code IS 'Primary currency code for the country';
COMMENT ON COLUMN countries.shipping_enabled IS 'Whether shipping is available to this country';
COMMENT ON COLUMN countries.shipping_zones IS 'Shipping zone configurations in JSON format';
COMMENT ON COLUMN countries.payment_methods IS 'Supported payment methods in JSON format';
COMMENT ON COLUMN countries.vat_rate IS 'VAT/GST rate as decimal (0.15 for 15%)';
COMMENT ON COLUMN countries.total_sales IS 'Total sales amount for this country';
COMMENT ON COLUMN countries.total_orders IS 'Total number of orders for this country';
COMMENT ON COLUMN countries.delivery_success_rate IS 'Percentage of successful deliveries';
COMMENT ON COLUMN countries.created_at IS 'Timestamp when country was created';
COMMENT ON COLUMN countries.updated_at IS 'Timestamp when country was last updated';

-- Function comments
COMMENT ON FUNCTION get_country_stats(BIGINT) IS 'Get comprehensive statistics for a specific country';
COMMENT ON FUNCTION get_store_countries_stats(BIGINT) IS 'Get aggregated statistics for all countries of a store';
COMMENT ON FUNCTION search_countries(TEXT, BIGINT, VARCHAR, VARCHAR, VARCHAR, BOOLEAN, BOOLEAN, INTEGER, INTEGER) IS 'Search countries with various filters and pagination';
COMMENT ON FUNCTION calculate_country_shipping_cost(VARCHAR, BIGINT, DECIMAL, BOOLEAN) IS 'Calculate shipping cost for a specific country';
COMMENT ON FUNCTION update_country_metrics_from_orders(VARCHAR, BIGINT) IS 'Update country performance metrics based on order data';