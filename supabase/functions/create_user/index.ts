// /supabase/functions/create_user/index.ts
import { serve } from "https://deno.land/std/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
serve(async (req)=>{
  const supabase = createClient(Deno.env.get("SUPABASE_URL"), Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"));
  const { email, full_name, role_id } = await req.json();
  const { data, error } = await supabase.rpc("create_user", {
    p_email: email,
    p_full_name: full_name,
    p_role_id: role_id
  });
  if (error) return new Response(JSON.stringify({
    error
  }), {
    status: 400
  });
  return new Response(JSON.stringify({
    user_id: data
  }), {
    status: 200
  });
});
