// /supabase/functions/upload_attachment/index.ts
import { serve } from "https://deno.land/std@0.170.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
serve(async (req)=>{
  try {
    const supabase = createClient(Deno.env.get("SUPABASE_URL"), Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"));
    // AUTH
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) return new Response(JSON.stringify({
      error: "Missing Authorization"
    }), {
      status: 401
    });
    const token = authHeader.replace("Bearer ", "");
    const { data: authData, error: authErr } = await supabase.auth.getUser(token);
    if (authErr || !authData.user) return new Response(JSON.stringify({
      error: "Unauthorized"
    }), {
      status: 401
    });
    const userId = authData.user.id;
    // parse form-data
    const form = await req.formData();
    const file = form.get("file");
    const issueId = form.get("issue_id");
    if (!file || !issueId) {
      return new Response(JSON.stringify({
        error: "file and issue_id are required"
      }), {
        status: 400
      });
    }
    // build path: issue_attachments/{issue_id}/{uuid}.{ext}
    const originalName = file.name || "file";
    const ext = originalName.includes(".") ? originalName.split(".").pop() : "";
    const uuid = crypto.randomUUID();
    const fileName = ext ? `${uuid}.${ext}` : uuid;
    const storagePath = `${issueId}/${fileName}`; // bucket root + path
    // upload to bucket 'issue_attachments'
    const bucket = "issue_attachments";
    const fileData = file.stream ? file.stream() : file; // Deno File
    const { error: uploadErr } = await supabase.storage.from(bucket).upload(storagePath, file, {
      cacheControl: "3600",
      upsert: false
    });
    if (uploadErr) {
      return new Response(JSON.stringify({
        error: uploadErr.message
      }), {
        status: 500
      });
    }
    // call RPC to insert DB record
    const { data: rpcData, error: rpcErr } = await supabase.rpc("add_post_attachment", {
      p_issue_id: issueId,
      p_uploaded_by: userId,
      p_file_path: storagePath
    });
    if (rpcErr) {
      // rollback: remove object from storage
      await supabase.storage.from(bucket).remove([
        storagePath
      ]).catch(()=>{});
      return new Response(JSON.stringify({
        error: rpcErr.message
      }), {
        status: 500
      });
    }
    const attachment_id = rpcData; // UUID returned by RPC
    // generate a signed URL (valid for 1 hour)
    const { data: signedData, error: signedErr } = await supabase.storage.from(bucket).createSignedUrl(storagePath, 60 * 60);
    if (signedErr) {
      return new Response(JSON.stringify({
        attachment_id,
        file_path: storagePath
      }), {
        status: 200
      });
    }
    return new Response(JSON.stringify({
      attachment_id,
      file_path: storagePath,
      url: signedData.signedUrl
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
