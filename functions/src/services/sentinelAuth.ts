import axios from "axios";

let cachedToken: string | null = null;
let tokenExpiry: number | null = null;

export async function getSentinelToken(): Promise<string> {
  if (cachedToken && Date.now() < (tokenExpiry ?? 0)) {
    return cachedToken;
  }

  const params = new URLSearchParams({
    grant_type: "client_credentials",
    client_id: process.env.SENTINEL_CLIENT_ID,
    client_secret: process.env.SENTINEL_CLIENT_SECRET,
  });

  const response = await axios.post(
    "https://identity.dataspace.copernicus.eu/auth/realms/CDSE/protocol/openid-connect/token",
    params.toString(),
    { headers: { "Content-Type": "application/x-www-form-urlencoded" } },
  );

  cachedToken = response.data.access_token;
  // Renovar 5 minutos antes de que expire
  tokenExpiry = Date.now() + (response.data.expires_in - 300) * 1000;

  return cachedToken;
}