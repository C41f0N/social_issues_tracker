// /supabase/functions/get_issue/index.ts
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

        // Get issue_id from query params or request body
        const url = new URL(req.url);
        let issueId = url.searchParams.get("issue_id");

        if (!issueId) {
            try {
                const body = await req.json();
                issueId = body.issue_id;
            } catch {
                // If JSON parsing fails, try to get from query params again
            }
        }

        if (!issueId) {
            return new Response(
                JSON.stringify({ error: "issue_id is required" }),
                { status: 400 }
            );
        }

        // Fetch issue from database using RPC function
        const { data: issueRows, error: issueError } = await supabase.rpc(
            "get_issue",
            { p_issue_id: issueId }
        );

        if (issueError || !issueRows || issueRows.length === 0) {
            return new Response(
                JSON.stringify({ error: "Issue not found" }),
                { status: 404 }
            );
        }

        const issue = issueRows[0];
        const bucket = "attachments";
        let displayPictureUrl: string | null = null;

        // Generate signed URL for display picture if it exists
        if (issue.display_picture_path) {
            const { data: signedData, error: signedErr } = await supabase.storage
                .from(bucket)
                .createSignedUrl(issue.display_picture_path, 60 * 60 * 24 * 30);

            if (!signedErr && signedData) {
                displayPictureUrl = signedData.signedUrl;
            }
        }

        // Fetch attachments for this issue using RPC function
        const { data: attachments, error: attachmentsError } = await supabase.rpc(
            "get_issue_attachments",
            { p_issue_id: issueId }
        );

        const attachmentUrls: Array<{
            attachment_id: string;
            file_path: string;
            url: string;
            uploaded_by: string;
            created_at: string;
        }> = [];

        if (attachments && !attachmentsError) {
            // Generate signed URLs for each attachment
            for (const attachment of attachments) {
                const { data: signedData, error: signedErr } = await supabase.storage
                    .from(bucket)
                    .createSignedUrl(attachment.file_path, 60 * 60 * 24 * 30);

                if (!signedErr && signedData) {
                    attachmentUrls.push({
                        attachment_id: attachment.attachment_id,
                        file_path: attachment.file_path,
                        url: signedData.signedUrl,
                        uploaded_by: attachment.uploaded_by,
                        created_at: attachment.created_at,
                    });
                } else {
                    // If signed URL generation fails, still include the attachment with path
                    attachmentUrls.push({
                        attachment_id: attachment.attachment_id,
                        file_path: attachment.file_path,
                        url: attachment.file_path, // Fallback to path
                        uploaded_by: attachment.uploaded_by,
                        created_at: attachment.created_at,
                    });
                }
            }
        }

        // Return issue data with URLs
        return new Response(
            JSON.stringify({
                issue_id: issue.issue_id,
                title: issue.title,
                description: issue.description,
                posted_at: issue.posted_at,
                user_id: issue.user_id,
                group_id: issue.group_id,
                upvote_count: issue.upvote_count,
                display_picture_url: displayPictureUrl,
                attachments: attachmentUrls,
            }),
            { status: 200 }
        );
    } catch (error) {
        return new Response(
            JSON.stringify({ error: error.message || "Internal server error" }),
            { status: 500 }
        );
    }
});

