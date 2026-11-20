import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { AccessToken, RoomServiceClient } from "npm:livekit-server-sdk@2.19.2";

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
    const interviewId = String(body.interview_id ?? "");
    const callId = String(body.call_id ?? "");
    let roomName = "";
    let mode = "";

    if (interviewId) {
      if (!/^[0-9a-f-]{36}$/i.test(interviewId)) return json({ error: "Invalid interview request." }, 400);
      const { data: canAccess, error: accessError } = await supabase.rpc("can_access_academy_interview", {
        p_interview_id: interviewId,
      });
      if (accessError || canAccess !== true) return json({ error: "You are not authorised to enter this interview." }, 403);
      const { data: interview, error: interviewError } = await supabase
        .from("academy_interviews")
        .select("id,interview_type")
        .eq("id", interviewId)
        .maybeSingle();
      if (interviewError || !interview || interview.interview_type !== "live") {
        return json({ error: "This live interview is unavailable." }, 404);
      }
      roomName = `cvacademy_${interviewId}`;
      mode = "academy_live";
    } else {
      const requestedMode = String(body.mode ?? "");
      if (!/^[0-9a-f-]{36}$/i.test(callId) || !["audio", "video"].includes(requestedMode)) {
        return json({ error: "Invalid call request." }, 400);
      }
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
      roomName = `cvcall_${callId}`;
      mode = invite.mode;
    }

    const configuredLivekitUrl = Deno.env.get("LIVEKIT_URL");
    const livekitApiKey = Deno.env.get("LIVEKIT_API_KEY");
    const livekitApiSecret = Deno.env.get("LIVEKIT_API_SECRET");
    if (!configuredLivekitUrl || !livekitApiKey || !livekitApiSecret) {
      return json({ error: "LiveKit is not configured yet. Add LIVEKIT_URL, LIVEKIT_API_KEY and LIVEKIT_API_SECRET to Supabase Edge Function secrets." }, 503);
    }

    const livekitUrl = configuredLivekitUrl.trim().replace(/^https:/i, "wss:").replace(/^http:/i, "ws:").replace(/\/+$/, "");
    if (!/^wss?:\/\//i.test(livekitUrl)) return json({ error: "LIVEKIT_URL must be the WebSocket URL from the same LiveKit project as the API key." }, 503);

    const livekitApiHost = livekitUrl.replace(/^wss:/i, "https:").replace(/^ws:/i, "http:");
    try {
      // Validate the key/secret pair against the selected LiveKit project before issuing a participant token.
      await new RoomServiceClient(livekitApiHost, livekitApiKey, livekitApiSecret).listRooms([roomName]);
    } catch (validationError) {
      console.error("LiveKit credential validation failed:", validationError);
      return json({ error: "LiveKit rejected the configured API key/secret. Confirm LIVEKIT_URL, LIVEKIT_API_KEY and LIVEKIT_API_SECRET all belong to the same LiveKit project." }, 503);
    }
    const token = new AccessToken(livekitApiKey, livekitApiSecret, {
      identity: authData.user.id,
      name: mode === "academy_live" ? "CreatorVerse Academy participant" : "CreatorVerse member",
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
