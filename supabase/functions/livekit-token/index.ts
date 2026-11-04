import { AccessToken } from "npm:livekit-server-sdk@2.13.3";
import { createClient } from "npm:@supabase/supabase-js@2";

const cors = { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type" };
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const authorization = req.headers.get("Authorization");
    if (!authorization) return new Response("Unauthorized", { status: 401, headers: cors });
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const supabase = createClient(supabaseUrl, anonKey, { global: { headers: { Authorization: authorization } } });
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) return new Response("Unauthorized", { status: 401, headers: cors });
    const body = await req.json();
    const room = String(body.room ?? "");
    const name = String(body.name ?? "Player");
    if (!room || room.length > 80) throw new Error("Invalid room");
    const { data: member, error: memberError } = await supabase
      .from("muhaybis_members").select("room_id").eq("room_id", room).eq("user_id", user.id).maybeSingle();
    if (memberError || !member) return new Response("Not a room member", { status: 403, headers: cors });
    const apiKey = Deno.env.get("LIVEKIT_API_KEY");
    const apiSecret = Deno.env.get("LIVEKIT_API_SECRET");
    const livekitUrl = Deno.env.get("LIVEKIT_URL");
    if (!apiKey || !apiSecret || !livekitUrl) throw new Error("LiveKit secrets are not configured on Supabase");
    const token = new AccessToken(apiKey, apiSecret, { identity: user.id, name: name.slice(0, 60), ttl: "2h" });
    token.addGrant({ roomJoin: true, room, canPublish: true, canSubscribe: true, canPublishData: true });
    return new Response(JSON.stringify({ token: await token.toJwt(), url: livekitUrl }), { headers: { ...cors, "Content-Type": "application/json" } });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 400, headers: { ...cors, "Content-Type": "application/json" } });
  }
});