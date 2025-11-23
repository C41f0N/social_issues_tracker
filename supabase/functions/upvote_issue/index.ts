import { serve } from "https://deno.land/std/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js";
import { z } from "https://deno.land/x/zod/mod.ts";
const schema = z.object({
  issue_id: z.string(),
  weight: z.number()
});
serve(async (req)=>{
  try {
    const supabase = createClient(Deno.env.get("SUPABASE_URL"), Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"));
    const auth = req.headers.get("Authorization");
    if (!auth) return new Response("Unauthorized", {
      status: 401
    });
    const user = (await supabase.auth.getUser(auth.replace("Bearer ", ""))).data.user;
    const body = schema.parse(await req.json());
    // insert upvote
    await supabase.from("issue_upvote").insert({
      issue_id: body.issue_id,
      user_id: user.id,
      weight: body.weight
    });
    return new Response(JSON.stringify({
      success: true
    }), {
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
