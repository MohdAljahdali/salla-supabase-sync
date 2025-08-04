-- =============================================================================
-- Product Tags Table
-- =============================================================================
-- This table stores product-tag relationships separately from the main products table
-- Normalizes the 'tag_ids' JSONB column from products table

CREATE TABLE IF NOT EXISTS product_tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    tag_id UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Tag assignment properties
    assignment_type VARCHAR(20) DEFAULT 'manual' CHECK (assignment_type IN (
        'manual', 'automatic', 'inherited', 'suggested', 'bulk_assigned', 'ai_generated'
    )),
    assignment_source VARCHAR(100), -- Source of automatic assignment
    confidence_score DECIMAL(3,2) DEFAULT 1.0 CHECK (confidence_score >= 0 AND confidence_score <= 1),
    
    -- Display and visibility
    is_visible BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    display_priority INTEGER DEFAULT 0,
    sort_order INTEGER DEFAULT 0,
    
    -- SEO and marketing
    affects_seo BOOLEAN DEFAULT TRUE,
    seo_weight DECIMAL(3,2) DEFAULT 1.0 CHECK (seo_weight >= 0 AND seo_weight <= 10),
    keyword_density DECIMAL(5,2) DEFAULT 0, -- Keyword density percentage
    
    -- Performance tracking
    click_count INTEGER DEFAULT 0,
    view_count INTEGER DEFAULT 0,
    search_count INTEGER DEFAULT 0,
    conversion_count INTEGER DEFAULT 0,
    last_interaction_at TIMESTAMPTZ,
    
    -- Analytics data
    performance_score DECIMAL(5,2) DEFAULT 0,
    relevance_score DECIMAL(5,2) DEFAULT 0,
    popularity_score DECIMAL(5,2) DEFAULT 0,
    
    -- Tag context
    context_type VARCHAR(50), -- 'color', 'size', 'material', 'brand', 'feature', etc.
    context_value VARCHAR(255),
    context_metadata JSONB DEFAULT '{}',
    
    -- A/B testing
    test_group VARCHAR(50),
    test_variant VARCHAR(50),
    
    -- External references
    external_tag_id VARCHAR(255),
    source_system VARCHAR(100),
    
    -- Sync information
    sync_status VARCHAR(20) DEFAULT 'synced' CHECK (sync_status IN ('pending', 'syncing', 'synced', 'error')),
    last_sync_at TIMESTAMPTZ,
    sync_errors JSONB DEFAULT '[]',
    
    -- Custom fields
    custom_fields JSONB DEFAULT '{}',
    metadata JSONB DEFAULT '{}',
    
    -- Timestamps
    assigned_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT product_tags_unique_assignment UNIQUE (product_id, tag_id),
    CONSTRAINT product_tags_sort_order_check CHECK (sort_order >= 0),
    CONSTRAINT product_tags_display_priority_check CHECK (display_priority >= 0)
);

-- =============================================================================
-- Product Tag History Table
-- =============================================================================
-- This table tracks changes to product-tag assignments for auditing

CREATE TABLE IF NOT EXISTS product_tag_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL,
    tag_id UUID NOT NULL,
    store_id UUID NOT NULL,
    
    -- Change information
    action_type VARCHAR(20) NOT NULL CHECK (action_type IN ('assigned', 'unassigned', 'updated')),
    old_values JSONB DEFAULT '{}',
    new_values JSONB DEFAULT '{}',
    change_reason VARCHAR(255),
    
    -- Assignment details at time of change
    assignment_type VARCHAR(20),
    confidence_score DECIMAL(3,2),
    context_type VARCHAR(50),
    
    -- Change context
    changed_by_user_id UUID,
    changed_by_system VARCHAR(100),
    ip_address INET,
    user_agent TEXT,
    
    -- Timestamps
    changed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- Product Tag Rules Table
-- =============================================================================
-- This table stores automatic tagging rules

CREATE TABLE IF NOT EXISTS product_tag_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Rule information
    rule_name VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Rule conditions
    conditions JSONB NOT NULL, -- {"field": "name", "operator": "contains", "value": "red"}
    target_tag_id UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    
    -- Rule properties
    is_active BOOLEAN DEFAULT TRUE,
    priority INTEGER DEFAULT 0,
    confidence_score DECIMAL(3,2) DEFAULT 0.8,
    
    -- Rule execution
    execution_mode VARCHAR(20) DEFAULT 'automatic' CHECK (execution_mode IN (
        'automatic', 'manual', 'suggestion_only'
    )),
    
    -- Context and scope
    context_type VARCHAR(50),
    applies_to_categories JSONB DEFAULT '[]', -- Array of category IDs
    applies_to_brands JSONB DEFAULT '[]', -- Array of brand IDs
    
    -- Performance tracking
    matches_count INTEGER DEFAULT 0,
    success_rate DECIMAL(5,2) DEFAULT 0,
    false_positive_rate DECIMAL(5,2) DEFAULT 0,
    last_executed_at TIMESTAMPTZ,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT product_tag_rules_unique_name UNIQUE (store_id, rule_name),
    CONSTRAINT product_tag_rules_priority_check CHECK (priority >= 0)
);

-- =============================================================================
-- Product Tag Suggestions Table
-- =============================================================================
-- This table stores AI/ML generated tag suggestions

CREATE TABLE IF NOT EXISTS product_tag_suggestions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    tag_id UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Suggestion details
    suggestion_source VARCHAR(100) NOT NULL, -- 'ai_model', 'ml_algorithm', 'user_behavior', etc.
    confidence_score DECIMAL(3,2) NOT NULL CHECK (confidence_score >= 0 AND confidence_score <= 1),
    relevance_score DECIMAL(3,2) DEFAULT 0,
    
    -- Suggestion context
    context_type VARCHAR(50),
    reasoning TEXT, -- Why this tag was suggested
    supporting_data JSONB DEFAULT '{}',
    
    -- Status and feedback
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN (
        'pending', 'accepted', 'rejected', 'ignored', 'expired'
    )),
    feedback_score INTEGER, -- User feedback (-1 to 1)
    feedback_comment TEXT,
    
    -- Processing
    reviewed_by_user_id UUID,
    reviewed_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT product_tag_suggestions_unique UNIQUE (product_id, tag_id, suggestion_source)
);

-- =============================================================================
-- Indexes
-- =============================================================================

-- Product Tags Indexes
CREATE INDEX IF NOT EXISTS idx_product_tags_product_id ON product_tags(product_id);
CREATE INDEX IF NOT EXISTS idx_product_tags_tag_id ON product_tags(tag_id);
CREATE INDEX IF NOT EXISTS idx_product_tags_store_id ON product_tags(store_id);

-- Assignment properties
CREATE INDEX IF NOT EXISTS idx_product_tags_assignment_type ON product_tags(assignment_type);
CREATE INDEX IF NOT EXISTS idx_product_tags_confidence_score ON product_tags(confidence_score DESC);
CREATE INDEX IF NOT EXISTS idx_product_tags_assignment_source ON product_tags(assignment_source);

-- Display and visibility
CREATE INDEX IF NOT EXISTS idx_product_tags_is_visible ON product_tags(is_visible);
CREATE INDEX IF NOT EXISTS idx_product_tags_is_featured ON product_tags(is_featured);
CREATE INDEX IF NOT EXISTS idx_product_tags_display_priority ON product_tags(display_priority DESC);
CREATE INDEX IF NOT EXISTS idx_product_tags_sort_order ON product_tags(sort_order);

-- SEO indexes
CREATE INDEX IF NOT EXISTS idx_product_tags_affects_seo ON product_tags(affects_seo);
CREATE INDEX IF NOT EXISTS idx_product_tags_seo_weight ON product_tags(seo_weight DESC);
CREATE INDEX IF NOT EXISTS idx_product_tags_keyword_density ON product_tags(keyword_density DESC);

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_product_tags_click_count ON product_tags(click_count DESC);
CREATE INDEX IF NOT EXISTS idx_product_tags_view_count ON product_tags(view_count DESC);
CREATE INDEX IF NOT EXISTS idx_product_tags_search_count ON product_tags(search_count DESC);
CREATE INDEX IF NOT EXISTS idx_product_tags_conversion_count ON product_tags(conversion_count DESC);
CREATE INDEX IF NOT EXISTS idx_product_tags_performance_score ON product_tags(performance_score DESC);
CREATE INDEX IF NOT EXISTS idx_product_tags_relevance_score ON product_tags(relevance_score DESC);
CREATE INDEX IF NOT EXISTS idx_product_tags_popularity_score ON product_tags(popularity_score DESC);
CREATE INDEX IF NOT EXISTS idx_product_tags_last_interaction ON product_tags(last_interaction_at DESC);

-- Context indexes
CREATE INDEX IF NOT EXISTS idx_product_tags_context_type ON product_tags(context_type);
CREATE INDEX IF NOT EXISTS idx_product_tags_context_value ON product_tags(context_value);

-- A/B testing indexes
CREATE INDEX IF NOT EXISTS idx_product_tags_test_group ON product_tags(test_group);
CREATE INDEX IF NOT EXISTS idx_product_tags_test_variant ON product_tags(test_variant);

-- External references
CREATE INDEX IF NOT EXISTS idx_product_tags_external_id ON product_tags(external_tag_id);
CREATE INDEX IF NOT EXISTS idx_product_tags_source_system ON product_tags(source_system);

-- Sync indexes
CREATE INDEX IF NOT EXISTS idx_product_tags_sync_status ON product_tags(sync_status);
CREATE INDEX IF NOT EXISTS idx_product_tags_last_sync_at ON product_tags(last_sync_at);

-- JSONB indexes
CREATE INDEX IF NOT EXISTS idx_product_tags_context_metadata ON product_tags USING gin(context_metadata);
CREATE INDEX IF NOT EXISTS idx_product_tags_custom_fields ON product_tags USING gin(custom_fields);
CREATE INDEX IF NOT EXISTS idx_product_tags_metadata ON product_tags USING gin(metadata);
CREATE INDEX IF NOT EXISTS idx_product_tags_sync_errors ON product_tags USING gin(sync_errors);

-- Composite indexes
CREATE INDEX IF NOT EXISTS idx_product_tags_featured_priority ON product_tags(tag_id, is_featured, display_priority) WHERE is_featured = TRUE;
CREATE INDEX IF NOT EXISTS idx_product_tags_product_sort ON product_tags(product_id, sort_order, is_visible) WHERE is_visible = TRUE;
CREATE INDEX IF NOT EXISTS idx_product_tags_context_performance ON product_tags(context_type, performance_score DESC, is_visible) WHERE is_visible = TRUE;
CREATE INDEX IF NOT EXISTS idx_product_tags_seo_relevant ON product_tags(tag_id, affects_seo, seo_weight DESC) WHERE affects_seo = TRUE;

-- Product Tag History Indexes
CREATE INDEX IF NOT EXISTS idx_product_tag_history_product_id ON product_tag_history(product_id);
CREATE INDEX IF NOT EXISTS idx_product_tag_history_tag_id ON product_tag_history(tag_id);
CREATE INDEX IF NOT EXISTS idx_product_tag_history_store_id ON product_tag_history(store_id);
CREATE INDEX IF NOT EXISTS idx_product_tag_history_action_type ON product_tag_history(action_type);
CREATE INDEX IF NOT EXISTS idx_product_tag_history_changed_at ON product_tag_history(changed_at DESC);
CREATE INDEX IF NOT EXISTS idx_product_tag_history_changed_by_user ON product_tag_history(changed_by_user_id);

-- Product Tag Rules Indexes
CREATE INDEX IF NOT EXISTS idx_product_tag_rules_store_id ON product_tag_rules(store_id);
CREATE INDEX IF NOT EXISTS idx_product_tag_rules_target_tag ON product_tag_rules(target_tag_id);
CREATE INDEX IF NOT EXISTS idx_product_tag_rules_is_active ON product_tag_rules(is_active);
CREATE INDEX IF NOT EXISTS idx_product_tag_rules_priority ON product_tag_rules(priority DESC);
CREATE INDEX IF NOT EXISTS idx_product_tag_rules_execution_mode ON product_tag_rules(execution_mode);
CREATE INDEX IF NOT EXISTS idx_product_tag_rules_context_type ON product_tag_rules(context_type);
CREATE INDEX IF NOT EXISTS idx_product_tag_rules_success_rate ON product_tag_rules(success_rate DESC);
CREATE INDEX IF NOT EXISTS idx_product_tag_rules_conditions ON product_tag_rules USING gin(conditions);
CREATE INDEX IF NOT EXISTS idx_product_tag_rules_applies_to_categories ON product_tag_rules USING gin(applies_to_categories);
CREATE INDEX IF NOT EXISTS idx_product_tag_rules_applies_to_brands ON product_tag_rules USING gin(applies_to_brands);

-- Product Tag Suggestions Indexes
CREATE INDEX IF NOT EXISTS idx_product_tag_suggestions_product_id ON product_tag_suggestions(product_id);
CREATE INDEX IF NOT EXISTS idx_product_tag_suggestions_tag_id ON product_tag_suggestions(tag_id);
CREATE INDEX IF NOT EXISTS idx_product_tag_suggestions_store_id ON product_tag_suggestions(store_id);
CREATE INDEX IF NOT EXISTS idx_product_tag_suggestions_source ON product_tag_suggestions(suggestion_source);
CREATE INDEX IF NOT EXISTS idx_product_tag_suggestions_confidence ON product_tag_suggestions(confidence_score DESC);
CREATE INDEX IF NOT EXISTS idx_product_tag_suggestions_status ON product_tag_suggestions(status);
CREATE INDEX IF NOT EXISTS idx_product_tag_suggestions_expires_at ON product_tag_suggestions(expires_at);
CREATE INDEX IF NOT EXISTS idx_product_tag_suggestions_reviewed_by ON product_tag_suggestions(reviewed_by_user_id);
CREATE INDEX IF NOT EXISTS idx_product_tag_suggestions_supporting_data ON product_tag_suggestions USING gin(supporting_data);

-- =============================================================================
-- Triggers
-- =============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_product_tags_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_product_tags_updated_at
    BEFORE UPDATE ON product_tags
    FOR EACH ROW
    EXECUTE FUNCTION update_product_tags_updated_at();

-- Auto-update updated_at timestamp for rules
CREATE OR REPLACE FUNCTION update_product_tag_rules_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_product_tag_rules_updated_at
    BEFORE UPDATE ON product_tag_rules
    FOR EACH ROW
    EXECUTE FUNCTION update_product_tag_rules_updated_at();

-- Auto-update updated_at timestamp for suggestions
CREATE OR REPLACE FUNCTION update_product_tag_suggestions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_product_tag_suggestions_updated_at
    BEFORE UPDATE ON product_tag_suggestions
    FOR EACH ROW
    EXECUTE FUNCTION update_product_tag_suggestions_updated_at();

-- Track tag assignment changes
CREATE OR REPLACE FUNCTION track_tag_assignment_changes()
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
    INSERT INTO product_tag_history (
        product_id,
        tag_id,
        store_id,
        action_type,
        old_values,
        new_values,
        assignment_type,
        confidence_score,
        context_type,
        changed_by_system
    ) VALUES (
        COALESCE(NEW.product_id, OLD.product_id),
        COALESCE(NEW.tag_id, OLD.tag_id),
        COALESCE(NEW.store_id, OLD.store_id),
        action_type_val,
        old_vals,
        new_vals,
        COALESCE(NEW.assignment_type, OLD.assignment_type),
        COALESCE(NEW.confidence_score, OLD.confidence_score),
        COALESCE(NEW.context_type, OLD.context_type),
        'system'
    );
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_track_tag_assignment_changes
    AFTER INSERT OR UPDATE OR DELETE ON product_tags
    FOR EACH ROW
    EXECUTE FUNCTION track_tag_assignment_changes();

-- Update performance scores based on metrics
CREATE OR REPLACE FUNCTION update_tag_performance_scores()
RETURNS TRIGGER AS $$
BEGIN
    -- Calculate performance score based on various metrics
    NEW.performance_score := (
        (NEW.click_count * 0.25) +
        (NEW.view_count * 0.15) +
        (NEW.search_count * 0.35) +
        (NEW.conversion_count * 0.25)
    ) / GREATEST(1, NEW.view_count) * 100;
    
    -- Calculate relevance score (simplified)
    NEW.relevance_score := (
        NEW.confidence_score * 50 +
        LEAST(NEW.keyword_density, 10) * 5
    );
    
    -- Calculate popularity score
    NEW.popularity_score := (
        LOG(GREATEST(1, NEW.search_count)) * 20 +
        LOG(GREATEST(1, NEW.click_count)) * 15
    );
    
    -- Update last interaction timestamp if any metric changed
    IF (NEW.click_count != OLD.click_count OR 
        NEW.view_count != OLD.view_count OR 
        NEW.search_count != OLD.search_count OR
        NEW.conversion_count != OLD.conversion_count) THEN
        NEW.last_interaction_at := CURRENT_TIMESTAMP;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_tag_performance_scores
    BEFORE UPDATE ON product_tags
    FOR EACH ROW
    WHEN (NEW.click_count != OLD.click_count OR 
          NEW.view_count != OLD.view_count OR 
          NEW.search_count != OLD.search_count OR
          NEW.conversion_count != OLD.conversion_count)
    EXECUTE FUNCTION update_tag_performance_scores();

-- Auto-expire suggestions
CREATE OR REPLACE FUNCTION auto_expire_suggestions()
RETURNS TRIGGER AS $$
BEGIN
    -- Set expiration date if not set (30 days from creation)
    IF NEW.expires_at IS NULL THEN
        NEW.expires_at := NEW.created_at + INTERVAL '30 days';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_expire_suggestions
    BEFORE INSERT ON product_tag_suggestions
    FOR EACH ROW
    EXECUTE FUNCTION auto_expire_suggestions();

-- =============================================================================
-- Helper Functions
-- =============================================================================

/**
 * Get all tags for a specific product
 * @param p_product_id UUID - Product ID
 * @param p_visible_only BOOLEAN - Whether to return only visible tags
 * @param p_context_type VARCHAR - Filter by context type
 * @return TABLE - Product tags
 */
CREATE OR REPLACE FUNCTION get_product_tags(
    p_product_id UUID,
    p_visible_only BOOLEAN DEFAULT TRUE,
    p_context_type VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    tag_id UUID,
    tag_name VARCHAR,
    tag_slug VARCHAR,
    assignment_type VARCHAR,
    confidence_score DECIMAL,
    context_type VARCHAR,
    performance_score DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pt.tag_id,
        t.name as tag_name,
        t.slug as tag_slug,
        pt.assignment_type,
        pt.confidence_score,
        pt.context_type,
        pt.performance_score
    FROM product_tags pt
    JOIN tags t ON t.id = pt.tag_id
    WHERE pt.product_id = p_product_id
      AND (NOT p_visible_only OR pt.is_visible = TRUE)
      AND (p_context_type IS NULL OR pt.context_type = p_context_type)
    ORDER BY pt.performance_score DESC, pt.sort_order ASC, t.name ASC;
END;
$$ LANGUAGE plpgsql;

/**
 * Assign tag to product
 * @param p_product_id UUID - Product ID
 * @param p_tag_id UUID - Tag ID
 * @param p_assignment_type VARCHAR - Type of assignment
 * @param p_context_type VARCHAR - Context type
 * @return BOOLEAN - Success status
 */
CREATE OR REPLACE FUNCTION assign_tag_to_product(
    p_product_id UUID,
    p_tag_id UUID,
    p_assignment_type VARCHAR DEFAULT 'manual',
    p_context_type VARCHAR DEFAULT NULL
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
    FROM product_tags
    WHERE product_id = p_product_id;
    
    -- Insert tag assignment
    INSERT INTO product_tags (
        product_id,
        tag_id,
        store_id,
        assignment_type,
        context_type,
        sort_order
    ) VALUES (
        p_product_id,
        p_tag_id,
        store_id_val,
        p_assignment_type,
        p_context_type,
        max_sort_order
    )
    ON CONFLICT (product_id, tag_id)
    DO UPDATE SET
        assignment_type = EXCLUDED.assignment_type,
        context_type = EXCLUDED.context_type,
        updated_at = CURRENT_TIMESTAMP;
    
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

/**
 * Remove tag from product
 * @param p_product_id UUID - Product ID
 * @param p_tag_id UUID - Tag ID
 * @return BOOLEAN - Success status
 */
CREATE OR REPLACE FUNCTION remove_tag_from_product(
    p_product_id UUID,
    p_tag_id UUID
)
RETURNS BOOLEAN AS $$
BEGIN
    DELETE FROM product_tags
    WHERE product_id = p_product_id
      AND tag_id = p_tag_id;
    
    RETURN FOUND;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

/**
 * Get products by tag with performance metrics
 * @param p_tag_id UUID - Tag ID
 * @param p_limit INTEGER - Limit results
 * @param p_offset INTEGER - Offset for pagination
 * @return TABLE - Products with tag
 */
CREATE OR REPLACE FUNCTION get_products_by_tag(
    p_tag_id UUID,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    product_id UUID,
    product_name VARCHAR,
    assignment_type VARCHAR,
    confidence_score DECIMAL,
    performance_score DECIMAL,
    click_count INTEGER,
    conversion_count INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pt.product_id,
        p.name as product_name,
        pt.assignment_type,
        pt.confidence_score,
        pt.performance_score,
        pt.click_count,
        pt.conversion_count
    FROM product_tags pt
    JOIN products p ON p.id = pt.product_id
    WHERE pt.tag_id = p_tag_id
      AND pt.is_visible = TRUE
    ORDER BY pt.performance_score DESC, p.name ASC
    LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql;

/**
 * Apply tagging rules to a product
 * @param p_product_id UUID - Product ID
 * @param p_store_id UUID - Store ID
 * @return INTEGER - Number of rules applied
 */
CREATE OR REPLACE FUNCTION apply_tagging_rules(
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
        SELECT * FROM product_tag_rules
        WHERE store_id = p_store_id
          AND is_active = TRUE
        ORDER BY priority DESC
    LOOP
        condition_met := FALSE;
        
        -- Simple condition evaluation (can be extended)
        IF rule_record.conditions->>'field' = 'name' AND 
           rule_record.conditions->>'operator' = 'contains' THEN
            condition_met := product_record.name ILIKE '%' || (rule_record.conditions->>'value') || '%';
        ELSIF rule_record.conditions->>'field' = 'description' AND 
              rule_record.conditions->>'operator' = 'contains' THEN
            condition_met := product_record.description ILIKE '%' || (rule_record.conditions->>'value') || '%';
        END IF;
        
        -- If condition is met, assign tag
        IF condition_met THEN
            PERFORM assign_tag_to_product(
                p_product_id,
                rule_record.target_tag_id,
                'automatic',
                rule_record.context_type
            );
            
            -- Update rule statistics
            UPDATE product_tag_rules
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
 * Generate tag suggestions for a product
 * @param p_product_id UUID - Product ID
 * @param p_suggestion_source VARCHAR - Source of suggestions
 * @param p_max_suggestions INTEGER - Maximum number of suggestions
 * @return INTEGER - Number of suggestions generated
 */
CREATE OR REPLACE FUNCTION generate_tag_suggestions(
    p_product_id UUID,
    p_suggestion_source VARCHAR DEFAULT 'ai_model',
    p_max_suggestions INTEGER DEFAULT 10
)
RETURNS INTEGER AS $$
DECLARE
    product_record RECORD;
    tag_record RECORD;
    store_id_val UUID;
    suggestions_count INTEGER := 0;
    confidence DECIMAL;
BEGIN
    -- Get product and store data
    SELECT p.*, p.store_id INTO product_record
    FROM products p
    WHERE p.id = p_product_id;
    
    IF product_record IS NULL THEN
        RETURN 0;
    END IF;
    
    store_id_val := product_record.store_id;
    
    -- Simple suggestion logic based on product name keywords
    -- In practice, this would use ML/AI models
    FOR tag_record IN 
        SELECT t.* FROM tags t
        WHERE t.store_id = store_id_val
          AND t.is_active = TRUE
          AND NOT EXISTS (
              SELECT 1 FROM product_tags pt
              WHERE pt.product_id = p_product_id
                AND pt.tag_id = t.id
          )
          AND NOT EXISTS (
              SELECT 1 FROM product_tag_suggestions pts
              WHERE pts.product_id = p_product_id
                AND pts.tag_id = t.id
                AND pts.status = 'pending'
          )
        LIMIT p_max_suggestions
    LOOP
        -- Calculate confidence based on name similarity (simplified)
        confidence := CASE 
            WHEN product_record.name ILIKE '%' || tag_record.name || '%' THEN 0.9
            WHEN product_record.description ILIKE '%' || tag_record.name || '%' THEN 0.7
            ELSE 0.3
        END;
        
        -- Only suggest if confidence is above threshold
        IF confidence >= 0.5 THEN
            INSERT INTO product_tag_suggestions (
                product_id,
                tag_id,
                store_id,
                suggestion_source,
                confidence_score,
                reasoning
            ) VALUES (
                p_product_id,
                tag_record.id,
                store_id_val,
                p_suggestion_source,
                confidence,
                'Generated based on product name/description similarity'
            );
            
            suggestions_count := suggestions_count + 1;
        END IF;
    END LOOP;
    
    RETURN suggestions_count;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END;
$$ LANGUAGE plpgsql;

/**
 * Get tag assignment statistics
 * @param p_store_id UUID - Store ID
 * @param p_tag_id UUID - Tag ID (optional)
 * @return JSONB - Assignment statistics
 */
CREATE OR REPLACE FUNCTION get_tag_assignment_stats(
    p_store_id UUID,
    p_tag_id UUID DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_assignments', COUNT(*),
        'visible_assignments', COUNT(*) FILTER (WHERE is_visible = TRUE),
        'featured_assignments', COUNT(*) FILTER (WHERE is_featured = TRUE),
        'assignment_types', (
            SELECT jsonb_object_agg(assignment_type, type_count)
            FROM (
                SELECT assignment_type, COUNT(*) as type_count
                FROM product_tags
                WHERE store_id = p_store_id
                  AND (p_tag_id IS NULL OR tag_id = p_tag_id)
                GROUP BY assignment_type
            ) type_stats
        ),
        'context_types', (
            SELECT jsonb_object_agg(context_type, context_count)
            FROM (
                SELECT context_type, COUNT(*) as context_count
                FROM product_tags
                WHERE store_id = p_store_id
                  AND (p_tag_id IS NULL OR tag_id = p_tag_id)
                  AND context_type IS NOT NULL
                GROUP BY context_type
            ) context_stats
        ),
        'avg_confidence_score', AVG(confidence_score),
        'avg_performance_score', AVG(performance_score),
        'avg_relevance_score', AVG(relevance_score),
        'total_clicks', SUM(click_count),
        'total_views', SUM(view_count),
        'total_searches', SUM(search_count),
        'total_conversions', SUM(conversion_count),
        'last_interaction', MAX(last_interaction_at)
    ) INTO result
    FROM product_tags
    WHERE store_id = p_store_id
      AND (p_tag_id IS NULL OR tag_id = p_tag_id);
    
    RETURN COALESCE(result, '{"error": "No assignments found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Comments
-- =============================================================================

COMMENT ON TABLE product_tags IS 'Normalized table for product-tag relationships, extracted from products.tag_ids JSONB column';
COMMENT ON TABLE product_tag_history IS 'Audit trail for tag assignment changes';
COMMENT ON TABLE product_tag_rules IS 'Automatic tagging rules for products';
COMMENT ON TABLE product_tag_suggestions IS 'AI/ML generated tag suggestions for products';

COMMENT ON COLUMN product_tags.assignment_type IS 'How the tag was assigned (manual, automatic, ai_generated, etc.)';
COMMENT ON COLUMN product_tags.confidence_score IS 'Confidence level of the assignment (0-1)';
COMMENT ON COLUMN product_tags.context_type IS 'Context or category of the tag (color, size, material, etc.)';
COMMENT ON COLUMN product_tags.performance_score IS 'Calculated performance score based on user interactions';
COMMENT ON COLUMN product_tags.keyword_density IS 'Keyword density percentage for SEO';

COMMENT ON FUNCTION get_product_tags(UUID, BOOLEAN, VARCHAR) IS 'Get all tags assigned to a product with optional filtering';
COMMENT ON FUNCTION assign_tag_to_product(UUID, UUID, VARCHAR, VARCHAR) IS 'Assign a tag to a product';
COMMENT ON FUNCTION apply_tagging_rules(UUID, UUID) IS 'Apply automatic tagging rules to a product';
COMMENT ON FUNCTION generate_tag_suggestions(UUID, VARCHAR, INTEGER) IS 'Generate AI/ML tag suggestions for a product';
COMMENT ON FUNCTION get_tag_assignment_stats(UUID, UUID) IS 'Get comprehensive statistics for tag assignments';