export type ReservationStatus = 'pending' | 'confirmed' | 'active' | 'completed' | 'cancelled';

export type ReservationData = {
  listingId: string;
  listingTitle: string;
  listingImage: string;
  renterId: string;
  renterName: string;
  ownerId: string;
  ownerName: string;
  startDate: string;
  endDate: string;
  months: number;
  monthlyPrice: number;
  maintenanceMonthly: number;
  taxes: number;
  total: number;
  status: ReservationStatus;
  createdAt: string;
  updatedAt: string;
};

export type CreateReservationPayload = {
  listingId: string;
  listingTitle: string;
  listingImage: string;
  ownerId: string;
  ownerName: string;
  startDate: string;
  endDate: string;
  months: number;
  monthlyPrice: number;
  maintenanceMonthly: number;
  taxes: number;
  total: number;
};

export type UpdateReservationPayload = {
  status: ReservationStatus;
};
