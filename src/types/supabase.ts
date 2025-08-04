/**
 * Supabase type definitions
 * Database schema and API types for the sync application
 */

import type { Timestamp, Currency, Language, Status } from './index';

// Database table types
export interface Database {
  public: {
    Tables: {
      stores: {
        Row: DbStore;
        Insert: DbStoreInsert;
        Update: DbStoreUpdate;
      };
      products: {
        Row: DbProduct;
        Insert: DbProductInsert;
        Update: DbProductUpdate;
      };
      categories: {
        Row: DbCategory;
        Insert: DbCategoryInsert;
        Update: DbCategoryUpdate;
      };
      customers: {
        Row: DbCustomer;
        Insert: DbCustomerInsert;
        Update: DbCustomerUpdate;
      };
      orders: {
        Row: DbOrder;
        Insert: DbOrderInsert;
        Update: DbOrderUpdate;
      };
      order_items: {
        Row: DbOrderItem;
        Insert: DbOrderItemInsert;
        Update: DbOrderItemUpdate;
      };
      sync_logs: {
        Row: DbSyncLog;
        Insert: DbSyncLogInsert;
        Update: DbSyncLogUpdate;
      };
      webhooks: {
        Row: DbWebhook;
        Insert: DbWebhookInsert;
        Update: DbWebhookUpdate;
      };
      brands: {
        Row: DbBrand;
        Insert: DbBrandInsert;
        Update: DbBrandUpdate;
      };
      branches: {
        Row: DbBranch;
        Insert: DbBranchInsert;
        Update: DbBranchUpdate;
      };
      currencies: {
        Row: DbCurrency;
        Insert: DbCurrencyInsert;
        Update: DbCurrencyUpdate;
      };
      countries: {
        Row: DbCountry;
        Insert: DbCountryInsert;
        Update: DbCountryUpdate;
      };
      taxes: {
        Row: DbTax;
        Insert: DbTaxInsert;
        Update: DbTaxUpdate;
      };
      coupons: {
        Row: DbCoupon;
        Insert: DbCouponInsert;
        Update: DbCouponUpdate;
      };
      coupon_codes: {
        Row: DbCouponCode;
        Insert: DbCouponCodeInsert;
        Update: DbCouponCodeUpdate;
      };
      special_offers: {
        Row: DbSpecialOffer;
        Insert: DbSpecialOfferInsert;
        Update: DbSpecialOfferUpdate;
      };
      affiliates: {
        Row: DbAffiliate;
        Insert: DbAffiliateInsert;
        Update: DbAffiliateUpdate;
      };
      transactions: {
        Row: DbTransaction;
        Insert: DbTransactionInsert;
        Update: DbTransactionUpdate;
      };
      payment_methods: {
        Row: DbPaymentMethod;
        Insert: DbPaymentMethodInsert;
        Update: DbPaymentMethodUpdate;
      };
      payment_banks: {
        Row: DbPaymentBank;
        Insert: DbPaymentBankInsert;
        Update: DbPaymentBankUpdate;
      };
      settlements: {
        Row: DbSettlement;
        Insert: DbSettlementInsert;
        Update: DbSettlementUpdate;
      };
      shipments: {
        Row: DbShipment;
        Insert: DbShipmentInsert;
        Update: DbShipmentUpdate;
      };
      shipping_companies: {
        Row: DbShippingCompany;
        Insert: DbShippingCompanyInsert;
        Update: DbShippingCompanyUpdate;
      };
      shipping_zones: {
        Row: DbShippingZone;
        Insert: DbShippingZoneInsert;
        Update: DbShippingZoneUpdate;
      };
      customer_groups: {
        Row: DbCustomerGroup;
        Insert: DbCustomerGroupInsert;
        Update: DbCustomerGroupUpdate;
      };
      abandoned_carts: {
        Row: DbAbandonedCart;
        Insert: DbAbandonedCartInsert;
        Update: DbAbandonedCartUpdate;
      };
      product_tags: {
        Row: DbProductTag;
        Insert: DbProductTagInsert;
        Update: DbProductTagUpdate;
      };
      order_tags: {
        Row: DbOrderTag;
        Insert: DbOrderTagInsert;
        Update: DbOrderTagUpdate;
      };
      product_options: {
        Row: DbProductOption;
        Insert: DbProductOptionInsert;
        Update: DbProductOptionUpdate;
      };
      product_variants: {
        Row: DbProductVariant;
        Insert: DbProductVariantInsert;
        Update: DbProductVariantUpdate;
      };
      product_images: {
        Row: DbProductImage;
        Insert: DbProductImageInsert;
        Update: DbProductImageUpdate;
      };
      product_option_values: {
        Row: DbProductOptionValue;
        Insert: DbProductOptionValueInsert;
        Update: DbProductOptionValueUpdate;
      };
      customer_addresses: {
        Row: DbCustomerAddress;
        Insert: DbCustomerAddressInsert;
        Update: DbCustomerAddressUpdate;
      };
      order_addresses: {
        Row: DbOrderAddress;
        Insert: DbOrderAddressInsert;
        Update: DbOrderAddressUpdate;
      };
      product_ratings: {
        Row: DbProductRating;
        Insert: DbProductRatingInsert;
        Update: DbProductRatingUpdate;
      };
      abandoned_cart_items: {
        Row: DbAbandonedCartItem;
        Insert: DbAbandonedCartItemInsert;
        Update: DbAbandonedCartItemUpdate;
      };
      branch_working_hours: {
        Row: DbBranchWorkingHour;
        Insert: DbBranchWorkingHourInsert;
        Update: DbBranchWorkingHourUpdate;
      };
      digital_files: {
        Row: DbDigitalFile;
        Insert: DbDigitalFileInsert;
        Update: DbDigitalFileUpdate;
      };
      digital_codes: {
        Row: DbDigitalCode;
        Insert: DbDigitalCodeInsert;
        Update: DbDigitalCodeUpdate;
      };
    };
    Views: {
      [_ in never]: never;
    };
    Functions: {
      [_ in never]: never;
    };
    Enums: {
      sync_status: 'pending' | 'syncing' | 'completed' | 'failed';
      order_status: 'pending' | 'processing' | 'shipped' | 'delivered' | 'cancelled' | 'refunded' | 'on-hold' | 'awaiting-shipment';
      payment_status: 'pending' | 'paid' | 'failed' | 'refunded' | 'partially-refunded' | 'authorized' | 'voided';
      product_status: 'sale' | 'hidden' | 'out';
    };
  };
}

// Store table
export interface DbStore {
  id: string;
  salla_store_id: string;
  name: string;
  description?: string;
  logo?: string;
  email: string;
  phone?: string;
  address?: string;
  city?: string;
  country?: string;
  currency: Currency;
  timezone: string;
  language: Language;
  commercial_registration?: string;
  tax_number?: string;
  status: Status;
  api_key?: string;
  webhook_secret?: string;
  last_sync?: Timestamp;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export type DbStoreInsert = Omit<DbStore, 'id' | 'created_at' | 'updated_at'>;
export type DbStoreUpdate = Partial<DbStoreInsert>;

// Product table
export interface DbProduct {
  id: string;
  store_id: string;
  salla_product_id: string;
  name: string;
  description?: string;
  price: number;
  sale_price?: number;
  cost_price?: number;
  quantity: number;
  unlimited_quantity?: boolean;
  sku?: string;
  mpn?: string;
  gtin?: string;
  weight?: number;
  weight_type?: 'kg' | 'g' | 'lb' | 'oz';
  requires_shipping: boolean;
  hide_quantity: boolean;
  status: 'sale' | 'hidden' | 'out';
  type: 'product' | 'service' | 'group_products' | 'codes' | 'digital';
  promotion_title?: string;
  subtitle?: string;
  seo_title?: string;
  seo_description?: string;
  images?: string[]; // References to product_images table
  thumbnail?: string; // Reference to product_images table
  categories?: string[];
  tags?: string[];
  brand_id?: string;
  brand?: string; // Reference to brands table
  options?: string[]; // References to product_options table
  variants?: string[]; // References to product_variants table
  metadata?: Record<string, unknown>;
  url?: string;
  rating?: string; // Reference to product_ratings table
  last_sync?: Timestamp;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export type DbProductInsert = Omit<DbProduct, 'id' | 'created_at' | 'updated_at'>;
export type DbProductUpdate = Partial<DbProductInsert>;

// Category table
export interface DbCategory {
  id: string;
  store_id: string;
  salla_category_id: string;
  name: string;
  description?: string;
  image?: string;
  parent_id?: string;
  sort_order: number;
  status: Status;
  seo_title?: string;
  seo_description?: string;
  last_sync?: Timestamp;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export type DbCategoryInsert = Omit<DbCategory, 'id' | 'created_at' | 'updated_at'>;
export type DbCategoryUpdate = Partial<DbCategoryInsert>;

// Customer table
export interface DbCustomer {
  id: string;
  store_id: string;
  salla_customer_id: string;
  first_name: string;
  last_name: string;
  email: string;
  phone?: string;
  mobile?: string;
  gender?: 'male' | 'female';
  birth_date?: string;
  city?: string;
  country?: string;
  avatar?: string;
  status: Status;
  email_verified: boolean;
  phone_verified: boolean;
  group_id?: string;
  group?: string; // Reference to customer_groups table
  addresses?: string[]; // References to customer_addresses table
  tags?: string[];
  notes?: string;
  metadata?: Record<string, unknown>;
  last_sync?: Timestamp;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export type DbCustomerInsert = Omit<DbCustomer, 'id' | 'created_at' | 'updated_at'>;
export type DbCustomerUpdate = Partial<DbCustomerInsert>;

// Order table
export interface DbOrder {
  id: string;
  store_id: string;
  salla_order_id: string;
  customer_id?: string;
  customer?: string; // Reference to customers table
  reference_id: string;
  status: 'pending' | 'processing' | 'shipped' | 'delivered' | 'cancelled' | 'refunded' | 'on-hold' | 'awaiting-shipment';
  payment_status: 'pending' | 'paid' | 'failed' | 'refunded' | 'partially-refunded' | 'authorized' | 'voided';
  total_amount: number;
  subtotal: number;
  tax_amount: number;
  shipping_cost: number;
  cash_on_delivery_cost?: number;
  discount_amount: number;
  coupon?: string; // Reference to coupons table
  currency: Currency;
  shipping_address?: string; // Reference to order_addresses table
  billing_address?: string; // Reference to order_addresses table
  payment_method?: string;
  shipping_company?: string; // Reference to shipping_companies table
  shipping_method?: string;
  tracking_url?: string;
  notes?: string;
  tags?: string[];
  order_date?: Timestamp;
  urls?: Record<string, unknown>;
  last_sync?: Timestamp;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export type DbOrderInsert = Omit<DbOrder, 'id' | 'created_at' | 'updated_at'>;
export type DbOrderUpdate = Partial<DbOrderInsert>;

// Order items table
export interface DbOrderItem {
  id: string;
  order_id: string;
  product_id?: string;
  salla_product_id: string;
  product?: string; // Reference to products table
  variant_id?: string;
  variant?: string; // Reference to product_variants table
  quantity: number;
  price: number;
  total: number;
  notes?: string;
  options?: string[]; // References to product_option_values table
  created_at: Timestamp;
  updated_at: Timestamp;
}

export type DbOrderItemInsert = Omit<DbOrderItem, 'id' | 'created_at' | 'updated_at'>;
export type DbOrderItemUpdate = Partial<DbOrderItemInsert>;

// Sync Logs table
export interface DbSyncLog {
  id: string;
  store_id: string;
  sync_type: 'products' | 'orders' | 'customers' | 'categories' | 'full';
  status: Database['public']['Enums']['sync_status'];
  started_at: Timestamp;
  completed_at?: Timestamp;
  records_processed: number;
  records_success: number;
  records_failed: number;
  error_message?: string;
  error_details?: Record<string, unknown>;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export type DbSyncLogInsert = Omit<DbSyncLog, 'id' | 'created_at' | 'updated_at'>;
export type DbSyncLogUpdate = Partial<DbSyncLogInsert>;

// Webhooks table
export interface DbWebhook {
  id: string;
  store_id: string;
  event: string;
  url: string;
  secret?: string;
  status: Status;
  last_triggered?: Timestamp;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export type DbWebhookInsert = Omit<DbWebhook, 'id' | 'created_at' | 'updated_at'>;
export type DbWebhookUpdate = Partial<DbWebhookInsert>;

// Brand table
export interface DbBrand {
  id: string;
  store_id: string;
  salla_brand_id: string;
  name: string;
  description?: string;
  logo?: string;
  website?: string;
  status: Status;
  last_sync?: Timestamp;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export type DbBrandInsert = Omit<DbBrand, 'id' | 'created_at' | 'updated_at'>;
export type DbBrandUpdate = Partial<DbBrandInsert>;

// Branch table
export interface DbBranch {
  id: string;
  store_id: string;
  salla_branch_id: string;
  name: string;
  status: Status;
  location?: {
    lat: string;
    lng: string;
  };
  street?: string;
  address_description?: string;
  additional_number?: string;
  building_number?: string;
  local?: string;
  postal_code?: string;
  contacts?: {
    phone?: string;
    whatsapp?: string;
    telephone?: string;
  };
  preparation_time?: string;
  is_open: boolean;
  closest_time?: string;
  working_hours?: string[]; // References to branch_working_hours table
  is_cod_available: boolean;
  is_default: boolean;
  type: string;
  cod_cost?: string;
  country_id?: string;
  city_id?: string;
  last_sync?: Timestamp;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export type DbBranchInsert = Omit<DbBranch, 'id' | 'created_at' | 'updated_at'>;
export type DbBranchUpdate = Partial<DbBranchInsert>;

// Currency table
export interface DbCurrency {
  id: string;
  store_id: string;
  salla_currency_id: string;
  code: string;
  name: string;
  symbol: string;
  exchange_rate: number;
  is_default: boolean;
  status: Status;
  last_sync?: Timestamp;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export type DbCurrencyInsert = Omit<DbCurrency, 'id' | 'created_at' | 'updated_at'>;
export type DbCurrencyUpdate = Partial<DbCurrencyInsert>;

// Country table
export interface DbCountry {
  id: string;
  salla_country_id: string;
  name: string;
  name_en: string;
  code: string;
  mobile_code: string;
  capital?: string;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export type DbCountryInsert = Omit<DbCountry, 'id' | 'created_at' | 'updated_at'>;
export type DbCountryUpdate = Partial<DbCountryInsert>;

// Tax table
export interface DbTax {
  id: string;
  store_id: string;
  salla_tax_id: string;
  name: string;
  rate: number;
  type: 'percentage' | 'fixed';
  status: Status;
  last_sync?: Timestamp;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export type DbTaxInsert = Omit<DbTax, 'id' | 'created_at' | 'updated_at'>;
export type DbTaxUpdate = Partial<DbTaxInsert>;

// Coupon table
export interface DbCoupon {
  id: string;
  store_id: string;
  salla_coupon_id: string;
  name: string;
  code: string;
  type: 'percentage' | 'fixed';
  amount: number;
  minimum_amount?: number;
  maximum_amount?: number;
  usage_limit?: number;
  used_count: number;
  start_date?: Timestamp;
  end_date?: Timestamp;
  status: Status;
  last_sync?: Timestamp;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export type DbCouponInsert = Omit<DbCoupon, 'id' | 'created_at' | 'updated_at'>;
export type DbCouponUpdate = Partial<DbCouponInsert>;

// Coupon Code table
export interface DbCouponCode {
  id: string;
  coupon_id: string;
  code: string;
  is_used: boolean;
  used_by?: string;
  used_at?: Timestamp;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export type DbCouponCodeInsert = Omit<DbCouponCode, 'id' | 'created_at' | 'updated_at'>;
export type DbCouponCodeUpdate = Partial<DbCouponCodeInsert>;

// Special Offer table
export interface DbSpecialOffer {
  id: string;
  store_id: string;
  salla_offer_id: string;
  name: string;
  description?: string;
  type: string;
  discount_type: 'percentage' | 'fixed';
  discount_amount: number;
  start_date?: Timestamp;
  end_date?: Timestamp;
  status: Status;
  conditions?: Record<string, unknown>;
  last_sync?: Timestamp;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export type DbSpecialOfferInsert = Omit<DbSpecialOffer, 'id' | 'created_at' | 'updated_at'>;
export type DbSpecialOfferUpdate = Partial<DbSpecialOfferInsert>;

// Affiliate table
export interface DbAffiliate {
  id: string;
  store_id: string;
  salla_affiliate_id: string;
  name: string;
  email: string;
  phone?: string;
  commission_rate: number;
  commission_type: 'percentage' | 'fixed';
  status: Status;
  total_sales: number;
  total_commission: number;
  last_sync?: Timestamp;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export type DbAffiliateInsert = Omit<DbAffiliate, 'id' | 'created_at' | 'updated_at'>;
export type DbAffiliateUpdate = Partial<DbAffiliateInsert>;

// Transaction table
export interface DbTransaction {
  id: string;
  store_id: string;
  salla_transaction_id: string;
  order_id?: string;
  type: 'payment' | 'refund' | 'partial_refund';
  amount: number;
  currency: Currency;
  status: 'pending' | 'completed' | 'failed' | 'cancelled';
  payment_method?: string;
  gateway?: string;
  gateway_transaction_id?: string;
  notes?: string;
  metadata?: Record<string, unknown>;
  processed_at?: Timestamp;
  last_sync?: Timestamp;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export type DbTransactionInsert = Omit<DbTransaction, 'id' | 'created_at' | 'updated_at'>;
export type DbTransactionUpdate = Partial<DbTransactionInsert>;

// Payment Method table
export interface DbPaymentMethod {
  id: string;
  store_id: string;
  salla_method_id: string;
  name: string;
  code: string;
  type: string;
  is_active: boolean;
  settings?: Record<string, unknown>;
  last_sync?: Timestamp;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export type DbPaymentMethodInsert = Omit<DbPaymentMethod, 'id' | 'created_at' | 'updated_at'>;
export type DbPaymentMethodUpdate = Partial<DbPaymentMethodInsert>;

// Payment Bank table
export interface DbPaymentBank {
  id: string;
  salla_bank_id: string;
  name: string;
  code: string;
  logo?: string;
  is_active: boolean;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export type DbPaymentBankInsert = Omit<DbPaymentBank, 'id' | 'created_at' | 'updated_at'>;
export type DbPaymentBankUpdate = Partial<DbPaymentBankInsert>;

// Settlement table
export interface DbSettlement {
  id: string;
  store_id: string;
  salla_settlement_id: string;
  amount: number;
  currency: Currency;
  status: 'pending' | 'processing' | 'completed' | 'failed';
  type: 'instant' | 'scheduled';
  bank_account?: Record<string, unknown>;
  processed_at?: Timestamp;
  last_sync?: Timestamp;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export type DbSettlementInsert = Omit<DbSettlement, 'id' | 'created_at' | 'updated_at'>;
export type DbSettlementUpdate = Partial<DbSettlementInsert>;

// Shipment table
export interface DbShipment {
  id: string;
  store_id: string;
  salla_shipment_id: string;
  order_id: string;
  tracking_number?: string;
  tracking_url?: string;
  shipping_company_id?: string;
  shipping_company?: Record<string, unknown>;
  status: 'pending' | 'processing' | 'shipped' | 'delivered' | 'returned' | 'cancelled';
  shipped_at?: Timestamp;
  delivered_at?: Timestamp;
  notes?: string;
  last_sync?: Timestamp;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export type DbShipmentInsert = Omit<DbShipment, 'id' | 'created_at' | 'updated_at'>;
export type DbShipmentUpdate = Partial<DbShipmentInsert>;

// Shipping Company table
export interface DbShippingCompany {
  id: string;
  store_id: string;
  salla_company_id: string;
  name: string;
  logo?: string;
  website?: string;
  tracking_url?: string;
  is_active: boolean;
  settings?: Record<string, unknown>;
  last_sync?: Timestamp;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export type DbShippingCompanyInsert = Omit<DbShippingCompany, 'id' | 'created_at' | 'updated_at'>;
export type DbShippingCompanyUpdate = Partial<DbShippingCompanyInsert>;

// Shipping Zone table
export interface DbShippingZone {
  id: string;
  store_id: string;
  salla_zone_id: string;
  name: string;
  countries: string[];
  cities?: string[];
  is_active: boolean;
  last_sync?: Timestamp;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export type DbShippingZoneInsert = Omit<DbShippingZone, 'id' | 'created_at' | 'updated_at'>;
export type DbShippingZoneUpdate = Partial<DbShippingZoneInsert>;

// Customer Group table
export interface DbCustomerGroup {
  id: string;
  store_id: string;
  salla_group_id: string;
  name: string;
  description?: string;
  discount_percentage?: number;
  is_default: boolean;
  last_sync?: Timestamp;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export type DbCustomerGroupInsert = Omit<DbCustomerGroup, 'id' | 'created_at' | 'updated_at'>;
export type DbCustomerGroupUpdate = Partial<DbCustomerGroupInsert>;

// Abandoned Cart table
export interface DbAbandonedCart {
  id: string;
  store_id: string;
  salla_cart_id: string;
  customer_id?: string;
  customer_email?: string;
  items: string[]; // References to abandoned_cart_items table
  total_amount: number;
  currency: Currency;
  abandoned_at: Timestamp;
  recovered_at?: Timestamp;
  recovery_email_sent: boolean;
  last_sync?: Timestamp;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export type DbAbandonedCartInsert = Omit<DbAbandonedCart, 'id' | 'created_at' | 'updated_at'>;
export type DbAbandonedCartUpdate = Partial<DbAbandonedCartInsert>;

// Product Tag table
export interface DbProductTag {
  id: string;
  store_id: string;
  salla_tag_id: string;
  name: string;
  slug: string;
  last_sync?: Timestamp;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export type DbProductTagInsert = Omit<DbProductTag, 'id' | 'created_at' | 'updated_at'>;
export type DbProductTagUpdate = Partial<DbProductTagInsert>;

// Order Tag table
export interface DbOrderTag {
  id: string;
  store_id: string;
  salla_tag_id: string;
  name: string;
  color?: string;
  last_sync?: Timestamp;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export type DbOrderTagInsert = Omit<DbOrderTag, 'id' | 'created_at' | 'updated_at'>;
export type DbOrderTagUpdate = Partial<DbOrderTagInsert>;

// Product Option table
export interface DbProductOption {
  id: string;
  store_id: string;
  product_id: string;
  salla_option_id: string;
  name: string;
  type: 'text' | 'textarea' | 'select' | 'radio' | 'checkbox' | 'file';
  required: boolean;
  values?: string[]; // References to product_option_values table
  last_sync?: Timestamp;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export type DbProductOptionInsert = Omit<DbProductOption, 'id' | 'created_at' | 'updated_at'>;
export type DbProductOptionUpdate = Partial<DbProductOptionInsert>;

// Product Variant table
export interface DbProductVariant {
  id: string;
  store_id: string;
  product_id: string;
  salla_variant_id: string;
  name: string;
  sku?: string;
  price: number;
  sale_price?: number;
  quantity: number;
  weight?: number;
  options: string[]; // References to product_option_values table
  image?: string; // Reference to product_images table
  status: Status;
  last_sync?: Timestamp;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export type DbProductVariantInsert = Omit<DbProductVariant, 'id' | 'created_at' | 'updated_at'>;
export type DbProductVariantUpdate = Partial<DbProductVariantInsert>;

// Product images table
export interface DbProductImage {
  id: string;
  store_id: string;
  product_id: string;
  salla_image_id: string;
  url: string;
  thumbnail?: string;
  original?: string;
  alt?: string;
  sort_order: number;
  is_main: boolean;
  type: 'image' | 'video';
  video_url?: string;
  three_d_image_url?: string;
  last_sync?: Timestamp;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export type DbProductImageInsert = Omit<DbProductImage, 'id' | 'created_at' | 'updated_at'>;
export type DbProductImageUpdate = Partial<DbProductImageInsert>;

// Product option values table
export interface DbProductOptionValue {
  id: string;
  store_id: string;
  option_id: string;
  salla_value_id: string;
  name: string;
  display_value?: string;
  price: number;
  quantity?: number;
  image_url?: string;
  is_default: boolean;
  is_out_of_stock: boolean;
  sort_order: number;
  last_sync?: Timestamp;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export type DbProductOptionValueInsert = Omit<DbProductOptionValue, 'id' | 'created_at' | 'updated_at'>;
export type DbProductOptionValueUpdate = Partial<DbProductOptionValueInsert>;

// Customer addresses table
export interface DbCustomerAddress {
  id: string;
  store_id: string;
  customer_id: string;
  type: 'shipping' | 'billing';
  first_name: string;
  last_name: string;
  company?: string;
  address_line_1: string;
  address_line_2?: string;
  city: string;
  state?: string;
  postal_code?: string;
  country: string;
  phone?: string;
  is_default: boolean;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export type DbCustomerAddressInsert = Omit<DbCustomerAddress, 'id' | 'created_at' | 'updated_at'>;
export type DbCustomerAddressUpdate = Partial<DbCustomerAddressInsert>;

// Order addresses table
export interface DbOrderAddress {
  id: string;
  store_id: string;
  order_id: string;
  type: 'shipping' | 'billing';
  first_name: string;
  last_name: string;
  company?: string;
  address_line_1: string;
  address_line_2?: string;
  city: string;
  state?: string;
  postal_code?: string;
  country: string;
  phone?: string;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export type DbOrderAddressInsert = Omit<DbOrderAddress, 'id' | 'created_at' | 'updated_at'>;
export type DbOrderAddressUpdate = Partial<DbOrderAddressInsert>;

// Product ratings table
export interface DbProductRating {
  id: string;
  store_id: string;
  product_id: string;
  customer_id?: string;
  rating: number;
  review?: string;
  status: 'pending' | 'approved' | 'rejected';
  created_at: Timestamp;
  updated_at: Timestamp;
}

export type DbProductRatingInsert = Omit<DbProductRating, 'id' | 'created_at' | 'updated_at'>;
export type DbProductRatingUpdate = Partial<DbProductRatingInsert>;

// Abandoned cart items table
export interface DbAbandonedCartItem {
  id: string;
  store_id: string;
  cart_id: string;
  product_id: string;
  variant_id?: string;
  quantity: number;
  price: number;
  total: number;
  options?: string; // JSON string of selected options
  created_at: Timestamp;
  updated_at: Timestamp;
}

export type DbAbandonedCartItemInsert = Omit<DbAbandonedCartItem, 'id' | 'created_at' | 'updated_at'>;
export type DbAbandonedCartItemUpdate = Partial<DbAbandonedCartItemInsert>;

// Branch working hours table
export interface DbBranchWorkingHour {
  id: string;
  store_id: string;
  branch_id: string;
  day: 'sunday' | 'monday' | 'tuesday' | 'wednesday' | 'thursday' | 'friday' | 'saturday';
  is_open: boolean;
  open_time?: string;
  close_time?: string;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export type DbBranchWorkingHourInsert = Omit<DbBranchWorkingHour, 'id' | 'created_at' | 'updated_at'>;
export type DbBranchWorkingHourUpdate = Partial<DbBranchWorkingHourInsert>;

// Digital files table
export interface DbDigitalFile {
  id: string;
  store_id: string;
  product_id: string;
  salla_file_id: string;
  name: string;
  file_url: string;
  file_size?: number;
  file_type?: string;
  download_limit?: number;
  expiry_days?: number;
  last_sync?: Timestamp;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export type DbDigitalFileInsert = Omit<DbDigitalFile, 'id' | 'created_at' | 'updated_at'>;
export type DbDigitalFileUpdate = Partial<DbDigitalFileInsert>;

// Digital codes table
export interface DbDigitalCode {
  id: string;
  store_id: string;
  product_id: string;
  code: string;
  is_used: boolean;
  used_by?: string;
  used_at?: Timestamp;
  order_id?: string;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export type DbDigitalCodeInsert = Omit<DbDigitalCode, 'id' | 'created_at' | 'updated_at'>;
export type DbDigitalCodeUpdate = Partial<DbDigitalCodeInsert>;



// Supabase client configuration
export interface SupabaseConfig {
  url: string;
  anonKey: string;
  serviceRoleKey?: string;
}

// Real-time subscription types
export interface RealtimeSubscription {
  table: keyof Database['public']['Tables'];
  event: 'INSERT' | 'UPDATE' | 'DELETE' | '*';
  filter?: string;
}

// Query builder types
export type SupabaseQuery<T> = {
  data: T[] | null;
  error: SupabaseError | null;
  count?: number;
};

export interface SupabaseError {
  message: string;
  details?: string;
  hint?: string;
  code?: string;
}

// Auth types
export interface SupabaseUser {
  id: string;
  email?: string;
  phone?: string;
  created_at: string;
  updated_at: string;
  last_sign_in_at?: string;
  app_metadata: Record<string, unknown>;
  user_metadata: Record<string, unknown>;
}

export interface SupabaseSession {
  access_token: string;
  refresh_token: string;
  expires_in: number;
  expires_at: number;
  token_type: string;
  user: SupabaseUser;
}

// Storage types
export interface SupabaseStorageObject {
  name: string;
  id: string;
  updated_at: string;
  created_at: string;
  last_accessed_at: string;
  metadata: Record<string, unknown>;
}

export interface SupabaseUploadOptions {
  cacheControl?: string;
  contentType?: string;
  upsert?: boolean;
}