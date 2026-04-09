// ============================================================================
// SHARED TYPESCRIPT INTERFACES
// Based on data-models.ts
// ============================================================================

// User types
export interface User {
  uid: string;
  email: string;
  fullName: string;
  phone: string;
  phonePrefix: string;
  role: 'owner' | 'renter';
  status: 'active' | 'suspended' | 'deleted';
  createdAt: number;
  updatedAt: number;
  profileImageUrl?: string;
  bio?: string;
}

// Terreno types
export interface TerrenoImage {
  url: string;
  alt?: string;
}

export interface Location {
  latitude: number;
  longitude: number;
  geohash: string;
}

export interface Terreno {
  id: string;
  ownerId: string;
  title: string;
  description: string;
  sizeHectares: number;
  location: Location;
  priceMonthly: number;
  features: Array<'irrigation' | 'power' | 'roads' | 'certification'>;
  images: TerrenoImage[];
  status: 'disponible' | 'reservado' | 'en_espera' | 'inactivo';
  createdAt: number;
  updatedAt: number;
  ratingAvg?: number;
  ratingCount?: number;
  lastNdviCheck?: number;
  ndviStatus?: 'green' | 'yellow' | 'red';
}

// Reserva types
export interface Reserva {
  id: string;
  terrenoId: string;
  renterId: string;
  ownerId: string;
  startDate: number;
  endDate: number;
  durationDays: number;
  pricePerMonth: number;
  estimatedTotal: number;
  status: 'en_espera' | 'reservado' | 'activa' | 'finalizada' | 'cancelada';
  createdAt: number;
  updatedAt: number;
}

// Payment types
export interface PaymentEvent {
  id: string;
  reservaId: string;
  terrenoId: string;
  amount: number;
  currency: string;
  boldReference: string;
  status: 'pending' | 'approved' | 'rejected' | 'cancelled';
  createdAt: number;
  updatedAt: number;
}

// Conversacion types
export interface Mensaje {
  id: string;
  senderId: string;
  content: string;
  timestamp: number;
  read: boolean;
}

export interface Conversacion {
  id: string;
  terrenoId: string;
  ownerId: string;
  renterId: string;
  lastMessage?: Mensaje;
  createdAt: number;
  updatedAt: number;
}

// Review types
export interface Review {
  id: string;
  reservaId: string;
  reviewerId: string;
  revieweeId: string;
  rating: number;
  comment?: string;
  createdAt: number;
}

// Action Token types (for NDVI actions)
export interface ActionToken {
  id: string;
  terrenoId: string;
  action: 'reactivate' | 'confirm_ndvi';
  tokenHash: string;
  expiresAt: number;
  consumed: boolean;
  createdAt: number;
}

// NDVI Check types
export interface NdviCheck {
  id: string;
  terrenoId: string;
  ndviValue: number;
  status: 'green' | 'yellow' | 'red';
  checkedAt: number;
  actionTaken?: string;
}

// API Response types
export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
    statusCode: number;
    timestamp: number;
    requestId?: string;
  };
  requestId?: string;
}

// Pagination types
export interface PaginationOptions {
  limit?: number;
  offset?: number;
  orderBy?: string;
  orderDirection?: 'asc' | 'desc';
}

export interface PaginatedResponse<T> extends ApiResponse<T[]> {
  pagination?: {
    total: number;
    limit: number;
    offset: number;
    hasMore: boolean;
  };
}

// Filter types
export interface TerrenoFilters {
  status?: string;
  ownerId?: string;
  minPrice?: number;
  maxPrice?: number;
  minSize?: number;
  maxSize?: number;
  features?: string[];
  locationBounds?: {
    northEast: { lat: number; lng: number };
    southWest: { lat: number; lng: number };
  };
}