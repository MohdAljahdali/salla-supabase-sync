-- =============================================================================
-- Invoice Brand Colors Table
-- =============================================================================
-- This file normalizes the brand_colors JSONB column from the invoices table
-- into a separate table with proper structure and relationships

-- =============================================================================
-- Invoice Brand Colors Table
-- =============================================================================

CREATE TABLE IF NOT EXISTS invoice_brand_colors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Color scheme identification
    color_scheme_name VARCHAR(100) NOT NULL DEFAULT 'default',
    color_scheme_version VARCHAR(20) DEFAULT '1.0',
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Primary brand colors
    primary_color VARCHAR(7) CHECK (primary_color ~ '^#[0-9A-Fa-f]{6}$'), -- Hex color
    primary_color_rgb VARCHAR(20), -- RGB format: "255,255,255"
    primary_color_hsl VARCHAR(20), -- HSL format: "360,100%,50%"
    primary_color_name VARCHAR(50), -- Human readable name
    
    -- Secondary brand colors
    secondary_color VARCHAR(7) CHECK (secondary_color ~ '^#[0-9A-Fa-f]{6}$'),
    secondary_color_rgb VARCHAR(20),
    secondary_color_hsl VARCHAR(20),
    secondary_color_name VARCHAR(50),
    
    -- Accent colors
    accent_color VARCHAR(7) CHECK (accent_color ~ '^#[0-9A-Fa-f]{6}$'),
    accent_color_rgb VARCHAR(20),
    accent_color_hsl VARCHAR(20),
    accent_color_name VARCHAR(50),
    
    -- Background colors
    background_color VARCHAR(7) CHECK (background_color ~ '^#[0-9A-Fa-f]{6}$'),
    background_color_rgb VARCHAR(20),
    background_color_hsl VARCHAR(20),
    background_color_name VARCHAR(50),
    
    -- Text colors
    text_color VARCHAR(7) CHECK (text_color ~ '^#[0-9A-Fa-f]{6}$'),
    text_color_rgb VARCHAR(20),
    text_color_hsl VARCHAR(20),
    text_color_name VARCHAR(50),
    
    -- Header colors
    header_color VARCHAR(7) CHECK (header_color ~ '^#[0-9A-Fa-f]{6}$'),
    header_color_rgb VARCHAR(20),
    header_color_hsl VARCHAR(20),
    header_color_name VARCHAR(50),
    
    -- Footer colors
    footer_color VARCHAR(7) CHECK (footer_color ~ '^#[0-9A-Fa-f]{6}$'),
    footer_color_rgb VARCHAR(20),
    footer_color_hsl VARCHAR(20),
    footer_color_name VARCHAR(50),
    
    -- Border colors
    border_color VARCHAR(7) CHECK (border_color ~ '^#[0-9A-Fa-f]{6}$'),
    border_color_rgb VARCHAR(20),
    border_color_hsl VARCHAR(20),
    border_color_name VARCHAR(50),
    
    -- Link colors
    link_color VARCHAR(7) CHECK (link_color ~ '^#[0-9A-Fa-f]{6}$'),
    link_color_rgb VARCHAR(20),
    link_color_hsl VARCHAR(20),
    link_color_name VARCHAR(50),
    
    -- Hover colors
    hover_color VARCHAR(7) CHECK (hover_color ~ '^#[0-9A-Fa-f]{6}$'),
    hover_color_rgb VARCHAR(20),
    hover_color_hsl VARCHAR(20),
    hover_color_name VARCHAR(50),
    
    -- Success/Error/Warning colors
    success_color VARCHAR(7) CHECK (success_color ~ '^#[0-9A-Fa-f]{6}$'),
    error_color VARCHAR(7) CHECK (error_color ~ '^#[0-9A-Fa-f]{6}$'),
    warning_color VARCHAR(7) CHECK (warning_color ~ '^#[0-9A-Fa-f]{6}$'),
    info_color VARCHAR(7) CHECK (info_color ~ '^#[0-9A-Fa-f]{6}$'),
    
    -- Button colors
    button_primary_color VARCHAR(7) CHECK (button_primary_color ~ '^#[0-9A-Fa-f]{6}$'),
    button_secondary_color VARCHAR(7) CHECK (button_secondary_color ~ '^#[0-9A-Fa-f]{6}$'),
    button_text_color VARCHAR(7) CHECK (button_text_color ~ '^#[0-9A-Fa-f]{6}$'),
    button_hover_color VARCHAR(7) CHECK (button_hover_color ~ '^#[0-9A-Fa-f]{6}$'),
    
    -- Table colors
    table_header_color VARCHAR(7) CHECK (table_header_color ~ '^#[0-9A-Fa-f]{6}$'),
    table_row_color VARCHAR(7) CHECK (table_row_color ~ '^#[0-9A-Fa-f]{6}$'),
    table_alt_row_color VARCHAR(7) CHECK (table_alt_row_color ~ '^#[0-9A-Fa-f]{6}$'),
    table_border_color VARCHAR(7) CHECK (table_border_color ~ '^#[0-9A-Fa-f]{6}$'),
    
    -- Logo and branding colors
    logo_primary_color VARCHAR(7) CHECK (logo_primary_color ~ '^#[0-9A-Fa-f]{6}$'),
    logo_secondary_color VARCHAR(7) CHECK (logo_secondary_color ~ '^#[0-9A-Fa-f]{6}$'),
    watermark_color VARCHAR(7) CHECK (watermark_color ~ '^#[0-9A-Fa-f]{6}$'),
    
    -- Color palette information
    color_palette_type VARCHAR(30) DEFAULT 'custom' CHECK (color_palette_type IN (
        'custom', 'monochromatic', 'analogous', 'complementary', 'triadic', 
        'tetradic', 'split_complementary', 'warm', 'cool', 'neutral'
    )),
    color_temperature VARCHAR(20) CHECK (color_temperature IN (
        'very_warm', 'warm', 'neutral', 'cool', 'very_cool'
    )),
    color_brightness VARCHAR(20) CHECK (color_brightness IN (
        'very_dark', 'dark', 'medium', 'light', 'very_light'
    )),
    color_saturation VARCHAR(20) CHECK (color_saturation IN (
        'very_low', 'low', 'medium', 'high', 'very_high'
    )),
    
    -- Accessibility and contrast
    wcag_aa_compliant BOOLEAN DEFAULT FALSE,
    wcag_aaa_compliant BOOLEAN DEFAULT FALSE,
    contrast_ratio_primary DECIMAL(4,2), -- Contrast ratio for primary colors
    contrast_ratio_secondary DECIMAL(4,2),
    high_contrast_mode BOOLEAN DEFAULT FALSE,
    
    -- Dark mode support
    supports_dark_mode BOOLEAN DEFAULT FALSE,
    dark_mode_primary_color VARCHAR(7) CHECK (dark_mode_primary_color ~ '^#[0-9A-Fa-f]{6}$'),
    dark_mode_background_color VARCHAR(7) CHECK (dark_mode_background_color ~ '^#[0-9A-Fa-f]{6}$'),
    dark_mode_text_color VARCHAR(7) CHECK (dark_mode_text_color ~ '^#[0-9A-Fa-f]{6}$'),
    
    -- Print-specific colors
    print_primary_color VARCHAR(7) CHECK (print_primary_color ~ '^#[0-9A-Fa-f]{6}$'),
    print_background_color VARCHAR(7) CHECK (print_background_color ~ '^#[0-9A-Fa-f]{6}$'),
    print_text_color VARCHAR(7) CHECK (print_text_color ~ '^#[0-9A-Fa-f]{6}$'),
    print_friendly BOOLEAN DEFAULT TRUE,
    
    -- Color usage context
    usage_context VARCHAR(50) DEFAULT 'invoice' CHECK (usage_context IN (
        'invoice', 'receipt', 'estimate', 'quote', 'statement', 'report', 
        'email', 'pdf', 'web', 'print', 'mobile'
    )),
    
    -- Brand guidelines
    brand_guidelines_url VARCHAR(500),
    color_usage_notes TEXT,
    color_restrictions TEXT,
    
    -- Color psychology and meaning
    primary_color_meaning VARCHAR(255), -- What the primary color represents
    color_emotion VARCHAR(100), -- Emotional response intended
    target_audience VARCHAR(100), -- Who the colors are designed for
    
    -- Technical specifications
    color_profile VARCHAR(30) DEFAULT 'sRGB' CHECK (color_profile IN (
        'sRGB', 'Adobe_RGB', 'ProPhoto_RGB', 'CMYK', 'LAB'
    )),
    color_depth INTEGER DEFAULT 8 CHECK (color_depth IN (8, 16, 32)),
    gamma_correction DECIMAL(3,2) DEFAULT 2.2,
    
    -- Application and rendering
    css_variables JSONB DEFAULT '{}', -- CSS custom properties
    scss_variables JSONB DEFAULT '{}', -- SCSS variables
    design_tokens JSONB DEFAULT '{}', -- Design system tokens
    
    -- Quality and validation
    color_validation_status VARCHAR(20) DEFAULT 'valid' CHECK (color_validation_status IN (
        'valid', 'invalid', 'warning', 'needs_review'
    )),
    validation_errors TEXT[],
    validation_warnings TEXT[],
    
    -- Performance and optimization
    color_compression_level INTEGER DEFAULT 0 CHECK (color_compression_level >= 0 AND color_compression_level <= 9),
    optimized_for_web BOOLEAN DEFAULT TRUE,
    optimized_for_print BOOLEAN DEFAULT TRUE,
    
    -- Localization and cultural considerations
    cultural_considerations TEXT,
    regional_preferences JSONB DEFAULT '{}', -- Color preferences by region
    cultural_meanings JSONB DEFAULT '{}', -- Cultural meanings of colors
    
    -- A/B testing and analytics
    ab_test_variant VARCHAR(50),
    conversion_rate DECIMAL(5,4),
    user_preference_score DECIMAL(3,2),
    engagement_metrics JSONB DEFAULT '{}',
    
    -- External integrations
    external_color_scheme_id VARCHAR(255),
    design_system_reference VARCHAR(255),
    pantone_colors JSONB DEFAULT '{}', -- Pantone color references
    
    -- Data source and quality
    data_source VARCHAR(50) DEFAULT 'manual' CHECK (data_source IN (
        'manual', 'api', 'import', 'brand_guidelines', 'design_system', 'ai_generated'
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
    UNIQUE(invoice_id, color_scheme_name)
);

-- =============================================================================
-- Invoice Brand Color History Table
-- =============================================================================
-- Track changes to brand colors

CREATE TABLE IF NOT EXISTS invoice_brand_color_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    brand_color_id UUID NOT NULL REFERENCES invoice_brand_colors(id) ON DELETE CASCADE,
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Change tracking
    change_type VARCHAR(20) NOT NULL CHECK (change_type IN (
        'created', 'updated', 'deleted', 'color_changed', 'scheme_updated', 
        'accessibility_improved', 'validated', 'optimized'
    )),
    changed_fields JSONB, -- Array of field names that changed
    old_values JSONB, -- Previous values of changed fields
    new_values JSONB, -- New values of changed fields
    
    -- Change context
    change_reason VARCHAR(255),
    change_source VARCHAR(50) DEFAULT 'manual' CHECK (change_source IN (
        'manual', 'api', 'import', 'system', 'brand_update', 'accessibility_fix', 'optimization'
    )),
    
    -- User context
    changed_by_user_id UUID,
    changed_by_user_type VARCHAR(20) DEFAULT 'admin' CHECK (changed_by_user_type IN (
        'admin', 'system', 'api', 'designer', 'brand_manager'
    )),
    
    -- Session context
    session_id VARCHAR(255),
    request_id VARCHAR(255),
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- Brand Color Palettes Table
-- =============================================================================
-- Store predefined color palettes for reuse

CREATE TABLE IF NOT EXISTS invoice_brand_color_palettes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Palette identification
    palette_name VARCHAR(100) NOT NULL,
    palette_description TEXT,
    palette_category VARCHAR(50) DEFAULT 'custom' CHECK (palette_category IN (
        'custom', 'corporate', 'seasonal', 'promotional', 'industry_standard', 'accessibility'
    )),
    
    -- Palette metadata
    is_default BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    usage_count INTEGER DEFAULT 0,
    popularity_score DECIMAL(3,2) DEFAULT 0,
    
    -- Color definitions (stored as JSONB for flexibility)
    color_definitions JSONB NOT NULL DEFAULT '{}',
    
    -- Palette properties
    color_count INTEGER GENERATED ALWAYS AS (jsonb_array_length(color_definitions->'colors')) STORED,
    palette_type VARCHAR(30) CHECK (palette_type IN (
        'monochromatic', 'analogous', 'complementary', 'triadic', 'tetradic', 'custom'
    )),
    
    -- Accessibility and compliance
    wcag_compliant BOOLEAN DEFAULT FALSE,
    accessibility_notes TEXT,
    
    -- Usage guidelines
    usage_guidelines TEXT,
    recommended_contexts TEXT[],
    
    -- External references
    external_palette_id VARCHAR(255),
    design_system_reference VARCHAR(255),
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    UNIQUE(store_id, palette_name)
);

-- =============================================================================
-- Color Accessibility Rules Table
-- =============================================================================
-- Store accessibility rules and compliance checks

CREATE TABLE IF NOT EXISTS invoice_color_accessibility_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Rule identification
    rule_name VARCHAR(100) NOT NULL,
    rule_description TEXT,
    rule_type VARCHAR(30) DEFAULT 'contrast' CHECK (rule_type IN (
        'contrast', 'color_blindness', 'brightness', 'saturation', 'wcag_aa', 'wcag_aaa'
    )),
    
    -- Rule parameters
    minimum_contrast_ratio DECIMAL(4,2),
    maximum_contrast_ratio DECIMAL(4,2),
    color_blindness_types TEXT[] DEFAULT ARRAY['protanopia', 'deuteranopia', 'tritanopia'],
    
    -- Compliance levels
    wcag_level VARCHAR(10) CHECK (wcag_level IN ('A', 'AA', 'AAA')),
    compliance_standard VARCHAR(50) DEFAULT 'WCAG 2.1',
    
    -- Rule configuration
    is_active BOOLEAN DEFAULT TRUE,
    is_mandatory BOOLEAN DEFAULT FALSE,
    severity_level VARCHAR(20) DEFAULT 'warning' CHECK (severity_level IN (
        'info', 'warning', 'error', 'critical'
    )),
    
    -- Validation settings
    auto_fix_enabled BOOLEAN DEFAULT FALSE,
    suggested_fixes JSONB DEFAULT '[]',
    
    -- Usage tracking
    usage_count INTEGER DEFAULT 0,
    last_used_at TIMESTAMPTZ,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    UNIQUE(store_id, rule_name)
);

-- =============================================================================
-- Indexes
-- =============================================================================

-- Primary indexes for invoice_brand_colors
CREATE INDEX IF NOT EXISTS idx_invoice_brand_colors_invoice_id ON invoice_brand_colors(invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoice_brand_colors_store_id ON invoice_brand_colors(store_id);
CREATE INDEX IF NOT EXISTS idx_invoice_brand_colors_scheme_name ON invoice_brand_colors(color_scheme_name);
CREATE INDEX IF NOT EXISTS idx_invoice_brand_colors_is_active ON invoice_brand_colors(is_active);
CREATE INDEX IF NOT EXISTS idx_invoice_brand_colors_usage_context ON invoice_brand_colors(usage_context);
CREATE INDEX IF NOT EXISTS idx_invoice_brand_colors_palette_type ON invoice_brand_colors(color_palette_type);
CREATE INDEX IF NOT EXISTS idx_invoice_brand_colors_wcag_compliant ON invoice_brand_colors(wcag_aa_compliant, wcag_aaa_compliant);
CREATE INDEX IF NOT EXISTS idx_invoice_brand_colors_dark_mode ON invoice_brand_colors(supports_dark_mode);
CREATE INDEX IF NOT EXISTS idx_invoice_brand_colors_print_friendly ON invoice_brand_colors(print_friendly);
CREATE INDEX IF NOT EXISTS idx_invoice_brand_colors_validation_status ON invoice_brand_colors(color_validation_status);
CREATE INDEX IF NOT EXISTS idx_invoice_brand_colors_sync_status ON invoice_brand_colors(sync_status);
CREATE INDEX IF NOT EXISTS idx_invoice_brand_colors_created_at ON invoice_brand_colors(created_at DESC);

-- Composite indexes
CREATE INDEX IF NOT EXISTS idx_invoice_brand_colors_store_scheme ON invoice_brand_colors(store_id, color_scheme_name);
CREATE INDEX IF NOT EXISTS idx_invoice_brand_colors_invoice_active ON invoice_brand_colors(invoice_id, is_active);
CREATE INDEX IF NOT EXISTS idx_invoice_brand_colors_accessibility ON invoice_brand_colors(wcag_aa_compliant, contrast_ratio_primary);

-- JSONB indexes
CREATE INDEX IF NOT EXISTS idx_invoice_brand_colors_css_variables ON invoice_brand_colors USING gin(css_variables);
CREATE INDEX IF NOT EXISTS idx_invoice_brand_colors_design_tokens ON invoice_brand_colors USING gin(design_tokens);
CREATE INDEX IF NOT EXISTS idx_invoice_brand_colors_regional_prefs ON invoice_brand_colors USING gin(regional_preferences);
CREATE INDEX IF NOT EXISTS idx_invoice_brand_colors_engagement ON invoice_brand_colors USING gin(engagement_metrics);
CREATE INDEX IF NOT EXISTS idx_invoice_brand_colors_pantone ON invoice_brand_colors USING gin(pantone_colors);
CREATE INDEX IF NOT EXISTS idx_invoice_brand_colors_custom_fields ON invoice_brand_colors USING gin(custom_fields);
CREATE INDEX IF NOT EXISTS idx_invoice_brand_colors_sync_errors ON invoice_brand_colors USING gin(sync_errors);

-- Array indexes
CREATE INDEX IF NOT EXISTS idx_invoice_brand_colors_validation_errors ON invoice_brand_colors USING gin(validation_errors);
CREATE INDEX IF NOT EXISTS idx_invoice_brand_colors_validation_warnings ON invoice_brand_colors USING gin(validation_warnings);

-- History table indexes
CREATE INDEX IF NOT EXISTS idx_invoice_brand_color_history_brand_color_id ON invoice_brand_color_history(brand_color_id);
CREATE INDEX IF NOT EXISTS idx_invoice_brand_color_history_invoice_id ON invoice_brand_color_history(invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoice_brand_color_history_store_id ON invoice_brand_color_history(store_id);
CREATE INDEX IF NOT EXISTS idx_invoice_brand_color_history_change_type ON invoice_brand_color_history(change_type);
CREATE INDEX IF NOT EXISTS idx_invoice_brand_color_history_created_at ON invoice_brand_color_history(created_at DESC);

-- Palettes table indexes
CREATE INDEX IF NOT EXISTS idx_invoice_brand_color_palettes_store_id ON invoice_brand_color_palettes(store_id);
CREATE INDEX IF NOT EXISTS idx_invoice_brand_color_palettes_category ON invoice_brand_color_palettes(palette_category);
CREATE INDEX IF NOT EXISTS idx_invoice_brand_color_palettes_is_default ON invoice_brand_color_palettes(is_default);
CREATE INDEX IF NOT EXISTS idx_invoice_brand_color_palettes_is_active ON invoice_brand_color_palettes(is_active);
CREATE INDEX IF NOT EXISTS idx_invoice_brand_color_palettes_popularity ON invoice_brand_color_palettes(popularity_score DESC);
CREATE INDEX IF NOT EXISTS idx_invoice_brand_color_palettes_color_definitions ON invoice_brand_color_palettes USING gin(color_definitions);

-- Accessibility rules indexes
CREATE INDEX IF NOT EXISTS idx_invoice_color_accessibility_rules_store_id ON invoice_color_accessibility_rules(store_id);
CREATE INDEX IF NOT EXISTS idx_invoice_color_accessibility_rules_type ON invoice_color_accessibility_rules(rule_type);
CREATE INDEX IF NOT EXISTS idx_invoice_color_accessibility_rules_active ON invoice_color_accessibility_rules(is_active);
CREATE INDEX IF NOT EXISTS idx_invoice_color_accessibility_rules_mandatory ON invoice_color_accessibility_rules(is_mandatory);
CREATE INDEX IF NOT EXISTS idx_invoice_color_accessibility_rules_wcag_level ON invoice_color_accessibility_rules(wcag_level);

-- =============================================================================
-- Triggers
-- =============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_invoice_brand_colors_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_invoice_brand_colors_updated_at
    BEFORE UPDATE ON invoice_brand_colors
    FOR EACH ROW
    EXECUTE FUNCTION update_invoice_brand_colors_updated_at();

CREATE TRIGGER trigger_update_invoice_brand_color_palettes_updated_at
    BEFORE UPDATE ON invoice_brand_color_palettes
    FOR EACH ROW
    EXECUTE FUNCTION update_invoice_brand_colors_updated_at();

CREATE TRIGGER trigger_update_invoice_color_accessibility_rules_updated_at
    BEFORE UPDATE ON invoice_color_accessibility_rules
    FOR EACH ROW
    EXECUTE FUNCTION update_invoice_brand_colors_updated_at();

-- Track brand color changes in history
CREATE OR REPLACE FUNCTION track_invoice_brand_color_changes()
RETURNS TRIGGER AS $$
DECLARE
    v_changed_fields TEXT[];
    v_old_values JSONB;
    v_new_values JSONB;
    v_change_type VARCHAR(20);
BEGIN
    IF TG_OP = 'INSERT' THEN
        v_change_type := 'created';
        INSERT INTO invoice_brand_color_history (
            brand_color_id, invoice_id, store_id, change_type,
            new_values, created_at
        ) VALUES (
            NEW.id, NEW.invoice_id, NEW.store_id, v_change_type,
            to_jsonb(NEW), CURRENT_TIMESTAMP
        );
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        -- Determine specific change type
        IF OLD.primary_color != NEW.primary_color OR 
           OLD.secondary_color != NEW.secondary_color OR
           OLD.accent_color != NEW.accent_color THEN
            v_change_type := 'color_changed';
        ELSIF OLD.color_scheme_name != NEW.color_scheme_name THEN
            v_change_type := 'scheme_updated';
        ELSIF OLD.wcag_aa_compliant != NEW.wcag_aa_compliant OR
              OLD.wcag_aaa_compliant != NEW.wcag_aaa_compliant THEN
            v_change_type := 'accessibility_improved';
        ELSIF OLD.color_validation_status != NEW.color_validation_status THEN
            v_change_type := 'validated';
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
            INSERT INTO invoice_brand_color_history (
                brand_color_id, invoice_id, store_id, change_type,
                changed_fields, old_values, new_values, created_at
            ) VALUES (
                NEW.id, NEW.invoice_id, NEW.store_id, v_change_type,
                v_changed_fields, v_old_values, v_new_values, CURRENT_TIMESTAMP
            );
        END IF;
        
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO invoice_brand_color_history (
            brand_color_id, invoice_id, store_id, change_type,
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

CREATE TRIGGER trigger_track_invoice_brand_color_changes
    AFTER INSERT OR UPDATE OR DELETE ON invoice_brand_colors
    FOR EACH ROW
    EXECUTE FUNCTION track_invoice_brand_color_changes();

-- Auto-convert color formats
CREATE OR REPLACE FUNCTION auto_convert_color_formats()
RETURNS TRIGGER AS $$
DECLARE
    v_r INTEGER;
    v_g INTEGER;
    v_b INTEGER;
    v_h INTEGER;
    v_s INTEGER;
    v_l INTEGER;
BEGIN
    -- Convert primary color to RGB and HSL if hex is provided
    IF NEW.primary_color IS NOT NULL AND NEW.primary_color_rgb IS NULL THEN
        v_r := ('x' || substring(NEW.primary_color, 2, 2))::bit(8)::int;
        v_g := ('x' || substring(NEW.primary_color, 4, 2))::bit(8)::int;
        v_b := ('x' || substring(NEW.primary_color, 6, 2))::bit(8)::int;
        NEW.primary_color_rgb := v_r || ',' || v_g || ',' || v_b;
    END IF;
    
    -- Similar conversions for other colors can be added here
    -- This is a simplified example - full HSL conversion would require more complex math
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_convert_color_formats
    BEFORE INSERT OR UPDATE ON invoice_brand_colors
    FOR EACH ROW
    EXECUTE FUNCTION auto_convert_color_formats();

-- Validate color accessibility
CREATE OR REPLACE FUNCTION validate_color_accessibility()
RETURNS TRIGGER AS $$
DECLARE
    v_contrast_ratio DECIMAL(4,2);
    v_validation_errors TEXT[] := ARRAY[]::TEXT[];
    v_validation_warnings TEXT[] := ARRAY[]::TEXT[];
BEGIN
    -- Reset validation status
    NEW.color_validation_status := 'valid';
    NEW.validation_errors := ARRAY[]::TEXT[];
    NEW.validation_warnings := ARRAY[]::TEXT[];
    
    -- Check if primary color exists
    IF NEW.primary_color IS NULL THEN
        v_validation_errors := array_append(v_validation_errors, 'Primary color is required');
    END IF;
    
    -- Check contrast ratio (simplified - would need actual calculation)
    IF NEW.contrast_ratio_primary IS NOT NULL AND NEW.contrast_ratio_primary < 4.5 THEN
        v_validation_warnings := array_append(v_validation_warnings, 'Primary color contrast ratio below WCAG AA standard');
        NEW.wcag_aa_compliant := FALSE;
    ELSIF NEW.contrast_ratio_primary IS NOT NULL AND NEW.contrast_ratio_primary >= 4.5 THEN
        NEW.wcag_aa_compliant := TRUE;
        IF NEW.contrast_ratio_primary >= 7.0 THEN
            NEW.wcag_aaa_compliant := TRUE;
        END IF;
    END IF;
    
    -- Set validation status based on errors and warnings
    IF array_length(v_validation_errors, 1) > 0 THEN
        NEW.color_validation_status := 'invalid';
        NEW.validation_errors := v_validation_errors;
    ELSIF array_length(v_validation_warnings, 1) > 0 THEN
        NEW.color_validation_status := 'warning';
        NEW.validation_warnings := v_validation_warnings;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validate_color_accessibility
    BEFORE INSERT OR UPDATE ON invoice_brand_colors
    FOR EACH ROW
    EXECUTE FUNCTION validate_color_accessibility();

-- Update palette usage statistics
CREATE OR REPLACE FUNCTION update_palette_usage_stats()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Update usage count for referenced palette
        UPDATE invoice_brand_color_palettes
        SET usage_count = usage_count + 1,
            last_used_at = CURRENT_TIMESTAMP
        WHERE store_id = NEW.store_id
        AND palette_name = NEW.color_scheme_name;
        
        RETURN NEW;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_palette_usage_stats
    AFTER INSERT ON invoice_brand_colors
    FOR EACH ROW
    EXECUTE FUNCTION update_palette_usage_stats();

-- =============================================================================
-- Helper Functions
-- =============================================================================

/**
 * Get invoice brand colors with complete details
 * @param p_invoice_id UUID - Invoice ID
 * @return JSONB - Complete brand colors data
 */
CREATE OR REPLACE FUNCTION get_invoice_brand_colors(
    p_invoice_id UUID
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'brand_colors', jsonb_agg(
            jsonb_build_object(
                'id', ibc.id,
                'color_scheme_name', ibc.color_scheme_name,
                'primary_color', ibc.primary_color,
                'secondary_color', ibc.secondary_color,
                'accent_color', ibc.accent_color,
                'background_color', ibc.background_color,
                'text_color', ibc.text_color,
                'header_color', ibc.header_color,
                'footer_color', ibc.footer_color,
                'button_primary_color', ibc.button_primary_color,
                'table_header_color', ibc.table_header_color,
                'usage_context', ibc.usage_context,
                'wcag_aa_compliant', ibc.wcag_aa_compliant,
                'wcag_aaa_compliant', ibc.wcag_aaa_compliant,
                'supports_dark_mode', ibc.supports_dark_mode,
                'print_friendly', ibc.print_friendly,
                'css_variables', ibc.css_variables,
                'design_tokens', ibc.design_tokens
            )
            ORDER BY ibc.is_active DESC, ibc.created_at DESC
        ),
        'accessibility_summary', jsonb_build_object(
            'wcag_aa_compliant', bool_or(ibc.wcag_aa_compliant),
            'wcag_aaa_compliant', bool_or(ibc.wcag_aaa_compliant),
            'high_contrast_available', bool_or(ibc.high_contrast_mode),
            'dark_mode_supported', bool_or(ibc.supports_dark_mode),
            'print_optimized', bool_or(ibc.print_friendly)
        )
    ) INTO result
    FROM invoice_brand_colors ibc
    WHERE ibc.invoice_id = p_invoice_id;
    
    RETURN COALESCE(result, '{"brand_colors": [], "accessibility_summary": {}}'::jsonb);
END;
$$ LANGUAGE plpgsql;

/**
 * Apply color palette to invoice
 * @param p_invoice_id UUID - Invoice ID
 * @param p_palette_name VARCHAR - Palette name
 * @return JSONB - Application result
 */
CREATE OR REPLACE FUNCTION apply_color_palette_to_invoice(
    p_invoice_id UUID,
    p_palette_name VARCHAR(100)
)
RETURNS JSONB AS $$
DECLARE
    v_store_id UUID;
    v_palette_data JSONB;
    v_brand_color_id UUID;
    result JSONB;
BEGIN
    -- Get store ID from invoice
    SELECT store_id INTO v_store_id
    FROM invoices
    WHERE id = p_invoice_id;
    
    IF v_store_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Invoice not found');
    END IF;
    
    -- Get palette data
    SELECT color_definitions INTO v_palette_data
    FROM invoice_brand_color_palettes
    WHERE store_id = v_store_id
    AND palette_name = p_palette_name
    AND is_active = TRUE;
    
    IF v_palette_data IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Palette not found');
    END IF;
    
    -- Insert or update brand colors for invoice
    INSERT INTO invoice_brand_colors (
        invoice_id, store_id, color_scheme_name,
        primary_color, secondary_color, accent_color,
        background_color, text_color, header_color,
        footer_color, button_primary_color, table_header_color,
        usage_context, data_source
    ) VALUES (
        p_invoice_id, v_store_id, p_palette_name,
        v_palette_data->>'primary_color',
        v_palette_data->>'secondary_color',
        v_palette_data->>'accent_color',
        v_palette_data->>'background_color',
        v_palette_data->>'text_color',
        v_palette_data->>'header_color',
        v_palette_data->>'footer_color',
        v_palette_data->>'button_primary_color',
        v_palette_data->>'table_header_color',
        'invoice', 'palette_application'
    )
    ON CONFLICT (invoice_id, color_scheme_name)
    DO UPDATE SET
        primary_color = EXCLUDED.primary_color,
        secondary_color = EXCLUDED.secondary_color,
        accent_color = EXCLUDED.accent_color,
        background_color = EXCLUDED.background_color,
        text_color = EXCLUDED.text_color,
        header_color = EXCLUDED.header_color,
        footer_color = EXCLUDED.footer_color,
        button_primary_color = EXCLUDED.button_primary_color,
        table_header_color = EXCLUDED.table_header_color,
        updated_at = CURRENT_TIMESTAMP
    RETURNING id INTO v_brand_color_id;
    
    RETURN jsonb_build_object(
        'success', true,
        'brand_color_id', v_brand_color_id,
        'palette_applied', p_palette_name,
        'colors_updated', v_palette_data
    );
END;
$$ LANGUAGE plpgsql;

/**
 * Generate CSS variables from brand colors
 * @param p_invoice_id UUID - Invoice ID
 * @return TEXT - CSS variables string
 */
CREATE OR REPLACE FUNCTION generate_css_variables_from_brand_colors(
    p_invoice_id UUID
)
RETURNS TEXT AS $$
DECLARE
    v_css_vars TEXT := '';
    v_color_record RECORD;
BEGIN
    FOR v_color_record IN
        SELECT *
        FROM invoice_brand_colors
        WHERE invoice_id = p_invoice_id
        AND is_active = TRUE
        ORDER BY created_at DESC
        LIMIT 1
    LOOP
        v_css_vars := v_css_vars || ':root {' || E'\n';
        
        IF v_color_record.primary_color IS NOT NULL THEN
            v_css_vars := v_css_vars || '  --primary-color: ' || v_color_record.primary_color || ';' || E'\n';
        END IF;
        
        IF v_color_record.secondary_color IS NOT NULL THEN
            v_css_vars := v_css_vars || '  --secondary-color: ' || v_color_record.secondary_color || ';' || E'\n';
        END IF;
        
        IF v_color_record.accent_color IS NOT NULL THEN
            v_css_vars := v_css_vars || '  --accent-color: ' || v_color_record.accent_color || ';' || E'\n';
        END IF;
        
        IF v_color_record.background_color IS NOT NULL THEN
            v_css_vars := v_css_vars || '  --background-color: ' || v_color_record.background_color || ';' || E'\n';
        END IF;
        
        IF v_color_record.text_color IS NOT NULL THEN
            v_css_vars := v_css_vars || '  --text-color: ' || v_color_record.text_color || ';' || E'\n';
        END IF;
        
        IF v_color_record.header_color IS NOT NULL THEN
            v_css_vars := v_css_vars || '  --header-color: ' || v_color_record.header_color || ';' || E'\n';
        END IF;
        
        IF v_color_record.footer_color IS NOT NULL THEN
            v_css_vars := v_css_vars || '  --footer-color: ' || v_color_record.footer_color || ';' || E'\n';
        END IF;
        
        IF v_color_record.button_primary_color IS NOT NULL THEN
            v_css_vars := v_css_vars || '  --button-primary-color: ' || v_color_record.button_primary_color || ';' || E'\n';
        END IF;
        
        IF v_color_record.table_header_color IS NOT NULL THEN
            v_css_vars := v_css_vars || '  --table-header-color: ' || v_color_record.table_header_color || ';' || E'\n';
        END IF;
        
        v_css_vars := v_css_vars || '}' || E'\n';
    END LOOP;
    
    RETURN v_css_vars;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Comments
-- =============================================================================

COMMENT ON TABLE invoice_brand_colors IS 'Normalized brand colors for invoices with comprehensive color management and accessibility features';
COMMENT ON TABLE invoice_brand_color_history IS 'Track changes to invoice brand colors';
COMMENT ON TABLE invoice_brand_color_palettes IS 'Predefined color palettes for reuse across invoices';
COMMENT ON TABLE invoice_color_accessibility_rules IS 'Accessibility rules and compliance checks for colors';

COMMENT ON COLUMN invoice_brand_colors.primary_color IS 'Primary brand color in hex format (#RRGGBB)';
COMMENT ON COLUMN invoice_brand_colors.contrast_ratio_primary IS 'WCAG contrast ratio for primary color against background';
COMMENT ON COLUMN invoice_brand_colors.wcag_aa_compliant IS 'Whether colors meet WCAG AA accessibility standards';
COMMENT ON COLUMN invoice_brand_colors.css_variables IS 'CSS custom properties generated from colors';
COMMENT ON COLUMN invoice_brand_colors.design_tokens IS 'Design system tokens for colors';

COMMENT ON FUNCTION get_invoice_brand_colors(UUID) IS 'Get complete brand colors data with accessibility summary for invoice';
COMMENT ON FUNCTION apply_color_palette_to_invoice(UUID, VARCHAR) IS 'Apply predefined color palette to invoice';
COMMENT ON FUNCTION generate_css_variables_from_brand_colors(UUID) IS 'Generate CSS variables string from invoice brand colors';