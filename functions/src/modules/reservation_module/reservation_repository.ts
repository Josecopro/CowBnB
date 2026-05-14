import { db } from "../../config/firebase_admin";
import { ReservationData, ReservationStatus } from "./reservation_types";
import { FieldValue } from "firebase-admin/firestore";

export class ReservationRepository {
  async create(data: ReservationData): Promise<string> {
    const docRef = db.collection("reservations").doc();
    await docRef.set(data);
    return docRef.id;
  }

  async getById(id: string): Promise<(ReservationData & { id: string }) | null> {
    const doc = await db.collection("reservations").doc(id).get();
    if (!doc.exists) return null;
    return { id: doc.id, ...(doc.data() as ReservationData) };
  }

  async getByRenter(renterId: string): Promise<(ReservationData & { id: string })[]> {
    const snapshot = await db.collection("reservations")
      .where("renterId", "==", renterId)
      .orderBy("createdAt", "desc")
      .get();
    return snapshot.docs.map(doc => ({ id: doc.id, ...(doc.data() as ReservationData) }));
  }

  async getByOwner(ownerId: string): Promise<(ReservationData & { id: string })[]> {
    const snapshot = await db.collection("reservations")
      .where("ownerId", "==", ownerId)
      .orderBy("createdAt", "desc")
      .get();
    return snapshot.docs.map(doc => ({ id: doc.id, ...(doc.data() as ReservationData) }));
  }

  async updateStatus(id: string, status: ReservationStatus): Promise<void> {
    await db.collection("reservations").doc(id).update({
      status,
      updatedAt: new Date().toISOString(),
    });
  }

  async delete(id: string): Promise<void> {
    await db.collection("reservations").doc(id).delete();
  }
}
