-- Create customers table
-- This table stores customer information from Salla stores
-- Includes personal info, addresses, and customer groups

CREATE TABLE IF NOT EXISTS customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Salla API identifiers
    salla_customer_id VARCHAR(100) NOT NULL,
    
    -- Personal information
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(50),
    mobile VARCHAR(50),
    
    -- Profile information
    avatar_url TEXT,
    date_of_birth DATE,
    gender VARCHAR(10) CHECK (gender IN ('male', 'female', 'other')),
    
    -- Account status
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'banned', 'pending')),
    email_verified BOOLEAN DEFAULT FALSE,
    phone_verified BOOLEAN DEFAULT FALSE,
    
    -- Customer group and classification
    customer_group_id UUID,
    customer_type VARCHAR(20) DEFAULT 'individual' CHECK (customer_type IN ('individual', 'business')),
    
    -- Business information (for business customers)
    company_name VARCHAR(255),
    tax_number VARCHAR(100),
    commercial_registration VARCHAR(100),
    
    -- Addresses (stored as JSON array)
    addresses JSONB DEFAULT '[]'::jsonb,
    default_address_id VARCHAR(100),
    
    -- Customer preferences
    language VARCHAR(10) DEFAULT 'ar',
    currency VARCHAR(3) DEFAULT 'SAR',
    timezone VARCHAR(50) DEFAULT 'Asia/Riyadh',
    
    -- Marketing preferences
    accepts_marketing BOOLEAN DEFAULT TRUE,
    email_marketing BOOLEAN DEFAULT TRUE,
    sms_marketing BOOLEAN DEFAULT TRUE,
    
    -- Customer statistics
    total_orders INTEGER DEFAULT 0,
    total_spent DECIMAL(12,2) DEFAULT 0,
    average_order_value DECIMAL(10,2) DEFAULT 0,
    last_order_date TIMESTAMPTZ,
    
    -- Tags and notes
    tags JSONB DEFAULT '[]'::jsonb,
    notes TEXT,
    
    -- Additional metadata
    metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Account dates
    last_login_at TIMESTAMPTZ,
    registered_at TIMESTAMPTZ,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Ensure unique customer per store
    UNIQUE(store_id, salla_customer_id),
    UNIQUE(store_id, email)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_customers_store_id ON customers(store_id);
CREATE INDEX IF NOT EXISTS idx_customers_salla_customer_id ON customers(salla_customer_id);
CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(email);
CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(phone);
CREATE INDEX IF NOT EXISTS idx_customers_mobile ON customers(mobile);
CREATE INDEX IF NOT EXISTS idx_customers_status ON customers(status);
CREATE INDEX IF NOT EXISTS idx_customers_customer_group_id ON customers(customer_group_id);
CREATE INDEX IF NOT EXISTS idx_customers_customer_type ON customers(customer_type);
CREATE INDEX IF NOT EXISTS idx_customers_total_spent ON customers(total_spent);
CREATE INDEX IF NOT EXISTS idx_customers_last_order_date ON customers(last_order_date);
CREATE INDEX IF NOT EXISTS idx_customers_registered_at ON customers(registered_at);
CREATE INDEX IF NOT EXISTS idx_customers_created_at ON customers(created_at);

-- Create GIN indexes for JSONB columns
CREATE INDEX IF NOT EXISTS idx_customers_addresses ON customers USING GIN(addresses);
CREATE INDEX IF NOT EXISTS idx_customers_tags ON customers USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_customers_metadata ON customers USING GIN(metadata);

-- Create updated_at trigger
CREATE TRIGGER update_customers_updated_at
    BEFORE UPDATE ON customers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Function to update customer statistics
CREATE OR REPLACE FUNCTION update_customer_stats(customer_uuid UUID)
RETURNS VOID AS $$
DECLARE
    order_count INTEGER;
    total_amount DECIMAL(12,2);
    avg_amount DECIMAL(10,2);
    last_order TIMESTAMPTZ;
BEGIN
    -- Calculate customer statistics from orders
    SELECT 
        COUNT(*),
        COALESCE(SUM(total_amount), 0),
        COALESCE(AVG(total_amount), 0),
        MAX(created_at)
    INTO order_count, total_amount, avg_amount, last_order
    FROM orders
    WHERE customer_id = customer_uuid
    AND status NOT IN ('cancelled', 'refunded');
    
    -- Update customer record
    UPDATE customers
    SET 
        total_orders = order_count,
        total_spent = total_amount,
        average_order_value = avg_amount,
        last_order_date = last_order,
        updated_at = NOW()
    WHERE id = customer_uuid;
END;
$$ language 'plpgsql';

-- Function to get customer full name
CREATE OR REPLACE FUNCTION get_customer_full_name(customer_row customers)
RETURNS TEXT AS $$
BEGIN
    RETURN TRIM(CONCAT(customer_row.first_name, ' ', customer_row.last_name));
END;
$$ language 'plpgsql';

-- Add comments
COMMENT ON TABLE customers IS 'Customers table storing customer information from Salla stores';
COMMENT ON COLUMN customers.salla_customer_id IS 'Unique customer identifier from Salla API';
COMMENT ON COLUMN customers.addresses IS 'Customer addresses stored as JSON array';
COMMENT ON COLUMN customers.tags IS 'Customer tags for segmentation and organization';
COMMENT ON COLUMN customers.total_spent IS 'Total amount spent by customer across all orders';
COMMENT ON COLUMN customers.metadata IS 'Additional customer metadata from Salla API';
COMMENT ON FUNCTION update_customer_stats(UUID) IS 'Updates customer statistics based on order history';
COMMENT ON FUNCTION get_customer_full_name(customers) IS 'Returns formatted full name of customer';