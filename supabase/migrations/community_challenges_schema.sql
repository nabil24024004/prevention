-- Community Challenges Database Schema
-- Prevention App v5.0.0
-- Created: February 9, 2026

-- ============================================
-- CHALLENGES TABLE
-- Community-wide or private challenges
-- ============================================
CREATE TABLE IF NOT EXISTS challenges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Challenge info
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  challenge_type TEXT NOT NULL CHECK (challenge_type IN ('streak', 'dhikr', 'quran', 'custom')),
  
  -- Duration
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  
  -- Goals
  target_value INTEGER NOT NULL DEFAULT 7, -- e.g., 7-day streak, 1000 dhikr
  target_unit TEXT NOT NULL DEFAULT 'days', -- days, count, pages, etc.
  
  -- Visibility
  is_public BOOLEAN DEFAULT true,
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  
  -- Status
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('draft', 'active', 'completed', 'cancelled')),
  
  -- Max participants (0 = unlimited)
  max_participants INTEGER DEFAULT 0,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  
  CONSTRAINT valid_dates CHECK (end_date >= start_date)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_challenges_status ON challenges(status, start_date);
CREATE INDEX IF NOT EXISTS idx_challenges_type ON challenges(challenge_type);

-- ============================================
-- CHALLENGE PARTICIPANTS TABLE
-- Track user participation in challenges
-- ============================================
CREATE TABLE IF NOT EXISTS challenge_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id UUID NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Progress tracking
  current_progress INTEGER DEFAULT 0,
  best_progress INTEGER DEFAULT 0,
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  completed_at TIMESTAMPTZ,
  
  -- Rank (updated periodically)
  current_rank INTEGER,
  
  -- Timestamps
  joined_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  
  CONSTRAINT unique_participant UNIQUE(challenge_id, user_id),
  CONSTRAINT check_progress CHECK (current_progress >= 0 AND best_progress >= 0)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_participants_challenge ON challenge_participants(challenge_id, current_rank);
CREATE INDEX IF NOT EXISTS idx_participants_user ON challenge_participants(user_id, is_active);

-- ============================================
-- USER BADGES TABLE
-- Badges and achievements earned
-- ============================================
CREATE TABLE IF NOT EXISTS user_badges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Badge info
  badge_type TEXT NOT NULL,
  badge_name TEXT NOT NULL,
  badge_description TEXT,
  badge_icon TEXT, -- Icon name or URL
  
  -- Source (optional - what earned this badge)
  challenge_id UUID REFERENCES challenges(id) ON DELETE SET NULL,
  streak_milestone INTEGER, -- e.g., 30-day streak
  
  -- Visibility
  is_featured BOOLEAN DEFAULT false, -- Show on profile
  
  -- Timestamps
  earned_at TIMESTAMPTZ DEFAULT now(),
  
  CONSTRAINT unique_user_badge UNIQUE(user_id, badge_type, badge_name)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_badges_user ON user_badges(user_id, earned_at DESC);
CREATE INDEX IF NOT EXISTS idx_badges_type ON user_badges(badge_type);

-- ============================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================
ALTER TABLE challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE challenge_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_badges ENABLE ROW LEVEL SECURITY;

-- Challenges: anyone can view public, creators can manage
DROP POLICY IF EXISTS "Anyone can view public challenges" ON challenges;
CREATE POLICY "Anyone can view public challenges"
  ON challenges FOR SELECT
  USING (is_public = true OR created_by = auth.uid());

DROP POLICY IF EXISTS "Users can create challenges" ON challenges;
CREATE POLICY "Users can create challenges"
  ON challenges FOR INSERT
  WITH CHECK (auth.uid() = created_by);

DROP POLICY IF EXISTS "Creators can update their challenges" ON challenges;
CREATE POLICY "Creators can update their challenges"
  ON challenges FOR UPDATE
  USING (auth.uid() = created_by);

-- Participants: users see their own + leaderboards of joined
DROP POLICY IF EXISTS "Users can view all participants" ON challenge_participants;
CREATE POLICY "Users can view all participants"
  ON challenge_participants FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Users can join challenges" ON challenge_participants;
CREATE POLICY "Users can join challenges"
  ON challenge_participants FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own participation" ON challenge_participants;
CREATE POLICY "Users can update own participation"
  ON challenge_participants FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can leave challenges" ON challenge_participants;
CREATE POLICY "Users can leave challenges"
  ON challenge_participants FOR DELETE
  USING (auth.uid() = user_id);

-- Badges: users see own badges
DROP POLICY IF EXISTS "Users can view own badges" ON user_badges;
CREATE POLICY "Users can view own badges"
  ON user_badges FOR SELECT
  USING (auth.uid() = user_id);

-- Featured badges are public
DROP POLICY IF EXISTS "Anyone can view featured badges" ON user_badges;
CREATE POLICY "Anyone can view featured badges"
  ON user_badges FOR SELECT
  USING (is_featured = true);

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Join a challenge
CREATE OR REPLACE FUNCTION join_challenge(p_challenge_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_challenge challenges%ROWTYPE;
  v_current_count INTEGER;
BEGIN
  -- Get challenge
  SELECT * INTO v_challenge FROM challenges WHERE id = p_challenge_id;
  
  IF v_challenge IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Challenge not found');
  END IF;
  
  IF v_challenge.status != 'active' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Challenge is not active');
  END IF;
  
  -- Check max participants
  IF v_challenge.max_participants > 0 THEN
    SELECT COUNT(*) INTO v_current_count 
    FROM challenge_participants 
    WHERE challenge_id = p_challenge_id AND is_active = true;
    
    IF v_current_count >= v_challenge.max_participants THEN
      RETURN jsonb_build_object('success', false, 'error', 'Challenge is full');
    END IF;
  END IF;
  
  -- Join
  INSERT INTO challenge_participants (challenge_id, user_id)
  VALUES (p_challenge_id, auth.uid())
  ON CONFLICT (challenge_id, user_id) 
  DO UPDATE SET is_active = true, updated_at = now();
  
  RETURN jsonb_build_object('success', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update challenge progress
CREATE OR REPLACE FUNCTION update_challenge_progress(
  p_challenge_id UUID,
  p_progress INTEGER
)
RETURNS JSONB AS $$
DECLARE
  v_participant challenge_participants%ROWTYPE;
  v_challenge challenges%ROWTYPE;
BEGIN
  SELECT * INTO v_participant 
  FROM challenge_participants 
  WHERE challenge_id = p_challenge_id AND user_id = auth.uid();
  
  IF v_participant IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not participating');
  END IF;
  
  SELECT * INTO v_challenge FROM challenges WHERE id = p_challenge_id;
  
  UPDATE challenge_participants
  SET 
    current_progress = p_progress,
    best_progress = GREATEST(best_progress, p_progress),
    completed_at = CASE 
      WHEN p_progress >= v_challenge.target_value AND completed_at IS NULL 
      THEN now() 
      ELSE completed_at 
    END,
    updated_at = now()
  WHERE challenge_id = p_challenge_id AND user_id = auth.uid();
  
  RETURN jsonb_build_object('success', true, 'completed', p_progress >= v_challenge.target_value);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get challenge leaderboard
CREATE OR REPLACE FUNCTION get_challenge_leaderboard(
  p_challenge_id UUID,
  p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
  user_id UUID,
  display_name TEXT,
  current_progress INTEGER,
  rank INTEGER,
  completed_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    cp.user_id,
    ('Participant ' || LEFT(cp.user_id::TEXT, 8))::TEXT as display_name,
    cp.current_progress,
    DENSE_RANK() OVER (ORDER BY cp.current_progress DESC)::INTEGER as rank,
    cp.completed_at
  FROM challenge_participants cp
  WHERE cp.challenge_id = p_challenge_id AND cp.is_active = true
  ORDER BY cp.current_progress DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Award a badge
CREATE OR REPLACE FUNCTION award_badge(
  p_badge_type TEXT,
  p_badge_name TEXT,
  p_description TEXT DEFAULT NULL,
  p_icon TEXT DEFAULT NULL,
  p_challenge_id UUID DEFAULT NULL,
  p_streak INTEGER DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
  INSERT INTO user_badges (
    user_id, badge_type, badge_name, badge_description, 
    badge_icon, challenge_id, streak_milestone
  )
  VALUES (
    auth.uid(), p_badge_type, p_badge_name, p_description,
    p_icon, p_challenge_id, p_streak
  )
  ON CONFLICT (user_id, badge_type, badge_name) DO NOTHING;
  
  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get user's active challenges
CREATE OR REPLACE FUNCTION get_my_active_challenges()
RETURNS TABLE (
  challenge_id UUID,
  title TEXT,
  description TEXT,
  challenge_type TEXT,
  end_date DATE,
  target_value INTEGER,
  target_unit TEXT,
  my_progress INTEGER,
  my_rank INTEGER,
  total_participants BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    c.id,
    c.title,
    c.description,
    c.challenge_type,
    c.end_date,
    c.target_value,
    c.target_unit,
    cp.current_progress,
    cp.current_rank,
    (SELECT COUNT(*) FROM challenge_participants cp2 WHERE cp2.challenge_id = c.id AND cp2.is_active = true)
  FROM challenges c
  JOIN challenge_participants cp ON cp.challenge_id = c.id
  WHERE cp.user_id = auth.uid() 
    AND cp.is_active = true 
    AND c.status = 'active'
  ORDER BY c.end_date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
