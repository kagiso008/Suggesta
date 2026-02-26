-- Toggle suggestion like function
-- This function handles the like/unlike functionality for suggestions
-- It runs in a transaction to prevent race conditions

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