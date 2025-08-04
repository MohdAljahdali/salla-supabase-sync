-- Create order_items table
-- This table stores individual items within each order
-- Each order can have multiple items (products)

CREATE TABLE IF NOT EXISTS order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    
    -- Salla API identifiers
    salla_order_item_id VARCHAR(100),
    salla_product_id VARCHAR(100),
    
    -- Product information (snapshot at time of order)
    product_name VARCHAR(500) NOT NULL,
    product_sku VARCHAR(255),
    product_image_url TEXT,
    
    -- Variant and option information
    variant_id VARCHAR(100),
    variant_name VARCHAR(255),
    selected_options JSONB DEFAULT '[]'::jsonb,
    
    -- Pricing information
    unit_price DECIMAL(10,2) NOT NULL DEFAULT 0,
    sale_price DECIMAL(10,2),
    cost_price DECIMAL(10,2),
    
    -- Quantity and totals
    quantity INTEGER NOT NULL DEFAULT 1,
    total_price DECIMAL(12,2) NOT NULL DEFAULT 0,
    
    -- Discount information
    discount_amount DECIMAL(10,2) DEFAULT 0,
    discount_percentage DECIMAL(5,2) DEFAULT 0,
    
    -- Tax information
    tax_amount DECIMAL(10,2) DEFAULT 0,
    tax_rate DECIMAL(5,2) DEFAULT 0,
    
    -- Item status
    status VARCHAR(30) DEFAULT 'pending' CHECK (status IN (
        'pending', 'processing', 'shipped', 'delivered', 'cancelled',
        'refunded', 'partially_refunded', 'returned', 'exchanged'
    )),
    
    -- Shipping information
    weight DECIMAL(8,2),
    weight_type VARCHAR(10) DEFAULT 'kg',
    requires_shipping BOOLEAN DEFAULT TRUE,
    
    -- Return and refund information
    is_returnable BOOLEAN DEFAULT TRUE,
    return_period_days INTEGER DEFAULT 14,
    returned_quantity INTEGER DEFAULT 0,
    refunded_quantity INTEGER DEFAULT 0,
    refunded_amount DECIMAL(10,2) DEFAULT 0,
    
    -- Notes and special instructions
    notes TEXT,
    special_instructions TEXT,
    
    -- Additional metadata
    metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_order_items_store_id ON order_items(store_id);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON order_items(product_id);
CREATE INDEX IF NOT EXISTS idx_order_items_salla_order_item_id ON order_items(salla_order_item_id);
CREATE INDEX IF NOT EXISTS idx_order_items_salla_product_id ON order_items(salla_product_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product_sku ON order_items(product_sku);
CREATE INDEX IF NOT EXISTS idx_order_items_variant_id ON order_items(variant_id);
CREATE INDEX IF NOT EXISTS idx_order_items_status ON order_items(status);
CREATE INDEX IF NOT EXISTS idx_order_items_unit_price ON order_items(unit_price);
CREATE INDEX IF NOT EXISTS idx_order_items_quantity ON order_items(quantity);
CREATE INDEX IF NOT EXISTS idx_order_items_total_price ON order_items(total_price);
CREATE INDEX IF NOT EXISTS idx_order_items_created_at ON order_items(created_at);

-- Create GIN indexes for JSONB columns
CREATE INDEX IF NOT EXISTS idx_order_items_selected_options ON order_items USING GIN(selected_options);
CREATE INDEX IF NOT EXISTS idx_order_items_metadata ON order_items USING GIN(metadata);

-- Create updated_at trigger
CREATE TRIGGER update_order_items_updated_at
    BEFORE UPDATE ON order_items
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Function to calculate item total price
CREATE OR REPLACE FUNCTION calculate_item_total()
RETURNS TRIGGER AS $$
BEGIN
    -- Calculate total price based on quantity and unit price
    NEW.total_price = (NEW.unit_price * NEW.quantity) - COALESCE(NEW.discount_amount, 0);
    
    -- Ensure total price is not negative
    IF NEW.total_price < 0 THEN
        NEW.total_price = 0;
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically calculate total price
CREATE TRIGGER calculate_order_item_total
    BEFORE INSERT OR UPDATE OF unit_price, quantity, discount_amount ON order_items
    FOR EACH ROW
    EXECUTE FUNCTION calculate_item_total();

-- Function to update order totals when items change
CREATE OR REPLACE FUNCTION update_order_totals_on_item_change()
RETURNS TRIGGER AS $$
DECLARE
    order_uuid UUID;
    new_subtotal DECIMAL(12,2);
BEGIN
    -- Get the order ID (works for INSERT, UPDATE, DELETE)
    IF TG_OP = 'DELETE' THEN
        order_uuid = OLD.order_id;
    ELSE
        order_uuid = NEW.order_id;
    END IF;
    
    -- Calculate new subtotal for the order
    SELECT COALESCE(SUM(total_price), 0)
    INTO new_subtotal
    FROM order_items
    WHERE order_id = order_uuid;
    
    -- Update the order subtotal
    UPDATE orders
    SET 
        subtotal = new_subtotal,
        total_amount = new_subtotal + COALESCE(tax_amount, 0) + COALESCE(shipping_cost, 0) - COALESCE(discount_amount, 0),
        updated_at = NOW()
    WHERE id = order_uuid;
    
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ language 'plpgsql';

-- Create trigger to update order totals when items change
CREATE TRIGGER update_order_totals_trigger
    AFTER INSERT OR UPDATE OR DELETE ON order_items
    FOR EACH ROW
    EXECUTE FUNCTION update_order_totals_on_item_change();

-- Function to get order items summary
CREATE OR REPLACE FUNCTION get_order_items_summary(order_uuid UUID)
RETURNS TABLE(
    item_count BIGINT,
    total_quantity BIGINT,
    subtotal DECIMAL(12,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) as item_count,
        SUM(quantity) as total_quantity,
        SUM(total_price) as subtotal
    FROM order_items
    WHERE order_id = order_uuid;
END;
$$ language 'plpgsql';

-- Function to check if item can be returned
CREATE OR REPLACE FUNCTION can_item_be_returned(item_uuid UUID)
RETURNS BOOLEAN AS $$
DECLARE
    item_record order_items%ROWTYPE;
    order_record orders%ROWTYPE;
    days_since_delivery INTEGER;
BEGIN
    -- Get item and order information
    SELECT * INTO item_record FROM order_items WHERE id = item_uuid;
    SELECT * INTO order_record FROM orders WHERE id = item_record.order_id;
    
    -- Check if item is returnable
    IF NOT item_record.is_returnable THEN
        RETURN FALSE;
    END IF;
    
    -- Check if order is delivered
    IF order_record.status != 'delivered' OR order_record.delivered_date IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Check if within return period
    days_since_delivery = EXTRACT(DAY FROM NOW() - order_record.delivered_date);
    IF days_since_delivery > item_record.return_period_days THEN
        RETURN FALSE;
    END IF;
    
    -- Check if already fully returned
    IF item_record.returned_quantity >= item_record.quantity THEN
        RETURN FALSE;
    END IF;
    
    RETURN TRUE;
END;
$$ language 'plpgsql';

-- Add comments
COMMENT ON TABLE order_items IS 'Order items table storing individual products within each order';
COMMENT ON COLUMN order_items.selected_options IS 'Product options selected for this item (size, color, etc.)';
COMMENT ON COLUMN order_items.total_price IS 'Total price for this item (unit_price * quantity - discount)';
COMMENT ON COLUMN order_items.metadata IS 'Additional item metadata from Salla API';
COMMENT ON FUNCTION get_order_items_summary(UUID) IS 'Returns summary statistics for order items';
COMMENT ON FUNCTION can_item_be_returned(UUID) IS 'Checks if an order item can be returned based on policies and dates';