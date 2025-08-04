-- =====================================================
-- Settings Table
-- =====================================================
-- This table stores general store settings and system configurations
-- for comprehensive store management and customization

CREATE TABLE IF NOT EXISTS settings (
    -- Primary identification
    id BIGSERIAL PRIMARY KEY,
    
    -- Store relationship (required)
    store_id BIGINT NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Setting identification
    setting_key VARCHAR(255) NOT NULL,
    setting_category VARCHAR(100) NOT NULL DEFAULT 'general',
    setting_group VARCHAR(100),
    setting_name VARCHAR(255) NOT NULL,
    setting_description TEXT,
    
    -- Setting values
    setting_value TEXT,
    setting_value_type VARCHAR(50) NOT NULL DEFAULT 'string', -- string, number, boolean, json, array
    default_value TEXT,
    
    -- Value constraints
    allowed_values JSONB, -- For enum-like settings
    min_value DECIMAL,
    max_value DECIMAL,
    validation_regex VARCHAR(500),
    
    -- Setting properties
    is_required BOOLEAN NOT NULL DEFAULT FALSE,
    is_public BOOLEAN NOT NULL DEFAULT FALSE, -- Can be accessed by public API
    is_editable BOOLEAN NOT NULL DEFAULT TRUE,
    is_system BOOLEAN NOT NULL DEFAULT FALSE, -- System-managed setting
    
    -- Display and UI
    display_order INTEGER DEFAULT 0,
    display_label VARCHAR(255),
    display_hint TEXT,
    input_type VARCHAR(50) DEFAULT 'text', -- text, number, select, checkbox, textarea, etc.
    
    -- Localization
    locale VARCHAR(10) DEFAULT 'en',
    is_translatable BOOLEAN NOT NULL DEFAULT FALSE,
    translations JSONB,
    
    -- Environment and context
    environment VARCHAR(50) DEFAULT 'production', -- production, staging, development
    applies_to VARCHAR(100) DEFAULT 'all', -- all, admin, frontend, api
    
    -- Dependencies
    depends_on_setting VARCHAR(255),
    depends_on_value TEXT,
    affects_settings TEXT[], -- Array of setting keys that this setting affects
    
    -- Security and access
    access_level VARCHAR(50) DEFAULT 'admin', -- admin, manager, staff, public
    requires_permission VARCHAR(100),
    is_sensitive BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- Versioning and history
    version INTEGER NOT NULL DEFAULT 1,
    previous_value TEXT,
    change_reason TEXT,
    changed_by_user_id BIGINT,
    
    -- Caching and performance
    cache_duration INTEGER DEFAULT 3600, -- Cache duration in seconds
    last_cached_at TIMESTAMP WITH TIME ZONE,
    cache_key VARCHAR(255),
    
    -- Validation and status
    is_valid BOOLEAN NOT NULL DEFAULT TRUE,
    validation_errors JSONB,
    last_validated_at TIMESTAMP WITH TIME ZONE,
    
    -- Usage tracking
    usage_count INTEGER NOT NULL DEFAULT 0,
    last_accessed_at TIMESTAMP WITH TIME ZONE,
    access_frequency VARCHAR(20) DEFAULT 'medium', -- low, medium, high
    
    -- Backup and restore
    is_backed_up BOOLEAN NOT NULL DEFAULT FALSE,
    backup_frequency VARCHAR(20) DEFAULT 'daily', -- never, daily, weekly, monthly
    last_backup_at TIMESTAMP WITH TIME ZONE,
    
    -- Integration and sync
    sync_with_salla BOOLEAN NOT NULL DEFAULT FALSE,
    salla_setting_key VARCHAR(255),
    last_synced_at TIMESTAMP WITH TIME ZONE,
    sync_status VARCHAR(20) DEFAULT 'pending', -- pending, synced, failed, disabled
    
    -- Performance metrics
    load_time_ms INTEGER,
    impact_score DECIMAL(3,2) DEFAULT 0.0, -- 0.0 to 10.0
    performance_category VARCHAR(20) DEFAULT 'normal', -- critical, high, normal, low
    
    -- Monitoring and alerts
    has_alerts BOOLEAN NOT NULL DEFAULT FALSE,
    alert_conditions JSONB,
    last_alert_at TIMESTAMP WITH TIME ZONE,
    
    -- Feature flags
    feature_flag VARCHAR(100),
    is_feature_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    feature_rollout_percentage INTEGER DEFAULT 100,
    
    -- API and external
    api_endpoint VARCHAR(500),
    external_reference VARCHAR(255),
    webhook_url VARCHAR(500),
    
    -- Custom fields for extensibility
    custom_attributes JSONB,
    tags TEXT[],
    metadata JSONB,
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by_user_id BIGINT,
    updated_by_user_id BIGINT
);

-- =====================================================
-- Indexes for Performance
-- =====================================================

-- Primary lookup indexes
CREATE INDEX IF NOT EXISTS idx_settings_store_key 
    ON settings(store_id, setting_key);

CREATE UNIQUE INDEX IF NOT EXISTS idx_settings_store_key_unique 
    ON settings(store_id, setting_key, locale)
    WHERE locale IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_settings_category 
    ON settings(store_id, setting_category, display_order);

CREATE INDEX IF NOT EXISTS idx_settings_group 
    ON settings(store_id, setting_group, display_order)
    WHERE setting_group IS NOT NULL;

-- Performance and access indexes
CREATE INDEX IF NOT EXISTS idx_settings_access_level 
    ON settings(store_id, access_level, is_public)
    WHERE is_editable = TRUE;

CREATE INDEX IF NOT EXISTS idx_settings_system 
    ON settings(store_id, is_system, setting_category)
    WHERE is_system = TRUE;

CREATE INDEX IF NOT EXISTS idx_settings_environment 
    ON settings(store_id, environment, applies_to);

-- Usage and performance indexes
CREATE INDEX IF NOT EXISTS idx_settings_usage 
    ON settings(store_id, usage_count, last_accessed_at)
    WHERE usage_count > 0;

CREATE INDEX IF NOT EXISTS idx_settings_performance 
    ON settings(store_id, performance_category, impact_score)
    WHERE performance_category IN ('critical', 'high');

-- Sync and integration indexes
CREATE INDEX IF NOT EXISTS idx_settings_sync 
    ON settings(store_id, sync_with_salla, sync_status)
    WHERE sync_with_salla = TRUE;

CREATE INDEX IF NOT EXISTS idx_settings_salla_key 
    ON settings(store_id, salla_setting_key)
    WHERE salla_setting_key IS NOT NULL;

-- Feature flags and validation indexes
CREATE INDEX IF NOT EXISTS idx_settings_feature_flags 
    ON settings(store_id, feature_flag, is_feature_enabled)
    WHERE feature_flag IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_settings_validation 
    ON settings(store_id, is_valid, last_validated_at)
    WHERE is_valid = FALSE;

-- Time-based indexes
CREATE INDEX IF NOT EXISTS idx_settings_created_at 
    ON settings(store_id, created_at);

CREATE INDEX IF NOT EXISTS idx_settings_updated_at 
    ON settings(store_id, updated_at);

-- JSON indexes for flexible querying
CREATE INDEX IF NOT EXISTS idx_settings_custom_attributes 
    ON settings USING GIN(custom_attributes)
    WHERE custom_attributes IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_settings_translations 
    ON settings USING GIN(translations)
    WHERE translations IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_settings_tags 
    ON settings USING GIN(tags)
    WHERE tags IS NOT NULL;

-- =====================================================
-- Unique Constraints
-- =====================================================

-- Ensure unique setting keys per store and locale
ALTER TABLE settings 
    ADD CONSTRAINT uk_settings_store_key_locale 
    UNIQUE (store_id, setting_key, locale);

-- Ensure unique display order within category
CREATE UNIQUE INDEX IF NOT EXISTS idx_settings_category_order 
    ON settings(store_id, setting_category, display_order)
    WHERE display_order IS NOT NULL;

-- =====================================================
-- Triggers
-- =====================================================

-- Updated at trigger
CREATE OR REPLACE FUNCTION update_settings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_settings_updated_at
    BEFORE UPDATE ON settings
    FOR EACH ROW
    EXECUTE FUNCTION update_settings_updated_at();

-- Version and change tracking trigger
CREATE OR REPLACE FUNCTION track_settings_changes()
RETURNS TRIGGER AS $$
BEGIN
    -- Track version changes
    IF OLD.setting_value IS DISTINCT FROM NEW.setting_value THEN
        NEW.version = OLD.version + 1;
        NEW.previous_value = OLD.setting_value;
        NEW.last_validated_at = NULL; -- Reset validation when value changes
    END IF;
    
    -- Update usage tracking
    IF OLD.last_accessed_at IS DISTINCT FROM NEW.last_accessed_at THEN
        NEW.usage_count = OLD.usage_count + 1;
    END IF;
    
    -- Update cache invalidation
    IF OLD.setting_value IS DISTINCT FROM NEW.setting_value THEN
        NEW.last_cached_at = NULL;
        NEW.cache_key = NULL;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_settings_changes
    BEFORE UPDATE ON settings
    FOR EACH ROW
    EXECUTE FUNCTION track_settings_changes();

-- Validation trigger
CREATE OR REPLACE FUNCTION validate_setting_value()
RETURNS TRIGGER AS $$
DECLARE
    validation_errors JSONB := '[]'::JSONB;
    error_found BOOLEAN := FALSE;
BEGIN
    -- Validate required settings
    IF NEW.is_required AND (NEW.setting_value IS NULL OR NEW.setting_value = '') THEN
        validation_errors := validation_errors || jsonb_build_object(
            'field', 'setting_value',
            'error', 'Required setting cannot be empty'
        );
        error_found := TRUE;
    END IF;
    
    -- Validate numeric ranges
    IF NEW.setting_value_type = 'number' AND NEW.setting_value IS NOT NULL THEN
        BEGIN
            DECLARE
                numeric_value DECIMAL := NEW.setting_value::DECIMAL;
            BEGIN
                IF NEW.min_value IS NOT NULL AND numeric_value < NEW.min_value THEN
                    validation_errors := validation_errors || jsonb_build_object(
                        'field', 'setting_value',
                        'error', 'Value is below minimum: ' || NEW.min_value
                    );
                    error_found := TRUE;
                END IF;
                
                IF NEW.max_value IS NOT NULL AND numeric_value > NEW.max_value THEN
                    validation_errors := validation_errors || jsonb_build_object(
                        'field', 'setting_value',
                        'error', 'Value is above maximum: ' || NEW.max_value
                    );
                    error_found := TRUE;
                END IF;
            END;
        EXCEPTION WHEN OTHERS THEN
            validation_errors := validation_errors || jsonb_build_object(
                'field', 'setting_value',
                'error', 'Invalid numeric value'
            );
            error_found := TRUE;
        END;
    END IF;
    
    -- Validate boolean values
    IF NEW.setting_value_type = 'boolean' AND NEW.setting_value IS NOT NULL THEN
        IF NEW.setting_value NOT IN ('true', 'false', '1', '0', 'yes', 'no') THEN
            validation_errors := validation_errors || jsonb_build_object(
                'field', 'setting_value',
                'error', 'Invalid boolean value'
            );
            error_found := TRUE;
        END IF;
    END IF;
    
    -- Validate allowed values
    IF NEW.allowed_values IS NOT NULL AND NEW.setting_value IS NOT NULL THEN
        IF NOT (NEW.allowed_values ? NEW.setting_value) THEN
            validation_errors := validation_errors || jsonb_build_object(
                'field', 'setting_value',
                'error', 'Value not in allowed values list'
            );
            error_found := TRUE;
        END IF;
    END IF;
    
    -- Update validation status
    NEW.is_valid = NOT error_found;
    NEW.validation_errors = CASE WHEN error_found THEN validation_errors ELSE NULL END;
    NEW.last_validated_at = CURRENT_TIMESTAMP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_settings_validation
    BEFORE INSERT OR UPDATE ON settings
    FOR EACH ROW
    EXECUTE FUNCTION validate_setting_value();

-- =====================================================
-- Helper Functions
-- =====================================================

-- Function to get setting value with type conversion
CREATE OR REPLACE FUNCTION get_setting_value(
    store_id_param BIGINT,
    setting_key_param VARCHAR,
    locale_param VARCHAR DEFAULT 'en'
)
RETURNS TEXT AS $$
DECLARE
    setting_record RECORD;
    result_value TEXT;
BEGIN
    SELECT * INTO setting_record
    FROM settings
    WHERE store_id = store_id_param
        AND setting_key = setting_key_param
        AND locale = locale_param
        AND is_valid = TRUE;
    
    IF NOT FOUND THEN
        -- Try default locale if specific locale not found
        SELECT * INTO setting_record
        FROM settings
        WHERE store_id = store_id_param
            AND setting_key = setting_key_param
            AND locale = 'en'
            AND is_valid = TRUE;
    END IF;
    
    IF FOUND THEN
        -- Update access tracking
        UPDATE settings 
        SET last_accessed_at = CURRENT_TIMESTAMP,
            usage_count = usage_count + 1
        WHERE id = setting_record.id;
        
        RETURN COALESCE(setting_record.setting_value, setting_record.default_value);
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Function to set setting value with validation
CREATE OR REPLACE FUNCTION set_setting_value(
    store_id_param BIGINT,
    setting_key_param VARCHAR,
    setting_value_param TEXT,
    user_id_param BIGINT DEFAULT NULL,
    change_reason_param TEXT DEFAULT NULL,
    locale_param VARCHAR DEFAULT 'en'
)
RETURNS BOOLEAN AS $$
DECLARE
    setting_id BIGINT;
    success BOOLEAN := FALSE;
BEGIN
    UPDATE settings
    SET setting_value = setting_value_param,
        updated_by_user_id = user_id_param,
        change_reason = change_reason_param,
        updated_at = CURRENT_TIMESTAMP
    WHERE store_id = store_id_param
        AND setting_key = setting_key_param
        AND locale = locale_param
        AND is_editable = TRUE
    RETURNING id INTO setting_id;
    
    IF FOUND THEN
        success := TRUE;
    END IF;
    
    RETURN success;
END;
$$ LANGUAGE plpgsql;

-- Function to get settings by category
CREATE OR REPLACE FUNCTION get_settings_by_category(
    store_id_param BIGINT,
    category_param VARCHAR,
    access_level_param VARCHAR DEFAULT 'admin',
    locale_param VARCHAR DEFAULT 'en'
)
RETURNS TABLE (
    setting_key VARCHAR,
    setting_name VARCHAR,
    setting_value TEXT,
    setting_value_type VARCHAR,
    display_label VARCHAR,
    display_hint TEXT,
    input_type VARCHAR,
    is_required BOOLEAN,
    allowed_values JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.setting_key,
        s.setting_name,
        COALESCE(s.setting_value, s.default_value) as setting_value,
        s.setting_value_type,
        s.display_label,
        s.display_hint,
        s.input_type,
        s.is_required,
        s.allowed_values
    FROM settings s
    WHERE s.store_id = store_id_param
        AND s.setting_category = category_param
        AND s.locale = locale_param
        AND s.is_valid = TRUE
        AND (
            s.access_level = access_level_param
            OR s.is_public = TRUE
            OR access_level_param = 'admin'
        )
    ORDER BY s.display_order, s.setting_name;
END;
$$ LANGUAGE plpgsql;

-- Function to get store settings statistics
CREATE OR REPLACE FUNCTION get_settings_stats(
    store_id_param BIGINT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_settings', COUNT(*),
        'valid_settings', COUNT(*) FILTER (WHERE is_valid = TRUE),
        'invalid_settings', COUNT(*) FILTER (WHERE is_valid = FALSE),
        'system_settings', COUNT(*) FILTER (WHERE is_system = TRUE),
        'user_settings', COUNT(*) FILTER (WHERE is_system = FALSE),
        'public_settings', COUNT(*) FILTER (WHERE is_public = TRUE),
        'synced_settings', COUNT(*) FILTER (WHERE sync_with_salla = TRUE AND sync_status = 'synced'),
        'categories', (
            SELECT jsonb_object_agg(setting_category, category_count)
            FROM (
                SELECT setting_category, COUNT(*) as category_count
                FROM settings
                WHERE (store_id_param IS NULL OR store_id = store_id_param)
                GROUP BY setting_category
            ) cat_stats
        ),
        'performance_distribution', (
            SELECT jsonb_object_agg(performance_category, perf_count)
            FROM (
                SELECT performance_category, COUNT(*) as perf_count
                FROM settings
                WHERE (store_id_param IS NULL OR store_id = store_id_param)
                GROUP BY performance_category
            ) perf_stats
        ),
        'last_updated', MAX(updated_at)
    ) INTO result
    FROM settings
    WHERE (store_id_param IS NULL OR store_id = store_id_param);
    
    RETURN COALESCE(result, '{"error": "No settings found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- Function to search settings
CREATE OR REPLACE FUNCTION search_settings(
    store_id_param BIGINT,
    search_term VARCHAR DEFAULT NULL,
    category_filter VARCHAR DEFAULT NULL,
    access_level_filter VARCHAR DEFAULT NULL,
    is_system_filter BOOLEAN DEFAULT NULL,
    limit_param INTEGER DEFAULT 50
)
RETURNS TABLE (
    id BIGINT,
    setting_key VARCHAR,
    setting_name VARCHAR,
    setting_category VARCHAR,
    setting_value TEXT,
    display_label VARCHAR,
    is_system BOOLEAN,
    access_level VARCHAR,
    last_updated TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id,
        s.setting_key,
        s.setting_name,
        s.setting_category,
        s.setting_value,
        s.display_label,
        s.is_system,
        s.access_level,
        s.updated_at
    FROM settings s
    WHERE s.store_id = store_id_param
        AND s.is_valid = TRUE
        AND (
            search_term IS NULL 
            OR s.setting_key ILIKE '%' || search_term || '%'
            OR s.setting_name ILIKE '%' || search_term || '%'
            OR s.display_label ILIKE '%' || search_term || '%'
        )
        AND (category_filter IS NULL OR s.setting_category = category_filter)
        AND (access_level_filter IS NULL OR s.access_level = access_level_filter)
        AND (is_system_filter IS NULL OR s.is_system = is_system_filter)
    ORDER BY 
        CASE WHEN search_term IS NOT NULL THEN
            CASE 
                WHEN s.setting_key ILIKE search_term || '%' THEN 1
                WHEN s.setting_name ILIKE search_term || '%' THEN 2
                ELSE 3
            END
        ELSE s.display_order
        END,
        s.setting_name
    LIMIT limit_param;
END;
$$ LANGUAGE plpgsql;

-- Function to bulk update settings
CREATE OR REPLACE FUNCTION bulk_update_settings(
    store_id_param BIGINT,
    settings_data JSONB,
    user_id_param BIGINT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    setting_item JSONB;
    updated_count INTEGER := 0;
    failed_count INTEGER := 0;
    result JSONB;
BEGIN
    FOR setting_item IN SELECT * FROM jsonb_array_elements(settings_data)
    LOOP
        BEGIN
            IF set_setting_value(
                store_id_param,
                setting_item->>'setting_key',
                setting_item->>'setting_value',
                user_id_param,
                'Bulk update'
            ) THEN
                updated_count := updated_count + 1;
            ELSE
                failed_count := failed_count + 1;
            END IF;
        EXCEPTION WHEN OTHERS THEN
            failed_count := failed_count + 1;
        END;
    END LOOP;
    
    result := jsonb_build_object(
        'updated_count', updated_count,
        'failed_count', failed_count,
        'total_processed', updated_count + failed_count,
        'success_rate', CASE 
            WHEN (updated_count + failed_count) > 0 THEN 
                (updated_count::DECIMAL / (updated_count + failed_count)) * 100
            ELSE 0
        END
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Comments for Documentation
-- =====================================================

COMMENT ON TABLE settings IS 'Store settings and system configurations with comprehensive management features';
COMMENT ON COLUMN settings.setting_key IS 'Unique identifier for the setting within the store';
COMMENT ON COLUMN settings.setting_category IS 'Category grouping for settings organization';
COMMENT ON COLUMN settings.setting_value_type IS 'Data type of the setting value for proper handling';
COMMENT ON COLUMN settings.is_system IS 'Whether this is a system-managed setting';
COMMENT ON COLUMN settings.access_level IS 'Required access level to modify this setting';
COMMENT ON COLUMN settings.sync_with_salla IS 'Whether this setting should sync with Salla platform';
COMMENT ON COLUMN settings.performance_category IS 'Performance impact category of this setting';

COMMENT ON FUNCTION get_setting_value(BIGINT, VARCHAR, VARCHAR) IS 'Get setting value with automatic type conversion and access tracking';
COMMENT ON FUNCTION set_setting_value(BIGINT, VARCHAR, TEXT, BIGINT, TEXT, VARCHAR) IS 'Set setting value with validation and change tracking';
COMMENT ON FUNCTION get_settings_by_category(BIGINT, VARCHAR, VARCHAR, VARCHAR) IS 'Get all settings in a category with access control';
COMMENT ON FUNCTION get_settings_stats(BIGINT) IS 'Get comprehensive statistics about store settings';
COMMENT ON FUNCTION search_settings(BIGINT, VARCHAR, VARCHAR, VARCHAR, BOOLEAN, INTEGER) IS 'Search settings with advanced filtering options';
COMMENT ON FUNCTION bulk_update_settings(BIGINT, JSONB, BIGINT) IS 'Bulk update multiple settings with transaction safety';