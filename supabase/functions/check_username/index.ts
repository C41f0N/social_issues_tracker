import { serve } from "https://deno.land/std/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
    if (req.method !== "POST") {
        return new Response("Method not allowed", { status: 405 });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
    if (!supabaseUrl || !anonKey) {
        return new Response("Missing Supabase env vars", { status: 500 });
    }

    const supabase = createClient(supabaseUrl, anonKey);
    const { username } = await req.json();

    if (!username || typeof username !== "string") {
        return new Response(JSON.stringify({ error: "username required" }), {
            status: 400,
        });
    }

    const { data, error } = await supabase.rpc("is_username_taken", {
        p_username: username,
    });

    if (error) {
        return new Response(JSON.stringify({ error }), { status: 400 });
    }

    return new Response(JSON.stringify({ taken: data }), { status: 200 });
});
