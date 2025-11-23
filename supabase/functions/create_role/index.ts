// /supabase/functions/create_role/index.ts
import { serve } from "https://deno.land/std/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
serve(async (req)=>{
  const supabase = createClient(Deno.env.get("SUPABASE_URL"), Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"));
  const { title, description, upvote_weight } = await req.json();
  const { data, error } = await supabase.rpc("create_role", {
    p_title: title,
    p_description: description,
    p_upvote_weight: upvote_weight ?? 1
  });
  if (error) return new Response(JSON.stringify({
    error
  }), {
    status: 400
  });
  return new Response(JSON.stringify({
    role_id: data
  }), {
    status: 200
  });
});
