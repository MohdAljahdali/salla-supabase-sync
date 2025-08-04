-- Create stores table
-- This is the main table that contains store information
-- All other tables will reference this table via store_id

CREATE TABLE IF NOT EXISTS stores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Basic store information
    name VARCHAR(255) NOT NULL,
    description TEXT,
    logo_url TEXT,
    
    -- Contact information
    email VARCHAR(255),
    phone VARCHAR(50),
    address TEXT,
    city VARCHAR(100),
    country VARCHAR(100),
    postal_code VARCHAR(20),
    
    -- Store settings
    default_currency VARCHAR(3) DEFAULT 'SAR',
    timezone VARCHAR(50) DEFAULT 'Asia/Riyadh',
    language VARCHAR(10) DEFAULT 'ar',
    
    -- E-commerce information
    commercial_registration_number VARCHAR(100),
    tax_number VARCHAR(100),
    
    -- Store status
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'disabled', 'maintenance')),
    
    -- API configuration
    salla_store_id VARCHAR(100) UNIQUE,
    salla_access_token TEXT,
    salla_refresh_token TEXT,
    api_last_sync TIMESTAMPTZ,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_stores_salla_store_id ON stores(salla_store_id);
CREATE INDEX IF NOT EXISTS idx_stores_status ON stores(status);
CREATE INDEX IF NOT EXISTS idx_stores_created_at ON stores(created_at);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_stores_updated_at
    BEFORE UPDATE ON stores
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Add comments
COMMENT ON TABLE stores IS 'Main stores table containing store information and configuration';
COMMENT ON COLUMN stores.salla_store_id IS 'Unique identifier from Salla API';
COMMENT ON COLUMN stores.status IS 'Store operational status: active, disabled, or maintenance';
COMMENT ON COLUMN stores.api_last_sync IS 'Last time data was synchronized with Salla API';