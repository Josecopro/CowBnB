import { db, storage } from "../../config/firebase_admin";
import { ListingData } from "./listing_types";
import { v4 as uuidv4 } from "uuid";

export class ListingRepository {
  async createListing(data: ListingData): Promise<string> {
    const docRef = db.collection("listings").doc();
    await docRef.set(data);
    return docRef.id;
  }

  async getListingsByOwner(ownerId: string): Promise<(ListingData & { id: string })[]> {
    const snapshot = await db.collection("listings").where("ownerId", "==", ownerId).orderBy("createdAt", "desc").get();
    return snapshot.docs.map(doc => ({ id: doc.id, ...(doc.data() as ListingData) }));
  }

  async getAllListings(): Promise<(ListingData & { id: string })[]> {
    const snapshot = await db.collection("listings").orderBy("createdAt", "desc").get();
    return snapshot.docs.map(doc => ({ id: doc.id, ...(doc.data() as ListingData) }));
  }

  async uploadImageBase64(base64Str: string, ext: string): Promise<string> {
    // Assuming base64Str does NOT contain "data:image/jpeg;base64," prefix.
    const fileBuffer = Buffer.from(base64Str, "base64");
    const filename = `listings/${uuidv4()}.${ext}`;
    const file = storage.bucket().file(filename);

    await file.save(fileBuffer, {
      metadata: { contentType: `image/${ext}` },
      public: true,
    });
    
    // Fallback URL format for emulator/production
    if (process.env.APP_STORAGE_EMULATOR_HOST) {
        return `http://${process.env.APP_STORAGE_EMULATOR_HOST}/v0/b/${storage.bucket().name}/o/${encodeURIComponent(filename)}?alt=media`;
    }
    return `https://storage.googleapis.com/${storage.bucket().name}/${filename}`;
  }
}
