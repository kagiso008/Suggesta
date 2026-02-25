-- ============================================================
-- SUGGESTA — SUPABASE SCHEMA
-- Run this entire file in the Supabase SQL Editor
-- ============================================================

-- SECTION 1: EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- for text search
CREATE EXTENSION IF NOT EXISTS "unaccent"; -- for case-insensitive search

-- SECTION 2: TABLES

-- 1. profiles
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE NOT NULL,
    avatar_url TEXT,
    bio TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. topics
CREATE TABLE topics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    category TEXT,
    tags TEXT[],
    view_count INTEGER DEFAULT 0,
    vote_count INTEGER DEFAULT 0,
    milestone_badge TEXT CHECK (milestone_badge IN ('hot', 'rising', 'viral')) DEFAULT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. topic_votes
CREATE TABLE topic_votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    topic_id UUID REFERENCES topics(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id, topic_id)
);

-- 4. topic_follows
CREATE TABLE topic_follows (
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    topic_id UUID REFERENCES topics(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (user_id, topic_id)
);

-- 5. topic_bookmarks
CREATE TABLE topic_bookmarks (
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    topic_id UUID REFERENCES topics(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (user_id, topic_id)
);

-- 6. suggestions
CREATE TABLE suggestions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    topic_id UUID REFERENCES topics(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    image_url TEXT,
    vote_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 6. suggestion_votes
CREATE TABLE suggestion_votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    suggestion_id UUID REFERENCES suggestions(id) ON DELETE CASCADE,
    vote_type INTEGER NOT NULL CHECK (vote_type IN (1, -1)), -- 1 for upvote, -1 for downvote
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id, suggestion_id)
);

-- 7. comments
CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    suggestion_id UUID REFERENCES suggestions(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    parent_id UUID REFERENCES comments(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 8. conversations
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    participants UUID[] NOT NULL,
    last_message TEXT,
    updated_at TIMESTAMPTZ DEFAULT now(),
    created_at TIMESTAMPTZ DEFAULT now(),
    CHECK (array_length(participants, 1) = 2)
);

-- 9. messages
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 10. notifications
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('topic_vote', 'suggestion_vote', 'comment', 'message', 'milestone')),
    title TEXT,
    body TEXT,
    is_read BOOLEAN DEFAULT false,
    ref_id UUID,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- SECTION 3: INDEXES

-- For performance
CREATE INDEX idx_topics_created_at ON topics(created_at DESC);
CREATE INDEX idx_topics_user_id ON topics(user_id);
CREATE INDEX idx_topics_category ON topics(category);
CREATE INDEX idx_topics_vote_count ON topics(vote_count DESC);

CREATE INDEX idx_suggestions_topic_id_vote_count ON suggestions(topic_id, vote_count DESC);
CREATE INDEX idx_suggestions_user_id ON suggestions(user_id);
CREATE INDEX idx_suggestions_created_at ON suggestions(created_at DESC);

CREATE INDEX idx_topic_votes_user_topic ON topic_votes(user_id, topic_id);
CREATE INDEX idx_topic_votes_topic ON topic_votes(topic_id);

CREATE INDEX idx_suggestion_votes_user_suggestion ON suggestion_votes(user_id, suggestion_id);
CREATE INDEX idx_suggestion_votes_suggestion ON suggestion_votes(suggestion_id);

CREATE INDEX idx_comments_suggestion_id ON comments(suggestion_id);
CREATE INDEX idx_comments_user_id ON comments(user_id);
CREATE INDEX idx_comments_parent_id ON comments(parent_id);

CREATE INDEX idx_conversations_participants ON conversations USING gin(participants);
CREATE INDEX idx_conversations_updated_at ON conversations(updated_at DESC);

CREATE INDEX idx_messages_conversation_id_created_at ON messages(conversation_id, created_at ASC);
CREATE INDEX idx_messages_sender_id ON messages(sender_id);

CREATE INDEX idx_notifications_user_id_created_at ON notifications(user_id, created_at DESC);
CREATE INDEX idx_notifications_is_read ON notifications(is_read) WHERE NOT is_read;

-- Full-text search index for topics
CREATE INDEX idx_topics_search ON topics USING gin(
    to_tsvector('english', title || ' ' || COALESCE(description, ''))
);

-- SECTION 4: ROW LEVEL SECURITY (RLS)

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE topics ENABLE ROW LEVEL SECURITY;
ALTER TABLE topic_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE topic_follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE topic_bookmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE suggestions ENABLE ROW LEVEL SECURITY;
ALTER TABLE suggestion_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- 1. profiles policies
CREATE POLICY "Public profiles are viewable by everyone" ON profiles
    FOR SELECT USING (true);

CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

-- 2. topics policies
CREATE POLICY "Topics are viewable by everyone" ON topics
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create topics" ON topics
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own topics" ON topics
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own topics" ON topics
    FOR DELETE USING (auth.uid() = user_id);

-- 3. topic_votes policies
CREATE POLICY "Topic votes are viewable by everyone" ON topic_votes
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can vote on topics" ON topic_votes
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own votes" ON topic_votes
    FOR DELETE USING (auth.uid() = user_id);

-- 4. topic_follows policies
CREATE POLICY "Users can view their own follows" ON topic_follows
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Authenticated users can follow topics" ON topic_follows
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can unfollow topics" ON topic_follows
    FOR DELETE USING (auth.uid() = user_id);

-- 5. topic_bookmarks policies
CREATE POLICY "Users can view their own bookmarks" ON topic_bookmarks
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Authenticated users can bookmark topics" ON topic_bookmarks
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can remove their own bookmarks" ON topic_bookmarks
    FOR DELETE USING (auth.uid() = user_id);

-- 6. suggestions policies
CREATE POLICY "Suggestions are viewable by everyone" ON suggestions
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create suggestions" ON suggestions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own suggestions" ON suggestions
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own suggestions" ON suggestions
    FOR DELETE USING (auth.uid() = user_id);

-- 6. suggestion_votes policies
CREATE POLICY "Suggestion votes are viewable by everyone" ON suggestion_votes
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can vote on suggestions" ON suggestion_votes
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own suggestion votes" ON suggestion_votes
    FOR DELETE USING (auth.uid() = user_id);

-- 7. comments policies
CREATE POLICY "Comments are viewable by everyone" ON comments
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create comments" ON comments
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own comments" ON comments
    FOR DELETE USING (auth.uid() = user_id);

-- 8. conversations policies
CREATE POLICY "Users can view conversations they participate in" ON conversations
    FOR SELECT USING (auth.uid() = ANY(participants));

CREATE POLICY "Authenticated users can create conversations" ON conversations
    FOR INSERT WITH CHECK (
        auth.uid() = ANY(participants) AND 
        array_length(participants, 1) = 2
    );

-- 9. messages policies
CREATE POLICY "Users can view messages in conversations they participate in" ON messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM conversations c 
            WHERE c.id = messages.conversation_id 
            AND auth.uid() = ANY(c.participants)
        )
    );

CREATE POLICY "Authenticated users can send messages" ON messages
    FOR INSERT WITH CHECK (
        auth.uid() = sender_id AND
        EXISTS (
            SELECT 1 FROM conversations c 
            WHERE c.id = messages.conversation_id 
            AND auth.uid() = ANY(c.participants)
        )
    );

-- 10. notifications policies
CREATE POLICY "Users can view own notifications" ON notifications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications" ON notifications
    FOR UPDATE USING (auth.uid() = user_id);

-- SECTION 5: FUNCTIONS & TRIGGERS

-- 5a. Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, username)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1))
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 5b. topic_votes → update topics.vote_count + milestone badge
CREATE OR REPLACE FUNCTION public.update_topic_vote_count()
RETURNS TRIGGER AS $$
DECLARE
    current_votes INTEGER;
    new_badge TEXT;
BEGIN
    -- Update vote_count
    IF TG_OP = 'INSERT' THEN
        UPDATE topics 
        SET vote_count = vote_count + 1 
        WHERE id = NEW.topic_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE topics 
        SET vote_count = vote_count - 1 
        WHERE id = OLD.topic_id;
    END IF;

    -- Get updated vote count and set milestone badge
    SELECT vote_count INTO current_votes
    FROM topics 
    WHERE id = COALESCE(NEW.topic_id, OLD.topic_id);

    -- Determine badge based on vote count
    IF current_votes >= 100 THEN
        new_badge := 'viral';
    ELSIF current_votes >= 50 THEN
        new_badge := 'hot';
    ELSIF current_votes >= 10 THEN
        new_badge := 'rising';
    ELSE
        new_badge := NULL;
    END IF;

    -- Update milestone badge
    UPDATE topics 
    SET milestone_badge = new_badge
    WHERE id = COALESCE(NEW.topic_id, OLD.topic_id);

    -- Create milestone notification if badge changed
    IF new_badge IS NOT NULL AND TG_OP = 'INSERT' THEN
        INSERT INTO notifications (user_id, type, title, body, ref_id)
        SELECT 
            user_id,
            'milestone',
            'Topic milestone reached!',
            'Your topic "' || title || '" reached ' || current_votes || ' votes and earned the ' || new_badge || ' badge!',
            id
        FROM topics 
        WHERE id = COALESCE(NEW.topic_id, OLD.topic_id);
    END IF;

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER topic_votes_count_trigger
    AFTER INSERT OR DELETE ON topic_votes
    FOR EACH ROW EXECUTE FUNCTION public.update_topic_vote_count();

-- 5c. suggestion_votes → update suggestions.vote_count
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

CREATE OR REPLACE TRIGGER suggestion_votes_count_trigger
    AFTER INSERT OR UPDATE OR DELETE ON suggestion_votes
    FOR EACH ROW EXECUTE FUNCTION public.update_suggestion_vote_count();

-- 5d. messages → update conversations.last_message + updated_at
CREATE OR REPLACE FUNCTION public.update_conversation_on_message()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE conversations 
    SET 
        last_message = NEW.content,
        updated_at = now()
    WHERE id = NEW.conversation_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER update_conversation_trigger
    AFTER INSERT ON messages
    FOR EACH ROW EXECUTE FUNCTION public.update_conversation_on_message();

-- 5e. refresh_trending() function
CREATE OR REPLACE FUNCTION public.refresh_trending()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY trending_topics;
END;
$$ LANGUAGE plpgsql;

-- 5f. Trigger to call refresh_trending after topic_votes change
CREATE OR REPLACE FUNCTION public.schedule_trending_refresh()
RETURNS TRIGGER AS $$
BEGIN
    -- Use a deferred trigger to avoid immediate refresh on every vote
    PERFORM pg_notify('trending_refresh', 'refresh');
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER schedule_trending_refresh_trigger
    AFTER INSERT OR DELETE ON topic_votes
    FOR EACH STATEMENT EXECUTE FUNCTION public.schedule_trending_refresh();

-- SECTION 6: MATERIALIZED VIEW — trending_topics
CREATE MATERIALIZED VIEW trending_topics AS
SELECT 
    t.id,
    t.title,
    t.category,
    t.vote_count,
    t.view_count,
    t.milestone_badge,
    t.user_id,
    t.created_at,
    -- Trending score formula
    (t.vote_count * 2 + COALESCE(s.suggestion_count, 0) + t.view_count * 0.1) 
    / POWER(EXTRACT(EPOCH FROM (now() - t.created_at)) / 3600 + 2, 1.5) AS score
FROM topics t
LEFT JOIN (
    SELECT topic_id, COUNT(*) as suggestion_count
    FROM suggestions
    GROUP BY topic_id
) s ON t.id = s.topic_id
WHERE t.created_at > now() - INTERVAL '30 days'
ORDER BY score DESC;

CREATE UNIQUE INDEX idx_trending_topics_id ON trending_topics(id);
CREATE INDEX idx_trending_topics_score ON trending_topics(score DESC);

-- SECTION 7: FUNCTIONS

-- Increment topic view count (called manually from Flutter)
CREATE OR REPLACE FUNCTION increment_topic_view(topic_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE topics SET view_count = view_count + 1 WHERE id = topic_id;
END;
$$;

-- SECTION 8: REALTIME PUBLICATION (enable tables for realtime)
-- Enable realtime for tables that need live updates
ALTER PUBLICATION supabase_realtime ADD TABLE topics;
ALTER PUBLICATION supabase_realtime ADD TABLE suggestions;
ALTER PUBLICATION supabase_realtime ADD TABLE comments;
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;

-- ============================================================
-- END OF SCHEMA
-- ============================================================