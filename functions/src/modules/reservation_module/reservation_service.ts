import { ReservationRepository } from "./reservation_repository";
import { ReservationData, ReservationStatus, CreateReservationPayload } from "./reservation_types";
import { db } from "../../config/firebase_admin";
import { FieldValue } from "firebase-admin/firestore";
import { ListingData } from "../listing_module/listing_types";

export class ReservationService {
  private repository: ReservationRepository;

  constructor() {
    this.repository = new ReservationRepository();
  }

  async create(
    payload: CreateReservationPayload,
    renterId: string,
    renterName: string,
  ): Promise<{ id: string }> {
    const listingRef = db.collection("listings").doc(payload.listingId);
    const listingDoc = await listingRef.get();
    if (!listingDoc.exists) {
      throw new Error("listing_not_found");
    }

    const listing = listingDoc.data() as ListingData;
    if (listing.status !== "active") {
      throw new Error("listing_not_available");
    }
    if (listing.ownerId === renterId) {
      throw new Error("owner_cannot_book");
    }

    const now = new Date().toISOString();
    const reservation: ReservationData = {
      listingId: payload.listingId,
      listingTitle: payload.listingTitle,
      listingImage: payload.listingImage,
      renterId,
      renterName,
      ownerId: payload.ownerId,
      ownerName: payload.ownerName,
      startDate: payload.startDate,
      endDate: payload.endDate,
      months: payload.months,
      monthlyPrice: payload.monthlyPrice,
      maintenanceMonthly: payload.maintenanceMonthly,
      taxes: payload.taxes,
      total: payload.total,
      status: "confirmed",
      createdAt: now,
      updatedAt: now,
    };

    const id = await this.repository.create(reservation);

    await listingRef.update({
      status: "rented",
      renterId,
      rentedAt: now,
      rentStart: payload.startDate || null,
      rentEnd: payload.endDate || null,
      bookingTotal: payload.total,
    });

    if (listing.ownerId) {
      await db.collection("user_profiles").doc(listing.ownerId).set(
        { current_month_earnings: FieldValue.increment(payload.total) },
        { merge: true },
      );
    }

    return { id };
  }

  async getByRenter(renterId: string) {
    return this.repository.getByRenter(renterId);
  }

  async getByOwner(ownerId: string) {
    return this.repository.getByOwner(ownerId);
  }

  async getById(id: string) {
    return this.repository.getById(id);
  }

  async updateStatus(id: string, uid: string, status: ReservationStatus): Promise<void> {
    const reservation = await this.repository.getById(id);
    if (!reservation) {
      throw new Error("reservation_not_found");
    }

    const isOwner = reservation.ownerId === uid;
    const isRenter = reservation.renterId === uid;
    if (!isOwner && !isRenter) {
      throw new Error("forbidden");
    }

    if (status === "cancelled") {
      const listingRef = db.collection("listings").doc(reservation.listingId);
      await listingRef.update({
        status: "active",
        renterId: FieldValue.delete(),
        rentedAt: FieldValue.delete(),
        rentStart: FieldValue.delete(),
        rentEnd: FieldValue.delete(),
        bookingTotal: FieldValue.delete(),
      });
    }

    if (status === "completed" && isRenter) {
      const listingRef = db.collection("listings").doc(reservation.listingId);
      await listingRef.update({ status: "review" });
    }

    await this.repository.updateStatus(id, status);
  }

  async delete(id: string, uid: string): Promise<void> {
    const reservation = await this.repository.getById(id);
    if (!reservation) {
      throw new Error("reservation_not_found");
    }
    if (reservation.renterId !== uid && reservation.ownerId !== uid) {
      throw new Error("forbidden");
    }
    await this.repository.delete(id);
  }
}
