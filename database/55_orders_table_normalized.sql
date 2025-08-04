-- =============================================================================
-- Orders Table Normalized
-- =============================================================================
-- This table normalizes the orders table by removing JSONB columns and
-- replacing them with references to separate normalized tables

CREATE TABLE IF NOT EXISTS orders_normalized (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
    
    -- Salla integration
    salla_order_id VARCHAR(255) UNIQUE,
    salla_customer_id VARCHAR(255),
    
    -- Order identification
    order_number VARCHAR(100) NOT NULL,
    reference_id VARCHAR(255),
    
    -- Order status
    status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (status IN (
        'pending', 'processing', 'shipped', 'delivered', 'cancelled', 'refunded', 'returned'
    )),
    payment_status VARCHAR(50) DEFAULT 'pending' CHECK (payment_status IN (
        'pending', 'paid', 'partially_paid', 'failed', 'refunded', 'cancelled'
    )),
    fulfillment_status VARCHAR(50) DEFAULT 'unfulfilled' CHECK (fulfillment_status IN (
        'unfulfilled', 'partially_fulfilled', 'fulfilled', 'shipped', 'delivered', 'returned'
    )),
    
    -- Financial information
    currency_code VARCHAR(3) NOT NULL DEFAULT 'SAR',
    subtotal DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    tax_amount DECIMAL(15,2) DEFAULT 0.00,
    shipping_cost DECIMAL(15,2) DEFAULT 0.00,
    discount_amount DECIMAL(15,2) DEFAULT 0.00,
    total_amount DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    
    -- Payment information
    payment_method VARCHAR(100),
    payment_gateway VARCHAR(100),
    transaction_id VARCHAR(255),
    
    -- Shipping information
    shipping_method VARCHAR(100),
    tracking_number VARCHAR(255),
    estimated_delivery_date DATE,
    actual_delivery_date DATE,
    
    -- Customer information
    customer_email VARCHAR(255),
    customer_phone VARCHAR(50),
    customer_name VARCHAR(255),
    
    -- Order dates
    order_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    shipped_date TIMESTAMPTZ,
    delivered_date TIMESTAMPTZ,
    cancelled_date TIMESTAMPTZ,
    
    -- Notes and comments
    notes TEXT,
    admin_notes TEXT,
    customer_notes TEXT,
    
    -- Flags
    is_gift BOOLEAN DEFAULT FALSE,
    requires_shipping BOOLEAN DEFAULT TRUE,
    is_test_order BOOLEAN DEFAULT FALSE,
    
    -- External references
    external_order_id VARCHAR(255),
    external_references JSONB DEFAULT '{}',
    
    -- Sync information
    sync_status VARCHAR(20) DEFAULT 'synced' CHECK (sync_status IN ('pending', 'syncing', 'synced', 'error')),
    last_sync_at TIMESTAMPTZ,
    sync_errors JSONB DEFAULT '[]',
    
    -- Custom fields
    custom_fields JSONB DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT orders_normalized_positive_amounts CHECK (
        subtotal >= 0 AND tax_amount >= 0 AND shipping_cost >= 0 AND 
        discount_amount >= 0 AND total_amount >= 0
    ),
    CONSTRAINT orders_normalized_valid_dates CHECK (
        order_date <= COALESCE(shipped_date, order_date) AND
        COALESCE(shipped_date, order_date) <= COALESCE(delivered_date, COALESCE(shipped_date, order_date))
    )
);

-- =============================================================================
-- Order Relationships Table
-- =============================================================================
-- Track relationships between orders and other entities

CREATE TABLE IF NOT EXISTS order_relationships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders_normalized(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Relationship information
    related_entity_type VARCHAR(50) NOT NULL CHECK (related_entity_type IN (
        'customer', 'product', 'coupon', 'promotion', 'invoice', 'shipment', 'return', 'refund'
    )),
    related_entity_id UUID NOT NULL,
    relationship_type VARCHAR(50) NOT NULL,
    
    -- Relationship properties
    relationship_strength DECIMAL(3,2) DEFAULT 1.00,
    is_primary BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Relationship context
    context_data JSONB DEFAULT '{}',
    relationship_notes TEXT,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMPTZ,
    
    -- Constraints
    UNIQUE(order_id, related_entity_type, related_entity_id, relationship_type)
);

-- =============================================================================
-- Indexes
-- =============================================================================

-- Basic indexes
CREATE INDEX IF NOT EXISTS idx_orders_normalized_store_id ON orders_normalized(store_id);
CREATE INDEX IF NOT EXISTS idx_orders_normalized_customer_id ON orders_normalized(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_normalized_salla_order_id ON orders_normalized(salla_order_id);
CREATE INDEX IF NOT EXISTS idx_orders_normalized_salla_customer_id ON orders_normalized(salla_customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_normalized_order_number ON orders_normalized(order_number);
CREATE INDEX IF NOT EXISTS idx_orders_normalized_reference_id ON orders_normalized(reference_id);
CREATE INDEX IF NOT EXISTS idx_orders_normalized_external_order_id ON orders_normalized(external_order_id);

-- Status indexes
CREATE INDEX IF NOT EXISTS idx_orders_normalized_status ON orders_normalized(status);
CREATE INDEX IF NOT EXISTS idx_orders_normalized_payment_status ON orders_normalized(payment_status);
CREATE INDEX IF NOT EXISTS idx_orders_normalized_fulfillment_status ON orders_normalized(fulfillment_status);

-- Financial indexes
CREATE INDEX IF NOT EXISTS idx_orders_normalized_currency_code ON orders_normalized(currency_code);
CREATE INDEX IF NOT EXISTS idx_orders_normalized_total_amount ON orders_normalized(total_amount DESC);
CREATE INDEX IF NOT EXISTS idx_orders_normalized_subtotal ON orders_normalized(subtotal DESC);

-- Payment indexes
CREATE INDEX IF NOT EXISTS idx_orders_normalized_payment_method ON orders_normalized(payment_method);
CREATE INDEX IF NOT EXISTS idx_orders_normalized_payment_gateway ON orders_normalized(payment_gateway);
CREATE INDEX IF NOT EXISTS idx_orders_normalized_transaction_id ON orders_normalized(transaction_id);

-- Shipping indexes
CREATE INDEX IF NOT EXISTS idx_orders_normalized_shipping_method ON orders_normalized(shipping_method);
CREATE INDEX IF NOT EXISTS idx_orders_normalized_tracking_number ON orders_normalized(tracking_number);
CREATE INDEX IF NOT EXISTS idx_orders_normalized_estimated_delivery_date ON orders_normalized(estimated_delivery_date);
CREATE INDEX IF NOT EXISTS idx_orders_normalized_actual_delivery_date ON orders_normalized(actual_delivery_date);

-- Customer indexes
CREATE INDEX IF NOT EXISTS idx_orders_normalized_customer_email ON orders_normalized(customer_email);
CREATE INDEX IF NOT EXISTS idx_orders_normalized_customer_phone ON orders_normalized(customer_phone);
CREATE INDEX IF NOT EXISTS idx_orders_normalized_customer_name ON orders_normalized(customer_name);

-- Date indexes
CREATE INDEX IF NOT EXISTS idx_orders_normalized_order_date ON orders_normalized(order_date DESC);
CREATE INDEX IF NOT EXISTS idx_orders_normalized_shipped_date ON orders_normalized(shipped_date DESC);
CREATE INDEX IF NOT EXISTS idx_orders_normalized_delivered_date ON orders_normalized(delivered_date DESC);
CREATE INDEX IF NOT EXISTS idx_orders_normalized_cancelled_date ON orders_normalized(cancelled_date DESC);

-- Flag indexes
CREATE INDEX IF NOT EXISTS idx_orders_normalized_is_gift ON orders_normalized(is_gift) WHERE is_gift = TRUE;
CREATE INDEX IF NOT EXISTS idx_orders_normalized_requires_shipping ON orders_normalized(requires_shipping);
CREATE INDEX IF NOT EXISTS idx_orders_normalized_is_test_order ON orders_normalized(is_test_order) WHERE is_test_order = TRUE;

-- Sync indexes
CREATE INDEX IF NOT EXISTS idx_orders_normalized_sync_status ON orders_normalized(sync_status);
CREATE INDEX IF NOT EXISTS idx_orders_normalized_last_sync_at ON orders_normalized(last_sync_at DESC);

-- Timestamp indexes
CREATE INDEX IF NOT EXISTS idx_orders_normalized_created_at ON orders_normalized(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_normalized_updated_at ON orders_normalized(updated_at DESC);

-- JSONB indexes
CREATE INDEX IF NOT EXISTS idx_orders_normalized_external_references ON orders_normalized USING gin(external_references);
CREATE INDEX IF NOT EXISTS idx_orders_normalized_sync_errors ON orders_normalized USING gin(sync_errors);
CREATE INDEX IF NOT EXISTS idx_orders_normalized_custom_fields ON orders_normalized USING gin(custom_fields);

-- Text search indexes
CREATE INDEX IF NOT EXISTS idx_orders_normalized_order_number_text ON orders_normalized USING gin(to_tsvector('english', order_number));
CREATE INDEX IF NOT EXISTS idx_orders_normalized_customer_name_text ON orders_normalized USING gin(to_tsvector('english', COALESCE(customer_name, '')));
CREATE INDEX IF NOT EXISTS idx_orders_normalized_notes_text ON orders_normalized USING gin(to_tsvector('english', COALESCE(notes, '')));

-- Composite indexes
CREATE INDEX IF NOT EXISTS idx_orders_normalized_store_status ON orders_normalized(store_id, status, order_date DESC);
CREATE INDEX IF NOT EXISTS idx_orders_normalized_customer_status ON orders_normalized(customer_id, status, order_date DESC);
CREATE INDEX IF NOT EXISTS idx_orders_normalized_store_customer ON orders_normalized(store_id, customer_id, order_date DESC);
CREATE INDEX IF NOT EXISTS idx_orders_normalized_payment_status_method ON orders_normalized(payment_status, payment_method);
CREATE INDEX IF NOT EXISTS idx_orders_normalized_fulfillment_shipping ON orders_normalized(fulfillment_status, shipping_method);
CREATE INDEX IF NOT EXISTS idx_orders_normalized_financial ON orders_normalized(currency_code, total_amount DESC, order_date DESC);
CREATE INDEX IF NOT EXISTS idx_orders_normalized_delivery_tracking ON orders_normalized(estimated_delivery_date, tracking_number) WHERE tracking_number IS NOT NULL;

-- Relationships table indexes
CREATE INDEX IF NOT EXISTS idx_order_relationships_order_id ON order_relationships(order_id);
CREATE INDEX IF NOT EXISTS idx_order_relationships_store_id ON order_relationships(store_id);
CREATE INDEX IF NOT EXISTS idx_order_relationships_entity_type ON order_relationships(related_entity_type);
CREATE INDEX IF NOT EXISTS idx_order_relationships_entity_id ON order_relationships(related_entity_id);
CREATE INDEX IF NOT EXISTS idx_order_relationships_type ON order_relationships(relationship_type);
CREATE INDEX IF NOT EXISTS idx_order_relationships_strength ON order_relationships(relationship_strength DESC);
CREATE INDEX IF NOT EXISTS idx_order_relationships_is_primary ON order_relationships(is_primary) WHERE is_primary = TRUE;
CREATE INDEX IF NOT EXISTS idx_order_relationships_is_active ON order_relationships(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_order_relationships_created_at ON order_relationships(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_relationships_context_data ON order_relationships USING gin(context_data);

-- =============================================================================
-- Triggers
-- =============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_orders_normalized_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_orders_normalized_updated_at
    BEFORE UPDATE ON orders_normalized
    FOR EACH ROW
    EXECUTE FUNCTION update_orders_normalized_updated_at();

CREATE TRIGGER trigger_update_order_relationships_updated_at
    BEFORE UPDATE ON order_relationships
    FOR EACH ROW
    EXECUTE FUNCTION update_orders_normalized_updated_at();

-- Update status dates
CREATE OR REPLACE FUNCTION update_order_status_dates()
RETURNS TRIGGER AS $$
BEGIN
    -- Update shipped_date when fulfillment_status changes to shipped
    IF OLD.fulfillment_status != 'shipped' AND NEW.fulfillment_status = 'shipped' THEN
        NEW.shipped_date = CURRENT_TIMESTAMP;
    END IF;
    
    -- Update delivered_date when fulfillment_status changes to delivered
    IF OLD.fulfillment_status != 'delivered' AND NEW.fulfillment_status = 'delivered' THEN
        NEW.delivered_date = CURRENT_TIMESTAMP;
        NEW.actual_delivery_date = CURRENT_DATE;
    END IF;
    
    -- Update cancelled_date when status changes to cancelled
    IF OLD.status != 'cancelled' AND NEW.status = 'cancelled' THEN
        NEW.cancelled_date = CURRENT_TIMESTAMP;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_order_status_dates
    BEFORE UPDATE ON orders_normalized
    FOR EACH ROW
    EXECUTE FUNCTION update_order_status_dates();

-- Validate order totals
CREATE OR REPLACE FUNCTION validate_order_totals()
RETURNS TRIGGER AS $$
BEGIN
    -- Calculate expected total
    DECLARE
        expected_total DECIMAL(15,2);
    BEGIN
        expected_total := NEW.subtotal + NEW.tax_amount + NEW.shipping_cost - NEW.discount_amount;
        
        -- Allow small rounding differences (up to 0.01)
        IF ABS(NEW.total_amount - expected_total) > 0.01 THEN
            RAISE EXCEPTION 'Order total (%) does not match calculated total (%). Subtotal: %, Tax: %, Shipping: %, Discount: %',
                NEW.total_amount, expected_total, NEW.subtotal, NEW.tax_amount, NEW.shipping_cost, NEW.discount_amount;
        END IF;
    END;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validate_order_totals
    BEFORE INSERT OR UPDATE ON orders_normalized
    FOR EACH ROW
    EXECUTE FUNCTION validate_order_totals();

-- Validate relationship constraints
CREATE OR REPLACE FUNCTION validate_order_relationships()
RETURNS TRIGGER AS $$
BEGIN
    -- Ensure only one primary relationship per entity type
    IF NEW.is_primary = TRUE THEN
        UPDATE order_relationships 
        SET is_primary = FALSE 
        WHERE order_id = NEW.order_id 
        AND related_entity_type = NEW.related_entity_type 
        AND id != COALESCE(NEW.id, gen_random_uuid());
    END IF;
    
    -- End relationship if ended_at is set
    IF NEW.ended_at IS NOT NULL THEN
        NEW.is_active = FALSE;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validate_order_relationships
    BEFORE INSERT OR UPDATE ON order_relationships
    FOR EACH ROW
    EXECUTE FUNCTION validate_order_relationships();

-- =============================================================================
-- Helper Functions
-- =============================================================================

/**
 * Get complete order data with related information
 * @param p_order_id UUID - Order ID
 * @return JSONB - Complete order data
 */
CREATE OR REPLACE FUNCTION get_complete_order_data(
    p_order_id UUID
)
RETURNS JSONB AS $$
DECLARE
    order_data JSONB;
    billing_address JSONB;
    shipping_address JSONB;
    order_tags JSONB;
    order_metadata JSONB;
    order_items JSONB;
    relationships JSONB;
BEGIN
    -- Get basic order data
    SELECT to_jsonb(o.*) INTO order_data
    FROM orders_normalized o
    WHERE o.id = p_order_id;
    
    IF order_data IS NULL THEN
        RETURN NULL;
    END IF;
    
    -- Get billing address
    SELECT jsonb_agg(to_jsonb(oba.*)) INTO billing_address
    FROM order_billing_addresses oba
    WHERE oba.order_id = p_order_id;
    
    -- Get shipping address
    SELECT jsonb_agg(to_jsonb(osa.*)) INTO shipping_address
    FROM order_shipping_addresses osa
    WHERE osa.order_id = p_order_id;
    
    -- Get order tags
    SELECT jsonb_agg(
        jsonb_build_object(
            'tag_name', ot.tag_name,
            'tag_value', ot.tag_value,
            'tag_type', ot.tag_type,
            'is_system_tag', ot.is_system_tag
        )
    ) INTO order_tags
    FROM order_tags ot
    WHERE ot.order_id = p_order_id AND ot.is_active = TRUE;
    
    -- Get order metadata
    SELECT jsonb_agg(
        jsonb_build_object(
            'metadata_key', om.metadata_key,
            'metadata_value', om.metadata_value,
            'metadata_type', om.metadata_type,
            'display_name', om.display_name
        )
    ) INTO order_metadata
    FROM order_metadata om
    WHERE om.order_id = p_order_id AND om.is_valid = TRUE;
    
    -- Get order items (assuming order_items table exists)
    SELECT jsonb_agg(to_jsonb(oi.*)) INTO order_items
    FROM order_items oi
    WHERE oi.order_id = p_order_id;
    
    -- Get relationships
    SELECT jsonb_agg(
        jsonb_build_object(
            'entity_type', or_rel.related_entity_type,
            'entity_id', or_rel.related_entity_id,
            'relationship_type', or_rel.relationship_type,
            'is_primary', or_rel.is_primary,
            'context_data', or_rel.context_data
        )
    ) INTO relationships
    FROM order_relationships or_rel
    WHERE or_rel.order_id = p_order_id AND or_rel.is_active = TRUE;
    
    -- Combine all data
    RETURN order_data || jsonb_build_object(
        'billing_addresses', COALESCE(billing_address, '[]'::jsonb),
        'shipping_addresses', COALESCE(shipping_address, '[]'::jsonb),
        'tags', COALESCE(order_tags, '[]'::jsonb),
        'metadata', COALESCE(order_metadata, '[]'::jsonb),
        'items', COALESCE(order_items, '[]'::jsonb),
        'relationships', COALESCE(relationships, '[]'::jsonb)
    );
END;
$$ LANGUAGE plpgsql;

/**
 * Search orders with filters
 * @param p_store_id UUID - Store ID
 * @param p_filters JSONB - Search filters
 * @param p_limit INTEGER - Result limit
 * @param p_offset INTEGER - Result offset
 * @return TABLE - Search results
 */
CREATE OR REPLACE FUNCTION search_orders_normalized(
    p_store_id UUID,
    p_filters JSONB DEFAULT '{}',
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    order_id UUID,
    order_number VARCHAR,
    customer_name VARCHAR,
    status VARCHAR,
    total_amount DECIMAL,
    order_date TIMESTAMPTZ,
    relevance_score REAL
) AS $$
DECLARE
    search_term TEXT;
    status_filter VARCHAR;
    date_from TIMESTAMPTZ;
    date_to TIMESTAMPTZ;
    min_amount DECIMAL;
    max_amount DECIMAL;
BEGIN
    -- Extract filters
    search_term := p_filters ->> 'search_term';
    status_filter := p_filters ->> 'status';
    date_from := (p_filters ->> 'date_from')::timestamptz;
    date_to := (p_filters ->> 'date_to')::timestamptz;
    min_amount := (p_filters ->> 'min_amount')::decimal;
    max_amount := (p_filters ->> 'max_amount')::decimal;
    
    RETURN QUERY
    SELECT 
        o.id as order_id,
        o.order_number,
        o.customer_name,
        o.status,
        o.total_amount,
        o.order_date,
        (
            CASE WHEN search_term IS NOT NULL THEN
                ts_rank(to_tsvector('english', 
                    COALESCE(o.order_number, '') || ' ' || 
                    COALESCE(o.customer_name, '') || ' ' || 
                    COALESCE(o.customer_email, '') || ' ' ||
                    COALESCE(o.notes, '')
                ), plainto_tsquery('english', search_term)) +
                CASE WHEN o.order_number ILIKE '%' || search_term || '%' THEN 0.5 ELSE 0 END +
                CASE WHEN o.customer_name ILIKE '%' || search_term || '%' THEN 0.3 ELSE 0 END
            ELSE 1.0
            END
        )::REAL as relevance_score
    FROM orders_normalized o
    WHERE o.store_id = p_store_id
    AND (search_term IS NULL OR (
        to_tsvector('english', 
            COALESCE(o.order_number, '') || ' ' || 
            COALESCE(o.customer_name, '') || ' ' || 
            COALESCE(o.customer_email, '') || ' ' ||
            COALESCE(o.notes, '')
        ) @@ plainto_tsquery('english', search_term)
        OR o.order_number ILIKE '%' || search_term || '%'
        OR o.customer_name ILIKE '%' || search_term || '%'
        OR o.customer_email ILIKE '%' || search_term || '%'
    ))
    AND (status_filter IS NULL OR o.status = status_filter)
    AND (date_from IS NULL OR o.order_date >= date_from)
    AND (date_to IS NULL OR o.order_date <= date_to)
    AND (min_amount IS NULL OR o.total_amount >= min_amount)
    AND (max_amount IS NULL OR o.total_amount <= max_amount)
    ORDER BY 
        CASE WHEN search_term IS NOT NULL THEN relevance_score ELSE 1.0 END DESC,
        o.order_date DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql;

/**
 * Get order statistics for store
 * @param p_store_id UUID - Store ID
 * @param p_date_from TIMESTAMPTZ - Start date
 * @param p_date_to TIMESTAMPTZ - End date
 * @return JSONB - Order statistics
 */
CREATE OR REPLACE FUNCTION get_order_stats(
    p_store_id UUID,
    p_date_from TIMESTAMPTZ DEFAULT NULL,
    p_date_to TIMESTAMPTZ DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_orders', COUNT(*),
        'total_revenue', SUM(total_amount),
        'average_order_value', AVG(total_amount),
        'total_tax', SUM(tax_amount),
        'total_shipping', SUM(shipping_cost),
        'total_discounts', SUM(discount_amount),
        'orders_by_status', (
            SELECT jsonb_object_agg(status, status_count)
            FROM (
                SELECT status, COUNT(*) as status_count
                FROM orders_normalized
                WHERE store_id = p_store_id
                AND (p_date_from IS NULL OR order_date >= p_date_from)
                AND (p_date_to IS NULL OR order_date <= p_date_to)
                GROUP BY status
            ) status_stats
        ),
        'orders_by_payment_status', (
            SELECT jsonb_object_agg(payment_status, payment_count)
            FROM (
                SELECT payment_status, COUNT(*) as payment_count
                FROM orders_normalized
                WHERE store_id = p_store_id
                AND (p_date_from IS NULL OR order_date >= p_date_from)
                AND (p_date_to IS NULL OR order_date <= p_date_to)
                GROUP BY payment_status
            ) payment_stats
        ),
        'orders_by_fulfillment_status', (
            SELECT jsonb_object_agg(fulfillment_status, fulfillment_count)
            FROM (
                SELECT fulfillment_status, COUNT(*) as fulfillment_count
                FROM orders_normalized
                WHERE store_id = p_store_id
                AND (p_date_from IS NULL OR order_date >= p_date_from)
                AND (p_date_to IS NULL OR order_date <= p_date_to)
                GROUP BY fulfillment_status
            ) fulfillment_stats
        ),
        'top_payment_methods', (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'payment_method', payment_method,
                    'order_count', method_count,
                    'total_revenue', method_revenue
                )
            )
            FROM (
                SELECT 
                    payment_method,
                    COUNT(*) as method_count,
                    SUM(total_amount) as method_revenue
                FROM orders_normalized
                WHERE store_id = p_store_id
                AND payment_method IS NOT NULL
                AND (p_date_from IS NULL OR order_date >= p_date_from)
                AND (p_date_to IS NULL OR order_date <= p_date_to)
                GROUP BY payment_method
                ORDER BY COUNT(*) DESC, SUM(total_amount) DESC
                LIMIT 10
            ) payment_method_stats
        ),
        'daily_orders', (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'date', order_date::date,
                    'order_count', daily_count,
                    'daily_revenue', daily_revenue
                )
            )
            FROM (
                SELECT 
                    order_date::date,
                    COUNT(*) as daily_count,
                    SUM(total_amount) as daily_revenue
                FROM orders_normalized
                WHERE store_id = p_store_id
                AND (p_date_from IS NULL OR order_date >= p_date_from)
                AND (p_date_to IS NULL OR order_date <= p_date_to)
                GROUP BY order_date::date
                ORDER BY order_date::date DESC
                LIMIT 30
            ) daily_stats
        )
    ) INTO result
    FROM orders_normalized
    WHERE store_id = p_store_id
    AND (p_date_from IS NULL OR order_date >= p_date_from)
    AND (p_date_to IS NULL OR order_date <= p_date_to);
    
    RETURN COALESCE(result, '{"error": "No orders found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Comments
-- =============================================================================

COMMENT ON TABLE orders_normalized IS 'Normalized orders table without JSONB columns';
COMMENT ON TABLE order_relationships IS 'Track relationships between orders and other entities';

COMMENT ON COLUMN orders_normalized.salla_order_id IS 'Unique identifier from Salla platform';
COMMENT ON COLUMN orders_normalized.status IS 'Current order status';
COMMENT ON COLUMN orders_normalized.payment_status IS 'Current payment status';
COMMENT ON COLUMN orders_normalized.fulfillment_status IS 'Current fulfillment status';
COMMENT ON COLUMN orders_normalized.total_amount IS 'Final order total including all fees and discounts';

COMMENT ON FUNCTION get_complete_order_data(UUID) IS 'Get complete order data with all related information';
COMMENT ON FUNCTION search_orders_normalized(UUID, JSONB, INTEGER, INTEGER) IS 'Search orders with filters and pagination';
COMMENT ON FUNCTION get_order_stats(UUID, TIMESTAMPTZ, TIMESTAMPTZ) IS 'Get comprehensive order statistics for store';