# Database Schema for Salla-Supabase Sync

This directory contains SQL scripts to create the database schema for the Salla-Supabase synchronization application.

## Core Tables Created

### 1. Stores Table (`01_stores_table.sql`)
- **Purpose**: Main reference table for store information
- **Key Features**:
  - Store basic information (name, description, logo)
  - Contact and address details
  - API configuration for Salla integration
  - Store settings (currency, timezone, language)
  - Automatic timestamp tracking

### 2. Products Table (`02_products_table.sql`)
- **Purpose**: Store all product information from Salla
- **Key Features**:
  - Complete product details (name, description, pricing)
  - Inventory management (SKU, quantity, variants)
  - SEO optimization fields
  - Product options and variants (JSON storage)
  - Media files (images, videos)
  - Category and tag relationships

### 3. Categories Table (`03_categories_table.sql`)
- **Purpose**: Hierarchical category structure
- **Key Features**:
  - Parent-child relationships for subcategories
  - Automatic level calculation
  - SEO fields for categories
  - Category path generation function
  - Product count caching

### 4. Customers Table (`04_customers_table.sql`)
- **Purpose**: Customer information and profiles
- **Key Features**:
  - Personal and business customer support
  - Multiple addresses (JSON storage)
  - Customer statistics (orders, spending)
  - Marketing preferences
  - Customer groups and tags

### 5. Orders Table (`05_orders_table.sql`)
- **Purpose**: Order management and tracking
- **Key Features**:
  - Complete order lifecycle tracking
  - Payment and shipping information
  - Automatic status date updates
  - Billing and shipping addresses
  - Order totals calculation

### 6. Order Items Table (`06_order_items_table.sql`)
- **Purpose**: Individual items within orders
- **Key Features**:
  - Product snapshot at time of order
  - Variant and option tracking
  - Return and refund management
  - Automatic total calculation
  - Order total updates on item changes

## Shipping and Delivery Tables

### 7. Shipping Companies Table (`07_shipping_companies_table.sql`)
- **Purpose**: Available shipping providers and services
- **Key Features**:
  - Shipping company information and configuration
  - Service capabilities and coverage areas
  - API integration settings
  - Pricing and delivery time estimates
  - Active status management

### 8. Shipping Zones Table (`08_shipping_zones_table.sql`)
- **Purpose**: Geographic shipping zones management
- **Key Features**:
  - Zone-specific shipping rules
  - Geographic coverage definition
  - Zone-based pricing calculations
  - Delivery time estimates per zone
  - Zone hierarchy support

### 9. Shipping Rules Table (`09_shipping_rules_table.sql`)
- **Purpose**: Complex shipping cost calculations
- **Key Features**:
  - Flexible shipping cost rules
  - Free shipping conditions
  - Weight and dimension-based pricing
  - Product and customer restrictions
  - Priority-based rule application

### 10. Shipments Table (`10_shipments_table.sql`)
- **Purpose**: Actual shipment tracking and management
- **Key Features**:
  - Real-time shipment tracking
  - Delivery status updates
  - Performance metrics and analytics
  - Integration with shipping providers
  - Delivery confirmation and feedback

## Financial and Payment Tables

### 11. Transactions Table (`12_transactions_table.sql`)
- **Purpose**: Financial transaction management and tracking
- **Key Features**:
  - Complete transaction lifecycle tracking
  - Payment method and gateway integration
  - Automatic fee calculation and net amount
  - Refund and chargeback management
  - Risk assessment and fraud detection
  - Reconciliation and reporting

### 12. Invoices Table (`13_invoices_table.sql`)
- **Purpose**: Invoice generation and management
- **Key Features**:
  - Automated invoice generation from orders
  - Payment tracking and balance calculation
  - Multi-currency and tax support
  - Digital invoice delivery (PDF, email)
  - Recurring invoice automation
  - Aging and overdue management

### 13. Payment Methods Table (`14_payment_methods_table.sql`)
- **Purpose**: Payment method configuration and management
- **Key Features**:
  - Multiple payment gateway support
  - Fee structure and limit configuration
  - Geographic and customer restrictions
  - Usage analytics and performance tracking
  - Security and compliance settings
  - A/B testing and optimization

### 14. Payment Banks Table (`15_payment_banks_table.sql`)
- **Purpose**: Bank account and transfer management
- **Key Features**:
  - Multiple bank account support
  - International transfer capabilities
  - Fee calculation and processing times
  - Compliance and verification tracking
  - Transaction limits and security
  - Performance analytics and reporting

## Marketing and Offers Tables

### 15. Coupons Table (`17_coupons_table.sql`)
- **Purpose**: Coupon and discount code management
- **Key Features**:
  - Flexible discount types (percentage, fixed, free shipping, BOGO)
  - Advanced usage conditions and restrictions
  - Customer and product targeting
  - Geographic and time-based limitations
  - Usage tracking and analytics
  - Auto-generation and bulk management

### 16. Special Offers Table (`18_special_offers_table.sql`)
- **Purpose**: Promotional campaigns and special offers
- **Key Features**:
  - Multiple offer types (flash sales, bundles, seasonal)
  - Advanced targeting and segmentation
  - Campaign management and scheduling
  - Performance tracking and analytics
  - SEO and marketing optimization
  - Approval workflow and compliance

### 17. Affiliates Table (`19_affiliates_table.sql`)
- **Purpose**: Affiliate partner management and tracking
- **Key Features**:
  - Comprehensive affiliate profiles
  - Flexible commission structures
  - Performance metrics and analytics
  - Payment processing and tracking
  - Fraud prevention and compliance
  - Recruitment and referral management

## Content Management Tables

### 18. Brands Table (`21_brands_table.sql`)
- **Purpose**: Brand management and organization
- **Key Features**:
  - Comprehensive brand profiles
  - Brand media and assets management
  - Performance metrics and analytics
  - SEO optimization and marketing
  - Social media integration
  - Quality assurance and partnerships

### 19. Tags Table (`22_tags_table.sql`)
- **Purpose**: Content classification and organization
- **Key Features**:
  - Hierarchical tag structure
  - Multiple tag types and categories
  - Usage tracking and analytics
  - Auto-assignment and suggestions
  - Performance metrics and engagement
  - Multilingual support and translations

### 20. Taxes Table (`23_taxes_table.sql`)
- **Purpose**: Tax configuration and calculation
- **Key Features**:
  - Multiple tax types and methods
  - Geographic and customer-based rules
  - Tiered and progressive taxation
  - Compliance and audit tracking
  - Performance metrics and reporting
  - Integration with external tax services

## Store Management Tables

### 21. Branches Table (`25_branches_table.sql`)
- **Purpose**: Store branch management and operations
- **Key Features**:
  - Comprehensive branch profiles
  - Inventory management per branch
  - Product allocation and distribution
  - Performance metrics and analytics
  - Staff management and operations
  - Financial tracking and reporting
  - Location-based services and mapping

### 22. Currencies Table (`26_currencies_table.sql`)
- **Purpose**: Multi-currency support and exchange rates
- **Key Features**:
  - Real-time exchange rate management
  - Currency conversion and calculations
  - Historical rate tracking
  - Performance metrics and analytics
  - Risk management and compliance
  - Payment integration and processing
  - Regional currency support

### 23. Countries Table (`27_countries_table.sql`)
- **Purpose**: Geographic and regional management
- **Key Features**:
  - Comprehensive country profiles
  - Shipping and logistics configuration
  - Tax and compliance management
  - Performance metrics and analytics
  - Regional settings and preferences
  - Economic and demographic data
  - Integration with external services

## Analytics and Reports Tables

### 24. Abandoned Carts Table (`29_abandoned_carts_table.sql`)
- **Purpose**: Track and analyze abandoned shopping carts for recovery optimization
- **Key Features**:
  - Comprehensive cart abandonment tracking
  - Customer behavior analysis and segmentation
  - Recovery campaign management and automation
  - Conversion tracking and performance metrics
  - Geographic and demographic insights
  - Marketing attribution and ROI analysis
  - Risk assessment and fraud detection
  - Seasonal and temporal pattern analysis

### 25. Reservations Table (`30_reservations_table.sql`)
- **Purpose**: Manage product reservations and booking systems
- **Key Features**:
  - Comprehensive reservation management
  - Service and appointment booking
  - Capacity and resource allocation
  - Staff scheduling and assignment
  - Payment processing and confirmation
  - Customer communication and notifications
  - Performance analytics and reporting
  - Integration with external booking systems

### 26. Product Quantities Table (`31_product_quantities_table.sql`)
- **Purpose**: Advanced inventory tracking and stock management
- **Key Features**:
  - Real-time inventory monitoring
  - Stock movement tracking and audit trails
  - Multi-location inventory management
  - Automated reorder and alert systems
  - Supplier and cost management
  - Quality control and expiry tracking
  - Forecasting and demand planning
  - Performance analytics and optimization

## Installation Instructions

### Option 1: Run All Core Tables
```sql
\i 00_run_all_core_tables.sql
```

### Option 2: Run All Shipping Tables
```sql
\i 11_run_all_shipping_tables.sql
```

### Option 3: Run All Financial Tables
```sql
\i 16_run_all_financial_tables.sql
```

### Option 4: Run All Marketing Tables
```sql
\i 20_run_all_marketing_tables.sql
```

### Option 5: Run All Content Management Tables
```sql
\i 24_run_all_content_management_tables.sql
```

### Option 6: Run All Store Management Tables
```sql
\i 28_run_all_store_management_tables.sql
```

### Option 7: Run All Analytics and Reports Tables
```sql
\i 32_run_all_analytics_reports_tables.sql
```

### Option 8: Run Individual Tables

#### Core Tables:
```sql
\i 01_stores_table.sql
\i 02_products_table.sql
\i 03_categories_table.sql
\i 04_customers_table.sql
\i 05_orders_table.sql
\i 06_order_items_table.sql
```

#### Shipping Tables:
```sql
\i 07_shipping_companies_table.sql
\i 08_shipping_zones_table.sql
\i 09_shipping_rules_table.sql
\i 10_shipments_table.sql
```

#### Financial Tables:
```sql
\i 12_transactions_table.sql
\i 13_invoices_table.sql
\i 14_payment_methods_table.sql
\i 15_payment_banks_table.sql
```

#### Marketing Tables:
```sql
\i 17_coupons_table.sql
\i 18_special_offers_table.sql
\i 19_affiliates_table.sql
```

#### Content Management Tables:
```sql
\i 21_brands_table.sql
\i 22_tags_table.sql
\i 23_taxes_table.sql
```

#### Store Management Tables:
```sql
\i 25_branches_table.sql
\i 26_currencies_table.sql
\i 27_countries_table.sql
```

#### Analytics and Reports Tables:
```sql
\i 29_abandoned_carts_table.sql
\i 30_reservations_table.sql
\i 31_product_quantities_table.sql
```

## Database Features

### Automatic Triggers
- **Updated At**: All tables automatically update `updated_at` timestamp
- **Category Levels**: Categories automatically calculate their hierarchy level
- **Order Status Dates**: Orders automatically track status change dates
- **Order Totals**: Order totals update when items are modified
- **Shipment Status Dates**: Shipments automatically track status change dates
- **Transaction Net Amount**: Transactions automatically calculate net amount after fees
- **Invoice Balance**: Invoices automatically calculate balance due and payment status
- **Payment Method Usage**: Payment methods track usage count and last used date
- **Coupon Status**: Coupons automatically update status based on usage and expiry
- **Offer Status**: Special offers automatically update status and remaining stock
- **Affiliate Performance**: Affiliates automatically calculate performance metrics
- **Brand Slug Generation**: Brands automatically generate URL-friendly slugs
- **Tag Hierarchy**: Tags automatically update hierarchy levels and paths
- **Tax Configuration Validation**: Taxes automatically validate configuration and rates
- **Branch Slug Generation**: Branches automatically generate URL-friendly slugs
- **Branch Performance Metrics**: Branches automatically update performance metrics
- **Currency Settings Validation**: Currencies automatically validate settings and rates
- **Currency Performance Metrics**: Currencies automatically update performance metrics
- **Country Settings Validation**: Countries automatically validate settings and configurations
- **Country Performance Metrics**: Countries automatically update performance metrics
- **Abandoned Cart Timestamps**: Abandoned carts automatically track abandonment, recovery, and conversion timestamps
- **Abandoned Cart Recovery Metrics**: Abandoned carts automatically calculate recovery scores and metrics
- **Reservation Status Timestamps**: Reservations automatically track status change timestamps
- **Reservation Amount Calculations**: Reservations automatically calculate total amounts and fees
- **Product Quantity Metrics**: Product quantities automatically calculate stock metrics and alerts
- **Inventory Stock Alerts**: Product quantities automatically trigger stock level alerts

### Performance Optimizations
- **Indexes**: Strategic indexes on frequently queried columns
- **GIN Indexes**: Optimized JSON column searching
- **Unique Constraints**: Prevent duplicate data from Salla API
- **Shipping Indexes**: Optimized shipping cost calculation queries

### Data Integrity
- **Foreign Keys**: Proper relationships between tables
- **Check Constraints**: Validate enum values and data ranges
- **Cascading Deletes**: Maintain referential integrity
- **Shipping Rule Validation**: Priority handling and rule validation

### Useful Views
- **products_with_categories**: Products with resolved category names
- **orders_with_customer**: Orders with current customer information
- **order_items_detailed**: Order items with complete details
- **shipping_options_complete**: Complete shipping options by store
- **shipment_tracking_summary**: Shipment tracking with status
- **shipping_company_performance**: Performance metrics by company
- **financial_overview**: Comprehensive financial overview for all stores
- **payment_method_performance**: Performance analytics for payment methods
- **invoice_aging_report**: Invoice aging analysis for accounts receivable
- **marketing_overview**: Comprehensive marketing activities overview
- **active_marketing_campaigns**: Currently active marketing campaigns
- **marketing_performance_report**: Monthly marketing performance analytics
- **content_management_overview**: Overview of content management elements per store
- **active_content_elements**: Unified view of all active content management elements
- **content_performance_report**: Performance metrics for content management elements
- **store_management_overview**: Comprehensive overview of store management elements per store
- **active_store_management_elements**: Unified view of all active store management elements
- **store_management_performance_report**: Performance metrics for store management elements
- **analytics_overview**: Comprehensive analytics overview combining abandoned carts, reservations, and inventory
- **daily_analytics_summary**: Daily summary of key analytics metrics for trend analysis
- **product_performance_analytics**: Product-level performance analytics combining multiple data sources
- **customer_analytics**: Customer behavior analytics based on abandoned carts and reservations

### Helper Functions
- **get_category_path()**: Generate category breadcrumb
- **update_customer_stats()**: Recalculate customer statistics
- **calculate_order_total()**: Calculate order totals
- **can_item_be_returned()**: Check return eligibility
- **calculate_shipping_cost()**: Calculate shipping costs by zone
- **get_shipping_quotes()**: Zone-based shipping quotes
- **track_shipment()**: Shipment tracking and management
- **analyze_delivery_performance()**: Delivery performance analytics
- **get_financial_dashboard()**: Comprehensive financial dashboard data
- **process_payment()**: Process payments and update related records
- **generate_financial_report()**: Generate financial reports for different periods
- **calculate_payment_method_fee()**: Calculate payment method fees
- **is_coupon_valid()**: Validate coupon eligibility for orders
- **apply_coupon_to_order()**: Apply coupons and track usage
- **get_store_coupon_stats()**: Coupon performance statistics
- **is_special_offer_valid()**: Validate special offer eligibility
- **apply_special_offer_to_order()**: Apply special offers and track usage
- **get_store_special_offers_stats()**: Special offer performance analytics
- **calculate_affiliate_commission()**: Calculate affiliate commissions
- **record_affiliate_sale()**: Record affiliate sales and update metrics
- **get_store_affiliate_stats()**: Affiliate performance statistics
- **get_marketing_dashboard()**: Comprehensive marketing dashboard data
- **apply_best_marketing_offer()**: Find and apply best available offers
- **generate_marketing_report()**: Generate marketing performance reports
- **cleanup_expired_marketing_campaigns()**: Automatically deactivate expired campaigns
- **get_brand_stats()**: Brand performance and product statistics
- **search_brands()**: Advanced brand search with filters
- **update_brand_metrics_from_products()**: Update brand metrics from product data
- **get_tag_stats()**: Tag usage and performance statistics
- **get_tag_hierarchy()**: Retrieve tag hierarchy and relationships
- **increment_tag_usage()**: Track and update tag usage metrics
- **calculate_tax_amount()**: Calculate tax amounts for orders
- **get_applicable_taxes()**: Get applicable taxes for products/orders
- **get_content_management_dashboard()**: Comprehensive content management metrics
- **search_content_elements()**: Unified search across brands, tags, and taxes
- **generate_content_management_report()**: Generate content management reports
- **cleanup_inactive_content_elements()**: Clean up inactive content elements
- **get_branch_stats()**: Branch performance and operational statistics
- **get_store_branches_stats()**: Aggregated branch statistics for stores
- **search_branches()**: Advanced branch search with location and performance filters
- **update_branch_metrics_from_orders()**: Update branch metrics from order data
- **get_currency_stats()**: Currency usage and performance statistics
- **convert_currency()**: Real-time currency conversion with current rates
- **update_exchange_rates()**: Bulk update exchange rates from external sources
- **get_currency_conversion_history()**: Historical currency conversion data
- **get_country_stats()**: Country performance and shipping statistics
- **search_countries()**: Advanced country search with geographic and economic filters
- **calculate_country_shipping_cost()**: Calculate shipping costs by country
- **update_country_metrics_from_orders()**: Update country metrics from order data
- **get_store_management_dashboard()**: Comprehensive store management dashboard
- **search_store_management_elements()**: Unified search across branches, currencies, and countries
- **generate_store_management_report()**: Generate store management performance reports
- **cleanup_inactive_store_management_elements()**: Clean up inactive store management elements
- **get_analytics_dashboard()**: Comprehensive analytics dashboard combining all analytics data
- **generate_analytics_report()**: Generate various types of analytics reports (summary, detailed, trends)
- **get_top_performing_products()**: Get top performing products based on different metrics
- **get_abandoned_cart_stats()**: Abandoned cart statistics and recovery metrics
- **search_abandoned_carts()**: Advanced search for abandoned carts with filters
- **mark_cart_as_recovered()**: Mark abandoned carts as recovered and update metrics
- **get_reservation_stats()**: Reservation statistics and performance metrics
- **search_reservations()**: Advanced reservation search with filters
- **get_staff_schedule()**: Staff scheduling and availability management
- **check_reservation_availability()**: Check availability for new reservations
- **update_reservation_status()**: Update reservation status and related metrics
- **get_inventory_stats()**: Comprehensive inventory statistics and analytics
- **search_product_quantities()**: Advanced inventory search with filters
- **update_product_quantity()**: Update product quantities with audit trail
- **get_reorder_list()**: Generate reorder recommendations based on stock levels
- **reserve_product_quantity()**: Reserve product quantities for orders

## Next Steps

After creating these core tables, you can:

1. **Add Additional Tables**: Create shipping, payment, and marketing tables
2. **Insert Test Data**: Add sample data for testing
3. **Configure RLS**: Set up Row Level Security policies
4. **Create API Functions**: Add stored procedures for common operations

## Notes

- All tables include `store_id` for multi-store support
- JSON columns are used for flexible data storage (addresses, options, metadata)
- Timestamps are in UTC with timezone support
- All monetary values use DECIMAL for precision
- Text fields are appropriately sized for Salla API data

## Support

For questions or issues with the database schema, refer to:
- Salla API Documentation
- Supabase Documentation
- Project README.md file