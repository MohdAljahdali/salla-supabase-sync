/**
 * Salla API type definitions
 * Based on Salla API documentation and requirements
 * Updated with complete API coverage from Salla Docs
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
  mobile?: string;
  address?: string;
  city?: string;
  state?: string;
  country?: string;
  postal_code?: string;
  currency: Currency;
  timezone: string;
  language: Language;
  commercial_registration?: string;
  tax_number?: string;
  vat_number?: string;
  status: Status;
  domain?: string;
  plan?: string;
  subscription_reference?: string;
  trial_ends_at?: Timestamp;
  created_at: Timestamp;
  updated_at: Timestamp;
  api_key?: string;
  webhook_secret?: string;
  settings?: Record<string, unknown>;
  social_links?: {
    facebook?: string;
    twitter?: string;
    instagram?: string;
    youtube?: string;
    linkedin?: string;
    snapchat?: string;
    tiktok?: string;
  };
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
  require_shipping?: boolean; // Alternative naming
  hide_quantity: boolean;
  status: 'sale' | 'hidden' | 'out';
  type: 'product' | 'service' | 'group_products' | 'codes' | 'digital' | 'booking';
  product_type?: 'product' | 'service' | 'group_products' | 'codes' | 'digital' | 'booking';
  promotion_title?: string;
  subtitle?: string;
  seo_title?: string;
  seo_description?: string;
  metadata_title?: string;
  metadata_description?: string;
  images?: SallaProductImage[];
  thumbnail?: SallaProductImage;
  main_image?: string;
  categories?: ID[];
  tags?: (string | ID)[];
  brand_id?: ID;
  brand?: SallaBrand;
  options?: SallaProductOption[];
  variants?: SallaProductVariant[];
  metadata?: Record<string, unknown>;
  url?: string;
  urls?: {
    customer: string;
    admin: string;
  };
  rating?: {
    count: number;
    stars: number;
    total?: number;
    rate?: number;
  };
  views?: number;
  sold_quantity?: number;
  notify_quantity?: number;
  maximum_quantity_per_order?: number;
  max_items_per_user?: number;
  min_amount_donating?: number;
  max_amount_donating?: number;
  sale_end?: string;
  pinned?: boolean;
  is_pinned?: boolean;
  pinned_date?: Timestamp;
  sort?: number;
  enable_upload_image?: boolean;
  enable_note?: boolean;
  allow_attachments?: boolean;
  active_advance?: boolean;
  show_in_app?: boolean;
  managed_by_branches?: boolean;
  with_tax?: boolean;
  calories?: number;
  starting_price?: number;
  channels?: string[];
  digital_files?: SallaDigitalFile[];
  digital_codes?: SallaDigitalCode[];
  booking_details?: SallaBookingDetails;
  services_blocks?: {
    installments?: unknown[];
  };
  created_at: Timestamp;
  updated_at: Timestamp;
}

export interface SallaProductImage {
  id: ID;
  url: string;
  original?: string;
  thumbnail?: string;
  alt?: string;
  main?: boolean;
  default?: boolean;
  sort?: number;
  three_d_image_url?: string;
  video_url?: string;
  type?: 'image' | 'video';
}

export interface SallaProductOption {
  id: ID;
  name: string;
  description?: string;
  type?: string;
  display_type: 'text' | 'color' | 'image';
  required?: boolean;
  associated_with_order_time?: number;
  availability_range?: boolean;
  not_same_day_order?: boolean;
  choose_date_time?: string;
  from_date_time?: string;
  to_date_time?: string;
  sort?: number;
  advance?: boolean;
  visibility?: 'always' | 'conditional';
  translations?: Record<string, {
    option_name?: string;
    description?: string;
  }>;
  values: SallaProductOptionValue[];
}

export interface SallaProductOptionValue {
  id: ID;
  name: string;
  display_value?: string;
  hashed_display_value?: string;
  image?: string;
  image_url?: string;
  price?: {
    amount: number;
    currency: Currency;
  };
  formatted_price?: string;
  quantity?: number;
  advance?: boolean;
  option_id?: ID;
  translations?: Record<string, {
    option_details_name?: string;
  }>;
  is_default?: boolean;
  is_out_of_stock?: boolean;
}

export interface SallaProductVariant {
  id: ID;
  product_id?: ID;
  sku?: string;
  price: number;
  sale_price?: number;
  cost_price?: number;
  quantity: number;
  weight?: number;
  weight_type?: 'kg' | 'g' | 'lb' | 'oz';
  options: Record<string, string>;
  option_values?: Record<string, ID>;
  image?: string;
  images?: SallaProductImage[];
  status?: 'active' | 'inactive';
  unlimited_quantity?: boolean;
  notify_quantity?: number;
  created_at?: Timestamp;
  updated_at?: Timestamp;
}

export interface SallaBrand {
  id: ID;
  name: string;
  description?: string;
  logo?: string;
  website?: string;
  status?: Status;
  sort_order?: number;
  seo_title?: string;
  seo_description?: string;
  created_at?: Timestamp;
  updated_at?: Timestamp;
}

export interface SallaDigitalFile {
  id: ID;
  name: string;
  file_url: string;
  file_size?: number;
  file_type?: string;
  download_limit?: number;
  download_expiry?: number;
  created_at?: Timestamp;
  updated_at?: Timestamp;
}

export interface SallaDigitalCode {
  id: ID;
  code: string;
  status: 'available' | 'used' | 'expired';
  used_at?: Timestamp;
  expires_at?: Timestamp;
  created_at?: Timestamp;
  updated_at?: Timestamp;
}

export interface SallaBookingDetails {
  id?: ID;
  duration?: number;
  duration_type?: 'minutes' | 'hours' | 'days';
  buffer_time?: number;
  max_bookings_per_day?: number;
  advance_booking_days?: number;
  booking_window_start?: string;
  booking_window_end?: string;
  available_days?: string[];
  time_slots?: SallaTimeSlot[];
  location?: string;
  instructions?: string;
  cancellation_policy?: string;
  created_at?: Timestamp;
  updated_at?: Timestamp;
}

export interface SallaTimeSlot {
  id: ID;
  start_time: string;
  end_time: string;
  capacity?: number;
  available?: boolean;
  price?: number;
  day_of_week?: number;
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



// Order related types
export interface SallaOrder {
  id: ID;
  store_id?: ID;
  customer_id?: ID;
  customer?: SallaCustomer;
  reference_id: string;
  status: SallaOrderStatus;
  payment_status: SallaPaymentStatus;
  shipping_status?: SallaShippingStatus;
  fulfillment_status?: 'pending' | 'processing' | 'shipped' | 'delivered' | 'cancelled';
  total: {
    amount: number;
    currency: Currency;
  };
  subtotal: {
    amount: number;
    currency: Currency;
  };
  shipping: {
    amount: number;
    currency: Currency;
  };
  tax: {
    amount: number;
    currency: Currency;
  };
  discount: {
    amount: number;
    currency: Currency;
  };
  cod_cost?: {
    amount: number;
    currency: Currency;
  };
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
  payment_method_name?: string;
  shipping_company?: {
    id: ID;
    name: string;
  };
  shipping_method?: string;
  tracking_number?: string;
  tracking_url?: string;
  notes?: string;
  admin_notes?: string;
  tags?: string[];
  branch_id?: ID;
  branch?: SallaBranch;
  source?: 'web' | 'mobile' | 'api' | 'pos';
  currency_rate?: number;
  date: {
    date: string;
    timezone: string;
  };
  urls?: {
    customer: string;
    admin: string;
  };
  can_cancel?: boolean;
  can_return?: boolean;
  can_edit?: boolean;
  weight?: number;
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

export type SallaShippingStatus = 
  | 'pending'
  | 'processing'
  | 'shipped'
  | 'delivered'
  | 'cancelled'
  | 'returned';

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
  price: {
    amount: number;
    currency: Currency;
  };
  total: {
    amount: number;
    currency: Currency;
  };
  unit_price?: {
    amount: number;
    currency: Currency;
  };
  notes?: string;
  special_notes?: string;
  options?: SallaOrderItemOption[];
  option_values?: SallaProductOptionValue[];
  weight?: number;
  sku?: string;
  image?: string;
  product_name?: string;
  product_type?: string;
  digital_files?: SallaDigitalFile[];
  created_at?: Timestamp;
  updated_at?: Timestamp;
}

export interface SallaOrderItemOption {
  id: ID;
  name: string;
  value: string;
  display_value?: string;
  price?: {
    amount: number;
    currency: Currency;
  };
}

export interface SallaAddress {
  id?: ID;
  customer_id?: ID;
  type?: 'shipping' | 'billing';
  first_name?: string;
  last_name?: string;
  company?: string;
  address_line_1: string;
  address_line_2?: string;
  city: string;
  state?: string;
  postal_code?: string;
  country: string;
  country_code?: string;
  phone?: string;
  email?: string;
  is_default?: boolean;
  latitude?: number;
  longitude?: number;
  description?: string;
  created_at?: Timestamp;
  updated_at?: Timestamp;
}

// Invoice related types
export interface SallaInvoice {
  id: ID;
  order_id?: ID;
  order?: SallaOrder;
  invoice_number: string;
  status: 'draft' | 'sent' | 'paid' | 'overdue' | 'cancelled';
  total: {
    amount: number;
    currency: Currency;
  };
  subtotal: {
    amount: number;
    currency: Currency;
  };
  tax: {
    amount: number;
    currency: Currency;
  };
  discount?: {
    amount: number;
    currency: Currency;
  };
  items: SallaInvoiceItem[];
  due_date?: string;
  issued_date: string;
  paid_date?: string;
  notes?: string;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export interface SallaInvoiceItem {
  id: ID;
  invoice_id: ID;
  product_id?: ID;
  product?: SallaProduct;
  description: string;
  quantity: number;
  unit_price: {
    amount: number;
    currency: Currency;
  };
  total: {
    amount: number;
    currency: Currency;
  };
  tax_rate?: number;
  discount_rate?: number;
}

// Branch related types
export interface SallaBranch {
  id: ID;
  name: string;
  description?: string;
  address?: string;
  city?: string;
  state?: string;
  country?: string;
  postal_code?: string;
  phone?: string;
  email?: string;
  manager_name?: string;
  status: Status;
  is_default?: boolean;
  latitude?: number;
  longitude?: number;
  working_hours?: SallaWorkingHours[];
  created_at: Timestamp;
  updated_at: Timestamp;
}

export interface SallaWorkingHours {
  day: 'monday' | 'tuesday' | 'wednesday' | 'thursday' | 'friday' | 'saturday' | 'sunday';
  is_open: boolean;
  opening_time?: string;
  closing_time?: string;
  break_start?: string;
  break_end?: string;
}

// Shipping related types
export interface SallaShippingCompany {
  id: ID;
  name: string;
  description?: string;
  logo?: string;
  tracking_url?: string;
  status: Status;
  cod_support?: boolean;
  insurance_support?: boolean;
  created_at?: Timestamp;
  updated_at?: Timestamp;
}

// Coupon related types
export interface SallaCoupon {
  id: ID;
  name: string;
  code: string;
  description?: string;
  type: 'fixed' | 'percentage';
  amount: number;
  minimum_amount?: number;
  maximum_amount?: number;
  usage_limit?: number;
  usage_limit_per_customer?: number;
  used_count?: number;
  start_date?: string;
  end_date?: string;
  status: Status;
  applicable_products?: ID[];
  applicable_categories?: ID[];
  applicable_customers?: ID[];
  exclude_products?: ID[];
  exclude_categories?: ID[];
  exclude_customers?: ID[];
  created_at: Timestamp;
  updated_at: Timestamp;
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

// Tax related types
export interface SallaTax {
  id: ID;
  name: string;
  description?: string;
  rate: number;
  type: 'percentage' | 'fixed';
  status: Status;
  applicable_countries?: string[];
  applicable_states?: string[];
  applicable_cities?: string[];
  applicable_products?: ID[];
  applicable_categories?: ID[];
  priority?: number;
  created_at: Timestamp;
  updated_at: Timestamp;
}

// Currency related types
export interface SallaCurrency {
  id: ID;
  code: string;
  name: string;
  symbol: string;
  exchange_rate: number;
  decimal_places: number;
  status: Status;
  is_default?: boolean;
  created_at?: Timestamp;
  updated_at?: Timestamp;
}

// Zone related types
export interface SallaZone {
  id: ID;
  name: string;
  description?: string;
  countries: SallaCountry[];
  states?: SallaState[];
  cities?: SallaCity[];
  status: Status;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export interface SallaCountry {
  id: ID;
  name: string;
  code: string;
  currency?: string;
  phone_code?: string;
  status: Status;
}

export interface SallaState {
  id: ID;
  name: string;
  code?: string;
  country_id: ID;
  country?: SallaCountry;
  status: Status;
}

export interface SallaCity {
  id: ID;
  name: string;
  state_id?: ID;
  state?: SallaState;
  country_id: ID;
  country?: SallaCountry;
  status: Status;
}

// Shipping Rule related types
export interface SallaShippingRule {
  id: ID;
  name: string;
  description?: string;
  shipping_company_id?: ID;
  shipping_company?: SallaShippingCompany;
  zones?: ID[];
  min_weight?: number;
  max_weight?: number;
  min_price?: number;
  max_price?: number;
  cost: number;
  cost_type: 'fixed' | 'percentage' | 'per_item' | 'per_weight';
  free_shipping_threshold?: number;
  delivery_time?: string;
  status: Status;
  priority?: number;
  created_at: Timestamp;
  updated_at: Timestamp;
}

// Tag related types
export interface SallaTag {
  id: ID;
  name: string;
  description?: string;
  color?: string;
  type?: 'product' | 'order' | 'customer';
  usage_count?: number;
  created_at?: Timestamp;
  updated_at?: Timestamp;
}





// Special Offer related types
export interface SallaSpecialOffer {
  id: ID;
  name: string;
  description?: string;
  type: 'buy_x_get_y' | 'quantity_discount' | 'bundle' | 'free_shipping';
  status: Status;
  start_date?: string;
  end_date?: string;
  usage_limit?: number;
  usage_limit_per_customer?: number;
  used_count?: number;
  conditions: SallaOfferCondition[];
  rewards: SallaOfferReward[];
  applicable_products?: ID[];
  applicable_categories?: ID[];
  applicable_customers?: ID[];
  created_at: Timestamp;
  updated_at: Timestamp;
}

export interface SallaOfferCondition {
  type: 'min_quantity' | 'min_amount' | 'specific_products';
  value: number | string;
  products?: ID[];
}

export interface SallaOfferReward {
  type: 'discount_percentage' | 'discount_fixed' | 'free_product' | 'free_shipping';
  value: number | string;
  products?: ID[];
}

// Transaction related types
export interface SallaTransaction {
  id: ID;
  order_id?: ID;
  order?: SallaOrder;
  reference_id: string;
  type: 'payment' | 'refund' | 'partial_refund';
  status: 'pending' | 'completed' | 'failed' | 'cancelled';
  amount: {
    amount: number;
    currency: Currency;
  };
  fee?: {
    amount: number;
    currency: Currency;
  };
  payment_method?: SallaPaymentMethod;
  gateway_response?: Record<string, unknown>;
  notes?: string;
  processed_at?: Timestamp;
  created_at: Timestamp;
  updated_at: Timestamp;
}

// Payment Method related types
export interface SallaPaymentMethod {
  id: ID;
  name: string;
  description?: string;
  type: 'credit_card' | 'bank_transfer' | 'cash_on_delivery' | 'digital_wallet' | 'installments';
  provider?: string;
  logo?: string;
  status: Status;
  is_default?: boolean;
  settings?: Record<string, unknown>;
  supported_currencies?: string[];
  fees?: {
    percentage?: number;
    fixed?: number;
  };
  created_at?: Timestamp;
  updated_at?: Timestamp;
}

// Bank related types
export interface SallaBank {
  id: ID;
  name: string;
  code?: string;
  country?: string;
  logo?: string;
  status: Status;
  account_details?: {
    account_number?: string;
    iban?: string;
    swift_code?: string;
    account_holder?: string;
  };
  created_at?: Timestamp;
  updated_at?: Timestamp;
}

// Settlement related types
export interface SallaSettlement {
  id: ID;
  reference_id: string;
  status: 'pending' | 'processing' | 'completed' | 'failed';
  amount: {
    amount: number;
    currency: Currency;
  };
  fee: {
    amount: number;
    currency: Currency;
  };
  net_amount: {
    amount: number;
    currency: Currency;
  };
  bank?: SallaBank;
  transactions: SallaTransaction[];
  settlement_date?: string;
  processed_at?: Timestamp;
  created_at: Timestamp;
  updated_at: Timestamp;
}

// Abandoned Cart related types
export interface SallaAbandonedCart {
  id: ID;
  customer_id?: ID;
  customer?: SallaCustomer;
  session_id?: string;
  email?: string;
  phone?: string;
  items: SallaCartItem[];
  total: {
    amount: number;
    currency: Currency;
  };
  recovery_emails_sent?: number;
  last_activity?: Timestamp;
  converted?: boolean;
  converted_order_id?: ID;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export interface SallaCartItem {
  id: ID;
  product_id: ID;
  product?: SallaProduct;
  variant_id?: ID;
  variant?: SallaProductVariant;
  quantity: number;
  price: {
    amount: number;
    currency: Currency;
  };
  options?: Record<string, string>;
  added_at: Timestamp;
}

// Customer Group related types
export interface SallaCustomerGroup {
  id: ID;
  name: string;
  description?: string;
  discount_percentage?: number;
  discount_fixed?: number;
  conditions?: SallaGroupCondition[];
  customer_count?: number;
  status: Status;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export interface SallaGroupCondition {
  type: 'total_orders' | 'total_spent' | 'registration_date' | 'last_order_date';
  operator: 'greater_than' | 'less_than' | 'equal_to' | 'between';
  value: number | string;
  value_end?: number | string;
}

// Option Template related types
export interface SallaOptionTemplate {
  id: ID;
  name: string;
  description?: string;
  options: SallaTemplateOption[];
  status: Status;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export interface SallaTemplateOption {
  id: ID;
  name: string;
  type: 'text' | 'color' | 'image' | 'dropdown' | 'radio' | 'checkbox';
  required: boolean;
  values: SallaTemplateOptionValue[];
  sort_order?: number;
}

export interface SallaTemplateOptionValue {
  id: ID;
  name: string;
  value: string;
  image?: string;
  color?: string;
  price_adjustment?: number;
  sort_order?: number;
}

// Shipment related types
export interface SallaShipment {
  id: ID;
  order_id: ID;
  order?: SallaOrder;
  tracking_number?: string;
  tracking_url?: string;
  shipping_company_id?: ID;
  shipping_company?: SallaShippingCompany;
  status: 'pending' | 'processing' | 'shipped' | 'delivered' | 'returned' | 'cancelled';
  shipped_at?: Timestamp;
  delivered_at?: Timestamp;
  estimated_delivery?: string;
  items: SallaShipmentItem[];
  notes?: string;
  weight?: number;
  dimensions?: {
    length?: number;
    width?: number;
    height?: number;
  };
  created_at: Timestamp;
  updated_at: Timestamp;
}

export interface SallaShipmentItem {
  id: ID;
  shipment_id: ID;
  order_item_id: ID;
  product_id: ID;
  product?: SallaProduct;
  quantity: number;
  weight?: number;
}

// Quantity related types
export interface SallaQuantityUpdate {
  id: ID;
  product_id: ID;
  product?: SallaProduct;
  variant_id?: ID;
  variant?: SallaProductVariant;
  type: 'increase' | 'decrease' | 'set';
  quantity: number;
  previous_quantity: number;
  new_quantity: number;
  reason?: string;
  notes?: string;
  user_id?: ID;
  created_at: Timestamp;
}

// Export related types
export interface SallaExport {
  id: ID;
  type: 'products' | 'orders' | 'customers' | 'categories';
  status: 'pending' | 'processing' | 'completed' | 'failed';
  file_url?: string;
  file_size?: number;
  total_records?: number;
  processed_records?: number;
  filters?: Record<string, unknown>;
  error_message?: string;
  expires_at?: Timestamp;
  created_at: Timestamp;
  updated_at: Timestamp;
}

// Reservation related types
export interface SallaReservation {
  id: ID;
  product_id: ID;
  product?: SallaProduct;
  variant_id?: ID;
  variant?: SallaProductVariant;
  customer_id?: ID;
  customer?: SallaCustomer;
  quantity: number;
  status: 'active' | 'expired' | 'cancelled' | 'converted';
  expires_at: Timestamp;
  order_id?: ID;
  notes?: string;
  created_at: Timestamp;
  updated_at: Timestamp;
}

// Affiliate related types
export interface SallaAffiliate {
  id: ID;
  name: string;
  email: string;
  phone?: string;
  code: string;
  commission_rate: number;
  commission_type: 'percentage' | 'fixed';
  status: Status;
  total_sales?: {
    amount: number;
    currency: Currency;
  };
  total_commission?: {
    amount: number;
    currency: Currency;
  };
  referral_count?: number;
  created_at: Timestamp;
  updated_at: Timestamp;
}

// Order Assignment related types
export interface SallaOrderAssignment {
  id: ID;
  order_id: ID;
  order?: SallaOrder;
  assigned_to_id: ID;
  assigned_by_id: ID;
  status: 'pending' | 'accepted' | 'rejected' | 'completed';
  notes?: string;
  assigned_at: Timestamp;
  accepted_at?: Timestamp;
  completed_at?: Timestamp;
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
  | 'product.quantity.updated'
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
  // Shipment events
  | 'shipment.created'
  | 'shipment.updated'
  | 'shipment.shipped'
  | 'shipment.delivered'
  // Invoice events
  | 'invoice.created'
  | 'invoice.updated'
  | 'invoice.paid'
  // Coupon events
  | 'coupon.used'
  // Abandoned cart events
  | 'cart.abandoned'
  | 'cart.recovered'
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