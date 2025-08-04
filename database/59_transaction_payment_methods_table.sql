-- =============================================================================
-- Transaction Payment Methods Table
-- =============================================================================
-- This table normalizes the payment_method_details JSONB column from transactions

CREATE TABLE IF NOT EXISTS transaction_payment_methods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id UUID NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Payment method identification
    method_type VARCHAR(50) NOT NULL CHECK (method_type IN (
        'credit_card', 'debit_card', 'bank_transfer', 'digital_wallet', 
        'cash_on_delivery', 'installments', 'buy_now_pay_later', 'cryptocurrency'
    )),
    method_name VARCHAR(100) NOT NULL,
    method_code VARCHAR(50),
    
    -- Card details (for card payments)
    card_brand VARCHAR(50), -- visa, mastercard, mada, etc.
    card_type VARCHAR(30), -- credit, debit, prepaid
    card_last_four VARCHAR(4),
    card_expiry_month INTEGER CHECK (card_expiry_month >= 1 AND card_expiry_month <= 12),
    card_expiry_year INTEGER CHECK (card_expiry_year >= 2020),
    card_holder_name VARCHAR(255),
    card_country VARCHAR(3), -- ISO country code
    card_issuer VARCHAR(100),
    
    -- Bank transfer details
    bank_name VARCHAR(255),
    bank_code VARCHAR(50),
    account_type VARCHAR(30), -- checking, savings, business
    account_last_four VARCHAR(4),
    routing_number VARCHAR(50),
    swift_code VARCHAR(11),
    
    -- Digital wallet details
    wallet_provider VARCHAR(100), -- apple_pay, google_pay, samsung_pay, stc_pay
    wallet_account_id VARCHAR(255),
    wallet_phone VARCHAR(50),
    wallet_email VARCHAR(255),
    
    -- Installment details
    installment_provider VARCHAR(100), -- tabby, tamara, postpay
    installment_plan VARCHAR(50), -- 3_months, 6_months, 12_months
    installment_count INTEGER CHECK (installment_count > 0),
    installment_amount DECIMAL(10,2) CHECK (installment_amount >= 0),
    first_payment_amount DECIMAL(10,2) CHECK (first_payment_amount >= 0),
    
    -- Authentication and security
    authentication_method VARCHAR(50), -- 3ds, pin, biometric, otp
    authentication_status VARCHAR(30) DEFAULT 'pending' CHECK (authentication_status IN (
        'pending', 'authenticated', 'failed', 'bypassed', 'not_required'
    )),
    risk_assessment VARCHAR(30) DEFAULT 'low' CHECK (risk_assessment IN (
        'low', 'medium', 'high', 'blocked'
    )),
    
    -- Processing details
    processor_name VARCHAR(100), -- payment processor
    processor_transaction_id VARCHAR(255),
    processor_reference VARCHAR(255),
    processing_fee DECIMAL(10,2) DEFAULT 0.00 CHECK (processing_fee >= 0),
    processing_currency VARCHAR(3) DEFAULT 'SAR',
    
    -- Verification status
    verification_status VARCHAR(30) DEFAULT 'pending' CHECK (verification_status IN (
        'pending', 'verified', 'failed', 'not_required'
    )),
    verification_method VARCHAR(50), -- cvv, avs, 3ds, otp
    verification_code VARCHAR(10),
    
    -- Geographic information
    billing_country VARCHAR(3), -- ISO country code
    billing_city VARCHAR(100),
    billing_postal_code VARCHAR(20),
    ip_address INET,
    ip_country VARCHAR(3),
    
    -- Device information
    device_type VARCHAR(30), -- mobile, desktop, tablet
    device_os VARCHAR(50),
    device_browser VARCHAR(50),
    device_fingerprint VARCHAR(255),
    
    -- Tokenization
    is_tokenized BOOLEAN DEFAULT FALSE,
    token_id VARCHAR(255),
    token_provider VARCHAR(100),
    token_expiry TIMESTAMPTZ,
    
    -- Recurring payment details
    is_recurring BOOLEAN DEFAULT FALSE,
    recurring_frequency VARCHAR(30), -- monthly, quarterly, yearly
    next_payment_date DATE,
    recurring_end_date DATE,
    
    -- Quality and compliance
    compliance_status VARCHAR(30) DEFAULT 'compliant' CHECK (compliance_status IN (
        'compliant', 'non_compliant', 'pending_review', 'exempt'
    )),
    pci_compliance BOOLEAN DEFAULT TRUE,
    fraud_score INTEGER CHECK (fraud_score >= 0 AND fraud_score <= 100),
    
    -- External references
    external_method_id VARCHAR(255),
    external_references JSONB DEFAULT '{}',
    
    -- Sync information
    sync_status VARCHAR(20) DEFAULT 'synced' CHECK (sync_status IN ('pending', 'syncing', 'synced', 'error')),
    last_sync_at TIMESTAMPTZ,
    sync_errors JSONB DEFAULT '[]',
    
    -- Custom fields
    custom_fields JSONB DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- Transaction Payment Method History Table
-- =============================================================================
-- Track changes to payment method details

CREATE TABLE IF NOT EXISTS transaction_payment_method_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    payment_method_id UUID NOT NULL REFERENCES transaction_payment_methods(id) ON DELETE CASCADE,
    transaction_id UUID NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Change tracking
    change_type VARCHAR(20) NOT NULL CHECK (change_type IN ('created', 'updated', 'deleted', 'verified', 'failed')),
    changed_fields JSONB DEFAULT '[]', -- Array of changed field names
    old_values JSONB DEFAULT '{}', -- Previous values
    new_values JSONB DEFAULT '{}', -- New values
    
    -- Change context
    change_reason VARCHAR(255),
    changed_by_user_id UUID,
    changed_by_system VARCHAR(100),
    change_source VARCHAR(50) DEFAULT 'manual' CHECK (change_source IN (
        'manual', 'api', 'webhook', 'sync', 'automation', 'migration'
    )),
    
    -- Additional context
    context_data JSONB DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- Transaction Gateway Responses Table
-- =============================================================================
-- Normalize gateway_response JSONB column

CREATE TABLE IF NOT EXISTS transaction_gateway_responses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id UUID NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Gateway identification
    gateway_name VARCHAR(100) NOT NULL,
    gateway_version VARCHAR(20),
    gateway_environment VARCHAR(20) DEFAULT 'production' CHECK (gateway_environment IN (
        'sandbox', 'staging', 'production'
    )),
    
    -- Response details
    response_code VARCHAR(20),
    response_message TEXT,
    response_status VARCHAR(30) CHECK (response_status IN (
        'success', 'failed', 'pending', 'cancelled', 'timeout', 'error'
    )),
    
    -- Transaction identifiers
    gateway_transaction_id VARCHAR(255),
    gateway_reference VARCHAR(255),
    authorization_code VARCHAR(50),
    approval_code VARCHAR(50),
    
    -- Processing details
    processing_time_ms INTEGER CHECK (processing_time_ms >= 0),
    retry_count INTEGER DEFAULT 0 CHECK (retry_count >= 0),
    is_retry BOOLEAN DEFAULT FALSE,
    original_response_id UUID REFERENCES transaction_gateway_responses(id),
    
    -- Financial details
    processed_amount DECIMAL(10,2) CHECK (processed_amount >= 0),
    processed_currency VARCHAR(3),
    exchange_rate DECIMAL(10,6),
    gateway_fee DECIMAL(10,2) DEFAULT 0.00 CHECK (gateway_fee >= 0),
    
    -- Error details
    error_code VARCHAR(50),
    error_message TEXT,
    error_category VARCHAR(50), -- network, authentication, validation, processing
    is_retryable BOOLEAN DEFAULT FALSE,
    
    -- Security and fraud
    fraud_score INTEGER CHECK (fraud_score >= 0 AND fraud_score <= 100),
    fraud_indicators JSONB DEFAULT '[]',
    security_checks JSONB DEFAULT '{}',
    
    -- Raw response data
    raw_request JSONB,
    raw_response JSONB,
    headers JSONB DEFAULT '{}',
    
    -- Webhook information
    webhook_received BOOLEAN DEFAULT FALSE,
    webhook_verified BOOLEAN DEFAULT FALSE,
    webhook_data JSONB,
    
    -- External references
    external_response_id VARCHAR(255),
    external_references JSONB DEFAULT '{}',
    
    -- Timestamps
    response_timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- Transaction Risk Details Table
-- =============================================================================
-- Normalize risk_details JSONB column

CREATE TABLE IF NOT EXISTS transaction_risk_details (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id UUID NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Risk assessment
    overall_risk_score INTEGER NOT NULL CHECK (overall_risk_score >= 0 AND overall_risk_score <= 100),
    risk_level VARCHAR(20) NOT NULL CHECK (risk_level IN ('low', 'medium', 'high', 'critical')),
    risk_category VARCHAR(50), -- fraud, chargeback, identity, velocity
    
    -- Risk factors
    velocity_score INTEGER CHECK (velocity_score >= 0 AND velocity_score <= 100),
    device_score INTEGER CHECK (device_score >= 0 AND device_score <= 100),
    location_score INTEGER CHECK (location_score >= 0 AND location_score <= 100),
    behavior_score INTEGER CHECK (behavior_score >= 0 AND behavior_score <= 100),
    identity_score INTEGER CHECK (identity_score >= 0 AND identity_score <= 100),
    
    -- Fraud indicators
    is_suspicious_device BOOLEAN DEFAULT FALSE,
    is_suspicious_location BOOLEAN DEFAULT FALSE,
    is_suspicious_velocity BOOLEAN DEFAULT FALSE,
    is_blacklisted BOOLEAN DEFAULT FALSE,
    is_high_risk_country BOOLEAN DEFAULT FALSE,
    
    -- Device analysis
    device_fingerprint VARCHAR(255),
    device_reputation VARCHAR(20) CHECK (device_reputation IN ('good', 'neutral', 'bad', 'unknown')),
    is_known_device BOOLEAN DEFAULT FALSE,
    device_age_days INTEGER,
    
    -- Location analysis
    ip_address INET,
    ip_country VARCHAR(3),
    ip_region VARCHAR(100),
    ip_city VARCHAR(100),
    is_vpn BOOLEAN DEFAULT FALSE,
    is_proxy BOOLEAN DEFAULT FALSE,
    is_tor BOOLEAN DEFAULT FALSE,
    distance_from_billing_km INTEGER,
    
    -- Velocity analysis
    transactions_last_hour INTEGER DEFAULT 0,
    transactions_last_day INTEGER DEFAULT 0,
    amount_last_hour DECIMAL(10,2) DEFAULT 0.00,
    amount_last_day DECIMAL(10,2) DEFAULT 0.00,
    unique_cards_last_day INTEGER DEFAULT 0,
    
    -- Identity verification
    email_verification_status VARCHAR(20) CHECK (email_verification_status IN (
        'verified', 'unverified', 'suspicious', 'disposable'
    )),
    phone_verification_status VARCHAR(20) CHECK (phone_verification_status IN (
        'verified', 'unverified', 'suspicious', 'invalid'
    )),
    address_verification_status VARCHAR(20) CHECK (address_verification_status IN (
        'verified', 'unverified', 'partial', 'failed'
    )),
    
    -- Machine learning scores
    ml_fraud_score DECIMAL(5,4) CHECK (ml_fraud_score >= 0 AND ml_fraud_score <= 1),
    ml_model_version VARCHAR(20),
    ml_features JSONB DEFAULT '{}',
    
    -- Decision and actions
    recommended_action VARCHAR(30) CHECK (recommended_action IN (
        'approve', 'review', 'decline', 'challenge', 'monitor'
    )),
    action_taken VARCHAR(30) CHECK (action_taken IN (
        'approved', 'reviewed', 'declined', 'challenged', 'monitored'
    )),
    action_reason TEXT,
    
    -- Review information
    requires_manual_review BOOLEAN DEFAULT FALSE,
    reviewed_by_user_id UUID,
    reviewed_at TIMESTAMPTZ,
    review_notes TEXT,
    
    -- External risk services
    external_risk_provider VARCHAR(100),
    external_risk_score INTEGER,
    external_risk_data JSONB DEFAULT '{}',
    
    -- Timestamps
    assessed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- Indexes
-- =============================================================================

-- Transaction Payment Methods indexes
CREATE INDEX IF NOT EXISTS idx_transaction_payment_methods_transaction_id ON transaction_payment_methods(transaction_id);
CREATE INDEX IF NOT EXISTS idx_transaction_payment_methods_store_id ON transaction_payment_methods(store_id);
CREATE INDEX IF NOT EXISTS idx_transaction_payment_methods_method_type ON transaction_payment_methods(method_type);
CREATE INDEX IF NOT EXISTS idx_transaction_payment_methods_method_name ON transaction_payment_methods(method_name);
CREATE INDEX IF NOT EXISTS idx_transaction_payment_methods_card_brand ON transaction_payment_methods(card_brand);
CREATE INDEX IF NOT EXISTS idx_transaction_payment_methods_card_last_four ON transaction_payment_methods(card_last_four);
CREATE INDEX IF NOT EXISTS idx_transaction_payment_methods_bank_name ON transaction_payment_methods(bank_name);
CREATE INDEX IF NOT EXISTS idx_transaction_payment_methods_wallet_provider ON transaction_payment_methods(wallet_provider);
CREATE INDEX IF NOT EXISTS idx_transaction_payment_methods_installment_provider ON transaction_payment_methods(installment_provider);
CREATE INDEX IF NOT EXISTS idx_transaction_payment_methods_authentication_status ON transaction_payment_methods(authentication_status);
CREATE INDEX IF NOT EXISTS idx_transaction_payment_methods_verification_status ON transaction_payment_methods(verification_status);
CREATE INDEX IF NOT EXISTS idx_transaction_payment_methods_is_tokenized ON transaction_payment_methods(is_tokenized) WHERE is_tokenized = TRUE;
CREATE INDEX IF NOT EXISTS idx_transaction_payment_methods_is_recurring ON transaction_payment_methods(is_recurring) WHERE is_recurring = TRUE;
CREATE INDEX IF NOT EXISTS idx_transaction_payment_methods_compliance_status ON transaction_payment_methods(compliance_status);
CREATE INDEX IF NOT EXISTS idx_transaction_payment_methods_sync_status ON transaction_payment_methods(sync_status);
CREATE INDEX IF NOT EXISTS idx_transaction_payment_methods_created_at ON transaction_payment_methods(created_at DESC);

-- JSONB indexes
CREATE INDEX IF NOT EXISTS idx_transaction_payment_methods_external_references ON transaction_payment_methods USING gin(external_references);
CREATE INDEX IF NOT EXISTS idx_transaction_payment_methods_custom_fields ON transaction_payment_methods USING gin(custom_fields);
CREATE INDEX IF NOT EXISTS idx_transaction_payment_methods_sync_errors ON transaction_payment_methods USING gin(sync_errors);

-- Payment Method History indexes
CREATE INDEX IF NOT EXISTS idx_transaction_payment_method_history_payment_method_id ON transaction_payment_method_history(payment_method_id);
CREATE INDEX IF NOT EXISTS idx_transaction_payment_method_history_transaction_id ON transaction_payment_method_history(transaction_id);
CREATE INDEX IF NOT EXISTS idx_transaction_payment_method_history_store_id ON transaction_payment_method_history(store_id);
CREATE INDEX IF NOT EXISTS idx_transaction_payment_method_history_change_type ON transaction_payment_method_history(change_type);
CREATE INDEX IF NOT EXISTS idx_transaction_payment_method_history_change_source ON transaction_payment_method_history(change_source);
CREATE INDEX IF NOT EXISTS idx_transaction_payment_method_history_created_at ON transaction_payment_method_history(created_at DESC);

-- Gateway Responses indexes
CREATE INDEX IF NOT EXISTS idx_transaction_gateway_responses_transaction_id ON transaction_gateway_responses(transaction_id);
CREATE INDEX IF NOT EXISTS idx_transaction_gateway_responses_store_id ON transaction_gateway_responses(store_id);
CREATE INDEX IF NOT EXISTS idx_transaction_gateway_responses_gateway_name ON transaction_gateway_responses(gateway_name);
CREATE INDEX IF NOT EXISTS idx_transaction_gateway_responses_response_status ON transaction_gateway_responses(response_status);
CREATE INDEX IF NOT EXISTS idx_transaction_gateway_responses_gateway_transaction_id ON transaction_gateway_responses(gateway_transaction_id);
CREATE INDEX IF NOT EXISTS idx_transaction_gateway_responses_response_code ON transaction_gateway_responses(response_code);
CREATE INDEX IF NOT EXISTS idx_transaction_gateway_responses_error_code ON transaction_gateway_responses(error_code);
CREATE INDEX IF NOT EXISTS idx_transaction_gateway_responses_is_retry ON transaction_gateway_responses(is_retry) WHERE is_retry = TRUE;
CREATE INDEX IF NOT EXISTS idx_transaction_gateway_responses_webhook_received ON transaction_gateway_responses(webhook_received) WHERE webhook_received = TRUE;
CREATE INDEX IF NOT EXISTS idx_transaction_gateway_responses_response_timestamp ON transaction_gateway_responses(response_timestamp DESC);

-- Risk Details indexes
CREATE INDEX IF NOT EXISTS idx_transaction_risk_details_transaction_id ON transaction_risk_details(transaction_id);
CREATE INDEX IF NOT EXISTS idx_transaction_risk_details_store_id ON transaction_risk_details(store_id);
CREATE INDEX IF NOT EXISTS idx_transaction_risk_details_overall_risk_score ON transaction_risk_details(overall_risk_score DESC);
CREATE INDEX IF NOT EXISTS idx_transaction_risk_details_risk_level ON transaction_risk_details(risk_level);
CREATE INDEX IF NOT EXISTS idx_transaction_risk_details_risk_category ON transaction_risk_details(risk_category);
CREATE INDEX IF NOT EXISTS idx_transaction_risk_details_is_suspicious_device ON transaction_risk_details(is_suspicious_device) WHERE is_suspicious_device = TRUE;
CREATE INDEX IF NOT EXISTS idx_transaction_risk_details_is_blacklisted ON transaction_risk_details(is_blacklisted) WHERE is_blacklisted = TRUE;
CREATE INDEX IF NOT EXISTS idx_transaction_risk_details_ip_country ON transaction_risk_details(ip_country);
CREATE INDEX IF NOT EXISTS idx_transaction_risk_details_recommended_action ON transaction_risk_details(recommended_action);
CREATE INDEX IF NOT EXISTS idx_transaction_risk_details_requires_manual_review ON transaction_risk_details(requires_manual_review) WHERE requires_manual_review = TRUE;
CREATE INDEX IF NOT EXISTS idx_transaction_risk_details_assessed_at ON transaction_risk_details(assessed_at DESC);

-- Composite indexes
CREATE INDEX IF NOT EXISTS idx_transaction_payment_methods_store_method ON transaction_payment_methods(store_id, method_type, method_name);
CREATE INDEX IF NOT EXISTS idx_transaction_payment_methods_card_details ON transaction_payment_methods(card_brand, card_type, card_last_four);
CREATE INDEX IF NOT EXISTS idx_transaction_gateway_responses_gateway_status ON transaction_gateway_responses(gateway_name, response_status, response_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_transaction_risk_details_risk_assessment ON transaction_risk_details(risk_level, overall_risk_score DESC, assessed_at DESC);

-- =============================================================================
-- Triggers
-- =============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_transaction_payment_methods_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_transaction_payment_methods_updated_at
    BEFORE UPDATE ON transaction_payment_methods
    FOR EACH ROW
    EXECUTE FUNCTION update_transaction_payment_methods_updated_at();

CREATE TRIGGER trigger_update_transaction_gateway_responses_updated_at
    BEFORE UPDATE ON transaction_gateway_responses
    FOR EACH ROW
    EXECUTE FUNCTION update_transaction_payment_methods_updated_at();

CREATE TRIGGER trigger_update_transaction_risk_details_updated_at
    BEFORE UPDATE ON transaction_risk_details
    FOR EACH ROW
    EXECUTE FUNCTION update_transaction_payment_methods_updated_at();

-- Track payment method changes
CREATE OR REPLACE FUNCTION track_payment_method_changes()
RETURNS TRIGGER AS $$
DECLARE
    changed_fields TEXT[];
    old_values JSONB := '{}';
    new_values JSONB := '{}';
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO transaction_payment_method_history (
            payment_method_id, transaction_id, store_id, change_type,
            new_values, change_source
        ) VALUES (
            NEW.id, NEW.transaction_id, NEW.store_id, 'created',
            to_jsonb(NEW), 'system'
        );
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        -- Detect changed fields
        IF OLD.method_type IS DISTINCT FROM NEW.method_type THEN
            changed_fields := array_append(changed_fields, 'method_type');
            old_values := old_values || jsonb_build_object('method_type', OLD.method_type);
            new_values := new_values || jsonb_build_object('method_type', NEW.method_type);
        END IF;
        
        IF OLD.authentication_status IS DISTINCT FROM NEW.authentication_status THEN
            changed_fields := array_append(changed_fields, 'authentication_status');
            old_values := old_values || jsonb_build_object('authentication_status', OLD.authentication_status);
            new_values := new_values || jsonb_build_object('authentication_status', NEW.authentication_status);
        END IF;
        
        IF OLD.verification_status IS DISTINCT FROM NEW.verification_status THEN
            changed_fields := array_append(changed_fields, 'verification_status');
            old_values := old_values || jsonb_build_object('verification_status', OLD.verification_status);
            new_values := new_values || jsonb_build_object('verification_status', NEW.verification_status);
        END IF;
        
        -- Insert history record if there are changes
        IF array_length(changed_fields, 1) > 0 THEN
            INSERT INTO transaction_payment_method_history (
                payment_method_id, transaction_id, store_id, change_type,
                changed_fields, old_values, new_values, change_source
            ) VALUES (
                NEW.id, NEW.transaction_id, NEW.store_id, 'updated',
                to_jsonb(changed_fields), old_values, new_values, 'system'
            );
        END IF;
        
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO transaction_payment_method_history (
            payment_method_id, transaction_id, store_id, change_type,
            old_values, change_source
        ) VALUES (
            OLD.id, OLD.transaction_id, OLD.store_id, 'deleted',
            to_jsonb(OLD), 'system'
        );
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_track_payment_method_changes
    AFTER INSERT OR UPDATE OR DELETE ON transaction_payment_methods
    FOR EACH ROW
    EXECUTE FUNCTION track_payment_method_changes();

-- =============================================================================
-- Helper Functions
-- =============================================================================

/**
 * Get transaction payment method details
 * @param p_transaction_id UUID - Transaction ID
 * @return JSONB - Payment method details
 */
CREATE OR REPLACE FUNCTION get_transaction_payment_method(
    p_transaction_id UUID
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'method_id', tpm.id,
        'method_type', tpm.method_type,
        'method_name', tpm.method_name,
        'card_brand', tpm.card_brand,
        'card_last_four', tpm.card_last_four,
        'bank_name', tpm.bank_name,
        'wallet_provider', tpm.wallet_provider,
        'installment_provider', tpm.installment_provider,
        'authentication_status', tpm.authentication_status,
        'verification_status', tpm.verification_status,
        'is_tokenized', tpm.is_tokenized,
        'is_recurring', tpm.is_recurring,
        'compliance_status', tpm.compliance_status
    ) INTO result
    FROM transaction_payment_methods tpm
    WHERE tpm.transaction_id = p_transaction_id;
    
    RETURN COALESCE(result, '{"error": "Payment method not found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

/**
 * Get transaction gateway response details
 * @param p_transaction_id UUID - Transaction ID
 * @return JSONB - Gateway response details
 */
CREATE OR REPLACE FUNCTION get_transaction_gateway_response(
    p_transaction_id UUID
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'response_id', tgr.id,
        'gateway_name', tgr.gateway_name,
        'response_code', tgr.response_code,
        'response_message', tgr.response_message,
        'response_status', tgr.response_status,
        'gateway_transaction_id', tgr.gateway_transaction_id,
        'authorization_code', tgr.authorization_code,
        'processing_time_ms', tgr.processing_time_ms,
        'processed_amount', tgr.processed_amount,
        'gateway_fee', tgr.gateway_fee,
        'error_code', tgr.error_code,
        'error_message', tgr.error_message,
        'fraud_score', tgr.fraud_score,
        'response_timestamp', tgr.response_timestamp
    ) INTO result
    FROM transaction_gateway_responses tgr
    WHERE tgr.transaction_id = p_transaction_id
    ORDER BY tgr.response_timestamp DESC
    LIMIT 1;
    
    RETURN COALESCE(result, '{"error": "Gateway response not found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

/**
 * Get transaction risk assessment
 * @param p_transaction_id UUID - Transaction ID
 * @return JSONB - Risk assessment details
 */
CREATE OR REPLACE FUNCTION get_transaction_risk_assessment(
    p_transaction_id UUID
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'risk_id', trd.id,
        'overall_risk_score', trd.overall_risk_score,
        'risk_level', trd.risk_level,
        'risk_category', trd.risk_category,
        'velocity_score', trd.velocity_score,
        'device_score', trd.device_score,
        'location_score', trd.location_score,
        'behavior_score', trd.behavior_score,
        'identity_score', trd.identity_score,
        'fraud_indicators', jsonb_build_object(
            'suspicious_device', trd.is_suspicious_device,
            'suspicious_location', trd.is_suspicious_location,
            'suspicious_velocity', trd.is_suspicious_velocity,
            'blacklisted', trd.is_blacklisted,
            'high_risk_country', trd.is_high_risk_country
        ),
        'recommended_action', trd.recommended_action,
        'action_taken', trd.action_taken,
        'requires_manual_review', trd.requires_manual_review,
        'assessed_at', trd.assessed_at
    ) INTO result
    FROM transaction_risk_details trd
    WHERE trd.transaction_id = p_transaction_id;
    
    RETURN COALESCE(result, '{"error": "Risk assessment not found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

/**
 * Get payment method statistics for store
 * @param p_store_id UUID - Store ID
 * @return JSONB - Payment method statistics
 */
CREATE OR REPLACE FUNCTION get_payment_method_stats(
    p_store_id UUID
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_methods', COUNT(*),
        'method_type_breakdown', (
            SELECT jsonb_object_agg(method_type, type_count)
            FROM (
                SELECT method_type, COUNT(*) as type_count
                FROM transaction_payment_methods
                WHERE store_id = p_store_id
                GROUP BY method_type
            ) method_stats
        ),
        'card_brand_breakdown', (
            SELECT jsonb_object_agg(card_brand, brand_count)
            FROM (
                SELECT card_brand, COUNT(*) as brand_count
                FROM transaction_payment_methods
                WHERE store_id = p_store_id
                AND card_brand IS NOT NULL
                GROUP BY card_brand
            ) brand_stats
        ),
        'authentication_status_breakdown', (
            SELECT jsonb_object_agg(authentication_status, auth_count)
            FROM (
                SELECT authentication_status, COUNT(*) as auth_count
                FROM transaction_payment_methods
                WHERE store_id = p_store_id
                GROUP BY authentication_status
            ) auth_stats
        ),
        'tokenized_methods', COUNT(*) FILTER (WHERE is_tokenized = TRUE),
        'recurring_methods', COUNT(*) FILTER (WHERE is_recurring = TRUE),
        'compliance_status_breakdown', (
            SELECT jsonb_object_agg(compliance_status, compliance_count)
            FROM (
                SELECT compliance_status, COUNT(*) as compliance_count
                FROM transaction_payment_methods
                WHERE store_id = p_store_id
                GROUP BY compliance_status
            ) compliance_stats
        )
    ) INTO result
    FROM transaction_payment_methods
    WHERE store_id = p_store_id;
    
    RETURN COALESCE(result, '{"error": "No payment methods found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Comments
-- =============================================================================

COMMENT ON TABLE transaction_payment_methods IS 'Normalized payment method details from transactions';
COMMENT ON TABLE transaction_payment_method_history IS 'Track changes to payment method details';
COMMENT ON TABLE transaction_gateway_responses IS 'Normalized gateway response details from transactions';
COMMENT ON TABLE transaction_risk_details IS 'Normalized risk assessment details from transactions';

COMMENT ON COLUMN transaction_payment_methods.method_type IS 'Type of payment method used';
COMMENT ON COLUMN transaction_payment_methods.authentication_status IS 'Status of payment authentication';
COMMENT ON COLUMN transaction_payment_methods.is_tokenized IS 'Whether payment method is tokenized for future use';
COMMENT ON COLUMN transaction_gateway_responses.processing_time_ms IS 'Gateway processing time in milliseconds';
COMMENT ON COLUMN transaction_risk_details.overall_risk_score IS 'Overall risk score (0-100)';

COMMENT ON FUNCTION get_transaction_payment_method(UUID) IS 'Get payment method details for transaction';
COMMENT ON FUNCTION get_transaction_gateway_response(UUID) IS 'Get gateway response details for transaction';
COMMENT ON FUNCTION get_transaction_risk_assessment(UUID) IS 'Get risk assessment details for transaction';
COMMENT ON FUNCTION get_payment_method_stats(UUID) IS 'Get payment method statistics for store';