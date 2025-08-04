-- =============================================================================
-- Transactions Table
-- =============================================================================
-- This table stores all financial transactions for stores
-- Includes payments, refunds, and other financial operations
-- Links to Salla API for transaction synchronization

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create transactions table
CREATE TABLE IF NOT EXISTS transactions (
    -- Primary identification
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Salla API identifiers
    salla_transaction_id VARCHAR(255) UNIQUE, -- Salla transaction ID
    salla_order_id VARCHAR(255), -- Related Salla order ID
    salla_payment_id VARCHAR(255), -- Salla payment ID
    
    -- Store relationship (required)
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Order relationship (optional - some transactions may not be order-related)
    order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
    
    -- Transaction identification
    transaction_number VARCHAR(100) NOT NULL, -- Human-readable transaction number
    reference_number VARCHAR(255), -- External reference number
    
    -- Transaction details
    transaction_type VARCHAR(50) NOT NULL CHECK (transaction_type IN (
        'payment', 'refund', 'partial_refund', 'chargeback', 
        'fee', 'commission', 'adjustment', 'transfer', 'withdrawal'
    )),
    
    transaction_status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (transaction_status IN (
        'pending', 'processing', 'completed', 'failed', 
        'cancelled', 'refunded', 'disputed', 'on_hold'
    )),
    
    -- Financial amounts (in store currency)
    amount DECIMAL(15,4) NOT NULL, -- Transaction amount
    currency_code VARCHAR(3) NOT NULL DEFAULT 'SAR',
    
    -- Fee and commission details
    gateway_fee DECIMAL(15,4) DEFAULT 0, -- Payment gateway fee
    platform_fee DECIMAL(15,4) DEFAULT 0, -- Platform commission
    tax_amount DECIMAL(15,4) DEFAULT 0, -- Tax amount
    net_amount DECIMAL(15,4), -- Amount after fees
    
    -- Payment method information
    payment_method VARCHAR(100), -- Payment method used
    payment_gateway VARCHAR(100), -- Payment gateway (mada, visa, mastercard, etc.)
    payment_method_details JSONB, -- Additional payment method details
    
    -- Transaction timing
    transaction_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    processed_at TIMESTAMPTZ, -- When transaction was processed
    settled_at TIMESTAMPTZ, -- When funds were settled
    
    -- Customer information
    customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
    customer_name VARCHAR(255),
    customer_email VARCHAR(255),
    customer_phone VARCHAR(50),
    
    -- Transaction description and notes
    description TEXT,
    internal_notes TEXT, -- Internal notes for staff
    
    -- Gateway response details
    gateway_transaction_id VARCHAR(255), -- Gateway's transaction ID
    gateway_response JSONB, -- Full gateway response
    gateway_status VARCHAR(100), -- Gateway status
    
    -- Refund information (for refund transactions)
    original_transaction_id UUID REFERENCES transactions(id),
    refund_reason VARCHAR(500),
    refund_type VARCHAR(50) CHECK (refund_type IN ('full', 'partial', 'chargeback')),
    
    -- Risk and fraud detection
    risk_score INTEGER CHECK (risk_score >= 0 AND risk_score <= 100),
    fraud_status VARCHAR(50) CHECK (fraud_status IN ('clean', 'review', 'reject')),
    risk_details JSONB,
    
    -- Reconciliation
    reconciled BOOLEAN DEFAULT FALSE,
    reconciled_at TIMESTAMPTZ,
    reconciliation_reference VARCHAR(255),
    
    -- Notification status
    customer_notified BOOLEAN DEFAULT FALSE,
    notification_sent_at TIMESTAMPTZ,
    
    -- Additional metadata
    metadata JSONB, -- Additional transaction data
    tags TEXT[], -- Transaction tags for categorization
    
    -- Audit fields
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID, -- User who created the record
    updated_by UUID -- User who last updated the record
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_transactions_store_id ON transactions(store_id);
CREATE INDEX IF NOT EXISTS idx_transactions_order_id ON transactions(order_id);
CREATE INDEX IF NOT EXISTS idx_transactions_customer_id ON transactions(customer_id);
CREATE INDEX IF NOT EXISTS idx_transactions_salla_transaction_id ON transactions(salla_transaction_id);
CREATE INDEX IF NOT EXISTS idx_transactions_salla_order_id ON transactions(salla_order_id);
CREATE INDEX IF NOT EXISTS idx_transactions_transaction_number ON transactions(transaction_number);
CREATE INDEX IF NOT EXISTS idx_transactions_reference_number ON transactions(reference_number);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON transactions(transaction_status);
CREATE INDEX IF NOT EXISTS idx_transactions_payment_method ON transactions(payment_method);
CREATE INDEX IF NOT EXISTS idx_transactions_payment_gateway ON transactions(payment_gateway);
CREATE INDEX IF NOT EXISTS idx_transactions_gateway_transaction_id ON transactions(gateway_transaction_id);
CREATE INDEX IF NOT EXISTS idx_transactions_transaction_date ON transactions(transaction_date);
CREATE INDEX IF NOT EXISTS idx_transactions_processed_at ON transactions(processed_at);
CREATE INDEX IF NOT EXISTS idx_transactions_settled_at ON transactions(settled_at);
CREATE INDEX IF NOT EXISTS idx_transactions_reconciled ON transactions(reconciled);
CREATE INDEX IF NOT EXISTS idx_transactions_original_transaction_id ON transactions(original_transaction_id);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON transactions(created_at);

-- GIN indexes for JSONB columns
CREATE INDEX IF NOT EXISTS idx_transactions_payment_method_details_gin ON transactions USING GIN(payment_method_details);
CREATE INDEX IF NOT EXISTS idx_transactions_gateway_response_gin ON transactions USING GIN(gateway_response);
CREATE INDEX IF NOT EXISTS idx_transactions_risk_details_gin ON transactions USING GIN(risk_details);
CREATE INDEX IF NOT EXISTS idx_transactions_metadata_gin ON transactions USING GIN(metadata);

-- GIN index for tags array
CREATE INDEX IF NOT EXISTS idx_transactions_tags_gin ON transactions USING GIN(tags);

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_transactions_store_status ON transactions(store_id, transaction_status);
CREATE INDEX IF NOT EXISTS idx_transactions_store_type ON transactions(store_id, transaction_type);
CREATE INDEX IF NOT EXISTS idx_transactions_store_date ON transactions(store_id, transaction_date);
CREATE INDEX IF NOT EXISTS idx_transactions_customer_date ON transactions(customer_id, transaction_date);
CREATE INDEX IF NOT EXISTS idx_transactions_order_type ON transactions(order_id, transaction_type);

-- Create trigger to automatically update updated_at
CREATE OR REPLACE FUNCTION update_transactions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_transactions_updated_at
    BEFORE UPDATE ON transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_transactions_updated_at();

-- Create trigger to automatically calculate net amount
CREATE OR REPLACE FUNCTION calculate_transaction_net_amount()
RETURNS TRIGGER AS $$
BEGIN
    -- Calculate net amount if not provided
    IF NEW.net_amount IS NULL THEN
        NEW.net_amount = NEW.amount - COALESCE(NEW.gateway_fee, 0) - COALESCE(NEW.platform_fee, 0) - COALESCE(NEW.tax_amount, 0);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_calculate_transaction_net_amount
    BEFORE INSERT OR UPDATE ON transactions
    FOR EACH ROW
    EXECUTE FUNCTION calculate_transaction_net_amount();

-- Create trigger to automatically update processed_at when status changes to completed
CREATE OR REPLACE FUNCTION update_transaction_processed_at()
RETURNS TRIGGER AS $$
BEGIN
    -- Set processed_at when status changes to completed
    IF NEW.transaction_status = 'completed' AND OLD.transaction_status != 'completed' THEN
        NEW.processed_at = NOW();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_transaction_processed_at
    BEFORE UPDATE ON transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_transaction_processed_at();

-- Helper function to get transaction summary for a store
CREATE OR REPLACE FUNCTION get_store_transaction_summary(
    p_store_id UUID,
    p_start_date TIMESTAMPTZ DEFAULT NULL,
    p_end_date TIMESTAMPTZ DEFAULT NULL
)
RETURNS TABLE (
    total_transactions BIGINT,
    total_amount DECIMAL(15,4),
    total_fees DECIMAL(15,4),
    total_net_amount DECIMAL(15,4),
    completed_transactions BIGINT,
    pending_transactions BIGINT,
    failed_transactions BIGINT,
    refunded_amount DECIMAL(15,4)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::BIGINT as total_transactions,
        COALESCE(SUM(t.amount), 0) as total_amount,
        COALESCE(SUM(t.gateway_fee + t.platform_fee + t.tax_amount), 0) as total_fees,
        COALESCE(SUM(t.net_amount), 0) as total_net_amount,
        COUNT(CASE WHEN t.transaction_status = 'completed' THEN 1 END)::BIGINT as completed_transactions,
        COUNT(CASE WHEN t.transaction_status = 'pending' THEN 1 END)::BIGINT as pending_transactions,
        COUNT(CASE WHEN t.transaction_status = 'failed' THEN 1 END)::BIGINT as failed_transactions,
        COALESCE(SUM(CASE WHEN t.transaction_type IN ('refund', 'partial_refund') THEN t.amount ELSE 0 END), 0) as refunded_amount
    FROM transactions t
    WHERE t.store_id = p_store_id
        AND (p_start_date IS NULL OR t.transaction_date >= p_start_date)
        AND (p_end_date IS NULL OR t.transaction_date <= p_end_date);
END;
$$ LANGUAGE plpgsql;

-- Helper function to get payment method statistics
CREATE OR REPLACE FUNCTION get_payment_method_stats(
    p_store_id UUID,
    p_start_date TIMESTAMPTZ DEFAULT NULL,
    p_end_date TIMESTAMPTZ DEFAULT NULL
)
RETURNS TABLE (
    payment_method VARCHAR(100),
    transaction_count BIGINT,
    total_amount DECIMAL(15,4),
    success_rate DECIMAL(5,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.payment_method,
        COUNT(*)::BIGINT as transaction_count,
        COALESCE(SUM(t.amount), 0) as total_amount,
        ROUND(
            (COUNT(CASE WHEN t.transaction_status = 'completed' THEN 1 END)::DECIMAL / COUNT(*)::DECIMAL) * 100, 
            2
        ) as success_rate
    FROM transactions t
    WHERE t.store_id = p_store_id
        AND t.payment_method IS NOT NULL
        AND (p_start_date IS NULL OR t.transaction_date >= p_start_date)
        AND (p_end_date IS NULL OR t.transaction_date <= p_end_date)
    GROUP BY t.payment_method
    ORDER BY total_amount DESC;
END;
$$ LANGUAGE plpgsql;

-- Helper function to get transactions requiring reconciliation
CREATE OR REPLACE FUNCTION get_unreconciled_transactions(
    p_store_id UUID DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    transaction_number VARCHAR(100),
    amount DECIMAL(15,4),
    transaction_date TIMESTAMPTZ,
    payment_method VARCHAR(100),
    gateway_transaction_id VARCHAR(255)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.id,
        t.transaction_number,
        t.amount,
        t.transaction_date,
        t.payment_method,
        t.gateway_transaction_id
    FROM transactions t
    WHERE t.reconciled = FALSE
        AND t.transaction_status = 'completed'
        AND (p_store_id IS NULL OR t.store_id = p_store_id)
    ORDER BY t.transaction_date DESC;
END;
$$ LANGUAGE plpgsql;

-- Add comments for documentation
COMMENT ON TABLE transactions IS 'Stores all financial transactions including payments, refunds, and other financial operations';
COMMENT ON COLUMN transactions.salla_transaction_id IS 'Unique identifier from Salla API';
COMMENT ON COLUMN transactions.transaction_type IS 'Type of transaction: payment, refund, etc.';
COMMENT ON COLUMN transactions.transaction_status IS 'Current status of the transaction';
COMMENT ON COLUMN transactions.amount IS 'Transaction amount in store currency';
COMMENT ON COLUMN transactions.net_amount IS 'Amount after deducting all fees';
COMMENT ON COLUMN transactions.payment_method IS 'Payment method used (card, bank_transfer, etc.)';
COMMENT ON COLUMN transactions.gateway_fee IS 'Fee charged by payment gateway';
COMMENT ON COLUMN transactions.platform_fee IS 'Platform commission fee';
COMMENT ON COLUMN transactions.risk_score IS 'Fraud risk score (0-100)';
COMMENT ON COLUMN transactions.reconciled IS 'Whether transaction has been reconciled with bank statements';
COMMENT ON COLUMN transactions.metadata IS 'Additional transaction data in JSON format';
COMMENT ON COLUMN transactions.tags IS 'Array of tags for transaction categorization';