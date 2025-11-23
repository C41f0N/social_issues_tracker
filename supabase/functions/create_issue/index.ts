// /supabase/functions/create_issue/index.ts
import { serve } from "https://deno.land/std/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
serve(async (req)=>{
  const auth = req.headers.get("Authorization");
  if (!auth) return new Response("Unauthorized", {
    status: 401
  });
  const supabase = createClient(Deno.env.get("SUPABASE_URL"), Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"));
  const jwt = auth.replace("Bearer ", "");
  const { data: session } = await supabase.auth.getUser(jwt);
  const { title, description, group_id } = await req.json();
  const { data, error } = await supabase.rpc("create_issue", {
    p_user_id: session.user.id,
    p_title: title,
    p_description: description,
    p_group_id: group_id ?? null
  });
  if (error) return new Response(JSON.stringify({
    error
  }), {
    status: 400
  });
  return new Response(JSON.stringify({
    issue_id: data
  }), {
    status: 200
  });
});
