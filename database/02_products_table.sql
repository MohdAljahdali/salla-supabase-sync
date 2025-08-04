-- Create products table
-- This table stores all product information from Salla stores
-- Each product belongs to a specific store

CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Salla API identifiers
    salla_product_id VARCHAR(100) NOT NULL,
    
    -- Basic product information
    name VARCHAR(500) NOT NULL,
    description TEXT,
    short_description TEXT,
    
    -- Pricing information
    price DECIMAL(10,2) NOT NULL DEFAULT 0,
    sale_price DECIMAL(10,2),
    cost_price DECIMAL(10,2),
    currency VARCHAR(3) DEFAULT 'SAR',
    
    -- Inventory information
    sku VARCHAR(255),
    mpn VARCHAR(255), -- Manufacturer Part Number
    gtin VARCHAR(255), -- Global Trade Item Number
    quantity INTEGER DEFAULT 0,
    unlimited_quantity BOOLEAN DEFAULT FALSE,
    hide_quantity BOOLEAN DEFAULT FALSE,
    
    -- Product specifications
    weight DECIMAL(8,2),
    weight_type VARCHAR(10) DEFAULT 'kg' CHECK (weight_type IN ('kg', 'g', 'lb', 'oz')),
    requires_shipping BOOLEAN DEFAULT TRUE,
    
    -- Product type and variants
    type VARCHAR(20) DEFAULT 'simple' CHECK (type IN ('simple', 'variable', 'digital')),
    has_variants BOOLEAN DEFAULT FALSE,
    has_options BOOLEAN DEFAULT FALSE,
    
    -- SEO information
    seo_title VARCHAR(255),
    seo_description TEXT,
    slug VARCHAR(255),
    
    -- Product status
    status VARCHAR(20) DEFAULT 'available' CHECK (status IN ('available', 'hidden', 'out_of_stock', 'draft')),
    is_featured BOOLEAN DEFAULT FALSE,
    
    -- Media
    main_image_url TEXT,
    images JSONB DEFAULT '[]'::jsonb,
    videos JSONB DEFAULT '[]'::jsonb,
    
    -- Categories and tags
    category_ids JSONB DEFAULT '[]'::jsonb,
    tag_ids JSONB DEFAULT '[]'::jsonb,
    
    -- Brand information
    brand_id UUID,
    
    -- Rating and reviews
    rating_average DECIMAL(3,2) DEFAULT 0,
    rating_count INTEGER DEFAULT 0,
    
    -- Product options and variants (stored as JSON)
    options JSONB DEFAULT '[]'::jsonb,
    variants JSONB DEFAULT '[]'::jsonb,
    
    -- Additional metadata
    metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Ensure unique product per store
    UNIQUE(store_id, salla_product_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_products_store_id ON products(store_id);
CREATE INDEX IF NOT EXISTS idx_products_salla_product_id ON products(salla_product_id);
CREATE INDEX IF NOT EXISTS idx_products_sku ON products(sku);
CREATE INDEX IF NOT EXISTS idx_products_status ON products(status);
CREATE INDEX IF NOT EXISTS idx_products_is_featured ON products(is_featured);
CREATE INDEX IF NOT EXISTS idx_products_brand_id ON products(brand_id);
CREATE INDEX IF NOT EXISTS idx_products_created_at ON products(created_at);
CREATE INDEX IF NOT EXISTS idx_products_price ON products(price);
CREATE INDEX IF NOT EXISTS idx_products_quantity ON products(quantity);

-- Create GIN indexes for JSONB columns
CREATE INDEX IF NOT EXISTS idx_products_category_ids ON products USING GIN(category_ids);
CREATE INDEX IF NOT EXISTS idx_products_tag_ids ON products USING GIN(tag_ids);
CREATE INDEX IF NOT EXISTS idx_products_metadata ON products USING GIN(metadata);

-- Create updated_at trigger
CREATE TRIGGER update_products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Add comments
COMMENT ON TABLE products IS 'Products table storing all product information from Salla stores';
COMMENT ON COLUMN products.salla_product_id IS 'Unique product identifier from Salla API';
COMMENT ON COLUMN products.unlimited_quantity IS 'Whether product has unlimited stock';
COMMENT ON COLUMN products.type IS 'Product type: simple, variable (with variants), or digital';
COMMENT ON COLUMN products.options IS 'Product options like size, color stored as JSON array';
COMMENT ON COLUMN products.variants IS 'Product variants with different combinations of options';
COMMENT ON COLUMN products.metadata IS 'Additional product metadata from Salla API';