import { Hono } from "hono";
import { AppVariables } from "../../app_types";
import { auth_middleware } from "../../middleware/auth_middleware";
import { auth_service } from "./auth_service";
import { UpsertProfilePayload } from "./auth_types";

const auth_routes = new Hono<{ Variables: AppVariables }>();

auth_routes.use("*", auth_middleware);

auth_routes.get("/me", async (c) => {
  const uid = c.get("user_uid");

  if (!uid) {
    return c.json({ error: "missing_user" }, 401);
  }

  const profile = await auth_service.get_profile(uid);
  return c.json({ profile });
});

auth_routes.post("/profile", async (c) => {
  const uid = c.get("user_uid");
  const email = c.get("user_email");

  if (!uid) {
    return c.json({ error: "missing_user" }, 401);
  }

  let payload: UpsertProfilePayload | null = null;
  try {
    payload = (await c.req.json()) as UpsertProfilePayload;
  } catch (error) {
    return c.json({ error: "invalid_json" }, 400);
  }

  if (!payload?.role || (payload.role !== "owner" && payload.role !== "renter")) {
    return c.json({ error: "invalid_role" }, 400);
  }

  const profile = await auth_service.upsert_profile(uid, payload, email ?? null);
  return c.json({ profile });
});

export { auth_routes };
