import { serve } from "https://deno.land/std/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
serve(async (req)=>{
  try {
    const supabase = createClient(Deno.env.get("SUPABASE_URL"), Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"));
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) return new Response(JSON.stringify({
      error: "Unauthorized"
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
    // fetch attachment to validate permissions (uploader or issue owner)
    const { data: attachRows, error: attachErr } = await supabase.rpc("get_attachment", {
      p_attachment_id: attachment_id
    });
    if (attachErr || !attachRows || attachRows.length === 0) return new Response(JSON.stringify({
      error: "Attachment not found"
    }), {
      status: 404
    });
    const attachment = attachRows[0];
    // check permission: allow if user is uploader OR user is owner of associated issue
    const userId = authData.user.id;
    if (attachment.uploaded_by !== userId) {
      // check issue owner
      const { data: issueRows } = await supabase.from("issues").select("user_id").eq("issue_id", attachment.issue_id).single();
      if (!issueRows || issueRows.user_id !== userId) {
        return new Response(JSON.stringify({
          error: "Forbidden"
        }), {
          status: 403
        });
      }
    }
    // call RPC to delete DB row and receive file_path
    const { data: deletedPath, error: delErr } = await supabase.rpc("delete_attachment", {
      p_attachment_id: attachment_id
    });
    if (delErr) return new Response(JSON.stringify({
      error: delErr.message
    }), {
      status: 500
    });
    const bucket = "issue_attachments";
    // delete object from storage
    const { error: storageErr } = await supabase.storage.from(bucket).remove([
      deletedPath
    ]);
    if (storageErr) {
      // log but return success for DB deletion (or you may prefer to return error)
      return new Response(JSON.stringify({
        error: storageErr.message
      }), {
        status: 500
      });
    }
    return new Response(JSON.stringify({
      success: true
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
