-- Add missing UPDATE policy for suggestion_votes table
-- This allows users to update their own votes (e.g., change from downvote to upvote)

CREATE POLICY "Users can update their own suggestion vote"
  ON suggestion_votes FOR UPDATE USING (auth.uid() = user_id);