-- =============================================================================
-- Run All Financial and Payment Tables
-- =============================================================================
-- This script creates all financial and payment related tables
-- Includes transactions, invoices, payment methods, and payment banks
-- Run this script to set up the complete financial system

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Include individual table creation scripts
\i 12_transactions_table.sql
\i 13_invoices_table.sql
\i 14_payment_methods_table.sql
\i 15_payment_banks_table.sql

-- =============================================================================
-- Additional Cross-Table Indexes
-- =============================================================================

-- Cross-table indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_transactions_invoice_cross ON transactions(order_id) 
    WHERE order_id IN (SELECT order_id FROM invoices);

CREATE INDEX IF NOT EXISTS idx_invoices_transactions_cross ON invoices(order_id) 
    WHERE order_id IN (SELECT order_id FROM transactions);

CREATE INDEX IF NOT EXISTS idx_transactions_payment_method_cross ON transactions(payment_method, transaction_status);

CREATE INDEX IF NOT EXISTS idx_payment_methods_usage_cross ON payment_methods(store_id, usage_count DESC);

-- =============================================================================
-- Financial Management Views
-- =============================================================================

-- View: Complete financial overview
CREATE OR REPLACE VIEW financial_overview AS
SELECT 
    s.id as store_id,
    s.name as store_name,
    
    -- Transaction summary
    COUNT(DISTINCT t.id) as total_transactions,
    COALESCE(SUM(CASE WHEN t.transaction_status = 'completed' THEN t.amount ELSE 0 END), 0) as completed_revenue,
    COALESCE(SUM(CASE WHEN t.transaction_status = 'pending' THEN t.amount ELSE 0 END), 0) as pending_revenue,
    COALESCE(SUM(CASE WHEN t.transaction_type IN ('refund', 'partial_refund') THEN t.amount ELSE 0 END), 0) as refunded_amount,
    COALESCE(SUM(t.gateway_fee + t.platform_fee), 0) as total_fees,
    
    -- Invoice summary
    COUNT(DISTINCT i.id) as total_invoices,
    COALESCE(SUM(i.total_amount), 0) as total_invoiced,
    COALESCE(SUM(i.paid_amount), 0) as total_paid,
    COALESCE(SUM(i.balance_due), 0) as outstanding_balance,
    COUNT(DISTINCT CASE WHEN i.due_date < CURRENT_DATE AND i.payment_status != 'paid' THEN i.id END) as overdue_invoices,
    
    -- Payment methods
    COUNT(DISTINCT pm.id) as active_payment_methods,
    COUNT(DISTINCT pb.id) as active_banks,
    
    -- Last activity
    GREATEST(
        COALESCE(MAX(t.created_at), '1970-01-01'::timestamptz),
        COALESCE(MAX(i.created_at), '1970-01-01'::timestamptz)
    ) as last_financial_activity
    
FROM stores s
LEFT JOIN transactions t ON s.id = t.store_id
LEFT JOIN invoices i ON s.id = i.store_id
LEFT JOIN payment_methods pm ON s.id = pm.store_id AND pm.is_active = TRUE
LEFT JOIN payment_banks pb ON s.id = pb.store_id AND pb.is_active = TRUE
GROUP BY s.id, s.name;

-- View: Payment method performance
CREATE OR REPLACE VIEW payment_method_performance AS
SELECT 
    pm.store_id,
    pm.id as payment_method_id,
    pm.method_name,
    pm.method_type,
    pm.payment_gateway,
    
    -- Usage statistics
    pm.usage_count,
    pm.last_used_at,
    
    -- Transaction statistics from transactions table
    COUNT(t.id) as transaction_count,
    COALESCE(SUM(t.amount), 0) as total_amount,
    COALESCE(AVG(t.amount), 0) as average_amount,
    
    -- Success rate
    CASE 
        WHEN COUNT(t.id) > 0 THEN
            ROUND((COUNT(CASE WHEN t.transaction_status = 'completed' THEN 1 END)::DECIMAL / COUNT(t.id)::DECIMAL) * 100, 2)
        ELSE 0
    END as success_rate,
    
    -- Fee analysis
    COALESCE(SUM(t.gateway_fee), 0) as total_gateway_fees,
    COALESCE(AVG(t.gateway_fee), 0) as average_gateway_fee,
    
    pm.is_active,
    pm.is_default
    
FROM payment_methods pm
LEFT JOIN transactions t ON pm.method_code = t.payment_method AND pm.store_id = t.store_id
GROUP BY 
    pm.store_id, pm.id, pm.method_name, pm.method_type, pm.payment_gateway,
    pm.usage_count, pm.last_used_at, pm.is_active, pm.is_default
ORDER BY pm.store_id, total_amount DESC;

-- View: Invoice aging report
CREATE OR REPLACE VIEW invoice_aging_report AS
SELECT 
    i.store_id,
    i.id as invoice_id,
    i.invoice_number,
    i.billing_name as customer_name,
    i.total_amount,
    i.paid_amount,
    i.balance_due,
    i.invoice_date,
    i.due_date,
    i.payment_status,
    
    -- Aging calculation
    CASE 
        WHEN i.due_date IS NULL THEN 'No Due Date'
        WHEN i.payment_status = 'paid' THEN 'Paid'
        WHEN i.due_date >= CURRENT_DATE THEN 'Current'
        WHEN i.due_date >= CURRENT_DATE - INTERVAL '30 days' THEN '1-30 Days'
        WHEN i.due_date >= CURRENT_DATE - INTERVAL '60 days' THEN '31-60 Days'
        WHEN i.due_date >= CURRENT_DATE - INTERVAL '90 days' THEN '61-90 Days'
        ELSE '90+ Days'
    END as aging_bucket,
    
    -- Days overdue
    CASE 
        WHEN i.due_date IS NULL OR i.payment_status = 'paid' THEN 0
        WHEN i.due_date < CURRENT_DATE THEN (CURRENT_DATE - i.due_date)::INTEGER
        ELSE 0
    END as days_overdue
    
FROM invoices i
WHERE i.invoice_status NOT IN ('cancelled', 'void')
ORDER BY i.store_id, i.due_date ASC;

-- =============================================================================
-- Advanced Helper Functions
-- =============================================================================

-- Function: Get comprehensive financial dashboard data
CREATE OR REPLACE FUNCTION get_financial_dashboard(
    p_store_id UUID,
    p_start_date TIMESTAMPTZ DEFAULT NULL,
    p_end_date TIMESTAMPTZ DEFAULT NULL
)
RETURNS TABLE (
    -- Revenue metrics
    total_revenue DECIMAL(15,4),
    completed_revenue DECIMAL(15,4),
    pending_revenue DECIMAL(15,4),
    refunded_amount DECIMAL(15,4),
    net_revenue DECIMAL(15,4),
    
    -- Transaction metrics
    total_transactions BIGINT,
    completed_transactions BIGINT,
    pending_transactions BIGINT,
    failed_transactions BIGINT,
    
    -- Fee analysis
    total_fees DECIMAL(15,4),
    gateway_fees DECIMAL(15,4),
    platform_fees DECIMAL(15,4),
    
    -- Invoice metrics
    total_invoices BIGINT,
    paid_invoices BIGINT,
    overdue_invoices BIGINT,
    outstanding_balance DECIMAL(15,4),
    
    -- Payment method stats
    active_payment_methods INTEGER,
    most_used_payment_method VARCHAR(100)
) AS $$
DECLARE
    start_date TIMESTAMPTZ := COALESCE(p_start_date, CURRENT_DATE - INTERVAL '30 days');
    end_date TIMESTAMPTZ := COALESCE(p_end_date, CURRENT_DATE + INTERVAL '1 day');
BEGIN
    RETURN QUERY
    WITH transaction_stats AS (
        SELECT 
            COALESCE(SUM(t.amount), 0) as total_rev,
            COALESCE(SUM(CASE WHEN t.transaction_status = 'completed' THEN t.amount ELSE 0 END), 0) as completed_rev,
            COALESCE(SUM(CASE WHEN t.transaction_status = 'pending' THEN t.amount ELSE 0 END), 0) as pending_rev,
            COALESCE(SUM(CASE WHEN t.transaction_type IN ('refund', 'partial_refund') THEN t.amount ELSE 0 END), 0) as refunded,
            COUNT(*)::BIGINT as total_trans,
            COUNT(CASE WHEN t.transaction_status = 'completed' THEN 1 END)::BIGINT as completed_trans,
            COUNT(CASE WHEN t.transaction_status = 'pending' THEN 1 END)::BIGINT as pending_trans,
            COUNT(CASE WHEN t.transaction_status = 'failed' THEN 1 END)::BIGINT as failed_trans,
            COALESCE(SUM(t.gateway_fee + t.platform_fee + t.tax_amount), 0) as total_fees_calc,
            COALESCE(SUM(t.gateway_fee), 0) as gateway_fees_calc,
            COALESCE(SUM(t.platform_fee), 0) as platform_fees_calc
        FROM transactions t
        WHERE t.store_id = p_store_id
            AND t.transaction_date >= start_date
            AND t.transaction_date <= end_date
    ),
    invoice_stats AS (
        SELECT 
            COUNT(*)::BIGINT as total_inv,
            COUNT(CASE WHEN i.payment_status = 'paid' THEN 1 END)::BIGINT as paid_inv,
            COUNT(CASE WHEN i.due_date < CURRENT_DATE AND i.payment_status != 'paid' THEN 1 END)::BIGINT as overdue_inv,
            COALESCE(SUM(i.balance_due), 0) as outstanding_bal
        FROM invoices i
        WHERE i.store_id = p_store_id
            AND i.invoice_date >= start_date::DATE
            AND i.invoice_date <= end_date::DATE
            AND i.invoice_status NOT IN ('cancelled', 'void')
    ),
    payment_method_stats AS (
        SELECT 
            COUNT(CASE WHEN pm.is_active THEN 1 END)::INTEGER as active_methods,
            (
                SELECT pm2.method_name
                FROM payment_methods pm2
                WHERE pm2.store_id = p_store_id
                    AND pm2.is_active = TRUE
                ORDER BY pm2.usage_count DESC
                LIMIT 1
            ) as most_used_method
        FROM payment_methods pm
        WHERE pm.store_id = p_store_id
    )
    SELECT 
        ts.total_rev,
        ts.completed_rev,
        ts.pending_rev,
        ts.refunded,
        ts.completed_rev - ts.refunded - ts.total_fees_calc as net_rev,
        ts.total_trans,
        ts.completed_trans,
        ts.pending_trans,
        ts.failed_trans,
        ts.total_fees_calc,
        ts.gateway_fees_calc,
        ts.platform_fees_calc,
        COALESCE(ins.total_inv, 0),
        COALESCE(ins.paid_inv, 0),
        COALESCE(ins.overdue_inv, 0),
        COALESCE(ins.outstanding_bal, 0),
        COALESCE(pms.active_methods, 0),
        COALESCE(pms.most_used_method, 'None')
    FROM transaction_stats ts
    CROSS JOIN invoice_stats ins
    CROSS JOIN payment_method_stats pms;
END;
$$ LANGUAGE plpgsql;

-- Function: Process payment and update related records
CREATE OR REPLACE FUNCTION process_payment(
    p_store_id UUID,
    p_order_id UUID,
    p_payment_method_id UUID,
    p_amount DECIMAL(15,4),
    p_currency_code VARCHAR(3) DEFAULT 'SAR',
    p_gateway_transaction_id VARCHAR(255) DEFAULT NULL
)
RETURNS TABLE (
    transaction_id UUID,
    invoice_id UUID,
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    v_transaction_id UUID;
    v_invoice_id UUID;
    v_payment_method payment_methods%ROWTYPE;
    v_calculated_fee DECIMAL(15,4);
BEGIN
    -- Get payment method details
    SELECT * INTO v_payment_method
    FROM payment_methods pm
    WHERE pm.id = p_payment_method_id AND pm.store_id = p_store_id;
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT NULL::UUID, NULL::UUID, FALSE, 'Payment method not found';
        RETURN;
    END IF;
    
    -- Calculate payment fee
    SELECT calculate_payment_method_fee(p_payment_method_id, p_amount) INTO v_calculated_fee;
    
    -- Create transaction record
    INSERT INTO transactions (
        store_id, order_id, transaction_type, transaction_status,
        amount, currency_code, payment_method, payment_gateway,
        gateway_transaction_id, gateway_fee
    ) VALUES (
        p_store_id, p_order_id, 'payment', 'completed',
        p_amount, p_currency_code, v_payment_method.method_code, v_payment_method.payment_gateway,
        p_gateway_transaction_id, v_calculated_fee
    ) RETURNING id INTO v_transaction_id;
    
    -- Update or create invoice
    SELECT id INTO v_invoice_id
    FROM invoices
    WHERE store_id = p_store_id AND order_id = p_order_id;
    
    IF v_invoice_id IS NOT NULL THEN
        -- Update existing invoice
        UPDATE invoices
        SET 
            paid_amount = paid_amount + p_amount,
            updated_at = NOW()
        WHERE id = v_invoice_id;
    END IF;
    
    -- Update payment method usage
    UPDATE payment_methods
    SET 
        usage_count = usage_count + 1,
        last_used_at = NOW()
    WHERE id = p_payment_method_id;
    
    RETURN QUERY SELECT v_transaction_id, v_invoice_id, TRUE, 'Payment processed successfully';
END;
$$ LANGUAGE plpgsql;

-- Function: Generate financial report
CREATE OR REPLACE FUNCTION generate_financial_report(
    p_store_id UUID,
    p_report_type VARCHAR(50), -- 'daily', 'weekly', 'monthly', 'yearly'
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL
)
RETURNS TABLE (
    period_label VARCHAR(100),
    period_start DATE,
    period_end DATE,
    total_revenue DECIMAL(15,4),
    total_transactions BIGINT,
    average_transaction DECIMAL(15,4),
    total_fees DECIMAL(15,4),
    net_revenue DECIMAL(15,4)
) AS $$
DECLARE
    v_start_date DATE := COALESCE(p_start_date, CURRENT_DATE - INTERVAL '30 days');
    v_end_date DATE := COALESCE(p_end_date, CURRENT_DATE);
BEGIN
    CASE p_report_type
        WHEN 'daily' THEN
            RETURN QUERY
            SELECT 
                TO_CHAR(t.transaction_date::DATE, 'YYYY-MM-DD') as period_label,
                t.transaction_date::DATE as period_start,
                t.transaction_date::DATE as period_end,
                COALESCE(SUM(t.amount), 0) as total_revenue,
                COUNT(*)::BIGINT as total_transactions,
                COALESCE(AVG(t.amount), 0) as average_transaction,
                COALESCE(SUM(t.gateway_fee + t.platform_fee), 0) as total_fees,
                COALESCE(SUM(t.net_amount), 0) as net_revenue
            FROM transactions t
            WHERE t.store_id = p_store_id
                AND t.transaction_date::DATE >= v_start_date
                AND t.transaction_date::DATE <= v_end_date
                AND t.transaction_status = 'completed'
            GROUP BY t.transaction_date::DATE
            ORDER BY t.transaction_date::DATE;
            
        WHEN 'weekly' THEN
            RETURN QUERY
            SELECT 
                'Week ' || EXTRACT(WEEK FROM t.transaction_date)::TEXT || ', ' || EXTRACT(YEAR FROM t.transaction_date)::TEXT as period_label,
                DATE_TRUNC('week', t.transaction_date)::DATE as period_start,
                (DATE_TRUNC('week', t.transaction_date) + INTERVAL '6 days')::DATE as period_end,
                COALESCE(SUM(t.amount), 0) as total_revenue,
                COUNT(*)::BIGINT as total_transactions,
                COALESCE(AVG(t.amount), 0) as average_transaction,
                COALESCE(SUM(t.gateway_fee + t.platform_fee), 0) as total_fees,
                COALESCE(SUM(t.net_amount), 0) as net_revenue
            FROM transactions t
            WHERE t.store_id = p_store_id
                AND t.transaction_date::DATE >= v_start_date
                AND t.transaction_date::DATE <= v_end_date
                AND t.transaction_status = 'completed'
            GROUP BY DATE_TRUNC('week', t.transaction_date), EXTRACT(WEEK FROM t.transaction_date), EXTRACT(YEAR FROM t.transaction_date)
            ORDER BY DATE_TRUNC('week', t.transaction_date);
            
        WHEN 'monthly' THEN
            RETURN QUERY
            SELECT 
                TO_CHAR(DATE_TRUNC('month', t.transaction_date), 'Month YYYY') as period_label,
                DATE_TRUNC('month', t.transaction_date)::DATE as period_start,
                (DATE_TRUNC('month', t.transaction_date) + INTERVAL '1 month' - INTERVAL '1 day')::DATE as period_end,
                COALESCE(SUM(t.amount), 0) as total_revenue,
                COUNT(*)::BIGINT as total_transactions,
                COALESCE(AVG(t.amount), 0) as average_transaction,
                COALESCE(SUM(t.gateway_fee + t.platform_fee), 0) as total_fees,
                COALESCE(SUM(t.net_amount), 0) as net_revenue
            FROM transactions t
            WHERE t.store_id = p_store_id
                AND t.transaction_date::DATE >= v_start_date
                AND t.transaction_date::DATE <= v_end_date
                AND t.transaction_status = 'completed'
            GROUP BY DATE_TRUNC('month', t.transaction_date)
            ORDER BY DATE_TRUNC('month', t.transaction_date);
    END CASE;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Comments for Views and Functions
-- =============================================================================

COMMENT ON VIEW financial_overview IS 'Comprehensive financial overview for all stores';
COMMENT ON VIEW payment_method_performance IS 'Performance analytics for payment methods';
COMMENT ON VIEW invoice_aging_report IS 'Invoice aging analysis for accounts receivable management';

COMMENT ON FUNCTION get_financial_dashboard(UUID, TIMESTAMPTZ, TIMESTAMPTZ) IS 'Get comprehensive financial dashboard data for a store';
COMMENT ON FUNCTION process_payment(UUID, UUID, UUID, DECIMAL, VARCHAR, VARCHAR) IS 'Process a payment and update related financial records';
COMMENT ON FUNCTION generate_financial_report(UUID, VARCHAR, DATE, DATE) IS 'Generate financial reports for different time periods';

-- =============================================================================
-- Final Success Message
-- =============================================================================

-- Display success message
DO $$
BEGIN
    RAISE NOTICE 'Financial and Payment Tables Setup Complete!';
    RAISE NOTICE 'Created tables: transactions, invoices, payment_methods, payment_banks';
    RAISE NOTICE 'Created views: financial_overview, payment_method_performance, invoice_aging_report';
    RAISE NOTICE 'Created functions: get_financial_dashboard, process_payment, generate_financial_report';
END $$;