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
}
