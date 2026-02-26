-- Add trending topics function to fetch topics with most views in last hour

CREATE OR REPLACE FUNCTION get_trending_topics_by_views(hours int DEFAULT 1, limit_count int DEFAULT 10)
RETURNS TABLE (
  id uuid,
  user_id uuid,
  title text,
  description text,
  category text,
  tags text[],
  view_count int,
  vote_count int,
  milestone_badge text,
  created_at timestamptz,
  username text,
  avatar_url text,
  suggestion_count int
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  one_hour_ago timestamptz;
BEGIN
  -- Calculate the time threshold (hours ago from now)
  one_hour_ago := now() - (hours || ' hour')::interval;
  
  -- Return topics ordered by view_count in descending order, filtered by creation time in last hour
  RETURN QUERY
  SELECT 
    t.id,
    t.user_id,
    t.title,
    t.description,
    t.category,
    t.tags,
    t.view_count,
    t.vote_count,
    t.milestone_badge,
    t.created_at,
    p.username,
    p.avatar_url,
    COALESCE(suggestion_counts.count, 0) as suggestion_count
  FROM topics t
  LEFT JOIN profiles p ON t.user_id = p.id
  LEFT JOIN (
    SELECT topic_id, COUNT(*) as count
    FROM suggestions
    GROUP BY topic_id
  ) suggestion_counts ON t.id = suggestion_counts.topic_id
  WHERE t.created_at >= one_hour_ago
  ORDER BY t.view_count DESC, t.created_at DESC
  LIMIT limit_count;
END;
$$;