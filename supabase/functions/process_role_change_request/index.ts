// /supabase/functions/process_role_change_request/index.ts
import { serve } from "https://deno.land/std/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
serve(async (req)=>{
  const supabase = createClient(Deno.env.get("SUPABASE_URL"), Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"));
  const { req_id, status } = await req.json();
  const { error } = await supabase.rpc("process_role_change_request", {
    p_req_id: req_id,
    p_status: status
  });
  if (error) return new Response(JSON.stringify({
    error
  }), {
    status: 400
  });
  return new Response(JSON.stringify({
    success: true
  }), {
    status: 200
  });
});
