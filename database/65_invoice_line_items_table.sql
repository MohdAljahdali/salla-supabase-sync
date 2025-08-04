-- =============================================================================
-- Invoice Line Items Table
-- =============================================================================
-- This file normalizes the line_items JSONB column from the invoices table
-- into a separate table with proper structure and relationships

-- =============================================================================
-- Invoice Line Items Table
-- =============================================================================

CREATE TABLE IF NOT EXISTS invoice_line_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Line item identification
    line_item_number INTEGER NOT NULL, -- Sequential number within invoice
    external_line_item_id VARCHAR(255), -- External system line item ID
    
    -- Product information
    product_id UUID, -- Reference to products table if exists
    product_sku VARCHAR(100),
    product_name VARCHAR(255) NOT NULL,
    product_description TEXT,
    product_type VARCHAR(50) DEFAULT 'physical' CHECK (product_type IN (
        'physical', 'digital', 'service', 'subscription', 'gift_card', 'bundle', 'virtual'
    )),
    
    -- Variant information
    variant_id UUID, -- Reference to product variants if exists
    variant_sku VARCHAR(100),
    variant_name VARCHAR(255),
    variant_attributes JSONB DEFAULT '{}', -- Size, color, etc.
    
    -- Quantity and units
    quantity DECIMAL(10,3) NOT NULL CHECK (quantity > 0),
    unit_of_measure VARCHAR(20) DEFAULT 'piece' CHECK (unit_of_measure IN (
        'piece', 'kg', 'gram', 'pound', 'ounce', 'liter', 'ml', 'meter', 'cm', 
        'inch', 'foot', 'yard', 'square_meter', 'square_foot', 'hour', 'day', 'month'
    )),
    
    -- Pricing information
    unit_price DECIMAL(15,4) NOT NULL CHECK (unit_price >= 0),
    list_price DECIMAL(15,4), -- Original/list price before discounts
    cost_price DECIMAL(15,4), -- Cost price for margin calculation
    
    -- Line totals
    line_subtotal DECIMAL(15,4) GENERATED ALWAYS AS (quantity * unit_price) STORED,
    line_discount_amount DECIMAL(15,4) DEFAULT 0 CHECK (line_discount_amount >= 0),
    line_tax_amount DECIMAL(15,4) DEFAULT 0 CHECK (line_tax_amount >= 0),
    line_total DECIMAL(15,4) GENERATED ALWAYS AS (line_subtotal - line_discount_amount + line_tax_amount) STORED,
    
    -- Margin and profitability
    gross_margin DECIMAL(15,4) GENERATED ALWAYS AS (
        CASE WHEN cost_price IS NOT NULL THEN line_subtotal - (quantity * cost_price) ELSE NULL END
    ) STORED,
    margin_percentage DECIMAL(5,2) GENERATED ALWAYS AS (
        CASE WHEN cost_price IS NOT NULL AND line_subtotal > 0 
        THEN ((line_subtotal - (quantity * cost_price)) / line_subtotal) * 100 
        ELSE NULL END
    ) STORED,
    
    -- Discount information
    discount_type VARCHAR(30) CHECK (discount_type IN (
        'percentage', 'fixed_amount', 'buy_x_get_y', 'bulk', 'loyalty', 'coupon', 'promotional'
    )),
    discount_value DECIMAL(15,4), -- Discount rate or amount
    discount_reason VARCHAR(255), -- Reason for discount
    discount_code VARCHAR(50), -- Discount code applied
    
    -- Tax information
    tax_rate DECIMAL(8,6) DEFAULT 0 CHECK (tax_rate >= 0),
    tax_type VARCHAR(50), -- VAT, sales tax, etc.
    tax_exempt BOOLEAN DEFAULT FALSE,
    tax_exempt_reason VARCHAR(255),
    
    -- Product categorization
    category_id UUID, -- Reference to categories if exists
    category_name VARCHAR(255),
    brand_id UUID, -- Reference to brands if exists
    brand_name VARCHAR(255),
    collection_id UUID, -- Reference to collections if exists
    collection_name VARCHAR(255),
    
    -- Physical properties
    weight DECIMAL(8,3), -- Product weight
    weight_unit VARCHAR(10) DEFAULT 'kg' CHECK (weight_unit IN ('kg', 'gram', 'pound', 'ounce')),
    dimensions JSONB, -- Length, width, height
    volume DECIMAL(10,3), -- Product volume
    volume_unit VARCHAR(10) DEFAULT 'liter' CHECK (volume_unit IN ('liter', 'ml', 'gallon', 'quart')),
    
    -- Shipping information
    requires_shipping BOOLEAN DEFAULT TRUE,
    shipping_class VARCHAR(50), -- Standard, express, fragile, etc.
    shipping_weight DECIMAL(8,3), -- Shipping weight (may differ from product weight)
    shipping_dimensions JSONB, -- Shipping dimensions
    
    -- Inventory tracking
    track_inventory BOOLEAN DEFAULT TRUE,
    inventory_location VARCHAR(100), -- Warehouse/location
    serial_numbers TEXT[], -- Serial numbers for tracked items
    batch_number VARCHAR(100), -- Batch/lot number
    expiry_date DATE, -- Expiry date for perishable items
    
    -- Fulfillment information
    fulfillment_status VARCHAR(30) DEFAULT 'pending' CHECK (fulfillment_status IN (
        'pending', 'processing', 'shipped', 'delivered', 'cancelled', 'returned', 'refunded'
    )),
    fulfillment_method VARCHAR(30) DEFAULT 'standard' CHECK (fulfillment_method IN (
        'standard', 'express', 'overnight', 'pickup', 'digital_delivery', 'drop_shipping'
    )),
    fulfillment_date DATE,
    tracking_number VARCHAR(255),
    carrier VARCHAR(100),
    
    -- Return and refund information
    is_returnable BOOLEAN DEFAULT TRUE,
    return_policy VARCHAR(255),
    return_window_days INTEGER DEFAULT 30,
    returned_quantity DECIMAL(10,3) DEFAULT 0 CHECK (returned_quantity >= 0),
    refunded_amount DECIMAL(15,4) DEFAULT 0 CHECK (refunded_amount >= 0),
    
    -- Digital product information
    is_digital BOOLEAN DEFAULT FALSE,
    download_url VARCHAR(500),
    download_limit INTEGER,
    download_expiry TIMESTAMPTZ,
    license_key VARCHAR(255),
    
    -- Subscription information
    is_subscription BOOLEAN DEFAULT FALSE,
    subscription_period VARCHAR(20) CHECK (subscription_period IN (
        'daily', 'weekly', 'monthly', 'quarterly', 'yearly'
    )),
    subscription_cycles INTEGER, -- Number of billing cycles
    subscription_start_date DATE,
    subscription_end_date DATE,
    
    -- Gift card information
    is_gift_card BOOLEAN DEFAULT FALSE,
    gift_card_code VARCHAR(100),
    gift_card_recipient_email VARCHAR(255),
    gift_card_message TEXT,
    gift_card_expiry DATE,
    
    -- Bundle information
    is_bundle BOOLEAN DEFAULT FALSE,
    bundle_id UUID, -- Reference to bundle if exists
    parent_line_item_id UUID REFERENCES invoice_line_items(id), -- For bundle components
    bundle_discount_amount DECIMAL(15,4) DEFAULT 0,
    
    -- Customization and personalization
    is_customized BOOLEAN DEFAULT FALSE,
    customization_details JSONB DEFAULT '{}', -- Custom text, images, etc.
    personalization_cost DECIMAL(15,4) DEFAULT 0,
    
    -- Quality and compliance
    quality_grade VARCHAR(20), -- A, B, C grade for products
    compliance_certifications TEXT[], -- ISO, FDA, etc.
    country_of_origin VARCHAR(2), -- ISO 3166-1 alpha-2
    
    -- Warranty information
    warranty_period_months INTEGER,
    warranty_type VARCHAR(30) CHECK (warranty_type IN (
        'manufacturer', 'extended', 'store', 'none'
    )),
    warranty_terms TEXT,
    
    -- Promotional and marketing
    promotional_tags TEXT[], -- Sale, new, featured, etc.
    marketing_source VARCHAR(100), -- Where customer found product
    affiliate_id VARCHAR(255), -- Affiliate who referred sale
    
    -- Analytics and tracking
    conversion_source VARCHAR(100), -- How this item was added to cart
    recommendation_engine VARCHAR(50), -- Which engine recommended this
    cross_sell_source_item_id UUID, -- Item that led to cross-sell
    upsell_source_item_id UUID, -- Item that led to upsell
    
    -- External integrations
    external_product_id VARCHAR(255), -- External system product ID
    supplier_id VARCHAR(255), -- Supplier identifier
    supplier_sku VARCHAR(100), -- Supplier SKU
    manufacturer_part_number VARCHAR(100),
    
    -- SEO and content
    seo_title VARCHAR(255),
    seo_description TEXT,
    meta_keywords TEXT[],
    product_url VARCHAR(500),
    image_urls TEXT[], -- Product image URLs
    
    -- Localization
    language_code VARCHAR(5) DEFAULT 'en', -- ISO 639-1
    currency_code VARCHAR(3) DEFAULT 'USD', -- ISO 4217
    localized_names JSONB DEFAULT '{}', -- Names in different languages
    localized_descriptions JSONB DEFAULT '{}', -- Descriptions in different languages
    
    -- Performance metrics
    view_count INTEGER DEFAULT 0,
    add_to_cart_count INTEGER DEFAULT 0,
    purchase_count INTEGER DEFAULT 1,
    return_rate DECIMAL(5,4) DEFAULT 0,
    
    -- Data source and quality
    data_source VARCHAR(50) DEFAULT 'manual' CHECK (data_source IN (
        'manual', 'api', 'import', 'pos', 'ecommerce', 'migration'
    )),
    data_quality_score DECIMAL(3,2) CHECK (data_quality_score >= 0 AND data_quality_score <= 1),
    confidence_level VARCHAR(20) DEFAULT 'high' CHECK (confidence_level IN (
        'very_low', 'low', 'medium', 'high', 'very_high'
    )),
    
    -- Sync information
    sync_status VARCHAR(20) DEFAULT 'synced' CHECK (sync_status IN ('pending', 'syncing', 'synced', 'error')),
    last_sync_at TIMESTAMPTZ,
    sync_errors JSONB DEFAULT '[]',
    
    -- Custom fields for extensibility
    custom_fields JSONB DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    UNIQUE(invoice_id, line_item_number),
    CHECK (returned_quantity <= quantity),
    CHECK (refunded_amount <= line_total),
    CHECK (line_discount_amount <= line_subtotal)
);

-- =============================================================================
-- Invoice Line Item History Table
-- =============================================================================
-- Track changes to line items

CREATE TABLE IF NOT EXISTS invoice_line_item_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    line_item_id UUID NOT NULL REFERENCES invoice_line_items(id) ON DELETE CASCADE,
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Change tracking
    change_type VARCHAR(20) NOT NULL CHECK (change_type IN (
        'created', 'updated', 'deleted', 'quantity_changed', 'price_changed', 
        'discount_applied', 'tax_updated', 'fulfilled', 'returned', 'refunded'
    )),
    changed_fields JSONB, -- Array of field names that changed
    old_values JSONB, -- Previous values of changed fields
    new_values JSONB, -- New values of changed fields
    
    -- Change context
    change_reason VARCHAR(255),
    change_source VARCHAR(50) DEFAULT 'manual' CHECK (change_source IN (
        'manual', 'api', 'import', 'system', 'pos', 'ecommerce', 'correction', 'audit'
    )),
    
    -- User context
    changed_by_user_id UUID,
    changed_by_user_type VARCHAR(20) DEFAULT 'admin' CHECK (changed_by_user_type IN (
        'admin', 'system', 'api', 'customer', 'pos_operator'
    )),
    
    -- Session context
    session_id VARCHAR(255),
    request_id VARCHAR(255),
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- Line Item Attributes Table
-- =============================================================================
-- Store additional attributes for line items

CREATE TABLE IF NOT EXISTS invoice_line_item_attributes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    line_item_id UUID NOT NULL REFERENCES invoice_line_items(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Attribute identification
    attribute_name VARCHAR(100) NOT NULL,
    attribute_type VARCHAR(30) DEFAULT 'text' CHECK (attribute_type IN (
        'text', 'number', 'boolean', 'date', 'datetime', 'url', 'email', 'phone', 'json'
    )),
    attribute_group VARCHAR(50), -- Group attributes logically
    
    -- Attribute values
    text_value TEXT,
    number_value DECIMAL(15,4),
    boolean_value BOOLEAN,
    date_value DATE,
    datetime_value TIMESTAMPTZ,
    json_value JSONB,
    
    -- Display and validation
    display_name VARCHAR(255),
    display_order INTEGER DEFAULT 100,
    is_required BOOLEAN DEFAULT FALSE,
    is_visible BOOLEAN DEFAULT TRUE,
    validation_rules JSONB DEFAULT '{}',
    
    -- Localization
    language_code VARCHAR(5) DEFAULT 'en',
    localized_values JSONB DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    UNIQUE(line_item_id, attribute_name, language_code)
);

-- =============================================================================
-- Line Item Bundles Table
-- =============================================================================
-- Track bundle relationships between line items

CREATE TABLE IF NOT EXISTS invoice_line_item_bundles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Bundle identification
    bundle_name VARCHAR(255) NOT NULL,
    bundle_sku VARCHAR(100),
    bundle_type VARCHAR(30) DEFAULT 'fixed' CHECK (bundle_type IN (
        'fixed', 'dynamic', 'configurable', 'recommended'
    )),
    
    -- Bundle pricing
    bundle_price DECIMAL(15,4) NOT NULL CHECK (bundle_price >= 0),
    individual_items_total DECIMAL(15,4) NOT NULL CHECK (individual_items_total >= 0),
    bundle_discount_amount DECIMAL(15,4) GENERATED ALWAYS AS (individual_items_total - bundle_price) STORED,
    bundle_discount_percentage DECIMAL(5,2) GENERATED ALWAYS AS (
        CASE WHEN individual_items_total > 0 
        THEN ((individual_items_total - bundle_price) / individual_items_total) * 100 
        ELSE 0 END
    ) STORED,
    
    -- Bundle configuration
    is_customizable BOOLEAN DEFAULT FALSE,
    min_items INTEGER DEFAULT 1,
    max_items INTEGER,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- Line Item Bundle Components Table
-- =============================================================================
-- Track individual components within bundles

CREATE TABLE IF NOT EXISTS invoice_line_item_bundle_components (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bundle_id UUID NOT NULL REFERENCES invoice_line_item_bundles(id) ON DELETE CASCADE,
    line_item_id UUID NOT NULL REFERENCES invoice_line_items(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Component details
    component_order INTEGER NOT NULL,
    is_required BOOLEAN DEFAULT TRUE,
    is_primary BOOLEAN DEFAULT FALSE, -- Main item in bundle
    
    -- Component pricing
    component_price DECIMAL(15,4) NOT NULL CHECK (component_price >= 0),
    component_discount DECIMAL(15,4) DEFAULT 0 CHECK (component_discount >= 0),
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    UNIQUE(bundle_id, line_item_id)
);

-- =============================================================================
-- Indexes
-- =============================================================================

-- Primary indexes for invoice_line_items
CREATE INDEX IF NOT EXISTS idx_invoice_line_items_invoice_id ON invoice_line_items(invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoice_line_items_store_id ON invoice_line_items(store_id);
CREATE INDEX IF NOT EXISTS idx_invoice_line_items_product_id ON invoice_line_items(product_id);
CREATE INDEX IF NOT EXISTS idx_invoice_line_items_product_sku ON invoice_line_items(product_sku);
CREATE INDEX IF NOT EXISTS idx_invoice_line_items_variant_id ON invoice_line_items(variant_id);
CREATE INDEX IF NOT EXISTS idx_invoice_line_items_category_id ON invoice_line_items(category_id);
CREATE INDEX IF NOT EXISTS idx_invoice_line_items_brand_id ON invoice_line_items(brand_id);
CREATE INDEX IF NOT EXISTS idx_invoice_line_items_fulfillment_status ON invoice_line_items(fulfillment_status);
CREATE INDEX IF NOT EXISTS idx_invoice_line_items_product_type ON invoice_line_items(product_type);
CREATE INDEX IF NOT EXISTS idx_invoice_line_items_is_digital ON invoice_line_items(is_digital);
CREATE INDEX IF NOT EXISTS idx_invoice_line_items_is_subscription ON invoice_line_items(is_subscription);
CREATE INDEX IF NOT EXISTS idx_invoice_line_items_is_bundle ON invoice_line_items(is_bundle);
CREATE INDEX IF NOT EXISTS idx_invoice_line_items_tracking_number ON invoice_line_items(tracking_number);
CREATE INDEX IF NOT EXISTS idx_invoice_line_items_sync_status ON invoice_line_items(sync_status);
CREATE INDEX IF NOT EXISTS idx_invoice_line_items_created_at ON invoice_line_items(created_at DESC);

-- Composite indexes
CREATE INDEX IF NOT EXISTS idx_invoice_line_items_store_product ON invoice_line_items(store_id, product_id);
CREATE INDEX IF NOT EXISTS idx_invoice_line_items_invoice_line_number ON invoice_line_items(invoice_id, line_item_number);
CREATE INDEX IF NOT EXISTS idx_invoice_line_items_fulfillment_date ON invoice_line_items(fulfillment_status, fulfillment_date);
CREATE INDEX IF NOT EXISTS idx_invoice_line_items_pricing ON invoice_line_items(unit_price, line_total, line_discount_amount);
CREATE INDEX IF NOT EXISTS idx_invoice_line_items_quantity_returned ON invoice_line_items(quantity, returned_quantity);
CREATE INDEX IF NOT EXISTS idx_invoice_line_items_subscription_dates ON invoice_line_items(subscription_start_date, subscription_end_date) WHERE is_subscription = TRUE;

-- JSONB indexes
CREATE INDEX IF NOT EXISTS idx_invoice_line_items_variant_attributes ON invoice_line_items USING gin(variant_attributes);
CREATE INDEX IF NOT EXISTS idx_invoice_line_items_dimensions ON invoice_line_items USING gin(dimensions);
CREATE INDEX IF NOT EXISTS idx_invoice_line_items_shipping_dimensions ON invoice_line_items USING gin(shipping_dimensions);
CREATE INDEX IF NOT EXISTS idx_invoice_line_items_customization ON invoice_line_items USING gin(customization_details);
CREATE INDEX IF NOT EXISTS idx_invoice_line_items_localized_names ON invoice_line_items USING gin(localized_names);
CREATE INDEX IF NOT EXISTS idx_invoice_line_items_custom_fields ON invoice_line_items USING gin(custom_fields);
CREATE INDEX IF NOT EXISTS idx_invoice_line_items_sync_errors ON invoice_line_items USING gin(sync_errors);

-- Array indexes
CREATE INDEX IF NOT EXISTS idx_invoice_line_items_serial_numbers ON invoice_line_items USING gin(serial_numbers);
CREATE INDEX IF NOT EXISTS idx_invoice_line_items_promotional_tags ON invoice_line_items USING gin(promotional_tags);
CREATE INDEX IF NOT EXISTS idx_invoice_line_items_compliance_certs ON invoice_line_items USING gin(compliance_certifications);
CREATE INDEX IF NOT EXISTS idx_invoice_line_items_meta_keywords ON invoice_line_items USING gin(meta_keywords);
CREATE INDEX IF NOT EXISTS idx_invoice_line_items_image_urls ON invoice_line_items USING gin(image_urls);

-- History table indexes
CREATE INDEX IF NOT EXISTS idx_invoice_line_item_history_line_item_id ON invoice_line_item_history(line_item_id);
CREATE INDEX IF NOT EXISTS idx_invoice_line_item_history_invoice_id ON invoice_line_item_history(invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoice_line_item_history_store_id ON invoice_line_item_history(store_id);
CREATE INDEX IF NOT EXISTS idx_invoice_line_item_history_change_type ON invoice_line_item_history(change_type);
CREATE INDEX IF NOT EXISTS idx_invoice_line_item_history_change_source ON invoice_line_item_history(change_source);
CREATE INDEX IF NOT EXISTS idx_invoice_line_item_history_created_at ON invoice_line_item_history(created_at DESC);

-- Attributes table indexes
CREATE INDEX IF NOT EXISTS idx_invoice_line_item_attributes_line_item_id ON invoice_line_item_attributes(line_item_id);
CREATE INDEX IF NOT EXISTS idx_invoice_line_item_attributes_store_id ON invoice_line_item_attributes(store_id);
CREATE INDEX IF NOT EXISTS idx_invoice_line_item_attributes_name ON invoice_line_item_attributes(attribute_name);
CREATE INDEX IF NOT EXISTS idx_invoice_line_item_attributes_type ON invoice_line_item_attributes(attribute_type);
CREATE INDEX IF NOT EXISTS idx_invoice_line_item_attributes_group ON invoice_line_item_attributes(attribute_group);

-- Bundle indexes
CREATE INDEX IF NOT EXISTS idx_invoice_line_item_bundles_invoice_id ON invoice_line_item_bundles(invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoice_line_item_bundles_store_id ON invoice_line_item_bundles(store_id);
CREATE INDEX IF NOT EXISTS idx_invoice_line_item_bundles_sku ON invoice_line_item_bundles(bundle_sku);
CREATE INDEX IF NOT EXISTS idx_invoice_line_item_bundle_components_bundle_id ON invoice_line_item_bundle_components(bundle_id);
CREATE INDEX IF NOT EXISTS idx_invoice_line_item_bundle_components_line_item_id ON invoice_line_item_bundle_components(line_item_id);

-- =============================================================================
-- Triggers
-- =============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_invoice_line_items_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_invoice_line_items_updated_at
    BEFORE UPDATE ON invoice_line_items
    FOR EACH ROW
    EXECUTE FUNCTION update_invoice_line_items_updated_at();

CREATE TRIGGER trigger_update_invoice_line_item_attributes_updated_at
    BEFORE UPDATE ON invoice_line_item_attributes
    FOR EACH ROW
    EXECUTE FUNCTION update_invoice_line_items_updated_at();

CREATE TRIGGER trigger_update_invoice_line_item_bundles_updated_at
    BEFORE UPDATE ON invoice_line_item_bundles
    FOR EACH ROW
    EXECUTE FUNCTION update_invoice_line_items_updated_at();

-- Track line item changes in history
CREATE OR REPLACE FUNCTION track_invoice_line_item_changes()
RETURNS TRIGGER AS $$
DECLARE
    v_changed_fields TEXT[];
    v_old_values JSONB;
    v_new_values JSONB;
    v_change_type VARCHAR(20);
BEGIN
    IF TG_OP = 'INSERT' THEN
        v_change_type := 'created';
        INSERT INTO invoice_line_item_history (
            line_item_id, invoice_id, store_id, change_type,
            new_values, created_at
        ) VALUES (
            NEW.id, NEW.invoice_id, NEW.store_id, v_change_type,
            to_jsonb(NEW), CURRENT_TIMESTAMP
        );
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        -- Determine specific change type
        IF OLD.quantity != NEW.quantity THEN
            v_change_type := 'quantity_changed';
        ELSIF OLD.unit_price != NEW.unit_price THEN
            v_change_type := 'price_changed';
        ELSIF OLD.line_discount_amount != NEW.line_discount_amount THEN
            v_change_type := 'discount_applied';
        ELSIF OLD.line_tax_amount != NEW.line_tax_amount THEN
            v_change_type := 'tax_updated';
        ELSIF OLD.fulfillment_status != NEW.fulfillment_status THEN
            v_change_type := 'fulfilled';
        ELSIF OLD.returned_quantity != NEW.returned_quantity THEN
            v_change_type := 'returned';
        ELSIF OLD.refunded_amount != NEW.refunded_amount THEN
            v_change_type := 'refunded';
        ELSE
            v_change_type := 'updated';
        END IF;
        
        -- Detect changed fields
        SELECT array_agg(key), 
               jsonb_object_agg(key, old_value),
               jsonb_object_agg(key, new_value)
        INTO v_changed_fields, v_old_values, v_new_values
        FROM (
            SELECT key, 
                   old_record.value as old_value,
                   new_record.value as new_value
            FROM jsonb_each(to_jsonb(OLD)) old_record
            JOIN jsonb_each(to_jsonb(NEW)) new_record ON old_record.key = new_record.key
            WHERE old_record.value IS DISTINCT FROM new_record.value
            AND old_record.key NOT IN ('updated_at', 'last_sync_at')
        ) changes;
        
        IF array_length(v_changed_fields, 1) > 0 THEN
            INSERT INTO invoice_line_item_history (
                line_item_id, invoice_id, store_id, change_type,
                changed_fields, old_values, new_values, created_at
            ) VALUES (
                NEW.id, NEW.invoice_id, NEW.store_id, v_change_type,
                v_changed_fields, v_old_values, v_new_values, CURRENT_TIMESTAMP
            );
        END IF;
        
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO invoice_line_item_history (
            line_item_id, invoice_id, store_id, change_type,
            old_values, created_at
        ) VALUES (
            OLD.id, OLD.invoice_id, OLD.store_id, 'deleted',
            to_jsonb(OLD), CURRENT_TIMESTAMP
        );
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_track_invoice_line_item_changes
    AFTER INSERT OR UPDATE OR DELETE ON invoice_line_items
    FOR EACH ROW
    EXECUTE FUNCTION track_invoice_line_item_changes();

-- Validate line item data
CREATE OR REPLACE FUNCTION validate_line_item_data()
RETURNS TRIGGER AS $$
BEGIN
    -- Validate quantity and returns
    IF NEW.returned_quantity > NEW.quantity THEN
        RAISE EXCEPTION 'Returned quantity (%) cannot exceed ordered quantity (%)', 
            NEW.returned_quantity, NEW.quantity;
    END IF;
    
    -- Validate refund amount
    IF NEW.refunded_amount > NEW.line_total THEN
        RAISE EXCEPTION 'Refunded amount (%) cannot exceed line total (%)', 
            NEW.refunded_amount, NEW.line_total;
    END IF;
    
    -- Validate discount amount
    IF NEW.line_discount_amount > NEW.line_subtotal THEN
        RAISE EXCEPTION 'Discount amount (%) cannot exceed line subtotal (%)', 
            NEW.line_discount_amount, NEW.line_subtotal;
    END IF;
    
    -- Validate subscription dates
    IF NEW.is_subscription = TRUE THEN
        IF NEW.subscription_start_date IS NULL THEN
            RAISE EXCEPTION 'Subscription start date is required for subscription items';
        END IF;
        
        IF NEW.subscription_end_date IS NOT NULL AND NEW.subscription_end_date <= NEW.subscription_start_date THEN
            RAISE EXCEPTION 'Subscription end date must be after start date';
        END IF;
    END IF;
    
    -- Validate digital product requirements
    IF NEW.is_digital = TRUE AND NEW.requires_shipping = TRUE THEN
        NEW.requires_shipping := FALSE;
    END IF;
    
    -- Validate gift card requirements
    IF NEW.is_gift_card = TRUE THEN
        IF NEW.gift_card_code IS NULL THEN
            NEW.gift_card_code := 'GC-' || UPPER(SUBSTRING(gen_random_uuid()::text, 1, 8));
        END IF;
    END IF;
    
    -- Auto-set fulfillment date when status changes to delivered
    IF NEW.fulfillment_status = 'delivered' AND OLD.fulfillment_status != 'delivered' THEN
        NEW.fulfillment_date := CURRENT_DATE;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validate_line_item_data
    BEFORE INSERT OR UPDATE ON invoice_line_items
    FOR EACH ROW
    EXECUTE FUNCTION validate_line_item_data();

-- Update invoice totals when line items change
CREATE OR REPLACE FUNCTION update_invoice_totals_from_line_items()
RETURNS TRIGGER AS $$
DECLARE
    v_invoice_id UUID;
    v_subtotal DECIMAL(15,4);
    v_discount_total DECIMAL(15,4);
    v_tax_total DECIMAL(15,4);
    v_total DECIMAL(15,4);
BEGIN
    -- Get invoice ID from the operation
    IF TG_OP = 'DELETE' THEN
        v_invoice_id := OLD.invoice_id;
    ELSE
        v_invoice_id := NEW.invoice_id;
    END IF;
    
    -- Calculate totals from line items
    SELECT 
        COALESCE(SUM(line_subtotal), 0),
        COALESCE(SUM(line_discount_amount), 0),
        COALESCE(SUM(line_tax_amount), 0),
        COALESCE(SUM(line_total), 0)
    INTO v_subtotal, v_discount_total, v_tax_total, v_total
    FROM invoice_line_items
    WHERE invoice_id = v_invoice_id;
    
    -- Update invoice totals
    UPDATE invoices
    SET 
        subtotal = v_subtotal,
        discount_total = v_discount_total,
        tax_total = v_tax_total,
        total = v_total,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = v_invoice_id;
    
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_invoice_totals_from_line_items
    AFTER INSERT OR UPDATE OR DELETE ON invoice_line_items
    FOR EACH ROW
    EXECUTE FUNCTION update_invoice_totals_from_line_items();

-- =============================================================================
-- Helper Functions
-- =============================================================================

/**
 * Get invoice line items with complete details
 * @param p_invoice_id UUID - Invoice ID
 * @return JSONB - Complete line items data
 */
CREATE OR REPLACE FUNCTION get_invoice_line_items(
    p_invoice_id UUID
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'line_items', jsonb_agg(
            jsonb_build_object(
                'id', ili.id,
                'line_item_number', ili.line_item_number,
                'product_sku', ili.product_sku,
                'product_name', ili.product_name,
                'variant_name', ili.variant_name,
                'quantity', ili.quantity,
                'unit_price', ili.unit_price,
                'line_subtotal', ili.line_subtotal,
                'line_discount_amount', ili.line_discount_amount,
                'line_tax_amount', ili.line_tax_amount,
                'line_total', ili.line_total,
                'fulfillment_status', ili.fulfillment_status,
                'product_type', ili.product_type,
                'is_digital', ili.is_digital,
                'is_subscription', ili.is_subscription,
                'is_bundle', ili.is_bundle,
                'attributes', COALESCE(attrs.attributes, '[]'::jsonb)
            )
            ORDER BY ili.line_item_number
        ),
        'line_items_summary', jsonb_build_object(
            'total_items', COUNT(*),
            'total_quantity', COALESCE(SUM(ili.quantity), 0),
            'total_subtotal', COALESCE(SUM(ili.line_subtotal), 0),
            'total_discount', COALESCE(SUM(ili.line_discount_amount), 0),
            'total_tax', COALESCE(SUM(ili.line_tax_amount), 0),
            'total_amount', COALESCE(SUM(ili.line_total), 0),
            'digital_items', COUNT(*) FILTER (WHERE ili.is_digital = TRUE),
            'physical_items', COUNT(*) FILTER (WHERE ili.is_digital = FALSE),
            'subscription_items', COUNT(*) FILTER (WHERE ili.is_subscription = TRUE),
            'bundle_items', COUNT(*) FILTER (WHERE ili.is_bundle = TRUE)
        )
    ) INTO result
    FROM invoice_line_items ili
    LEFT JOIN (
        SELECT 
            line_item_id,
            jsonb_agg(
                jsonb_build_object(
                    'name', attribute_name,
                    'value', COALESCE(text_value, number_value::text, boolean_value::text, date_value::text)
                )
            ) as attributes
        FROM invoice_line_item_attributes
        GROUP BY line_item_id
    ) attrs ON attrs.line_item_id = ili.id
    WHERE ili.invoice_id = p_invoice_id;
    
    RETURN COALESCE(result, '{"line_items": [], "line_items_summary": {"total_items": 0}}'::jsonb);
END;
$$ LANGUAGE plpgsql;

/**
 * Search line items with filters
 * @param p_store_id UUID - Store ID
 * @param p_filters JSONB - Search filters
 * @param p_limit INTEGER - Result limit
 * @param p_offset INTEGER - Result offset
 * @return JSONB - Search results
 */
CREATE OR REPLACE FUNCTION search_invoice_line_items(
    p_store_id UUID,
    p_filters JSONB DEFAULT '{}',
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS JSONB AS $$
DECLARE
    v_where_clause TEXT := 'WHERE ili.store_id = $1';
    v_params TEXT[];
    v_param_count INTEGER := 1;
    result JSONB;
BEGIN
    -- Build dynamic WHERE clause based on filters
    IF p_filters ? 'product_name' THEN
        v_param_count := v_param_count + 1;
        v_where_clause := v_where_clause || ' AND ili.product_name ILIKE $' || v_param_count;
        v_params := array_append(v_params, '%' || (p_filters->>'product_name') || '%');
    END IF;
    
    IF p_filters ? 'product_sku' THEN
        v_param_count := v_param_count + 1;
        v_where_clause := v_where_clause || ' AND ili.product_sku = $' || v_param_count;
        v_params := array_append(v_params, p_filters->>'product_sku');
    END IF;
    
    IF p_filters ? 'fulfillment_status' THEN
        v_param_count := v_param_count + 1;
        v_where_clause := v_where_clause || ' AND ili.fulfillment_status = $' || v_param_count;
        v_params := array_append(v_params, p_filters->>'fulfillment_status');
    END IF;
    
    IF p_filters ? 'product_type' THEN
        v_param_count := v_param_count + 1;
        v_where_clause := v_where_clause || ' AND ili.product_type = $' || v_param_count;
        v_params := array_append(v_params, p_filters->>'product_type');
    END IF;
    
    IF p_filters ? 'date_from' THEN
        v_param_count := v_param_count + 1;
        v_where_clause := v_where_clause || ' AND ili.created_at >= $' || v_param_count;
        v_params := array_append(v_params, p_filters->>'date_from');
    END IF;
    
    IF p_filters ? 'date_to' THEN
        v_param_count := v_param_count + 1;
        v_where_clause := v_where_clause || ' AND ili.created_at <= $' || v_param_count;
        v_params := array_append(v_params, p_filters->>'date_to');
    END IF;
    
    -- Execute dynamic query
    EXECUTE format('
        SELECT jsonb_build_object(
            ''line_items'', jsonb_agg(
                jsonb_build_object(
                    ''id'', ili.id,
                    ''invoice_id'', ili.invoice_id,
                    ''line_item_number'', ili.line_item_number,
                    ''product_sku'', ili.product_sku,
                    ''product_name'', ili.product_name,
                    ''quantity'', ili.quantity,
                    ''unit_price'', ili.unit_price,
                    ''line_total'', ili.line_total,
                    ''fulfillment_status'', ili.fulfillment_status,
                    ''product_type'', ili.product_type,
                    ''created_at'', ili.created_at
                )
                ORDER BY ili.created_at DESC
            ),
            ''total_count'', COUNT(*) OVER(),
            ''has_more'', COUNT(*) OVER() > $%s + $%s
        )
        FROM invoice_line_items ili
        %s
        ORDER BY ili.created_at DESC
        LIMIT $%s OFFSET $%s',
        v_param_count + 1, v_param_count + 2, v_where_clause, v_param_count + 1, v_param_count + 2
    ) INTO result
    USING p_store_id, VARIADIC v_params, p_limit, p_offset;
    
    RETURN COALESCE(result, '{"line_items": [], "total_count": 0, "has_more": false}'::jsonb);
END;
$$ LANGUAGE plpgsql;

/**
 * Get line item analytics for store
 * @param p_store_id UUID - Store ID
 * @param p_start_date DATE - Start date
 * @param p_end_date DATE - End date
 * @return JSONB - Analytics data
 */
CREATE OR REPLACE FUNCTION get_line_item_analytics(
    p_store_id UUID,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'period', jsonb_build_object(
            'start_date', COALESCE(p_start_date, DATE_TRUNC('month', CURRENT_DATE)),
            'end_date', COALESCE(p_end_date, CURRENT_DATE)
        ),
        'summary', jsonb_build_object(
            'total_line_items', COUNT(*),
            'total_quantity_sold', COALESCE(SUM(ili.quantity), 0),
            'total_revenue', COALESCE(SUM(ili.line_total), 0),
            'average_unit_price', COALESCE(AVG(ili.unit_price), 0),
            'average_line_value', COALESCE(AVG(ili.line_total), 0)
        ),
        'by_product_type', (
            SELECT jsonb_object_agg(product_type, type_data)
            FROM (
                SELECT 
                    ili.product_type,
                    jsonb_build_object(
                        'count', COUNT(*),
                        'quantity', SUM(ili.quantity),
                        'revenue', SUM(ili.line_total),
                        'avg_price', AVG(ili.unit_price)
                    ) as type_data
                FROM invoice_line_items ili
                JOIN invoices i ON i.id = ili.invoice_id
                WHERE ili.store_id = p_store_id
                AND (p_start_date IS NULL OR i.invoice_date >= p_start_date)
                AND (p_end_date IS NULL OR i.invoice_date <= p_end_date)
                GROUP BY ili.product_type
            ) product_types
        ),
        'top_products', (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'product_sku', product_sku,
                    'product_name', product_name,
                    'quantity_sold', quantity_sold,
                    'revenue', revenue,
                    'avg_price', avg_price
                )
                ORDER BY quantity_sold DESC
            )
            FROM (
                SELECT 
                    ili.product_sku,
                    ili.product_name,
                    SUM(ili.quantity) as quantity_sold,
                    SUM(ili.line_total) as revenue,
                    AVG(ili.unit_price) as avg_price
                FROM invoice_line_items ili
                JOIN invoices i ON i.id = ili.invoice_id
                WHERE ili.store_id = p_store_id
                AND (p_start_date IS NULL OR i.invoice_date >= p_start_date)
                AND (p_end_date IS NULL OR i.invoice_date <= p_end_date)
                GROUP BY ili.product_sku, ili.product_name
                ORDER BY SUM(ili.quantity) DESC
                LIMIT 10
            ) top_products
        ),
        'fulfillment_status', jsonb_build_object(
            'pending', COUNT(*) FILTER (WHERE ili.fulfillment_status = 'pending'),
            'processing', COUNT(*) FILTER (WHERE ili.fulfillment_status = 'processing'),
            'shipped', COUNT(*) FILTER (WHERE ili.fulfillment_status = 'shipped'),
            'delivered', COUNT(*) FILTER (WHERE ili.fulfillment_status = 'delivered'),
            'returned', COUNT(*) FILTER (WHERE ili.fulfillment_status = 'returned')
        ),
        'returns_and_refunds', jsonb_build_object(
            'returned_items', COUNT(*) FILTER (WHERE ili.returned_quantity > 0),
            'total_returned_quantity', COALESCE(SUM(ili.returned_quantity), 0),
            'total_refunded_amount', COALESCE(SUM(ili.refunded_amount), 0),
            'return_rate', CASE 
                WHEN COUNT(*) > 0 THEN (COUNT(*) FILTER (WHERE ili.returned_quantity > 0))::DECIMAL / COUNT(*) * 100
                ELSE 0 
            END
        )
    ) INTO result
    FROM invoice_line_items ili
    JOIN invoices i ON i.id = ili.invoice_id
    WHERE ili.store_id = p_store_id
    AND (p_start_date IS NULL OR i.invoice_date >= p_start_date)
    AND (p_end_date IS NULL OR i.invoice_date <= p_end_date);
    
    RETURN COALESCE(result, '{"error": "No line item data found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Comments
-- =============================================================================

COMMENT ON TABLE invoice_line_items IS 'Normalized line items for invoices with comprehensive product and fulfillment information';
COMMENT ON TABLE invoice_line_item_history IS 'Track changes to invoice line items';
COMMENT ON TABLE invoice_line_item_attributes IS 'Additional attributes for line items';
COMMENT ON TABLE invoice_line_item_bundles IS 'Bundle information for grouped line items';
COMMENT ON TABLE invoice_line_item_bundle_components IS 'Individual components within bundles';

COMMENT ON COLUMN invoice_line_items.line_subtotal IS 'Calculated as quantity * unit_price';
COMMENT ON COLUMN invoice_line_items.line_total IS 'Calculated as line_subtotal - line_discount_amount + line_tax_amount';
COMMENT ON COLUMN invoice_line_items.gross_margin IS 'Calculated as line_subtotal - (quantity * cost_price)';
COMMENT ON COLUMN invoice_line_items.variant_attributes IS 'JSON object containing variant attributes like size, color, etc.';
COMMENT ON COLUMN invoice_line_items.customization_details IS 'JSON object containing customization details';

COMMENT ON FUNCTION get_invoice_line_items(UUID) IS 'Get complete line items data with attributes for invoice';
COMMENT ON FUNCTION search_invoice_line_items(UUID, JSONB, INTEGER, INTEGER) IS 'Search line items with dynamic filters';
COMMENT ON FUNCTION get_line_item_analytics(UUID, DATE, DATE) IS 'Generate line item analytics report for store';