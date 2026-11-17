import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { AccessToken } from "npm:livekit-server-sdk@2.19.2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
};

function json(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: corsHeaders });
}

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (request.method !== "POST") return json({ error: "Method not allowed." }, 405);

  try {
    const authorization = request.headers.get("Authorization");
    if (!authorization?.startsWith("Bearer ")) return json({ error: "Sign in to start a call." }, 401);

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseKey = Deno.env.get("SUPABASE_ANON_KEY") ?? Deno.env.get("SUPABASE_PUBLISHABLE_KEY");
    if (!supabaseUrl || !supabaseKey) return json({ error: "Supabase function environment is incomplete." }, 500);

    const supabase = createClient(supabaseUrl, supabaseKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data: authData, error: authError } = await supabase.auth.getUser();
    if (authError || !authData.user) return json({ error: "Your session is invalid. Sign in again." }, 401);

    const body = await request.json();
    const conversationId = String(body.conversation_id ?? "");
    const callId = String(body.call_id ?? "");
    const mode = String(body.mode ?? "");
    if (!/^[0-9a-f-]{36}$/i.test(conversationId) ||
        !/^[A-Za-z0-9_-]{8,80}$/.test(callId) ||
        !["audio", "video"].includes(mode)) {
      return json({ error: "Invalid call request." }, 400);
    }

    // This query is scoped by the caller's JWT and the conversation's RLS policies.
    // A user who is not a direct-chat participant or group member cannot mint a room token.
    const { data: conversation, error: conversationError } = await supabase
      .from("cv_conversations")
      .select("id")
      .eq("id", conversationId)
      .maybeSingle();
    if (conversationError || !conversation) return json({ error: "You are not a member of this conversation." }, 403);

    const livekitUrl = Deno.env.get("LIVEKIT_URL");
    const livekitApiKey = Deno.env.get("LIVEKIT_API_KEY");
    const livekitApiSecret = Deno.env.get("LIVEKIT_API_SECRET");
    if (!livekitUrl || !livekitApiKey || !livekitApiSecret) {
      return json({ error: "LiveKit is not configured yet. Add LIVEKIT_URL, LIVEKIT_API_KEY and LIVEKIT_API_SECRET to Supabase Edge Function secrets." }, 503);
    }

    const roomName = `cv_${conversationId}_${callId}`;
    const token = new AccessToken(livekitApiKey, livekitApiSecret, {
      identity: authData.user.id,
      name: "CreatorVerse member",
      ttl: "10m",
    });
    token.addGrant({
      roomJoin: true,
      room: roomName,
      canPublish: true,
      canSubscribe: true,
      canPublishData: true,
    });

    return json({ url: livekitUrl, token: await token.toJwt(), room_name: roomName, mode });
  } catch (error) {
    console.error("LiveKit token request failed:", error);
    return json({ error: "Could not prepare this call. Please try again." }, 500);
  }
});
