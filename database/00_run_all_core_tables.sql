-- Run all core database tables for Salla-Supabase sync
-- This script creates the essential tables needed for the application
-- Execute this file in Supabase SQL editor to create all core tables

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Run core table creation scripts in order
-- Note: Execute each file separately in Supabase SQL editor

-- 1. Stores table (main reference table)
\i 01_stores_table.sql

-- 2. Products table
\i 02_products_table.sql

-- 3. Categories table
\i 03_categories_table.sql

-- 4. Customers table
\i 04_customers_table.sql

-- 5. Orders table
\i 05_orders_table.sql

-- 6. Order Items table
\i 06_order_items_table.sql

-- Create additional indexes for cross-table queries
CREATE INDEX IF NOT EXISTS idx_products_categories_gin ON products USING GIN(category_ids);
CREATE INDEX IF NOT EXISTS idx_orders_customer_store ON orders(customer_id, store_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product_order ON order_items(product_id, order_id);

-- Create views for common queries

-- View: Product with category names
CREATE OR REPLACE VIEW products_with_categories AS
SELECT 
    p.*,
    s.name as store_name,
    ARRAY(
        SELECT c.name 
        FROM categories c 
        WHERE c.id::text = ANY(SELECT jsonb_array_elements_text(p.category_ids))
    ) as category_names
FROM products p
JOIN stores s ON p.store_id = s.id;

-- View: Orders with customer details
CREATE OR REPLACE VIEW orders_with_customer AS
SELECT 
    o.*,
    s.name as store_name,
    c.first_name,
    c.last_name,
    c.email as customer_email_current,
    c.phone as customer_phone_current
FROM orders o
JOIN stores s ON o.store_id = s.id
LEFT JOIN customers c ON o.customer_id = c.id;

-- View: Order items with product details
CREATE OR REPLACE VIEW order_items_detailed AS
SELECT 
    oi.*,
    o.order_number,
    o.status as order_status,
    o.order_date,
    p.name as current_product_name,
    p.sku as current_product_sku,
    s.name as store_name
FROM order_items oi
JOIN orders o ON oi.order_id = o.id
JOIN stores s ON oi.store_id = s.id
LEFT JOIN products p ON oi.product_id = p.id;

-- Add comments
COMMENT ON VIEW products_with_categories IS 'Products with resolved category names';
COMMENT ON VIEW orders_with_customer IS 'Orders with current customer information';
COMMENT ON VIEW order_items_detailed IS 'Order items with order and product details';

-- Success message
SELECT 'Core database tables created successfully!' as message;