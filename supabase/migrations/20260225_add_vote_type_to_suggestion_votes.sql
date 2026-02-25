-- Migration to add vote_type column to suggestion_votes table
-- and update the trigger function to handle upvote/downvote

-- First, drop the existing trigger
DROP TRIGGER IF EXISTS suggestion_votes_count_trigger ON suggestion_votes;

-- Add vote_type column with default value 1 (upvote) for existing rows
ALTER TABLE suggestion_votes 
ADD COLUMN IF NOT EXISTS vote_type INTEGER NOT NULL DEFAULT 1 
CHECK (vote_type IN (1, -1));

-- Update the trigger function to handle vote_type
CREATE OR REPLACE FUNCTION public.update_suggestion_vote_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE suggestions 
        SET vote_count = vote_count + NEW.vote_type
        WHERE id = NEW.suggestion_id;
    ELSIF TG_OP = 'UPDATE' THEN
        UPDATE suggestions 
        SET vote_count = vote_count - OLD.vote_type + NEW.vote_type
        WHERE id = NEW.suggestion_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE suggestions 
        SET vote_count = vote_count - OLD.vote_type
        WHERE id = OLD.suggestion_id;
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Recreate the trigger to fire on INSERT, UPDATE, and DELETE
CREATE TRIGGER suggestion_votes_count_trigger
    AFTER INSERT OR UPDATE OR DELETE ON suggestion_votes
    FOR EACH ROW EXECUTE FUNCTION public.update_suggestion_vote_count();

-- Note: Existing votes will be treated as upvotes (vote_type = 1)
-- This maintains backward compatibility