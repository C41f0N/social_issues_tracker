import { serve } from "https://deno.land/std/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js";
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
    const form = await req.formData();
    const file = form.get("file");
    const issue_id = form.get("issue_id");
    const path = `${issue_id}/${crypto.randomUUID()}-${file.name}`;
    const { error: uploadErr } = await supabase.storage.from("attachments").upload(path, file);
    if (uploadErr) throw uploadErr;
    await supabase.from("attachment").insert({
      issue_id,
      file_path: path,
      user_id: user.id
    });
    return new Response(JSON.stringify({
      success: true,
      path
    }), {
      status: 200
    });
  } catch (e) {
    return new Response(JSON.stringify({
      error: e.message
    }), {
      status: 400
    });
  }
});
