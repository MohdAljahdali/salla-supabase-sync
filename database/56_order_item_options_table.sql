-- =============================================================================
-- Order Item Options Table
-- =============================================================================
-- This table normalizes the 'selected_options' JSONB column from the order_items table
-- Stores selected product options for order items

CREATE TABLE IF NOT EXISTS order_item_options (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_item_id UUID NOT NULL REFERENCES order_items(id) ON DELETE CASCADE,
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Option identification
    option_name VARCHAR(100) NOT NULL,
    option_value TEXT NOT NULL,
    option_type VARCHAR(50) DEFAULT 'text' CHECK (option_type IN (
        'text', 'number', 'boolean', 'color', 'size', 'material', 'style', 'variant', 'custom'
    )),
    
    -- Option properties
    option_display_name VARCHAR(255),
    option_group VARCHAR(100),
    option_order INTEGER DEFAULT 0,
    is_required BOOLEAN DEFAULT FALSE,
    is_custom_option BOOLEAN DEFAULT FALSE,
    
    -- Pricing impact
    price_modifier DECIMAL(10,2) DEFAULT 0.00,
    price_modifier_type VARCHAR(20) DEFAULT 'fixed' CHECK (price_modifier_type IN (
        'fixed', 'percentage', 'multiplier'
    )),
    
    -- Weight and shipping impact
    weight_modifier DECIMAL(8,2) DEFAULT 0.00,
    shipping_impact DECIMAL(10,2) DEFAULT 0.00,
    
    -- Inventory tracking
    sku_modifier VARCHAR(100),
    stock_impact INTEGER DEFAULT 0,
    
    -- Display properties
    display_value TEXT,
    display_color VARCHAR(7), -- Hex color code
    display_image_url TEXT,
    display_icon VARCHAR(50),
    
    -- Validation
    validation_rules JSONB DEFAULT '{}',
    is_valid BOOLEAN DEFAULT TRUE,
    validation_errors JSONB DEFAULT '[]',
    
    -- Localization
    language_code VARCHAR(5) DEFAULT 'en',
    localized_names JSONB DEFAULT '{}', -- {"ar": "اللون", "en": "Color"}
    localized_values JSONB DEFAULT '{}', -- {"ar": "أحمر", "en": "Red"}
    
    -- Option source and tracking
    option_source VARCHAR(50) DEFAULT 'product' CHECK (option_source IN (
        'product', 'variant', 'custom', 'addon', 'bundle', 'personalization'
    )),
    source_reference VARCHAR(255),
    
    -- Business rules
    affects_availability BOOLEAN DEFAULT FALSE,
    affects_shipping BOOLEAN DEFAULT FALSE,
    affects_returns BOOLEAN DEFAULT FALSE,
    return_policy_override TEXT,
    
    -- Analytics and tracking
    selection_count INTEGER DEFAULT 1,
    popularity_score DECIMAL(5,2) DEFAULT 0.00,
    conversion_impact DECIMAL(3,2) DEFAULT 0.00,
    
    -- Quality and compliance
    quality_grade VARCHAR(10) DEFAULT 'A' CHECK (quality_grade IN ('A', 'B', 'C', 'D', 'F')),
    compliance_status VARCHAR(20) DEFAULT 'compliant' CHECK (compliance_status IN (
        'compliant', 'non_compliant', 'pending_review', 'exempt'
    )),
    safety_warnings JSONB DEFAULT '[]',
    
    -- External references
    external_option_id VARCHAR(255),
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
    UNIQUE(order_item_id, option_name, language_code)
);

-- =============================================================================
-- Order Item Option History Table
-- =============================================================================
-- Track changes to order item options

CREATE TABLE IF NOT EXISTS order_item_option_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    option_id UUID REFERENCES order_item_options(id) ON DELETE SET NULL,
    order_item_id UUID NOT NULL REFERENCES order_items(id) ON DELETE CASCADE,
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Option information
    option_name VARCHAR(100) NOT NULL,
    
    -- Change information
    change_type VARCHAR(20) NOT NULL CHECK (change_type IN (
        'created', 'updated', 'deleted', 'validated', 'invalidated', 'selected', 'deselected'
    )),
    old_value TEXT,
    new_value TEXT,
    old_price_modifier DECIMAL(10,2),
    new_price_modifier DECIMAL(10,2),
    
    -- Change context
    changed_by_user_id UUID,
    change_reason VARCHAR(255),
    change_source VARCHAR(50) DEFAULT 'system',
    
    -- Impact tracking
    price_impact DECIMAL(10,2) DEFAULT 0.00,
    weight_impact DECIMAL(8,2) DEFAULT 0.00,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- Order Item Option Rules Table
-- =============================================================================
-- Define rules for option combinations and dependencies

CREATE TABLE IF NOT EXISTS order_item_option_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Rule identification
    rule_name VARCHAR(100) NOT NULL,
    rule_description TEXT,
    rule_type VARCHAR(50) NOT NULL CHECK (rule_type IN (
        'dependency', 'exclusion', 'requirement', 'pricing', 'availability', 'validation'
    )),
    
    -- Rule conditions
    condition_options JSONB NOT NULL DEFAULT '{}', -- {"color": "red", "size": "large"}
    target_options JSONB NOT NULL DEFAULT '{}', -- Options affected by this rule
    
    -- Rule actions
    action_type VARCHAR(50) NOT NULL CHECK (action_type IN (
        'enable', 'disable', 'require', 'exclude', 'modify_price', 'modify_availability'
    )),
    action_parameters JSONB DEFAULT '{}',
    
    -- Rule properties
    is_active BOOLEAN DEFAULT TRUE,
    priority INTEGER DEFAULT 0,
    applies_to_all_products BOOLEAN DEFAULT FALSE,
    product_filters JSONB DEFAULT '{}',
    
    -- Validation and testing
    validation_status VARCHAR(20) DEFAULT 'valid' CHECK (validation_status IN (
        'valid', 'invalid', 'testing', 'disabled'
    )),
    last_validated_at TIMESTAMPTZ,
    
    -- Usage tracking
    application_count INTEGER DEFAULT 0,
    last_applied_at TIMESTAMPTZ,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    UNIQUE(store_id, rule_name)
);

-- =============================================================================
-- Indexes
-- =============================================================================

-- Basic indexes
CREATE INDEX IF NOT EXISTS idx_order_item_options_order_item_id ON order_item_options(order_item_id);
CREATE INDEX IF NOT EXISTS idx_order_item_options_order_id ON order_item_options(order_id);
CREATE INDEX IF NOT EXISTS idx_order_item_options_store_id ON order_item_options(store_id);
CREATE INDEX IF NOT EXISTS idx_order_item_options_option_name ON order_item_options(option_name);
CREATE INDEX IF NOT EXISTS idx_order_item_options_option_type ON order_item_options(option_type);
CREATE INDEX IF NOT EXISTS idx_order_item_options_external_option_id ON order_item_options(external_option_id);

-- Option properties
CREATE INDEX IF NOT EXISTS idx_order_item_options_option_group ON order_item_options(option_group);
CREATE INDEX IF NOT EXISTS idx_order_item_options_option_order ON order_item_options(option_order);
CREATE INDEX IF NOT EXISTS idx_order_item_options_is_required ON order_item_options(is_required) WHERE is_required = TRUE;
CREATE INDEX IF NOT EXISTS idx_order_item_options_is_custom ON order_item_options(is_custom_option) WHERE is_custom_option = TRUE;

-- Pricing impact
CREATE INDEX IF NOT EXISTS idx_order_item_options_price_modifier ON order_item_options(price_modifier) WHERE price_modifier != 0;
CREATE INDEX IF NOT EXISTS idx_order_item_options_price_modifier_type ON order_item_options(price_modifier_type);

-- Weight and shipping
CREATE INDEX IF NOT EXISTS idx_order_item_options_weight_modifier ON order_item_options(weight_modifier) WHERE weight_modifier != 0;
CREATE INDEX IF NOT EXISTS idx_order_item_options_shipping_impact ON order_item_options(shipping_impact) WHERE shipping_impact != 0;

-- Inventory tracking
CREATE INDEX IF NOT EXISTS idx_order_item_options_sku_modifier ON order_item_options(sku_modifier);
CREATE INDEX IF NOT EXISTS idx_order_item_options_stock_impact ON order_item_options(stock_impact) WHERE stock_impact != 0;

-- Validation
CREATE INDEX IF NOT EXISTS idx_order_item_options_is_valid ON order_item_options(is_valid);

-- Localization
CREATE INDEX IF NOT EXISTS idx_order_item_options_language_code ON order_item_options(language_code);

-- Option source
CREATE INDEX IF NOT EXISTS idx_order_item_options_option_source ON order_item_options(option_source);
CREATE INDEX IF NOT EXISTS idx_order_item_options_source_reference ON order_item_options(source_reference);

-- Business rules
CREATE INDEX IF NOT EXISTS idx_order_item_options_affects_availability ON order_item_options(affects_availability) WHERE affects_availability = TRUE;
CREATE INDEX IF NOT EXISTS idx_order_item_options_affects_shipping ON order_item_options(affects_shipping) WHERE affects_shipping = TRUE;
CREATE INDEX IF NOT EXISTS idx_order_item_options_affects_returns ON order_item_options(affects_returns) WHERE affects_returns = TRUE;

-- Analytics
CREATE INDEX IF NOT EXISTS idx_order_item_options_selection_count ON order_item_options(selection_count DESC);
CREATE INDEX IF NOT EXISTS idx_order_item_options_popularity_score ON order_item_options(popularity_score DESC);
CREATE INDEX IF NOT EXISTS idx_order_item_options_conversion_impact ON order_item_options(conversion_impact DESC);

-- Quality and compliance
CREATE INDEX IF NOT EXISTS idx_order_item_options_quality_grade ON order_item_options(quality_grade);
CREATE INDEX IF NOT EXISTS idx_order_item_options_compliance_status ON order_item_options(compliance_status);

-- Sync information
CREATE INDEX IF NOT EXISTS idx_order_item_options_sync_status ON order_item_options(sync_status);
CREATE INDEX IF NOT EXISTS idx_order_item_options_last_sync_at ON order_item_options(last_sync_at DESC);

-- Timestamps
CREATE INDEX IF NOT EXISTS idx_order_item_options_created_at ON order_item_options(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_item_options_updated_at ON order_item_options(updated_at DESC);

-- JSONB indexes
CREATE INDEX IF NOT EXISTS idx_order_item_options_validation_rules ON order_item_options USING gin(validation_rules);
CREATE INDEX IF NOT EXISTS idx_order_item_options_validation_errors ON order_item_options USING gin(validation_errors);
CREATE INDEX IF NOT EXISTS idx_order_item_options_localized_names ON order_item_options USING gin(localized_names);
CREATE INDEX IF NOT EXISTS idx_order_item_options_localized_values ON order_item_options USING gin(localized_values);
CREATE INDEX IF NOT EXISTS idx_order_item_options_safety_warnings ON order_item_options USING gin(safety_warnings);
CREATE INDEX IF NOT EXISTS idx_order_item_options_external_references ON order_item_options USING gin(external_references);
CREATE INDEX IF NOT EXISTS idx_order_item_options_custom_fields ON order_item_options USING gin(custom_fields);
CREATE INDEX IF NOT EXISTS idx_order_item_options_sync_errors ON order_item_options USING gin(sync_errors);

-- Text search indexes
CREATE INDEX IF NOT EXISTS idx_order_item_options_option_name_text ON order_item_options USING gin(to_tsvector('english', option_name));
CREATE INDEX IF NOT EXISTS idx_order_item_options_option_value_text ON order_item_options USING gin(to_tsvector('english', option_value));
CREATE INDEX IF NOT EXISTS idx_order_item_options_display_name_text ON order_item_options USING gin(to_tsvector('english', COALESCE(option_display_name, '')));

-- Composite indexes
CREATE INDEX IF NOT EXISTS idx_order_item_options_item_name_lang ON order_item_options(order_item_id, option_name, language_code);
CREATE INDEX IF NOT EXISTS idx_order_item_options_order_name ON order_item_options(order_id, option_name);
CREATE INDEX IF NOT EXISTS idx_order_item_options_store_name ON order_item_options(store_id, option_name);
CREATE INDEX IF NOT EXISTS idx_order_item_options_group_order ON order_item_options(option_group, option_order, option_name);
CREATE INDEX IF NOT EXISTS idx_order_item_options_pricing ON order_item_options(price_modifier_type, price_modifier DESC) WHERE price_modifier != 0;
CREATE INDEX IF NOT EXISTS idx_order_item_options_impact ON order_item_options(affects_availability, affects_shipping, affects_returns);
CREATE INDEX IF NOT EXISTS idx_order_item_options_analytics ON order_item_options(popularity_score DESC, selection_count DESC, conversion_impact DESC);
CREATE INDEX IF NOT EXISTS idx_order_item_options_quality ON order_item_options(quality_grade, compliance_status);

-- History table indexes
CREATE INDEX IF NOT EXISTS idx_order_item_option_history_option_id ON order_item_option_history(option_id);
CREATE INDEX IF NOT EXISTS idx_order_item_option_history_order_item_id ON order_item_option_history(order_item_id);
CREATE INDEX IF NOT EXISTS idx_order_item_option_history_order_id ON order_item_option_history(order_id);
CREATE INDEX IF NOT EXISTS idx_order_item_option_history_store_id ON order_item_option_history(store_id);
CREATE INDEX IF NOT EXISTS idx_order_item_option_history_option_name ON order_item_option_history(option_name);
CREATE INDEX IF NOT EXISTS idx_order_item_option_history_change_type ON order_item_option_history(change_type);
CREATE INDEX IF NOT EXISTS idx_order_item_option_history_created_at ON order_item_option_history(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_item_option_history_changed_by ON order_item_option_history(changed_by_user_id);

-- Rules table indexes
CREATE INDEX IF NOT EXISTS idx_order_item_option_rules_store_id ON order_item_option_rules(store_id);
CREATE INDEX IF NOT EXISTS idx_order_item_option_rules_rule_name ON order_item_option_rules(rule_name);
CREATE INDEX IF NOT EXISTS idx_order_item_option_rules_rule_type ON order_item_option_rules(rule_type);
CREATE INDEX IF NOT EXISTS idx_order_item_option_rules_action_type ON order_item_option_rules(action_type);
CREATE INDEX IF NOT EXISTS idx_order_item_option_rules_is_active ON order_item_option_rules(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_order_item_option_rules_priority ON order_item_option_rules(priority DESC);
CREATE INDEX IF NOT EXISTS idx_order_item_option_rules_validation_status ON order_item_option_rules(validation_status);
CREATE INDEX IF NOT EXISTS idx_order_item_option_rules_application_count ON order_item_option_rules(application_count DESC);
CREATE INDEX IF NOT EXISTS idx_order_item_option_rules_created_at ON order_item_option_rules(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_item_option_rules_condition_options ON order_item_option_rules USING gin(condition_options);
CREATE INDEX IF NOT EXISTS idx_order_item_option_rules_target_options ON order_item_option_rules USING gin(target_options);
CREATE INDEX IF NOT EXISTS idx_order_item_option_rules_action_parameters ON order_item_option_rules USING gin(action_parameters);
CREATE INDEX IF NOT EXISTS idx_order_item_option_rules_product_filters ON order_item_option_rules USING gin(product_filters);

-- =============================================================================
-- Triggers
-- =============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_order_item_options_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_order_item_options_updated_at
    BEFORE UPDATE ON order_item_options
    FOR EACH ROW
    EXECUTE FUNCTION update_order_item_options_updated_at();

CREATE TRIGGER trigger_update_order_item_option_rules_updated_at
    BEFORE UPDATE ON order_item_option_rules
    FOR EACH ROW
    EXECUTE FUNCTION update_order_item_options_updated_at();

-- Track option changes
CREATE OR REPLACE FUNCTION track_order_item_option_changes()
RETURNS TRIGGER AS $$
DECLARE
    change_type_val VARCHAR(20);
BEGIN
    IF TG_OP = 'INSERT' THEN
        change_type_val := 'created';
        INSERT INTO order_item_option_history (
            option_id, order_item_id, order_id, store_id, option_name,
            change_type, new_value, new_price_modifier, change_source
        ) VALUES (
            NEW.id, NEW.order_item_id, NEW.order_id, NEW.store_id, NEW.option_name,
            change_type_val, NEW.option_value, NEW.price_modifier, 'system'
        );
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        change_type_val := 'updated';
        
        -- Track value changes
        IF OLD.option_value IS DISTINCT FROM NEW.option_value THEN
            INSERT INTO order_item_option_history (
                option_id, order_item_id, order_id, store_id, option_name,
                change_type, old_value, new_value,
                old_price_modifier, new_price_modifier,
                price_impact, change_source
            ) VALUES (
                NEW.id, NEW.order_item_id, NEW.order_id, NEW.store_id, NEW.option_name,
                change_type_val, OLD.option_value, NEW.option_value,
                OLD.price_modifier, NEW.price_modifier,
                NEW.price_modifier - OLD.price_modifier, 'system'
            );
        END IF;
        
        -- Track validation status changes
        IF OLD.is_valid != NEW.is_valid THEN
            change_type_val := CASE WHEN NEW.is_valid THEN 'validated' ELSE 'invalidated' END;
            INSERT INTO order_item_option_history (
                option_id, order_item_id, order_id, store_id, option_name,
                change_type, old_value, new_value, change_source
            ) VALUES (
                NEW.id, NEW.order_item_id, NEW.order_id, NEW.store_id, NEW.option_name,
                change_type_val, OLD.is_valid::text, NEW.is_valid::text, 'system'
            );
        END IF;
        
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO order_item_option_history (
            option_id, order_item_id, order_id, store_id, option_name,
            change_type, old_value, old_price_modifier, change_source
        ) VALUES (
            OLD.id, OLD.order_item_id, OLD.order_id, OLD.store_id, OLD.option_name,
            'deleted', OLD.option_value, OLD.price_modifier, 'system'
        );
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_track_order_item_option_changes
    AFTER INSERT OR UPDATE OR DELETE ON order_item_options
    FOR EACH ROW
    EXECUTE FUNCTION track_order_item_option_changes();

-- Validate option values
CREATE OR REPLACE FUNCTION validate_order_item_option_value()
RETURNS TRIGGER AS $$
DECLARE
    validation_errors JSONB := '[]'::jsonb;
    is_valid_value BOOLEAN := TRUE;
BEGIN
    -- Validate based on option type
    CASE NEW.option_type
        WHEN 'number' THEN
            IF NEW.option_value !~ '^-?\d+(\.\d+)?$' THEN
                validation_errors := validation_errors || '["Value must be a valid number"]'::jsonb;
                is_valid_value := FALSE;
            END IF;
        WHEN 'boolean' THEN
            IF LOWER(NEW.option_value) NOT IN ('true', 'false', '1', '0', 'yes', 'no') THEN
                validation_errors := validation_errors || '["Value must be a valid boolean"]'::jsonb;
                is_valid_value := FALSE;
            END IF;
        WHEN 'color' THEN
            IF NEW.option_value !~ '^#[0-9A-Fa-f]{6}$' AND NEW.option_value !~ '^[a-zA-Z]+$' THEN
                validation_errors := validation_errors || '["Value must be a valid color (hex code or color name)"]'::jsonb;
                is_valid_value := FALSE;
            END IF;
    END CASE;
    
    -- Validate display color if provided
    IF NEW.display_color IS NOT NULL AND NEW.display_color !~ '^#[0-9A-Fa-f]{6}$' THEN
        validation_errors := validation_errors || '["Display color must be a valid hex color code"]'::jsonb;
        is_valid_value := FALSE;
    END IF;
    
    -- Update validation status
    NEW.is_valid := is_valid_value;
    NEW.validation_errors := validation_errors;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validate_order_item_option_value
    BEFORE INSERT OR UPDATE ON order_item_options
    FOR EACH ROW
    EXECUTE FUNCTION validate_order_item_option_value();

-- Update popularity scores
CREATE OR REPLACE FUNCTION update_option_popularity_scores()
RETURNS TRIGGER AS $$
BEGIN
    -- Update selection count and popularity score
    UPDATE order_item_options 
    SET 
        selection_count = selection_count + 1,
        popularity_score = LEAST(100.00, popularity_score + 0.1)
    WHERE id = NEW.id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_option_popularity_scores
    AFTER INSERT ON order_item_options
    FOR EACH ROW
    EXECUTE FUNCTION update_option_popularity_scores();

-- =============================================================================
-- Helper Functions
-- =============================================================================

/**
 * Get options for order item
 * @param p_order_item_id UUID - Order item ID
 * @param p_language_code VARCHAR - Language code (optional)
 * @return TABLE - Order item options
 */
CREATE OR REPLACE FUNCTION get_order_item_options(
    p_order_item_id UUID,
    p_language_code VARCHAR DEFAULT 'en'
)
RETURNS TABLE (
    option_id UUID,
    option_name VARCHAR,
    option_value TEXT,
    option_type VARCHAR,
    display_name VARCHAR,
    display_value TEXT,
    price_modifier DECIMAL,
    weight_modifier DECIMAL,
    is_required BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        oio.id as option_id,
        oio.option_name,
        oio.option_value,
        oio.option_type,
        COALESCE(
            oio.localized_names ->> p_language_code,
            oio.option_display_name,
            oio.option_name
        ) as display_name,
        COALESCE(
            oio.localized_values ->> p_language_code,
            oio.display_value,
            oio.option_value
        ) as display_value,
        oio.price_modifier,
        oio.weight_modifier,
        oio.is_required
    FROM order_item_options oio
    WHERE oio.order_item_id = p_order_item_id
    AND (oio.language_code = p_language_code OR oio.language_code = 'en')
    AND oio.is_valid = TRUE
    ORDER BY oio.option_group, oio.option_order, oio.option_name;
END;
$$ LANGUAGE plpgsql;

/**
 * Calculate total price impact of options for order item
 * @param p_order_item_id UUID - Order item ID
 * @return DECIMAL - Total price impact
 */
CREATE OR REPLACE FUNCTION calculate_option_price_impact(
    p_order_item_id UUID
)
RETURNS DECIMAL(10,2) AS $$
DECLARE
    total_impact DECIMAL(10,2) := 0.00;
    option_record RECORD;
    base_price DECIMAL(10,2);
BEGIN
    -- Get base price from order item
    SELECT unit_price INTO base_price
    FROM order_items
    WHERE id = p_order_item_id;
    
    IF base_price IS NULL THEN
        RETURN 0.00;
    END IF;
    
    -- Calculate impact for each option
    FOR option_record IN
        SELECT price_modifier, price_modifier_type
        FROM order_item_options
        WHERE order_item_id = p_order_item_id
        AND is_valid = TRUE
    LOOP
        CASE option_record.price_modifier_type
            WHEN 'fixed' THEN
                total_impact := total_impact + option_record.price_modifier;
            WHEN 'percentage' THEN
                total_impact := total_impact + (base_price * option_record.price_modifier / 100);
            WHEN 'multiplier' THEN
                total_impact := total_impact + (base_price * (option_record.price_modifier - 1));
        END CASE;
    END LOOP;
    
    RETURN total_impact;
END;
$$ LANGUAGE plpgsql;

/**
 * Apply option rules to order item
 * @param p_order_item_id UUID - Order item ID
 * @return INTEGER - Number of rules applied
 */
CREATE OR REPLACE FUNCTION apply_order_item_option_rules(
    p_order_item_id UUID
)
RETURNS INTEGER AS $$
DECLARE
    order_item_record order_items;
    rule_record order_item_option_rules;
    rules_applied INTEGER := 0;
    current_options JSONB;
BEGIN
    -- Get order item record
    SELECT * INTO order_item_record FROM order_items WHERE id = p_order_item_id;
    
    IF order_item_record.id IS NULL THEN
        RAISE EXCEPTION 'Order item not found';
    END IF;
    
    -- Get current options as JSONB
    SELECT jsonb_object_agg(option_name, option_value) INTO current_options
    FROM order_item_options
    WHERE order_item_id = p_order_item_id AND is_valid = TRUE;
    
    -- Apply active rules
    FOR rule_record IN
        SELECT *
        FROM order_item_option_rules
        WHERE store_id = order_item_record.store_id
        AND is_active = TRUE
        AND validation_status = 'valid'
        ORDER BY priority DESC
    LOOP
        -- Check if rule conditions are met
        IF current_options @> rule_record.condition_options THEN
            -- Apply rule action (simplified implementation)
            CASE rule_record.action_type
                WHEN 'modify_price' THEN
                    -- Update price modifiers for target options
                    UPDATE order_item_options
                    SET price_modifier = price_modifier + COALESCE((rule_record.action_parameters ->> 'price_adjustment')::decimal, 0)
                    WHERE order_item_id = p_order_item_id
                    AND option_name = ANY(SELECT jsonb_array_elements_text(rule_record.target_options -> 'option_names'));
                    
                WHEN 'require' THEN
                    -- Mark target options as required
                    UPDATE order_item_options
                    SET is_required = TRUE
                    WHERE order_item_id = p_order_item_id
                    AND option_name = ANY(SELECT jsonb_array_elements_text(rule_record.target_options -> 'option_names'));
            END CASE;
            
            -- Update rule usage
            UPDATE order_item_option_rules
            SET 
                application_count = application_count + 1,
                last_applied_at = CURRENT_TIMESTAMP
            WHERE id = rule_record.id;
            
            rules_applied := rules_applied + 1;
        END IF;
    END LOOP;
    
    RETURN rules_applied;
END;
$$ LANGUAGE plpgsql;

/**
 * Get option statistics for store
 * @param p_store_id UUID - Store ID
 * @return JSONB - Option statistics
 */
CREATE OR REPLACE FUNCTION get_order_item_option_stats(
    p_store_id UUID
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_options', COUNT(*),
        'unique_option_names', COUNT(DISTINCT option_name),
        'valid_options', COUNT(*) FILTER (WHERE is_valid = TRUE),
        'invalid_options', COUNT(*) FILTER (WHERE is_valid = FALSE),
        'required_options', COUNT(*) FILTER (WHERE is_required = TRUE),
        'custom_options', COUNT(*) FILTER (WHERE is_custom_option = TRUE),
        'options_with_price_impact', COUNT(*) FILTER (WHERE price_modifier != 0),
        'options_with_weight_impact', COUNT(*) FILTER (WHERE weight_modifier != 0),
        'avg_price_modifier', AVG(price_modifier),
        'avg_popularity_score', AVG(popularity_score),
        'avg_selection_count', AVG(selection_count),
        'option_types', (
            SELECT jsonb_object_agg(option_type, type_count)
            FROM (
                SELECT option_type, COUNT(*) as type_count
                FROM order_item_options
                WHERE store_id = p_store_id
                GROUP BY option_type
            ) type_stats
        ),
        'option_sources', (
            SELECT jsonb_object_agg(option_source, source_count)
            FROM (
                SELECT option_source, COUNT(*) as source_count
                FROM order_item_options
                WHERE store_id = p_store_id
                GROUP BY option_source
            ) source_stats
        ),
        'price_modifier_types', (
            SELECT jsonb_object_agg(price_modifier_type, modifier_count)
            FROM (
                SELECT price_modifier_type, COUNT(*) as modifier_count
                FROM order_item_options
                WHERE store_id = p_store_id
                AND price_modifier != 0
                GROUP BY price_modifier_type
            ) modifier_stats
        ),
        'top_options', (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'option_name', option_name,
                    'selection_count', SUM(selection_count),
                    'avg_popularity_score', AVG(popularity_score),
                    'avg_price_impact', AVG(price_modifier)
                )
            )
            FROM (
                SELECT 
                    option_name,
                    SUM(selection_count) as total_selections,
                    AVG(popularity_score) as avg_popularity,
                    AVG(price_modifier) as avg_impact
                FROM order_item_options
                WHERE store_id = p_store_id
                GROUP BY option_name
                ORDER BY SUM(selection_count) DESC, AVG(popularity_score) DESC
                LIMIT 10
            ) top_options_stats
        )
    ) INTO result
    FROM order_item_options
    WHERE store_id = p_store_id;
    
    RETURN COALESCE(result, '{"error": "No options found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Comments
-- =============================================================================

COMMENT ON TABLE order_item_options IS 'Normalized options from order_items.selected_options JSONB column';
COMMENT ON TABLE order_item_option_history IS 'Track changes to order item options';
COMMENT ON TABLE order_item_option_rules IS 'Rules for option combinations and dependencies';

COMMENT ON COLUMN order_item_options.price_modifier IS 'Price adjustment for this option';
COMMENT ON COLUMN order_item_options.price_modifier_type IS 'Type of price modification (fixed, percentage, multiplier)';
COMMENT ON COLUMN order_item_options.quality_grade IS 'Quality grade for option value';
COMMENT ON COLUMN order_item_options.compliance_status IS 'Compliance status for regulations';

COMMENT ON FUNCTION get_order_item_options(UUID, VARCHAR) IS 'Get options for order item with localization';
COMMENT ON FUNCTION calculate_option_price_impact(UUID) IS 'Calculate total price impact of options';
COMMENT ON FUNCTION apply_order_item_option_rules(UUID) IS 'Apply option rules to order item';
COMMENT ON FUNCTION get_order_item_option_stats(UUID) IS 'Get option statistics for store';