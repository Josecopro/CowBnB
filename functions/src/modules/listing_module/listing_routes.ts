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
    const { title, description, size, price, features, images } = body;

    // images array should be { base64: string, ext: string }[]
    if (!title || !description || size == null || price == null) {
      return c.json({ error: "Missing required fields" }, 400);
    }

    const listingId = await service.createListing(uid, {
      title,
      description,
      size: Number(size),
      price: Number(price),
      features: features || [],
    }, images || []);

    return c.json({ id: listingId, success: true }, 201);
  } catch (error) {
    console.error("Error creating listing", error);
    return c.json({ error: "Internal server error" }, 500);
  }
});

export { listing_routes };
