-- ============================================================
-- NOTIFICATION TRIGGERS
-- These triggers automatically create notifications for various events
-- ============================================================

-- 1. Trigger for new comments on suggestions
CREATE OR REPLACE FUNCTION notify_on_comment()
RETURNS TRIGGER AS $$
DECLARE
    suggestion_owner_id UUID;
    suggestion_content TEXT;
    commenter_username TEXT;
BEGIN
    -- Get suggestion owner and content
    SELECT s.user_id, s.content, p.username
    INTO suggestion_owner_id, suggestion_content, commenter_username
    FROM suggestions s
    JOIN profiles p ON p.id = NEW.user_id
    WHERE s.id = NEW.suggestion_id;

    -- If we found the suggestion owner and it's not the commenter themselves
    IF suggestion_owner_id IS NOT NULL AND suggestion_owner_id != NEW.user_id THEN
        -- Insert notification
        INSERT INTO notifications (user_id, type, title, body, ref_id)
        VALUES (
            suggestion_owner_id,
            'comment',
            'New Comment',
            COALESCE(commenter_username, 'Someone') || ' commented on your suggestion: "' || 
            LEFT(suggestion_content, 50) || (CASE WHEN LENGTH(suggestion_content) > 50 THEN '...' ELSE '' END) || '"',
            NEW.id
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER comment_notification_trigger
AFTER INSERT ON comments
FOR EACH ROW EXECUTE FUNCTION notify_on_comment();

-- 2. Trigger for new messages in conversations
CREATE OR REPLACE FUNCTION notify_on_message()
RETURNS TRIGGER AS $$
DECLARE
    recipient_id UUID;
    sender_username TEXT;
    conversation_title TEXT;
BEGIN
    -- Get conversation participants (assuming 2 participants)
    SELECT 
        CASE 
            WHEN participants[1] = NEW.sender_id THEN participants[2]
            ELSE participants[1]
        END,
        p.username,
        COALESCE(c.last_message, 'New message')
    INTO recipient_id, sender_username, conversation_title
    FROM conversations c
    JOIN profiles p ON p.id = NEW.sender_id
    WHERE c.id = NEW.conversation_id;

    -- If we found a recipient
    IF recipient_id IS NOT NULL THEN
        -- Insert notification
        INSERT INTO notifications (user_id, type, title, body, ref_id)
        VALUES (
            recipient_id,
            'message',
            'New Message',
            COALESCE(sender_username, 'Someone') || ': "' || 
            LEFT(NEW.content, 100) || (CASE WHEN LENGTH(NEW.content) > 100 THEN '...' ELSE '' END) || '"',
            NEW.conversation_id
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER message_notification_trigger
AFTER INSERT ON messages
FOR EACH ROW EXECUTE FUNCTION notify_on_message();

-- 3. Trigger for topic votes (when someone votes on your topic)
CREATE OR REPLACE FUNCTION notify_on_topic_vote()
RETURNS TRIGGER AS $$
DECLARE
    topic_owner_id UUID;
    topic_title TEXT;
    voter_username TEXT;
BEGIN
    -- Get topic owner and title
    SELECT t.user_id, t.title, p.username
    INTO topic_owner_id, topic_title, voter_username
    FROM topics t
    JOIN profiles p ON p.id = NEW.user_id
    WHERE t.id = NEW.topic_id;

    -- If we found the topic owner and it's not the voter themselves
    IF topic_owner_id IS NOT NULL AND topic_owner_id != NEW.user_id THEN
        -- Insert notification
        INSERT INTO notifications (user_id, type, title, body, ref_id)
        VALUES (
            topic_owner_id,
            'topic_vote',
            'Topic Voted',
            COALESCE(voter_username, 'Someone') || ' voted on your topic: "' || 
            LEFT(topic_title, 50) || (CASE WHEN LENGTH(topic_title) > 50 THEN '...' ELSE '' END) || '"',
            NEW.topic_id
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER topic_vote_notification_trigger
AFTER INSERT ON topic_votes
FOR EACH ROW EXECUTE FUNCTION notify_on_topic_vote();

-- 4. Trigger for suggestion votes (when someone votes on your suggestion)
CREATE OR REPLACE FUNCTION notify_on_suggestion_vote()
RETURNS TRIGGER AS $$
DECLARE
    suggestion_owner_id UUID;
    suggestion_content TEXT;
    topic_title TEXT;
    voter_username TEXT;
BEGIN
    -- Get suggestion owner, content, and topic title
    SELECT s.user_id, s.content, t.title, p.username
    INTO suggestion_owner_id, suggestion_content, topic_title, voter_username
    FROM suggestions s
    JOIN topics t ON t.id = s.topic_id
    JOIN profiles p ON p.id = NEW.user_id
    WHERE s.id = NEW.suggestion_id;

    -- If we found the suggestion owner and it's not the voter themselves
    IF suggestion_owner_id IS NOT NULL AND suggestion_owner_id != NEW.user_id THEN
        -- Insert notification
        INSERT INTO notifications (user_id, type, title, body, ref_id)
        VALUES (
            suggestion_owner_id,
            'suggestion_vote',
            'Suggestion Voted',
            COALESCE(voter_username, 'Someone') || ' voted on your suggestion in "' || 
            LEFT(topic_title, 30) || (CASE WHEN LENGTH(topic_title) > 30 THEN '...' ELSE '' END) || '": "' ||
            LEFT(suggestion_content, 50) || (CASE WHEN LENGTH(suggestion_content) > 50 THEN '...' ELSE '' END) || '"',
            NEW.suggestion_id
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER suggestion_vote_notification_trigger
AFTER INSERT ON suggestion_votes
FOR EACH ROW EXECUTE FUNCTION notify_on_suggestion_vote();

-- 5. Function to call the edge function for push notifications
-- This would be called from the triggers above if we want real-time push notifications
-- For now, we'll just insert into the notifications table and rely on real-time subscriptions

-- 6. Add FCM token column to profiles table if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'fcm_token'
    ) THEN
        ALTER TABLE profiles ADD COLUMN fcm_token TEXT;
        CREATE INDEX idx_profiles_fcm_token ON profiles(fcm_token) WHERE fcm_token IS NOT NULL;
    END IF;
END $$;

-- 7. Cleanup function to remove old notifications (keep last 100 per user)
CREATE OR REPLACE FUNCTION cleanup_old_notifications()
RETURNS void AS $$
BEGIN
    DELETE FROM notifications
    WHERE id IN (
        SELECT id FROM (
            SELECT 
                id,
                ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at DESC) as row_num
            FROM notifications
        ) ranked
        WHERE row_num > 100
    );
END;
$$ LANGUAGE plpgsql;

-- 8. Function to mark all notifications as read for a user
CREATE OR REPLACE FUNCTION mark_all_notifications_read(user_uuid UUID)
RETURNS void AS $$
BEGIN
    UPDATE notifications
    SET is_read = true
    WHERE user_id = user_uuid AND is_read = false;
END;
$$ LANGUAGE plpgsql;

-- 9. Function to get unread notification count for a user
CREATE OR REPLACE FUNCTION get_unread_notification_count(user_uuid UUID)
RETURNS INTEGER AS $$
DECLARE
    unread_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO unread_count
    FROM notifications
    WHERE user_id = user_uuid AND is_read = false;
    
    RETURN unread_count;
END;
$$ LANGUAGE plpgsql;

-- 10. View for notification statistics
CREATE OR REPLACE VIEW notification_stats AS
SELECT 
    user_id,
    COUNT(*) as total_notifications,
    COUNT(*) FILTER (WHERE is_read = false) as unread_count,
    COUNT(*) FILTER (WHERE type = 'topic_vote') as topic_vote_notifications,
    COUNT(*) FILTER (WHERE type = 'suggestion_vote') as suggestion_vote_notifications,
    COUNT(*) FILTER (WHERE type = 'comment') as comment_notifications,
    COUNT(*) FILTER (WHERE type = 'message') as message_notifications,
    COUNT(*) FILTER (WHERE type = 'milestone') as milestone_notifications,
    MAX(created_at) as latest_notification
FROM notifications
GROUP BY user_id;

-- ============================================================
-- DEPLOYMENT NOTES
-- ============================================================

-- To deploy these triggers:
-- 1. Run this entire file in the Supabase SQL Editor
-- 2. Or run: psql -h your-db-host -U postgres -d your-db -f notification_triggers.sql

-- To test the triggers:
-- 1. Insert a comment: INSERT INTO comments (suggestion_id, user_id, content) VALUES (...)
-- 2. Insert a message: INSERT INTO messages (conversation_id, sender_id, content) VALUES (...)
-- 3. Insert a topic vote: INSERT INTO topic_votes (user_id, topic_id) VALUES (...)
-- 4. Insert a suggestion vote: INSERT INTO suggestion_votes (user_id, suggestion_id, vote_type) VALUES (...)

-- To cleanup old notifications manually:
-- SELECT cleanup_old_notifications();

-- To mark all notifications as read for a user:
-- SELECT mark_all_notifications_read('user-uuid-here');

-- To get unread count:
-- SELECT get_unread_notification_count('user-uuid-here');