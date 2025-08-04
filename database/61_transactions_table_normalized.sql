-- =============================================================================
-- Transactions Table (Normalized)
-- =============================================================================
-- This file normalizes the transactions table by removing JSONB columns
-- and replacing them with references to separate normalized tables

-- First, let's create a backup of the original transactions table
CREATE TABLE IF NOT EXISTS transactions_backup AS 
SELECT * FROM transactions WHERE 1=0; -- Create empty backup table with same structure

-- =============================================================================
-- Normalized Transactions Table
-- =============================================================================

CREATE TABLE IF NOT EXISTS transactions_normalized (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Basic transaction information
    transaction_number VARCHAR(100) NOT NULL,
    external_transaction_id VARCHAR(255),
    
    -- Order relationship
    order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
    
    -- Transaction type and status
    transaction_type VARCHAR(50) NOT NULL CHECK (transaction_type IN (
        'payment', 'refund', 'partial_refund', 'chargeback', 'authorization', 'capture', 'void'
    )),
    status VARCHAR(30) NOT NULL DEFAULT 'pending' CHECK (status IN (
        'pending', 'processing', 'completed', 'failed', 'cancelled', 'refunded', 'partially_refunded'
    )),
    
    -- Financial details
    amount DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
    currency VARCHAR(3) NOT NULL DEFAULT 'SAR',
    exchange_rate DECIMAL(10,6) DEFAULT 1.000000,
    amount_in_base_currency DECIMAL(10,2) GENERATED ALWAYS AS (amount * exchange_rate) STORED,
    
    -- Fee information
    fee_amount DECIMAL(10,2) DEFAULT 0.00 CHECK (fee_amount >= 0),
    tax_amount DECIMAL(10,2) DEFAULT 0.00 CHECK (tax_amount >= 0),
    net_amount DECIMAL(10,2) GENERATED ALWAYS AS (amount - fee_amount - tax_amount) STORED,
    
    -- Payment gateway information
    gateway_name VARCHAR(100) NOT NULL,
    gateway_transaction_id VARCHAR(255),
    gateway_reference VARCHAR(255),
    
    -- Processing information
    processed_at TIMESTAMPTZ,
    processing_time_ms INTEGER CHECK (processing_time_ms >= 0),
    
    -- Reference to normalized tables (replacing JSONB columns)
    payment_method_id UUID REFERENCES transaction_payment_methods(id) ON DELETE SET NULL,
    gateway_response_id UUID REFERENCES transaction_gateway_responses(id) ON DELETE SET NULL,
    risk_assessment_id UUID REFERENCES transaction_risk_details(id) ON DELETE SET NULL,
    
    -- Customer information
    customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
    customer_email VARCHAR(255),
    customer_phone VARCHAR(50),
    
    -- Reconciliation
    is_reconciled BOOLEAN DEFAULT FALSE,
    reconciled_at TIMESTAMPTZ,
    reconciliation_reference VARCHAR(255),
    
    -- Fraud and security
    is_flagged_for_review BOOLEAN DEFAULT FALSE,
    review_status VARCHAR(30) DEFAULT 'not_required' CHECK (review_status IN (
        'not_required', 'pending', 'in_review', 'approved', 'rejected'
    )),
    reviewed_by_user_id UUID,
    reviewed_at TIMESTAMPTZ,
    review_notes TEXT,
    
    -- Refund information
    refund_reason VARCHAR(255),
    refunded_amount DECIMAL(10,2) DEFAULT 0.00 CHECK (refunded_amount >= 0),
    remaining_refundable_amount DECIMAL(10,2) GENERATED ALWAYS AS (amount - refunded_amount) STORED,
    
    -- Parent transaction (for refunds, chargebacks)
    parent_transaction_id UUID REFERENCES transactions_normalized(id) ON DELETE SET NULL,
    
    -- External references
    external_references JSONB DEFAULT '{}',
    
    -- Sync information
    sync_status VARCHAR(20) DEFAULT 'synced' CHECK (sync_status IN ('pending', 'syncing', 'synced', 'error')),
    last_sync_at TIMESTAMPTZ,
    sync_errors JSONB DEFAULT '[]',
    
    -- Custom fields (minimal JSONB for truly custom data)
    custom_fields JSONB DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    UNIQUE(store_id, transaction_number),
    CHECK (refunded_amount <= amount),
    CHECK (processed_at IS NULL OR processed_at >= created_at)
);

-- =============================================================================
-- Transaction Relationships Table
-- =============================================================================
-- Track relationships between transactions and other entities

CREATE TABLE IF NOT EXISTS transaction_relationships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id UUID NOT NULL REFERENCES transactions_normalized(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Relationship details
    related_entity_type VARCHAR(50) NOT NULL CHECK (related_entity_type IN (
        'order', 'customer', 'product', 'coupon', 'shipping', 'tax', 'invoice', 'subscription'
    )),
    related_entity_id UUID NOT NULL,
    relationship_type VARCHAR(50) NOT NULL CHECK (relationship_type IN (
        'payment_for', 'refund_for', 'fee_for', 'tax_for', 'shipping_for', 'related_to'
    )),
    
    -- Relationship properties
    relationship_strength DECIMAL(3,2) DEFAULT 1.00 CHECK (relationship_strength >= 0 AND relationship_strength <= 1),
    is_primary_relationship BOOLEAN DEFAULT FALSE,
    relationship_notes TEXT,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    UNIQUE(transaction_id, related_entity_type, related_entity_id, relationship_type)
);

-- =============================================================================
-- Indexes
-- =============================================================================

-- Primary indexes for transactions_normalized
CREATE INDEX IF NOT EXISTS idx_transactions_normalized_store_id ON transactions_normalized(store_id);
CREATE INDEX IF NOT EXISTS idx_transactions_normalized_transaction_number ON transactions_normalized(transaction_number);
CREATE INDEX IF NOT EXISTS idx_transactions_normalized_external_transaction_id ON transactions_normalized(external_transaction_id);
CREATE INDEX IF NOT EXISTS idx_transactions_normalized_order_id ON transactions_normalized(order_id);
CREATE INDEX IF NOT EXISTS idx_transactions_normalized_transaction_type ON transactions_normalized(transaction_type);
CREATE INDEX IF NOT EXISTS idx_transactions_normalized_status ON transactions_normalized(status);
CREATE INDEX IF NOT EXISTS idx_transactions_normalized_amount ON transactions_normalized(amount DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_normalized_currency ON transactions_normalized(currency);
CREATE INDEX IF NOT EXISTS idx_transactions_normalized_gateway_name ON transactions_normalized(gateway_name);
CREATE INDEX IF NOT EXISTS idx_transactions_normalized_gateway_transaction_id ON transactions_normalized(gateway_transaction_id);
CREATE INDEX IF NOT EXISTS idx_transactions_normalized_customer_id ON transactions_normalized(customer_id);
CREATE INDEX IF NOT EXISTS idx_transactions_normalized_customer_email ON transactions_normalized(customer_email);
CREATE INDEX IF NOT EXISTS idx_transactions_normalized_is_reconciled ON transactions_normalized(is_reconciled);
CREATE INDEX IF NOT EXISTS idx_transactions_normalized_is_flagged_for_review ON transactions_normalized(is_flagged_for_review) WHERE is_flagged_for_review = TRUE;
CREATE INDEX IF NOT EXISTS idx_transactions_normalized_review_status ON transactions_normalized(review_status);
CREATE INDEX IF NOT EXISTS idx_transactions_normalized_parent_transaction_id ON transactions_normalized(parent_transaction_id);
CREATE INDEX IF NOT EXISTS idx_transactions_normalized_sync_status ON transactions_normalized(sync_status);
CREATE INDEX IF NOT EXISTS idx_transactions_normalized_processed_at ON transactions_normalized(processed_at DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_normalized_created_at ON transactions_normalized(created_at DESC);

-- Foreign key indexes
CREATE INDEX IF NOT EXISTS idx_transactions_normalized_payment_method_id ON transactions_normalized(payment_method_id);
CREATE INDEX IF NOT EXISTS idx_transactions_normalized_gateway_response_id ON transactions_normalized(gateway_response_id);
CREATE INDEX IF NOT EXISTS idx_transactions_normalized_risk_assessment_id ON transactions_normalized(risk_assessment_id);

-- JSONB indexes
CREATE INDEX IF NOT EXISTS idx_transactions_normalized_external_references ON transactions_normalized USING gin(external_references);
CREATE INDEX IF NOT EXISTS idx_transactions_normalized_custom_fields ON transactions_normalized USING gin(custom_fields);
CREATE INDEX IF NOT EXISTS idx_transactions_normalized_sync_errors ON transactions_normalized USING gin(sync_errors);

-- Composite indexes
CREATE INDEX IF NOT EXISTS idx_transactions_normalized_store_status_created ON transactions_normalized(store_id, status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_normalized_store_type_amount ON transactions_normalized(store_id, transaction_type, amount DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_normalized_gateway_status_processed ON transactions_normalized(gateway_name, status, processed_at DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_normalized_customer_status_created ON transactions_normalized(customer_id, status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_normalized_order_type_status ON transactions_normalized(order_id, transaction_type, status);

-- Transaction Relationships indexes
CREATE INDEX IF NOT EXISTS idx_transaction_relationships_transaction_id ON transaction_relationships(transaction_id);
CREATE INDEX IF NOT EXISTS idx_transaction_relationships_store_id ON transaction_relationships(store_id);
CREATE INDEX IF NOT EXISTS idx_transaction_relationships_related_entity ON transaction_relationships(related_entity_type, related_entity_id);
CREATE INDEX IF NOT EXISTS idx_transaction_relationships_relationship_type ON transaction_relationships(relationship_type);
CREATE INDEX IF NOT EXISTS idx_transaction_relationships_is_primary ON transaction_relationships(is_primary_relationship) WHERE is_primary_relationship = TRUE;
CREATE INDEX IF NOT EXISTS idx_transaction_relationships_created_at ON transaction_relationships(created_at DESC);

-- =============================================================================
-- Triggers
-- =============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_transactions_normalized_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_transactions_normalized_updated_at
    BEFORE UPDATE ON transactions_normalized
    FOR EACH ROW
    EXECUTE FUNCTION update_transactions_normalized_updated_at();

CREATE TRIGGER trigger_update_transaction_relationships_updated_at
    BEFORE UPDATE ON transaction_relationships
    FOR EACH ROW
    EXECUTE FUNCTION update_transactions_normalized_updated_at();

-- Update processed_at when status changes to completed
CREATE OR REPLACE FUNCTION update_transaction_processed_at()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'completed' AND OLD.status != 'completed' AND NEW.processed_at IS NULL THEN
        NEW.processed_at = CURRENT_TIMESTAMP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_transaction_processed_at
    BEFORE UPDATE ON transactions_normalized
    FOR EACH ROW
    EXECUTE FUNCTION update_transaction_processed_at();

-- Validate transaction amounts
CREATE OR REPLACE FUNCTION validate_transaction_amounts()
RETURNS TRIGGER AS $$
BEGIN
    -- Ensure refunded amount doesn't exceed transaction amount
    IF NEW.refunded_amount > NEW.amount THEN
        RAISE EXCEPTION 'Refunded amount (%) cannot exceed transaction amount (%)', 
            NEW.refunded_amount, NEW.amount;
    END IF;
    
    -- Ensure fees don't exceed transaction amount
    IF (NEW.fee_amount + NEW.tax_amount) > NEW.amount THEN
        RAISE EXCEPTION 'Total fees (%) cannot exceed transaction amount (%)', 
            (NEW.fee_amount + NEW.tax_amount), NEW.amount;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validate_transaction_amounts
    BEFORE INSERT OR UPDATE ON transactions_normalized
    FOR EACH ROW
    EXECUTE FUNCTION validate_transaction_amounts();

-- Ensure relationship constraints
CREATE OR REPLACE FUNCTION validate_transaction_relationships()
RETURNS TRIGGER AS $$
DECLARE
    v_exists BOOLEAN;
BEGIN
    -- Validate that related entity exists based on type
    CASE NEW.related_entity_type
        WHEN 'order' THEN
            SELECT EXISTS(SELECT 1 FROM orders WHERE id = NEW.related_entity_id) INTO v_exists;
        WHEN 'customer' THEN
            SELECT EXISTS(SELECT 1 FROM customers WHERE id = NEW.related_entity_id) INTO v_exists;
        WHEN 'invoice' THEN
            SELECT EXISTS(SELECT 1 FROM invoices WHERE id = NEW.related_entity_id) INTO v_exists;
        ELSE
            v_exists := TRUE; -- Skip validation for other types
    END CASE;
    
    IF NOT v_exists THEN
        RAISE EXCEPTION 'Related entity of type % with ID % does not exist', 
            NEW.related_entity_type, NEW.related_entity_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validate_transaction_relationships
    BEFORE INSERT OR UPDATE ON transaction_relationships
    FOR EACH ROW
    EXECUTE FUNCTION validate_transaction_relationships();

-- =============================================================================
-- Helper Functions
-- =============================================================================

/**
 * Get complete transaction data with all related information
 * @param p_transaction_id UUID - Transaction ID
 * @return JSONB - Complete transaction data
 */
CREATE OR REPLACE FUNCTION get_complete_transaction_data(
    p_transaction_id UUID
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'transaction', jsonb_build_object(
            'id', t.id,
            'transaction_number', t.transaction_number,
            'external_transaction_id', t.external_transaction_id,
            'order_id', t.order_id,
            'transaction_type', t.transaction_type,
            'status', t.status,
            'amount', t.amount,
            'currency', t.currency,
            'net_amount', t.net_amount,
            'gateway_name', t.gateway_name,
            'customer_id', t.customer_id,
            'customer_email', t.customer_email,
            'is_reconciled', t.is_reconciled,
            'processed_at', t.processed_at,
            'created_at', t.created_at
        ),
        'payment_method', get_transaction_payment_method(t.id),
        'gateway_response', get_transaction_gateway_response(t.id),
        'risk_assessment', get_transaction_risk_assessment(t.id),
        'metadata', get_transaction_metadata(t.id),
        'tags', get_transaction_tags(t.id),
        'relationships', (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'entity_type', tr.related_entity_type,
                    'entity_id', tr.related_entity_id,
                    'relationship_type', tr.relationship_type,
                    'is_primary', tr.is_primary_relationship
                )
            )
            FROM transaction_relationships tr
            WHERE tr.transaction_id = t.id
        )
    ) INTO result
    FROM transactions_normalized t
    WHERE t.id = p_transaction_id;
    
    RETURN COALESCE(result, '{"error": "Transaction not found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

/**
 * Search transactions with filters
 * @param p_store_id UUID - Store ID
 * @param p_filters JSONB - Search filters
 * @param p_limit INTEGER - Result limit
 * @param p_offset INTEGER - Result offset
 * @return JSONB - Search results
 */
CREATE OR REPLACE FUNCTION search_transactions(
    p_store_id UUID,
    p_filters JSONB DEFAULT '{}',
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS JSONB AS $$
DECLARE
    v_where_clause TEXT := 'WHERE t.store_id = $1';
    v_params TEXT[] := ARRAY[p_store_id::TEXT];
    v_param_count INTEGER := 1;
    v_query TEXT;
    result JSONB;
BEGIN
    -- Build dynamic WHERE clause based on filters
    IF p_filters ? 'status' THEN
        v_param_count := v_param_count + 1;
        v_where_clause := v_where_clause || ' AND t.status = $' || v_param_count;
        v_params := array_append(v_params, p_filters->>'status');
    END IF;
    
    IF p_filters ? 'transaction_type' THEN
        v_param_count := v_param_count + 1;
        v_where_clause := v_where_clause || ' AND t.transaction_type = $' || v_param_count;
        v_params := array_append(v_params, p_filters->>'transaction_type');
    END IF;
    
    IF p_filters ? 'gateway_name' THEN
        v_param_count := v_param_count + 1;
        v_where_clause := v_where_clause || ' AND t.gateway_name = $' || v_param_count;
        v_params := array_append(v_params, p_filters->>'gateway_name');
    END IF;
    
    IF p_filters ? 'customer_email' THEN
        v_param_count := v_param_count + 1;
        v_where_clause := v_where_clause || ' AND t.customer_email ILIKE $' || v_param_count;
        v_params := array_append(v_params, '%' || (p_filters->>'customer_email') || '%');
    END IF;
    
    IF p_filters ? 'min_amount' THEN
        v_param_count := v_param_count + 1;
        v_where_clause := v_where_clause || ' AND t.amount >= $' || v_param_count;
        v_params := array_append(v_params, p_filters->>'min_amount');
    END IF;
    
    IF p_filters ? 'max_amount' THEN
        v_param_count := v_param_count + 1;
        v_where_clause := v_where_clause || ' AND t.amount <= $' || v_param_count;
        v_params := array_append(v_params, p_filters->>'max_amount');
    END IF;
    
    IF p_filters ? 'date_from' THEN
        v_param_count := v_param_count + 1;
        v_where_clause := v_where_clause || ' AND t.created_at >= $' || v_param_count;
        v_params := array_append(v_params, p_filters->>'date_from');
    END IF;
    
    IF p_filters ? 'date_to' THEN
        v_param_count := v_param_count + 1;
        v_where_clause := v_where_clause || ' AND t.created_at <= $' || v_param_count;
        v_params := array_append(v_params, p_filters->>'date_to');
    END IF;
    
    -- Build and execute query
    v_query := format('
        SELECT jsonb_build_object(
            ''transactions'', jsonb_agg(
                jsonb_build_object(
                    ''id'', t.id,
                    ''transaction_number'', t.transaction_number,
                    ''transaction_type'', t.transaction_type,
                    ''status'', t.status,
                    ''amount'', t.amount,
                    ''currency'', t.currency,
                    ''gateway_name'', t.gateway_name,
                    ''customer_email'', t.customer_email,
                    ''processed_at'', t.processed_at,
                    ''created_at'', t.created_at
                )
                ORDER BY t.created_at DESC
            ),
            ''total_count'', (
                SELECT COUNT(*)
                FROM transactions_normalized t
                %s
            )
        )
        FROM (
            SELECT *
            FROM transactions_normalized t
            %s
            ORDER BY t.created_at DESC
            LIMIT %s OFFSET %s
        ) t',
        v_where_clause,
        v_where_clause,
        p_limit,
        p_offset
    );
    
    EXECUTE v_query INTO result USING v_params;
    
    RETURN COALESCE(result, '{"transactions": [], "total_count": 0}'::jsonb);
END;
$$ LANGUAGE plpgsql;

/**
 * Get transaction statistics for store
 * @param p_store_id UUID - Store ID
 * @param p_date_from DATE - Start date (optional)
 * @param p_date_to DATE - End date (optional)
 * @return JSONB - Transaction statistics
 */
CREATE OR REPLACE FUNCTION get_transaction_statistics(
    p_store_id UUID,
    p_date_from DATE DEFAULT NULL,
    p_date_to DATE DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_where_clause TEXT := 'WHERE store_id = $1';
    v_params UUID[] := ARRAY[p_store_id];
    result JSONB;
BEGIN
    -- Add date filters if provided
    IF p_date_from IS NOT NULL THEN
        v_where_clause := v_where_clause || ' AND created_at >= $2';
        -- Note: This is a simplified example, proper parameter handling would be more complex
    END IF;
    
    IF p_date_to IS NOT NULL THEN
        v_where_clause := v_where_clause || ' AND created_at <= $3';
    END IF;
    
    SELECT jsonb_build_object(
        'total_transactions', COUNT(*),
        'total_amount', COALESCE(SUM(amount), 0),
        'total_fees', COALESCE(SUM(fee_amount), 0),
        'total_net_amount', COALESCE(SUM(net_amount), 0),
        'average_transaction_amount', COALESCE(AVG(amount), 0),
        'status_breakdown', (
            SELECT jsonb_object_agg(status, status_count)
            FROM (
                SELECT status, COUNT(*) as status_count
                FROM transactions_normalized
                WHERE store_id = p_store_id
                AND (p_date_from IS NULL OR created_at >= p_date_from)
                AND (p_date_to IS NULL OR created_at <= p_date_to)
                GROUP BY status
            ) status_stats
        ),
        'type_breakdown', (
            SELECT jsonb_object_agg(transaction_type, type_count)
            FROM (
                SELECT transaction_type, COUNT(*) as type_count
                FROM transactions_normalized
                WHERE store_id = p_store_id
                AND (p_date_from IS NULL OR created_at >= p_date_from)
                AND (p_date_to IS NULL OR created_at <= p_date_to)
                GROUP BY transaction_type
            ) type_stats
        ),
        'gateway_breakdown', (
            SELECT jsonb_object_agg(gateway_name, gateway_count)
            FROM (
                SELECT gateway_name, COUNT(*) as gateway_count
                FROM transactions_normalized
                WHERE store_id = p_store_id
                AND (p_date_from IS NULL OR created_at >= p_date_from)
                AND (p_date_to IS NULL OR created_at <= p_date_to)
                GROUP BY gateway_name
            ) gateway_stats
        ),
        'currency_breakdown', (
            SELECT jsonb_object_agg(currency, currency_data)
            FROM (
                SELECT 
                    currency,
                    jsonb_build_object(
                        'count', COUNT(*),
                        'total_amount', SUM(amount),
                        'average_amount', AVG(amount)
                    ) as currency_data
                FROM transactions_normalized
                WHERE store_id = p_store_id
                AND (p_date_from IS NULL OR created_at >= p_date_from)
                AND (p_date_to IS NULL OR created_at <= p_date_to)
                GROUP BY currency
            ) currency_stats
        ),
        'reconciliation_status', jsonb_build_object(
            'reconciled_count', COUNT(*) FILTER (WHERE is_reconciled = TRUE),
            'unreconciled_count', COUNT(*) FILTER (WHERE is_reconciled = FALSE),
            'reconciled_amount', COALESCE(SUM(amount) FILTER (WHERE is_reconciled = TRUE), 0),
            'unreconciled_amount', COALESCE(SUM(amount) FILTER (WHERE is_reconciled = FALSE), 0)
        ),
        'review_status', jsonb_build_object(
            'flagged_for_review', COUNT(*) FILTER (WHERE is_flagged_for_review = TRUE),
            'pending_review', COUNT(*) FILTER (WHERE review_status = 'pending'),
            'in_review', COUNT(*) FILTER (WHERE review_status = 'in_review'),
            'approved', COUNT(*) FILTER (WHERE review_status = 'approved'),
            'rejected', COUNT(*) FILTER (WHERE review_status = 'rejected')
        )
    ) INTO result
    FROM transactions_normalized
    WHERE store_id = p_store_id
    AND (p_date_from IS NULL OR created_at >= p_date_from)
    AND (p_date_to IS NULL OR created_at <= p_date_to);
    
    RETURN COALESCE(result, '{"error": "No transactions found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Data Migration Function
-- =============================================================================

/**
 * Migrate data from original transactions table to normalized structure
 * This function should be run after creating all the normalized tables
 */
CREATE OR REPLACE FUNCTION migrate_transactions_to_normalized()
RETURNS BOOLEAN AS $$
DECLARE
    v_transaction RECORD;
    v_new_transaction_id UUID;
    v_payment_method_id UUID;
    v_gateway_response_id UUID;
    v_risk_assessment_id UUID;
BEGIN
    -- Loop through all transactions in the original table
    FOR v_transaction IN 
        SELECT * FROM transactions 
        ORDER BY created_at
    LOOP
        -- Insert payment method details if exists
        IF v_transaction.payment_method_details IS NOT NULL THEN
            INSERT INTO transaction_payment_methods (
                transaction_id, store_id, method_type, method_name,
                card_brand, card_last_four, bank_name, wallet_provider,
                external_references, created_at, updated_at
            ) VALUES (
                v_transaction.id, v_transaction.store_id,
                COALESCE(v_transaction.payment_method_details->>'type', 'unknown'),
                COALESCE(v_transaction.payment_method_details->>'name', 'Unknown'),
                v_transaction.payment_method_details->>'card_brand',
                v_transaction.payment_method_details->>'card_last_four',
                v_transaction.payment_method_details->>'bank_name',
                v_transaction.payment_method_details->>'wallet_provider',
                v_transaction.payment_method_details,
                v_transaction.created_at, v_transaction.updated_at
            ) RETURNING id INTO v_payment_method_id;
        END IF;
        
        -- Insert gateway response if exists
        IF v_transaction.gateway_response IS NOT NULL THEN
            INSERT INTO transaction_gateway_responses (
                transaction_id, store_id, gateway_name,
                response_code, response_message, response_status,
                gateway_transaction_id, raw_response,
                created_at, updated_at
            ) VALUES (
                v_transaction.id, v_transaction.store_id, v_transaction.gateway_name,
                v_transaction.gateway_response->>'code',
                v_transaction.gateway_response->>'message',
                v_transaction.gateway_response->>'status',
                v_transaction.gateway_response->>'transaction_id',
                v_transaction.gateway_response,
                v_transaction.created_at, v_transaction.updated_at
            ) RETURNING id INTO v_gateway_response_id;
        END IF;
        
        -- Insert risk details if exists
        IF v_transaction.risk_details IS NOT NULL THEN
            INSERT INTO transaction_risk_details (
                transaction_id, store_id,
                overall_risk_score, risk_level,
                ip_address, ip_country,
                created_at, updated_at
            ) VALUES (
                v_transaction.id, v_transaction.store_id,
                COALESCE((v_transaction.risk_details->>'score')::INTEGER, 0),
                COALESCE(v_transaction.risk_details->>'level', 'low'),
                (v_transaction.risk_details->>'ip_address')::INET,
                v_transaction.risk_details->>'ip_country',
                v_transaction.created_at, v_transaction.updated_at
            ) RETURNING id INTO v_risk_assessment_id;
        END IF;
        
        -- Insert metadata if exists
        IF v_transaction.metadata IS NOT NULL THEN
            INSERT INTO transaction_metadata (
                transaction_id, store_id, metadata_key, metadata_value,
                created_at, updated_at
            )
            SELECT 
                v_transaction.id, v_transaction.store_id,
                key, value::TEXT,
                v_transaction.created_at, v_transaction.updated_at
            FROM jsonb_each_text(v_transaction.metadata);
        END IF;
        
        -- Insert tags if exists
        IF v_transaction.tags IS NOT NULL AND array_length(v_transaction.tags, 1) > 0 THEN
            INSERT INTO transaction_tags (
                transaction_id, store_id, tag_name, tag_slug,
                created_at, updated_at
            )
            SELECT 
                v_transaction.id, v_transaction.store_id,
                tag, lower(regexp_replace(tag, '[^a-zA-Z0-9]+', '-', 'g')),
                v_transaction.created_at, v_transaction.updated_at
            FROM unnest(v_transaction.tags) AS tag;
        END IF;
        
        -- Insert into normalized transactions table
        INSERT INTO transactions_normalized (
            id, store_id, transaction_number, external_transaction_id,
            order_id, transaction_type, status, amount, currency,
            fee_amount, tax_amount, gateway_name, gateway_transaction_id,
            customer_id, customer_email, customer_phone,
            is_reconciled, reconciled_at, refund_reason, refunded_amount,
            payment_method_id, gateway_response_id, risk_assessment_id,
            sync_status, last_sync_at, created_at, updated_at
        ) VALUES (
            v_transaction.id, v_transaction.store_id,
            v_transaction.transaction_number, v_transaction.external_transaction_id,
            v_transaction.order_id, v_transaction.transaction_type, v_transaction.status,
            v_transaction.amount, v_transaction.currency,
            v_transaction.fee_amount, v_transaction.tax_amount,
            v_transaction.gateway_name, v_transaction.gateway_transaction_id,
            v_transaction.customer_id, v_transaction.customer_email, v_transaction.customer_phone,
            v_transaction.is_reconciled, v_transaction.reconciled_at,
            v_transaction.refund_reason, v_transaction.refunded_amount,
            v_payment_method_id, v_gateway_response_id, v_risk_assessment_id,
            v_transaction.sync_status, v_transaction.last_sync_at,
            v_transaction.created_at, v_transaction.updated_at
        );
        
    END LOOP;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Comments
-- =============================================================================

COMMENT ON TABLE transactions_normalized IS 'Normalized transactions table without JSONB columns';
COMMENT ON TABLE transaction_relationships IS 'Track relationships between transactions and other entities';

COMMENT ON COLUMN transactions_normalized.amount_in_base_currency IS 'Calculated amount in base currency using exchange rate';
COMMENT ON COLUMN transactions_normalized.net_amount IS 'Calculated net amount after fees and taxes';
COMMENT ON COLUMN transactions_normalized.remaining_refundable_amount IS 'Calculated remaining amount that can be refunded';
COMMENT ON COLUMN transactions_normalized.payment_method_id IS 'Reference to normalized payment method details';
COMMENT ON COLUMN transactions_normalized.gateway_response_id IS 'Reference to normalized gateway response details';
COMMENT ON COLUMN transactions_normalized.risk_assessment_id IS 'Reference to normalized risk assessment details';

COMMENT ON FUNCTION get_complete_transaction_data(UUID) IS 'Get complete transaction data with all related information';
COMMENT ON FUNCTION search_transactions(UUID, JSONB, INTEGER, INTEGER) IS 'Search transactions with dynamic filters';
COMMENT ON FUNCTION get_transaction_statistics(UUID, DATE, DATE) IS 'Get comprehensive transaction statistics for store';
COMMENT ON FUNCTION migrate_transactions_to_normalized() IS 'Migrate data from original transactions table to normalized structure';

-- =============================================================================
-- Views for Backward Compatibility
-- =============================================================================

-- Create a view that mimics the original transactions table structure
CREATE OR REPLACE VIEW transactions_legacy_view AS
SELECT 
    t.id,
    t.store_id,
    t.transaction_number,
    t.external_transaction_id,
    t.order_id,
    t.transaction_type,
    t.status,
    t.amount,
    t.currency,
    t.fee_amount,
    t.tax_amount,
    t.net_amount,
    t.gateway_name,
    t.gateway_transaction_id,
    t.gateway_reference,
    t.customer_id,
    t.customer_email,
    t.customer_phone,
    t.is_reconciled,
    t.reconciled_at,
    t.refund_reason,
    t.refunded_amount,
    t.parent_transaction_id,
    
    -- Reconstruct JSONB columns from normalized tables
    COALESCE((
        SELECT jsonb_build_object(
            'type', tpm.method_type,
            'name', tpm.method_name,
            'card_brand', tpm.card_brand,
            'card_last_four', tpm.card_last_four,
            'bank_name', tpm.bank_name,
            'wallet_provider', tpm.wallet_provider,
            'authentication_status', tpm.authentication_status,
            'is_tokenized', tpm.is_tokenized
        )
        FROM transaction_payment_methods tpm
        WHERE tpm.id = t.payment_method_id
    ), '{}'::jsonb) AS payment_method_details,
    
    COALESCE((
        SELECT jsonb_build_object(
            'code', tgr.response_code,
            'message', tgr.response_message,
            'status', tgr.response_status,
            'transaction_id', tgr.gateway_transaction_id,
            'processing_time_ms', tgr.processing_time_ms
        )
        FROM transaction_gateway_responses tgr
        WHERE tgr.id = t.gateway_response_id
    ), '{}'::jsonb) AS gateway_response,
    
    COALESCE((
        SELECT jsonb_build_object(
            'score', trd.overall_risk_score,
            'level', trd.risk_level,
            'ip_address', trd.ip_address::TEXT,
            'ip_country', trd.ip_country,
            'recommended_action', trd.recommended_action
        )
        FROM transaction_risk_details trd
        WHERE trd.id = t.risk_assessment_id
    ), '{}'::jsonb) AS risk_details,
    
    COALESCE((
        SELECT jsonb_object_agg(tm.metadata_key, tm.metadata_value)
        FROM transaction_metadata tm
        WHERE tm.transaction_id = t.id
        AND tm.is_expired = FALSE
    ), '{}'::jsonb) AS metadata,
    
    COALESCE((
        SELECT array_agg(tt.tag_name ORDER BY tt.display_order, tt.tag_name)
        FROM transaction_tags tt
        WHERE tt.transaction_id = t.id
        AND tt.is_active = TRUE
    ), '{}'::TEXT[]) AS tags,
    
    t.sync_status,
    t.last_sync_at,
    t.created_at,
    t.updated_at
FROM transactions_normalized t;

COMMENT ON VIEW transactions_legacy_view IS 'Legacy view that reconstructs original transactions table structure for backward compatibility';