import { AccessToken } from "npm:livekit-server-sdk@2.emand";

const cors = { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type" };
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const auth = req.headers.get("Authorization");
    if (!auth) return new Response("Unauthorized", { status: 401, headers: cors });
    const body = await req.json();
    const room = String(body.room ?? "");
    const identity = String(body.identity ?? "");
    const name = String(body.name ?? "Player");
    if (!room || !identity || room.length > 80 || identity.length > 100) throw new Error("Invalid room or identity");
    const apiKey = Deno.env.get("LIVEKIT_API_KEY");
    const apiSecret = Deno.env.get("LIVEKIT_API_SECRET");
    const url = Deno.env.get("LIVEKIT_URL");
    if (!apiKey || !apiSecret || !url) throw new Error("LiveKit secrets are not configured on Supabase");
    const token = new AccessToken(apiKey, apiSecret, { identity, name, ttl: "2h" });
    token.addGrant({ roomJoin: true, room, canPublish: true, canSubscribe: true, canPublishData: true });
    return new Response(JSON.stringify({ token: await token.toJwt(), url }), { headers: { ...cors, "Content-Type": "application/json" } });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 400, headers: { ...cors, "Content-Type": "application/json" } });
  }
});