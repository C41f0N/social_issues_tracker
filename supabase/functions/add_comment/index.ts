import { serve } from "https://deno.land/std/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js";
import { z } from "https://deno.land/x/zod/mod.ts";
const bodySchema = z.object({
  issue_id: z.string(),
  content: z.string().min(1)
});
serve(async (req)=>{
  try {
    const supabase = createClient(Deno.env.get("SUPABASE_URL"), Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"));
    const auth = req.headers.get("Authorization");
    if (!auth) return new Response("Unauthorized", {
      status: 401
    });
    const user = (await supabase.auth.getUser(auth.replace("Bearer ", ""))).data.user;
    if (!user) return new Response("Unauthorized", {
      status: 401
    });
    const body = bodySchema.parse(await req.json());
    const { data, error } = await supabase.from("comment").insert({
      issue_id: body.issue_id,
      user_id: user.id,
      content: body.content
    }).select().single();
    if (error) throw error;
    return new Response(JSON.stringify(data), {
      status: 200
    });
  } catch (err) {
    return new Response(JSON.stringify({
      error: err.message
    }), {
      status: 400
    });
  }
});
