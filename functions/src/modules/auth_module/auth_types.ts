export type UserRole = "owner" | "renter";

export type UserProfile = {
  uid: string;
  email: string | null;
  display_name: string | null;
  phone_number: string | null;
  role: UserRole;
  created_at: FirebaseFirestore.Timestamp;
  updated_at: FirebaseFirestore.Timestamp;
};

export type UpsertProfilePayload = {
  role: UserRole;
  display_name?: string;
  phone_number?: string;
};
