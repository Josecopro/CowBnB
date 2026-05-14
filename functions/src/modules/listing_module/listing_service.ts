import { ListingRepository } from "./listing_repository";
import { ListingData } from "./listing_types";
import { db } from "../../config/firebase_admin";
import { FieldValue } from "firebase-admin/firestore";

export class ListingService {

  async bookListing(
    listingId: string,
    total: number,
    renterId: string,
    rentStart?: string,
    rentEnd?: string
  ): Promise<void> {
    const listingRef = db.collection("listings").doc(listingId);
    const snapshot = await listingRef.get();
    if (!snapshot.exists) {
      throw new Error("listing_not_found");
    }

    const listing = snapshot.data() as ListingData;
    const currentStatus = listing.status ?? "active";
    if (currentStatus !== "active") {
      throw new Error("listing_not_available");
    }
    if (listing.ownerId === renterId) {
      throw new Error("owner_cannot_book");
    }

    await listingRef.update({
      status: "rented",
      renterId,
      rentedAt: new Date().toISOString(),
      rentStart: rentStart ?? null,
      rentEnd: rentEnd ?? null,
      bookingTotal: total,
    });

    if (listing.ownerId) {
      await db.collection("user_profiles").doc(listing.ownerId).set(
        {
          current_month_earnings: FieldValue.increment(total),
        },
        { merge: true }
      );
    }
  }

  async updateListingStatus(listingId: string, status: string, ownerId: string): Promise<void> {
    const listingRef = db.collection("listings").doc(listingId);
    const snapshot = await listingRef.get();
    if (!snapshot.exists) {
      throw new Error("listing_not_found");
    }

    const listing = snapshot.data() as ListingData;
    if (listing.ownerId !== ownerId) {
      throw new Error("forbidden");
    }

    if ((listing.status ?? "active") === "rented") {
      throw new Error("listing_rented");
    }

    if (status !== "active" && status !== "review") {
      throw new Error("invalid_status");
    }

    if (status === "active") {
      await listingRef.update({
        status,
        renterId: FieldValue.delete(),
        rentedAt: FieldValue.delete(),
        rentStart: FieldValue.delete(),
        rentEnd: FieldValue.delete(),
        bookingTotal: FieldValue.delete(),
      });
      return;
    }

    await listingRef.update({ status });
  }

  async updateListing(
    listingId: string,
    ownerId: string,
    data: Partial<ListingData>
  ): Promise<void> {
    const doc = await db.collection("listings").doc(listingId).get();
    const listing = doc.data() as ListingData | undefined;
    if (!listing) {
      throw new Error("listing_not_found");
    }
    if (listing.ownerId !== ownerId) {
      throw new Error("forbidden");
    }
    await this.repository.updateListing(listingId, data);
  }

  async deleteListing(listingId: string, ownerId: string): Promise<void> {
    const doc = await db.collection("listings").doc(listingId).get();
    const listing = doc.data() as ListingData | undefined;
    if (!listing) {
      throw new Error("listing_not_found");
    }
    if (listing.ownerId !== ownerId) {
      throw new Error("forbidden");
    }
    if ((listing.status ?? "active") === "rented") {
      throw new Error("listing_rented");
    }
    await db.collection("listings").doc(listingId).delete();
  }

  async completeRental(listingId: string, renterId: string): Promise<void> {
    const listingRef = db.collection("listings").doc(listingId);
    const snapshot = await listingRef.get();
    if (!snapshot.exists) {
      throw new Error("listing_not_found");
    }

    const listing = snapshot.data() as ListingData;
    if ((listing.status ?? "active") !== "rented") {
      throw new Error("listing_not_rented");
    }
    if (listing.renterId !== renterId) {
      throw new Error("forbidden");
    }
    await listingRef.update({ status: "review" });
  }

  private repository: ListingRepository;

  constructor() {
    this.repository = new ListingRepository();
  }

  async createListing(
    uid: string, 
    data: { title: string; description: string; size: number; price: number; maintenanceCost?: number; status?: ListingData['status']; features: string[]; }, 
    imagesBase64: { base64: string; ext: string }[]
  ): Promise<string> {
    const imageUrls: string[] = [];

    for (const img of imagesBase64) {
      const url = await this.repository.uploadImageBase64(img.base64, img.ext);
      imageUrls.push(url);
    }

    const listing: ListingData = {
      ...data,
      ownerId: uid,
      images: imageUrls,
      createdAt: new Date().toISOString(),
    };

    return this.repository.createListing(listing);
  }

  async getAllListings() {
    return this.repository.getAllListings();
  }

  async getListingsByOwner(uid: string) {
    return this.repository.getListingsByOwner(uid);
  }

  async getListingsByRenter(uid: string) {
    return this.repository.getListingsByRenter(uid);
  }

  async incrementViews(id: string) {
    await this.repository.incrementViews(id);
    const listingSnapshot = await db.collection("listings").doc(id).get();
    const listing = listingSnapshot.data() as ListingData | undefined;
    if (listing?.ownerId) {
      await db.collection("user_profiles").doc(listing.ownerId).set(
        {
          total_views: FieldValue.increment(1),
        },
        { merge: true }
      );
    }
  }
}
