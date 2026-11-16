import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { importPKCS8, SignJWT } from "https://esm.sh/jose@5";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-push-webhook-secret",
};

async function getGoogleAccessToken(serviceAccount: any): Promise<string> {
  const privateKey = await importPKCS8(serviceAccount.private_key, "RS256");
  const now = Math.floor(Date.now() / 1000);
  const assertion = await new SignJWT({ scope: "https://www.googleapis.com/auth/firebase.messaging" })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setIssuer(serviceAccount.client_email)
    .setSubject(serviceAccount.client_email)
    .setAudience("https://oauth2.googleapis.com/token")
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(privateKey);
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({ grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer", assertion }),
  });
  const result = await response.json();
  if (!response.ok) throw new Error(result.error_description || result.error || "Google OAuth failed");
  return result.access_token;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return new Response("Method not allowed", { status: 405 });

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !serviceRoleKey) {
      throw new Error("Supabase server configuration is missing");
    }
    const supabase = createClient(supabaseUrl, serviceRoleKey);

    // The webhook secret is stored encrypted in Supabase Vault, not in the
    // database trigger definition or an exposed environment variable.
    const { data: expectedSecret, error: secretError } = await supabase.rpc("cv_get_push_webhook_secret");
    if (secretError) throw new Error("Could not validate the push webhook configuration");
    const suppliedSecret = req.headers.get("x-push-webhook-secret");
    if (!expectedSecret || !suppliedSecret || suppliedSecret !== expectedSecret) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const payload = await req.json();
    const notification = payload.record ?? payload;
    if (!notification?.user_id || !notification?.title) {
      return new Response(JSON.stringify({ ignored: true, reason: "Missing recipient or title" }), {
        status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const serviceAccountRaw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
    if (!serviceAccountRaw) throw new Error("FIREBASE_SERVICE_ACCOUNT secret is missing");
    const serviceAccount = JSON.parse(serviceAccountRaw);

    const { data: devices, error: deviceError } = await supabase
      .from("cv_device_tokens").select("id, token").eq("user_id", notification.user_id);
    if (deviceError) throw deviceError;
    if (!devices?.length) {
      return new Response(JSON.stringify({ sent: 0, reason: "No registered devices for recipient" }), {
        status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const accessToken = await getGoogleAccessToken(serviceAccount);
    const results = await Promise.all(devices.map(async (device: { id: string; token: string }) => {
      const message = {
        token: device.token,
        notification: { title: notification.title, body: notification.body ?? "" },
        data: {
          notification_id: String(notification.id ?? ""),
          href: String(notification.href ?? ""),
          type: String(notification.type ?? ""),
          entity_type: String(notification.entity_type ?? ""),
          entity_id: String(notification.entity_id ?? ""),
        },
        android: { priority: "high", notification: { channel_id: "creatorverse_alerts", sound: "default" } },
      };
      const response = await fetch(
        `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
        {
          method: "POST",
          headers: { Authorization: `Bearer ${accessToken}`, "Content-Type": "application/json" },
          // FCM HTTP v1 requires the message to be nested inside the top-level { message: ... } object.
          body: JSON.stringify({ message }),
        },
      );
      const result = await response.json();
      if (!response.ok && result?.error?.details?.some((detail: any) => detail.errorCode === "UNREGISTERED")) {
        await supabase.from("cv_device_tokens").delete().eq("id", device.id);
      }
      return { ok: response.ok, result };
    }));

    const sent = results.filter((result) => result.ok).length;
    const failed = results.length - sent;
    return new Response(JSON.stringify({ sent, failed, results }), {
      status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("push notification error:", error);
    return new Response(JSON.stringify({ error: error instanceof Error ? error.message : "Unknown error" }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});