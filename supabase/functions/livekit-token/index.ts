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
    const callId = String(body.call_id ?? "");
    const requestedMode = String(body.mode ?? "");
    if (!/^[0-9a-f-]{36}$/i.test(callId) || !["audio", "video"].includes(requestedMode)) {
      return json({ error: "Invalid call request." }, 400);
    }

    // This RLS-protected RPC returns an invite only to its caller or invited participant.
    const { data: invite, error: inviteError } = await supabase.rpc("cv_get_call_invite", {
      p_call_id: callId,
    });
    if (inviteError || !invite) return json({ error: "Call invite not found or access denied." }, 403);
    if (![invite.caller_id, invite.callee_id].includes(authData.user.id)) {
      return json({ error: "You are not a participant in this call." }, 403);
    }
    if (invite.mode !== requestedMode || !["ringing", "accepted"].includes(invite.status)) {
      return json({ error: "This call is no longer available." }, 410);
    }
    if (new Date(invite.expires_at).getTime() < Date.now()) {
      return json({ error: "This call invitation has expired." }, 410);
    }

    const livekitUrl = Deno.env.get("LIVEKIT_URL");
    const livekitApiKey = Deno.env.get("LIVEKIT_API_KEY");
    const livekitApiSecret = Deno.env.get("LIVEKIT_API_SECRET");
    if (!livekitUrl || !livekitApiKey || !livekitApiSecret) {
      return json({ error: "LiveKit is not configured yet. Add LIVEKIT_URL, LIVEKIT_API_KEY and LIVEKIT_API_SECRET to Supabase Edge Function secrets." }, 503);
    }

    const roomName = `cvcall_${callId}`;
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

    return json({ url: livekitUrl, token: await token.toJwt(), room_name: roomName, mode: invite.mode });
  } catch (error) {
    console.error("LiveKit token request failed:", error);
    return json({ error: "Could not prepare this call. Please try again." }, 500);
  }
});
