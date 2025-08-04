-- =============================================================================
-- Payment Methods Table
-- =============================================================================
-- This table stores available payment methods for stores
-- Includes payment gateway settings and configurations
-- Links to Salla API for payment method synchronization

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create payment_methods table
CREATE TABLE IF NOT EXISTS payment_methods (
    -- Primary identification
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Salla API identifiers
    salla_payment_method_id VARCHAR(255) UNIQUE, -- Salla payment method ID
    
    -- Store relationship (required)
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Payment method identification
    method_code VARCHAR(100) NOT NULL, -- Unique code for the payment method
    method_name VARCHAR(255) NOT NULL, -- Display name
    method_name_ar VARCHAR(255), -- Arabic name
    method_name_en VARCHAR(255), -- English name
    
    -- Payment method type and category
    method_type VARCHAR(50) NOT NULL CHECK (method_type IN (
        'card', 'bank_transfer', 'digital_wallet', 'cash_on_delivery', 
        'installment', 'buy_now_pay_later', 'cryptocurrency', 'other'
    )),
    
    payment_gateway VARCHAR(100), -- Gateway provider (mada, visa, mastercard, stc_pay, etc.)
    gateway_provider VARCHAR(100), -- Gateway service provider
    
    -- Method status and availability
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_default BOOLEAN DEFAULT FALSE, -- Default payment method
    is_featured BOOLEAN DEFAULT FALSE, -- Featured in checkout
    
    -- Display settings
    display_order INTEGER DEFAULT 0, -- Order in payment method list
    icon_url VARCHAR(500), -- Payment method icon
    logo_url VARCHAR(500), -- Payment method logo
    description TEXT, -- Method description
    instructions TEXT, -- Payment instructions for customers
    
    -- Availability settings
    min_amount DECIMAL(15,4), -- Minimum order amount
    max_amount DECIMAL(15,4), -- Maximum order amount
    supported_currencies TEXT[], -- Supported currency codes
    
    -- Geographic availability
    available_countries TEXT[], -- Available country codes
    restricted_countries TEXT[], -- Restricted country codes
    available_regions JSONB, -- Available regions/states
    
    -- Customer restrictions
    customer_types TEXT[], -- Allowed customer types (individual, business)
    min_customer_age INTEGER, -- Minimum customer age
    requires_verification BOOLEAN DEFAULT FALSE, -- Requires customer verification
    
    -- Fee structure
    fee_type VARCHAR(50) CHECK (fee_type IN ('fixed', 'percentage', 'tiered', 'none')),
    fee_amount DECIMAL(15,4) DEFAULT 0, -- Fixed fee amount
    fee_percentage DECIMAL(5,4) DEFAULT 0, -- Percentage fee
    fee_structure JSONB, -- Complex fee structure
    
    -- Processing settings
    processing_time VARCHAR(100), -- Expected processing time
    settlement_time VARCHAR(100), -- Settlement time
    supports_refunds BOOLEAN DEFAULT TRUE,
    supports_partial_refunds BOOLEAN DEFAULT TRUE,
    supports_recurring BOOLEAN DEFAULT FALSE,
    supports_installments BOOLEAN DEFAULT FALSE,
    
    -- Security and compliance
    requires_3ds BOOLEAN DEFAULT FALSE, -- Requires 3D Secure
    pci_compliant BOOLEAN DEFAULT TRUE,
    security_features JSONB, -- Security features and settings
    
    -- Gateway configuration
    gateway_config JSONB, -- Gateway-specific configuration
    api_credentials JSONB, -- Encrypted API credentials
    webhook_url VARCHAR(500), -- Webhook URL for notifications
    
    -- Testing and sandbox
    test_mode BOOLEAN DEFAULT FALSE,
    sandbox_config JSONB, -- Sandbox configuration
    
    -- Installment settings (for installment methods)
    installment_plans JSONB, -- Available installment plans
    installment_provider VARCHAR(100), -- Installment service provider
    
    -- Digital wallet settings
    wallet_provider VARCHAR(100), -- Wallet provider (stc_pay, apple_pay, etc.)
    wallet_config JSONB, -- Wallet-specific configuration
    
    -- Bank transfer settings
    bank_details JSONB, -- Bank account details
    transfer_instructions TEXT, -- Transfer instructions
    
    -- Cash on delivery settings
    cod_fee DECIMAL(15,4), -- COD handling fee
    cod_areas JSONB, -- Areas where COD is available
    
    -- Validation rules
    validation_rules JSONB, -- Custom validation rules
    error_messages JSONB, -- Custom error messages
    
    -- Analytics and tracking
    usage_count INTEGER DEFAULT 0, -- Number of times used
    success_rate DECIMAL(5,2), -- Success rate percentage
    last_used_at TIMESTAMPTZ, -- Last time method was used
    
    -- Integration status
    integration_status VARCHAR(50) DEFAULT 'pending' CHECK (integration_status IN (
        'pending', 'active', 'inactive', 'error', 'maintenance'
    )),
    last_sync_at TIMESTAMPTZ, -- Last sync with gateway
    sync_errors JSONB, -- Sync error details
    
    -- Maintenance and updates
    maintenance_mode BOOLEAN DEFAULT FALSE,
    maintenance_message TEXT,
    maintenance_start_at TIMESTAMPTZ,
    maintenance_end_at TIMESTAMPTZ,
    
    -- Additional metadata
    metadata JSONB, -- Additional payment method data
    tags TEXT[], -- Payment method tags
    
    -- Audit fields
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID, -- User who created the record
    updated_by UUID -- User who last updated the record
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_payment_methods_store_id ON payment_methods(store_id);
CREATE INDEX IF NOT EXISTS idx_payment_methods_salla_payment_method_id ON payment_methods(salla_payment_method_id);
CREATE INDEX IF NOT EXISTS idx_payment_methods_method_code ON payment_methods(method_code);
CREATE INDEX IF NOT EXISTS idx_payment_methods_method_type ON payment_methods(method_type);
CREATE INDEX IF NOT EXISTS idx_payment_methods_payment_gateway ON payment_methods(payment_gateway);
CREATE INDEX IF NOT EXISTS idx_payment_methods_gateway_provider ON payment_methods(gateway_provider);
CREATE INDEX IF NOT EXISTS idx_payment_methods_is_active ON payment_methods(is_active);
CREATE INDEX IF NOT EXISTS idx_payment_methods_is_default ON payment_methods(is_default);
CREATE INDEX IF NOT EXISTS idx_payment_methods_display_order ON payment_methods(display_order);
CREATE INDEX IF NOT EXISTS idx_payment_methods_integration_status ON payment_methods(integration_status);
CREATE INDEX IF NOT EXISTS idx_payment_methods_test_mode ON payment_methods(test_mode);
CREATE INDEX IF NOT EXISTS idx_payment_methods_maintenance_mode ON payment_methods(maintenance_mode);
CREATE INDEX IF NOT EXISTS idx_payment_methods_created_at ON payment_methods(created_at);

-- GIN indexes for array columns
CREATE INDEX IF NOT EXISTS idx_payment_methods_supported_currencies_gin ON payment_methods USING GIN(supported_currencies);
CREATE INDEX IF NOT EXISTS idx_payment_methods_available_countries_gin ON payment_methods USING GIN(available_countries);
CREATE INDEX IF NOT EXISTS idx_payment_methods_restricted_countries_gin ON payment_methods USING GIN(restricted_countries);
CREATE INDEX IF NOT EXISTS idx_payment_methods_customer_types_gin ON payment_methods USING GIN(customer_types);
CREATE INDEX IF NOT EXISTS idx_payment_methods_tags_gin ON payment_methods USING GIN(tags);

-- GIN indexes for JSONB columns
CREATE INDEX IF NOT EXISTS idx_payment_methods_available_regions_gin ON payment_methods USING GIN(available_regions);
CREATE INDEX IF NOT EXISTS idx_payment_methods_fee_structure_gin ON payment_methods USING GIN(fee_structure);
CREATE INDEX IF NOT EXISTS idx_payment_methods_security_features_gin ON payment_methods USING GIN(security_features);
CREATE INDEX IF NOT EXISTS idx_payment_methods_gateway_config_gin ON payment_methods USING GIN(gateway_config);
CREATE INDEX IF NOT EXISTS idx_payment_methods_installment_plans_gin ON payment_methods USING GIN(installment_plans);
CREATE INDEX IF NOT EXISTS idx_payment_methods_wallet_config_gin ON payment_methods USING GIN(wallet_config);
CREATE INDEX IF NOT EXISTS idx_payment_methods_bank_details_gin ON payment_methods USING GIN(bank_details);
CREATE INDEX IF NOT EXISTS idx_payment_methods_cod_areas_gin ON payment_methods USING GIN(cod_areas);
CREATE INDEX IF NOT EXISTS idx_payment_methods_validation_rules_gin ON payment_methods USING GIN(validation_rules);
CREATE INDEX IF NOT EXISTS idx_payment_methods_metadata_gin ON payment_methods USING GIN(metadata);

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_payment_methods_store_active ON payment_methods(store_id, is_active);
CREATE INDEX IF NOT EXISTS idx_payment_methods_store_type ON payment_methods(store_id, method_type);
CREATE INDEX IF NOT EXISTS idx_payment_methods_store_order ON payment_methods(store_id, display_order);
CREATE INDEX IF NOT EXISTS idx_payment_methods_active_order ON payment_methods(is_active, display_order);

-- Unique constraint for store and method code
CREATE UNIQUE INDEX IF NOT EXISTS idx_payment_methods_store_method_code ON payment_methods(store_id, method_code);

-- Create trigger to automatically update updated_at
CREATE OR REPLACE FUNCTION update_payment_methods_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_payment_methods_updated_at
    BEFORE UPDATE ON payment_methods
    FOR EACH ROW
    EXECUTE FUNCTION update_payment_methods_updated_at();

-- Create trigger to ensure only one default payment method per store
CREATE OR REPLACE FUNCTION ensure_single_default_payment_method()
RETURNS TRIGGER AS $$
BEGIN
    -- If setting this method as default, unset others
    IF NEW.is_default = TRUE THEN
        UPDATE payment_methods 
        SET is_default = FALSE 
        WHERE store_id = NEW.store_id 
        AND id != NEW.id 
        AND is_default = TRUE;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_ensure_single_default_payment_method
    BEFORE INSERT OR UPDATE ON payment_methods
    FOR EACH ROW
    EXECUTE FUNCTION ensure_single_default_payment_method();

-- Create trigger to increment usage count
CREATE OR REPLACE FUNCTION increment_payment_method_usage()
RETURNS TRIGGER AS $$
BEGIN
    -- This would be called from transactions table trigger
    -- when a payment is made using this method
    UPDATE payment_methods 
    SET 
        usage_count = usage_count + 1,
        last_used_at = NOW()
    WHERE id = NEW.payment_method_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Helper function to get active payment methods for a store
CREATE OR REPLACE FUNCTION get_active_payment_methods(
    p_store_id UUID,
    p_order_amount DECIMAL(15,4) DEFAULT NULL,
    p_currency_code VARCHAR(3) DEFAULT 'SAR',
    p_country_code VARCHAR(2) DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    method_code VARCHAR(100),
    method_name VARCHAR(255),
    method_type VARCHAR(50),
    payment_gateway VARCHAR(100),
    fee_amount DECIMAL(15,4),
    fee_percentage DECIMAL(5,4),
    icon_url VARCHAR(500),
    description TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pm.id,
        pm.method_code,
        pm.method_name,
        pm.method_type,
        pm.payment_gateway,
        pm.fee_amount,
        pm.fee_percentage,
        pm.icon_url,
        pm.description
    FROM payment_methods pm
    WHERE pm.store_id = p_store_id
        AND pm.is_active = TRUE
        AND pm.integration_status = 'active'
        AND pm.maintenance_mode = FALSE
        AND (p_order_amount IS NULL OR pm.min_amount IS NULL OR p_order_amount >= pm.min_amount)
        AND (p_order_amount IS NULL OR pm.max_amount IS NULL OR p_order_amount <= pm.max_amount)
        AND (p_currency_code IS NULL OR pm.supported_currencies IS NULL OR p_currency_code = ANY(pm.supported_currencies))
        AND (p_country_code IS NULL OR pm.available_countries IS NULL OR p_country_code = ANY(pm.available_countries))
        AND (pm.restricted_countries IS NULL OR p_country_code != ALL(pm.restricted_countries))
    ORDER BY pm.display_order ASC, pm.method_name ASC;
END;
$$ LANGUAGE plpgsql;

-- Helper function to calculate payment method fee
CREATE OR REPLACE FUNCTION calculate_payment_method_fee(
    p_payment_method_id UUID,
    p_order_amount DECIMAL(15,4)
)
RETURNS DECIMAL(15,4) AS $$
DECLARE
    method_record payment_methods%ROWTYPE;
    calculated_fee DECIMAL(15,4) := 0;
BEGIN
    -- Get payment method details
    SELECT * INTO method_record
    FROM payment_methods
    WHERE id = p_payment_method_id;
    
    IF NOT FOUND THEN
        RETURN 0;
    END IF;
    
    -- Calculate fee based on type
    CASE method_record.fee_type
        WHEN 'fixed' THEN
            calculated_fee = COALESCE(method_record.fee_amount, 0);
        WHEN 'percentage' THEN
            calculated_fee = p_order_amount * COALESCE(method_record.fee_percentage, 0) / 100;
        WHEN 'tiered' THEN
            -- Complex tiered calculation would go here
            -- For now, use fixed + percentage
            calculated_fee = COALESCE(method_record.fee_amount, 0) + 
                           (p_order_amount * COALESCE(method_record.fee_percentage, 0) / 100);
        ELSE
            calculated_fee = 0;
    END CASE;
    
    RETURN calculated_fee;
END;
$$ LANGUAGE plpgsql;

-- Helper function to validate payment method for order
CREATE OR REPLACE FUNCTION validate_payment_method(
    p_payment_method_id UUID,
    p_order_amount DECIMAL(15,4),
    p_currency_code VARCHAR(3),
    p_country_code VARCHAR(2) DEFAULT NULL,
    p_customer_type VARCHAR(50) DEFAULT NULL
)
RETURNS TABLE (
    is_valid BOOLEAN,
    error_message TEXT
) AS $$
DECLARE
    method_record payment_methods%ROWTYPE;
BEGIN
    -- Get payment method details
    SELECT * INTO method_record
    FROM payment_methods
    WHERE id = p_payment_method_id;
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Payment method not found';
        RETURN;
    END IF;
    
    -- Check if method is active
    IF NOT method_record.is_active THEN
        RETURN QUERY SELECT FALSE, 'Payment method is not active';
        RETURN;
    END IF;
    
    -- Check integration status
    IF method_record.integration_status != 'active' THEN
        RETURN QUERY SELECT FALSE, 'Payment method is not available';
        RETURN;
    END IF;
    
    -- Check maintenance mode
    IF method_record.maintenance_mode THEN
        RETURN QUERY SELECT FALSE, COALESCE(method_record.maintenance_message, 'Payment method is under maintenance');
        RETURN;
    END IF;
    
    -- Check amount limits
    IF method_record.min_amount IS NOT NULL AND p_order_amount < method_record.min_amount THEN
        RETURN QUERY SELECT FALSE, 'Order amount is below minimum limit';
        RETURN;
    END IF;
    
    IF method_record.max_amount IS NOT NULL AND p_order_amount > method_record.max_amount THEN
        RETURN QUERY SELECT FALSE, 'Order amount exceeds maximum limit';
        RETURN;
    END IF;
    
    -- Check currency support
    IF method_record.supported_currencies IS NOT NULL AND NOT (p_currency_code = ANY(method_record.supported_currencies)) THEN
        RETURN QUERY SELECT FALSE, 'Currency not supported';
        RETURN;
    END IF;
    
    -- Check country availability
    IF p_country_code IS NOT NULL THEN
        IF method_record.available_countries IS NOT NULL AND NOT (p_country_code = ANY(method_record.available_countries)) THEN
            RETURN QUERY SELECT FALSE, 'Payment method not available in your country';
            RETURN;
        END IF;
        
        IF method_record.restricted_countries IS NOT NULL AND (p_country_code = ANY(method_record.restricted_countries)) THEN
            RETURN QUERY SELECT FALSE, 'Payment method is restricted in your country';
            RETURN;
        END IF;
    END IF;
    
    -- Check customer type
    IF p_customer_type IS NOT NULL AND method_record.customer_types IS NOT NULL AND NOT (p_customer_type = ANY(method_record.customer_types)) THEN
        RETURN QUERY SELECT FALSE, 'Payment method not available for your customer type';
        RETURN;
    END IF;
    
    -- All validations passed
    RETURN QUERY SELECT TRUE, 'Payment method is valid';
END;
$$ LANGUAGE plpgsql;

-- Add comments for documentation
COMMENT ON TABLE payment_methods IS 'Stores available payment methods and their configurations for stores';
COMMENT ON COLUMN payment_methods.salla_payment_method_id IS 'Unique identifier from Salla API';
COMMENT ON COLUMN payment_methods.method_code IS 'Unique code for the payment method within the store';
COMMENT ON COLUMN payment_methods.method_type IS 'Type of payment method: card, bank_transfer, digital_wallet, etc.';
COMMENT ON COLUMN payment_methods.payment_gateway IS 'Payment gateway provider (mada, visa, stc_pay, etc.)';
COMMENT ON COLUMN payment_methods.fee_structure IS 'Complex fee structure in JSON format';
COMMENT ON COLUMN payment_methods.gateway_config IS 'Gateway-specific configuration in JSON format';
COMMENT ON COLUMN payment_methods.installment_plans IS 'Available installment plans in JSON format';
COMMENT ON COLUMN payment_methods.supported_currencies IS 'Array of supported currency codes';
COMMENT ON COLUMN payment_methods.available_countries IS 'Array of available country codes';
COMMENT ON COLUMN payment_methods.integration_status IS 'Current integration status with the payment gateway';
COMMENT ON COLUMN payment_methods.metadata IS 'Additional payment method data in JSON format';
COMMENT ON COLUMN payment_methods.tags IS 'Array of tags for payment method categorization';