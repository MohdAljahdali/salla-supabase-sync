-- Create orders table
-- This table stores order information from Salla stores
-- Each order belongs to a customer and store

CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
    
    -- Salla API identifiers
    salla_order_id VARCHAR(100) NOT NULL,
    
    -- Order identification
    order_number VARCHAR(100) NOT NULL,
    reference_id VARCHAR(100),
    
    -- Order status
    status VARCHAR(30) DEFAULT 'pending' CHECK (status IN (
        'pending', 'processing', 'shipped', 'delivered', 'cancelled', 
        'refunded', 'partially_refunded', 'on_hold', 'awaiting_payment',
        'payment_failed', 'ready_for_pickup'
    )),
    
    -- Payment information
    payment_status VARCHAR(30) DEFAULT 'pending' CHECK (payment_status IN (
        'pending', 'paid', 'partially_paid', 'failed', 'cancelled',
        'refunded', 'partially_refunded', 'authorized', 'captured'
    )),
    payment_method VARCHAR(50),
    payment_gateway VARCHAR(50),
    
    -- Financial information
    subtotal DECIMAL(12,2) NOT NULL DEFAULT 0,
    tax_amount DECIMAL(10,2) DEFAULT 0,
    shipping_cost DECIMAL(10,2) DEFAULT 0,
    discount_amount DECIMAL(10,2) DEFAULT 0,
    total_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    currency VARCHAR(3) DEFAULT 'SAR',
    
    -- Coupon information
    coupon_code VARCHAR(100),
    coupon_discount DECIMAL(10,2) DEFAULT 0,
    
    -- Customer information (snapshot at time of order)
    customer_name VARCHAR(255),
    customer_email VARCHAR(255),
    customer_phone VARCHAR(50),
    
    -- Billing address
    billing_address JSONB DEFAULT '{}'::jsonb,
    
    -- Shipping information
    shipping_address JSONB DEFAULT '{}'::jsonb,
    shipping_method VARCHAR(100),
    shipping_company VARCHAR(100),
    tracking_number VARCHAR(100),
    tracking_url TEXT,
    
    -- Delivery information
    estimated_delivery_date DATE,
    actual_delivery_date TIMESTAMPTZ,
    delivery_instructions TEXT,
    
    -- Order notes and tags
    notes TEXT,
    admin_notes TEXT,
    tags JSONB DEFAULT '[]'::jsonb,
    
    -- Order URLs
    order_url TEXT,
    invoice_url TEXT,
    
    -- Important dates
    order_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    payment_date TIMESTAMPTZ,
    shipped_date TIMESTAMPTZ,
    delivered_date TIMESTAMPTZ,
    cancelled_date TIMESTAMPTZ,
    
    -- Additional metadata
    metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Ensure unique order per store
    UNIQUE(store_id, salla_order_id),
    UNIQUE(store_id, order_number)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_orders_store_id ON orders(store_id);
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_salla_order_id ON orders(salla_order_id);
CREATE INDEX IF NOT EXISTS idx_orders_order_number ON orders(order_number);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_payment_status ON orders(payment_status);
CREATE INDEX IF NOT EXISTS idx_orders_payment_method ON orders(payment_method);
CREATE INDEX IF NOT EXISTS idx_orders_total_amount ON orders(total_amount);
CREATE INDEX IF NOT EXISTS idx_orders_order_date ON orders(order_date);
CREATE INDEX IF NOT EXISTS idx_orders_payment_date ON orders(payment_date);
CREATE INDEX IF NOT EXISTS idx_orders_shipped_date ON orders(shipped_date);
CREATE INDEX IF NOT EXISTS idx_orders_delivered_date ON orders(delivered_date);
CREATE INDEX IF NOT EXISTS idx_orders_tracking_number ON orders(tracking_number);
CREATE INDEX IF NOT EXISTS idx_orders_coupon_code ON orders(coupon_code);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at);

-- Create GIN indexes for JSONB columns
CREATE INDEX IF NOT EXISTS idx_orders_billing_address ON orders USING GIN(billing_address);
CREATE INDEX IF NOT EXISTS idx_orders_shipping_address ON orders USING GIN(shipping_address);
CREATE INDEX IF NOT EXISTS idx_orders_tags ON orders USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_orders_metadata ON orders USING GIN(metadata);

-- Create updated_at trigger
CREATE TRIGGER update_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Function to update order status dates
CREATE OR REPLACE FUNCTION update_order_status_dates()
RETURNS TRIGGER AS $$
BEGIN
    -- Update payment_date when payment_status changes to paid
    IF OLD.payment_status != 'paid' AND NEW.payment_status = 'paid' THEN
        NEW.payment_date = NOW();
    END IF;
    
    -- Update shipped_date when status changes to shipped
    IF OLD.status != 'shipped' AND NEW.status = 'shipped' THEN
        NEW.shipped_date = NOW();
    END IF;
    
    -- Update delivered_date when status changes to delivered
    IF OLD.status != 'delivered' AND NEW.status = 'delivered' THEN
        NEW.delivered_date = NOW();
    END IF;
    
    -- Update cancelled_date when status changes to cancelled
    IF OLD.status != 'cancelled' AND NEW.status = 'cancelled' THEN
        NEW.cancelled_date = NOW();
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update status dates
CREATE TRIGGER update_order_status_dates_trigger
    BEFORE UPDATE OF status, payment_status ON orders
    FOR EACH ROW
    EXECUTE FUNCTION update_order_status_dates();

-- Function to calculate order totals
CREATE OR REPLACE FUNCTION calculate_order_total(order_uuid UUID)
RETURNS DECIMAL(12,2) AS $$
DECLARE
    calculated_total DECIMAL(12,2);
BEGIN
    SELECT 
        subtotal + COALESCE(tax_amount, 0) + COALESCE(shipping_cost, 0) - COALESCE(discount_amount, 0)
    INTO calculated_total
    FROM orders
    WHERE id = order_uuid;
    
    RETURN COALESCE(calculated_total, 0);
END;
$$ language 'plpgsql';

-- Function to get order summary
CREATE OR REPLACE FUNCTION get_order_summary(order_uuid UUID)
RETURNS TABLE(
    order_number VARCHAR(100),
    customer_name VARCHAR(255),
    status VARCHAR(30),
    total_amount DECIMAL(12,2),
    order_date TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        o.order_number,
        o.customer_name,
        o.status,
        o.total_amount,
        o.order_date
    FROM orders o
    WHERE o.id = order_uuid;
END;
$$ language 'plpgsql';

-- Add comments
COMMENT ON TABLE orders IS 'Orders table storing order information from Salla stores';
COMMENT ON COLUMN orders.salla_order_id IS 'Unique order identifier from Salla API';
COMMENT ON COLUMN orders.billing_address IS 'Billing address stored as JSON object';
COMMENT ON COLUMN orders.shipping_address IS 'Shipping address stored as JSON object';
COMMENT ON COLUMN orders.tags IS 'Order tags for organization and filtering';
COMMENT ON COLUMN orders.metadata IS 'Additional order metadata from Salla API';
COMMENT ON FUNCTION calculate_order_total(UUID) IS 'Calculates total order amount including taxes and shipping';
COMMENT ON FUNCTION get_order_summary(UUID) IS 'Returns order summary information';