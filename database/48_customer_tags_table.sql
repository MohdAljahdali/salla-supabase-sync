-- =============================================================================
-- Customer Tags Table
-- =============================================================================
-- This table normalizes the 'tags' JSONB column from the customers table
-- Stores customer tags for segmentation and organization

CREATE TABLE IF NOT EXISTS customer_tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    tag_id UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Tag assignment details
    assigned_by_user_id UUID, -- Who assigned this tag
    assignment_source VARCHAR(50) DEFAULT 'manual' CHECK (assignment_source IN (
        'manual', 'automatic', 'import', 'api', 'rule_based', 'behavior_based', 'purchase_based'
    )),
    assignment_reason TEXT, -- Why this tag was assigned
    
    -- Tag properties
    tag_value VARCHAR(500), -- Custom value for the tag (if applicable)
    tag_context VARCHAR(100), -- Context where tag applies (e.g., 'purchase', 'behavior', 'demographic')
    
    -- Display and visibility
    is_visible BOOLEAN DEFAULT TRUE,
    is_public BOOLEAN DEFAULT FALSE, -- Whether customer can see this tag
    display_order INTEGER DEFAULT 0,
    
    -- Tag lifecycle
    is_active BOOLEAN DEFAULT TRUE,
    expires_at TIMESTAMPTZ, -- When this tag assignment expires
    auto_remove BOOLEAN DEFAULT FALSE, -- Whether to auto-remove based on conditions
    
    -- Performance tracking
    click_count INTEGER DEFAULT 0, -- If tag is clickable in UI
    conversion_count INTEGER DEFAULT 0, -- Conversions attributed to this tag
    revenue_attributed DECIMAL(12,2) DEFAULT 0,
    
    -- A/B testing
    ab_test_group VARCHAR(50),
    ab_test_variant VARCHAR(50),
    
    -- Confidence and quality
    confidence_score DECIMAL(3,2) DEFAULT 1.0 CHECK (confidence_score >= 0 AND confidence_score <= 1),
    quality_score DECIMAL(3,2) DEFAULT 1.0 CHECK (quality_score >= 0 AND quality_score <= 1),
    
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
    CONSTRAINT customer_tags_unique_assignment UNIQUE(customer_id, tag_id),
    CONSTRAINT customer_tags_confidence_check CHECK (confidence_score >= 0 AND confidence_score <= 1),
    CONSTRAINT customer_tags_quality_check CHECK (quality_score >= 0 AND quality_score <= 1)
);

-- =============================================================================
-- Customer Tag History Table
-- =============================================================================
-- Track changes to customer tag assignments

CREATE TABLE IF NOT EXISTS customer_tag_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_tag_id UUID REFERENCES customer_tags(id) ON DELETE SET NULL,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    tag_id UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Change information
    change_type VARCHAR(20) NOT NULL CHECK (change_type IN (
        'assigned', 'removed', 'updated', 'expired', 'auto_removed', 'bulk_assigned'
    )),
    changed_fields JSONB DEFAULT '[]', -- List of changed field names
    old_values JSONB DEFAULT '{}', -- Previous values
    new_values JSONB DEFAULT '{}', -- New values
    
    -- Change context
    changed_by_user_id UUID,
    change_reason VARCHAR(255),
    change_source VARCHAR(50) DEFAULT 'system',
    batch_id UUID, -- For bulk operations
    
    -- Performance impact
    performance_impact JSONB DEFAULT '{}', -- Impact on customer metrics
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- Customer Tag Rules Table
-- =============================================================================
-- Define rules for automatic tag assignment

CREATE TABLE IF NOT EXISTS customer_tag_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tag_id UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Rule identification
    rule_name VARCHAR(255) NOT NULL,
    rule_description TEXT,
    
    -- Rule conditions
    conditions JSONB NOT NULL, -- Rule conditions in JSON format
    condition_logic VARCHAR(10) DEFAULT 'AND' CHECK (condition_logic IN ('AND', 'OR')),
    
    -- Rule actions
    action_type VARCHAR(50) DEFAULT 'assign' CHECK (action_type IN (
        'assign', 'remove', 'update_value', 'set_expiry'
    )),
    action_parameters JSONB DEFAULT '{}',
    
    -- Rule properties
    is_active BOOLEAN DEFAULT TRUE,
    priority INTEGER DEFAULT 0, -- Higher priority rules run first
    
    -- Execution settings
    execution_frequency VARCHAR(20) DEFAULT 'immediate' CHECK (execution_frequency IN (
        'immediate', 'hourly', 'daily', 'weekly', 'monthly'
    )),
    last_executed_at TIMESTAMPTZ,
    next_execution_at TIMESTAMPTZ,
    
    -- Performance tracking
    execution_count INTEGER DEFAULT 0,
    success_count INTEGER DEFAULT 0,
    error_count INTEGER DEFAULT 0,
    customers_affected INTEGER DEFAULT 0,
    
    -- Rule lifecycle
    effective_from TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    effective_until TIMESTAMPTZ,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT customer_tag_rules_unique_name UNIQUE(store_id, rule_name)
);

-- =============================================================================
-- Customer Tag Suggestions Table
-- =============================================================================
-- Store AI/ML generated tag suggestions

CREATE TABLE IF NOT EXISTS customer_tag_suggestions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    tag_id UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Suggestion details
    suggestion_source VARCHAR(50) NOT NULL CHECK (suggestion_source IN (
        'ml_model', 'behavior_analysis', 'purchase_pattern', 'demographic_analysis', 
        'similarity_analysis', 'manual_review'
    )),
    suggestion_reason TEXT,
    
    -- Confidence and scoring
    confidence_score DECIMAL(3,2) NOT NULL CHECK (confidence_score >= 0 AND confidence_score <= 1),
    relevance_score DECIMAL(3,2) CHECK (relevance_score >= 0 AND relevance_score <= 1),
    
    -- Suggestion status
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN (
        'pending', 'approved', 'rejected', 'auto_applied', 'expired'
    )),
    reviewed_by_user_id UUID,
    reviewed_at TIMESTAMPTZ,
    review_notes TEXT,
    
    -- Supporting data
    supporting_data JSONB DEFAULT '{}', -- Data that supports this suggestion
    model_version VARCHAR(50), -- Version of ML model that generated suggestion
    
    -- Lifecycle
    expires_at TIMESTAMPTZ DEFAULT (CURRENT_TIMESTAMP + INTERVAL '30 days'),
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT customer_tag_suggestions_unique UNIQUE(customer_id, tag_id, suggestion_source),
    CONSTRAINT customer_tag_suggestions_confidence_check CHECK (confidence_score >= 0 AND confidence_score <= 1)
);

-- =============================================================================
-- Indexes
-- =============================================================================

-- Basic indexes
CREATE INDEX IF NOT EXISTS idx_customer_tags_customer_id ON customer_tags(customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_tags_tag_id ON customer_tags(tag_id);
CREATE INDEX IF NOT EXISTS idx_customer_tags_store_id ON customer_tags(store_id);
CREATE INDEX IF NOT EXISTS idx_customer_tags_external_tag_id ON customer_tags(external_tag_id);

-- Assignment details
CREATE INDEX IF NOT EXISTS idx_customer_tags_assigned_by ON customer_tags(assigned_by_user_id);
CREATE INDEX IF NOT EXISTS idx_customer_tags_assignment_source ON customer_tags(assignment_source);
CREATE INDEX IF NOT EXISTS idx_customer_tags_tag_context ON customer_tags(tag_context);

-- Display and visibility
CREATE INDEX IF NOT EXISTS idx_customer_tags_is_visible ON customer_tags(is_visible);
CREATE INDEX IF NOT EXISTS idx_customer_tags_is_public ON customer_tags(is_public);
CREATE INDEX IF NOT EXISTS idx_customer_tags_display_order ON customer_tags(display_order);
CREATE INDEX IF NOT EXISTS idx_customer_tags_is_active ON customer_tags(is_active);

-- Lifecycle
CREATE INDEX IF NOT EXISTS idx_customer_tags_expires_at ON customer_tags(expires_at) WHERE expires_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_customer_tags_auto_remove ON customer_tags(auto_remove) WHERE auto_remove = TRUE;

-- Performance tracking
CREATE INDEX IF NOT EXISTS idx_customer_tags_click_count ON customer_tags(click_count DESC);
CREATE INDEX IF NOT EXISTS idx_customer_tags_conversion_count ON customer_tags(conversion_count DESC);
CREATE INDEX IF NOT EXISTS idx_customer_tags_revenue_attributed ON customer_tags(revenue_attributed DESC);

-- A/B testing
CREATE INDEX IF NOT EXISTS idx_customer_tags_ab_test_group ON customer_tags(ab_test_group);
CREATE INDEX IF NOT EXISTS idx_customer_tags_ab_test_variant ON customer_tags(ab_test_variant);

-- Quality scores
CREATE INDEX IF NOT EXISTS idx_customer_tags_confidence_score ON customer_tags(confidence_score DESC);
CREATE INDEX IF NOT EXISTS idx_customer_tags_quality_score ON customer_tags(quality_score DESC);

-- Sync information
CREATE INDEX IF NOT EXISTS idx_customer_tags_sync_status ON customer_tags(sync_status);
CREATE INDEX IF NOT EXISTS idx_customer_tags_last_sync_at ON customer_tags(last_sync_at DESC);

-- Timestamps
CREATE INDEX IF NOT EXISTS idx_customer_tags_created_at ON customer_tags(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_customer_tags_updated_at ON customer_tags(updated_at DESC);

-- JSONB indexes
CREATE INDEX IF NOT EXISTS idx_customer_tags_external_references ON customer_tags USING gin(external_references);
CREATE INDEX IF NOT EXISTS idx_customer_tags_custom_fields ON customer_tags USING gin(custom_fields);
CREATE INDEX IF NOT EXISTS idx_customer_tags_sync_errors ON customer_tags USING gin(sync_errors);

-- Composite indexes
CREATE INDEX IF NOT EXISTS idx_customer_tags_customer_active ON customer_tags(customer_id, is_active, is_visible);
CREATE INDEX IF NOT EXISTS idx_customer_tags_tag_performance ON customer_tags(tag_id, conversion_count DESC, revenue_attributed DESC);
CREATE INDEX IF NOT EXISTS idx_customer_tags_assignment ON customer_tags(assignment_source, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_customer_tags_expiry ON customer_tags(expires_at, auto_remove) WHERE expires_at IS NOT NULL;

-- History table indexes
CREATE INDEX IF NOT EXISTS idx_customer_tag_history_customer_tag_id ON customer_tag_history(customer_tag_id);
CREATE INDEX IF NOT EXISTS idx_customer_tag_history_customer_id ON customer_tag_history(customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_tag_history_tag_id ON customer_tag_history(tag_id);
CREATE INDEX IF NOT EXISTS idx_customer_tag_history_store_id ON customer_tag_history(store_id);
CREATE INDEX IF NOT EXISTS idx_customer_tag_history_change_type ON customer_tag_history(change_type);
CREATE INDEX IF NOT EXISTS idx_customer_tag_history_created_at ON customer_tag_history(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_customer_tag_history_changed_by ON customer_tag_history(changed_by_user_id);
CREATE INDEX IF NOT EXISTS idx_customer_tag_history_batch_id ON customer_tag_history(batch_id) WHERE batch_id IS NOT NULL;

-- Rules table indexes
CREATE INDEX IF NOT EXISTS idx_customer_tag_rules_tag_id ON customer_tag_rules(tag_id);
CREATE INDEX IF NOT EXISTS idx_customer_tag_rules_store_id ON customer_tag_rules(store_id);
CREATE INDEX IF NOT EXISTS idx_customer_tag_rules_is_active ON customer_tag_rules(is_active);
CREATE INDEX IF NOT EXISTS idx_customer_tag_rules_priority ON customer_tag_rules(priority DESC);
CREATE INDEX IF NOT EXISTS idx_customer_tag_rules_execution_frequency ON customer_tag_rules(execution_frequency);
CREATE INDEX IF NOT EXISTS idx_customer_tag_rules_next_execution ON customer_tag_rules(next_execution_at) WHERE next_execution_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_customer_tag_rules_effective_period ON customer_tag_rules(effective_from, effective_until);
CREATE INDEX IF NOT EXISTS idx_customer_tag_rules_performance ON customer_tag_rules(success_count DESC, customers_affected DESC);

-- Suggestions table indexes
CREATE INDEX IF NOT EXISTS idx_customer_tag_suggestions_customer_id ON customer_tag_suggestions(customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_tag_suggestions_tag_id ON customer_tag_suggestions(tag_id);
CREATE INDEX IF NOT EXISTS idx_customer_tag_suggestions_store_id ON customer_tag_suggestions(store_id);
CREATE INDEX IF NOT EXISTS idx_customer_tag_suggestions_source ON customer_tag_suggestions(suggestion_source);
CREATE INDEX IF NOT EXISTS idx_customer_tag_suggestions_status ON customer_tag_suggestions(status);
CREATE INDEX IF NOT EXISTS idx_customer_tag_suggestions_confidence ON customer_tag_suggestions(confidence_score DESC);
CREATE INDEX IF NOT EXISTS idx_customer_tag_suggestions_relevance ON customer_tag_suggestions(relevance_score DESC);
CREATE INDEX IF NOT EXISTS idx_customer_tag_suggestions_expires_at ON customer_tag_suggestions(expires_at);
CREATE INDEX IF NOT EXISTS idx_customer_tag_suggestions_reviewed_by ON customer_tag_suggestions(reviewed_by_user_id);
CREATE INDEX IF NOT EXISTS idx_customer_tag_suggestions_model_version ON customer_tag_suggestions(model_version);

-- =============================================================================
-- Triggers
-- =============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_customer_tags_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_customer_tags_updated_at
    BEFORE UPDATE ON customer_tags
    FOR EACH ROW
    EXECUTE FUNCTION update_customer_tags_updated_at();

CREATE TRIGGER trigger_update_customer_tag_rules_updated_at
    BEFORE UPDATE ON customer_tag_rules
    FOR EACH ROW
    EXECUTE FUNCTION update_customer_tags_updated_at();

CREATE TRIGGER trigger_update_customer_tag_suggestions_updated_at
    BEFORE UPDATE ON customer_tag_suggestions
    FOR EACH ROW
    EXECUTE FUNCTION update_customer_tags_updated_at();

-- Track tag assignment changes
CREATE OR REPLACE FUNCTION track_customer_tag_changes()
RETURNS TRIGGER AS $$
DECLARE
    change_type_val VARCHAR(20);
BEGIN
    IF TG_OP = 'INSERT' THEN
        change_type_val := 'assigned';
        INSERT INTO customer_tag_history (
            customer_tag_id, customer_id, tag_id, store_id, change_type,
            new_values, change_source
        ) VALUES (
            NEW.id, NEW.customer_id, NEW.tag_id, NEW.store_id, change_type_val,
            to_jsonb(NEW), 'system'
        );
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        change_type_val := 'updated';
        INSERT INTO customer_tag_history (
            customer_tag_id, customer_id, tag_id, store_id, change_type,
            old_values, new_values, change_source
        ) VALUES (
            NEW.id, NEW.customer_id, NEW.tag_id, NEW.store_id, change_type_val,
            to_jsonb(OLD), to_jsonb(NEW), 'system'
        );
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        change_type_val := 'removed';
        INSERT INTO customer_tag_history (
            customer_tag_id, customer_id, tag_id, store_id, change_type,
            old_values, change_source
        ) VALUES (
            OLD.id, OLD.customer_id, OLD.tag_id, OLD.store_id, change_type_val,
            to_jsonb(OLD), 'system'
        );
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_track_customer_tag_changes
    AFTER INSERT OR UPDATE OR DELETE ON customer_tags
    FOR EACH ROW
    EXECUTE FUNCTION track_customer_tag_changes();

-- Auto-expire suggestions
CREATE OR REPLACE FUNCTION auto_expire_suggestions()
RETURNS TRIGGER AS $$
BEGIN
    -- Auto-expire old suggestions
    UPDATE customer_tag_suggestions 
    SET status = 'expired'
    WHERE expires_at < CURRENT_TIMESTAMP 
    AND status = 'pending';
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_expire_suggestions
    AFTER INSERT ON customer_tag_suggestions
    FOR EACH STATEMENT
    EXECUTE FUNCTION auto_expire_suggestions();

-- Update tag performance scores
CREATE OR REPLACE FUNCTION update_tag_performance_score()
RETURNS TRIGGER AS $$
DECLARE
    performance_score DECIMAL(3,2);
BEGIN
    -- Calculate performance score based on conversions and revenue
    SELECT 
        LEAST(1.0, (
            (COALESCE(NEW.conversion_count, 0) * 0.6) + 
            (LEAST(COALESCE(NEW.revenue_attributed, 0) / 1000, 1) * 0.4)
        ))
    INTO performance_score;
    
    -- Update quality score based on performance
    NEW.quality_score := GREATEST(0.1, performance_score);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_tag_performance_score
    BEFORE UPDATE ON customer_tags
    FOR EACH ROW
    WHEN (NEW.conversion_count != OLD.conversion_count OR NEW.revenue_attributed != OLD.revenue_attributed)
    EXECUTE FUNCTION update_tag_performance_score();

-- =============================================================================
-- Helper Functions
-- =============================================================================

/**
 * Get customer tags with tag details
 * @param p_customer_id UUID - Customer ID
 * @param p_context VARCHAR - Tag context filter
 * @return TABLE - Customer tags with details
 */
CREATE OR REPLACE FUNCTION get_customer_tags(
    p_customer_id UUID,
    p_context VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    tag_id UUID,
    tag_name VARCHAR,
    tag_value VARCHAR,
    tag_context VARCHAR,
    assignment_source VARCHAR,
    confidence_score DECIMAL,
    is_active BOOLEAN,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ct.tag_id,
        t.name as tag_name,
        ct.tag_value,
        ct.tag_context,
        ct.assignment_source,
        ct.confidence_score,
        ct.is_active,
        ct.created_at
    FROM customer_tags ct
    JOIN tags t ON t.id = ct.tag_id
    WHERE ct.customer_id = p_customer_id
    AND ct.is_visible = TRUE
    AND (p_context IS NULL OR ct.tag_context = p_context)
    ORDER BY ct.display_order, ct.created_at DESC;
END;
$$ LANGUAGE plpgsql;

/**
 * Assign tag to customer
 * @param p_customer_id UUID - Customer ID
 * @param p_tag_id UUID - Tag ID
 * @param p_assignment_source VARCHAR - Assignment source
 * @param p_assigned_by_user_id UUID - User who assigned
 * @return BOOLEAN - Success status
 */
CREATE OR REPLACE FUNCTION assign_customer_tag(
    p_customer_id UUID,
    p_tag_id UUID,
    p_assignment_source VARCHAR DEFAULT 'manual',
    p_assigned_by_user_id UUID DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    store_id_val UUID;
    existing_assignment UUID;
BEGIN
    -- Get store_id from customer
    SELECT store_id INTO store_id_val FROM customers WHERE id = p_customer_id;
    
    IF store_id_val IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Check if assignment already exists
    SELECT id INTO existing_assignment 
    FROM customer_tags 
    WHERE customer_id = p_customer_id AND tag_id = p_tag_id;
    
    IF existing_assignment IS NOT NULL THEN
        -- Update existing assignment
        UPDATE customer_tags 
        SET 
            is_active = TRUE,
            assignment_source = p_assignment_source,
            assigned_by_user_id = p_assigned_by_user_id,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = existing_assignment;
    ELSE
        -- Create new assignment
        INSERT INTO customer_tags (
            customer_id, tag_id, store_id, assignment_source, assigned_by_user_id
        ) VALUES (
            p_customer_id, p_tag_id, store_id_val, p_assignment_source, p_assigned_by_user_id
        );
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

/**
 * Remove tag from customer
 * @param p_customer_id UUID - Customer ID
 * @param p_tag_id UUID - Tag ID
 * @param p_removed_by_user_id UUID - User who removed
 * @return BOOLEAN - Success status
 */
CREATE OR REPLACE FUNCTION remove_customer_tag(
    p_customer_id UUID,
    p_tag_id UUID,
    p_removed_by_user_id UUID DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    existing_assignment UUID;
BEGIN
    -- Check if assignment exists
    SELECT id INTO existing_assignment 
    FROM customer_tags 
    WHERE customer_id = p_customer_id AND tag_id = p_tag_id AND is_active = TRUE;
    
    IF existing_assignment IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Mark as inactive instead of deleting
    UPDATE customer_tags 
    SET 
        is_active = FALSE,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = existing_assignment;
    
    -- Log the removal
    INSERT INTO customer_tag_history (
        customer_tag_id, customer_id, tag_id, store_id, change_type,
        changed_by_user_id, change_reason, change_source
    ) SELECT 
        id, customer_id, tag_id, store_id, 'removed',
        p_removed_by_user_id, 'Manual removal', 'manual'
    FROM customer_tags WHERE id = existing_assignment;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

/**
 * Apply tag rules to customer
 * @param p_customer_id UUID - Customer ID
 * @return INTEGER - Number of rules applied
 */
CREATE OR REPLACE FUNCTION apply_customer_tag_rules(
    p_customer_id UUID
)
RETURNS INTEGER AS $$
DECLARE
    rule_record RECORD;
    rules_applied INTEGER := 0;
    customer_data JSONB;
BEGIN
    -- Get customer data for rule evaluation
    SELECT to_jsonb(c.*) INTO customer_data 
    FROM customers c WHERE id = p_customer_id;
    
    -- Loop through active rules
    FOR rule_record IN 
        SELECT * FROM customer_tag_rules 
        WHERE is_active = TRUE 
        AND (effective_until IS NULL OR effective_until > CURRENT_TIMESTAMP)
        ORDER BY priority DESC
    LOOP
        -- Simple rule evaluation (would need more complex logic in real implementation)
        -- This is a placeholder for rule engine integration
        
        -- Example: If rule conditions match, apply the action
        -- In real implementation, this would evaluate the JSON conditions
        -- against customer data using a proper rule engine
        
        -- For now, just increment counter
        rules_applied := rules_applied + 1;
        
        -- Update rule execution stats
        UPDATE customer_tag_rules 
        SET 
            execution_count = execution_count + 1,
            last_executed_at = CURRENT_TIMESTAMP
        WHERE id = rule_record.id;
    END LOOP;
    
    RETURN rules_applied;
END;
$$ LANGUAGE plpgsql;

/**
 * Generate tag suggestions for customer
 * @param p_customer_id UUID - Customer ID
 * @param p_suggestion_source VARCHAR - Source of suggestions
 * @return INTEGER - Number of suggestions generated
 */
CREATE OR REPLACE FUNCTION generate_customer_tag_suggestions(
    p_customer_id UUID,
    p_suggestion_source VARCHAR DEFAULT 'behavior_analysis'
)
RETURNS INTEGER AS $$
DECLARE
    suggestions_count INTEGER := 0;
    customer_data RECORD;
    store_id_val UUID;
BEGIN
    -- Get customer and store data
    SELECT c.*, c.store_id INTO customer_data, store_id_val
    FROM customers c WHERE id = p_customer_id;
    
    IF customer_data.id IS NULL THEN
        RETURN 0;
    END IF;
    
    -- Example suggestion logic (placeholder)
    -- In real implementation, this would use ML models or behavioral analysis
    
    -- High-value customer suggestion
    IF customer_data.total_spent > 1000 THEN
        INSERT INTO customer_tag_suggestions (
            customer_id, tag_id, store_id, suggestion_source,
            confidence_score, suggestion_reason
        )
        SELECT 
            p_customer_id, t.id, store_id_val, p_suggestion_source,
            0.85, 'High total spending amount'
        FROM tags t 
        WHERE t.name = 'high_value_customer' 
        AND t.store_id = store_id_val
        ON CONFLICT (customer_id, tag_id, suggestion_source) DO NOTHING;
        
        suggestions_count := suggestions_count + 1;
    END IF;
    
    -- Frequent buyer suggestion
    IF customer_data.total_orders > 10 THEN
        INSERT INTO customer_tag_suggestions (
            customer_id, tag_id, store_id, suggestion_source,
            confidence_score, suggestion_reason
        )
        SELECT 
            p_customer_id, t.id, store_id_val, p_suggestion_source,
            0.75, 'High order frequency'
        FROM tags t 
        WHERE t.name = 'frequent_buyer' 
        AND t.store_id = store_id_val
        ON CONFLICT (customer_id, tag_id, suggestion_source) DO NOTHING;
        
        suggestions_count := suggestions_count + 1;
    END IF;
    
    RETURN suggestions_count;
END;
$$ LANGUAGE plpgsql;

/**
 * Get customer tag assignment statistics
 * @param p_customer_id UUID - Customer ID
 * @return JSONB - Tag assignment statistics
 */
CREATE OR REPLACE FUNCTION get_customer_tag_stats(
    p_customer_id UUID
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_tags', COUNT(*),
        'active_tags', COUNT(*) FILTER (WHERE is_active = TRUE),
        'visible_tags', COUNT(*) FILTER (WHERE is_visible = TRUE),
        'public_tags', COUNT(*) FILTER (WHERE is_public = TRUE),
        'assignment_sources', (
            SELECT jsonb_object_agg(assignment_source, source_count)
            FROM (
                SELECT assignment_source, COUNT(*) as source_count
                FROM customer_tags
                WHERE customer_id = p_customer_id AND is_active = TRUE
                GROUP BY assignment_source
            ) source_stats
        ),
        'tag_contexts', (
            SELECT jsonb_object_agg(tag_context, context_count)
            FROM (
                SELECT tag_context, COUNT(*) as context_count
                FROM customer_tags
                WHERE customer_id = p_customer_id AND is_active = TRUE
                GROUP BY tag_context
            ) context_stats
        ),
        'avg_confidence_score', AVG(confidence_score),
        'total_conversions', SUM(conversion_count),
        'total_revenue_attributed', SUM(revenue_attributed)
    ) INTO result
    FROM customer_tags
    WHERE customer_id = p_customer_id;
    
    RETURN COALESCE(result, '{"error": "No tags found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Comments
-- =============================================================================

COMMENT ON TABLE customer_tags IS 'Normalized customer tags from customers.tags JSONB column';
COMMENT ON TABLE customer_tag_history IS 'Track changes to customer tag assignments';
COMMENT ON TABLE customer_tag_rules IS 'Rules for automatic customer tag assignment';
COMMENT ON TABLE customer_tag_suggestions IS 'AI/ML generated tag suggestions for customers';

COMMENT ON COLUMN customer_tags.assignment_source IS 'How this tag was assigned to the customer';
COMMENT ON COLUMN customer_tags.tag_context IS 'Context where this tag applies';
COMMENT ON COLUMN customer_tags.confidence_score IS 'Confidence in tag assignment (0.00 to 1.00)';
COMMENT ON COLUMN customer_tags.expires_at IS 'When this tag assignment expires';
COMMENT ON COLUMN customer_tags.revenue_attributed IS 'Revenue attributed to this tag';

COMMENT ON FUNCTION get_customer_tags(UUID, VARCHAR) IS 'Get customer tags with tag details';
COMMENT ON FUNCTION assign_customer_tag(UUID, UUID, VARCHAR, UUID) IS 'Assign tag to customer';
COMMENT ON FUNCTION remove_customer_tag(UUID, UUID, UUID) IS 'Remove tag from customer';
COMMENT ON FUNCTION apply_customer_tag_rules(UUID) IS 'Apply automatic tag rules to customer';
COMMENT ON FUNCTION generate_customer_tag_suggestions(UUID, VARCHAR) IS 'Generate tag suggestions for customer';
COMMENT ON FUNCTION get_customer_tag_stats(UUID) IS 'Get customer tag assignment statistics';