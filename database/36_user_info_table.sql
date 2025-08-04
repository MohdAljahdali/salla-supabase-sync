-- =====================================================
-- User Info Table
-- =====================================================
-- This table stores comprehensive user information and profiles
-- for detailed user management and personalization

CREATE TABLE IF NOT EXISTS user_info (
    -- Primary identification
    id BIGSERIAL PRIMARY KEY,
    
    -- Store relationship (required)
    store_id BIGINT NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- User identification
    user_id BIGINT NOT NULL, -- Reference to main users table
    user_uuid UUID DEFAULT gen_random_uuid(),
    external_user_id VARCHAR(255),
    username VARCHAR(100),
    
    -- Personal information
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    middle_name VARCHAR(100),
    full_name VARCHAR(255),
    display_name VARCHAR(255),
    nickname VARCHAR(100),
    
    -- Contact information
    primary_email VARCHAR(255),
    secondary_email VARCHAR(255),
    email_verified BOOLEAN NOT NULL DEFAULT FALSE,
    email_verification_date TIMESTAMP WITH TIME ZONE,
    
    -- Phone information
    primary_phone VARCHAR(50),
    secondary_phone VARCHAR(50),
    phone_verified BOOLEAN NOT NULL DEFAULT FALSE,
    phone_verification_date TIMESTAMP WITH TIME ZONE,
    phone_country_code VARCHAR(5),
    
    -- Address information
    address_line_1 VARCHAR(255),
    address_line_2 VARCHAR(255),
    city VARCHAR(100),
    state_province VARCHAR(100),
    postal_code VARCHAR(20),
    country_code VARCHAR(3),
    country_name VARCHAR(100),
    
    -- Personal details
    date_of_birth DATE,
    gender VARCHAR(20), -- male, female, other, prefer_not_to_say
    nationality VARCHAR(100),
    preferred_language VARCHAR(10) DEFAULT 'en',
    timezone VARCHAR(50) DEFAULT 'UTC',
    
    -- Professional information
    job_title VARCHAR(255),
    company_name VARCHAR(255),
    department VARCHAR(100),
    industry VARCHAR(100),
    experience_level VARCHAR(50), -- junior, mid, senior, expert
    
    -- User role and permissions
    user_role VARCHAR(50) NOT NULL DEFAULT 'user', -- admin, manager, staff, user, customer
    permission_level VARCHAR(50) DEFAULT 'basic', -- basic, advanced, full, custom
    access_level INTEGER DEFAULT 1, -- 1-10 scale
    is_super_admin BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- Account status and security
    account_status VARCHAR(50) NOT NULL DEFAULT 'active', -- active, inactive, suspended, banned, pending
    account_type VARCHAR(50) DEFAULT 'standard', -- standard, premium, enterprise, trial
    security_level VARCHAR(50) DEFAULT 'standard', -- basic, standard, enhanced, maximum
    two_factor_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- Authentication information
    last_login_at TIMESTAMP WITH TIME ZONE,
    last_login_ip INET,
    login_count INTEGER NOT NULL DEFAULT 0,
    failed_login_attempts INTEGER NOT NULL DEFAULT 0,
    last_failed_login_at TIMESTAMP WITH TIME ZONE,
    
    -- Password and security
    password_last_changed TIMESTAMP WITH TIME ZONE,
    password_expires_at TIMESTAMP WITH TIME ZONE,
    requires_password_change BOOLEAN NOT NULL DEFAULT FALSE,
    security_questions_set BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- Profile and preferences
    avatar_url VARCHAR(500),
    cover_image_url VARCHAR(500),
    bio TEXT,
    website_url VARCHAR(500),
    social_media_links JSONB,
    
    -- User preferences
    notification_preferences JSONB,
    privacy_settings JSONB,
    display_preferences JSONB,
    communication_preferences JSONB,
    
    -- Localization preferences
    date_format VARCHAR(50) DEFAULT 'YYYY-MM-DD',
    time_format VARCHAR(20) DEFAULT '24h',
    number_format JSONB,
    currency_preference VARCHAR(3) DEFAULT 'USD',
    
    -- Activity and engagement
    total_logins INTEGER NOT NULL DEFAULT 0,
    total_sessions INTEGER NOT NULL DEFAULT 0,
    total_time_spent_minutes BIGINT NOT NULL DEFAULT 0,
    last_activity_at TIMESTAMP WITH TIME ZONE,
    activity_score INTEGER DEFAULT 0, -- 0-100
    
    -- User behavior and analytics
    page_views INTEGER NOT NULL DEFAULT 0,
    actions_performed INTEGER NOT NULL DEFAULT 0,
    features_used TEXT[],
    most_used_features JSONB,
    user_journey JSONB,
    
    -- Subscription and billing
    subscription_plan VARCHAR(100),
    subscription_status VARCHAR(50) DEFAULT 'none', -- none, active, expired, cancelled
    subscription_start_date DATE,
    subscription_end_date DATE,
    billing_preferences JSONB,
    
    -- Support and help
    support_tier VARCHAR(50) DEFAULT 'standard', -- basic, standard, premium, enterprise
    total_support_tickets INTEGER NOT NULL DEFAULT 0,
    last_support_contact TIMESTAMP WITH TIME ZONE,
    satisfaction_score DECIMAL(3,2), -- 0.00 to 10.00
    
    -- Training and onboarding
    onboarding_completed BOOLEAN NOT NULL DEFAULT FALSE,
    onboarding_progress INTEGER DEFAULT 0, -- 0-100 percentage
    training_completed TEXT[],
    certifications TEXT[],
    skill_level JSONB,
    
    -- Device and browser information
    preferred_device_type VARCHAR(50), -- desktop, mobile, tablet
    browser_preferences JSONB,
    device_info JSONB,
    operating_system VARCHAR(100),
    
    -- Integration and external accounts
    external_accounts JSONB, -- Social logins, third-party integrations
    api_access_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    api_key_hash VARCHAR(255),
    api_usage_stats JSONB,
    
    -- Compliance and legal
    terms_accepted BOOLEAN NOT NULL DEFAULT FALSE,
    terms_accepted_date TIMESTAMP WITH TIME ZONE,
    privacy_policy_accepted BOOLEAN NOT NULL DEFAULT FALSE,
    privacy_policy_accepted_date TIMESTAMP WITH TIME ZONE,
    marketing_consent BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- Data and privacy
    data_retention_preference VARCHAR(50) DEFAULT 'standard', -- minimal, standard, extended
    data_export_requests INTEGER NOT NULL DEFAULT 0,
    data_deletion_requested BOOLEAN NOT NULL DEFAULT FALSE,
    data_deletion_date TIMESTAMP WITH TIME ZONE,
    
    -- Performance and metrics
    productivity_score INTEGER DEFAULT 0, -- 0-100
    efficiency_rating DECIMAL(3,2), -- 0.00 to 10.00
    goal_completion_rate DECIMAL(5,2) DEFAULT 0.00, -- 0.00 to 100.00
    performance_metrics JSONB,
    
    -- Team and collaboration
    team_id BIGINT,
    team_role VARCHAR(100),
    manager_user_id BIGINT,
    direct_reports_count INTEGER DEFAULT 0,
    collaboration_score INTEGER DEFAULT 0, -- 0-100
    
    -- Notifications and alerts
    notification_channels TEXT[], -- email, sms, push, in_app
    alert_preferences JSONB,
    digest_frequency VARCHAR(20) DEFAULT 'weekly', -- never, daily, weekly, monthly
    quiet_hours JSONB,
    
    -- Gamification and rewards
    points_earned INTEGER NOT NULL DEFAULT 0,
    level_achieved INTEGER DEFAULT 1,
    badges_earned TEXT[],
    achievements JSONB,
    rewards_claimed INTEGER NOT NULL DEFAULT 0,
    
    -- Health and wellness (for employee users)
    work_schedule JSONB,
    break_preferences JSONB,
    wellness_score INTEGER DEFAULT 0, -- 0-100
    stress_level VARCHAR(20), -- low, medium, high
    
    -- Emergency and backup contacts
    emergency_contacts JSONB,
    backup_email VARCHAR(255),
    recovery_phone VARCHAR(50),
    trusted_devices JSONB,
    
    -- Audit and compliance tracking
    compliance_training_status JSONB,
    audit_log_retention_days INTEGER DEFAULT 90,
    sensitive_data_access BOOLEAN NOT NULL DEFAULT FALSE,
    background_check_status VARCHAR(50), -- not_required, pending, completed, failed
    
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
CREATE INDEX IF NOT EXISTS idx_user_info_store_user 
    ON user_info(store_id, user_id);

CREATE UNIQUE INDEX IF NOT EXISTS idx_user_info_user_uuid 
    ON user_info(user_uuid);

CREATE INDEX IF NOT EXISTS idx_user_info_username 
    ON user_info(store_id, username)
    WHERE username IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_user_info_email 
    ON user_info(store_id, primary_email)
    WHERE primary_email IS NOT NULL;

-- Role and permission indexes
CREATE INDEX IF NOT EXISTS idx_user_info_role 
    ON user_info(store_id, user_role, account_status);

CREATE INDEX IF NOT EXISTS idx_user_info_permissions 
    ON user_info(store_id, permission_level, access_level);

CREATE INDEX IF NOT EXISTS idx_user_info_admin 
    ON user_info(store_id, is_super_admin)
    WHERE is_super_admin = TRUE;

-- Status and activity indexes
CREATE INDEX IF NOT EXISTS idx_user_info_status 
    ON user_info(store_id, account_status, account_type);

CREATE INDEX IF NOT EXISTS idx_user_info_activity 
    ON user_info(store_id, last_activity_at DESC)
    WHERE last_activity_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_user_info_login 
    ON user_info(store_id, last_login_at DESC)
    WHERE last_login_at IS NOT NULL;

-- Security and authentication indexes
CREATE INDEX IF NOT EXISTS idx_user_info_security 
    ON user_info(store_id, security_level, two_factor_enabled);

CREATE INDEX IF NOT EXISTS idx_user_info_failed_logins 
    ON user_info(store_id, failed_login_attempts)
    WHERE failed_login_attempts > 0;

CREATE INDEX IF NOT EXISTS idx_user_info_verification 
    ON user_info(store_id, email_verified, phone_verified);

-- Team and collaboration indexes
CREATE INDEX IF NOT EXISTS idx_user_info_team 
    ON user_info(store_id, team_id, team_role)
    WHERE team_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_user_info_manager 
    ON user_info(store_id, manager_user_id)
    WHERE manager_user_id IS NOT NULL;

-- Subscription and billing indexes
CREATE INDEX IF NOT EXISTS idx_user_info_subscription 
    ON user_info(store_id, subscription_status, subscription_end_date)
    WHERE subscription_status IS NOT NULL;

-- Performance and engagement indexes
CREATE INDEX IF NOT EXISTS idx_user_info_performance 
    ON user_info(store_id, productivity_score, activity_score)
    WHERE productivity_score IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_user_info_engagement 
    ON user_info(store_id, total_logins, total_time_spent_minutes);

-- Geographic and localization indexes
CREATE INDEX IF NOT EXISTS idx_user_info_location 
    ON user_info(country_code, state_province, city)
    WHERE country_code IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_user_info_timezone 
    ON user_info(timezone, preferred_language);

-- Time-based indexes
CREATE INDEX IF NOT EXISTS idx_user_info_created_at 
    ON user_info(store_id, created_at);

CREATE INDEX IF NOT EXISTS idx_user_info_updated_at 
    ON user_info(store_id, updated_at);

-- JSON indexes for flexible querying
CREATE INDEX IF NOT EXISTS idx_user_info_preferences 
    ON user_info USING GIN(notification_preferences)
    WHERE notification_preferences IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_user_info_custom_attributes 
    ON user_info USING GIN(custom_attributes)
    WHERE custom_attributes IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_user_info_tags 
    ON user_info USING GIN(tags)
    WHERE tags IS NOT NULL;

-- =====================================================
-- Unique Constraints
-- =====================================================

-- Ensure unique user per store
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_info_store_user_unique 
    ON user_info(store_id, user_id);

-- Ensure unique usernames per store
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_info_username_unique 
    ON user_info(store_id, username)
    WHERE username IS NOT NULL;

-- Ensure unique primary emails per store
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_info_email_unique 
    ON user_info(store_id, primary_email)
    WHERE primary_email IS NOT NULL;

-- =====================================================
-- Triggers
-- =====================================================

-- Updated at trigger
CREATE OR REPLACE FUNCTION update_user_info_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_user_info_updated_at
    BEFORE UPDATE ON user_info
    FOR EACH ROW
    EXECUTE FUNCTION update_user_info_updated_at();

-- User activity tracking trigger
CREATE OR REPLACE FUNCTION track_user_activity()
RETURNS TRIGGER AS $$
BEGIN
    -- Update login tracking
    IF OLD.last_login_at IS DISTINCT FROM NEW.last_login_at THEN
        NEW.login_count = OLD.login_count + 1;
        NEW.total_logins = OLD.total_logins + 1;
        NEW.failed_login_attempts = 0; -- Reset failed attempts on successful login
    END IF;
    
    -- Update activity tracking
    IF OLD.last_activity_at IS DISTINCT FROM NEW.last_activity_at THEN
        NEW.total_sessions = OLD.total_sessions + 1;
    END IF;
    
    -- Calculate activity score based on recent activity
    IF NEW.last_activity_at IS NOT NULL THEN
        DECLARE
            days_since_activity INTEGER;
        BEGIN
            days_since_activity := EXTRACT(DAY FROM (CURRENT_TIMESTAMP - NEW.last_activity_at));
            CASE 
                WHEN days_since_activity = 0 THEN NEW.activity_score = 100;
                WHEN days_since_activity <= 7 THEN NEW.activity_score = 80;
                WHEN days_since_activity <= 30 THEN NEW.activity_score = 60;
                WHEN days_since_activity <= 90 THEN NEW.activity_score = 40;
                ELSE NEW.activity_score = 20;
            END CASE;
        END;
    END IF;
    
    -- Generate full name if not provided
    IF NEW.full_name IS NULL AND (NEW.first_name IS NOT NULL OR NEW.last_name IS NOT NULL) THEN
        NEW.full_name = TRIM(COALESCE(NEW.first_name, '') || ' ' || COALESCE(NEW.last_name, ''));
    END IF;
    
    -- Set display name if not provided
    IF NEW.display_name IS NULL THEN
        NEW.display_name = COALESCE(NEW.full_name, NEW.username, NEW.primary_email);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_user_activity
    BEFORE UPDATE ON user_info
    FOR EACH ROW
    EXECUTE FUNCTION track_user_activity();

-- Security monitoring trigger
CREATE OR REPLACE FUNCTION monitor_user_security()
RETURNS TRIGGER AS $$
BEGIN
    -- Track failed login attempts
    IF OLD.failed_login_attempts IS DISTINCT FROM NEW.failed_login_attempts 
       AND NEW.failed_login_attempts > OLD.failed_login_attempts THEN
        NEW.last_failed_login_at = CURRENT_TIMESTAMP;
        
        -- Auto-suspend account after too many failed attempts
        IF NEW.failed_login_attempts >= 5 AND NEW.account_status = 'active' THEN
            NEW.account_status = 'suspended';
            NEW.metadata = COALESCE(NEW.metadata, '{}'::jsonb) || 
                          jsonb_build_object('auto_suspended', true, 'reason', 'too_many_failed_logins', 'suspended_at', CURRENT_TIMESTAMP);
        END IF;
    END IF;
    
    -- Check password expiration
    IF NEW.password_expires_at IS NOT NULL AND NEW.password_expires_at < CURRENT_TIMESTAMP THEN
        NEW.requires_password_change = TRUE;
    END IF;
    
    -- Update security level based on security features
    DECLARE
        security_score INTEGER := 0;
    BEGIN
        IF NEW.two_factor_enabled THEN security_score := security_score + 25; END IF;
        IF NEW.email_verified THEN security_score := security_score + 15; END IF;
        IF NEW.phone_verified THEN security_score := security_score + 15; END IF;
        IF NEW.security_questions_set THEN security_score := security_score + 10; END IF;
        IF NEW.password_last_changed > (CURRENT_TIMESTAMP - INTERVAL '90 days') THEN security_score := security_score + 20; END IF;
        IF NEW.trusted_devices IS NOT NULL THEN security_score := security_score + 15; END IF;
        
        CASE 
            WHEN security_score >= 80 THEN NEW.security_level = 'maximum';
            WHEN security_score >= 60 THEN NEW.security_level = 'enhanced';
            WHEN security_score >= 40 THEN NEW.security_level = 'standard';
            ELSE NEW.security_level = 'basic';
        END CASE;
    END;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_user_security
    BEFORE UPDATE ON user_info
    FOR EACH ROW
    EXECUTE FUNCTION monitor_user_security();

-- =====================================================
-- Helper Functions
-- =====================================================

-- Function to get user profile
CREATE OR REPLACE FUNCTION get_user_profile(
    store_id_param BIGINT,
    user_id_param BIGINT
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'user_id', user_id,
        'user_uuid', user_uuid,
        'personal_info', jsonb_build_object(
            'full_name', full_name,
            'display_name', display_name,
            'email', primary_email,
            'phone', primary_phone,
            'avatar_url', avatar_url
        ),
        'account_info', jsonb_build_object(
            'user_role', user_role,
            'account_status', account_status,
            'account_type', account_type,
            'security_level', security_level,
            'two_factor_enabled', two_factor_enabled
        ),
        'activity_info', jsonb_build_object(
            'last_login_at', last_login_at,
            'last_activity_at', last_activity_at,
            'total_logins', total_logins,
            'activity_score', activity_score
        ),
        'preferences', jsonb_build_object(
            'preferred_language', preferred_language,
            'timezone', timezone,
            'notification_preferences', notification_preferences,
            'privacy_settings', privacy_settings
        )
    ) INTO result
    FROM user_info
    WHERE store_id = store_id_param AND user_id = user_id_param;
    
    IF result IS NULL THEN
        RETURN '{"error": "User not found"}'::jsonb;
    END IF;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to update user activity
CREATE OR REPLACE FUNCTION update_user_activity(
    store_id_param BIGINT,
    user_id_param BIGINT,
    activity_type VARCHAR DEFAULT 'general',
    ip_address INET DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    success BOOLEAN := FALSE;
BEGIN
    UPDATE user_info
    SET last_activity_at = CURRENT_TIMESTAMP,
        actions_performed = actions_performed + 1,
        page_views = CASE WHEN activity_type = 'page_view' THEN page_views + 1 ELSE page_views END,
        updated_at = CURRENT_TIMESTAMP
    WHERE store_id = store_id_param AND user_id = user_id_param
    RETURNING TRUE INTO success;
    
    RETURN COALESCE(success, FALSE);
END;
$$ LANGUAGE plpgsql;

-- Function to record user login
CREATE OR REPLACE FUNCTION record_user_login(
    store_id_param BIGINT,
    user_id_param BIGINT,
    ip_address INET DEFAULT NULL,
    user_agent TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    success BOOLEAN := FALSE;
BEGIN
    UPDATE user_info
    SET last_login_at = CURRENT_TIMESTAMP,
        last_login_ip = ip_address,
        last_activity_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP,
        metadata = COALESCE(metadata, '{}'::jsonb) || 
                  jsonb_build_object('last_user_agent', user_agent, 'last_login_recorded', CURRENT_TIMESTAMP)
    WHERE store_id = store_id_param AND user_id = user_id_param
    RETURNING TRUE INTO success;
    
    RETURN COALESCE(success, FALSE);
END;
$$ LANGUAGE plpgsql;

-- Function to search users
CREATE OR REPLACE FUNCTION search_users(
    store_id_param BIGINT,
    search_term VARCHAR DEFAULT NULL,
    role_filter VARCHAR DEFAULT NULL,
    status_filter VARCHAR DEFAULT NULL,
    team_filter BIGINT DEFAULT NULL,
    limit_param INTEGER DEFAULT 50
)
RETURNS TABLE (
    user_id BIGINT,
    user_uuid UUID,
    full_name VARCHAR,
    display_name VARCHAR,
    primary_email VARCHAR,
    user_role VARCHAR,
    account_status VARCHAR,
    last_login_at TIMESTAMP WITH TIME ZONE,
    activity_score INTEGER,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ui.user_id,
        ui.user_uuid,
        ui.full_name,
        ui.display_name,
        ui.primary_email,
        ui.user_role,
        ui.account_status,
        ui.last_login_at,
        ui.activity_score,
        ui.created_at
    FROM user_info ui
    WHERE ui.store_id = store_id_param
        AND (
            search_term IS NULL 
            OR ui.full_name ILIKE '%' || search_term || '%'
            OR ui.display_name ILIKE '%' || search_term || '%'
            OR ui.primary_email ILIKE '%' || search_term || '%'
            OR ui.username ILIKE '%' || search_term || '%'
        )
        AND (role_filter IS NULL OR ui.user_role = role_filter)
        AND (status_filter IS NULL OR ui.account_status = status_filter)
        AND (team_filter IS NULL OR ui.team_id = team_filter)
    ORDER BY ui.last_activity_at DESC NULLS LAST, ui.created_at DESC
    LIMIT limit_param;
END;
$$ LANGUAGE plpgsql;

-- Function to get user statistics
CREATE OR REPLACE FUNCTION get_user_stats(
    store_id_param BIGINT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_users', COUNT(*),
        'active_users', COUNT(*) FILTER (WHERE account_status = 'active'),
        'inactive_users', COUNT(*) FILTER (WHERE account_status = 'inactive'),
        'suspended_users', COUNT(*) FILTER (WHERE account_status = 'suspended'),
        'verified_users', COUNT(*) FILTER (WHERE email_verified = TRUE),
        'two_factor_users', COUNT(*) FILTER (WHERE two_factor_enabled = TRUE),
        'recent_logins', COUNT(*) FILTER (WHERE last_login_at > CURRENT_TIMESTAMP - INTERVAL '7 days'),
        'average_activity_score', AVG(activity_score) FILTER (WHERE activity_score > 0),
        'role_distribution', (
            SELECT jsonb_object_agg(user_role, role_count)
            FROM (
                SELECT user_role, COUNT(*) as role_count
                FROM user_info
                WHERE (store_id_param IS NULL OR store_id = store_id_param)
                GROUP BY user_role
            ) role_stats
        ),
        'security_levels', (
            SELECT jsonb_object_agg(security_level, security_count)
            FROM (
                SELECT security_level, COUNT(*) as security_count
                FROM user_info
                WHERE (store_id_param IS NULL OR store_id = store_id_param)
                GROUP BY security_level
            ) security_stats
        ),
        'last_updated', MAX(updated_at)
    ) INTO result
    FROM user_info
    WHERE (store_id_param IS NULL OR store_id = store_id_param);
    
    RETURN COALESCE(result, '{"error": "No users found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- Function to get user performance metrics
CREATE OR REPLACE FUNCTION get_user_performance(
    store_id_param BIGINT,
    user_id_param BIGINT
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'user_id', user_id,
        'performance_scores', jsonb_build_object(
            'activity_score', activity_score,
            'productivity_score', productivity_score,
            'efficiency_rating', efficiency_rating,
            'goal_completion_rate', goal_completion_rate
        ),
        'engagement_metrics', jsonb_build_object(
            'total_logins', total_logins,
            'total_sessions', total_sessions,
            'total_time_spent_hours', (total_time_spent_minutes::DECIMAL / 60),
            'page_views', page_views,
            'actions_performed', actions_performed
        ),
        'recent_activity', jsonb_build_object(
            'last_login_at', last_login_at,
            'last_activity_at', last_activity_at,
            'days_since_last_login', CASE 
                WHEN last_login_at IS NOT NULL THEN 
                    EXTRACT(DAY FROM (CURRENT_TIMESTAMP - last_login_at))
                ELSE NULL
            END
        ),
        'achievements', jsonb_build_object(
            'points_earned', points_earned,
            'level_achieved', level_achieved,
            'badges_earned', badges_earned,
            'rewards_claimed', rewards_claimed
        )
    ) INTO result
    FROM user_info
    WHERE store_id = store_id_param AND user_id = user_id_param;
    
    IF result IS NULL THEN
        RETURN '{"error": "User not found"}'::jsonb;
    END IF;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Comments for Documentation
-- =====================================================

COMMENT ON TABLE user_info IS 'Comprehensive user information and profiles for detailed user management';
COMMENT ON COLUMN user_info.user_id IS 'Reference to the main users table';
COMMENT ON COLUMN user_info.user_uuid IS 'Unique UUID identifier for external integrations';
COMMENT ON COLUMN user_info.user_role IS 'Role of the user within the store (admin, manager, staff, etc.)';
COMMENT ON COLUMN user_info.account_status IS 'Current status of the user account';
COMMENT ON COLUMN user_info.security_level IS 'Security level based on enabled security features';
COMMENT ON COLUMN user_info.activity_score IS 'Score representing user activity level (0-100)';
COMMENT ON COLUMN user_info.two_factor_enabled IS 'Whether two-factor authentication is enabled';
COMMENT ON COLUMN user_info.failed_login_attempts IS 'Number of consecutive failed login attempts';
COMMENT ON COLUMN user_info.productivity_score IS 'User productivity score (0-100)';
COMMENT ON COLUMN user_info.total_time_spent_minutes IS 'Total time spent in the system in minutes';

COMMENT ON FUNCTION get_user_profile(BIGINT, BIGINT) IS 'Get comprehensive user profile information';
COMMENT ON FUNCTION update_user_activity(BIGINT, BIGINT, VARCHAR, INET) IS 'Update user activity tracking';
COMMENT ON FUNCTION record_user_login(BIGINT, BIGINT, INET, TEXT) IS 'Record user login with IP and user agent';
COMMENT ON FUNCTION search_users(BIGINT, VARCHAR, VARCHAR, VARCHAR, BIGINT, INTEGER) IS 'Search users with advanced filtering options';
COMMENT ON FUNCTION get_user_stats(BIGINT) IS 'Get comprehensive user statistics';
COMMENT ON FUNCTION get_user_performance(BIGINT, BIGINT) IS 'Get detailed user performance metrics';