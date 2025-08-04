-- =============================================================================
-- Payment Banks Table
-- =============================================================================
-- This table stores bank information for payment processing
-- Includes bank transfer details and configurations
-- Links to Salla API for bank information synchronization

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create payment_banks table
CREATE TABLE IF NOT EXISTS payment_banks (
    -- Primary identification
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Salla API identifiers
    salla_bank_id VARCHAR(255) UNIQUE, -- Salla bank ID
    
    -- Store relationship (required)
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Bank identification
    bank_code VARCHAR(50) NOT NULL, -- Bank code (SWIFT/BIC or local code)
    bank_name VARCHAR(255) NOT NULL, -- Bank name
    bank_name_ar VARCHAR(255), -- Arabic bank name
    bank_name_en VARCHAR(255), -- English bank name
    
    -- Bank details
    bank_type VARCHAR(50) CHECK (bank_type IN (
        'commercial', 'islamic', 'investment', 'development', 'central', 'other'
    )),
    
    country_code VARCHAR(2) NOT NULL, -- ISO country code
    currency_code VARCHAR(3) NOT NULL DEFAULT 'SAR', -- Primary currency
    supported_currencies TEXT[], -- All supported currencies
    
    -- Bank contact information
    website_url VARCHAR(500),
    phone_number VARCHAR(50),
    email VARCHAR(255),
    
    -- Bank address
    address JSONB, -- Complete bank address
    
    -- Account details for receiving payments
    account_holder_name VARCHAR(255), -- Account holder name
    account_number VARCHAR(100), -- Bank account number
    iban VARCHAR(34), -- International Bank Account Number
    swift_code VARCHAR(11), -- SWIFT/BIC code
    routing_number VARCHAR(50), -- Routing number (for US banks)
    sort_code VARCHAR(10), -- Sort code (for UK banks)
    
    -- Additional account details
    account_type VARCHAR(50) CHECK (account_type IN (
        'checking', 'savings', 'business', 'current', 'other'
    )),
    
    branch_name VARCHAR(255), -- Bank branch name
    branch_code VARCHAR(50), -- Bank branch code
    branch_address JSONB, -- Branch address
    
    -- Transfer settings
    min_transfer_amount DECIMAL(15,4), -- Minimum transfer amount
    max_transfer_amount DECIMAL(15,4), -- Maximum transfer amount
    daily_transfer_limit DECIMAL(15,4), -- Daily transfer limit
    monthly_transfer_limit DECIMAL(15,4), -- Monthly transfer limit
    
    -- Processing information
    processing_time VARCHAR(100), -- Expected processing time
    settlement_time VARCHAR(100), -- Settlement time
    cut_off_time TIME, -- Daily cut-off time for same-day processing
    
    -- Fees and charges
    transfer_fee_type VARCHAR(50) CHECK (transfer_fee_type IN ('fixed', 'percentage', 'tiered', 'none')),
    transfer_fee_amount DECIMAL(15,4) DEFAULT 0, -- Fixed transfer fee
    transfer_fee_percentage DECIMAL(5,4) DEFAULT 0, -- Percentage transfer fee
    fee_structure JSONB, -- Complex fee structure
    
    -- Operating hours and availability
    operating_hours JSONB, -- Bank operating hours
    operating_days TEXT[], -- Operating days of the week
    holiday_schedule JSONB, -- Holiday schedule
    
    -- Bank status and availability
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_default BOOLEAN DEFAULT FALSE, -- Default bank for the store
    is_verified BOOLEAN DEFAULT FALSE, -- Whether bank details are verified
    
    -- Verification details
    verification_status VARCHAR(50) DEFAULT 'pending' CHECK (verification_status IN (
        'pending', 'verified', 'rejected', 'expired'
    )),
    verification_date TIMESTAMPTZ,
    verification_method VARCHAR(100), -- How verification was done
    verification_reference VARCHAR(255), -- Verification reference number
    verification_notes TEXT,
    
    -- Compliance and regulations
    regulatory_info JSONB, -- Regulatory information
    compliance_status VARCHAR(50) DEFAULT 'compliant',
    aml_status VARCHAR(50), -- Anti-Money Laundering status
    kyc_required BOOLEAN DEFAULT TRUE, -- Know Your Customer requirement
    
    -- Integration settings
    api_endpoint VARCHAR(500), -- Bank API endpoint
    api_version VARCHAR(20), -- API version
    api_credentials JSONB, -- Encrypted API credentials
    webhook_url VARCHAR(500), -- Webhook URL for notifications
    
    -- Security settings
    encryption_method VARCHAR(100), -- Encryption method used
    security_protocols TEXT[], -- Supported security protocols
    certificate_info JSONB, -- SSL/TLS certificate information
    
    -- Transaction tracking
    last_transaction_at TIMESTAMPTZ, -- Last transaction time
    total_transactions INTEGER DEFAULT 0, -- Total number of transactions
    total_amount_transferred DECIMAL(15,4) DEFAULT 0, -- Total amount transferred
    
    -- Error handling and monitoring
    last_error_at TIMESTAMPTZ, -- Last error occurrence
    error_count INTEGER DEFAULT 0, -- Number of errors
    error_details JSONB, -- Error details and logs
    
    -- Maintenance and updates
    maintenance_mode BOOLEAN DEFAULT FALSE,
    maintenance_message TEXT,
    maintenance_start_at TIMESTAMPTZ,
    maintenance_end_at TIMESTAMPTZ,
    
    -- Integration status
    integration_status VARCHAR(50) DEFAULT 'pending' CHECK (integration_status IN (
        'pending', 'active', 'inactive', 'error', 'maintenance'
    )),
    last_sync_at TIMESTAMPTZ, -- Last sync with bank systems
    sync_errors JSONB, -- Sync error details
    
    -- Notification settings
    notification_email VARCHAR(255), -- Email for bank notifications
    notification_phone VARCHAR(50), -- Phone for bank notifications
    notification_preferences JSONB, -- Notification preferences
    
    -- Additional metadata
    metadata JSONB, -- Additional bank data
    tags TEXT[], -- Bank tags for categorization
    
    -- Audit fields
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID, -- User who created the record
    updated_by UUID -- User who last updated the record
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_payment_banks_store_id ON payment_banks(store_id);
CREATE INDEX IF NOT EXISTS idx_payment_banks_salla_bank_id ON payment_banks(salla_bank_id);
CREATE INDEX IF NOT EXISTS idx_payment_banks_bank_code ON payment_banks(bank_code);
CREATE INDEX IF NOT EXISTS idx_payment_banks_bank_name ON payment_banks(bank_name);
CREATE INDEX IF NOT EXISTS idx_payment_banks_bank_type ON payment_banks(bank_type);
CREATE INDEX IF NOT EXISTS idx_payment_banks_country_code ON payment_banks(country_code);
CREATE INDEX IF NOT EXISTS idx_payment_banks_currency_code ON payment_banks(currency_code);
CREATE INDEX IF NOT EXISTS idx_payment_banks_account_number ON payment_banks(account_number);
CREATE INDEX IF NOT EXISTS idx_payment_banks_iban ON payment_banks(iban);
CREATE INDEX IF NOT EXISTS idx_payment_banks_swift_code ON payment_banks(swift_code);
CREATE INDEX IF NOT EXISTS idx_payment_banks_is_active ON payment_banks(is_active);
CREATE INDEX IF NOT EXISTS idx_payment_banks_is_default ON payment_banks(is_default);
CREATE INDEX IF NOT EXISTS idx_payment_banks_is_verified ON payment_banks(is_verified);
CREATE INDEX IF NOT EXISTS idx_payment_banks_verification_status ON payment_banks(verification_status);
CREATE INDEX IF NOT EXISTS idx_payment_banks_integration_status ON payment_banks(integration_status);
CREATE INDEX IF NOT EXISTS idx_payment_banks_maintenance_mode ON payment_banks(maintenance_mode);
CREATE INDEX IF NOT EXISTS idx_payment_banks_created_at ON payment_banks(created_at);

-- GIN indexes for array columns
CREATE INDEX IF NOT EXISTS idx_payment_banks_supported_currencies_gin ON payment_banks USING GIN(supported_currencies);
CREATE INDEX IF NOT EXISTS idx_payment_banks_operating_days_gin ON payment_banks USING GIN(operating_days);
CREATE INDEX IF NOT EXISTS idx_payment_banks_security_protocols_gin ON payment_banks USING GIN(security_protocols);
CREATE INDEX IF NOT EXISTS idx_payment_banks_tags_gin ON payment_banks USING GIN(tags);

-- GIN indexes for JSONB columns
CREATE INDEX IF NOT EXISTS idx_payment_banks_address_gin ON payment_banks USING GIN(address);
CREATE INDEX IF NOT EXISTS idx_payment_banks_branch_address_gin ON payment_banks USING GIN(branch_address);
CREATE INDEX IF NOT EXISTS idx_payment_banks_fee_structure_gin ON payment_banks USING GIN(fee_structure);
CREATE INDEX IF NOT EXISTS idx_payment_banks_operating_hours_gin ON payment_banks USING GIN(operating_hours);
CREATE INDEX IF NOT EXISTS idx_payment_banks_holiday_schedule_gin ON payment_banks USING GIN(holiday_schedule);
CREATE INDEX IF NOT EXISTS idx_payment_banks_regulatory_info_gin ON payment_banks USING GIN(regulatory_info);
CREATE INDEX IF NOT EXISTS idx_payment_banks_api_credentials_gin ON payment_banks USING GIN(api_credentials);
CREATE INDEX IF NOT EXISTS idx_payment_banks_certificate_info_gin ON payment_banks USING GIN(certificate_info);
CREATE INDEX IF NOT EXISTS idx_payment_banks_error_details_gin ON payment_banks USING GIN(error_details);
CREATE INDEX IF NOT EXISTS idx_payment_banks_notification_preferences_gin ON payment_banks USING GIN(notification_preferences);
CREATE INDEX IF NOT EXISTS idx_payment_banks_metadata_gin ON payment_banks USING GIN(metadata);

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_payment_banks_store_active ON payment_banks(store_id, is_active);
CREATE INDEX IF NOT EXISTS idx_payment_banks_store_verified ON payment_banks(store_id, is_verified);
CREATE INDEX IF NOT EXISTS idx_payment_banks_country_currency ON payment_banks(country_code, currency_code);
CREATE INDEX IF NOT EXISTS idx_payment_banks_active_verified ON payment_banks(is_active, is_verified);

-- Unique constraint for store and bank code
CREATE UNIQUE INDEX IF NOT EXISTS idx_payment_banks_store_bank_code ON payment_banks(store_id, bank_code);

-- Create trigger to automatically update updated_at
CREATE OR REPLACE FUNCTION update_payment_banks_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_payment_banks_updated_at
    BEFORE UPDATE ON payment_banks
    FOR EACH ROW
    EXECUTE FUNCTION update_payment_banks_updated_at();

-- Create trigger to ensure only one default bank per store
CREATE OR REPLACE FUNCTION ensure_single_default_bank()
RETURNS TRIGGER AS $$
BEGIN
    -- If setting this bank as default, unset others
    IF NEW.is_default = TRUE THEN
        UPDATE payment_banks 
        SET is_default = FALSE 
        WHERE store_id = NEW.store_id 
        AND id != NEW.id 
        AND is_default = TRUE;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_ensure_single_default_bank
    BEFORE INSERT OR UPDATE ON payment_banks
    FOR EACH ROW
    EXECUTE FUNCTION ensure_single_default_bank();

-- Create trigger to update transaction statistics
CREATE OR REPLACE FUNCTION update_bank_transaction_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- This would be called when a bank transfer is completed
    UPDATE payment_banks 
    SET 
        total_transactions = total_transactions + 1,
        total_amount_transferred = total_amount_transferred + NEW.amount,
        last_transaction_at = NOW()
    WHERE id = NEW.bank_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Helper function to get active banks for a store
CREATE OR REPLACE FUNCTION get_active_banks(
    p_store_id UUID,
    p_currency_code VARCHAR(3) DEFAULT NULL,
    p_country_code VARCHAR(2) DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    bank_code VARCHAR(50),
    bank_name VARCHAR(255),
    bank_type VARCHAR(50),
    account_number VARCHAR(100),
    iban VARCHAR(34),
    swift_code VARCHAR(11),
    is_verified BOOLEAN,
    transfer_fee_amount DECIMAL(15,4)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pb.id,
        pb.bank_code,
        pb.bank_name,
        pb.bank_type,
        pb.account_number,
        pb.iban,
        pb.swift_code,
        pb.is_verified,
        pb.transfer_fee_amount
    FROM payment_banks pb
    WHERE pb.store_id = p_store_id
        AND pb.is_active = TRUE
        AND pb.integration_status = 'active'
        AND pb.maintenance_mode = FALSE
        AND (p_currency_code IS NULL OR pb.currency_code = p_currency_code OR p_currency_code = ANY(pb.supported_currencies))
        AND (p_country_code IS NULL OR pb.country_code = p_country_code)
    ORDER BY pb.is_default DESC, pb.is_verified DESC, pb.bank_name ASC;
END;
$$ LANGUAGE plpgsql;

-- Helper function to calculate bank transfer fee
CREATE OR REPLACE FUNCTION calculate_bank_transfer_fee(
    p_bank_id UUID,
    p_transfer_amount DECIMAL(15,4)
)
RETURNS DECIMAL(15,4) AS $$
DECLARE
    bank_record payment_banks%ROWTYPE;
    calculated_fee DECIMAL(15,4) := 0;
BEGIN
    -- Get bank details
    SELECT * INTO bank_record
    FROM payment_banks
    WHERE id = p_bank_id;
    
    IF NOT FOUND THEN
        RETURN 0;
    END IF;
    
    -- Calculate fee based on type
    CASE bank_record.transfer_fee_type
        WHEN 'fixed' THEN
            calculated_fee = COALESCE(bank_record.transfer_fee_amount, 0);
        WHEN 'percentage' THEN
            calculated_fee = p_transfer_amount * COALESCE(bank_record.transfer_fee_percentage, 0) / 100;
        WHEN 'tiered' THEN
            -- Complex tiered calculation would go here
            -- For now, use fixed + percentage
            calculated_fee = COALESCE(bank_record.transfer_fee_amount, 0) + 
                           (p_transfer_amount * COALESCE(bank_record.transfer_fee_percentage, 0) / 100);
        ELSE
            calculated_fee = 0;
    END CASE;
    
    RETURN calculated_fee;
END;
$$ LANGUAGE plpgsql;

-- Helper function to validate bank transfer
CREATE OR REPLACE FUNCTION validate_bank_transfer(
    p_bank_id UUID,
    p_transfer_amount DECIMAL(15,4),
    p_currency_code VARCHAR(3)
)
RETURNS TABLE (
    is_valid BOOLEAN,
    error_message TEXT
) AS $$
DECLARE
    bank_record payment_banks%ROWTYPE;
BEGIN
    -- Get bank details
    SELECT * INTO bank_record
    FROM payment_banks
    WHERE id = p_bank_id;
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Bank not found';
        RETURN;
    END IF;
    
    -- Check if bank is active
    IF NOT bank_record.is_active THEN
        RETURN QUERY SELECT FALSE, 'Bank is not active';
        RETURN;
    END IF;
    
    -- Check if bank is verified
    IF NOT bank_record.is_verified THEN
        RETURN QUERY SELECT FALSE, 'Bank account is not verified';
        RETURN;
    END IF;
    
    -- Check integration status
    IF bank_record.integration_status != 'active' THEN
        RETURN QUERY SELECT FALSE, 'Bank integration is not active';
        RETURN;
    END IF;
    
    -- Check maintenance mode
    IF bank_record.maintenance_mode THEN
        RETURN QUERY SELECT FALSE, COALESCE(bank_record.maintenance_message, 'Bank is under maintenance');
        RETURN;
    END IF;
    
    -- Check amount limits
    IF bank_record.min_transfer_amount IS NOT NULL AND p_transfer_amount < bank_record.min_transfer_amount THEN
        RETURN QUERY SELECT FALSE, 'Transfer amount is below minimum limit';
        RETURN;
    END IF;
    
    IF bank_record.max_transfer_amount IS NOT NULL AND p_transfer_amount > bank_record.max_transfer_amount THEN
        RETURN QUERY SELECT FALSE, 'Transfer amount exceeds maximum limit';
        RETURN;
    END IF;
    
    -- Check currency support
    IF bank_record.currency_code != p_currency_code AND 
       (bank_record.supported_currencies IS NULL OR NOT (p_currency_code = ANY(bank_record.supported_currencies))) THEN
        RETURN QUERY SELECT FALSE, 'Currency not supported by this bank';
        RETURN;
    END IF;
    
    -- All validations passed
    RETURN QUERY SELECT TRUE, 'Bank transfer is valid';
END;
$$ LANGUAGE plpgsql;

-- Helper function to get bank statistics
CREATE OR REPLACE FUNCTION get_bank_statistics(
    p_store_id UUID,
    p_start_date TIMESTAMPTZ DEFAULT NULL,
    p_end_date TIMESTAMPTZ DEFAULT NULL
)
RETURNS TABLE (
    bank_id UUID,
    bank_name VARCHAR(255),
    total_transactions BIGINT,
    total_amount DECIMAL(15,4),
    average_amount DECIMAL(15,4),
    last_transaction_date TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pb.id as bank_id,
        pb.bank_name,
        pb.total_transactions::BIGINT,
        pb.total_amount_transferred,
        CASE 
            WHEN pb.total_transactions > 0 THEN pb.total_amount_transferred / pb.total_transactions
            ELSE 0
        END as average_amount,
        pb.last_transaction_at
    FROM payment_banks pb
    WHERE pb.store_id = p_store_id
        AND pb.is_active = TRUE
        AND (p_start_date IS NULL OR pb.last_transaction_at >= p_start_date)
        AND (p_end_date IS NULL OR pb.last_transaction_at <= p_end_date)
    ORDER BY pb.total_amount_transferred DESC;
END;
$$ LANGUAGE plpgsql;

-- Add comments for documentation
COMMENT ON TABLE payment_banks IS 'Stores bank information for payment processing and transfers';
COMMENT ON COLUMN payment_banks.salla_bank_id IS 'Unique identifier from Salla API';
COMMENT ON COLUMN payment_banks.bank_code IS 'Bank code (SWIFT/BIC or local bank code)';
COMMENT ON COLUMN payment_banks.bank_type IS 'Type of bank: commercial, islamic, investment, etc.';
COMMENT ON COLUMN payment_banks.iban IS 'International Bank Account Number';
COMMENT ON COLUMN payment_banks.swift_code IS 'SWIFT/BIC code for international transfers';
COMMENT ON COLUMN payment_banks.verification_status IS 'Bank account verification status';
COMMENT ON COLUMN payment_banks.fee_structure IS 'Complex fee structure in JSON format';
COMMENT ON COLUMN payment_banks.operating_hours IS 'Bank operating hours in JSON format';
COMMENT ON COLUMN payment_banks.supported_currencies IS 'Array of supported currency codes';
COMMENT ON COLUMN payment_banks.integration_status IS 'Current integration status with bank systems';
COMMENT ON COLUMN payment_banks.metadata IS 'Additional bank data in JSON format';
COMMENT ON COLUMN payment_banks.tags IS 'Array of tags for bank categorization';