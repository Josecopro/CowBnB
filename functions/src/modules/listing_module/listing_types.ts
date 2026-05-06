export interface ListingData {
  title: string;
  description: string;
  size: number;
  price: number;
  features: string[];
  images: string[];
  ownerId: string;
  createdAt: string;
  views?: number;
  rating?: number;
  reviewCount?: number;
}
