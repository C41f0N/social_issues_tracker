import { serve } from "https://deno.land/std/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !serviceRoleKey) {
      console.error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
      return new Response("Missing Supabase env vars", { status: 500 });
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey);

    const body = await req.json().catch((e) => {
      console.error("Invalid JSON body:", e);
      return null;
    });

    if (!body) {
      return new Response(JSON.stringify({ error: "invalid_json" }), { status: 400 });
    }

    const { user_id, email, full_name, username } = body as Record<string, unknown>;

    if (!user_id || !email || !full_name || !username) {
      console.error("Missing required fields", { user_id, email, full_name, username });
      return new Response(JSON.stringify({ error: "user_id, email, full_name, username required" }), { status: 400 });
    }

    const defaultRoleId = "00000000-0000-0000-0000-000000000001";

    const { data, error } = await supabase.rpc("create_user", {
      p_user_id: user_id,
      p_email: email,
      p_full_name: full_name,
      p_role_id: defaultRoleId,
      p_username: username,
    });

    if (error) {
      // log full error for debugging (safe since this runs server-side)
      console.error("RPC create_user error:", error);
      return new Response(JSON.stringify({ error: error.message ?? error }), { status: 400 });
    }

    return new Response(JSON.stringify({ user_id: data }), { status: 200 });
  } catch (err) {
    console.error("Unhandled error in create_user function:", err);
    return new Response(JSON.stringify({ error: String(err) }), { status: 500 });
  }
});