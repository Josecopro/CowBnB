import { FieldValue } from "firebase-admin/firestore";
import { db } from "../../config/firebase_admin";
import { UpsertProfilePayload, UserProfile } from "./auth_types";

const collection_name = "user_profiles";

export const auth_repository = {
  async get_profile(uid: string) {
    const snapshot = await db.collection(collection_name).doc(uid).get();
    return snapshot.exists ? (snapshot.data() as UserProfile) : null;
  },

  async upsert_profile(uid: string, payload: UpsertProfilePayload, email: string | null) {
    const now = FieldValue.serverTimestamp();
    const ref = db.collection(collection_name).doc(uid);

    await ref.set(
      {
        uid,
        email: email ?? null,
        display_name: payload.display_name ?? null,
        phone_number: payload.phone_number ?? null,
        role: payload.role,
        updated_at: now,
        created_at: now,
      },
      { merge: true }
    );

    const updated = await ref.get();
    return updated.data() as UserProfile;
  },
};
