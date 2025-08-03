/**
 * Salla API type definitions
 * Based on Salla API documentation and requirements
 */

import type { ID, Timestamp, Currency, Language, Status } from './index';

// Store related types
export interface SallaStore {
  id: ID;
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
  created_at: Timestamp;
  updated_at: Timestamp;
  api_key?: string;
  webhook_secret?: string;
}

// Product related types
export interface SallaProduct {
  id: ID;
  store_id?: ID;
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
  images?: SallaProductImage[];
  thumbnail?: SallaProductImage;
  categories?: ID[];
  tags?: string[];
  brand_id?: ID;
  brand?: SallaBrand;
  options?: SallaProductOption[];
  variants?: SallaProductVariant[];
  metadata?: Record<string, unknown>;
  url?: string;
  rating?: {
    count: number;
    stars: number;
  };
  created_at: Timestamp;
  updated_at: Timestamp;
}

export interface SallaProductImage {
  id: ID;
  url: string;
  alt?: string;
  main?: boolean;
}

export interface SallaProductOption {
  id: ID;
  name: string;
  display_type: 'text' | 'color' | 'image';
  values: SallaProductOptionValue[];
}

export interface SallaProductOptionValue {
  id: ID;
  name: string;
  display_value?: string;
  image?: string;
}

export interface SallaProductVariant {
  id: ID;
  sku?: string;
  price: number;
  sale_price?: number;
  quantity: number;
  weight?: number;
  options: Record<string, string>;
  image?: string;
}

export interface SallaBrand {
  id: ID;
  name: string;
  logo?: string;
  website?: string;
}

// Category related types
export interface SallaCategory {
  id: ID;
  store_id: ID;
  name: string;
  description?: string;
  image?: string;
  parent_id?: ID;
  sort_order: number;
  status: Status;
  seo_title?: string;
  seo_description?: string;
  created_at: Timestamp;
  updated_at: Timestamp;
}

// Customer related types
export interface SallaCustomer {
  id: ID;
  store_id?: ID;
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
  group_id?: ID;
  group?: SallaCustomerGroup;
  addresses?: SallaAddress[];
  tags?: string[];
  notes?: string;
  metadata?: Record<string, unknown>;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export interface SallaCustomerGroup {
  id: ID;
  name: string;
  description?: string;
  discount_percentage?: number;
}

// Order related types
export interface SallaOrder {
  id: ID;
  store_id?: ID;
  customer_id?: ID;
  customer?: SallaCustomer;
  reference_id: string;
  status: SallaOrderStatus;
  payment_status: SallaPaymentStatus;
  total: {
    amount: number;
    currency: Currency;
  };
  subtotal: number;
  tax_amount: number;
  shipping_cost: number;
  cash_on_delivery_cost?: number;
  discount_amount: number;
  coupon?: {
    id: ID;
    code: string;
    amount: number;
  };
  currency: Currency;
  items: SallaOrderItem[];
  shipping_address?: SallaAddress;
  billing_address?: SallaAddress;
  payment_method?: string;
  shipping_company?: {
    id: ID;
    name: string;
  };
  shipping_method?: string;
  tracking_url?: string;
  notes?: string;
  tags?: string[];
  date: {
    date: string;
    timezone: string;
  };
  urls?: {
    customer: string;
    admin: string;
  };
  created_at: Timestamp;
  updated_at: Timestamp;
}

export type SallaOrderStatus = 
  | 'pending'
  | 'processing' 
  | 'shipped'
  | 'delivered'
  | 'cancelled'
  | 'refunded'
  | 'on-hold'
  | 'awaiting-shipment';

export type SallaPaymentStatus = 
  | 'pending'
  | 'paid'
  | 'failed'
  | 'refunded'
  | 'partially-refunded'
  | 'authorized'
  | 'voided';

export interface SallaOrderItem {
  id: ID;
  order_id: ID;
  product_id: ID;
  product?: {
    id: ID;
    name: string;
    sku?: string;
    image?: string;
    url?: string;
  };
  variant_id?: ID;
  variant?: SallaProductVariant;
  quantity: number;
  price: number;
  total: number;
  notes?: string;
  options?: SallaOrderItemOption[];
}

export interface SallaOrderItemOption {
  name: string;
  value: string;
  display_value?: string;
}



export interface SallaAddress {
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
}

// Webhook related types
export interface SallaWebhook {
  id: ID;
  store_id: ID;
  event: SallaWebhookEvent;
  url: string;
  secret?: string;
  status: Status;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export type SallaWebhookEvent = 
  // Order events
  | 'order.created'
  | 'order.updated'
  | 'order.status.updated'
  | 'order.cancelled'
  | 'order.refunded'
  | 'order.payment.updated'
  | 'order.shipped'
  | 'order.delivered'
  // Product events
  | 'product.created'
  | 'product.updated'
  | 'product.deleted'
  | 'product.available'
  | 'product.quantity.low'
  // Customer events
  | 'customer.created'
  | 'customer.updated'
  | 'customer.login'
  | 'customer.otp.request'
  // Category events
  | 'category.created'
  | 'category.updated'
  | 'category.deleted'
  // Store events
  | 'store.updated'
  | 'store.branch.created'
  | 'store.branch.updated'
  | 'store.branch.activated'
  | 'store.branch.setAsMain'
  // Coupon events
  | 'coupon.created'
  | 'coupon.updated'
  // Special offer events
  | 'specialoffer.created'
  | 'specialoffer.updated'
  // Review events
  | 'review.added'
  // Shipping events
  | 'shipping.zone.created'
  | 'shipping.zone.updated'
  // App events
  | 'app.store.authorize'
  | 'app.installed'
  | 'app.updated';

export interface SallaWebhookPayload {
  event: SallaWebhookEvent;
  created: Timestamp;
  data: {
    object: SallaOrder | SallaProduct | SallaCustomer | SallaStore;
  };
}

// API Configuration
export interface SallaApiConfig {
  baseUrl: string;
  apiKey: string;
  storeId: ID;
  timeout?: number;
  retries?: number;
}

// API Response types specific to Salla
export interface SallaApiResponse<T = unknown> {
  status: number;
  success: boolean;
  data?: T;
  error?: {
    type: string;
    message: string;
    fields?: Record<string, string[]>;
  };
  pagination?: {
    count: number;
    total: number;
    perPage: number;
    currentPage: number;
    totalPages: number;
    links: {
      previous?: string;
      next?: string;
    };
  };
}

// Sync status types
export interface SallaSyncStatus {
  store_id: ID;
  last_sync: Timestamp;
  sync_status: 'idle' | 'syncing' | 'error' | 'completed';
  synced_products: number;
  synced_orders: number;
  synced_customers: number;
  errors?: string[];
}