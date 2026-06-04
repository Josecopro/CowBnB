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
  // NDVI and terrain monitoring fields
  coordenadas?: number[][]; // Polygon coordinates [ [lng, lat], ... ]
  estado?: 'disponible' | 'reservado' | 'en_espera' | 'inactivo';
  razonEspera?: 'ndvi_alto' | null;
  ndviDetectado?: number | null;
  ndviFecha?: string | null; // ISO string of the latest NDVI reading
  tokenConfirmacion?: string | null;
  tokenExpira?: string | null; // ISO string
  confirmadoPorArrendatario?: boolean | null;
}
