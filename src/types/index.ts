/**
 * Global type definitions for Salla-Supabase Sync project
 * Contains common types used throughout the application
 */

// Common utility types
export type ID = string;
export type Timestamp = string;
export type Currency = 'SAR' | 'USD' | 'EUR' | 'AED';
export type Language = 'ar' | 'en';
export type Status = 'active' | 'inactive' | 'pending' | 'suspended';

// API Response types
export interface ApiResponse<T = unknown> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

export interface PaginatedResponse<T> extends ApiResponse<T[]> {
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}

// Error handling types
export interface AppError {
  code: string;
  message: string;
  details?: Record<string, unknown>;
}

// Form types
export interface FormField {
  name: string;
  label: string;
  type: 'text' | 'email' | 'password' | 'number' | 'select' | 'textarea' | 'checkbox';
  required?: boolean;
  placeholder?: string;
  options?: Array<{ value: string; label: string }>;
}

// Theme types
export type Theme = 'light' | 'dark' | 'system';

// Component props types
export interface BaseComponentProps {
  className?: string;
  children?: React.ReactNode;
}

// Loading states
export interface LoadingState {
  isLoading: boolean;
  error?: string | null;
}

// User preferences
export interface UserPreferences {
  theme: Theme;
  language: Language;
  currency: Currency;
  timezone: string;
}

// Export all types from sub-modules
// Note: These exports are commented out temporarily to avoid module resolution errors
// They will be enabled once the modules are properly configured
// export * from './salla';
// export * from './supabase';
// export * from './components';