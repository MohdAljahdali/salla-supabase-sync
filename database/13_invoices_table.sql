-- =============================================================================
-- Invoices Table
-- =============================================================================
-- This table stores invoice information for orders
-- Includes billing details, payment status, and invoice management
-- Links to Salla API for invoice synchronization

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create invoices table
CREATE TABLE IF NOT EXISTS invoices (
    -- Primary identification
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Salla API identifiers
    salla_invoice_id VARCHAR(255) UNIQUE, -- Salla invoice ID
    salla_order_id VARCHAR(255), -- Related Salla order ID
    
    -- Store relationship (required)
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    
    -- Order relationship (required for most invoices)
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    
    -- Customer relationship
    customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
    
    -- Invoice identification
    invoice_number VARCHAR(100) NOT NULL, -- Human-readable invoice number
    invoice_prefix VARCHAR(20), -- Invoice number prefix
    invoice_sequence INTEGER, -- Sequential number
    
    -- Invoice type and status
    invoice_type VARCHAR(50) NOT NULL DEFAULT 'sale' CHECK (invoice_type IN (
        'sale', 'refund', 'credit_note', 'debit_note', 'proforma', 'estimate'
    )),
    
    invoice_status VARCHAR(50) NOT NULL DEFAULT 'draft' CHECK (invoice_status IN (
        'draft', 'sent', 'viewed', 'paid', 'partially_paid', 
        'overdue', 'cancelled', 'refunded', 'void'
    )),
    
    payment_status VARCHAR(50) NOT NULL DEFAULT 'unpaid' CHECK (payment_status IN (
        'unpaid', 'partially_paid', 'paid', 'overpaid', 'refunded'
    )),
    
    -- Invoice dates
    invoice_date DATE NOT NULL DEFAULT CURRENT_DATE,
    due_date DATE,
    sent_date TIMESTAMPTZ,
    paid_date TIMESTAMPTZ,
    
    -- Billing information
    billing_name VARCHAR(255) NOT NULL,
    billing_email VARCHAR(255),
    billing_phone VARCHAR(50),
    billing_company VARCHAR(255),
    billing_tax_number VARCHAR(100), -- VAT/Tax registration number
    
    -- Billing address
    billing_address JSONB, -- Complete billing address
    
    -- Financial amounts (in store currency)
    currency_code VARCHAR(3) NOT NULL DEFAULT 'SAR',
    
    -- Line items totals
    subtotal DECIMAL(15,4) NOT NULL DEFAULT 0, -- Before tax and discounts
    discount_amount DECIMAL(15,4) DEFAULT 0, -- Total discount amount
    tax_amount DECIMAL(15,4) DEFAULT 0, -- Total tax amount
    shipping_amount DECIMAL(15,4) DEFAULT 0, -- Shipping cost
    total_amount DECIMAL(15,4) NOT NULL DEFAULT 0, -- Final total
    
    -- Payment tracking
    paid_amount DECIMAL(15,4) DEFAULT 0, -- Amount already paid
    balance_due DECIMAL(15,4) DEFAULT 0, -- Remaining balance
    
    -- Tax details
    tax_rate DECIMAL(5,4), -- Tax rate applied
    tax_inclusive BOOLEAN DEFAULT FALSE, -- Whether prices include tax
    tax_details JSONB, -- Detailed tax breakdown
    
    -- Discount information
    discount_type VARCHAR(50), -- Type of discount applied
    discount_value DECIMAL(15,4), -- Discount value
    discount_details JSONB, -- Detailed discount information
    
    -- Invoice items (denormalized for quick access)
    line_items JSONB, -- Array of invoice line items
    
    -- Terms and conditions
    payment_terms VARCHAR(500), -- Payment terms text
    notes TEXT, -- Invoice notes
    footer_text TEXT, -- Footer text for invoice
    
    -- Invoice template and branding
    template_id VARCHAR(100), -- Invoice template used
    logo_url VARCHAR(500), -- Company logo URL
    brand_colors JSONB, -- Brand colors for invoice
    
    -- Language and localization
    language_code VARCHAR(5) DEFAULT 'ar', -- Invoice language
    locale VARCHAR(10) DEFAULT 'ar_SA', -- Locale for formatting
    
    -- Digital invoice features
    pdf_url VARCHAR(500), -- URL to PDF version
    pdf_generated_at TIMESTAMPTZ, -- When PDF was generated
    public_url VARCHAR(500), -- Public URL for customer access
    access_token VARCHAR(255), -- Token for secure access
    
    -- Email tracking
    email_sent_count INTEGER DEFAULT 0, -- Number of times emailed
    last_email_sent_at TIMESTAMPTZ, -- Last email sent time
    email_opened BOOLEAN DEFAULT FALSE, -- Whether email was opened
    email_opened_at TIMESTAMPTZ, -- When email was first opened
    
    -- Reminder settings
    reminder_enabled BOOLEAN DEFAULT TRUE,
    reminder_days_before INTEGER DEFAULT 3, -- Days before due date to send reminder
    reminder_sent_count INTEGER DEFAULT 0,
    last_reminder_sent_at TIMESTAMPTZ,
    
    -- Late fees
    late_fee_enabled BOOLEAN DEFAULT FALSE,
    late_fee_amount DECIMAL(15,4) DEFAULT 0,
    late_fee_percentage DECIMAL(5,4), -- Late fee as percentage
    late_fee_applied_at TIMESTAMPTZ,
    
    -- Related invoices (for refunds, credit notes)
    parent_invoice_id UUID REFERENCES invoices(id),
    refund_reason VARCHAR(500),
    
    -- Recurring invoice settings
    is_recurring BOOLEAN DEFAULT FALSE,
    recurring_frequency VARCHAR(50), -- monthly, quarterly, yearly
    recurring_interval INTEGER DEFAULT 1, -- Every X periods
    next_invoice_date DATE, -- Next invoice generation date
    recurring_end_date DATE, -- When to stop recurring
    
    -- Integration and sync
    external_invoice_id VARCHAR(255), -- External system invoice ID
    sync_status VARCHAR(50) DEFAULT 'pending', -- Sync status with external systems
    last_sync_at TIMESTAMPTZ,
    sync_errors JSONB, -- Sync error details
    
    -- Additional metadata
    metadata JSONB, -- Additional invoice data
    tags TEXT[], -- Invoice tags for categorization
    
    -- Audit fields
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID, -- User who created the invoice
    updated_by UUID -- User who last updated the invoice
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_invoices_store_id ON invoices(store_id);
CREATE INDEX IF NOT EXISTS idx_invoices_order_id ON invoices(order_id);
CREATE INDEX IF NOT EXISTS idx_invoices_customer_id ON invoices(customer_id);
CREATE INDEX IF NOT EXISTS idx_invoices_salla_invoice_id ON invoices(salla_invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoices_salla_order_id ON invoices(salla_order_id);
CREATE INDEX IF NOT EXISTS idx_invoices_invoice_number ON invoices(invoice_number);
CREATE INDEX IF NOT EXISTS idx_invoices_invoice_type ON invoices(invoice_type);
CREATE INDEX IF NOT EXISTS idx_invoices_invoice_status ON invoices(invoice_status);
CREATE INDEX IF NOT EXISTS idx_invoices_payment_status ON invoices(payment_status);
CREATE INDEX IF NOT EXISTS idx_invoices_invoice_date ON invoices(invoice_date);
CREATE INDEX IF NOT EXISTS idx_invoices_due_date ON invoices(due_date);
CREATE INDEX IF NOT EXISTS idx_invoices_billing_email ON invoices(billing_email);
CREATE INDEX IF NOT EXISTS idx_invoices_billing_tax_number ON invoices(billing_tax_number);
CREATE INDEX IF NOT EXISTS idx_invoices_parent_invoice_id ON invoices(parent_invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoices_is_recurring ON invoices(is_recurring);
CREATE INDEX IF NOT EXISTS idx_invoices_next_invoice_date ON invoices(next_invoice_date);
CREATE INDEX IF NOT EXISTS idx_invoices_external_invoice_id ON invoices(external_invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoices_created_at ON invoices(created_at);

-- GIN indexes for JSONB columns
CREATE INDEX IF NOT EXISTS idx_invoices_billing_address_gin ON invoices USING GIN(billing_address);
CREATE INDEX IF NOT EXISTS idx_invoices_tax_details_gin ON invoices USING GIN(tax_details);
CREATE INDEX IF NOT EXISTS idx_invoices_discount_details_gin ON invoices USING GIN(discount_details);
CREATE INDEX IF NOT EXISTS idx_invoices_line_items_gin ON invoices USING GIN(line_items);
CREATE INDEX IF NOT EXISTS idx_invoices_brand_colors_gin ON invoices USING GIN(brand_colors);
CREATE INDEX IF NOT EXISTS idx_invoices_sync_errors_gin ON invoices USING GIN(sync_errors);
CREATE INDEX IF NOT EXISTS idx_invoices_metadata_gin ON invoices USING GIN(metadata);

-- GIN index for tags array
CREATE INDEX IF NOT EXISTS idx_invoices_tags_gin ON invoices USING GIN(tags);

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_invoices_store_status ON invoices(store_id, invoice_status);
CREATE INDEX IF NOT EXISTS idx_invoices_store_payment_status ON invoices(store_id, payment_status);
CREATE INDEX IF NOT EXISTS idx_invoices_store_date ON invoices(store_id, invoice_date);
CREATE INDEX IF NOT EXISTS idx_invoices_customer_date ON invoices(customer_id, invoice_date);
CREATE INDEX IF NOT EXISTS idx_invoices_due_status ON invoices(due_date, payment_status);

-- Create trigger to automatically update updated_at
CREATE OR REPLACE FUNCTION update_invoices_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_invoices_updated_at
    BEFORE UPDATE ON invoices
    FOR EACH ROW
    EXECUTE FUNCTION update_invoices_updated_at();

-- Create trigger to automatically calculate balance due
CREATE OR REPLACE FUNCTION calculate_invoice_balance()
RETURNS TRIGGER AS $$
BEGIN
    -- Calculate balance due
    NEW.balance_due = NEW.total_amount - COALESCE(NEW.paid_amount, 0);
    
    -- Update payment status based on amounts
    IF NEW.paid_amount = 0 THEN
        NEW.payment_status = 'unpaid';
    ELSIF NEW.paid_amount >= NEW.total_amount THEN
        NEW.payment_status = 'paid';
        IF NEW.paid_date IS NULL THEN
            NEW.paid_date = NOW();
        END IF;
    ELSIF NEW.paid_amount > NEW.total_amount THEN
        NEW.payment_status = 'overpaid';
    ELSE
        NEW.payment_status = 'partially_paid';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_calculate_invoice_balance
    BEFORE INSERT OR UPDATE ON invoices
    FOR EACH ROW
    EXECUTE FUNCTION calculate_invoice_balance();

-- Create trigger to generate invoice number if not provided
CREATE OR REPLACE FUNCTION generate_invoice_number()
RETURNS TRIGGER AS $$
DECLARE
    next_sequence INTEGER;
    prefix VARCHAR(20);
BEGIN
    -- Only generate if invoice_number is not provided
    IF NEW.invoice_number IS NULL OR NEW.invoice_number = '' THEN
        -- Get or set prefix
        prefix = COALESCE(NEW.invoice_prefix, 'INV');
        
        -- Get next sequence number for this store and prefix
        SELECT COALESCE(MAX(invoice_sequence), 0) + 1 
        INTO next_sequence
        FROM invoices 
        WHERE store_id = NEW.store_id 
        AND invoice_prefix = prefix;
        
        -- Set sequence and generate number
        NEW.invoice_sequence = next_sequence;
        NEW.invoice_number = prefix || '-' || LPAD(next_sequence::TEXT, 6, '0');
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_generate_invoice_number
    BEFORE INSERT ON invoices
    FOR EACH ROW
    EXECUTE FUNCTION generate_invoice_number();

-- Helper function to get invoice summary for a store
CREATE OR REPLACE FUNCTION get_store_invoice_summary(
    p_store_id UUID,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL
)
RETURNS TABLE (
    total_invoices BIGINT,
    total_amount DECIMAL(15,4),
    paid_amount DECIMAL(15,4),
    outstanding_amount DECIMAL(15,4),
    overdue_invoices BIGINT,
    overdue_amount DECIMAL(15,4)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::BIGINT as total_invoices,
        COALESCE(SUM(i.total_amount), 0) as total_amount,
        COALESCE(SUM(i.paid_amount), 0) as paid_amount,
        COALESCE(SUM(i.balance_due), 0) as outstanding_amount,
        COUNT(CASE WHEN i.due_date < CURRENT_DATE AND i.payment_status != 'paid' THEN 1 END)::BIGINT as overdue_invoices,
        COALESCE(SUM(CASE WHEN i.due_date < CURRENT_DATE AND i.payment_status != 'paid' THEN i.balance_due ELSE 0 END), 0) as overdue_amount
    FROM invoices i
    WHERE i.store_id = p_store_id
        AND i.invoice_status != 'cancelled'
        AND (p_start_date IS NULL OR i.invoice_date >= p_start_date)
        AND (p_end_date IS NULL OR i.invoice_date <= p_end_date);
END;
$$ LANGUAGE plpgsql;

-- Helper function to get overdue invoices
CREATE OR REPLACE FUNCTION get_overdue_invoices(
    p_store_id UUID DEFAULT NULL,
    p_days_overdue INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    invoice_number VARCHAR(100),
    customer_name VARCHAR(255),
    total_amount DECIMAL(15,4),
    balance_due DECIMAL(15,4),
    due_date DATE,
    days_overdue INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        i.id,
        i.invoice_number,
        i.billing_name as customer_name,
        i.total_amount,
        i.balance_due,
        i.due_date,
        (CURRENT_DATE - i.due_date)::INTEGER as days_overdue
    FROM invoices i
    WHERE i.due_date < CURRENT_DATE - INTERVAL '1 day' * p_days_overdue
        AND i.payment_status NOT IN ('paid', 'refunded')
        AND i.invoice_status NOT IN ('cancelled', 'void')
        AND (p_store_id IS NULL OR i.store_id = p_store_id)
    ORDER BY i.due_date ASC;
END;
$$ LANGUAGE plpgsql;

-- Helper function to get recurring invoices due for generation
CREATE OR REPLACE FUNCTION get_recurring_invoices_due(
    p_store_id UUID DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    invoice_number VARCHAR(100),
    next_invoice_date DATE,
    recurring_frequency VARCHAR(50)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        i.id,
        i.invoice_number,
        i.next_invoice_date,
        i.recurring_frequency
    FROM invoices i
    WHERE i.is_recurring = TRUE
        AND i.next_invoice_date <= CURRENT_DATE
        AND (i.recurring_end_date IS NULL OR i.recurring_end_date >= CURRENT_DATE)
        AND (p_store_id IS NULL OR i.store_id = p_store_id)
    ORDER BY i.next_invoice_date ASC;
END;
$$ LANGUAGE plpgsql;

-- Add comments for documentation
COMMENT ON TABLE invoices IS 'Stores invoice information for orders including billing details and payment tracking';
COMMENT ON COLUMN invoices.salla_invoice_id IS 'Unique identifier from Salla API';
COMMENT ON COLUMN invoices.invoice_number IS 'Human-readable invoice number';
COMMENT ON COLUMN invoices.invoice_type IS 'Type of invoice: sale, refund, credit_note, etc.';
COMMENT ON COLUMN invoices.payment_status IS 'Payment status: unpaid, paid, partially_paid, etc.';
COMMENT ON COLUMN invoices.total_amount IS 'Final total amount of the invoice';
COMMENT ON COLUMN invoices.balance_due IS 'Remaining amount to be paid';
COMMENT ON COLUMN invoices.line_items IS 'Array of invoice line items in JSON format';
COMMENT ON COLUMN invoices.billing_address IS 'Complete billing address in JSON format';
COMMENT ON COLUMN invoices.is_recurring IS 'Whether this is a recurring invoice';
COMMENT ON COLUMN invoices.metadata IS 'Additional invoice data in JSON format';
COMMENT ON COLUMN invoices.tags IS 'Array of tags for invoice categorization';