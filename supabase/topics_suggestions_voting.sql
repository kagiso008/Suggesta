-- ============================================================
-- SUGGESTA — Topics, Suggestions & Voting Schema
-- Run this in the Supabase SQL Editor
-- ============================================================


-- ─── SECTION 1: TABLES ───────────────────────────────────────

CREATE TABLE IF NOT EXISTS profiles (
  id          uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username    text UNIQUE NOT NULL,
  avatar_url  text,
  bio         text,
  created_at  timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS topics (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          uuid REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  title            text NOT NULL,
  description      text,
  category         text,
  tags             text[],
  view_count       int DEFAULT 0,
  vote_count       int DEFAULT 0,
  milestone_badge  text,  -- 'rising' | 'hot' | 'viral' | null
  created_at       timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS topic_votes (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  topic_id    uuid REFERENCES topics(id) ON DELETE CASCADE NOT NULL,
  created_at  timestamptz DEFAULT now(),
  UNIQUE(user_id, topic_id)
);

CREATE TABLE IF NOT EXISTS suggestions (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  topic_id    uuid REFERENCES topics(id) ON DELETE CASCADE NOT NULL,
  user_id     uuid REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  content     text NOT NULL,
  image_url   text,
  vote_count  int DEFAULT 0,
  created_at  timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS suggestion_votes (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        uuid REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  suggestion_id  uuid REFERENCES suggestions(id) ON DELETE CASCADE NOT NULL,
  created_at     timestamptz DEFAULT now(),
  UNIQUE(user_id, suggestion_id)
);


-- ─── SECTION 2: INDEXES ──────────────────────────────────────

-- Fast ranked suggestion queries
CREATE INDEX IF NOT EXISTS idx_suggestions_topic_votes
  ON suggestions(topic_id, vote_count DESC, created_at ASC);

-- Fast home feed
CREATE INDEX IF NOT EXISTS idx_topics_created
  ON topics(created_at DESC);

-- Fast vote lookups
CREATE INDEX IF NOT EXISTS idx_topic_votes_user
  ON topic_votes(user_id, topic_id);

CREATE INDEX IF NOT EXISTS idx_suggestion_votes_user
  ON suggestion_votes(user_id, suggestion_id);


-- ─── SECTION 3: ROW LEVEL SECURITY ───────────────────────────

ALTER TABLE profiles        ENABLE ROW LEVEL SECURITY;
ALTER TABLE topics          ENABLE ROW LEVEL SECURITY;
ALTER TABLE topic_votes     ENABLE ROW LEVEL SECURITY;
ALTER TABLE suggestions     ENABLE ROW LEVEL SECURITY;
ALTER TABLE suggestion_votes ENABLE ROW LEVEL SECURITY;

-- profiles
CREATE POLICY "Public profiles are viewable by everyone"
  ON profiles FOR SELECT USING (true);

CREATE POLICY "Users can insert their own profile"
  ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON profiles FOR UPDATE USING (auth.uid() = id);

-- topics
CREATE POLICY "Topics are viewable by everyone"
  ON topics FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create topics"
  ON topics FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Topic owners can update their topics"
  ON topics FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Topic owners can delete their topics"
  ON topics FOR DELETE USING (auth.uid() = user_id);

-- topic_votes
CREATE POLICY "Topic votes viewable by everyone"
  ON topic_votes FOR SELECT USING (true);

CREATE POLICY "Authenticated users can vote on topics"
  ON topic_votes FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can remove their own topic vote"
  ON topic_votes FOR DELETE USING (auth.uid() = user_id);

-- suggestions
CREATE POLICY "Suggestions are viewable by everyone"
  ON suggestions FOR SELECT USING (true);

CREATE POLICY "Authenticated users can add suggestions"
  ON suggestions FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Suggestion owners can update their suggestions"
  ON suggestions FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Suggestion owners can delete their suggestions"
  ON suggestions FOR DELETE USING (auth.uid() = user_id);

-- suggestion_votes
CREATE POLICY "Suggestion votes viewable by everyone"
  ON suggestion_votes FOR SELECT USING (true);

CREATE POLICY "Authenticated users can vote on suggestions"
  ON suggestion_votes FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can remove their own suggestion vote"
  ON suggestion_votes FOR DELETE USING (auth.uid() = user_id);


-- ─── SECTION 4: FUNCTIONS & TRIGGERS ─────────────────────────

-- 4a. Auto-create profile row when a new user signs up
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.profiles (id, username)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1))
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();


-- 4b. Update topics.vote_count when topic_votes changes
CREATE OR REPLACE FUNCTION handle_topic_vote_change()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  new_count int;
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE topics
    SET vote_count = vote_count + 1
    WHERE id = NEW.topic_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE topics
    SET vote_count = GREATEST(vote_count - 1, 0)
    WHERE id = OLD.topic_id;
  END IF;

  -- Update milestone badge
  SELECT vote_count INTO new_count
  FROM topics
  WHERE id = COALESCE(NEW.topic_id, OLD.topic_id);

  UPDATE topics SET milestone_badge =
    CASE
      WHEN new_count >= 100 THEN 'viral'
      WHEN new_count >= 50  THEN 'hot'
      WHEN new_count >= 10  THEN 'rising'
      ELSE null
    END
  WHERE id = COALESCE(NEW.topic_id, OLD.topic_id);

  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS on_topic_vote_change ON topic_votes;
CREATE TRIGGER on_topic_vote_change
  AFTER INSERT OR DELETE ON topic_votes
  FOR EACH ROW EXECUTE FUNCTION handle_topic_vote_change();


-- 4c. Update suggestions.vote_count when suggestion_votes changes
CREATE OR REPLACE FUNCTION handle_suggestion_vote_change()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE suggestions
    SET vote_count = vote_count + 1
    WHERE id = NEW.suggestion_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE suggestions
    SET vote_count = GREATEST(vote_count - 1, 0)
    WHERE id = OLD.suggestion_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS on_suggestion_vote_change ON suggestion_votes;
CREATE TRIGGER on_suggestion_vote_change
  AFTER INSERT OR DELETE ON suggestion_votes
  FOR EACH ROW EXECUTE FUNCTION handle_suggestion_vote_change();


-- 4d. Increment topic view count (called manually from Flutter)
CREATE OR REPLACE FUNCTION increment_topic_view(topic_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE topics SET view_count = view_count + 1 WHERE id = topic_id;
END;
$$;


-- ─── SECTION 5: REALTIME ─────────────────────────────────────

-- Enable realtime for these tables
ALTER PUBLICATION supabase_realtime ADD TABLE topics;
ALTER PUBLICATION supabase_realtime ADD TABLE suggestions;
ALTER PUBLICATION supabase_realtime ADD TABLE topic_votes;
ALTER PUBLICATION supabase_realtime ADD TABLE suggestion_votes;