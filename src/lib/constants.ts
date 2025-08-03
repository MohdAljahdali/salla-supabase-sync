/**
 * Application constants and configuration values
 */

// API Configuration
export const API_CONFIG = {
  SALLA_BASE_URL: 'https://api.salla.dev/admin/v2',
  SUPABASE_URL: process.env.NEXT_PUBLIC_SUPABASE_URL || '',
  SUPABASE_ANON_KEY: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '',
  TIMEOUT: 30000, // 30 seconds
  RETRY_ATTEMPTS: 3,
  RATE_LIMIT: {
    REQUESTS_PER_MINUTE: 60,
    REQUESTS_PER_HOUR: 1000,
  },
} as const;

// Salla API Endpoints
export const SALLA_ENDPOINTS = {
  STORES: '/stores',
  PRODUCTS: '/products',
  CATEGORIES: '/categories',
  CUSTOMERS: '/customers',
  ORDERS: '/orders',
  WEBHOOKS: '/webhooks',
  AUTH: '/oauth2/token',
} as const;

// Supabase Table Names
export const SUPABASE_TABLES = {
  STORES: 'stores',
  PRODUCTS: 'products',
  CATEGORIES: 'categories',
  CUSTOMERS: 'customers',
  ORDERS: 'orders',
  ORDER_ITEMS: 'order_items',
  SYNC_LOGS: 'sync_logs',
  WEBHOOKS: 'webhooks',
} as const;

// Sync Status Values
export const SYNC_STATUS = {
  PENDING: 'pending',
  IN_PROGRESS: 'in_progress',
  COMPLETED: 'completed',
  FAILED: 'failed',
  CANCELLED: 'cancelled',
} as const;

// Order Status Values
export const ORDER_STATUS = {
  PENDING: 'pending',
  PROCESSING: 'processing',
  SHIPPED: 'shipped',
  DELIVERED: 'delivered',
  CANCELLED: 'cancelled',
  REFUNDED: 'refunded',
} as const;

// Payment Status Values
export const PAYMENT_STATUS = {
  PENDING: 'pending',
  PAID: 'paid',
  FAILED: 'failed',
  REFUNDED: 'refunded',
  PARTIALLY_REFUNDED: 'partially_refunded',
} as const;

// Product Status Values
export const PRODUCT_STATUS = {
  ACTIVE: 'active',
  INACTIVE: 'inactive',
  DRAFT: 'draft',
  OUT_OF_STOCK: 'out_of_stock',
} as const;

// Webhook Events
export const WEBHOOK_EVENTS = {
  ORDER_CREATED: 'order.created',
  ORDER_UPDATED: 'order.updated',
  ORDER_CANCELLED: 'order.cancelled',
  PRODUCT_CREATED: 'product.created',
  PRODUCT_UPDATED: 'product.updated',
  PRODUCT_DELETED: 'product.deleted',
  CUSTOMER_CREATED: 'customer.created',
  CUSTOMER_UPDATED: 'customer.updated',
} as const;

// UI Constants
export const UI_CONFIG = {
  SIDEBAR_WIDTH: 280,
  HEADER_HEIGHT: 64,
  MOBILE_BREAKPOINT: 768,
  TABLET_BREAKPOINT: 1024,
  DESKTOP_BREAKPOINT: 1280,
  MAX_CONTENT_WIDTH: 1440,
} as const;

// Theme Configuration
export const THEME_CONFIG = {
  DEFAULT_THEME: 'light' as const,
  STORAGE_KEY: 'salla-sync-theme',
  THEMES: ['light', 'dark', 'system'] as const,
} as const;

// Language Configuration
export const LANGUAGE_CONFIG = {
  DEFAULT_LANGUAGE: 'ar' as const,
  SUPPORTED_LANGUAGES: ['ar', 'en'] as const,
  STORAGE_KEY: 'salla-sync-language',
  RTL_LANGUAGES: ['ar'] as const,
} as const;

// Pagination Configuration
export const PAGINATION_CONFIG = {
  DEFAULT_PAGE_SIZE: 20,
  PAGE_SIZE_OPTIONS: [10, 20, 50, 100],
  MAX_PAGE_SIZE: 100,
} as const;

// File Upload Configuration
export const FILE_UPLOAD_CONFIG = {
  MAX_FILE_SIZE: 5 * 1024 * 1024, // 5MB
  ALLOWED_IMAGE_TYPES: ['image/jpeg', 'image/png', 'image/webp', 'image/gif'],
  ALLOWED_DOCUMENT_TYPES: ['application/pdf', 'text/csv', 'application/vnd.ms-excel'],
  MAX_FILES_PER_UPLOAD: 10,
} as const;

// Validation Rules
export const VALIDATION_RULES = {
  PASSWORD_MIN_LENGTH: 8,
  PASSWORD_MAX_LENGTH: 128,
  USERNAME_MIN_LENGTH: 3,
  USERNAME_MAX_LENGTH: 50,
  EMAIL_MAX_LENGTH: 254,
  PHONE_REGEX: /^(\+966|966|0)?5[0-9]{8}$/,
  EMAIL_REGEX: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
} as const;

// Cache Configuration
export const CACHE_CONFIG = {
  DEFAULT_TTL: 5 * 60 * 1000, // 5 minutes
  LONG_TTL: 60 * 60 * 1000, // 1 hour
  SHORT_TTL: 30 * 1000, // 30 seconds
  MAX_CACHE_SIZE: 100,
} as const;

// Error Messages (Arabic)
export const ERROR_MESSAGES = {
  NETWORK_ERROR: 'خطأ في الاتصال بالشبكة',
  UNAUTHORIZED: 'غير مصرح لك بالوصول',
  FORBIDDEN: 'ممنوع الوصول',
  NOT_FOUND: 'العنصر غير موجود',
  SERVER_ERROR: 'خطأ في الخادم',
  VALIDATION_ERROR: 'خطأ في التحقق من البيانات',
  SYNC_FAILED: 'فشل في المزامنة',
  INVALID_CREDENTIALS: 'بيانات الدخول غير صحيحة',
  SESSION_EXPIRED: 'انتهت صلاحية الجلسة',
  RATE_LIMIT_EXCEEDED: 'تم تجاوز الحد المسموح من الطلبات',
} as const;

// Success Messages (Arabic)
export const SUCCESS_MESSAGES = {
  SYNC_COMPLETED: 'تمت المزامنة بنجاح',
  DATA_SAVED: 'تم حفظ البيانات بنجاح',
  DATA_UPDATED: 'تم تحديث البيانات بنجاح',
  DATA_DELETED: 'تم حذف البيانات بنجاح',
  LOGIN_SUCCESS: 'تم تسجيل الدخول بنجاح',
  LOGOUT_SUCCESS: 'تم تسجيل الخروج بنجاح',
  SETTINGS_SAVED: 'تم حفظ الإعدادات بنجاح',
} as const;

// Loading Messages (Arabic)
export const LOADING_MESSAGES = {
  SYNCING: 'جاري المزامنة...',
  LOADING: 'جاري التحميل...',
  SAVING: 'جاري الحفظ...',
  DELETING: 'جاري الحذف...',
  PROCESSING: 'جاري المعالجة...',
  CONNECTING: 'جاري الاتصال...',
} as const;

// Navigation Items
export const NAVIGATION_ITEMS = [
  {
    key: 'dashboard',
    label: 'لوحة التحكم',
    href: '/dashboard',
    icon: 'LayoutDashboard',
  },
  {
    key: 'stores',
    label: 'المتاجر',
    href: '/stores',
    icon: 'Store',
  },
  {
    key: 'products',
    label: 'المنتجات',
    href: '/products',
    icon: 'Package',
  },
  {
    key: 'orders',
    label: 'الطلبات',
    href: '/orders',
    icon: 'ShoppingCart',
  },
  {
    key: 'customers',
    label: 'العملاء',
    href: '/customers',
    icon: 'Users',
  },
  {
    key: 'sync',
    label: 'المزامنة',
    href: '/sync',
    icon: 'RefreshCw',
  },
  {
    key: 'settings',
    label: 'الإعدادات',
    href: '/settings',
    icon: 'Settings',
  },
] as const;

// Chart Colors
export const CHART_COLORS = {
  PRIMARY: '#3b82f6',
  SECONDARY: '#10b981',
  WARNING: '#f59e0b',
  DANGER: '#ef4444',
  INFO: '#06b6d4',
  SUCCESS: '#22c55e',
  MUTED: '#6b7280',
} as const;

// Date Formats
export const DATE_FORMATS = {
  SHORT: 'dd/MM/yyyy',
  LONG: 'dd MMMM yyyy',
  WITH_TIME: 'dd/MM/yyyy HH:mm',
  TIME_ONLY: 'HH:mm',
  ISO: 'yyyy-MM-dd',
} as const;

// Currency Configuration
export const CURRENCY_CONFIG = {
  DEFAULT_CURRENCY: 'SAR',
  SUPPORTED_CURRENCIES: ['SAR', 'USD', 'EUR', 'AED'],
  DECIMAL_PLACES: 2,
} as const;

// Export all constants as a single object for convenience
export const CONSTANTS = {
  API_CONFIG,
  SALLA_ENDPOINTS,
  SUPABASE_TABLES,
  SYNC_STATUS,
  ORDER_STATUS,
  PAYMENT_STATUS,
  PRODUCT_STATUS,
  WEBHOOK_EVENTS,
  UI_CONFIG,
  THEME_CONFIG,
  LANGUAGE_CONFIG,
  PAGINATION_CONFIG,
  FILE_UPLOAD_CONFIG,
  VALIDATION_RULES,
  CACHE_CONFIG,
  ERROR_MESSAGES,
  SUCCESS_MESSAGES,
  LOADING_MESSAGES,
  NAVIGATION_ITEMS,
  CHART_COLORS,
  DATE_FORMATS,
  CURRENCY_CONFIG,
} as const;