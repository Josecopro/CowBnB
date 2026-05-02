import { onRequest } from "firebase-functions/v2/https";
import { app } from "./app";

export const api = onRequest(async (req, res) => {
	const host = req.headers.host ?? "localhost";
	const url = new URL(req.originalUrl ?? req.url, `http://${host}`);
	const method = req.method.toUpperCase();
	const body =
		method === "GET" || method === "HEAD"
			? undefined
			: (req.rawBody as unknown as BodyInit);
	const request = new Request(url, {
		method,
		headers: req.headers as HeadersInit,
		body,
	});

	const response = await app.fetch(request);

	res.status(response.status);
	response.headers.forEach((value, key) => {
		res.setHeader(key, value);
	});

	const buffer = Buffer.from(await response.arrayBuffer());
	res.send(buffer);
});
