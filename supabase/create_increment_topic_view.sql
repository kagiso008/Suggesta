-- Create the increment_topic_view RPC function
-- Run this in your Supabase SQL Editor

CREATE OR REPLACE FUNCTION public.increment_topic_view(topic_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE topics SET view_count = view_count + 1 WHERE id = topic_id;
END;
$$;

-- Test the function (optional)
-- SELECT public.increment_topic_view('your-topic-id-here');