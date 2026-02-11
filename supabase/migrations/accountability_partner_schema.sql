-- Accountability Partner System Database Schema
-- Prevention App v5.0.0
-- Created: February 9, 2026

-- ============================================
-- PARTNERSHIPS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS partnerships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  partner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'declined', 'ended')),
  invite_code TEXT UNIQUE,
  
  -- Notification preferences
  notify_on_relapse BOOLEAN DEFAULT true,
  notify_on_missed_checkin BOOLEAN DEFAULT true,
  notify_on_streak_milestone BOOLEAN DEFAULT true,
  anonymous_mode BOOLEAN DEFAULT false,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  accepted_at TIMESTAMPTZ,
  
  -- Constraints
  CONSTRAINT unique_partnership UNIQUE(user_id, partner_id),
  CONSTRAINT no_self_partnership CHECK (user_id != partner_id)
);

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS idx_partnerships_user_id ON partnerships(user_id);
CREATE INDEX IF NOT EXISTS idx_partnerships_partner_id ON partnerships(partner_id);
CREATE INDEX IF NOT EXISTS idx_partnerships_invite_code ON partnerships(invite_code);
CREATE INDEX IF NOT EXISTS idx_partnerships_status ON partnerships(status);

-- ============================================
-- PARTNER NOTIFICATIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS partner_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  partnership_id UUID NOT NULL REFERENCES partnerships(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  recipient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  type TEXT NOT NULL CHECK (type IN ('relapse', 'missed_checkin', 'milestone', 'encouragement', 'partnership_request')),
  title TEXT,
  message TEXT,
  metadata JSONB DEFAULT '{}',
  
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS idx_partner_notifications_recipient ON partner_notifications(recipient_id);
CREATE INDEX IF NOT EXISTS idx_partner_notifications_partnership ON partner_notifications(partnership_id);
CREATE INDEX IF NOT EXISTS idx_partner_notifications_unread ON partner_notifications(recipient_id) WHERE read_at IS NULL;

-- ============================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================
ALTER TABLE partnerships ENABLE ROW LEVEL SECURITY;
ALTER TABLE partner_notifications ENABLE ROW LEVEL SECURITY;

-- Users can view partnerships where they are user or partner
CREATE POLICY "Users can view own partnerships"
  ON partnerships FOR SELECT
  USING (auth.uid() = user_id OR auth.uid() = partner_id);

-- Users can create partnerships (invites)
CREATE POLICY "Users can create partnerships"
  ON partnerships FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update own partnerships
CREATE POLICY "Users can update own partnerships"
  ON partnerships FOR UPDATE
  USING (auth.uid() = user_id OR auth.uid() = partner_id);

-- Users can delete own partnerships
CREATE POLICY "Users can delete own partnerships"
  ON partnerships FOR DELETE
  USING (auth.uid() = user_id);

-- Users can view notifications where they are recipient
CREATE POLICY "Users can view own notifications"
  ON partner_notifications FOR SELECT
  USING (auth.uid() = recipient_id);

-- Users can create notifications for their partners
CREATE POLICY "Users can create notifications"
  ON partner_notifications FOR INSERT
  WITH CHECK (auth.uid() = sender_id);

-- Users can update their own notifications (mark as read)
CREATE POLICY "Users can update own notifications"
  ON partner_notifications FOR UPDATE
  USING (auth.uid() = recipient_id);

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Generate a unique invite code
CREATE OR REPLACE FUNCTION generate_invite_code()
RETURNS TEXT AS $$
DECLARE
  chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  result TEXT := '';
  i INTEGER;
BEGIN
  FOR i IN 1..8 LOOP
    result := result || substr(chars, floor(random() * length(chars) + 1)::int, 1);
  END LOOP;
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Create partnership invite
CREATE OR REPLACE FUNCTION create_partnership_invite()
RETURNS UUID AS $$
DECLARE
  new_id UUID;
  new_code TEXT;
  attempts INTEGER := 0;
BEGIN
  -- Generate unique code with retry
  LOOP
    new_code := generate_invite_code();
    EXIT WHEN NOT EXISTS (SELECT 1 FROM partnerships WHERE invite_code = new_code);
    attempts := attempts + 1;
    IF attempts > 10 THEN
      RAISE EXCEPTION 'Could not generate unique invite code';
    END IF;
  END LOOP;
  
  INSERT INTO partnerships (user_id, invite_code, status)
  VALUES (auth.uid(), new_code, 'pending')
  RETURNING id INTO new_id;
  
  RETURN new_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Accept partnership invite
CREATE OR REPLACE FUNCTION accept_partnership_invite(p_invite_code TEXT)
RETURNS JSONB AS $$
DECLARE
  partnership_record RECORD;
BEGIN
  -- Find the pending partnership
  SELECT * INTO partnership_record
  FROM partnerships
  WHERE invite_code = p_invite_code
    AND status = 'pending'
    AND partner_id IS NULL;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invalid or expired invite code');
  END IF;
  
  -- Check not accepting own invite
  IF partnership_record.user_id = auth.uid() THEN
    RETURN jsonb_build_object('success', false, 'error', 'Cannot accept your own invite');
  END IF;
  
  -- Check if already partners
  IF EXISTS (
    SELECT 1 FROM partnerships
    WHERE status = 'active'
      AND ((user_id = auth.uid() AND partner_id = partnership_record.user_id)
        OR (user_id = partnership_record.user_id AND partner_id = auth.uid()))
  ) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Already partners with this user');
  END IF;
  
  -- Accept the partnership
  UPDATE partnerships
  SET partner_id = auth.uid(),
      status = 'active',
      accepted_at = now(),
      updated_at = now()
  WHERE id = partnership_record.id;
  
  -- Create notification for inviter
  INSERT INTO partner_notifications (partnership_id, sender_id, recipient_id, type, title, message)
  VALUES (
    partnership_record.id,
    auth.uid(),
    partnership_record.user_id,
    'partnership_request',
    'Partnership Accepted',
    'Your accountability partner invite was accepted!'
  );
  
  RETURN jsonb_build_object('success', true, 'partnership_id', partnership_record.id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Notify partner on significant event
CREATE OR REPLACE FUNCTION notify_partner(
  p_event_type TEXT,
  p_title TEXT,
  p_message TEXT,
  p_metadata JSONB DEFAULT '{}'
)
RETURNS VOID AS $$
DECLARE
  partner RECORD;
BEGIN
  -- Find active partnerships where notification is enabled
  FOR partner IN
    SELECT p.id, p.partner_id, p.user_id,
           CASE WHEN p.user_id = auth.uid() THEN p.partner_id ELSE p.user_id END as recipient
    FROM partnerships p
    WHERE status = 'active'
      AND (p.user_id = auth.uid() OR p.partner_id = auth.uid())
      AND (
        (p_event_type = 'relapse' AND p.notify_on_relapse) OR
        (p_event_type = 'missed_checkin' AND p.notify_on_missed_checkin) OR
        (p_event_type = 'milestone' AND p.notify_on_streak_milestone) OR
        (p_event_type = 'encouragement')
      )
  LOOP
    INSERT INTO partner_notifications (partnership_id, sender_id, recipient_id, type, title, message, metadata)
    VALUES (partner.id, auth.uid(), partner.recipient, p_event_type, p_title, p_message, p_metadata);
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- End partnership
CREATE OR REPLACE FUNCTION end_partnership(p_partnership_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE partnerships
  SET status = 'ended',
      updated_at = now()
  WHERE id = p_partnership_id
    AND (user_id = auth.uid() OR partner_id = auth.uid())
    AND status = 'active';
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
