-- =====================================================
-- Currencies Table for Salla-Supabase Integration
-- =====================================================
-- This table stores supported currencies and exchange rates
-- for multi-currency support in stores

CREATE TABLE IF NOT EXISTS currencies (
    -- Primary identification
    id BIGSERIAL PRIMARY KEY,
    salla_currency_id VARCHAR(255) UNIQUE, -- Salla API currency identifier
    
    -- Store relationship (required)
    store_id BIGINT NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Basic currency information
    code VARCHAR(3) NOT NULL, -- ISO 4217 currency code (USD, EUR, SAR, etc.)
    name VARCHAR(255) NOT NULL,
    name_ar VARCHAR(255), -- Arabic name
    name_en VARCHAR(255), -- English name
    symbol VARCHAR(10), -- Currency symbol ($, €, ﷼, etc.)
    
    -- Currency details
    decimal_places INTEGER DEFAULT 2, -- Number of decimal places
    rounding_method VARCHAR(50) DEFAULT 'round', -- round, floor, ceil
    thousand_separator VARCHAR(5) DEFAULT ',',
    decimal_separator VARCHAR(5) DEFAULT '.',
    
    -- Exchange rate information
    exchange_rate DECIMAL(15,8) DEFAULT 1.0, -- Rate relative to base currency
    base_currency_code VARCHAR(3), -- Base currency for conversion
    rate_source VARCHAR(100), -- Source of exchange rate (manual, api, bank)
    rate_provider VARCHAR(255), -- Provider name (xe.com, fixer.io, etc.)
    
    -- Rate update information
    last_rate_update TIMESTAMPTZ,
    rate_update_frequency VARCHAR(50) DEFAULT 'daily', -- hourly, daily, weekly, manual
    auto_update_enabled BOOLEAN DEFAULT FALSE,
    rate_fluctuation_threshold DECIMAL(5,4) DEFAULT 0.05, -- 5% threshold
    
    -- Status and settings
    status VARCHAR(50) DEFAULT 'active', -- active, inactive, deprecated
    is_active BOOLEAN DEFAULT TRUE,
    is_default BOOLEAN DEFAULT FALSE, -- Default currency for the store
    is_base_currency BOOLEAN DEFAULT FALSE, -- Base currency for calculations
    
    -- Display settings
    display_format VARCHAR(100), -- Format string for display
    position VARCHAR(20) DEFAULT 'before', -- before, after (symbol position)
    space_between BOOLEAN DEFAULT FALSE, -- Space between symbol and amount
    
    -- Conversion settings
    buy_rate DECIMAL(15,8), -- Rate for buying this currency
    sell_rate DECIMAL(15,8), -- Rate for selling this currency
    margin_percentage DECIMAL(5,4) DEFAULT 0, -- Margin for currency conversion
    
    -- Historical tracking
    historical_rates JSONB, -- Historical exchange rates
    rate_history_retention_days INTEGER DEFAULT 365,
    
    -- Validation and limits
    min_amount DECIMAL(15,2) DEFAULT 0.01, -- Minimum transaction amount
    max_amount DECIMAL(15,2), -- Maximum transaction amount
    daily_limit DECIMAL(15,2), -- Daily transaction limit
    
    -- Regional information
    country_codes JSONB, -- Countries where this currency is used
    region VARCHAR(100), -- Geographic region
    timezone VARCHAR(100), -- Primary timezone for this currency
    
    -- Payment integration
    payment_gateways JSONB, -- Supported payment gateways
    gateway_settings JSONB, -- Gateway-specific settings
    
    -- Performance metrics
    total_transactions INTEGER DEFAULT 0,
    total_volume DECIMAL(15,2) DEFAULT 0,
    average_transaction_amount DECIMAL(15,2) DEFAULT 0,
    conversion_count INTEGER DEFAULT 0, -- Number of conversions
    
    -- Risk management
    volatility_score DECIMAL(3,2), -- Volatility rating (1.00 to 5.00)
    risk_level VARCHAR(50) DEFAULT 'low', -- low, medium, high
    hedging_enabled BOOLEAN DEFAULT FALSE,
    
    -- Compliance and regulations
    regulatory_status VARCHAR(100),
    compliance_notes TEXT,
    restricted_countries JSONB, -- Countries where currency is restricted
    
    -- API and integration
    api_settings JSONB,
    webhook_events JSONB,
    sync_status VARCHAR(50) DEFAULT 'pending',
    last_sync_at TIMESTAMPTZ,
    sync_errors JSONB,
    
    -- Localization
    localized_names JSONB, -- Names in different languages
    localized_symbols JSONB, -- Symbols in different locales
    rtl_support BOOLEAN DEFAULT FALSE, -- Right-to-left text support
    
    -- Analytics and reporting
    analytics_enabled BOOLEAN DEFAULT TRUE,
    reporting_currency BOOLEAN DEFAULT FALSE, -- Use for reporting
    
    -- Custom fields and metadata
    custom_fields JSONB,
    tags JSONB, -- Currency tags for categorization
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
CREATE INDEX IF NOT EXISTS idx_currencies_store_id ON currencies(store_id);
CREATE INDEX IF NOT EXISTS idx_currencies_salla_currency_id ON currencies(salla_currency_id);
CREATE INDEX IF NOT EXISTS idx_currencies_code ON currencies(code);

-- Status and settings indexes
CREATE INDEX IF NOT EXISTS idx_currencies_status ON currencies(status);
CREATE INDEX IF NOT EXISTS idx_currencies_is_active ON currencies(is_active);
CREATE INDEX IF NOT EXISTS idx_currencies_is_default ON currencies(is_default);
CREATE INDEX IF NOT EXISTS idx_currencies_is_base_currency ON currencies(is_base_currency);

-- Exchange rate indexes
CREATE INDEX IF NOT EXISTS idx_currencies_exchange_rate ON currencies(exchange_rate);
CREATE INDEX IF NOT EXISTS idx_currencies_base_currency_code ON currencies(base_currency_code);
CREATE INDEX IF NOT EXISTS idx_currencies_last_rate_update ON currencies(last_rate_update);

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_currencies_total_volume ON currencies(total_volume);
CREATE INDEX IF NOT EXISTS idx_currencies_total_transactions ON currencies(total_transactions);

-- Timestamp indexes
CREATE INDEX IF NOT EXISTS idx_currencies_created_at ON currencies(created_at);
CREATE INDEX IF NOT EXISTS idx_currencies_updated_at ON currencies(updated_at);

-- Composite indexes
CREATE INDEX IF NOT EXISTS idx_currencies_store_code ON currencies(store_id, code);
CREATE INDEX IF NOT EXISTS idx_currencies_store_active ON currencies(store_id, is_active);
CREATE INDEX IF NOT EXISTS idx_currencies_store_default ON currencies(store_id, is_default);

-- JSONB indexes for better performance
CREATE INDEX IF NOT EXISTS idx_currencies_country_codes_gin ON currencies USING GIN(country_codes);
CREATE INDEX IF NOT EXISTS idx_currencies_payment_gateways_gin ON currencies USING GIN(payment_gateways);
CREATE INDEX IF NOT EXISTS idx_currencies_historical_rates_gin ON currencies USING GIN(historical_rates);

-- Unique constraints
CREATE UNIQUE INDEX IF NOT EXISTS idx_currencies_store_code_unique ON currencies(store_id, code);
CREATE UNIQUE INDEX IF NOT EXISTS idx_currencies_store_default_unique ON currencies(store_id) WHERE is_default = TRUE;
CREATE UNIQUE INDEX IF NOT EXISTS idx_currencies_store_base_unique ON currencies(store_id) WHERE is_base_currency = TRUE;

-- =====================================================
-- Triggers for Automatic Updates
-- =====================================================

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_currencies_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_currencies_updated_at
    BEFORE UPDATE ON currencies
    FOR EACH ROW
    EXECUTE FUNCTION update_currencies_updated_at();

-- Trigger to validate currency settings
CREATE OR REPLACE FUNCTION validate_currency_settings()
RETURNS TRIGGER AS $$
BEGIN
    -- Validate currency code format (3 characters, uppercase)
    IF NEW.code !~ '^[A-Z]{3}$' THEN
        RAISE EXCEPTION 'Currency code must be 3 uppercase letters (ISO 4217 format)';
    END IF;
    
    -- Validate decimal places
    IF NEW.decimal_places < 0 OR NEW.decimal_places > 8 THEN
        RAISE EXCEPTION 'Decimal places must be between 0 and 8';
    END IF;
    
    -- Validate exchange rate
    IF NEW.exchange_rate <= 0 THEN
        RAISE EXCEPTION 'Exchange rate must be greater than 0';
    END IF;
    
    -- Set activated_at when currency becomes active
    IF NEW.is_active = TRUE AND (OLD IS NULL OR OLD.is_active = FALSE) THEN
        NEW.activated_at = CURRENT_TIMESTAMP;
    END IF;
    
    -- Set deactivated_at when currency becomes inactive
    IF NEW.is_active = FALSE AND OLD IS NOT NULL AND OLD.is_active = TRUE THEN
        NEW.deactivated_at = CURRENT_TIMESTAMP;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validate_currency_settings
    BEFORE INSERT OR UPDATE ON currencies
    FOR EACH ROW
    EXECUTE FUNCTION validate_currency_settings();

-- Trigger to update performance metrics
CREATE OR REPLACE FUNCTION update_currency_performance_metrics()
RETURNS TRIGGER AS $$
BEGIN
    -- Update average transaction amount
    IF NEW.total_transactions > 0 THEN
        NEW.average_transaction_amount = NEW.total_volume / NEW.total_transactions;
    ELSE
        NEW.average_transaction_amount = 0;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_currency_performance_metrics
    BEFORE UPDATE ON currencies
    FOR EACH ROW
    WHEN (OLD.total_volume IS DISTINCT FROM NEW.total_volume OR OLD.total_transactions IS DISTINCT FROM NEW.total_transactions)
    EXECUTE FUNCTION update_currency_performance_metrics();

-- Trigger to store historical exchange rates
CREATE OR REPLACE FUNCTION store_historical_exchange_rate()
RETURNS TRIGGER AS $$
DECLARE
    current_history JSONB;
    new_rate_entry JSONB;
BEGIN
    -- Only store history if exchange rate changed
    IF OLD IS NULL OR OLD.exchange_rate IS DISTINCT FROM NEW.exchange_rate THEN
        current_history = COALESCE(NEW.historical_rates, '[]'::jsonb);
        
        new_rate_entry = jsonb_build_object(
            'rate', NEW.exchange_rate,
            'timestamp', CURRENT_TIMESTAMP,
            'source', NEW.rate_source,
            'provider', NEW.rate_provider
        );
        
        -- Add new rate to history
        NEW.historical_rates = current_history || new_rate_entry;
        
        -- Keep only recent history based on retention period
        NEW.historical_rates = (
            SELECT jsonb_agg(rate_entry)
            FROM jsonb_array_elements(NEW.historical_rates) AS rate_entry
            WHERE (rate_entry->>'timestamp')::timestamptz > 
                  CURRENT_TIMESTAMP - INTERVAL '1 day' * NEW.rate_history_retention_days
        );
        
        NEW.last_rate_update = CURRENT_TIMESTAMP;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_store_historical_exchange_rate
    BEFORE INSERT OR UPDATE ON currencies
    FOR EACH ROW
    EXECUTE FUNCTION store_historical_exchange_rate();

-- =====================================================
-- Helper Functions
-- =====================================================

-- Function to get currency statistics
CREATE OR REPLACE FUNCTION get_currency_stats(currency_id BIGINT)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'currency_id', c.id,
        'code', c.code,
        'name', c.name,
        'symbol', c.symbol,
        'exchange_rate', c.exchange_rate,
        'is_default', c.is_default,
        'is_base_currency', c.is_base_currency,
        'total_transactions', COALESCE(c.total_transactions, 0),
        'total_volume', COALESCE(c.total_volume, 0),
        'average_transaction_amount', COALESCE(c.average_transaction_amount, 0),
        'conversion_count', COALESCE(c.conversion_count, 0),
        'volatility_score', COALESCE(c.volatility_score, 0),
        'last_rate_update', c.last_rate_update,
        'status', c.status,
        'is_active', c.is_active
    ) INTO result
    FROM currencies c
    WHERE c.id = currency_id;
    
    RETURN COALESCE(result, '{}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- Function to get store currencies statistics
CREATE OR REPLACE FUNCTION get_store_currencies_stats(store_id_param BIGINT)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'store_id', store_id_param,
        'total_currencies', COUNT(*),
        'active_currencies', COUNT(*) FILTER (WHERE is_active = TRUE),
        'default_currency', (SELECT code FROM currencies WHERE store_id = store_id_param AND is_default = TRUE LIMIT 1),
        'base_currency', (SELECT code FROM currencies WHERE store_id = store_id_param AND is_base_currency = TRUE LIMIT 1),
        'total_volume', COALESCE(SUM(total_volume), 0),
        'total_transactions', COALESCE(SUM(total_transactions), 0),
        'supported_regions', jsonb_agg(DISTINCT region) FILTER (WHERE region IS NOT NULL),
        'currency_codes', jsonb_agg(code ORDER BY is_default DESC, total_volume DESC)
    ) INTO result
    FROM currencies
    WHERE store_id = store_id_param;
    
    RETURN COALESCE(result, '{}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- Function to convert amount between currencies
CREATE OR REPLACE FUNCTION convert_currency(
    amount DECIMAL,
    from_currency_code VARCHAR,
    to_currency_code VARCHAR,
    store_id_param BIGINT
)
RETURNS DECIMAL AS $$
DECLARE
    from_rate DECIMAL;
    to_rate DECIMAL;
    base_amount DECIMAL;
    converted_amount DECIMAL;
BEGIN
    -- Get exchange rates
    SELECT exchange_rate INTO from_rate
    FROM currencies
    WHERE code = from_currency_code AND store_id = store_id_param AND is_active = TRUE;
    
    SELECT exchange_rate INTO to_rate
    FROM currencies
    WHERE code = to_currency_code AND store_id = store_id_param AND is_active = TRUE;
    
    -- Check if currencies exist
    IF from_rate IS NULL OR to_rate IS NULL THEN
        RAISE EXCEPTION 'Currency not found or inactive';
    END IF;
    
    -- Convert to base currency first, then to target currency
    base_amount = amount / from_rate;
    converted_amount = base_amount * to_rate;
    
    RETURN converted_amount;
END;
$$ LANGUAGE plpgsql;

-- Function to update exchange rates
CREATE OR REPLACE FUNCTION update_exchange_rates(
    store_id_param BIGINT,
    rates_data JSONB
)
RETURNS INTEGER AS $$
DECLARE
    rate_entry JSONB;
    updated_count INTEGER := 0;
BEGIN
    -- Loop through provided rates
    FOR rate_entry IN SELECT * FROM jsonb_array_elements(rates_data)
    LOOP
        UPDATE currencies
        SET 
            exchange_rate = (rate_entry->>'rate')::DECIMAL,
            rate_source = COALESCE(rate_entry->>'source', rate_source),
            rate_provider = COALESCE(rate_entry->>'provider', rate_provider),
            updated_at = CURRENT_TIMESTAMP
        WHERE 
            store_id = store_id_param
            AND code = rate_entry->>'currency_code'
            AND is_active = TRUE;
        
        IF FOUND THEN
            updated_count := updated_count + 1;
        END IF;
    END LOOP;
    
    RETURN updated_count;
END;
$$ LANGUAGE plpgsql;

-- Function to get currency conversion history
CREATE OR REPLACE FUNCTION get_currency_conversion_history(
    currency_code_param VARCHAR,
    store_id_param BIGINT,
    days_back INTEGER DEFAULT 30
)
RETURNS TABLE (
    rate DECIMAL,
    rate_date TIMESTAMPTZ,
    source VARCHAR,
    provider VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (rate_entry->>'rate')::DECIMAL,
        (rate_entry->>'timestamp')::TIMESTAMPTZ,
        rate_entry->>'source',
        rate_entry->>'provider'
    FROM currencies c,
         jsonb_array_elements(c.historical_rates) AS rate_entry
    WHERE 
        c.code = currency_code_param
        AND c.store_id = store_id_param
        AND (rate_entry->>'timestamp')::TIMESTAMPTZ > CURRENT_TIMESTAMP - INTERVAL '1 day' * days_back
    ORDER BY (rate_entry->>'timestamp')::TIMESTAMPTZ DESC;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Comments for Documentation
-- =====================================================

COMMENT ON TABLE currencies IS 'Supported currencies with exchange rates for multi-currency stores';
COMMENT ON COLUMN currencies.id IS 'Primary key for currency';
COMMENT ON COLUMN currencies.salla_currency_id IS 'Unique identifier from Salla API';
COMMENT ON COLUMN currencies.store_id IS 'Reference to parent store';
COMMENT ON COLUMN currencies.code IS 'ISO 4217 currency code (3 letters)';
COMMENT ON COLUMN currencies.name IS 'Currency display name';
COMMENT ON COLUMN currencies.symbol IS 'Currency symbol for display';
COMMENT ON COLUMN currencies.exchange_rate IS 'Exchange rate relative to base currency';
COMMENT ON COLUMN currencies.is_default IS 'Default currency for the store';
COMMENT ON COLUMN currencies.is_base_currency IS 'Base currency for calculations';
COMMENT ON COLUMN currencies.historical_rates IS 'Historical exchange rates in JSON format';
COMMENT ON COLUMN currencies.total_transactions IS 'Total number of transactions in this currency';
COMMENT ON COLUMN currencies.total_volume IS 'Total transaction volume in this currency';
COMMENT ON COLUMN currencies.created_at IS 'Timestamp when currency was created';
COMMENT ON COLUMN currencies.updated_at IS 'Timestamp when currency was last updated';

-- Function comments
COMMENT ON FUNCTION get_currency_stats(BIGINT) IS 'Get comprehensive statistics for a specific currency';
COMMENT ON FUNCTION get_store_currencies_stats(BIGINT) IS 'Get aggregated statistics for all currencies of a store';
COMMENT ON FUNCTION convert_currency(DECIMAL, VARCHAR, VARCHAR, BIGINT) IS 'Convert amount between two currencies';
COMMENT ON FUNCTION update_exchange_rates(BIGINT, JSONB) IS 'Bulk update exchange rates for store currencies';
COMMENT ON FUNCTION get_currency_conversion_history(VARCHAR, BIGINT, INTEGER) IS 'Get historical exchange rates for a currency';