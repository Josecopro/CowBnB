import { Hono } from "hono";
import { logger } from "hono/logger";
import { cors } from "hono/cors";
import { auth_routes } from "./modules/auth_module";
import { AppVariables } from "./app_types";

const app = new Hono<{ Variables: AppVariables }>();

app.use("*", logger());
app.use(
  "*",
  cors({
    origin: "*",
    allowHeaders: ["Authorization", "Content-Type"],
    allowMethods: ["GET", "POST", "OPTIONS"],
  })
);

app.get("/api/health", (c) => c.json({ status: "ok" }));
app.route("/api/auth", auth_routes);

export { app };
