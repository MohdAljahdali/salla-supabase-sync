-- =====================================================
-- Sync Logs Table
-- =====================================================
-- This table tracks all synchronization operations between
-- Salla API and Supabase database for monitoring and debugging

CREATE TABLE IF NOT EXISTS sync_logs (
    -- Primary identification
    id BIGSERIAL PRIMARY KEY,
    
    -- Store relationship (required)
    store_id BIGINT NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Sync operation identification
    sync_id UUID DEFAULT gen_random_uuid(),
    batch_id UUID, -- For grouping related sync operations
    parent_sync_id BIGINT REFERENCES sync_logs(id), -- For nested/dependent syncs
    
    -- Sync operation details
    operation_type VARCHAR(100) NOT NULL, -- full_sync, incremental_sync, real_time_sync, manual_sync
    sync_direction VARCHAR(50) NOT NULL, -- salla_to_supabase, supabase_to_salla, bidirectional
    entity_type VARCHAR(100) NOT NULL, -- products, orders, customers, categories, etc.
    entity_id VARCHAR(255), -- ID of the specific entity being synced
    
    -- API and endpoint information
    api_endpoint VARCHAR(500),
    api_method VARCHAR(10), -- GET, POST, PUT, DELETE, PATCH
    api_version VARCHAR(20),
    webhook_event VARCHAR(100), -- For webhook-triggered syncs
    
    -- Sync status and progress
    sync_status VARCHAR(50) NOT NULL DEFAULT 'pending', -- pending, running, completed, failed, cancelled, retrying
    progress_percentage DECIMAL(5,2) DEFAULT 0.00, -- 0.00 to 100.00
    current_step VARCHAR(255),
    total_steps INTEGER,
    completed_steps INTEGER DEFAULT 0,
    
    -- Timing information
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    duration_seconds INTEGER, -- Calculated duration
    timeout_seconds INTEGER DEFAULT 300, -- Sync timeout
    
    -- Data metrics
    records_to_sync INTEGER DEFAULT 0,
    records_processed INTEGER DEFAULT 0,
    records_created INTEGER DEFAULT 0,
    records_updated INTEGER DEFAULT 0,
    records_deleted INTEGER DEFAULT 0,
    records_skipped INTEGER DEFAULT 0,
    records_failed INTEGER DEFAULT 0,
    
    -- Data size and performance
    data_size_bytes BIGINT DEFAULT 0,
    request_size_bytes BIGINT DEFAULT 0,
    response_size_bytes BIGINT DEFAULT 0,
    processing_time_ms INTEGER DEFAULT 0,
    network_time_ms INTEGER DEFAULT 0,
    
    -- Error handling and debugging
    error_count INTEGER DEFAULT 0,
    warning_count INTEGER DEFAULT 0,
    last_error_message TEXT,
    error_details JSONB,
    stack_trace TEXT,
    
    -- Retry mechanism
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    retry_delay_seconds INTEGER DEFAULT 60,
    next_retry_at TIMESTAMP WITH TIME ZONE,
    
    -- Request and response data
    request_headers JSONB,
    request_body JSONB,
    response_headers JSONB,
    response_body JSONB,
    response_status_code INTEGER,
    
    -- Rate limiting and throttling
    rate_limit_remaining INTEGER,
    rate_limit_reset_at TIMESTAMP WITH TIME ZONE,
    throttle_delay_ms INTEGER DEFAULT 0,
    
    -- Sync configuration
    sync_config JSONB, -- Configuration used for this sync
    filters_applied JSONB, -- Any filters applied during sync
    mapping_rules JSONB, -- Data mapping rules used
    transformation_rules JSONB, -- Data transformation rules
    
    -- Data validation and quality
    validation_errors JSONB,
    data_quality_score DECIMAL(5,2), -- 0.00 to 100.00
    schema_version VARCHAR(50),
    data_integrity_check BOOLEAN DEFAULT FALSE,
    
    -- Conflict resolution
    conflicts_detected INTEGER DEFAULT 0,
    conflicts_resolved INTEGER DEFAULT 0,
    conflict_resolution_strategy VARCHAR(100), -- last_write_wins, manual_review, custom_rules
    conflict_details JSONB,
    
    -- Synchronization metadata
    source_last_modified TIMESTAMP WITH TIME ZONE,
    target_last_modified TIMESTAMP WITH TIME ZONE,
    sync_checksum VARCHAR(255), -- For data integrity verification
    incremental_token VARCHAR(500), -- For incremental syncs
    
    -- Performance metrics
    cpu_usage_percent DECIMAL(5,2),
    memory_usage_mb INTEGER,
    disk_io_mb INTEGER,
    network_io_mb INTEGER,
    database_queries_count INTEGER DEFAULT 0,
    
    -- Business impact metrics
    business_impact_score INTEGER DEFAULT 0, -- 0-100
    critical_data_affected BOOLEAN DEFAULT FALSE,
    customer_facing_impact BOOLEAN DEFAULT FALSE,
    revenue_impact_amount DECIMAL(15,2),
    
    -- Monitoring and alerting
    alert_level VARCHAR(20) DEFAULT 'info', -- debug, info, warning, error, critical
    notification_sent BOOLEAN DEFAULT FALSE,
    escalation_level INTEGER DEFAULT 0, -- 0-5
    monitoring_tags TEXT[],
    
    -- Compliance and audit
    compliance_requirements TEXT[],
    audit_trail JSONB,
    data_classification VARCHAR(50), -- public, internal, confidential, restricted
    retention_period_days INTEGER DEFAULT 90,
    
    -- Integration context
    integration_version VARCHAR(50),
    client_version VARCHAR(50),
    user_agent VARCHAR(500),
    client_ip INET,
    session_id VARCHAR(255),
    
    -- Scheduling and automation
    scheduled_sync BOOLEAN DEFAULT FALSE,
    schedule_id BIGINT,
    trigger_type VARCHAR(100), -- manual, scheduled, webhook, api, event
    trigger_source VARCHAR(255),
    
    -- Dependencies and relationships
    depends_on_sync_ids BIGINT[],
    blocks_sync_ids BIGINT[],
    related_entity_ids TEXT[],
    affected_tables TEXT[],
    
    -- Rollback and recovery
    rollback_available BOOLEAN DEFAULT FALSE,
    rollback_data JSONB,
    recovery_point VARCHAR(255),
    backup_reference VARCHAR(255),
    
    -- Testing and debugging
    test_mode BOOLEAN DEFAULT FALSE,
    debug_mode BOOLEAN DEFAULT FALSE,
    debug_info JSONB,
    test_scenario VARCHAR(255),
    
    -- Environment and deployment
    environment VARCHAR(50) DEFAULT 'production', -- development, staging, production
    deployment_version VARCHAR(100),
    feature_flags TEXT[],
    configuration_hash VARCHAR(255),
    
    -- Resource utilization
    worker_id VARCHAR(100),
    queue_name VARCHAR(100),
    priority_level INTEGER DEFAULT 5, -- 1-10 (1 = highest priority)
    resource_pool VARCHAR(100),
    
    -- Data lineage and traceability
    data_source VARCHAR(255),
    data_destination VARCHAR(255),
    transformation_pipeline TEXT[],
    data_lineage JSONB,
    
    -- Security and access
    access_token_hash VARCHAR(255),
    permission_level VARCHAR(50),
    security_context JSONB,
    encryption_used BOOLEAN DEFAULT FALSE,
    
    -- Custom fields for extensibility
    custom_metrics JSONB,
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
CREATE INDEX IF NOT EXISTS idx_sync_logs_store_id 
    ON sync_logs(store_id);

CREATE UNIQUE INDEX IF NOT EXISTS idx_sync_logs_sync_id 
    ON sync_logs(sync_id);

CREATE INDEX IF NOT EXISTS idx_sync_logs_batch_id 
    ON sync_logs(batch_id)
    WHERE batch_id IS NOT NULL;

-- Status and operation indexes
CREATE INDEX IF NOT EXISTS idx_sync_logs_status 
    ON sync_logs(store_id, sync_status, operation_type);

CREATE INDEX IF NOT EXISTS idx_sync_logs_entity 
    ON sync_logs(store_id, entity_type, entity_id)
    WHERE entity_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_sync_logs_direction 
    ON sync_logs(store_id, sync_direction, entity_type);

-- Timing and performance indexes
CREATE INDEX IF NOT EXISTS idx_sync_logs_started_at 
    ON sync_logs(store_id, started_at DESC)
    WHERE started_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_sync_logs_completed_at 
    ON sync_logs(store_id, completed_at DESC)
    WHERE completed_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_sync_logs_duration 
    ON sync_logs(store_id, duration_seconds)
    WHERE duration_seconds IS NOT NULL;

-- Error and retry indexes
CREATE INDEX IF NOT EXISTS idx_sync_logs_errors 
    ON sync_logs(store_id, error_count, sync_status)
    WHERE error_count > 0;

CREATE INDEX IF NOT EXISTS idx_sync_logs_retries 
    ON sync_logs(store_id, retry_count, next_retry_at)
    WHERE retry_count > 0;

CREATE INDEX IF NOT EXISTS idx_sync_logs_failed 
    ON sync_logs(store_id, sync_status, last_error_message)
    WHERE sync_status = 'failed';

-- Progress and metrics indexes
CREATE INDEX IF NOT EXISTS idx_sync_logs_progress 
    ON sync_logs(store_id, progress_percentage, sync_status)
    WHERE progress_percentage > 0;

CREATE INDEX IF NOT EXISTS idx_sync_logs_records 
    ON sync_logs(store_id, records_processed, records_to_sync);

-- API and webhook indexes
CREATE INDEX IF NOT EXISTS idx_sync_logs_api_endpoint 
    ON sync_logs(store_id, api_endpoint, api_method)
    WHERE api_endpoint IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_sync_logs_webhook 
    ON sync_logs(store_id, webhook_event, trigger_type)
    WHERE webhook_event IS NOT NULL;

-- Business impact indexes
CREATE INDEX IF NOT EXISTS idx_sync_logs_business_impact 
    ON sync_logs(store_id, business_impact_score, critical_data_affected)
    WHERE business_impact_score > 0;

CREATE INDEX IF NOT EXISTS idx_sync_logs_customer_impact 
    ON sync_logs(store_id, customer_facing_impact, alert_level)
    WHERE customer_facing_impact = TRUE;

-- Scheduling and automation indexes
CREATE INDEX IF NOT EXISTS idx_sync_logs_scheduled 
    ON sync_logs(store_id, scheduled_sync, schedule_id)
    WHERE scheduled_sync = TRUE;

CREATE INDEX IF NOT EXISTS idx_sync_logs_trigger 
    ON sync_logs(store_id, trigger_type, trigger_source);

-- Environment and testing indexes
CREATE INDEX IF NOT EXISTS idx_sync_logs_environment 
    ON sync_logs(store_id, environment, test_mode);

CREATE INDEX IF NOT EXISTS idx_sync_logs_debug 
    ON sync_logs(store_id, debug_mode, test_scenario)
    WHERE debug_mode = TRUE;

-- Time-based indexes
CREATE INDEX IF NOT EXISTS idx_sync_logs_created_at 
    ON sync_logs(store_id, created_at);

CREATE INDEX IF NOT EXISTS idx_sync_logs_updated_at 
    ON sync_logs(store_id, updated_at);

-- JSON indexes for flexible querying
CREATE INDEX IF NOT EXISTS idx_sync_logs_error_details 
    ON sync_logs USING GIN(error_details)
    WHERE error_details IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_sync_logs_sync_config 
    ON sync_logs USING GIN(sync_config)
    WHERE sync_config IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_sync_logs_tags 
    ON sync_logs USING GIN(tags)
    WHERE tags IS NOT NULL;

-- =====================================================
-- Unique Constraints
-- =====================================================

-- Ensure unique sync IDs
CREATE UNIQUE INDEX IF NOT EXISTS idx_sync_logs_sync_id_unique 
    ON sync_logs(sync_id);

-- =====================================================
-- Triggers
-- =====================================================

-- Updated at trigger
CREATE OR REPLACE FUNCTION update_sync_logs_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_sync_logs_updated_at
    BEFORE UPDATE ON sync_logs
    FOR EACH ROW
    EXECUTE FUNCTION update_sync_logs_updated_at();

-- Sync timing and metrics calculation trigger
CREATE OR REPLACE FUNCTION calculate_sync_metrics()
RETURNS TRIGGER AS $$
BEGIN
    -- Calculate duration when sync is completed
    IF OLD.sync_status != 'completed' AND NEW.sync_status = 'completed' THEN
        IF NEW.started_at IS NOT NULL THEN
            NEW.completed_at = CURRENT_TIMESTAMP;
            NEW.duration_seconds = EXTRACT(EPOCH FROM (NEW.completed_at - NEW.started_at))::INTEGER;
        END IF;
        
        -- Calculate progress percentage
        IF NEW.records_to_sync > 0 THEN
            NEW.progress_percentage = (NEW.records_processed::DECIMAL / NEW.records_to_sync::DECIMAL) * 100;
        ELSE
            NEW.progress_percentage = 100.00;
        END IF;
    END IF;
    
    -- Calculate data quality score
    IF NEW.records_processed > 0 THEN
        DECLARE
            success_rate DECIMAL;
            error_rate DECIMAL;
        BEGIN
            success_rate := ((NEW.records_created + NEW.records_updated)::DECIMAL / NEW.records_processed::DECIMAL) * 100;
            error_rate := (NEW.records_failed::DECIMAL / NEW.records_processed::DECIMAL) * 100;
            
            NEW.data_quality_score := GREATEST(0, success_rate - (error_rate * 2));
        END;
    END IF;
    
    -- Set business impact score based on various factors
    DECLARE
        impact_score INTEGER := 0;
    BEGIN
        -- High volume operations have higher impact
        IF NEW.records_processed > 10000 THEN impact_score := impact_score + 30;
        ELSIF NEW.records_processed > 1000 THEN impact_score := impact_score + 20;
        ELSIF NEW.records_processed > 100 THEN impact_score := impact_score + 10;
        END IF;
        
        -- Critical entity types have higher impact
        IF NEW.entity_type IN ('orders', 'customers', 'products') THEN
            impact_score := impact_score + 25;
        END IF;
        
        -- Errors increase impact
        IF NEW.error_count > 0 THEN
            impact_score := impact_score + (NEW.error_count * 5);
        END IF;
        
        -- Customer-facing operations have higher impact
        IF NEW.customer_facing_impact THEN
            impact_score := impact_score + 20;
        END IF;
        
        NEW.business_impact_score := LEAST(100, impact_score);
    END;
    
    -- Set alert level based on status and errors
    IF NEW.sync_status = 'failed' THEN
        NEW.alert_level = 'error';
    ELSIF NEW.error_count > 0 THEN
        NEW.alert_level = 'warning';
    ELSIF NEW.sync_status = 'completed' THEN
        NEW.alert_level = 'info';
    END IF;
    
    -- Update retry timing
    IF OLD.retry_count != NEW.retry_count AND NEW.retry_count < NEW.max_retries THEN
        NEW.next_retry_at = CURRENT_TIMESTAMP + (NEW.retry_delay_seconds * INTERVAL '1 second');
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_sync_metrics
    BEFORE UPDATE ON sync_logs
    FOR EACH ROW
    EXECUTE FUNCTION calculate_sync_metrics();

-- Sync status change notification trigger
CREATE OR REPLACE FUNCTION notify_sync_status_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Send notifications for important status changes
    IF OLD.sync_status IS DISTINCT FROM NEW.sync_status THEN
        -- Log status change in metadata
        NEW.metadata = COALESCE(NEW.metadata, '{}'::jsonb) || 
                      jsonb_build_object(
                          'status_changed_at', CURRENT_TIMESTAMP,
                          'previous_status', OLD.sync_status,
                          'new_status', NEW.sync_status
                      );
        
        -- Mark for notification if it's a critical status
        IF NEW.sync_status IN ('failed', 'completed') OR NEW.alert_level IN ('error', 'critical') THEN
            NEW.notification_sent = FALSE; -- Will be processed by notification system
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_sync_status_notification
    BEFORE UPDATE ON sync_logs
    FOR EACH ROW
    EXECUTE FUNCTION notify_sync_status_change();

-- =====================================================
-- Helper Functions
-- =====================================================

-- Function to start a new sync operation
CREATE OR REPLACE FUNCTION start_sync_operation(
    store_id_param BIGINT,
    operation_type_param VARCHAR,
    sync_direction_param VARCHAR,
    entity_type_param VARCHAR,
    entity_id_param VARCHAR DEFAULT NULL,
    sync_config_param JSONB DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    new_sync_id UUID;
BEGIN
    INSERT INTO sync_logs (
        store_id,
        operation_type,
        sync_direction,
        entity_type,
        entity_id,
        sync_config,
        sync_status,
        started_at
    ) VALUES (
        store_id_param,
        operation_type_param,
        sync_direction_param,
        entity_type_param,
        entity_id_param,
        sync_config_param,
        'running',
        CURRENT_TIMESTAMP
    ) RETURNING sync_id INTO new_sync_id;
    
    RETURN new_sync_id;
END;
$$ LANGUAGE plpgsql;

-- Function to update sync progress
CREATE OR REPLACE FUNCTION update_sync_progress(
    sync_id_param UUID,
    records_processed_param INTEGER DEFAULT NULL,
    current_step_param VARCHAR DEFAULT NULL,
    error_message_param TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    success BOOLEAN := FALSE;
BEGIN
    UPDATE sync_logs
    SET records_processed = COALESCE(records_processed_param, records_processed),
        current_step = COALESCE(current_step_param, current_step),
        last_error_message = CASE 
            WHEN error_message_param IS NOT NULL THEN error_message_param
            ELSE last_error_message
        END,
        error_count = CASE 
            WHEN error_message_param IS NOT NULL THEN error_count + 1
            ELSE error_count
        END,
        updated_at = CURRENT_TIMESTAMP
    WHERE sync_id = sync_id_param
    RETURNING TRUE INTO success;
    
    RETURN COALESCE(success, FALSE);
END;
$$ LANGUAGE plpgsql;

-- Function to complete sync operation
CREATE OR REPLACE FUNCTION complete_sync_operation(
    sync_id_param UUID,
    final_status VARCHAR DEFAULT 'completed',
    records_created_param INTEGER DEFAULT 0,
    records_updated_param INTEGER DEFAULT 0,
    records_deleted_param INTEGER DEFAULT 0,
    records_failed_param INTEGER DEFAULT 0
)
RETURNS BOOLEAN AS $$
DECLARE
    success BOOLEAN := FALSE;
BEGIN
    UPDATE sync_logs
    SET sync_status = final_status,
        completed_at = CURRENT_TIMESTAMP,
        records_created = records_created_param,
        records_updated = records_updated_param,
        records_deleted = records_deleted_param,
        records_failed = records_failed_param,
        progress_percentage = CASE 
            WHEN final_status = 'completed' THEN 100.00
            ELSE progress_percentage
        END,
        updated_at = CURRENT_TIMESTAMP
    WHERE sync_id = sync_id_param
    RETURNING TRUE INTO success;
    
    RETURN COALESCE(success, FALSE);
END;
$$ LANGUAGE plpgsql;

-- Function to get sync statistics
CREATE OR REPLACE FUNCTION get_sync_stats(
    store_id_param BIGINT DEFAULT NULL,
    days_back INTEGER DEFAULT 7
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_syncs', COUNT(*),
        'successful_syncs', COUNT(*) FILTER (WHERE sync_status = 'completed'),
        'failed_syncs', COUNT(*) FILTER (WHERE sync_status = 'failed'),
        'running_syncs', COUNT(*) FILTER (WHERE sync_status = 'running'),
        'pending_syncs', COUNT(*) FILTER (WHERE sync_status = 'pending'),
        'average_duration_seconds', AVG(duration_seconds) FILTER (WHERE duration_seconds IS NOT NULL),
        'total_records_processed', SUM(records_processed),
        'total_records_created', SUM(records_created),
        'total_records_updated', SUM(records_updated),
        'total_records_failed', SUM(records_failed),
        'average_data_quality_score', AVG(data_quality_score) FILTER (WHERE data_quality_score IS NOT NULL),
        'entity_type_distribution', (
            SELECT jsonb_object_agg(entity_type, entity_count)
            FROM (
                SELECT entity_type, COUNT(*) as entity_count
                FROM sync_logs
                WHERE (store_id_param IS NULL OR store_id = store_id_param)
                    AND created_at >= CURRENT_TIMESTAMP - (days_back || ' days')::INTERVAL
                GROUP BY entity_type
            ) entity_stats
        ),
        'operation_type_distribution', (
            SELECT jsonb_object_agg(operation_type, operation_count)
            FROM (
                SELECT operation_type, COUNT(*) as operation_count
                FROM sync_logs
                WHERE (store_id_param IS NULL OR store_id = store_id_param)
                    AND created_at >= CURRENT_TIMESTAMP - (days_back || ' days')::INTERVAL
                GROUP BY operation_type
            ) operation_stats
        ),
        'error_summary', (
            SELECT jsonb_object_agg(error_type, error_count)
            FROM (
                SELECT 
                    COALESCE(last_error_message, 'Unknown Error') as error_type,
                    COUNT(*) as error_count
                FROM sync_logs
                WHERE (store_id_param IS NULL OR store_id = store_id_param)
                    AND created_at >= CURRENT_TIMESTAMP - (days_back || ' days')::INTERVAL
                    AND sync_status = 'failed'
                GROUP BY last_error_message
                ORDER BY error_count DESC
                LIMIT 10
            ) error_stats
        ),
        'last_updated', MAX(updated_at)
    ) INTO result
    FROM sync_logs
    WHERE (store_id_param IS NULL OR store_id = store_id_param)
        AND created_at >= CURRENT_TIMESTAMP - (days_back || ' days')::INTERVAL;
    
    RETURN COALESCE(result, '{"error": "No sync logs found"}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- Function to search sync logs
CREATE OR REPLACE FUNCTION search_sync_logs(
    store_id_param BIGINT,
    entity_type_filter VARCHAR DEFAULT NULL,
    status_filter VARCHAR DEFAULT NULL,
    operation_filter VARCHAR DEFAULT NULL,
    date_from TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    date_to TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    limit_param INTEGER DEFAULT 100
)
RETURNS TABLE (
    sync_id UUID,
    operation_type VARCHAR,
    entity_type VARCHAR,
    sync_status VARCHAR,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    duration_seconds INTEGER,
    records_processed INTEGER,
    error_count INTEGER,
    progress_percentage DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        sl.sync_id,
        sl.operation_type,
        sl.entity_type,
        sl.sync_status,
        sl.started_at,
        sl.completed_at,
        sl.duration_seconds,
        sl.records_processed,
        sl.error_count,
        sl.progress_percentage
    FROM sync_logs sl
    WHERE sl.store_id = store_id_param
        AND (entity_type_filter IS NULL OR sl.entity_type = entity_type_filter)
        AND (status_filter IS NULL OR sl.sync_status = status_filter)
        AND (operation_filter IS NULL OR sl.operation_type = operation_filter)
        AND (date_from IS NULL OR sl.created_at >= date_from)
        AND (date_to IS NULL OR sl.created_at <= date_to)
    ORDER BY sl.created_at DESC
    LIMIT limit_param;
END;
$$ LANGUAGE plpgsql;

-- Function to get sync details
CREATE OR REPLACE FUNCTION get_sync_details(
    sync_id_param UUID
)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'sync_info', jsonb_build_object(
            'sync_id', sync_id,
            'operation_type', operation_type,
            'sync_direction', sync_direction,
            'entity_type', entity_type,
            'entity_id', entity_id,
            'sync_status', sync_status
        ),
        'timing', jsonb_build_object(
            'started_at', started_at,
            'completed_at', completed_at,
            'duration_seconds', duration_seconds,
            'processing_time_ms', processing_time_ms
        ),
        'metrics', jsonb_build_object(
            'records_to_sync', records_to_sync,
            'records_processed', records_processed,
            'records_created', records_created,
            'records_updated', records_updated,
            'records_deleted', records_deleted,
            'records_failed', records_failed,
            'progress_percentage', progress_percentage,
            'data_quality_score', data_quality_score
        ),
        'errors', jsonb_build_object(
            'error_count', error_count,
            'warning_count', warning_count,
            'last_error_message', last_error_message,
            'retry_count', retry_count,
            'next_retry_at', next_retry_at
        ),
        'api_info', jsonb_build_object(
            'api_endpoint', api_endpoint,
            'api_method', api_method,
            'response_status_code', response_status_code,
            'webhook_event', webhook_event
        ),
        'business_impact', jsonb_build_object(
            'business_impact_score', business_impact_score,
            'critical_data_affected', critical_data_affected,
            'customer_facing_impact', customer_facing_impact,
            'alert_level', alert_level
        )
    ) INTO result
    FROM sync_logs
    WHERE sync_id = sync_id_param;
    
    IF result IS NULL THEN
        RETURN '{"error": "Sync log not found"}'::jsonb;
    END IF;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to retry failed sync
CREATE OR REPLACE FUNCTION retry_failed_sync(
    sync_id_param UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    success BOOLEAN := FALSE;
    current_retry_count INTEGER;
    max_retry_count INTEGER;
BEGIN
    -- Get current retry information
    SELECT retry_count, max_retries
    INTO current_retry_count, max_retry_count
    FROM sync_logs
    WHERE sync_id = sync_id_param AND sync_status = 'failed';
    
    -- Check if retries are available
    IF current_retry_count < max_retry_count THEN
        UPDATE sync_logs
        SET sync_status = 'pending',
            retry_count = retry_count + 1,
            last_error_message = NULL,
            started_at = NULL,
            completed_at = NULL,
            updated_at = CURRENT_TIMESTAMP
        WHERE sync_id = sync_id_param
        RETURNING TRUE INTO success;
    END IF;
    
    RETURN COALESCE(success, FALSE);
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Comments for Documentation
-- =====================================================

COMMENT ON TABLE sync_logs IS 'Comprehensive tracking of all synchronization operations between Salla API and Supabase';
COMMENT ON COLUMN sync_logs.sync_id IS 'Unique identifier for the sync operation';
COMMENT ON COLUMN sync_logs.operation_type IS 'Type of sync operation (full_sync, incremental_sync, etc.)';
COMMENT ON COLUMN sync_logs.sync_direction IS 'Direction of data synchronization';
COMMENT ON COLUMN sync_logs.entity_type IS 'Type of entity being synchronized';
COMMENT ON COLUMN sync_logs.sync_status IS 'Current status of the sync operation';
COMMENT ON COLUMN sync_logs.progress_percentage IS 'Completion percentage of the sync operation';
COMMENT ON COLUMN sync_logs.business_impact_score IS 'Score representing business impact of the sync (0-100)';
COMMENT ON COLUMN sync_logs.data_quality_score IS 'Score representing data quality of the sync (0-100)';
COMMENT ON COLUMN sync_logs.retry_count IS 'Number of retry attempts for failed syncs';

COMMENT ON FUNCTION start_sync_operation(BIGINT, VARCHAR, VARCHAR, VARCHAR, VARCHAR, JSONB) IS 'Start a new sync operation and return sync ID';
COMMENT ON FUNCTION update_sync_progress(UUID, INTEGER, VARCHAR, TEXT) IS 'Update progress of an ongoing sync operation';
COMMENT ON FUNCTION complete_sync_operation(UUID, VARCHAR, INTEGER, INTEGER, INTEGER, INTEGER) IS 'Mark sync operation as completed with final metrics';
COMMENT ON FUNCTION get_sync_stats(BIGINT, INTEGER) IS 'Get comprehensive sync statistics for a store';
COMMENT ON FUNCTION search_sync_logs(BIGINT, VARCHAR, VARCHAR, VARCHAR, TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE, INTEGER) IS 'Search sync logs with advanced filtering';
COMMENT ON FUNCTION get_sync_details(UUID) IS 'Get detailed information about a specific sync operation';
COMMENT ON FUNCTION retry_failed_sync(UUID) IS 'Retry a failed sync operation if retries are available';