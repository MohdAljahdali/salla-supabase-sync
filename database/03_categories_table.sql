-- Create categories table
-- This table stores product categories with hierarchical structure support
-- Categories can have parent-child relationships for subcategories

CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Salla API identifiers
    salla_category_id VARCHAR(100) NOT NULL,
    
    -- Basic category information
    name VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Hierarchical structure
    parent_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    level INTEGER DEFAULT 0,
    sort_order INTEGER DEFAULT 0,
    
    -- SEO information
    seo_title VARCHAR(255),
    seo_description TEXT,
    slug VARCHAR(255),
    
    -- Media
    image_url TEXT,
    icon_url TEXT,
    
    -- Category status
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'hidden')),
    is_featured BOOLEAN DEFAULT FALSE,
    
    -- Display settings
    show_in_menu BOOLEAN DEFAULT TRUE,
    show_products_count BOOLEAN DEFAULT TRUE,
    
    -- Product count (cached for performance)
    products_count INTEGER DEFAULT 0,
    
    -- Additional metadata
    metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Ensure unique category per store
    UNIQUE(store_id, salla_category_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_categories_store_id ON categories(store_id);
CREATE INDEX IF NOT EXISTS idx_categories_salla_category_id ON categories(salla_category_id);
CREATE INDEX IF NOT EXISTS idx_categories_parent_id ON categories(parent_id);
CREATE INDEX IF NOT EXISTS idx_categories_level ON categories(level);
CREATE INDEX IF NOT EXISTS idx_categories_status ON categories(status);
CREATE INDEX IF NOT EXISTS idx_categories_is_featured ON categories(is_featured);
CREATE INDEX IF NOT EXISTS idx_categories_sort_order ON categories(sort_order);
CREATE INDEX IF NOT EXISTS idx_categories_slug ON categories(slug);
CREATE INDEX IF NOT EXISTS idx_categories_created_at ON categories(created_at);

-- Create GIN index for JSONB metadata
CREATE INDEX IF NOT EXISTS idx_categories_metadata ON categories USING GIN(metadata);

-- Create updated_at trigger
CREATE TRIGGER update_categories_updated_at
    BEFORE UPDATE ON categories
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Function to update category level based on parent
CREATE OR REPLACE FUNCTION update_category_level()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.parent_id IS NULL THEN
        NEW.level = 0;
    ELSE
        SELECT level + 1 INTO NEW.level
        FROM categories
        WHERE id = NEW.parent_id;
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update level
CREATE TRIGGER update_category_level_trigger
    BEFORE INSERT OR UPDATE OF parent_id ON categories
    FOR EACH ROW
    EXECUTE FUNCTION update_category_level();

-- Function to get category path (breadcrumb)
CREATE OR REPLACE FUNCTION get_category_path(category_id UUID)
RETURNS TEXT AS $$
DECLARE
    path TEXT := '';
    current_id UUID := category_id;
    current_name TEXT;
    current_parent_id UUID;
BEGIN
    WHILE current_id IS NOT NULL LOOP
        SELECT name, parent_id INTO current_name, current_parent_id
        FROM categories
        WHERE id = current_id;
        
        IF path = '' THEN
            path := current_name;
        ELSE
            path := current_name || ' > ' || path;
        END IF;
        
        current_id := current_parent_id;
    END LOOP;
    
    RETURN path;
END;
$$ language 'plpgsql';

-- Add comments
COMMENT ON TABLE categories IS 'Categories table with hierarchical structure support';
COMMENT ON COLUMN categories.salla_category_id IS 'Unique category identifier from Salla API';
COMMENT ON COLUMN categories.parent_id IS 'Reference to parent category for hierarchical structure';
COMMENT ON COLUMN categories.level IS 'Category depth level (0 for root categories)';
COMMENT ON COLUMN categories.products_count IS 'Cached count of products in this category';
COMMENT ON FUNCTION get_category_path(UUID) IS 'Returns full category path as breadcrumb string';