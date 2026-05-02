import { MiddlewareHandler } from "hono";
import { auth } from "../config/firebase_admin";

export const auth_middleware: MiddlewareHandler = async (c, next) => {
  const authorization = c.req.header("Authorization") || "";
  const match = authorization.match(/^Bearer (.+)$/i);
  const token = match?.[1];

  if (!token) {
    return c.json({ error: "missing_auth_token" }, 401);
  }

  try {
    const decoded = await auth.verifyIdToken(token);
    c.set("user_uid", decoded.uid);
    c.set("user_email", decoded.email ?? null);
    await next();
    return;
  } catch (error) {
    return c.json({ error: "invalid_auth_token" }, 401);
  }
};
