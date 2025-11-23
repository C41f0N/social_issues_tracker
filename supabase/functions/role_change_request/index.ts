// /supabase/functions/submit_role_change_request/index.ts
import { serve } from "https://deno.land/std/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
serve(async (req)=>{
  const auth = req.headers.get("Authorization");
  if (!auth) return new Response("Unauthorized", {
    status: 401
  });
  const supabase = createClient(Deno.env.get("SUPABASE_URL"), Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"));
  const jwt = auth.replace("Bearer ", "");
  const { data: userInfo } = await supabase.auth.getUser(jwt);
  if (!userInfo.user) return new Response("Unauthorized", {
    status: 401
  });
  const { requested_role_id, admin_id } = await req.json();
  const { data, error } = await supabase.rpc("submit_role_change_request", {
    p_user_id: userInfo.user.id,
    p_requested_role_id: requested_role_id,
    p_admin_id: admin_id
  });
  if (error) return new Response(JSON.stringify({
    error
  }), {
    status: 400
  });
  return new Response(JSON.stringify({
    req_id: data
  }), {
    status: 200
  });
});
