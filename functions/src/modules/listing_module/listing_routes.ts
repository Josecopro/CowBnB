import { Hono } from "hono";
import { AppVariables } from "../../app_types";
import { ListingService } from "./listing_service";
import { auth_middleware } from "../../middleware/auth_middleware";

const listing_routes = new Hono<{ Variables: AppVariables }>();
const service = new ListingService();

listing_routes.use("*", auth_middleware);

listing_routes.post("/", async (c) => {
  try {
    const uid = c.get("user_uid");
    if (!uid) return c.json({ error: "Unauthorized" }, 401);

    const body = await c.req.json();
    const { title, description, size, price, features, images, maintenanceCost, status } = body;

    // images array should be { base64: string, ext: string }[]
    if (!title || !description || size == null || price == null) {
      return c.json({ error: "Missing required fields" }, 400);
    }

    const listingId = await service.createListing(uid, {
      title,
      description,
      size: Number(size),
      price: Number(price),
      maintenanceCost: maintenanceCost != null ? Number(maintenanceCost) : undefined,
      status,
      features: features || [],
    }, images || []);

    return c.json({ id: listingId, success: true }, 201);
  } catch (error) {
    console.error("Error creating listing", error);
    return c.json({ error: "Internal server error" }, 500);
  }
});

listing_routes.get("/", async (c) => {
  try {
    const listings = await service.getAllListings();
    return c.json({ data: listings, success: true }, 200);
  } catch (error) {
    console.error("Error retrieving listings", error);
    return c.json({ error: "Internal server error" }, 500);
  }
});

listing_routes.get("/me", async (c) => {
  try {
    const uid = c.get("user_uid");
    if (!uid) return c.json({ error: "Unauthorized" }, 401);

    const listings = await service.getListingsByOwner(uid);
    return c.json({ data: listings, success: true }, 200);
  } catch (error) {
    console.error("Error retrieving user listings", error);
    return c.json({ error: "Internal server error" }, 500);
  }
});

listing_routes.get("/renter", async (c) => {
  try {
    const uid = c.get("user_uid");
    if (!uid) return c.json({ error: "Unauthorized" }, 401);

    const listings = await service.getListingsByRenter(uid);
    return c.json({ data: listings, success: true }, 200);
  } catch (error) {
    console.error("Error retrieving renter listings", error);
    return c.json({ error: "Internal server error" }, 500);
  }
});

listing_routes.post("/:id/view", async (c) => {
  try {
    const id = c.req.param("id");
    await service.incrementViews(id);
    return c.json({ success: true }, 200);
  } catch (error) {
    console.error(`Error incrementing views for ${c.req.param("id")}`, error);
    return c.json({ error: "Internal server error" }, 500);
  }
});


listing_routes.post("/:id/book", async (c) => {
  try {
    const id = c.req.param("id");
    const uid = c.get("user_uid");
    if (!uid) return c.json({ error: "Unauthorized" }, 401);
    
    const body = await c.req.json();
    const total = Number(body?.total ?? 0);
    const rentStart = body?.rentStart ? String(body.rentStart) : undefined;
    const rentEnd = body?.rentEnd ? String(body.rentEnd) : undefined;
    if (Number.isNaN(total) || total <= 0) {
      return c.json({ error: "invalid_total" }, 400);
    }

    await service.bookListing(id, total, uid, rentStart, rentEnd);
    return c.json({ success: true }, 200);
  } catch (error) {
    const message = error instanceof Error ? error.message : "unknown_error";
    if (message === "listing_not_found") return c.json({ error: message }, 404);
    if (message === "listing_not_available") return c.json({ error: message }, 409);
    if (message === "owner_cannot_book") return c.json({ error: message }, 400);
    return c.json({ error: "Internal server error" }, 500);
  }
});

listing_routes.post("/:id/complete", async (c) => {
  try {
    const id = c.req.param("id");
    const uid = c.get("user_uid");
    if (!uid) return c.json({ error: "Unauthorized" }, 401);

    await service.completeRental(id, uid);
    return c.json({ success: true }, 200);
  } catch (error) {
    const message = error instanceof Error ? error.message : "unknown_error";
    if (message === "listing_not_found") return c.json({ error: message }, 404);
    if (message === "listing_not_rented") return c.json({ error: message }, 409);
    if (message === "forbidden") return c.json({ error: message }, 403);
    return c.json({ error: "Internal server error" }, 500);
  }
});

listing_routes.patch("/:id", async (c) => {
  try {
    const id = c.req.param("id");
    const uid = c.get("user_uid");
    if (!uid) return c.json({ error: "Unauthorized" }, 401);

    const body = await c.req.json();
    await service.updateListing(id, uid, body);
    return c.json({ success: true }, 200);
  } catch (error) {
    const message = error instanceof Error ? error.message : "unknown_error";
    if (message === "listing_not_found") return c.json({ error: message }, 404);
    if (message === "forbidden") return c.json({ error: message }, 403);
    return c.json({ error: "Internal server error" }, 500);
  }
});

listing_routes.patch("/:id/status", async (c) => {
  try {
    const id = c.req.param("id");
    const uid = c.get("user_uid");
    if (!uid) return c.json({ error: "Unauthorized" }, 401);
    
    const body = await c.req.json();
    if(body.status) {
        await service.updateListingStatus(id, body.status, uid);
    }
    return c.json({ success: true }, 200);
  } catch (error) {
    const message = error instanceof Error ? error.message : "unknown_error";
    if (message === "listing_not_found") return c.json({ error: message }, 404);
    if (message === "listing_rented") return c.json({ error: message }, 409);
    if (message === "forbidden") return c.json({ error: message }, 403);
    if (message === "invalid_status") return c.json({ error: message }, 400);
    return c.json({ error: "Internal server error" }, 500);
  }
});

listing_routes.delete("/:id", async (c) => {
  try {
    const id = c.req.param("id");
    const uid = c.get("user_uid");
    if (!uid) return c.json({ error: "Unauthorized" }, 401);
    
    await service.deleteListing(id, uid);
    return c.json({ success: true }, 200);
  } catch (error) {
    const message = error instanceof Error ? error.message : "unknown_error";
    if (message === "listing_not_found") return c.json({ error: message }, 404);
    if (message === "listing_rented") return c.json({ error: message }, 409);
    if (message === "forbidden") return c.json({ error: message }, 403);
    return c.json({ error: "Internal server error" }, 500);
  }
});

export { listing_routes };
