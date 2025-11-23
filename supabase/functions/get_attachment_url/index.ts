import { serve } from "https://deno.land/std/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
serve(async (req)=>{
  try {
    const supabase = createClient(Deno.env.get("SUPABASE_URL"), Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"));
    // authenticate (optional depending on privacy)
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) return new Response(JSON.stringify({
      error: "Missing Authorization"
    }), {
      status: 401
    });
    const token = authHeader.replace("Bearer ", "");
    const { data: authData } = await supabase.auth.getUser(token);
    if (!authData.user) return new Response(JSON.stringify({
      error: "Unauthorized"
    }), {
      status: 401
    });
    const { attachment_id } = await req.json();
    // fetch path via RPC
    const { data: attachRows, error: attachErr } = await supabase.rpc("get_attachment", {
      p_attachment_id: attachment_id
    });
    if (attachErr || !attachRows || attachRows.length === 0) return new Response(JSON.stringify({
      error: "Attachment not found"
    }), {
      status: 404
    });
    const file_path = attachRows[0].file_path;
    const bucket = "issue_attachments";
    const { data: signed, error: signedErr } = await supabase.storage.from(bucket).createSignedUrl(file_path, 60 * 60);
    if (signedErr) return new Response(JSON.stringify({
      error: signedErr.message
    }), {
      status: 500
    });
    return new Response(JSON.stringify({
      url: signed.signedUrl
    }), {
      status: 200
    });
  } catch (e) {
    return new Response(JSON.stringify({
      error: e.message
    }), {
      status: 500
    });
  }
});
