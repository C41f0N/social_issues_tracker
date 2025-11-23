-- Add display_picture_path column to issues table
ALTER TABLE public.issues
ADD COLUMN IF NOT EXISTS display_picture_path TEXT;

-- Update create_issue function to accept display_picture_path parameter
-- Redefine create_issue with parameter order expected by backend edge functions
-- Signature: (p_description, p_display_picture_path, p_group_id, p_title, p_user_id)
CREATE OR REPLACE FUNCTION create_issue(
    p_title TEXT,
    p_description TEXT,
    p_user_id UUID,
    p_display_picture_path TEXT DEFAULT NULL,
    p_group_id UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    new_issue_id UUID;
BEGIN
    -- Map parameters into the issues table columns correctly
    INSERT INTO issues(user_id, title, description, group_id, display_picture_path)
    VALUES (p_user_id, p_title, p_description, p_group_id, p_display_picture_path)
    RETURNING issue_id INTO new_issue_id;

    RETURN new_issue_id;
END;
$$ LANGUAGE plpgsql;


-- Get issue by ID
CREATE OR REPLACE FUNCTION get_issue(p_issue_id UUID)
RETURNS TABLE (
    issue_id UUID,
    title TEXT,
    description TEXT,
    posted_at TIMESTAMPTZ,
    user_id UUID,
    group_id UUID,
    upvote_count INTEGER,
    display_picture_path TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        i.issue_id,
        i.title,
        i.description,
        i.posted_at,
        i.user_id,
        i.group_id,
        i.upvote_count,
        i.display_picture_path
    FROM issues i
    WHERE i.issue_id = p_issue_id;
END;
$$ LANGUAGE plpgsql;

-- Get attachments for an issue
CREATE OR REPLACE FUNCTION get_issue_attachments(p_issue_id UUID)
RETURNS TABLE (
    attachment_id UUID,
    issue_id UUID,
    uploaded_by UUID,
    file_path TEXT,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pa.attachment_id,
        pa.issue_id,
        pa.uploaded_by,
        pa.file_path,
        pa.created_at
    FROM post_attachments pa
    WHERE pa.issue_id = p_issue_id
    ORDER BY pa.created_at ASC;
END;
$$ LANGUAGE plpgsql;


