import { Hono } from "hono";
import { AppVariables } from "../../app_types";
import { auth_middleware } from "../../middleware/auth_middleware";
import { ReservationService } from "./reservation_service";
import { CreateReservationPayload } from "./reservation_types";

const reservation_routes = new Hono<{ Variables: AppVariables }>();
const service = new ReservationService();

reservation_routes.use("*", auth_middleware);

reservation_routes.post("/", async (c) => {
  try {
    const uid = c.get("user_uid");
    if (!uid) return c.json({ error: "Unauthorized" }, 401);

    const body = (await c.req.json()) as CreateReservationPayload & { renterName?: string };
    if (!body.listingId || !body.total || !body.startDate || !body.endDate) {
      return c.json({ error: "Missing required fields" }, 400);
    }

    const result = await service.create(
      body,
      uid,
      body.renterName || "Usuario",
    );
    return c.json({ id: result.id, success: true }, 201);
  } catch (error) {
    const message = error instanceof Error ? error.message : "unknown_error";
    if (message === "listing_not_found") return c.json({ error: message }, 404);
    if (message === "listing_not_available") return c.json({ error: message }, 409);
    if (message === "owner_cannot_book") return c.json({ error: message }, 400);
    console.error("Error creating reservation", error);
    return c.json({ error: "Internal server error" }, 500);
  }
});

reservation_routes.get("/renter", async (c) => {
  try {
    const uid = c.get("user_uid");
    if (!uid) return c.json({ error: "Unauthorized" }, 401);

    const reservations = await service.getByRenter(uid);
    return c.json({ data: reservations, success: true }, 200);
  } catch (error) {
    console.error("Error getting renter reservations", error);
    return c.json({ error: "Internal server error" }, 500);
  }
});

reservation_routes.get("/owner", async (c) => {
  try {
    const uid = c.get("user_uid");
    if (!uid) return c.json({ error: "Unauthorized" }, 401);

    const reservations = await service.getByOwner(uid);
    return c.json({ data: reservations, success: true }, 200);
  } catch (error) {
    console.error("Error getting owner reservations", error);
    return c.json({ error: "Internal server error" }, 500);
  }
});

reservation_routes.get("/:id", async (c) => {
  try {
    const uid = c.get("user_uid");
    if (!uid) return c.json({ error: "Unauthorized" }, 401);

    const id = c.req.param("id");
    const reservation = await service.getById(id);
    if (!reservation) return c.json({ error: "reservation_not_found" }, 404);
    if (reservation.renterId !== uid && reservation.ownerId !== uid) {
      return c.json({ error: "forbidden" }, 403);
    }
    return c.json({ data: reservation, success: true }, 200);
  } catch (error) {
    console.error("Error getting reservation", error);
    return c.json({ error: "Internal server error" }, 500);
  }
});

reservation_routes.patch("/:id/status", async (c) => {
  try {
    const uid = c.get("user_uid");
    if (!uid) return c.json({ error: "Unauthorized" }, 401);

    const id = c.req.param("id");
    const body = (await c.req.json()) as { status: string };
    if (!body.status) {
      return c.json({ error: "Missing status" }, 400);
    }

    await service.updateStatus(id, uid, body.status as any);
    return c.json({ success: true }, 200);
  } catch (error) {
    const message = error instanceof Error ? error.message : "unknown_error";
    if (message === "reservation_not_found") return c.json({ error: message }, 404);
    if (message === "forbidden") return c.json({ error: message }, 403);
    console.error("Error updating reservation status", error);
    return c.json({ error: "Internal server error" }, 500);
  }
});

reservation_routes.delete("/:id", async (c) => {
  try {
    const uid = c.get("user_uid");
    if (!uid) return c.json({ error: "Unauthorized" }, 401);

    const id = c.req.param("id");
    await service.delete(id, uid);
    return c.json({ success: true }, 200);
  } catch (error) {
    const message = error instanceof Error ? error.message : "unknown_error";
    if (message === "reservation_not_found") return c.json({ error: message }, 404);
    if (message === "forbidden") return c.json({ error: message }, 403);
    console.error("Error deleting reservation", error);
    return c.json({ error: "Internal server error" }, 500);
  }
});

export { reservation_routes };
