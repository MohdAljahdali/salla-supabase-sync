-- =============================================================================
-- Order Tags Table
-- =============================================================================
-- This table normalizes the 'tags' JSONB column from the orders table
-- Stores tag assignments for orders

CREATE TABLE IF NOT EXISTS order_tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Tag identification
    tag_name VARCHAR(100) NOT NULL,
    tag_slug VARCHAR(100) NOT NULL,
    tag_color VARCHAR(7), -- Hex color code
    tag_icon VARCHAR(50),
    
    -- Assignment properties
    assigned_by_user_id UUID,
    assignment_source VARCHAR(50) DEFAULT 'manual' CHECK (assignment_source IN (
        'manual', 'automatic', 'rule_based', 'ai_suggested', 'imported', 'webhook'
    )),
    assignment_reason VARCHAR(255),
    confidence_score DECIMAL(3,2) DEFAULT 1.00 CHECK (confidence_score >= 0 AND confidence_score <= 1),
    
    -- Tag properties
    is_system_tag BOOLEAN DEFAULT FALSE,
    is_public BOOLEAN DEFAULT TRUE,
    is_searchable BOOLEAN DEFAULT TRUE,
    weight INTEGER DEFAULT 1 CHECK (weight >= 0),
    
    -- Display properties
    display_order INTEGER DEFAULT 0,
    is_featured BOOLEAN DEFAULT FALSE,
    show_in_filters BOOLEAN DEFAULT TRUE,
    show_in_reports BOOLEAN DEFAULT TRUE,
    
    -- Tag lifecycle
    is_active BOOLEAN DEFAULT TRUE,
    expires_at TIMESTAMPTZ,
    auto_remove_after_days INTEGER,
    
    -- Performance tracking
    usage_count INTEGER DEFAULT 1,
    click_count INTEGER DEFAULT 0,
    conversion_rate DECIMAL(5,2) DEFAULT 0.00,
    performance_score DECIMAL(3,2) DEFAULT 0.00,
    
    -- A/B testing
    ab_test_group VARCHAR(50),
    ab_test_variant VARCHAR(50),
    ab_test_active BOOLEAN DEFAULT FALSE,
    
    -- Context and metadata
    context JSONB DEFAULT '{}', -- Additional context about the tag assignment
    tag_metadata JSONB DEFAULT '{}',
    
    -- Quality and validation
    quality_score DECIMAL(3,2) DEFAULT 0.00 CHECK (quality_score >= 0 AND quality_score <= 1),
    validation_status VARCHAR(20) DEFAULT 'valid' CHECK (validation_status IN (
        'valid', 'invalid', 'pending', 'needs_review'
    )),
    validation_errors JSONB DEFAULT '[]',
    
    -- External references
    external_tag_id VARCHAR(255),
    external_references JSONB DEFAULT '{}',
    
    -- Sync information
    sync_status VARCHAR(20) DEFAULT 'synced' CHECK (sync_status IN ('pending', 'syncing', 'synced', 'error')),
    last_sync_at TIMESTAMPTZ,
    sync_errors JSONB DEFAULT '[]',
    
    -- Custom fields
    custom_fields JSONB DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    UNIQUE(order_id, tag_slug)
);

-- =============================================================================
-- Order Tag History Table
-- =============================================================================
-- Track changes to order tag assignments

CREATE TABLE IF NOT EXISTS order_tag_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_tag_id UUID REFERENCES order_tags(id) ON DELETE SET NULL,
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Tag information
    tag_name VARCHAR(100) NOT NULL,
    tag_slug VARCHAR(100) NOT NULL,
    
    -- Change information
    change_type VARCHAR(20) NOT NULL CHECK (change_type IN (
        'assigned', 'removed', 'updated', 'activated', 'deactivated', 'expired'
    )),
    field_name VARCHAR(100),
    old_value TEXT,
    new_value TEXT,
    
    -- Change context
    changed_by_user_id UUID,
    change_reason VARCHAR(255),
    change_source VARCHAR(50) DEFAULT 'system',
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- Order Tag Rules Table
-- =============================================================================
-- Define rules for automatic tag assignment

CREATE TABLE IF NOT EXISTS order_tag_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Rule identification
    rule_name VARCHAR(100) NOT NULL,
    rule_description TEXT,
    
    -- Tag to assign
    tag_name VARCHAR(100) NOT NULL,
    tag_slug VARCHAR(100) NOT NULL,
    
    -- Rule conditions
    conditions JSONB NOT NULL DEFAULT '{}', -- Rule conditions in JSON format
    
    -- Rule properties
    is_active BOOLEAN DEFAULT TRUE,
    priority INTEGER DEFAULT 0,
    rule_type VARCHAR(50) DEFAULT 'conditional' CHECK (rule_type IN (
        'conditional', 'scheduled', 'event_based', 'ml_based'
    )),
    
    -- Execution settings
    execution_order INTEGER DEFAULT 0,
    max_executions_per_day INTEGER,
    cooldown_minutes INTEGER DEFAULT 0,
    
    -- Performance tracking
    execution_count INTEGER DEFAULT 0,
    success_count INTEGER DEFAULT 0,
    failure_count INTEGER DEFAULT 0,
    last_executed_at TIMESTAMPTZ,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    UNIQUE(store_id, rule_name)
);

-- =============================================================================
-- Order Tag Suggestions Table
-- =============================================================================
-- Store AI-generated tag suggestions

CREATE TABLE IF NOT EXISTS order_tag_suggestions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Suggested tag
    suggested_tag_name VARCHAR(100) NOT NULL,
    suggested_tag_slug VARCHAR(100) NOT NULL,
    
    -- Suggestion properties
    confidence_score DECIMAL(3,2) NOT NULL CHECK (confidence_score >= 0 AND confidence_score <= 1),
    suggestion_reason TEXT,
    suggestion_source VARCHAR(50) DEFAULT 'ai' CHECK (suggestion_source IN (
        'ai', 'ml_model', 'rule_based', 'user_behavior', 'similar_orders'
    )),
    
    -- Suggestion status
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN (
        'pending', 'accepted', 'rejected', 'expired'
    )),
    reviewed_by_user_id UUID,
    reviewed_at TIMESTAMPTZ,
    review_notes TEXT,
    
    -- Auto-expiration
    expires_at TIMESTAMPTZ DEFAULT (CURRENT_TIMESTAMP + INTERVAL '7 days'),
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- Indexes
-- =============================================================================

-- Basic indexes
CREATE INDEX IF NOT EXISTS idx_order_tags_order_id ON order_tags(order_id);
CREATE INDEX IF NOT EXISTS idx_order_tags_store_id ON order_tags(store_id);
CREATE INDEX IF NOT EXISTS idx_order_tags_tag_name ON order_tags(tag_name);
CREATE INDEX IF NOT EXISTS idx_order_tags_tag_slug ON order_tags(tag_slug);
CREATE INDEX IF NOT EXISTS idx_order_tags_external_tag_id ON order_tags(external_tag_id);

-- Assignment properties
CREATE INDEX IF NOT EXISTS idx_order_tags_assigned_by ON order_tags(assigned_by_user_id);
CREATE INDEX IF NOT EXISTS idx_order_tags_assignment_source ON order_tags(assignment_source);
CREATE INDEX IF NOT EXISTS idx_order_tags_confidence_score ON order_tags(confidence_score DESC);

-- Tag properties
CREATE INDEX IF NOT EXISTS idx_order_tags_is_system_tag ON order_tags(is_system_tag);
CREATE INDEX IF NOT EXISTS idx_order_tags_is_public ON order_tags(is_public) WHERE is_public = TRUE;
CREATE INDEX IF NOT EXISTS idx_order_tags_is_searchable ON order_tags(is_searchable) WHERE is_searchable = TRUE;
CREATE INDEX IF NOT EXISTS idx_order_tags_weight ON order_tags(weight DESC);

-- Display properties
CREATE INDEX IF NOT EXISTS idx_order_tags_display_order ON order_tags(display_order);
CREATE INDEX IF NOT EXISTS idx_order_tags_is_featured ON order_tags(is_featured) WHERE is_featured = TRUE;
CREATE INDEX IF NOT EXISTS idx_order_tags_show_in_filters ON order_tags(show_in_filters) WHERE show_in_filters = TRUE;
CREATE INDEX IF NOT EXISTS idx_order_tags_show_in_reports ON order_tags(show_in_reports) WHERE show_in_reports = TRUE;

-- Tag lifecycle
CREATE INDEX IF NOT EXISTS idx_order_tags_is_active ON order_tags(is_active);
CREATE INDEX IF NOT EXISTS idx_order_tags_expires_at ON order_tags(expires_at) WHERE expires_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_order_tags_auto_remove_after_days ON order_tags(auto_remove_after_days) WHERE auto_remove_after_days IS NOT NULL;

-- Performance tracking
CREATE INDEX IF NOT EXISTS idx_order_tags_usage_count ON order_tags(usage_count DESC);
CREATE INDEX IF NOT EXISTS idx_order_tags_click_count ON order_tags(click_count DESC);
CREATE INDEX IF NOT EXISTS idx_order_tags_conversion_rate ON order_tags(conversion_rate DESC);
CREATE INDEX IF NOT EXISTS idx_order_tags_performance_score ON order_tags(performance_score DESC);

-- A/B testing
CREATE INDEX IF NOT EXISTS idx_order_tags_ab_test_group ON order_tags(ab_test_group) WHERE ab_test_group IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_order_tags_ab_test_variant ON order_tags(ab_test_variant) WHERE ab_test_variant IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_order_tags_ab_test_active ON order_tags(ab_test_active) WHERE ab_test_active = TRUE;

-- Quality and validation
CREATE INDEX IF NOT EXISTS idx_order_tags_quality_score ON order_tags(quality_score DESC);
CREATE INDEX IF NOT EXISTS idx_order_tags_validation_status ON order_tags(validation_status);

-- Sync information
CREATE INDEX IF NOT EXISTS idx_order_tags_sync_status ON order_tags(sync_status);
CREATE INDEX IF NOT EXISTS idx_order_tags_last_sync_at ON order_tags(last_sync_at DESC);

-- Timestamps
CREATE INDEX IF NOT EXISTS idx_order_tags_created_at ON order_tags(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_tags_updated_at ON order_tags(updated_at DESC);

-- JSONB indexes
CREATE INDEX IF NOT EXISTS idx_order_tags_context ON order_tags USING gin(context);
CREATE INDEX IF NOT EXISTS idx_order_tags_tag_metadata ON order_tags USING gin(tag_metadata);
CREATE INDEX IF NOT EXISTS idx_order_tags_validation_errors ON order_tags USING gin(validation_errors);
CREATE INDEX IF NOT EXISTS idx_order_tags_external_references ON order_tags USING gin(external_references);
CREATE INDEX IF NOT EXISTS idx_order_tags_custom_fields ON order_tags USING gin(custom_fields);
CREATE INDEX IF NOT EXISTS idx_order_tags_sync_errors ON order_tags USING gin(sync_errors);

-- Text search indexes
CREATE INDEX IF NOT EXISTS idx_order_tags_tag_name_text ON order_tags USING gin(to_tsvector('english', tag_name));
CREATE INDEX IF NOT EXISTS idx_order_tags_assignment_reason_text ON order_tags USING gin(to_tsvector('english', COALESCE(assignment_reason, '')));

-- Composite indexes
CREATE INDEX IF NOT EXISTS idx_order_tags_order_active ON order_tags(order_id, is_active);
CREATE INDEX IF NOT EXISTS idx_order_tags_store_tag ON order_tags(store_id, tag_slug);
CREATE INDEX IF NOT EXISTS idx_order_tags_performance ON order_tags(performance_score DESC, usage_count DESC, conversion_rate DESC);
CREATE INDEX IF NOT EXISTS idx_order_tags_display ON order_tags(display_order, is_featured DESC, weight DESC);
CREATE INDEX IF NOT EXISTS idx_order_tags_quality ON order_tags(quality_score DESC, validation_status, confidence_score DESC);

-- History table indexes
CREATE INDEX IF NOT EXISTS idx_order_tag_history_order_tag_id ON order_tag_history(order_tag_id);
CREATE INDEX IF NOT EXISTS idx_order_tag_history_order_id ON order_tag_history(order_id);
CREATE INDEX IF NOT EXISTS idx_order_tag_history_store_id ON order_tag_history(store_id);
CREATE INDEX IF NOT EXISTS idx_order_tag_history_tag_slug ON order_tag_history(tag_slug);
CREATE INDEX IF NOT EXISTS idx_order_tag_history_change_type ON order_tag_history(change_type);
CREATE INDEX IF NOT EXISTS idx_order_tag_history_created_at ON order_tag_history(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_tag_history_changed_by ON order_tag_history(changed_by_user_id);

-- Rules table indexes
CREATE INDEX IF NOT EXISTS idx_order_tag_rules_store_id ON order_tag_rules(store_id);
CREATE INDEX IF NOT EXISTS idx_order_tag_rules_tag_slug ON order_tag_rules(tag_slug);
CREATE INDEX IF NOT EXISTS idx_order_tag_rules_is_active ON order_tag_rules(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_order_tag_rules_priority ON order_tag_rules(priority DESC);
CREATE INDEX IF NOT EXISTS idx_order_tag_rules_rule_type ON order_tag_rules(rule_type);
CREATE INDEX IF NOT EXISTS idx_order_tag_rules_execution_order ON order_tag_rules(execution_order);
CREATE INDEX IF NOT EXISTS idx_order_tag_rules_last_executed_at ON order_tag_rules(last_executed_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_tag_rules_conditions ON order_tag_rules USING gin(conditions);

-- Suggestions table indexes
CREATE INDEX IF NOT EXISTS idx_order_tag_suggestions_order_id ON order_tag_suggestions(order_id);
CREATE INDEX IF NOT EXISTS idx_order_tag_suggestions_store_id ON order_tag_suggestions(store_id);
CREATE INDEX IF NOT EXISTS idx_order_tag_suggestions_tag_slug ON order_tag_suggestions(suggested_tag_slug);
CREATE INDEX IF NOT EXISTS idx_order_tag_suggestions_confidence_score ON order_tag_suggestions(confidence_score DESC);
CREATE INDEX IF NOT EXISTS idx_order_tag_suggestions_status ON order_tag_suggestions(status);
CREATE INDEX IF NOT EXISTS idx_order_tag_suggestions_suggestion_source ON order_tag_suggestions(suggestion_source);
CREATE INDEX IF NOT EXISTS idx_order_tag_suggestions_expires_at ON order_tag_suggestions(expires_at);
CREATE INDEX IF NOT EXISTS idx_order_tag_suggestions_reviewed_by ON order_tag_suggestions(reviewed_by_user_id);
CREATE INDEX IF NOT EXISTS idx_order_tag_suggestions_created_at ON order_tag_suggestions(created_at DESC);

-- =============================================================================
-- Triggers
-- =============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_order_tags_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_order_tags_updated_at
    BEFORE UPDATE ON order_tags
    FOR EACH ROW
    EXECUTE FUNCTION update_order_tags_updated_at();

CREATE TRIGGER trigger_update_order_tag_rules_updated_at
    BEFORE UPDATE ON order_tag_rules
    FOR EACH ROW
    EXECUTE FUNCTION update_order_tags_updated_at();

CREATE TRIGGER trigger_update_order_tag_suggestions_updated_at
    BEFORE UPDATE ON order_tag_suggestions
    FOR EACH ROW
    EXECUTE FUNCTION update_order_tags_updated_at();

-- Track tag assignment changes
CREATE OR REPLACE FUNCTION track_order_tag_changes()
RETURNS TRIGGER AS $$
DECLARE
    change_type_val VARCHAR(20);
BEGIN
    IF TG_OP = 'INSERT' THEN
        change_type_val := 'assigned';
        INSERT INTO order_tag_history (
            order_tag_id, order_id, store_id, tag_name, tag_slug,
            change_type, changed_by_user_id, change_source
        ) VALUES (
            NEW.id, NEW.order_id, NEW.store_id, NEW.tag_name, NEW.tag_slug,
            change_type_val, NEW.assigned_by_user_id, 'system'
        );
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        change_type_val := 'updated';
        
        -- Track activation/deactivation
        IF OLD.is_active != NEW.is_active THEN
            change_type_val := CASE WHEN NEW.is_active THEN 'activated' ELSE 'deactivated' END;
            INSERT INTO order_tag_history (
                order_tag_id, order_id, store_id, tag_name, tag_slug,
                change_type, field_name, old_value, new_value, change_source
            ) VALUES (
                NEW.id, NEW.order_id, NEW.store_id, NEW.tag_name, NEW.tag_slug,
                change_type_val, 'is_active', OLD.is_active::text, NEW.is_active::text, 'system'
            );
        END IF;
        
        -- Track performance score changes
        IF OLD.performance_score IS DISTINCT FROM NEW.performance_score THEN
            INSERT INTO order_tag_history (
                order_tag_id, order_id, store_id, tag_name, tag_slug,
                change_type, field_name, old_value, new_value, change_source
            ) VALUES (
                NEW.id, NEW.order_id, NEW.store_id, NEW.tag_name, NEW.tag_slug,
                'updated', 'performance_score', OLD.performance_score::text, NEW.performance_score::text, 'system'
            );
        END IF;
        
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO order_tag_history (
            order_tag_id, order_id, store_id, tag_name, tag_slug,
            change_type, change_source
        ) VALUES (
            OLD.id, OLD.order_id, OLD.store_id, OLD.tag_name, OLD.tag_slug,
            'removed', 'system'
        );
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_track_order_tag_changes
    AFTER INSERT OR UPDATE OR DELETE ON order_tags
    FOR EACH ROW
    EXECUTE FUNCTION track_order_tag_changes();

-- Auto-expire suggestions
CREATE OR REPLACE FUNCTION auto_expire_tag_suggestions()
RETURNS TRIGGER AS $$
BEGIN
    -- Auto-expire suggestions that have passed their expiration date
    UPDATE order_tag_suggestions 
    SET 
        status = 'expired',
        updated_at = CURRENT_TIMESTAMP
    WHERE expires_at <= CURRENT_TIMESTAMP 
    AND status = 'pending';
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_expire_tag_suggestions
    AFTER INSERT OR UPDATE ON order_tag_suggestions
    FOR EACH STATEMENT
    EXECUTE FUNCTION auto_expire_tag_suggestions();

-- Update tag performance scores
CREATE OR REPLACE FUNCTION update_tag_performance_score()
RETURNS TRIGGER AS $$
DECLARE
    usage_score DECIMAL(3,2);
    click_score DECIMAL(3,2);
    conversion_score DECIMAL(3,2);
    quality_score DECIMAL(3,2);
BEGIN
    -- Calculate performance score based on various metrics
    usage_score := LEAST(1.00, NEW.usage_count / 100.0); -- Normalize to 0-1
    click_score := CASE 
        WHEN NEW.usage_count = 0 THEN 0.00
        ELSE LEAST(1.00, NEW.click_count::DECIMAL / NEW.usage_count)
    END;
    conversion_score := NEW.conversion_rate / 100.0;
    quality_score := NEW.quality_score;
    
    -- Calculate weighted performance score
    NEW.performance_score := (
        usage_score * 0.25 +
        click_score * 0.25 +
        conversion_score * 0.30 +
        quality_score * 0.20
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_tag_performance_score
    BEFORE INSERT OR UPDATE ON order_tags
    FOR EACH ROW
    EXECUTE FUNCTION update_tag_performance_score();

-- =============================================================================
-- Helper Functions
-- =============================================================================

/**
 * Get tags for order
 * @param p_order_id UUID - Order ID
 * @return TABLE - Order tags
 */
CREATE OR REPLACE FUNCTION get_order_tags(
    p_order_id UUID
)
RETURNS TABLE (
    tag_id UUID,
    tag_name VARCHAR,
    tag_slug VARCHAR,
    tag_color VARCHAR,
    tag_icon VARCHAR,
    is_featured BOOLEAN,
    weight INTEGER,
    performance_score DECIMAL,
    assignment_source VARCHAR,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ot.id as tag_id,
        ot.tag_name,
        ot.tag_slug,
        ot.tag_color,
        ot.tag_icon,
        ot.is_featured,
        ot.weight,
        ot.performance_score,
        ot.assignment_source,
        ot.created_at
    FROM order_tags ot
    WHERE ot.order_id = p_order_id
    AND ot.is_active = TRUE
    ORDER BY ot.display_order, ot.weight DESC, ot.tag_name;
END;
$$ LANGUAGE plpgsql;

/**
 * Assign tag to order
 * @param p_order_id UUID - Order ID
 * @param p_tag_name VARCHAR - Tag name
 * @param p_assigned_by_user_id UUID - User who assigned the tag
 * @param p_assignment_source VARCHAR - Assignment source
 * @return UUID - Tag assignment ID
 */
CREATE OR REPLACE FUNCTION assign_order_tag(
    p_order_id UUID,
    p_tag_name VARCHAR,
    p_assigned_by_user_id UUID DEFAULT NULL,
    p_assignment_source VARCHAR DEFAULT 'manual'
)
RETURNS UUID AS $$
DECLARE
    tag_id UUID;
    order_record orders;
    tag_slug_val VARCHAR(100);
BEGIN
    -- Get order record
    SELECT * INTO order_record FROM orders WHERE id = p_order_id;
    
    IF order_record.id IS NULL THEN
        RAISE EXCEPTION 'Order not found';
    END IF;
    
    -- Generate tag slug
    tag_slug_val := LOWER(REPLACE(TRIM(p_tag_name), ' ', '_'));
    
    -- Check if tag already exists for this order
    SELECT id INTO tag_id 
    FROM order_tags 
    WHERE order_id = p_order_id AND tag_slug = tag_slug_val;
    
    IF tag_id IS NOT NULL THEN
        -- Reactivate if exists but inactive
        UPDATE order_tags 
        SET 
            is_active = TRUE,
            usage_count = usage_count + 1,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = tag_id;
        
        RETURN tag_id;
    END IF;
    
    -- Insert new tag assignment
    INSERT INTO order_tags (
        order_id, store_id, tag_name, tag_slug,
        assigned_by_user_id, assignment_source
    ) VALUES (
        p_order_id, order_record.store_id, p_tag_name, tag_slug_val,
        p_assigned_by_user_id, p_assignment_source
    ) RETURNING id INTO tag_id;
    
    RETURN tag_id;
END;
$$ LANGUAGE plpgsql;

/**
 * Remove tag from order
 * @param p_order_id UUID - Order ID
 * @param p_tag_slug VARCHAR - Tag slug
 * @return BOOLEAN - Success status
 */
CREATE OR REPLACE FUNCTION remove_order_tag(
    p_order_id UUID,
    p_tag_slug VARCHAR
)
RETURNS BOOLEAN AS $$
DECLARE
    tag_exists BOOLEAN;
BEGIN
    -- Check if tag exists
    SELECT EXISTS(
        SELECT 1 FROM order_tags 
        WHERE order_id = p_order_id AND tag_slug = p_tag_slug AND is_active = TRUE
    ) INTO tag_exists;
    
    IF NOT tag_exists THEN
        RETURN FALSE;
    END IF;
    
    -- Deactivate tag instead of deleting
    UPDATE order_tags 
    SET 
        is_active = FALSE,
        updated_at = CURRENT_TIMESTAMP
    WHERE order_id = p_order_id AND tag_slug = p_tag_slug;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

/**
 * Apply tag rules to order
 * @param p_order_id UUID - Order ID
 * @return INTEGER - Number of rules applied
 */
CREATE OR REPLACE FUNCTION apply_order_tag_rules(
    p_order_id UUID
)
RETURNS INTEGER AS $$
DECLARE
    rule_record order_tag_rules;
    order_record orders;
    rules_applied INTEGER := 0;
    condition_met BOOLEAN;
BEGIN
    -- Get order record
    SELECT * INTO order_record FROM orders WHERE id = p_order_id;
    
    IF order_record.id IS NULL THEN
        RETURN 0;
    END IF;
    
    -- Loop through active rules for this store
    FOR rule_record IN 
        SELECT * FROM order_tag_rules 
        WHERE store_id = order_record.store_id 
        AND is_active = TRUE
        ORDER BY priority DESC, execution_order
    LOOP
        -- Check if rule conditions are met (simplified example)
        condition_met := TRUE; -- This would be replaced with actual condition evaluation
        
        IF condition_met THEN
            -- Apply the rule by assigning the tag
            PERFORM assign_order_tag(
                p_order_id,
                rule_record.tag_name,
                NULL,
                'rule_based'
            );
            
            -- Update rule execution statistics
            UPDATE order_tag_rules 
            SET 
                execution_count = execution_count + 1,
                success_count = success_count + 1,
                last_executed_at = CURRENT_TIMESTAMP
            WHERE id = rule_record.id;
            
            rules_applied := rules_applied + 1;
        END IF;
    END LOOP;
    
    RETURN rules_applied;
END;
$$ LANGUAGE plpgsql;

/**
 * Generate tag suggestions for order
 * @param p_order_id UUID - Order ID
 * @param p_max_suggestions INTEGER - Maximum number of suggestions
 * @return INTEGER - Number of suggestions generated
 */
CREATE OR REPLACE FUNCTION generate_order_tag_suggestions(
    p_order_id UUID,
    p_max_suggestions INTEGER DEFAULT 5
)
RETURNS INTEGER AS $$
DECLARE
    order_record orders;
    suggestions_generated INTEGER := 0;
    suggestion_record RECORD;
BEGIN
    -- Get order record
    SELECT * INTO order_record FROM orders WHERE id = p_order_id;
    
    IF order_record.id IS NULL THEN
        RETURN 0;
    END IF;
    
    -- Clear existing pending suggestions
    DELETE FROM order_tag_suggestions 
    WHERE order_id = p_order_id AND status = 'pending';
    
    -- Generate suggestions based on similar orders (simplified example)
    FOR suggestion_record IN
        SELECT 
            ot.tag_name,
            ot.tag_slug,
            AVG(ot.performance_score) as avg_performance,
            COUNT(*) as usage_frequency
        FROM order_tags ot
        JOIN orders o ON ot.order_id = o.id
        WHERE o.store_id = order_record.store_id
        AND o.total_amount BETWEEN (order_record.total_amount * 0.8) AND (order_record.total_amount * 1.2)
        AND ot.is_active = TRUE
        AND NOT EXISTS (
            SELECT 1 FROM order_tags existing
            WHERE existing.order_id = p_order_id 
            AND existing.tag_slug = ot.tag_slug
        )
        GROUP BY ot.tag_name, ot.tag_slug
        HAVING COUNT(*) >= 2
        ORDER BY AVG(ot.performance_score) DESC, COUNT(*) DESC
        LIMIT p_max_suggestions
    LOOP
        -- Insert suggestion
        INSERT INTO order_tag_suggestions (
            order_id, store_id, suggested_tag_name, suggested_tag_slug,
            confidence_score, suggestion_reason, suggestion_source
        ) VALUES (
            p_order_id, order_record.store_id, 
            suggestion_record.tag_name, suggestion_record.tag_slug,
            LEAST(1.00, suggestion_record.avg_performance),
            FORMAT('Used in %s similar orders with %.2f%% performance', 
                   suggestion_record.usage_frequency, 
                   suggestion_record.avg_performance * 100),
            'similar_orders'
        );
        
        suggestions_generated := suggestions_generated + 1;
    END LOOP;
    
    RETURN suggestions_generated;
END;
$$ LANGUAGE plpgsql;

/**
 * Get tag assignment statistics for store
 * @param p_store_id UUID - Store ID
 * @return JSONB - Tag statistics
 */
CREATE OR REPLACE FUNCTION get_order_tag_stats(
    p_store_id UUID
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_tag_assignments', COUNT(*),
        'active_tag_assignments', COUNT(*) FILTER (WHERE is_active = TRUE),
        'unique_tags', COUNT(DISTINCT tag_slug),
        'system_tags', COUNT(*) FILTER (WHERE is_system_tag = TRUE),
        'featured_tags', COUNT(*) FILTER (WHERE is_featured = TRUE),
        'manual_assignments', COUNT(*) FILTER (WHERE assignment_source = 'manual'),
        'automatic_assignments', COUNT(*) FILTER (WHERE assignment_source = 'automatic'),
        'rule_based_assignments', COUNT(*) FILTER (WHERE assignment_source = 'rule_based'),
        'avg_performance_score', AVG(performance_score),
        'avg_quality_score', AVG(quality_score),
        'avg_confidence_score', AVG(confidence_score),
        'avg_usage_count', AVG(usage_count),
        'avg_conversion_rate', AVG(conversion_rate),
        'assignment_sources', (
            SELECT jsonb_object_agg(assignment_source, source_count)
            FROM (
                SELECT assignment_source, COUNT(*) as source_count
                FROM order_tags
                WHERE store_id = p_store_id
                GROUP BY assignment_source
            ) source_stats
        ),
        'top_tags', (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'tag_name', tag_name,
                    'tag_slug', tag_slug,
                    'usage_count', SUM(usage_count),
                    'avg_performance_score', AVG(performance_score)
                )
            )
            FROM (
                SELECT 
                    tag_name, tag_slug,
                    SUM(usage_count) as total_usage,
                    AVG(performance_score) as avg_performance
                FROM order_tags
                WHERE store_id = p_store_id AND is_active = TRUE
                GROUP BY tag_name, tag_slug
                ORDER BY SUM(usage_count) DESC, AVG(performance_score) DESC
                LIMIT 10
            ) top_tags_stats
        ),
        'validation_statuses', (
            SELECT jsonb_object_agg(validation_status, status_count)
            FROM (
                SELECT validation_status, COUNT(*) as status_count
                FROM order_tags
                WHERE store_id = p_store_id
                GROUP BY validation_status
            ) validation_stats
        )
    ) INTO result
    FROM order_tags
    WHERE store_id = p_store_id;
    
    RETURN COALESCE(result, '{"error": "No tag assignments found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Comments
-- =============================================================================

COMMENT ON TABLE order_tags IS 'Normalized tags from orders.tags JSONB column';
COMMENT ON TABLE order_tag_history IS 'Track changes to order tag assignments';
COMMENT ON TABLE order_tag_rules IS 'Rules for automatic tag assignment';
COMMENT ON TABLE order_tag_suggestions IS 'AI-generated tag suggestions';

COMMENT ON COLUMN order_tags.confidence_score IS 'Confidence in tag assignment (0.00 to 1.00)';
COMMENT ON COLUMN order_tags.performance_score IS 'Overall tag performance score';
COMMENT ON COLUMN order_tags.quality_score IS 'Tag quality score based on various factors';
COMMENT ON COLUMN order_tags.weight IS 'Tag weight for sorting and importance';

COMMENT ON FUNCTION get_order_tags(UUID) IS 'Get tags for order';
COMMENT ON FUNCTION assign_order_tag(UUID, VARCHAR, UUID, VARCHAR) IS 'Assign tag to order';
COMMENT ON FUNCTION remove_order_tag(UUID, VARCHAR) IS 'Remove tag from order';
COMMENT ON FUNCTION apply_order_tag_rules(UUID) IS 'Apply tag rules to order';
COMMENT ON FUNCTION generate_order_tag_suggestions(UUID, INTEGER) IS 'Generate tag suggestions for order';
COMMENT ON FUNCTION get_order_tag_stats(UUID) IS 'Get tag assignment statistics for store';