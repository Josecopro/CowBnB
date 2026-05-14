export interface ListingData {
  title: string;
  description: string;
  size: number;
  price: number;
  maintenanceCost?: number;
  status?: 'active' | 'rented' | 'review';
  features: string[];
  images: string[];
  ownerId: string;
  renterId?: string;
  rentedAt?: string;
  rentStart?: string;
  rentEnd?: string;
  bookingTotal?: number;
  createdAt: string;
  views?: number;
  rating?: number;
  reviewCount?: number;
  location?: {
    city?: string;
    country?: string;
    address?: string;
    lat?: number;
    lng?: number;
  };
  irrigation?: string;
  soil_type?: string;
  crops?: string;
  amenities?: string[];
  totalArea?: number;
}
