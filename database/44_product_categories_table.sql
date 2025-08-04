-- =============================================================================
-- Product Categories Table
-- =============================================================================
-- This table stores product-category relationships separately from the main products table
-- Normalizes the 'category_ids' JSONB column from products table

CREATE TABLE IF NOT EXISTS product_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Relationship properties
    is_primary BOOLEAN DEFAULT FALSE,
    sort_order INTEGER DEFAULT 0,
    
    -- Category assignment details
    assignment_type VARCHAR(20) DEFAULT 'manual' CHECK (assignment_type IN (
        'manual', 'automatic', 'inherited', 'suggested', 'bulk_assigned'
    )),
    assignment_source VARCHAR(100), -- Source of automatic assignment
    confidence_score DECIMAL(3,2) DEFAULT 1.0 CHECK (confidence_score >= 0 AND confidence_score <= 1),
    
    -- Display and visibility
    is_visible BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    display_priority INTEGER DEFAULT 0,
    
    -- SEO and marketing
    affects_seo BOOLEAN DEFAULT TRUE,
    seo_weight DECIMAL(3,2) DEFAULT 1.0 CHECK (seo_weight >= 0 AND seo_weight <= 10),
    
    -- Performance tracking
    click_count INTEGER DEFAULT 0,
    view_count INTEGER DEFAULT 0,
    conversion_count INTEGER DEFAULT 0,
    last_interaction_at TIMESTAMPTZ,
    
    -- Analytics data
    performance_score DECIMAL(5,2) DEFAULT 0,
    bounce_rate DECIMAL(5,2) DEFAULT 0,
    avg_time_on_page INTEGER DEFAULT 0, -- in seconds
    
    -- A/B testing
    test_group VARCHAR(50),
    test_variant VARCHAR(50),
    
    -- External references
    external_category_id VARCHAR(255),
    source_system VARCHAR(100),
    
    -- Sync information
    sync_status VARCHAR(20) DEFAULT 'synced' CHECK (sync_status IN ('pending', 'syncing', 'synced', 'error')),
    last_sync_at TIMESTAMPTZ,
    sync_errors JSONB DEFAULT '[]',
    
    -- Custom fields
    custom_fields JSONB DEFAULT '{}',
    tags JSONB DEFAULT '[]',
    
    -- Timestamps
    assigned_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT product_categories_unique_assignment UNIQUE (product_id, category_id),
    CONSTRAINT product_categories_sort_order_check CHECK (sort_order >= 0),
    CONSTRAINT product_categories_display_priority_check CHECK (display_priority >= 0)
);

-- =============================================================================
-- Product Category History Table
-- =============================================================================
-- This table tracks changes to product-category assignments for auditing

CREATE TABLE IF NOT EXISTS product_category_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL,
    category_id UUID NOT NULL,
    store_id UUID NOT NULL,
    
    -- Change information
    action_type VARCHAR(20) NOT NULL CHECK (action_type IN ('assigned', 'unassigned', 'updated')),
    old_values JSONB DEFAULT '{}',
    new_values JSONB DEFAULT '{}',
    change_reason VARCHAR(255),
    
    -- Assignment details at time of change
    was_primary BOOLEAN,
    assignment_type VARCHAR(20),
    confidence_score DECIMAL(3,2),
    
    -- Change context
    changed_by_user_id UUID,
    changed_by_system VARCHAR(100),
    ip_address INET,
    user_agent TEXT,
    
    -- Timestamps
    changed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- Product Category Rules Table
-- =============================================================================
-- This table stores automatic categorization rules

CREATE TABLE IF NOT EXISTS product_category_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Rule information
    rule_name VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Rule conditions
    conditions JSONB NOT NULL, -- {"field": "name", "operator": "contains", "value": "laptop"}
    target_category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    
    -- Rule properties
    is_active BOOLEAN DEFAULT TRUE,
    priority INTEGER DEFAULT 0,
    confidence_score DECIMAL(3,2) DEFAULT 0.8,
    
    -- Rule execution
    execution_mode VARCHAR(20) DEFAULT 'automatic' CHECK (execution_mode IN (
        'automatic', 'manual', 'suggestion_only'
    )),
    
    -- Performance tracking
    matches_count INTEGER DEFAULT 0,
    success_rate DECIMAL(5,2) DEFAULT 0,
    last_executed_at TIMESTAMPTZ,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT product_category_rules_unique_name UNIQUE (store_id, rule_name),
    CONSTRAINT product_category_rules_priority_check CHECK (priority >= 0)
);

-- =============================================================================
-- Indexes
-- =============================================================================

-- Product Categories Indexes
CREATE INDEX IF NOT EXISTS idx_product_categories_product_id ON product_categories(product_id);
CREATE INDEX IF NOT EXISTS idx_product_categories_category_id ON product_categories(category_id);
CREATE INDEX IF NOT EXISTS idx_product_categories_store_id ON product_categories(store_id);

-- Relationship properties
CREATE INDEX IF NOT EXISTS idx_product_categories_is_primary ON product_categories(is_primary);
CREATE INDEX IF NOT EXISTS idx_product_categories_sort_order ON product_categories(sort_order);
CREATE INDEX IF NOT EXISTS idx_product_categories_assignment_type ON product_categories(assignment_type);
CREATE INDEX IF NOT EXISTS idx_product_categories_confidence_score ON product_categories(confidence_score DESC);

-- Display and visibility
CREATE INDEX IF NOT EXISTS idx_product_categories_is_visible ON product_categories(is_visible);
CREATE INDEX IF NOT EXISTS idx_product_categories_is_featured ON product_categories(is_featured);
CREATE INDEX IF NOT EXISTS idx_product_categories_display_priority ON product_categories(display_priority DESC);

-- SEO indexes
CREATE INDEX IF NOT EXISTS idx_product_categories_affects_seo ON product_categories(affects_seo);
CREATE INDEX IF NOT EXISTS idx_product_categories_seo_weight ON product_categories(seo_weight DESC);

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_product_categories_click_count ON product_categories(click_count DESC);
CREATE INDEX IF NOT EXISTS idx_product_categories_view_count ON product_categories(view_count DESC);
CREATE INDEX IF NOT EXISTS idx_product_categories_conversion_count ON product_categories(conversion_count DESC);
CREATE INDEX IF NOT EXISTS idx_product_categories_performance_score ON product_categories(performance_score DESC);
CREATE INDEX IF NOT EXISTS idx_product_categories_last_interaction ON product_categories(last_interaction_at DESC);

-- A/B testing indexes
CREATE INDEX IF NOT EXISTS idx_product_categories_test_group ON product_categories(test_group);
CREATE INDEX IF NOT EXISTS idx_product_categories_test_variant ON product_categories(test_variant);

-- External references
CREATE INDEX IF NOT EXISTS idx_product_categories_external_id ON product_categories(external_category_id);
CREATE INDEX IF NOT EXISTS idx_product_categories_source_system ON product_categories(source_system);

-- Sync indexes
CREATE INDEX IF NOT EXISTS idx_product_categories_sync_status ON product_categories(sync_status);
CREATE INDEX IF NOT EXISTS idx_product_categories_last_sync_at ON product_categories(last_sync_at);

-- JSONB indexes
CREATE INDEX IF NOT EXISTS idx_product_categories_custom_fields ON product_categories USING gin(custom_fields);
CREATE INDEX IF NOT EXISTS idx_product_categories_tags ON product_categories USING gin(tags);
CREATE INDEX IF NOT EXISTS idx_product_categories_sync_errors ON product_categories USING gin(sync_errors);

-- Composite indexes
CREATE INDEX IF NOT EXISTS idx_product_categories_primary_visible ON product_categories(product_id, is_primary, is_visible) WHERE is_primary = TRUE AND is_visible = TRUE;
CREATE INDEX IF NOT EXISTS idx_product_categories_featured_priority ON product_categories(category_id, is_featured, display_priority) WHERE is_featured = TRUE;
CREATE INDEX IF NOT EXISTS idx_product_categories_product_sort ON product_categories(product_id, sort_order, is_visible) WHERE is_visible = TRUE;
CREATE INDEX IF NOT EXISTS idx_product_categories_category_performance ON product_categories(category_id, performance_score DESC, is_visible) WHERE is_visible = TRUE;

-- Product Category History Indexes
CREATE INDEX IF NOT EXISTS idx_product_category_history_product_id ON product_category_history(product_id);
CREATE INDEX IF NOT EXISTS idx_product_category_history_category_id ON product_category_history(category_id);
CREATE INDEX IF NOT EXISTS idx_product_category_history_store_id ON product_category_history(store_id);
CREATE INDEX IF NOT EXISTS idx_product_category_history_action_type ON product_category_history(action_type);
CREATE INDEX IF NOT EXISTS idx_product_category_history_changed_at ON product_category_history(changed_at DESC);
CREATE INDEX IF NOT EXISTS idx_product_category_history_changed_by_user ON product_category_history(changed_by_user_id);

-- Product Category Rules Indexes
CREATE INDEX IF NOT EXISTS idx_product_category_rules_store_id ON product_category_rules(store_id);
CREATE INDEX IF NOT EXISTS idx_product_category_rules_target_category ON product_category_rules(target_category_id);
CREATE INDEX IF NOT EXISTS idx_product_category_rules_is_active ON product_category_rules(is_active);
CREATE INDEX IF NOT EXISTS idx_product_category_rules_priority ON product_category_rules(priority DESC);
CREATE INDEX IF NOT EXISTS idx_product_category_rules_execution_mode ON product_category_rules(execution_mode);
CREATE INDEX IF NOT EXISTS idx_product_category_rules_success_rate ON product_category_rules(success_rate DESC);
CREATE INDEX IF NOT EXISTS idx_product_category_rules_conditions ON product_category_rules USING gin(conditions);

-- =============================================================================
-- Triggers
-- =============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_product_categories_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_product_categories_updated_at
    BEFORE UPDATE ON product_categories
    FOR EACH ROW
    EXECUTE FUNCTION update_product_categories_updated_at();

-- Auto-update updated_at timestamp for rules
CREATE OR REPLACE FUNCTION update_product_category_rules_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_product_category_rules_updated_at
    BEFORE UPDATE ON product_category_rules
    FOR EACH ROW
    EXECUTE FUNCTION update_product_category_rules_updated_at();

-- Ensure only one primary category per product
CREATE OR REPLACE FUNCTION enforce_single_primary_category()
RETURNS TRIGGER AS $$
BEGIN
    -- If setting a category as primary, unset others
    IF NEW.is_primary = TRUE THEN
        UPDATE product_categories
        SET is_primary = FALSE,
            updated_at = CURRENT_TIMESTAMP
        WHERE product_id = NEW.product_id
          AND category_id != NEW.category_id
          AND is_primary = TRUE;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_enforce_single_primary_category
    AFTER INSERT OR UPDATE ON product_categories
    FOR EACH ROW
    WHEN (NEW.is_primary = TRUE)
    EXECUTE FUNCTION enforce_single_primary_category();

-- Track category assignment changes
CREATE OR REPLACE FUNCTION track_category_assignment_changes()
RETURNS TRIGGER AS $$
DECLARE
    action_type_val VARCHAR(20);
    old_vals JSONB := '{}';
    new_vals JSONB := '{}';
BEGIN
    -- Determine action type
    IF TG_OP = 'INSERT' THEN
        action_type_val := 'assigned';
        new_vals := to_jsonb(NEW);
    ELSIF TG_OP = 'UPDATE' THEN
        action_type_val := 'updated';
        old_vals := to_jsonb(OLD);
        new_vals := to_jsonb(NEW);
    ELSIF TG_OP = 'DELETE' THEN
        action_type_val := 'unassigned';
        old_vals := to_jsonb(OLD);
    END IF;
    
    -- Insert history record
    INSERT INTO product_category_history (
        product_id,
        category_id,
        store_id,
        action_type,
        old_values,
        new_values,
        was_primary,
        assignment_type,
        confidence_score,
        changed_by_system
    ) VALUES (
        COALESCE(NEW.product_id, OLD.product_id),
        COALESCE(NEW.category_id, OLD.category_id),
        COALESCE(NEW.store_id, OLD.store_id),
        action_type_val,
        old_vals,
        new_vals,
        COALESCE(NEW.is_primary, OLD.is_primary),
        COALESCE(NEW.assignment_type, OLD.assignment_type),
        COALESCE(NEW.confidence_score, OLD.confidence_score),
        'system'
    );
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_track_category_assignment_changes
    AFTER INSERT OR UPDATE OR DELETE ON product_categories
    FOR EACH ROW
    EXECUTE FUNCTION track_category_assignment_changes();

-- Update performance score based on metrics
CREATE OR REPLACE FUNCTION update_category_performance_score()
RETURNS TRIGGER AS $$
BEGIN
    -- Calculate performance score based on various metrics
    NEW.performance_score := (
        (NEW.click_count * 0.3) +
        (NEW.view_count * 0.2) +
        (NEW.conversion_count * 0.5)
    ) / GREATEST(1, NEW.view_count) * 100;
    
    -- Update last interaction timestamp if any metric changed
    IF (NEW.click_count != OLD.click_count OR 
        NEW.view_count != OLD.view_count OR 
        NEW.conversion_count != OLD.conversion_count) THEN
        NEW.last_interaction_at := CURRENT_TIMESTAMP;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_category_performance_score
    BEFORE UPDATE ON product_categories
    FOR EACH ROW
    WHEN (NEW.click_count != OLD.click_count OR 
          NEW.view_count != OLD.view_count OR 
          NEW.conversion_count != OLD.conversion_count)
    EXECUTE FUNCTION update_category_performance_score();

-- =============================================================================
-- Helper Functions
-- =============================================================================

/**
 * Get all categories for a specific product
 * @param p_product_id UUID - Product ID
 * @param p_visible_only BOOLEAN - Whether to return only visible categories
 * @return TABLE - Product categories
 */
CREATE OR REPLACE FUNCTION get_product_categories(
    p_product_id UUID,
    p_visible_only BOOLEAN DEFAULT TRUE
)
RETURNS TABLE (
    category_id UUID,
    category_name VARCHAR,
    is_primary BOOLEAN,
    sort_order INTEGER,
    assignment_type VARCHAR,
    confidence_score DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pc.category_id,
        c.name as category_name,
        pc.is_primary,
        pc.sort_order,
        pc.assignment_type,
        pc.confidence_score
    FROM product_categories pc
    JOIN categories c ON c.id = pc.category_id
    WHERE pc.product_id = p_product_id
      AND (NOT p_visible_only OR pc.is_visible = TRUE)
    ORDER BY pc.is_primary DESC, pc.sort_order ASC, c.name ASC;
END;
$$ LANGUAGE plpgsql;

/**
 * Get primary category for a product
 * @param p_product_id UUID - Product ID
 * @return UUID - Primary category ID
 */
CREATE OR REPLACE FUNCTION get_primary_category(
    p_product_id UUID
)
RETURNS UUID AS $$
DECLARE
    primary_category_id UUID;
BEGIN
    SELECT pc.category_id INTO primary_category_id
    FROM product_categories pc
    WHERE pc.product_id = p_product_id
      AND pc.is_primary = TRUE
      AND pc.is_visible = TRUE
    LIMIT 1;
    
    RETURN primary_category_id;
END;
$$ LANGUAGE plpgsql;

/**
 * Assign product to category
 * @param p_product_id UUID - Product ID
 * @param p_category_id UUID - Category ID
 * @param p_is_primary BOOLEAN - Whether this is the primary category
 * @param p_assignment_type VARCHAR - Type of assignment
 * @return BOOLEAN - Success status
 */
CREATE OR REPLACE FUNCTION assign_product_to_category(
    p_product_id UUID,
    p_category_id UUID,
    p_is_primary BOOLEAN DEFAULT FALSE,
    p_assignment_type VARCHAR DEFAULT 'manual'
)
RETURNS BOOLEAN AS $$
DECLARE
    store_id_val UUID;
    max_sort_order INTEGER;
BEGIN
    -- Get store_id from product
    SELECT store_id INTO store_id_val
    FROM products
    WHERE id = p_product_id;
    
    IF store_id_val IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Get next sort order
    SELECT COALESCE(MAX(sort_order), 0) + 1 INTO max_sort_order
    FROM product_categories
    WHERE product_id = p_product_id;
    
    -- Insert category assignment
    INSERT INTO product_categories (
        product_id,
        category_id,
        store_id,
        is_primary,
        sort_order,
        assignment_type
    ) VALUES (
        p_product_id,
        p_category_id,
        store_id_val,
        p_is_primary,
        max_sort_order,
        p_assignment_type
    )
    ON CONFLICT (product_id, category_id)
    DO UPDATE SET
        is_primary = EXCLUDED.is_primary,
        assignment_type = EXCLUDED.assignment_type,
        updated_at = CURRENT_TIMESTAMP;
    
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

/**
 * Remove product from category
 * @param p_product_id UUID - Product ID
 * @param p_category_id UUID - Category ID
 * @return BOOLEAN - Success status
 */
CREATE OR REPLACE FUNCTION remove_product_from_category(
    p_product_id UUID,
    p_category_id UUID
)
RETURNS BOOLEAN AS $$
BEGIN
    DELETE FROM product_categories
    WHERE product_id = p_product_id
      AND category_id = p_category_id;
    
    RETURN FOUND;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

/**
 * Get products in category with performance metrics
 * @param p_category_id UUID - Category ID
 * @param p_limit INTEGER - Limit results
 * @param p_offset INTEGER - Offset for pagination
 * @return TABLE - Products in category
 */
CREATE OR REPLACE FUNCTION get_category_products(
    p_category_id UUID,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    product_id UUID,
    product_name VARCHAR,
    is_primary BOOLEAN,
    performance_score DECIMAL,
    click_count INTEGER,
    view_count INTEGER,
    conversion_count INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pc.product_id,
        p.name as product_name,
        pc.is_primary,
        pc.performance_score,
        pc.click_count,
        pc.view_count,
        pc.conversion_count
    FROM product_categories pc
    JOIN products p ON p.id = pc.product_id
    WHERE pc.category_id = p_category_id
      AND pc.is_visible = TRUE
    ORDER BY pc.performance_score DESC, pc.is_primary DESC, p.name ASC
    LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql;

/**
 * Apply categorization rules to a product
 * @param p_product_id UUID - Product ID
 * @param p_store_id UUID - Store ID
 * @return INTEGER - Number of rules applied
 */
CREATE OR REPLACE FUNCTION apply_categorization_rules(
    p_product_id UUID,
    p_store_id UUID
)
RETURNS INTEGER AS $$
DECLARE
    rule_record RECORD;
    product_record RECORD;
    rules_applied INTEGER := 0;
    condition_met BOOLEAN;
BEGIN
    -- Get product data
    SELECT * INTO product_record
    FROM products
    WHERE id = p_product_id;
    
    IF product_record IS NULL THEN
        RETURN 0;
    END IF;
    
    -- Apply each active rule
    FOR rule_record IN 
        SELECT * FROM product_category_rules
        WHERE store_id = p_store_id
          AND is_active = TRUE
        ORDER BY priority DESC
    LOOP
        condition_met := FALSE;
        
        -- Simple condition evaluation (can be extended)
        -- This is a basic implementation - in practice, you'd want more sophisticated rule evaluation
        IF rule_record.conditions->>'field' = 'name' AND 
           rule_record.conditions->>'operator' = 'contains' THEN
            condition_met := product_record.name ILIKE '%' || (rule_record.conditions->>'value') || '%';
        END IF;
        
        -- If condition is met, assign category
        IF condition_met THEN
            PERFORM assign_product_to_category(
                p_product_id,
                rule_record.target_category_id,
                FALSE,
                'automatic'
            );
            
            -- Update rule statistics
            UPDATE product_category_rules
            SET matches_count = matches_count + 1,
                last_executed_at = CURRENT_TIMESTAMP
            WHERE id = rule_record.id;
            
            rules_applied := rules_applied + 1;
        END IF;
    END LOOP;
    
    RETURN rules_applied;
END;
$$ LANGUAGE plpgsql;

/**
 * Get category assignment statistics
 * @param p_store_id UUID - Store ID
 * @param p_category_id UUID - Category ID (optional)
 * @return JSONB - Assignment statistics
 */
CREATE OR REPLACE FUNCTION get_category_assignment_stats(
    p_store_id UUID,
    p_category_id UUID DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_assignments', COUNT(*),
        'primary_assignments', COUNT(*) FILTER (WHERE is_primary = TRUE),
        'visible_assignments', COUNT(*) FILTER (WHERE is_visible = TRUE),
        'featured_assignments', COUNT(*) FILTER (WHERE is_featured = TRUE),
        'assignment_types', (
            SELECT jsonb_object_agg(assignment_type, type_count)
            FROM (
                SELECT assignment_type, COUNT(*) as type_count
                FROM product_categories
                WHERE store_id = p_store_id
                  AND (p_category_id IS NULL OR category_id = p_category_id)
                GROUP BY assignment_type
            ) type_stats
        ),
        'avg_confidence_score', AVG(confidence_score),
        'total_clicks', SUM(click_count),
        'total_views', SUM(view_count),
        'total_conversions', SUM(conversion_count),
        'avg_performance_score', AVG(performance_score),
        'last_interaction', MAX(last_interaction_at)
    ) INTO result
    FROM product_categories
    WHERE store_id = p_store_id
      AND (p_category_id IS NULL OR category_id = p_category_id);
    
    RETURN COALESCE(result, '{"error": "No assignments found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Comments
-- =============================================================================

COMMENT ON TABLE product_categories IS 'Normalized table for product-category relationships, extracted from products.category_ids JSONB column';
COMMENT ON TABLE product_category_history IS 'Audit trail for category assignment changes';
COMMENT ON TABLE product_category_rules IS 'Automatic categorization rules for products';

COMMENT ON COLUMN product_categories.is_primary IS 'Whether this is the primary/main category for the product';
COMMENT ON COLUMN product_categories.assignment_type IS 'How the category was assigned (manual, automatic, etc.)';
COMMENT ON COLUMN product_categories.confidence_score IS 'Confidence level of the assignment (0-1)';
COMMENT ON COLUMN product_categories.performance_score IS 'Calculated performance score based on user interactions';
COMMENT ON COLUMN product_categories.seo_weight IS 'Weight of this category assignment for SEO purposes';

COMMENT ON FUNCTION get_product_categories(UUID, BOOLEAN) IS 'Get all categories assigned to a product';
COMMENT ON FUNCTION assign_product_to_category(UUID, UUID, BOOLEAN, VARCHAR) IS 'Assign a product to a category';
COMMENT ON FUNCTION apply_categorization_rules(UUID, UUID) IS 'Apply automatic categorization rules to a product';
COMMENT ON FUNCTION get_category_assignment_stats(UUID, UUID) IS 'Get comprehensive statistics for category assignments';