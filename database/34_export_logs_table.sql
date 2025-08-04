-- =====================================================
-- Export Logs Table
-- =====================================================
-- This table tracks all data export operations and their status
-- for comprehensive export management and monitoring

CREATE TABLE IF NOT EXISTS export_logs (
    -- Primary identification
    id BIGSERIAL PRIMARY KEY,
    
    -- Store relationship (required)
    store_id BIGINT NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Export identification
    export_id UUID NOT NULL DEFAULT gen_random_uuid(),
    export_name VARCHAR(255) NOT NULL,
    export_type VARCHAR(100) NOT NULL, -- products, orders, customers, inventory, etc.
    export_format VARCHAR(50) NOT NULL DEFAULT 'csv', -- csv, xlsx, json, xml, pdf
    
    -- Export request details
    requested_by_user_id BIGINT,
    request_source VARCHAR(100) DEFAULT 'admin_panel', -- admin_panel, api, scheduled, webhook
    request_ip_address INET,
    user_agent TEXT,
    
    -- Export parameters
    export_filters JSONB, -- Filters applied to the export
    export_columns TEXT[], -- Specific columns to export
    date_range_start TIMESTAMP WITH TIME ZONE,
    date_range_end TIMESTAMP WITH TIME ZONE,
    include_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- Export status and progress
    status VARCHAR(50) NOT NULL DEFAULT 'pending', -- pending, processing, completed, failed, cancelled
    progress_percentage INTEGER DEFAULT 0 CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
    current_step VARCHAR(255),
    total_steps INTEGER,
    completed_steps INTEGER DEFAULT 0,
    
    -- Data metrics
    total_records INTEGER DEFAULT 0,
    processed_records INTEGER DEFAULT 0,
    exported_records INTEGER DEFAULT 0,
    failed_records INTEGER DEFAULT 0,
    skipped_records INTEGER DEFAULT 0,
    
    -- File information
    file_name VARCHAR(500),
    file_path VARCHAR(1000),
    file_size_bytes BIGINT,
    file_url VARCHAR(1000),
    download_url VARCHAR(1000),
    
    -- Compression and security
    is_compressed BOOLEAN NOT NULL DEFAULT FALSE,
    compression_type VARCHAR(20), -- zip, gzip, none
    is_encrypted BOOLEAN NOT NULL DEFAULT FALSE,
    encryption_method VARCHAR(50),
    password_protected BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- Timing information
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    duration_seconds INTEGER,
    estimated_completion_time TIMESTAMP WITH TIME ZONE,
    
    -- Error handling
    error_message TEXT,
    error_code VARCHAR(50),
    error_details JSONB,
    retry_count INTEGER NOT NULL DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    
    -- Performance metrics
    memory_usage_mb INTEGER,
    cpu_usage_percentage DECIMAL(5,2),
    processing_speed_records_per_second DECIMAL(10,2),
    peak_memory_usage_mb INTEGER,
    
    -- Quality and validation
    data_quality_score DECIMAL(3,2), -- 0.0 to 10.0
    validation_errors JSONB,
    data_integrity_check BOOLEAN NOT NULL DEFAULT FALSE,
    checksum VARCHAR(255),
    
    -- Access and download tracking
    download_count INTEGER NOT NULL DEFAULT 0,
    last_downloaded_at TIMESTAMP WITH TIME ZONE,
    downloaded_by_user_ids BIGINT[],
    access_permissions JSONB,
    
    -- Expiration and cleanup
    expires_at TIMESTAMP WITH TIME ZONE,
    auto_delete_after_days INTEGER DEFAULT 30,
    is_permanent BOOLEAN NOT NULL DEFAULT FALSE,
    cleanup_status VARCHAR(20) DEFAULT 'active', -- active, expired, deleted
    
    -- Scheduling and automation
    is_scheduled BOOLEAN NOT NULL DEFAULT FALSE,
    schedule_expression VARCHAR(100), -- Cron expression
    next_scheduled_run TIMESTAMP WITH TIME ZONE,
    schedule_timezone VARCHAR(50) DEFAULT 'UTC',
    
    -- Notification settings
    notify_on_completion BOOLEAN NOT NULL DEFAULT TRUE,
    notification_emails TEXT[],
    notification_webhooks TEXT[],
    notification_sent BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- Export template and reusability
    template_name VARCHAR(255),
    is_template BOOLEAN NOT NULL DEFAULT FALSE,
    template_description TEXT,
    reuse_count INTEGER NOT NULL DEFAULT 0,
    
    -- Data source and destination
    source_tables TEXT[],
    destination_type VARCHAR(100) DEFAULT 'local', -- local, s3, ftp, email, webhook
    destination_config JSONB,
    external_reference VARCHAR(255),
    
    -- Compliance and audit
    compliance_requirements TEXT[],
    audit_trail JSONB,
    data_classification VARCHAR(50) DEFAULT 'internal', -- public, internal, confidential, restricted
    retention_policy VARCHAR(100),
    
    -- Integration and sync
    sync_with_external BOOLEAN NOT NULL DEFAULT FALSE,
    external_system VARCHAR(100),
    external_export_id VARCHAR(255),
    sync_status VARCHAR(20) DEFAULT 'none', -- none, pending, synced, failed
    
    -- Monitoring and alerts
    has_alerts BOOLEAN NOT NULL DEFAULT FALSE,
    alert_conditions JSONB,
    last_alert_sent_at TIMESTAMP WITH TIME ZONE,
    monitoring_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    
    -- Business context
    business_purpose TEXT,
    department VARCHAR(100),
    cost_center VARCHAR(100),
    priority_level VARCHAR(20) DEFAULT 'normal', -- low, normal, high, critical
    
    -- Version and history
    export_version INTEGER NOT NULL DEFAULT 1,
    parent_export_id BIGINT REFERENCES export_logs(id),
    is_incremental BOOLEAN NOT NULL DEFAULT FALSE,
    baseline_export_id BIGINT,
    
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
CREATE INDEX IF NOT EXISTS idx_export_logs_store_id 
    ON export_logs(store_id, created_at DESC);

CREATE UNIQUE INDEX IF NOT EXISTS idx_export_logs_export_id 
    ON export_logs(export_id);

CREATE INDEX IF NOT EXISTS idx_export_logs_status 
    ON export_logs(store_id, status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_export_logs_type 
    ON export_logs(store_id, export_type, status);

-- User and request tracking indexes
CREATE INDEX IF NOT EXISTS idx_export_logs_user 
    ON export_logs(store_id, requested_by_user_id, created_at DESC)
    WHERE requested_by_user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_export_logs_source 
    ON export_logs(store_id, request_source, status);

-- Performance and monitoring indexes
CREATE INDEX IF NOT EXISTS idx_export_logs_processing 
    ON export_logs(store_id, status, started_at)
    WHERE status IN ('pending', 'processing');

CREATE INDEX IF NOT EXISTS idx_export_logs_failed 
    ON export_logs(store_id, status, error_code)
    WHERE status = 'failed';

CREATE INDEX IF NOT EXISTS idx_export_logs_duration 
    ON export_logs(store_id, duration_seconds, completed_at)
    WHERE duration_seconds IS NOT NULL;

-- File and download tracking indexes
CREATE INDEX IF NOT EXISTS idx_export_logs_file_path 
    ON export_logs(file_path)
    WHERE file_path IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_export_logs_downloads 
    ON export_logs(store_id, download_count, last_downloaded_at)
    WHERE download_count > 0;

-- Scheduling and automation indexes
CREATE INDEX IF NOT EXISTS idx_export_logs_scheduled 
    ON export_logs(store_id, is_scheduled, next_scheduled_run)
    WHERE is_scheduled = TRUE;

CREATE INDEX IF NOT EXISTS idx_export_logs_templates 
    ON export_logs(store_id, is_template, template_name)
    WHERE is_template = TRUE;

-- Expiration and cleanup indexes
CREATE INDEX IF NOT EXISTS idx_export_logs_expiration 
    ON export_logs(expires_at, cleanup_status)
    WHERE expires_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_export_logs_cleanup 
    ON export_logs(store_id, cleanup_status, created_at)
    WHERE cleanup_status != 'deleted';

-- Time-based indexes
CREATE INDEX IF NOT EXISTS idx_export_logs_date_range 
    ON export_logs(store_id, date_range_start, date_range_end)
    WHERE date_range_start IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_export_logs_completed_at 
    ON export_logs(store_id, completed_at DESC)
    WHERE completed_at IS NOT NULL;

-- Business and compliance indexes
CREATE INDEX IF NOT EXISTS idx_export_logs_priority 
    ON export_logs(store_id, priority_level, status)
    WHERE priority_level IN ('high', 'critical');

CREATE INDEX IF NOT EXISTS idx_export_logs_classification 
    ON export_logs(store_id, data_classification, created_at);

-- JSON indexes for flexible querying
CREATE INDEX IF NOT EXISTS idx_export_logs_filters 
    ON export_logs USING GIN(export_filters)
    WHERE export_filters IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_export_logs_custom_attributes 
    ON export_logs USING GIN(custom_attributes)
    WHERE custom_attributes IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_export_logs_tags 
    ON export_logs USING GIN(tags)
    WHERE tags IS NOT NULL;

-- =====================================================
-- Unique Constraints
-- =====================================================

-- Ensure unique export IDs
ALTER TABLE export_logs 
    ADD CONSTRAINT uk_export_logs_export_id 
    UNIQUE (export_id);

-- Ensure unique template names per store
CREATE UNIQUE INDEX IF NOT EXISTS idx_export_logs_template_name 
    ON export_logs(store_id, template_name)
    WHERE is_template = TRUE AND template_name IS NOT NULL;

-- =====================================================
-- Triggers
-- =====================================================

-- Updated at trigger
CREATE OR REPLACE FUNCTION update_export_logs_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_export_logs_updated_at
    BEFORE UPDATE ON export_logs
    FOR EACH ROW
    EXECUTE FUNCTION update_export_logs_updated_at();

-- Status and timing tracking trigger
CREATE OR REPLACE FUNCTION track_export_status_changes()
RETURNS TRIGGER AS $$
BEGIN
    -- Track status changes and timing
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        CASE NEW.status
            WHEN 'processing' THEN
                NEW.started_at = COALESCE(NEW.started_at, CURRENT_TIMESTAMP);
            WHEN 'completed' THEN
                NEW.completed_at = COALESCE(NEW.completed_at, CURRENT_TIMESTAMP);
                IF NEW.started_at IS NOT NULL THEN
                    NEW.duration_seconds = EXTRACT(EPOCH FROM (NEW.completed_at - NEW.started_at))::INTEGER;
                END IF;
            WHEN 'failed' THEN
                NEW.completed_at = COALESCE(NEW.completed_at, CURRENT_TIMESTAMP);
                IF NEW.started_at IS NOT NULL THEN
                    NEW.duration_seconds = EXTRACT(EPOCH FROM (NEW.completed_at - NEW.started_at))::INTEGER;
                END IF;
        END CASE;
    END IF;
    
    -- Update progress calculations
    IF NEW.total_records > 0 THEN
        NEW.progress_percentage = LEAST(100, (NEW.processed_records * 100 / NEW.total_records));
    END IF;
    
    -- Update processing speed
    IF NEW.duration_seconds > 0 AND NEW.processed_records > 0 THEN
        NEW.processing_speed_records_per_second = NEW.processed_records::DECIMAL / NEW.duration_seconds;
    END IF;
    
    -- Set expiration date if not set
    IF NEW.expires_at IS NULL AND NEW.auto_delete_after_days IS NOT NULL THEN
        NEW.expires_at = NEW.created_at + (NEW.auto_delete_after_days || ' days')::INTERVAL;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_export_status_changes
    BEFORE UPDATE ON export_logs
    FOR EACH ROW
    EXECUTE FUNCTION track_export_status_changes();

-- File information trigger
CREATE OR REPLACE FUNCTION update_export_file_info()
RETURNS TRIGGER AS $$
BEGIN
    -- Generate file name if not provided
    IF NEW.file_name IS NULL AND NEW.export_name IS NOT NULL THEN
        NEW.file_name = LOWER(REPLACE(NEW.export_name, ' ', '_')) || '_' || 
                       TO_CHAR(NEW.created_at, 'YYYY_MM_DD_HH24_MI_SS') || 
                       '.' || NEW.export_format;
    END IF;
    
    -- Generate download URL if file URL is provided
    IF NEW.file_url IS NOT NULL AND NEW.download_url IS NULL THEN
        NEW.download_url = NEW.file_url || '?download=true&token=' || NEW.export_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_export_file_info
    BEFORE INSERT OR UPDATE ON export_logs
    FOR EACH ROW
    EXECUTE FUNCTION update_export_file_info();

-- =====================================================
-- Helper Functions
-- =====================================================

-- Function to get export statistics
CREATE OR REPLACE FUNCTION get_export_stats(
    store_id_param BIGINT DEFAULT NULL,
    date_from TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    date_to TIMESTAMP WITH TIME ZONE DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_exports', COUNT(*),
        'completed_exports', COUNT(*) FILTER (WHERE status = 'completed'),
        'failed_exports', COUNT(*) FILTER (WHERE status = 'failed'),
        'pending_exports', COUNT(*) FILTER (WHERE status IN ('pending', 'processing')),
        'success_rate', CASE 
            WHEN COUNT(*) > 0 THEN 
                (COUNT(*) FILTER (WHERE status = 'completed')::DECIMAL / COUNT(*)) * 100
            ELSE 0
        END,
        'total_records_exported', COALESCE(SUM(exported_records), 0),
        'total_file_size_mb', COALESCE(SUM(file_size_bytes), 0) / 1024 / 1024,
        'average_duration_seconds', AVG(duration_seconds) FILTER (WHERE duration_seconds IS NOT NULL),
        'export_types', (
            SELECT jsonb_object_agg(export_type, type_count)
            FROM (
                SELECT export_type, COUNT(*) as type_count
                FROM export_logs
                WHERE (store_id_param IS NULL OR store_id = store_id_param)
                    AND (date_from IS NULL OR created_at >= date_from)
                    AND (date_to IS NULL OR created_at <= date_to)
                GROUP BY export_type
            ) type_stats
        ),
        'formats_distribution', (
            SELECT jsonb_object_agg(export_format, format_count)
            FROM (
                SELECT export_format, COUNT(*) as format_count
                FROM export_logs
                WHERE (store_id_param IS NULL OR store_id = store_id_param)
                    AND (date_from IS NULL OR created_at >= date_from)
                    AND (date_to IS NULL OR created_at <= date_to)
                GROUP BY export_format
            ) format_stats
        ),
        'last_export', MAX(created_at)
    ) INTO result
    FROM export_logs
    WHERE (store_id_param IS NULL OR store_id = store_id_param)
        AND (date_from IS NULL OR created_at >= date_from)
        AND (date_to IS NULL OR created_at <= date_to);
    
    RETURN COALESCE(result, '{"error": "No exports found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- Function to search export logs
CREATE OR REPLACE FUNCTION search_export_logs(
    store_id_param BIGINT,
    search_term VARCHAR DEFAULT NULL,
    status_filter VARCHAR DEFAULT NULL,
    type_filter VARCHAR DEFAULT NULL,
    user_filter BIGINT DEFAULT NULL,
    date_from TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    date_to TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    limit_param INTEGER DEFAULT 50
)
RETURNS TABLE (
    id BIGINT,
    export_id UUID,
    export_name VARCHAR,
    export_type VARCHAR,
    status VARCHAR,
    progress_percentage INTEGER,
    total_records INTEGER,
    exported_records INTEGER,
    file_size_mb DECIMAL,
    duration_seconds INTEGER,
    created_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        el.id,
        el.export_id,
        el.export_name,
        el.export_type,
        el.status,
        el.progress_percentage,
        el.total_records,
        el.exported_records,
        CASE WHEN el.file_size_bytes IS NOT NULL 
             THEN (el.file_size_bytes::DECIMAL / 1024 / 1024) 
             ELSE NULL END as file_size_mb,
        el.duration_seconds,
        el.created_at,
        el.completed_at
    FROM export_logs el
    WHERE el.store_id = store_id_param
        AND (
            search_term IS NULL 
            OR el.export_name ILIKE '%' || search_term || '%'
            OR el.export_type ILIKE '%' || search_term || '%'
            OR el.file_name ILIKE '%' || search_term || '%'
        )
        AND (status_filter IS NULL OR el.status = status_filter)
        AND (type_filter IS NULL OR el.export_type = type_filter)
        AND (user_filter IS NULL OR el.requested_by_user_id = user_filter)
        AND (date_from IS NULL OR el.created_at >= date_from)
        AND (date_to IS NULL OR el.created_at <= date_to)
    ORDER BY el.created_at DESC
    LIMIT limit_param;
END;
$$ LANGUAGE plpgsql;

-- Function to get export details
CREATE OR REPLACE FUNCTION get_export_details(
    export_id_param UUID
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT to_jsonb(el.*) INTO result
    FROM export_logs el
    WHERE el.export_id = export_id_param;
    
    IF result IS NULL THEN
        RETURN '{"error": "Export not found"}'::jsonb;
    END IF;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to update export progress
CREATE OR REPLACE FUNCTION update_export_progress(
    export_id_param UUID,
    processed_records_param INTEGER DEFAULT NULL,
    current_step_param VARCHAR DEFAULT NULL,
    error_message_param TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    success BOOLEAN := FALSE;
BEGIN
    UPDATE export_logs
    SET processed_records = COALESCE(processed_records_param, processed_records),
        current_step = COALESCE(current_step_param, current_step),
        error_message = COALESCE(error_message_param, error_message),
        updated_at = CURRENT_TIMESTAMP
    WHERE export_id = export_id_param
    RETURNING TRUE INTO success;
    
    RETURN COALESCE(success, FALSE);
END;
$$ LANGUAGE plpgsql;

-- Function to mark export as completed
CREATE OR REPLACE FUNCTION complete_export(
    export_id_param UUID,
    file_path_param VARCHAR DEFAULT NULL,
    file_size_param BIGINT DEFAULT NULL,
    exported_records_param INTEGER DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    success BOOLEAN := FALSE;
BEGIN
    UPDATE export_logs
    SET status = 'completed',
        file_path = COALESCE(file_path_param, file_path),
        file_size_bytes = COALESCE(file_size_param, file_size_bytes),
        exported_records = COALESCE(exported_records_param, exported_records),
        completed_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
    WHERE export_id = export_id_param
        AND status IN ('pending', 'processing')
    RETURNING TRUE INTO success;
    
    RETURN COALESCE(success, FALSE);
END;
$$ LANGUAGE plpgsql;

-- Function to mark export as failed
CREATE OR REPLACE FUNCTION fail_export(
    export_id_param UUID,
    error_message_param TEXT,
    error_code_param VARCHAR DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    success BOOLEAN := FALSE;
BEGIN
    UPDATE export_logs
    SET status = 'failed',
        error_message = error_message_param,
        error_code = error_code_param,
        completed_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
    WHERE export_id = export_id_param
        AND status IN ('pending', 'processing')
    RETURNING TRUE INTO success;
    
    RETURN COALESCE(success, FALSE);
END;
$$ LANGUAGE plpgsql;

-- Function to cleanup expired exports
CREATE OR REPLACE FUNCTION cleanup_expired_exports(
    store_id_param BIGINT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    deleted_count INTEGER := 0;
    result JSONB;
BEGIN
    UPDATE export_logs
    SET cleanup_status = 'deleted',
        updated_at = CURRENT_TIMESTAMP
    WHERE (store_id_param IS NULL OR store_id = store_id_param)
        AND expires_at < CURRENT_TIMESTAMP
        AND cleanup_status = 'active'
        AND is_permanent = FALSE;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    result := jsonb_build_object(
        'deleted_count', deleted_count,
        'cleanup_timestamp', CURRENT_TIMESTAMP
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Comments for Documentation
-- =====================================================

COMMENT ON TABLE export_logs IS 'Comprehensive tracking of all data export operations and their status';
COMMENT ON COLUMN export_logs.export_id IS 'Unique UUID identifier for the export operation';
COMMENT ON COLUMN export_logs.export_type IS 'Type of data being exported (products, orders, customers, etc.)';
COMMENT ON COLUMN export_logs.status IS 'Current status of the export operation';
COMMENT ON COLUMN export_logs.progress_percentage IS 'Completion percentage of the export process';
COMMENT ON COLUMN export_logs.file_path IS 'Local file system path where the export file is stored';
COMMENT ON COLUMN export_logs.download_url IS 'Secure URL for downloading the export file';
COMMENT ON COLUMN export_logs.expires_at IS 'When the export file will be automatically deleted';
COMMENT ON COLUMN export_logs.is_scheduled IS 'Whether this export runs on a schedule';
COMMENT ON COLUMN export_logs.data_classification IS 'Security classification of the exported data';

COMMENT ON FUNCTION get_export_stats(BIGINT, TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE) IS 'Get comprehensive statistics about export operations';
COMMENT ON FUNCTION search_export_logs(BIGINT, VARCHAR, VARCHAR, VARCHAR, BIGINT, TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE, INTEGER) IS 'Search export logs with advanced filtering options';
COMMENT ON FUNCTION get_export_details(UUID) IS 'Get complete details of a specific export operation';
COMMENT ON FUNCTION update_export_progress(UUID, INTEGER, VARCHAR, TEXT) IS 'Update progress information for an ongoing export';
COMMENT ON FUNCTION complete_export(UUID, VARCHAR, BIGINT, INTEGER) IS 'Mark an export as successfully completed';
COMMENT ON FUNCTION fail_export(UUID, TEXT, VARCHAR) IS 'Mark an export as failed with error details';
COMMENT ON FUNCTION cleanup_expired_exports(BIGINT) IS 'Clean up expired export files and logs';