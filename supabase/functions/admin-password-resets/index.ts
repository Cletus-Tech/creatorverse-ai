import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

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
    if (!authorization?.startsWith("Bearer ")) return json({ error: "Sign in is required." }, 401);
    const url = Deno.env.get("SUPABASE_URL");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? Deno.env.get("SUPABASE_PUBLISHABLE_KEY");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!url || !anonKey || !serviceKey) return json({ error: "Password reset service is not configured." }, 500);

    const callerClient = createClient(url, anonKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data: authData, error: authError } = await callerClient.auth.getUser();
    if (authError || !authData.user) return json({ error: "Your session is invalid. Sign in again." }, 401);

    const admin = createClient(url, serviceKey, { auth: { persistSession: false, autoRefreshToken: false } });
    const { data: profile, error: profileError } = await admin.from("profiles")
      .select("role").eq("id", authData.user.id).maybeSingle();
    if (profileError || profile?.role !== "super_admin") return json({ error: "Only the super admin can send password reset requests." }, 403);

    const body = await request.json();
    const action = String(body.action ?? "");

    if (action === "complete") {
      const current = authData.user.app_metadata ?? {};
      if (current.force_password_change !== true) return json({ ok: true });
      const { error } = await admin.auth.admin.updateUserById(authData.user.id, {
        app_metadata: { ...current, force_password_change: false },
      });
      if (error) return json({ error: "Password changed, but security confirmation failed. Contact support." }, 500);
      return json({ ok: true, message: "Password change confirmed." });
    }

    const { data: profile, error: profileError } = await admin.from("profiles")
      .select("role").eq("id", authData.user.id).maybeSingle();
    if (profileError || !["admin", "super_admin"].includes(profile?.role ?? "")) {
      return json({ error: "Only an administrator can reset student passwords." }, 403);
    }
    if (action !== "temporary") return json({ error: "Invalid reset action." }, 400);
    const userId = String(body.user_id ?? "");
    if (!/^[0-9a-f-]{36}$/i.test(userId)) return json({ error: "Choose a valid student account." }, 400);
    const { data: targetProfile, error: targetProfileError } = await admin.from("profiles")
      .select("id,role").eq("id", userId).maybeSingle();
    if (targetProfileError || !targetProfile) return json({ error: "Student account was not found." }, 404);
    if (targetProfile.role !== "student" || userId === authData.user.id) {
      return json({ error: "This action is restricted to student accounts." }, 403);
    }
    const { data: targetAuth, error: targetAuthError } = await admin.auth.admin.getUserById(userId);
    if (targetAuthError || !targetAuth.user) return json({ error: "Student Auth account was not found." }, 404);

    const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#$%";
    const random = new Uint8Array(20);
    crypto.getRandomValues(random);
    const temporaryPassword = Array.from(random, (v) => alphabet[v % alphabet.length]).join("");
    const existingMetadata = targetAuth.user.app_metadata ?? {};
    const { error: updateError } = await admin.auth.admin.updateUserById(userId, {
      password: temporaryPassword,
      app_metadata: { ...existingMetadata, force_password_change: true },
    });
    if (updateError) return json({ error: updateError.message || "Could not reset the student's password." }, 400);
    const { error: revokeError } = await admin.auth.admin.signOut(userId, "global");
    if (revokeError) console.error("Could not revoke existing student sessions:", revokeError);
    return json({
      ok: true,
      temporary_password: temporaryPassword,
      message: "A unique temporary password was generated. Share it privately with the student; they must change it at their next sign-in.",
      force_password_change: true,
    });
  } catch (error) {
    console.error("Admin password reset request failed:", error);
    return json({ error: "The password reset request could not be completed." }, 500);
  }
});
