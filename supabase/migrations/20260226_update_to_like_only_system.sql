-- Migration to update suggestion_votes table for like-only system
-- Changes:
-- 1. Update CHECK constraint to only allow vote_type = 1 (like)
-- 2. Update trigger function to always add/subtract 1
-- 3. Set default value to 1

-- First, drop the existing trigger
DROP TRIGGER IF EXISTS suggestion_votes_count_trigger ON suggestion_votes;

-- Update the CHECK constraint to only allow vote_type = 1 (like)
-- We need to drop and recreate the constraint
ALTER TABLE suggestion_votes 
DROP CONSTRAINT IF EXISTS suggestion_votes_vote_type_check;

ALTER TABLE suggestion_votes
ADD CONSTRAINT suggestion_votes_vote_type_check 
CHECK (vote_type = 1);

-- Update any existing downvotes (-1) to upvotes (1) to maintain data consistency
UPDATE suggestion_votes 
SET vote_type = 1 
WHERE vote_type = -1;

-- Update the trigger function to handle like-only system
-- Since vote_type is always 1, we can simplify the function
CREATE OR REPLACE FUNCTION public.update_suggestion_vote_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Always add 1 for new likes
        UPDATE suggestions 
        SET vote_count = vote_count + 1
        WHERE id = NEW.suggestion_id;
    ELSIF TG_OP = 'UPDATE' THEN
        -- In like-only system, updates shouldn't change vote_type (always 1)
        -- But handle it anyway for safety
        UPDATE suggestions 
        SET vote_count = vote_count - OLD.vote_type + NEW.vote_type
        WHERE id = NEW.suggestion_id;
    ELSIF TG_OP = 'DELETE' THEN
        -- Always subtract 1 for removed likes
        UPDATE suggestions 
        SET vote_count = vote_count - 1
        WHERE id = OLD.suggestion_id;
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Recreate the trigger
CREATE TRIGGER suggestion_votes_count_trigger
    AFTER INSERT OR UPDATE OR DELETE ON suggestion_votes
    FOR EACH ROW EXECUTE FUNCTION public.update_suggestion_vote_count();

-- Add the toggle_suggestion_like function if not already added
-- (This function should be created separately, but we include it here for completeness)
CREATE OR REPLACE FUNCTION public.toggle_suggestion_like(suggestion_id uuid)
RETURNS TABLE (
    new_vote_count integer,
    has_voted boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    current_user_id uuid;
    vote_exists boolean;
    current_vote_count integer;
BEGIN
    -- Get the current user ID from JWT
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'User must be authenticated to like suggestions';
    END IF;
    
    -- Start transaction
    BEGIN
        -- Check if vote already exists
        SELECT EXISTS (
            SELECT 1
            FROM suggestion_votes sv
            WHERE sv.user_id = current_user_id
            AND sv.suggestion_id = toggle_suggestion_like.suggestion_id
        ) INTO vote_exists;
        
        -- Get current vote count
        SELECT s.vote_count INTO current_vote_count
        FROM suggestions s
        WHERE s.id = toggle_suggestion_like.suggestion_id;
        
        IF vote_exists THEN
            -- Delete existing vote (unlike)
            DELETE FROM suggestion_votes sv
            WHERE sv.user_id = current_user_id
            AND sv.suggestion_id = toggle_suggestion_like.suggestion_id;
            
            -- Decrement vote_count (handled by trigger, but we'll update manually for consistency)
            UPDATE suggestions s
            SET vote_count = GREATEST(0, current_vote_count - 1)
            WHERE s.id = toggle_suggestion_like.suggestion_id
            RETURNING s.vote_count INTO current_vote_count;
            
            -- Return results
            new_vote_count := current_vote_count;
            has_voted := false;
        ELSE
            -- Insert new vote (like) - vote_type is always 1 for likes
            INSERT INTO suggestion_votes (user_id, suggestion_id, vote_type)
            VALUES (current_user_id, toggle_suggestion_like.suggestion_id, 1);
            
            -- Increment vote_count (handled by trigger, but we'll update manually for consistency)
            UPDATE suggestions s
            SET vote_count = current_vote_count + 1
            WHERE s.id = toggle_suggestion_like.suggestion_id
            RETURNING s.vote_count INTO current_vote_count;
            
            -- Return results
            new_vote_count := current_vote_count;
            has_voted := true;
        END IF;
        
        -- Return the result
        RETURN QUERY SELECT new_vote_count, has_voted;
        
    EXCEPTION
        WHEN OTHERS THEN
            -- Rollback will happen automatically
            RAISE;
    END;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.toggle_suggestion_like(uuid) TO authenticated;

-- Update comment to reflect like-only system
COMMENT ON TABLE suggestion_votes IS 'Stores user likes (upvotes) for suggestions. Each user can like a suggestion only once.';
COMMENT ON COLUMN suggestion_votes.vote_type IS 'Always 1 for like (upvote-only system).';