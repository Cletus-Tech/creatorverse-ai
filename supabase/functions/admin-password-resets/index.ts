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
const resetRedirect = "https://creatorverse-ai.vercel.app/reset.html";

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
    const mailer = createClient(url, anonKey, { auth: { persistSession: false, autoRefreshToken: false } });
    let targets: Array<{ id: string; email: string }> = [];

    if (action === "one") {
      const userId = String(body.user_id ?? "");
      if (!/^[0-9a-f-]{36}$/i.test(userId)) return json({ error: "Choose a valid account." }, 400);
      const { data, error } = await admin.auth.admin.getUserById(userId);
      if (error || !data.user?.email) return json({ error: "That account has no usable email address." }, 404);
      targets = [{ id: data.user.id, email: data.user.email }];
    } else if (action === "all") {
      let page = 1;
      const perPage = 500;
      while (true) {
        const { data, error } = await admin.auth.admin.listUsers({ page, perPage });
        if (error) return json({ error: "Could not load registered accounts for bulk reset." }, 500);
        const users = data.users ?? [];
        targets.push(...users.filter((u) => !!u.email).map((u) => ({ id: u.id, email: u.email! })));
        if (users.length < perPage) break;
        page += 1;
        if (page > 20) return json({ error: "The account list is too large for one request. Contact support to run a managed bulk reset." }, 413);
      }
      if (!targets.length) return json({ sent: 0, failed: 0, message: "No registered accounts with email addresses were found." });
    } else {
      return json({ error: "Choose one account or all accounts." }, 400);
    }

    let sent = 0;
    const failures: string[] = [];
    // Keep the batch small to avoid overwhelming the configured SMTP provider.
    for (let i = 0; i < targets.length; i += 2) {
      const batch = targets.slice(i, i + 2);
      const outcomes = await Promise.all(batch.map(async (target) => {
        const { error } = await mailer.auth.resetPasswordForEmail(target.email, { redirectTo: resetRedirect });
        return { email: target.email, error };
      }));
      for (const outcome of outcomes) {
        if (outcome.error) failures.push(outcome.email);
        else sent += 1;
      }
    }
    return json({
      attempted: targets.length,
      sent,
      failed: failures.length,
      message: action === "one"
        ? (sent ? "A password reset email has been requested for the selected account." : "The reset email could not be sent. Check your Auth email/SMTP settings.")
        : "Bulk reset email request finished. Review the sent and failed counts; email delivery is subject to your SMTP provider's limits.",
    });
  } catch (error) {
    console.error("Admin password reset request failed:", error);
    return json({ error: "The password reset request could not be completed." }, 500);
  }
});
