/**
 * Supabase type definitions
 * Database schema and API types for the sync application
 */

import type { ID, Timestamp, Currency, Language, Status } from './index';

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
  images?: Record<string, unknown>[];
  thumbnail?: Record<string, unknown>;
  categories?: string[];
  tags?: string[];
  brand_id?: string;
  brand?: Record<string, unknown>;
  options?: Record<string, unknown>[];
  variants?: Record<string, unknown>[];
  metadata?: Record<string, unknown>;
  url?: string;
  rating?: Record<string, unknown>;
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
  group?: Record<string, unknown>;
  addresses?: Record<string, unknown>[];
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
  customer?: Record<string, unknown>;
  reference_id: string;
  status: 'pending' | 'processing' | 'shipped' | 'delivered' | 'cancelled' | 'refunded' | 'on-hold' | 'awaiting-shipment';
  payment_status: 'pending' | 'paid' | 'failed' | 'refunded' | 'partially-refunded' | 'authorized' | 'voided';
  total_amount: number;
  subtotal: number;
  tax_amount: number;
  shipping_cost: number;
  cash_on_delivery_cost?: number;
  discount_amount: number;
  coupon?: Record<string, unknown>;
  currency: Currency;
  shipping_address?: Record<string, unknown>;
  billing_address?: Record<string, unknown>;
  payment_method?: string;
  shipping_company?: Record<string, unknown>;
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
  product?: Record<string, unknown>;
  variant_id?: string;
  variant?: Record<string, unknown>;
  quantity: number;
  price: number;
  total: number;
  notes?: string;
  options?: Record<string, unknown>[];
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