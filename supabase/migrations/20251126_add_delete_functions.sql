-- =========================================
-- Delete Issue Function
-- =========================================
-- Deletes an issue only if the requesting user owns it
-- Relies on CASCADE constraints to delete related records:
--   - comments (ON DELETE CASCADE)
--   - issue_upvotes (ON DELETE CASCADE)
--   - post_attachments (ON DELETE CASCADE)
--   - group_join_request (ON DELETE CASCADE)
CREATE OR REPLACE FUNCTION delete_issue(p_issue_id UUID, p_user_id UUID) RETURNS TEXT AS $$
DECLARE v_owner_id UUID;
BEGIN -- Check if issue exists and get owner
SELECT user_id INTO v_owner_id
FROM issues
WHERE issue_id = p_issue_id;
IF NOT FOUND THEN RAISE EXCEPTION 'Issue not found';
END IF;
-- Check if user owns the issue
IF v_owner_id <> p_user_id THEN RAISE EXCEPTION 'You can only delete your own issues';
END IF;
-- Delete the issue (cascade will handle related records)
DELETE FROM issues
WHERE issue_id = p_issue_id;
RETURN 'Issue deleted successfully';
END;
$$ LANGUAGE plpgsql;
-- =========================================
-- Delete Group Function
-- =========================================
-- Deletes a group only if the requesting user owns it
-- Relies on CASCADE constraints to delete related records:
--   - group_upvotes (ON DELETE CASCADE)
--   - group_join_request (ON DELETE CASCADE)
-- Issues in the group will have their group_id set to NULL (ON DELETE SET NULL)
CREATE OR REPLACE FUNCTION delete_group(p_group_id UUID, p_user_id UUID) RETURNS TEXT AS $$
DECLARE v_owner_id UUID;
BEGIN -- Check if group exists and get owner
SELECT owner_id INTO v_owner_id
FROM groups
WHERE group_id = p_group_id;
IF NOT FOUND THEN RAISE EXCEPTION 'Group not found';
END IF;
-- Check if user owns the group
IF v_owner_id <> p_user_id THEN RAISE EXCEPTION 'You can only delete your own groups';
END IF;
-- Delete the group (cascade will handle related records)
DELETE FROM groups
WHERE group_id = p_group_id;
RETURN 'Group deleted successfully';
END;
$$ LANGUAGE plpgsql;