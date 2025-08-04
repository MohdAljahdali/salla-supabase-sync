/**
 * Validation schemas and functions using Zod
 * Provides type-safe validation for forms and API data
 */

import { z } from 'zod';
import { VALIDATION_RULES } from './constants';

// Base validation schemas
export const emailSchema = z
  .string()
  .min(1, 'البريد الإلكتروني مطلوب')
  .max(VALIDATION_RULES.EMAIL_MAX_LENGTH, 'البريد الإلكتروني طويل جداً')
  .email('البريد الإلكتروني غير صحيح');

export const passwordSchema = z
  .string()
  .min(VALIDATION_RULES.PASSWORD_MIN_LENGTH, `كلمة المرور يجب أن تكون ${VALIDATION_RULES.PASSWORD_MIN_LENGTH} أحرف على الأقل`)
  .max(VALIDATION_RULES.PASSWORD_MAX_LENGTH, `كلمة المرور يجب أن تكون ${VALIDATION_RULES.PASSWORD_MAX_LENGTH} حرف على الأكثر`)
  .regex(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/, 'كلمة المرور يجب أن تحتوي على حرف كبير وصغير ورقم');

export const phoneSchema = z
  .string()
  .min(1, 'رقم الهاتف مطلوب')
  .regex(VALIDATION_RULES.PHONE_REGEX, 'رقم الهاتف غير صحيح');

export const usernameSchema = z
  .string()
  .min(VALIDATION_RULES.USERNAME_MIN_LENGTH, `اسم المستخدم يجب أن يكون ${VALIDATION_RULES.USERNAME_MIN_LENGTH} أحرف على الأقل`)
  .max(VALIDATION_RULES.USERNAME_MAX_LENGTH, `اسم المستخدم يجب أن يكون ${VALIDATION_RULES.USERNAME_MAX_LENGTH} حرف على الأكثر`)
  .regex(/^[a-zA-Z0-9_]+$/, 'اسم المستخدم يجب أن يحتوي على أحرف وأرقام فقط');

// Common field schemas
export const nameSchema = z
  .string()
  .min(1, 'الاسم مطلوب')
  .max(100, 'الاسم طويل جداً')
  .regex(/^[\u0600-\u06FFa-zA-Z\s]+$/, 'الاسم يجب أن يحتوي على أحرف عربية أو إنجليزية فقط');

export const descriptionSchema = z
  .string()
  .max(1000, 'الوصف طويل جداً')
  .optional();

export const urlSchema = z
  .string()
  .url('الرابط غير صحيح')
  .optional();

export const requiredUrlSchema = z
  .string()
  .min(1, 'الرابط مطلوب')
  .url('الرابط غير صحيح');

export const priceSchema = z
  .number()
  .min(0, 'السعر يجب أن يكون أكبر من أو يساوي صفر')
  .max(999999.99, 'السعر كبير جداً');

export const quantitySchema = z
  .number()
  .int('الكمية يجب أن تكون رقم صحيح')
  .min(0, 'الكمية يجب أن تكون أكبر من أو تساوي صفر');

// Authentication schemas
export const loginSchema = z.object({
  email: emailSchema,
  password: z.string().min(1, 'كلمة المرور مطلوبة'),
  rememberMe: z.boolean().optional(),
});

export const registerSchema = z.object({
  name: nameSchema,
  email: emailSchema,
  password: passwordSchema,
  confirmPassword: z.string(),
  phone: phoneSchema.optional(),
  acceptTerms: z.boolean().refine(val => val === true, {
    message: 'يجب الموافقة على الشروط والأحكام',
  }),
}).refine(data => data.password === data.confirmPassword, {
  message: 'كلمات المرور غير متطابقة',
  path: ['confirmPassword'],
});

export const forgotPasswordSchema = z.object({
  email: emailSchema,
});

export const resetPasswordSchema = z.object({
  token: z.string().min(1, 'الرمز مطلوب'),
  password: passwordSchema,
  confirmPassword: z.string(),
}).refine(data => data.password === data.confirmPassword, {
  message: 'كلمات المرور غير متطابقة',
  path: ['confirmPassword'],
});

// Store schemas
export const storeSchema = z.object({
  name: nameSchema,
  description: descriptionSchema,
  url: urlSchema,
  email: emailSchema.optional(),
  phone: phoneSchema.optional(),
  address: z.string().max(500, 'العنوان طويل جداً').optional(),
  city: z.string().max(100, 'اسم المدينة طويل جداً').optional(),
  country: z.string().max(100, 'اسم البلد طويل جداً').optional(),
  currency: z.string().length(3, 'رمز العملة يجب أن يكون 3 أحرف').optional(),
  timezone: z.string().optional(),
  language: z.enum(['ar', 'en']).optional(),
});

// Product schemas
export const productSchema = z.object({
  name: nameSchema,
  description: descriptionSchema,
  sku: z.string().min(1, 'رمز المنتج مطلوب').max(100, 'رمز المنتج طويل جداً'),
  price: priceSchema,
  comparePrice: priceSchema.optional(),
  cost: priceSchema.optional(),
  quantity: quantitySchema,
  weight: z.number().min(0, 'الوزن يجب أن يكون أكبر من أو يساوي صفر').optional(),
  dimensions: z.object({
    length: z.number().min(0).optional(),
    width: z.number().min(0).optional(),
    height: z.number().min(0).optional(),
  }).optional(),
  categoryId: z.string().uuid('معرف الفئة غير صحيح').optional(),
  tags: z.array(z.string()).optional(),
  images: z.array(z.string().url('رابط الصورة غير صحيح')).optional(),
  status: z.enum(['active', 'inactive', 'draft', 'out_of_stock']).optional(),
  seoTitle: z.string().max(60, 'عنوان SEO طويل جداً').optional(),
  seoDescription: z.string().max(160, 'وصف SEO طويل جداً').optional(),
});

// Category schemas
export const categorySchema = z.object({
  name: nameSchema,
  description: descriptionSchema,
  parentId: z.string().uuid('معرف الفئة الأب غير صحيح').optional(),
  image: z.string().url('رابط الصورة غير صحيح').optional(),
  status: z.enum(['active', 'inactive']).optional(),
  sortOrder: z.number().int().min(0).optional(),
  seoTitle: z.string().max(60, 'عنوان SEO طويل جداً').optional(),
  seoDescription: z.string().max(160, 'وصف SEO طويل جداً').optional(),
});

// Customer schemas
export const customerSchema = z.object({
  firstName: nameSchema,
  lastName: nameSchema,
  email: emailSchema,
  phone: phoneSchema.optional(),
  dateOfBirth: z.string().optional(),
  gender: z.enum(['male', 'female']).optional(),
  addresses: z.array(z.object({
    type: z.enum(['billing', 'shipping']),
    firstName: nameSchema,
    lastName: nameSchema,
    company: z.string().max(100).optional(),
    address1: z.string().min(1, 'العنوان مطلوب').max(200),
    address2: z.string().max(200).optional(),
    city: z.string().min(1, 'المدينة مطلوبة').max(100),
    state: z.string().max(100).optional(),
    postalCode: z.string().max(20).optional(),
    country: z.string().min(1, 'البلد مطلوب').max(100),
    phone: phoneSchema.optional(),
  })).optional(),
});

// Order schemas
export const orderItemSchema = z.object({
  productId: z.string().uuid('معرف المنتج غير صحيح'),
  variantId: z.string().uuid().optional(),
  quantity: quantitySchema.min(1, 'الكمية يجب أن تكون أكبر من صفر'),
  price: priceSchema,
  discount: priceSchema.optional(),
});

export const orderSchema = z.object({
  customerId: z.string().uuid('معرف العميل غير صحيح'),
  items: z.array(orderItemSchema).min(1, 'يجب أن يحتوي الطلب على منتج واحد على الأقل'),
  shippingAddress: z.object({
    firstName: nameSchema,
    lastName: nameSchema,
    company: z.string().max(100).optional(),
    address1: z.string().min(1, 'العنوان مطلوب').max(200),
    address2: z.string().max(200).optional(),
    city: z.string().min(1, 'المدينة مطلوبة').max(100),
    state: z.string().max(100).optional(),
    postalCode: z.string().max(20).optional(),
    country: z.string().min(1, 'البلد مطلوب').max(100),
    phone: phoneSchema.optional(),
  }),
  billingAddress: z.object({
    firstName: nameSchema,
    lastName: nameSchema,
    company: z.string().max(100).optional(),
    address1: z.string().min(1, 'العنوان مطلوب').max(200),
    address2: z.string().max(200).optional(),
    city: z.string().min(1, 'المدينة مطلوبة').max(100),
    state: z.string().max(100).optional(),
    postalCode: z.string().max(20).optional(),
    country: z.string().min(1, 'البلد مطلوب').max(100),
    phone: phoneSchema.optional(),
  }).optional(),
  notes: z.string().max(500, 'الملاحظات طويلة جداً').optional(),
  discountCode: z.string().max(50).optional(),
  shippingMethod: z.string().max(100).optional(),
  paymentMethod: z.string().max(100).optional(),
});

// Settings schemas
export const settingsSchema = z.object({
  general: z.object({
    siteName: nameSchema,
    siteDescription: descriptionSchema,
    contactEmail: emailSchema,
    contactPhone: phoneSchema.optional(),
    timezone: z.string(),
    language: z.enum(['ar', 'en']),
    currency: z.string().length(3),
  }),
  salla: z.object({
    clientId: z.string().min(1, 'معرف العميل مطلوب'),
    clientSecret: z.string().min(1, 'سر العميل مطلوب'),
    accessToken: z.string().optional(),
    refreshToken: z.string().optional(),
    storeUrl: urlSchema,
    webhookSecret: z.string().optional(),
  }),
  supabase: z.object({
    url: urlSchema,
    anonKey: z.string().min(1, 'مفتاح Supabase مطلوب'),
    serviceRoleKey: z.string().optional(),
  }),
  sync: z.object({
    autoSync: z.boolean(),
    syncInterval: z.number().min(5, 'فترة المزامنة يجب أن تكون 5 دقائق على الأقل'),
    batchSize: z.number().min(1).max(100),
    enableWebhooks: z.boolean(),
  }),
  notifications: z.object({
    email: z.boolean(),
    browser: z.boolean(),
    syncErrors: z.boolean(),
    orderUpdates: z.boolean(),
    productUpdates: z.boolean(),
  }),
});

// Webhook schemas
export const webhookSchema = z.object({
  url: urlSchema.refine(url => url !== undefined, { message: 'رابط الويب هوك مطلوب' }),
  events: z.array(z.string()).min(1, 'يجب اختيار حدث واحد على الأقل'),
  secret: z.string().min(8, 'سر الويب هوك يجب أن يكون 8 أحرف على الأقل').optional(),
  active: z.boolean().optional(),
});

// Search and filter schemas
export const searchSchema = z.object({
  query: z.string().max(100, 'استعلام البحث طويل جداً').optional(),
  filters: z.record(z.string(), z.unknown()).optional(),
  sort: z.string().optional(),
  order: z.enum(['asc', 'desc']).optional(),
  page: z.number().int().min(1).optional(),
  limit: z.number().int().min(1).max(100).optional(),
});

// File upload schemas
export const fileUploadSchema = z.object({
  file: z.instanceof(File, { message: 'الملف مطلوب' }),
  type: z.enum(['image', 'document']),
  maxSize: z.number().optional(),
  allowedTypes: z.array(z.string()).optional(),
});

// Export validation functions
export const validateEmail = (email: string): boolean => {
  return emailSchema.safeParse(email).success;
};

export const validatePhone = (phone: string): boolean => {
  return phoneSchema.safeParse(phone).success;
};

export const validatePassword = (password: string): boolean => {
  return passwordSchema.safeParse(password).success;
};

export const validateUrl = (url: string): boolean => {
  return z.string().url('الرابط غير صحيح').safeParse(url).success;
};

// Type exports
export type LoginFormData = z.infer<typeof loginSchema>;
export type RegisterFormData = z.infer<typeof registerSchema>;
export type ForgotPasswordFormData = z.infer<typeof forgotPasswordSchema>;
export type ResetPasswordFormData = z.infer<typeof resetPasswordSchema>;
export type StoreFormData = z.infer<typeof storeSchema>;
export type ProductFormData = z.infer<typeof productSchema>;
export type CategoryFormData = z.infer<typeof categorySchema>;
export type CustomerFormData = z.infer<typeof customerSchema>;
export type OrderFormData = z.infer<typeof orderSchema>;
export type OrderItemFormData = z.infer<typeof orderItemSchema>;
export type SettingsFormData = z.infer<typeof settingsSchema>;
export type WebhookFormData = z.infer<typeof webhookSchema>;
export type SearchFormData = z.infer<typeof searchSchema>;
export type FileUploadFormData = z.infer<typeof fileUploadSchema>;