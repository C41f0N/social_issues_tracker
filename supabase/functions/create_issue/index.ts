// /supabase/functions/create_issue/index.ts
import { serve } from "https://deno.land/std@0.170.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Authentication
    const auth = req.headers.get("Authorization");
    if (!auth) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
      });
    }

    const jwt = auth.replace("Bearer ", "");
    const { data: session, error: authError } = await supabase.auth.getUser(jwt);
    if (authError || !session?.user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
      });
    }

    const userId = session.user.id;

    // Parse multipart/form-data
    const form = await req.formData();
    const title = form.get("title");
    const description = form.get("description");
    const displayPicture = form.get("display_picture") as File | null;
    const attachments = form.getAll("attachments") as File[];

    // Validate required fields
    if (!title || !description) {
      return new Response(
        JSON.stringify({ error: "title and description are required" }),
        { status: 400 }
      );
    }

    // Create issue first to get issue_id
    // Note: group_id is not allowed to be set in this endpoint, always null
    const { data: issueId, error: createError } = await supabase.rpc(
      "create_issue",
      {
        p_user_id: userId,
        p_title: title.toString(),
        p_description: description.toString(),
        p_group_id: null, // group_id is not allowed in this endpoint
        p_display_picture_path: null, // Will update after upload
      }
    );

    if (createError || !issueId) {
      return new Response(
        JSON.stringify({ error: createError?.message || "Failed to create issue" }),
        { status: 400 }
      );
    }

    const bucket = "attachments";
    const uploadedFiles: string[] = [];
    let displayPicturePath: string | null = null;
    let displayPictureUrl: string | null = null;

    try {
      // Upload display picture if provided
      if (displayPicture && displayPicture.size > 0) {
        const originalName = displayPicture.name || "display_picture";
        const ext = originalName.includes(".")
          ? originalName.split(".").pop()
          : "";
        const uuid = crypto.randomUUID();
        const fileName = ext ? `${uuid}.${ext}` : uuid;
        const storagePath = `${issueId}/${fileName}`;

        const { error: uploadError } = await supabase.storage
          .from(bucket)
          .upload(storagePath, displayPicture, {
            cacheControl: "3600",
            upsert: false,
          });

        if (uploadError) {
          throw new Error(`Failed to upload display picture: ${uploadError.message}`);
        }

        displayPicturePath = storagePath;
        uploadedFiles.push(storagePath);

        // Update issue with display picture path
        const { error: updateError } = await supabase
          .from("issues")
          .update({ display_picture_path: displayPicturePath })
          .eq("issue_id", issueId);

        if (updateError) {
          throw new Error(`Failed to update display picture path: ${updateError.message}`);
        }

        // Generate signed URL for display picture (valid for 1 hour)
        const { data: signedData, error: signedErr } = await supabase.storage
          .from(bucket)
          .createSignedUrl(storagePath, 60 * 60);

        if (!signedErr && signedData) {
          displayPictureUrl = signedData.signedUrl;
        }
      }

      // Upload attachments
      const attachmentUrls: string[] = [];
      for (const attachment of attachments) {
        if (attachment.size === 0) continue;

        const originalName = attachment.name || "attachment";
        const ext = originalName.includes(".")
          ? originalName.split(".").pop()
          : "";
        const uuid = crypto.randomUUID();
        const fileName = ext ? `${uuid}.${ext}` : uuid;
        const storagePath = `${issueId}/${fileName}`;

        const { error: uploadError } = await supabase.storage
          .from(bucket)
          .upload(storagePath, attachment, {
            cacheControl: "3600",
            upsert: false,
          });

        if (uploadError) {
          throw new Error(`Failed to upload attachment: ${uploadError.message}`);
        }

        uploadedFiles.push(storagePath);

        // Add attachment to database
        const { data: attachmentId, error: rpcError } = await supabase.rpc(
          "add_post_attachment",
          {
            p_issue_id: issueId,
            p_uploaded_by: userId,
            p_file_path: storagePath,
          }
        );

        if (rpcError) {
          throw new Error(`Failed to add attachment record: ${rpcError.message}`);
        }

        // Generate signed URL for attachment (valid for 1 hour)
        const { data: signedData, error: signedErr } = await supabase.storage
          .from(bucket)
          .createSignedUrl(storagePath, 60 * 60 * 24 * 30);

        if (!signedErr && signedData) {
          attachmentUrls.push(signedData.signedUrl);
        } else {
          // If signed URL generation fails, still include the path as fallback
          attachmentUrls.push(storagePath);
        }
      }

      return new Response(
        JSON.stringify({
          issue_id: issueId,
          display_picture_url: displayPictureUrl,
          attachment_urls: attachmentUrls,
        }),
        { status: 200 }
      );
    } catch (error) {
      // Rollback: delete uploaded files
      if (uploadedFiles.length > 0) {
        await supabase.storage
          .from(bucket)
          .remove(uploadedFiles)
          .catch(() => { });
      }

      // Delete the issue if we created it
      await supabase
        .from("issues")
        .delete()
        .eq("issue_id", issueId)
        .catch(() => { });

      return new Response(
        JSON.stringify({ error: error.message || "Failed to process files" }),
        { status: 500 }
      );
    }
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message || "Internal server error" }),
      { status: 500 }
    );
  }
});
