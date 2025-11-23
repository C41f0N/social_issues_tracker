GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated;

GRANT SELECT ON TABLE public.users TO anon, authenticated;
GRANT SELECT ON TABLE public.roles TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON TABLE public.users TO authenticated;


CREATE SCHEMA public;
SET search_path TO public;



-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

---------------------------------------
-- ROLES
---------------------------------------
CREATE TABLE public.roles (
    role_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title        TEXT NOT NULL,
    description  TEXT,
    upvote_weight INTEGER NOT NULL DEFAULT 1
);

-- Seed default citizen role with stable id '1'
INSERT INTO public.roles (role_id, title, description, upvote_weight)
VALUES (
    '00000000-0000-0000-0000-000000000001',
    'Citizen',
    'Default citizen role',
    1
)
ON CONFLICT (role_id) DO NOTHING;

---------------------------------------
-- USERS
---------------------------------------

CREATE TABLE public.users (
    user_id    UUID PRIMARY KEY,
    email      TEXT UNIQUE NOT NULL,
    full_name  TEXT NOT NULL,
    role_id    UUID NOT NULL REFERENCES roles(role_id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    username    TEXT NOT NULL UNIQUE
);
------------------------------------------
-- ADMIN
------------------------------------------
CREATE TABLE public.admin (
    admin_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL
);

---------------------------------------
-- GROUPS
---------------------------------------
CREATE TABLE public.groups (
    group_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        TEXT NOT NULL,
    description TEXT,
    owner_id    UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

---------------------------------------
-- ISSUES (POSTS)
---------------------------------------
CREATE TABLE public.issues (
    issue_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title        TEXT NOT NULL,
    description  TEXT NOT NULL,
    posted_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    user_id      UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    group_id     UUID REFERENCES groups(group_id) ON DELETE SET NULL,
    upvote_count INTEGER NOT NULL DEFAULT 0
);

-- A post can belong to only ONE group → no extra table needed

---------------------------------------
-- COMMENTS
---------------------------------------
CREATE TABLE public.comments (
    comment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    issue_id   UUID NOT NULL REFERENCES issues(issue_id) ON DELETE CASCADE,
    user_id    UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    content    TEXT NOT NULL,
    posted_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

------------------------------------------
-- POST ATTACHMENTS
------------------------------------------
CREATE TABLE public.post_attachments (
    attachment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    issue_id UUID NOT NULL REFERENCES issues(issue_id) ON DELETE CASCADE,
    uploaded_by UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    file_path TEXT NOT NULL,                
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

---------------------------------------
-- ISSUE UPVOTES (POST UPVOTES)
---------------------------------------
CREATE TABLE public.issue_upvotes (
    upvote_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    issue_id  UUID NOT NULL REFERENCES issues(issue_id) ON DELETE CASCADE,
    user_id   UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    made_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(issue_id, user_id)
);

---------------------------------------
-- GROUP UPVOTES
---------------------------------------
CREATE TABLE public.group_upvotes (
    group_upvote_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id        UUID NOT NULL REFERENCES groups(group_id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    made_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(group_id, user_id)
);

---------------------------------------
-- REQUEST: ADD POST TO GROUP
---------------------------------------
-- Either:
-- 1) Post author requests group owner 
-- OR  
-- 2) Group owner requests post author


CREATE TABLE public.group_join_request (
    req_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    issue_id      UUID NOT NULL REFERENCES issues(issue_id) ON DELETE CASCADE,
    group_id      UUID NOT NULL REFERENCES groups(group_id) ON DELETE CASCADE,
    requested_by_group BOOLEAN NOT NULL, -- true if request made by group owner, false if made by post author
    status        TEXT NOT NULL DEFAULT 'pending',  -- pending, approved, rejected
    handled_at    TIMESTAMPTZ,
    requested_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(issue_id, group_id)
);


---------------------------------------
-- ROLE CHANGE REQUEST
---------------------------------------
CREATE TABLE public.role_change_request (
    req_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    requested_role_id UUID NOT NULL REFERENCES roles(role_id),
    status        TEXT NOT NULL DEFAULT 'pending', -- pending / approved / rejected
    submitted_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    reviewed_by_admin UUID REFERENCES users(user_id),
    reviewed_at   TIMESTAMPTZ
);
INSERT INTO storage.buckets (id, name, public)
VALUES ('attachments', 'attachments', false)
ON CONFLICT (id) DO NOTHING;

-- Users can upload into their folder
DROP POLICY IF EXISTS "Users can upload attachments" ON storage.objects;

CREATE POLICY "Users can upload attachments"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'attachments'
    AND (storage.foldername(name))[1] = auth.uid()::text
);
-- =========================================
-- 1️⃣ Create a new role
-- =========================================
CREATE OR REPLACE FUNCTION create_role(
    p_title TEXT,
    p_description TEXT,
    p_upvote_weight INTEGER DEFAULT 1
)
RETURNS UUID AS $$
DECLARE
    new_role_id UUID;
BEGIN
    INSERT INTO roles(title, description, upvote_weight)
    VALUES (p_title, p_description, p_upvote_weight)
    RETURNING role_id INTO new_role_id;

    RETURN new_role_id;
END;
$$ LANGUAGE plpgsql;

-- =========================================
-- 2️⃣ Create a new user
-- =========================================
CREATE OR REPLACE FUNCTION create_user(
    p_user_id UUID,
    p_email TEXT,
    p_full_name TEXT,
    p_role_id UUID,
    p_username TEXT
)
RETURNS UUID AS $$
DECLARE
    new_user_id UUID;
BEGIN
    INSERT INTO users(user_id, email, full_name, role_id, username)
    VALUES (p_user_id, p_email, p_full_name, p_role_id, p_username)
    RETURNING user_id INTO new_user_id;

    RETURN new_user_id;
END;
$$ LANGUAGE plpgsql;

-- Check if a username is already taken; returns true if exists
CREATE OR REPLACE FUNCTION is_username_taken(
    p_username TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    exists_bool BOOLEAN;
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM users WHERE username = p_username
    ) INTO exists_bool;

    RETURN exists_bool;
END;
$$ LANGUAGE plpgsql;

-- =========================================
-- 3️⃣ Submit role change request
-- =========================================
CREATE OR REPLACE FUNCTION submit_role_change_request(
    p_user_id UUID,
    p_requested_role_id UUID,
    p_admin_id UUID
)
RETURNS UUID AS $$
DECLARE
    new_req_id UUID;
BEGIN
    INSERT INTO role_change_request(user_id, requested_role_id, reviewed_by_admin)
    VALUES (p_user_id, p_requested_role_id, p_admin_id)
    RETURNING req_id INTO new_req_id;

    RETURN new_req_id;
END;
$$ LANGUAGE plpgsql;

-- =========================================
-- 4️⃣ Process role change request (admin)
-- =========================================
CREATE OR REPLACE FUNCTION process_role_change_request(
    p_req_id UUID,
    p_status TEXT -- 'approved' or 'rejected'
)
RETURNS VOID AS $$
DECLARE
    v_user_id UUID;
    v_role_id UUID;
BEGIN
    SELECT user_id, requested_role_id
    INTO v_user_id, v_role_id
    FROM role_change_request
    WHERE req_id = p_req_id;

    UPDATE role_change_request
    SET status = p_status,
        reviewed_at = NOW()
    WHERE req_id = p_req_id;

    IF p_status = 'approved' THEN
        UPDATE users
        SET role_id = v_role_id
        WHERE user_id = v_user_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- =========================================
-- 5️⃣ Create a new issue (post)
-- =========================================
CREATE OR REPLACE FUNCTION create_issue(
    p_user_id UUID,
    p_title TEXT,
    p_description TEXT,
    p_group_id UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    new_issue_id UUID;
BEGIN
    INSERT INTO issues(user_id, title, description, group_id)
    VALUES (p_user_id, p_title, p_description, p_group_id)
    RETURNING issue_id INTO new_issue_id;

    RETURN new_issue_id;
END;
$$ LANGUAGE plpgsql;

-- =========================================
-- 6️⃣ Add comment to an issue
-- =========================================
CREATE OR REPLACE FUNCTION add_comment(
    p_issue_id UUID,
    p_user_id UUID,
    p_content TEXT
)
RETURNS UUID AS $$
DECLARE
    new_comment_id UUID;
BEGIN
    INSERT INTO comments(issue_id, user_id, content)
    VALUES (p_issue_id, p_user_id, p_content)
    RETURNING comment_id INTO new_comment_id;

    RETURN new_comment_id;
END;
$$ LANGUAGE plpgsql;

-- =========================================
-- 7️⃣ Add attachment to issue
-- =========================================
CREATE OR REPLACE FUNCTION add_post_attachment(
    p_issue_id UUID,
    p_uploaded_by UUID,
    p_file_path TEXT
)
RETURNS UUID AS $$
DECLARE
    new_attachment_id UUID;
BEGIN
    INSERT INTO post_attachments(issue_id, uploaded_by, file_path)
    VALUES (p_issue_id, p_uploaded_by, p_file_path)
    RETURNING attachment_id INTO new_attachment_id;

    RETURN new_attachment_id;
END;
$$ LANGUAGE plpgsql;

--get attachment
CREATE OR REPLACE FUNCTION get_attachment(p_attachment_id UUID)
RETURNS TABLE (
  attachment_id UUID,
  issue_id UUID,
  uploaded_by UUID,
  file_path TEXT,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
    SELECT attachment_id, issue_id, uploaded_by, file_path, created_at
    FROM post_attachments
    WHERE attachment_id = p_attachment_id;
END;
$$ LANGUAGE plpgsql;

--delete attachment
CREATE OR REPLACE FUNCTION delete_attachment(p_attachment_id UUID)
RETURNS TEXT AS $$
DECLARE
  deleted_path TEXT;
BEGIN
  SELECT file_path INTO deleted_path FROM post_attachments WHERE attachment_id = p_attachment_id;
  DELETE FROM post_attachments WHERE attachment_id = p_attachment_id;
  RETURN deleted_path;  -- Edge function will use this to delete from storage
END;
$$ LANGUAGE plpgsql;


-- =========================================
-- 8️⃣ Upvote an issue
-- =========================================
CREATE OR REPLACE FUNCTION upvote_issue(
    p_issue_id UUID,
    p_user_id UUID
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO issue_upvotes(issue_id, user_id)
    VALUES (p_issue_id, p_user_id)
    ON CONFLICT (issue_id, user_id) DO NOTHING;

    UPDATE issues
    SET upvote_count = upvote_count + 1
    WHERE issue_id = p_issue_id;
END;
$$ LANGUAGE plpgsql;

-- =========================================
-- 9️⃣ Upvote a group
-- =========================================
CREATE OR REPLACE FUNCTION upvote_group(
    p_group_id UUID,
    p_user_id UUID
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO group_upvotes(group_id, user_id)
    VALUES (p_group_id, p_user_id)
    ON CONFLICT (group_id, user_id) DO NOTHING;
END;
$$ LANGUAGE plpgsql;

-- =========================================
-- 10️⃣ Create a new group
-- =========================================
CREATE OR REPLACE FUNCTION create_group(
    p_owner_id UUID,
    p_name TEXT,
    p_description TEXT
)
RETURNS UUID AS $$
DECLARE
    new_group_id UUID;
BEGIN
    INSERT INTO groups(owner_id, name, description)
    VALUES (p_owner_id, p_name, p_description)
    RETURNING group_id INTO new_group_id;

    RETURN new_group_id;
END;
$$ LANGUAGE plpgsql;

-- =========================================
-- 11️⃣ Submit group join request
-- =========================================
CREATE OR REPLACE FUNCTION submit_group_join_request(
    p_issue_id UUID,
    p_group_id UUID,
    p_requester_id UUID
)
RETURNS UUID AS $$
DECLARE
    new_req_id UUID;
BEGIN
    INSERT INTO group_join_request(issue_id, group_id, requester_id)
    VALUES (p_issue_id, p_group_id, p_requester_id)
    RETURNING req_id INTO new_req_id;

    RETURN new_req_id;
END;
$$ LANGUAGE plpgsql;

-- =========================================
-- Group owner requests issue author to add their issue to the group
-- =========================================
CREATE OR REPLACE FUNCTION owner_requests_issue_to_add(
    p_issue_id UUID,       -- The post/issue to be added
    p_group_id UUID,       -- The target group
    p_group_owner_id UUID  -- The owner of the group (requester)
)
RETURNS UUID AS $$
DECLARE
    new_req_id UUID;
BEGIN
    INSERT INTO group_join_request(issue_id, group_id, requester_id)
    VALUES (p_issue_id, p_group_id, p_group_owner_id)
    RETURNING req_id INTO new_req_id;

    RETURN new_req_id;
END;
$$ LANGUAGE plpgsql;

-- =========================================
-- Process a group join request (author → owner OR owner → author)
-- =========================================
CREATE OR REPLACE FUNCTION process_group_join_request(
    p_req_id UUID,
    p_status VARCHAR -- 'approved' or 'rejected'
)
RETURNS VOID AS $$
DECLARE
    v_issue_id UUID;
    v_group_id UUID;
BEGIN
    -- Get issue_id and group_id for the request
    SELECT issue_id, group_id
    INTO v_issue_id, v_group_id
    FROM group_join_request
    WHERE req_id = p_req_id;

    -- Update request status and processed timestamp
    UPDATE group_join_request
    SET status = p_status,
        processed_at = NOW()
    WHERE req_id = p_req_id;

    -- If approved, add the post to the group
    IF p_status = 'approved' THEN
        INSERT INTO group_posts(group_id, post_id)
        VALUES (v_group_id, v_issue_id)
        ON CONFLICT (group_id, post_id) DO NOTHING;
    END IF;
END;
$$ LANGUAGE plpgsql;

--cancel group join request
   CREATE OR REPLACE FUNCTION cancel_group_join_request(
    p_req_id UUID,
    p_performer_user_id UUID
)
RETURNS VOID AS $$
DECLARE
    v_issue_id UUID;
    v_group_id UUID;
    v_requested_by_user BOOLEAN;
    v_issue_author UUID;
    v_group_owner UUID;
BEGIN
    SELECT issue_id, group_id, requested_by_user
    INTO v_issue_id, v_group_id, v_requested_by_user
    FROM group_join_request
    WHERE req_id = p_req_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'group_join_request % not found', p_req_id;
    END IF;

    SELECT user_id INTO v_issue_author FROM issues WHERE issue_id = v_issue_id;
    SELECT owner_id INTO v_group_owner FROM groups WHERE group_id = v_group_id;

    IF p_performer_user_id IS NULL THEN
        RAISE EXCEPTION 'performer user id is required';
    END IF;

    -- Authorization: allow the issue author or group owner to cancel (either side)
    IF v_requested_by_user THEN
        -- Request made by issue author; allow issue author or group owner to cancel
        IF p_performer_user_id <> v_issue_author AND p_performer_user_id <> v_group_owner THEN
            RAISE EXCEPTION 'user % not authorized to cancel request %', p_performer_user_id, p_req_id;
        END IF;
    ELSE
        -- Request made by group owner; allow group owner or issue author to cancel
        IF p_performer_user_id <> v_group_owner AND p_performer_user_id <> v_issue_author THEN
            RAISE EXCEPTION 'user % not authorized to cancel request %', p_performer_user_id, p_req_id;
        END IF;
    END IF;

    UPDATE group_join_request
    SET status = 'cancelled',
        handled_at = NOW()
    WHERE req_id = p_req_id;
END;
$$ LANGUAGE plpgsql;


-- Remove an upvote from a post
CREATE OR REPLACE FUNCTION remove_post_upvote(
    p_issue_id UUID,
    p_user_id UUID
)
RETURNS VOID AS $$
BEGIN
    -- Delete the upvote record
    DELETE FROM issue_upvotes
    WHERE issue_id = p_issue_id
      AND user_id = p_user_id;

    -- Decrement the upvote count on the post
    UPDATE issues
    SET upvote_count = GREATEST(upvote_count - 1, 0)
    WHERE issue_id = p_issue_id;
END;
$$ LANGUAGE plpgsql;

-- Remove an upvote from a group
CREATE OR REPLACE FUNCTION remove_group_upvote(
    p_group_id UUID,
    p_user_id UUID
)
RETURNS VOID AS $$
BEGIN
    DELETE FROM group_upvotes
    WHERE group_id = p_group_id
      AND user_id = p_user_id;
END;
$$ LANGUAGE plpgsql;
