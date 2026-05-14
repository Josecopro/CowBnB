import { Hono } from "hono";
import { AppVariables } from "../../app_types";
import { auth_middleware } from "../../middleware/auth_middleware";
import { auth_repository } from "./auth_repository";
import { db } from "../../config/firebase_admin";
import { FieldValue } from "firebase-admin/firestore";

const favorites_routes = new Hono<{ Variables: AppVariables }>();

favorites_routes.use("*", auth_middleware);

favorites_routes.get("/", async (c) => {
  const uid = c.get("user_uid");
  if (!uid) return c.json({ error: "missing_user" }, 401);

  try {
    const profileRef = db.collection("user_profiles").doc(uid);
    const doc = await profileRef.get();
    const data = doc.exists ? doc.data() : null;
    const favoriteIds: string[] = data?.favorites || [];

    if (favoriteIds.length === 0) {
      return c.json({ data: [] });
    }

    // Fetch listings
    // Since firestore 'in' queries are limited to 10-30, we'll fetch them individually or use batches.
    // For simplicity locally, let's fetch individually (in parallel).
    const promises = favoriteIds.map(id => db.collection("listings").doc(id).get());
    const snapshots = await Promise.all(promises);
    const listings = snapshots
      .filter(s => s.exists)
      .map(s => ({ id: s.id, ...s.data() }));

    return c.json({ data: listings });
  } catch (error) {
    console.error("Error retrieving favorites", error);
    return c.json({ error: "Internal server error" }, 500);
  }
});

favorites_routes.post("/:id", async (c) => {
  const uid = c.get("user_uid");
  if (!uid) return c.json({ error: "missing_user" }, 401);
  const listingId = c.req.param("id");

  try {
    await db.collection("user_profiles").doc(uid).set({
      favorites: FieldValue.arrayUnion(listingId)
    }, { merge: true });
    return c.json({ success: true });
  } catch (error) {
    return c.json({ error: "Internal server error" }, 500);
  }
});

favorites_routes.delete("/:id", async (c) => {
  const uid = c.get("user_uid");
  if (!uid) return c.json({ error: "missing_user" }, 401);
  const listingId = c.req.param("id");

  try {
    await db.collection("user_profiles").doc(uid).set({
      favorites: FieldValue.arrayRemove(listingId)
    }, { merge: true });
    return c.json({ success: true });
  } catch (error) {
    return c.json({ error: "Internal server error" }, 500);
  }
});

export { favorites_routes };
