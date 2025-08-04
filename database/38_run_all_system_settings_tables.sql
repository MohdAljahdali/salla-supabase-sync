-- =====================================================
-- Run All System and Settings Tables
-- =====================================================
-- This script creates all system and settings tables in the correct order
-- Execute this file to set up all system and settings tables at once

-- Display start message
\echo ''
\echo '================================================'
\echo 'Creating System and Settings Tables'
\echo '================================================'
\echo ''

-- 1. Settings Table
\echo 'Creating Settings Table...'
\i 33_settings_table.sql
\echo 'Settings Table created successfully!'
\echo ''

-- 2. Export Logs Table
\echo 'Creating Export Logs Table...'
\i 34_export_logs_table.sql
\echo 'Export Logs Table created successfully!'
\echo ''

-- 3. Store Info Table
\echo 'Creating Store Info Table...'
\i 35_store_info_table.sql
\echo 'Store Info Table created successfully!'
\echo ''

-- 4. User Info Table
\echo 'Creating User Info Table...'
\i 36_user_info_table.sql
\echo 'User Info Table created successfully!'
\echo ''

-- 5. Sync Logs Table
\echo 'Creating Sync Logs Table...'
\i 37_sync_logs_table.sql
\echo 'Sync Logs Table created successfully!'
\echo ''

-- =====================================================
-- Cross-Table Indexes for System Performance
-- =====================================================

\echo 'Creating cross-table indexes for system performance...'

-- System monitoring indexes
CREATE INDEX IF NOT EXISTS idx_system_store_activity 
    ON sync_logs(store_id, started_at DESC, sync_status)
    WHERE started_at >= CURRENT_TIMESTAMP - INTERVAL '24 hours';

CREATE INDEX IF NOT EXISTS idx_system_user_activity 
    ON user_info(store_id, last_activity_at DESC, account_status)
    WHERE last_activity_at >= CURRENT_TIMESTAMP - INTERVAL '7 days';

CREATE INDEX IF NOT EXISTS idx_system_export_activity 
    ON export_logs(store_id, started_at DESC, export_status)
    WHERE started_at >= CURRENT_TIMESTAMP - INTERVAL '30 days';

-- Performance monitoring indexes
CREATE INDEX IF NOT EXISTS idx_system_sync_performance 
    ON sync_logs(store_id, duration_seconds, records_processed)
    WHERE sync_status = 'completed' AND duration_seconds IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_system_export_performance 
    ON export_logs(store_id, processing_time_seconds, total_records)
    WHERE export_status = 'completed' AND processing_time_seconds IS NOT NULL;

-- Error tracking indexes
CREATE INDEX IF NOT EXISTS idx_system_sync_errors 
    ON sync_logs(store_id, error_count, last_error_message)
    WHERE error_count > 0;

CREATE INDEX IF NOT EXISTS idx_system_export_errors 
    ON export_logs(store_id, error_count, last_error_message)
    WHERE error_count > 0;

-- Security monitoring indexes
CREATE INDEX IF NOT EXISTS idx_system_user_security 
    ON user_info(store_id, failed_login_attempts, last_failed_login_at)
    WHERE failed_login_attempts > 0;

CREATE INDEX IF NOT EXISTS idx_system_user_verification 
    ON user_info(store_id, email_verified, phone_verified, two_factor_enabled);

-- Settings usage indexes
CREATE INDEX IF NOT EXISTS idx_system_settings_usage 
    ON settings(store_id, last_accessed_at DESC, access_count)
    WHERE last_accessed_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_system_settings_critical 
    ON settings(store_id, is_critical, is_system_setting)
    WHERE is_critical = TRUE OR is_system_setting = TRUE;

\echo 'Cross-table indexes created successfully!'
\echo ''

-- =====================================================
-- System Views for Comprehensive Monitoring
-- =====================================================

\echo 'Creating system monitoring views...'

-- System overview view
CREATE OR REPLACE VIEW system_overview AS
SELECT 
    s.id as store_id,
    s.name as store_name,
    si.store_status,
    si.total_users,
    si.active_users_count,
    si.total_orders,
    si.total_products,
    -- Recent sync activity
    (
        SELECT COUNT(*)
        FROM sync_logs sl
        WHERE sl.store_id = s.id
            AND sl.started_at >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
    ) as syncs_last_24h,
    (
        SELECT COUNT(*)
        FROM sync_logs sl
        WHERE sl.store_id = s.id
            AND sl.sync_status = 'failed'
            AND sl.started_at >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
    ) as failed_syncs_last_24h,
    -- Recent export activity
    (
        SELECT COUNT(*)
        FROM export_logs el
        WHERE el.store_id = s.id
            AND el.started_at >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
    ) as exports_last_24h,
    -- Active users
    (
        SELECT COUNT(*)
        FROM user_info ui
        WHERE ui.store_id = s.id
            AND ui.account_status = 'active'
            AND ui.last_activity_at >= CURRENT_TIMESTAMP - INTERVAL '7 days'
    ) as active_users_last_7d,
    -- System health indicators
    CASE 
        WHEN (
            SELECT COUNT(*)
            FROM sync_logs sl
            WHERE sl.store_id = s.id
                AND sl.sync_status = 'failed'
                AND sl.started_at >= CURRENT_TIMESTAMP - INTERVAL '1 hour'
        ) > 5 THEN 'critical'
        WHEN (
            SELECT COUNT(*)
            FROM sync_logs sl
            WHERE sl.store_id = s.id
                AND sl.sync_status = 'failed'
                AND sl.started_at >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
        ) > 10 THEN 'warning'
        ELSE 'healthy'
    END as system_health,
    CURRENT_TIMESTAMP as last_updated
FROM stores s
LEFT JOIN store_info si ON s.id = si.store_id;

-- Sync performance view
CREATE OR REPLACE VIEW sync_performance_summary AS
SELECT 
    store_id,
    entity_type,
    operation_type,
    COUNT(*) as total_syncs,
    COUNT(*) FILTER (WHERE sync_status = 'completed') as successful_syncs,
    COUNT(*) FILTER (WHERE sync_status = 'failed') as failed_syncs,
    AVG(duration_seconds) FILTER (WHERE duration_seconds IS NOT NULL) as avg_duration_seconds,
    AVG(records_processed) FILTER (WHERE records_processed > 0) as avg_records_processed,
    AVG(data_quality_score) FILTER (WHERE data_quality_score IS NOT NULL) as avg_data_quality,
    MAX(started_at) as last_sync_at,
    SUM(records_created) as total_records_created,
    SUM(records_updated) as total_records_updated,
    SUM(records_failed) as total_records_failed
FROM sync_logs
WHERE started_at >= CURRENT_TIMESTAMP - INTERVAL '30 days'
GROUP BY store_id, entity_type, operation_type;

-- User activity summary view
CREATE OR REPLACE VIEW user_activity_summary AS
SELECT 
    store_id,
    user_role,
    account_status,
    COUNT(*) as total_users,
    COUNT(*) FILTER (WHERE last_login_at >= CURRENT_TIMESTAMP - INTERVAL '24 hours') as active_last_24h,
    COUNT(*) FILTER (WHERE last_login_at >= CURRENT_TIMESTAMP - INTERVAL '7 days') as active_last_7d,
    COUNT(*) FILTER (WHERE last_login_at >= CURRENT_TIMESTAMP - INTERVAL '30 days') as active_last_30d,
    COUNT(*) FILTER (WHERE email_verified = TRUE) as verified_users,
    COUNT(*) FILTER (WHERE two_factor_enabled = TRUE) as two_factor_users,
    COUNT(*) FILTER (WHERE failed_login_attempts > 0) as users_with_failed_logins,
    AVG(activity_score) FILTER (WHERE activity_score > 0) as avg_activity_score,
    AVG(total_logins) as avg_total_logins
FROM user_info
GROUP BY store_id, user_role, account_status;

-- Export analytics view
CREATE OR REPLACE VIEW export_analytics_summary AS
SELECT 
    store_id,
    export_type,
    export_format,
    COUNT(*) as total_exports,
    COUNT(*) FILTER (WHERE export_status = 'completed') as successful_exports,
    COUNT(*) FILTER (WHERE export_status = 'failed') as failed_exports,
    AVG(processing_time_seconds) FILTER (WHERE processing_time_seconds IS NOT NULL) as avg_processing_time,
    AVG(total_records) FILTER (WHERE total_records > 0) as avg_records_exported,
    AVG(file_size_bytes) FILTER (WHERE file_size_bytes > 0) as avg_file_size_bytes,
    MAX(started_at) as last_export_at,
    SUM(total_records) as total_records_exported
FROM export_logs
WHERE started_at >= CURRENT_TIMESTAMP - INTERVAL '30 days'
GROUP BY store_id, export_type, export_format;

\echo 'System monitoring views created successfully!'
\echo ''

-- =====================================================
-- System Helper Functions
-- =====================================================

\echo 'Creating system helper functions...'

-- Function to get comprehensive system dashboard
CREATE OR REPLACE FUNCTION get_system_dashboard(
    store_id_param BIGINT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'overview', (
            SELECT jsonb_agg(row_to_json(so))
            FROM system_overview so
            WHERE (store_id_param IS NULL OR so.store_id = store_id_param)
        ),
        'sync_performance', (
            SELECT jsonb_agg(row_to_json(sps))
            FROM sync_performance_summary sps
            WHERE (store_id_param IS NULL OR sps.store_id = store_id_param)
            ORDER BY sps.total_syncs DESC
            LIMIT 10
        ),
        'user_activity', (
            SELECT jsonb_agg(row_to_json(uas))
            FROM user_activity_summary uas
            WHERE (store_id_param IS NULL OR uas.store_id = store_id_param)
        ),
        'export_analytics', (
            SELECT jsonb_agg(row_to_json(eas))
            FROM export_analytics_summary eas
            WHERE (store_id_param IS NULL OR eas.store_id = store_id_param)
            ORDER BY eas.total_exports DESC
            LIMIT 10
        ),
        'system_alerts', (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'type', 'sync_failure',
                    'store_id', store_id,
                    'entity_type', entity_type,
                    'error_message', last_error_message,
                    'occurred_at', started_at
                )
            )
            FROM sync_logs
            WHERE (store_id_param IS NULL OR store_id = store_id_param)
                AND sync_status = 'failed'
                AND started_at >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
            ORDER BY started_at DESC
            LIMIT 20
        ),
        'generated_at', CURRENT_TIMESTAMP
    ) INTO result;
    
    RETURN COALESCE(result, '{"error": "No data found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- Function to generate system health report
CREATE OR REPLACE FUNCTION generate_system_health_report(
    store_id_param BIGINT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'health_score', (
            -- Calculate overall health score based on various metrics
            SELECT CASE 
                WHEN failed_syncs_24h = 0 AND failed_exports_24h = 0 THEN 100
                WHEN failed_syncs_24h <= 5 AND failed_exports_24h <= 2 THEN 80
                WHEN failed_syncs_24h <= 15 AND failed_exports_24h <= 5 THEN 60
                WHEN failed_syncs_24h <= 30 AND failed_exports_24h <= 10 THEN 40
                ELSE 20
            END
            FROM (
                SELECT 
                    COUNT(*) FILTER (WHERE sl.sync_status = 'failed' AND sl.started_at >= CURRENT_TIMESTAMP - INTERVAL '24 hours') as failed_syncs_24h,
                    COUNT(*) FILTER (WHERE el.export_status = 'failed' AND el.started_at >= CURRENT_TIMESTAMP - INTERVAL '24 hours') as failed_exports_24h
                FROM sync_logs sl
                FULL OUTER JOIN export_logs el ON sl.store_id = el.store_id
                WHERE (store_id_param IS NULL OR COALESCE(sl.store_id, el.store_id) = store_id_param)
            ) health_calc
        ),
        'sync_health', (
            SELECT jsonb_build_object(
                'total_syncs_24h', COUNT(*),
                'successful_syncs_24h', COUNT(*) FILTER (WHERE sync_status = 'completed'),
                'failed_syncs_24h', COUNT(*) FILTER (WHERE sync_status = 'failed'),
                'running_syncs', COUNT(*) FILTER (WHERE sync_status = 'running'),
                'avg_duration_minutes', AVG(duration_seconds / 60.0) FILTER (WHERE duration_seconds IS NOT NULL),
                'avg_data_quality', AVG(data_quality_score) FILTER (WHERE data_quality_score IS NOT NULL)
            )
            FROM sync_logs
            WHERE (store_id_param IS NULL OR store_id = store_id_param)
                AND started_at >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
        ),
        'user_health', (
            SELECT jsonb_build_object(
                'total_active_users', COUNT(*) FILTER (WHERE account_status = 'active'),
                'users_with_failed_logins', COUNT(*) FILTER (WHERE failed_login_attempts > 0),
                'unverified_users', COUNT(*) FILTER (WHERE email_verified = FALSE),
                'users_without_2fa', COUNT(*) FILTER (WHERE two_factor_enabled = FALSE AND account_status = 'active'),
                'recent_activity_users', COUNT(*) FILTER (WHERE last_activity_at >= CURRENT_TIMESTAMP - INTERVAL '24 hours')
            )
            FROM user_info
            WHERE (store_id_param IS NULL OR store_id = store_id_param)
        ),
        'export_health', (
            SELECT jsonb_build_object(
                'total_exports_24h', COUNT(*),
                'successful_exports_24h', COUNT(*) FILTER (WHERE export_status = 'completed'),
                'failed_exports_24h', COUNT(*) FILTER (WHERE export_status = 'failed'),
                'avg_processing_time_minutes', AVG(processing_time_seconds / 60.0) FILTER (WHERE processing_time_seconds IS NOT NULL)
            )
            FROM export_logs
            WHERE (store_id_param IS NULL OR store_id = store_id_param)
                AND started_at >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
        ),
        'recommendations', (
            -- Generate recommendations based on health metrics
            SELECT jsonb_agg(recommendation)
            FROM (
                SELECT 'Enable two-factor authentication for more users' as recommendation
                WHERE (
                    SELECT COUNT(*) FILTER (WHERE two_factor_enabled = FALSE AND account_status = 'active')
                    FROM user_info
                    WHERE (store_id_param IS NULL OR store_id = store_id_param)
                ) > 0
                
                UNION ALL
                
                SELECT 'Investigate recent sync failures' as recommendation
                WHERE (
                    SELECT COUNT(*) FILTER (WHERE sync_status = 'failed')
                    FROM sync_logs
                    WHERE (store_id_param IS NULL OR store_id = store_id_param)
                        AND started_at >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
                ) > 5
                
                UNION ALL
                
                SELECT 'Review export performance' as recommendation
                WHERE (
                    SELECT AVG(processing_time_seconds)
                    FROM export_logs
                    WHERE (store_id_param IS NULL OR store_id = store_id_param)
                        AND started_at >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
                        AND processing_time_seconds IS NOT NULL
                ) > 300 -- More than 5 minutes
            ) recommendations
        ),
        'generated_at', CURRENT_TIMESTAMP
    ) INTO result;
    
    RETURN COALESCE(result, '{"error": "No data found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

\echo 'System helper functions created successfully!'
\echo ''

-- =====================================================
-- Final Success Message
-- =====================================================

\echo '================================================'
\echo 'System and Settings Tables Setup Complete!'
\echo '================================================'
\echo ''
\echo 'Created tables:'
\echo '  1. Settings Table (settings)'
\echo '  2. Export Logs Table (export_logs)'
\echo '  3. Store Info Table (store_info)'
\echo '  4. User Info Table (user_info)'
\echo '  5. Sync Logs Table (sync_logs)'
\echo ''
\echo 'Created views:'
\echo '  - system_overview'
\echo '  - sync_performance_summary'
\echo '  - user_activity_summary'
\echo '  - export_analytics_summary'
\echo ''
\echo 'Created functions:'
\echo '  - get_system_dashboard()'
\echo '  - generate_system_health_report()'
\echo ''
\echo 'All system and settings tables are ready for use!'
\echo ''