-- Guided Spiritual Exercises Database Schema
-- Prevention App v5.0.0
-- Created: February 9, 2026

-- ============================================
-- SPIRITUAL LOGS TABLE
-- Track daily spiritual activities
-- ============================================
CREATE TABLE IF NOT EXISTS spiritual_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  log_date DATE NOT NULL DEFAULT CURRENT_DATE,
  
  -- Salah tracking (5 daily prayers)
  fajr_prayed BOOLEAN DEFAULT false,
  dhuhr_prayed BOOLEAN DEFAULT false,
  asr_prayed BOOLEAN DEFAULT false,
  maghrib_prayed BOOLEAN DEFAULT false,
  isha_prayed BOOLEAN DEFAULT false,
  
  -- Dhikr counts
  subhanallah_count INTEGER DEFAULT 0,
  alhamdulillah_count INTEGER DEFAULT 0,
  allahuakbar_count INTEGER DEFAULT 0,
  istighfar_count INTEGER DEFAULT 0,
  salawat_count INTEGER DEFAULT 0,
  custom_dhikr_count INTEGER DEFAULT 0,
  custom_dhikr_text TEXT,
  
  -- Quran reading
  quran_pages_read INTEGER DEFAULT 0,
  quran_minutes_read INTEGER DEFAULT 0,
  
  -- Adhkar completed
  morning_adhkar_completed BOOLEAN DEFAULT false,
  evening_adhkar_completed BOOLEAN DEFAULT false,
  sleep_adhkar_completed BOOLEAN DEFAULT false,
  
  -- Notes
  notes TEXT,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  
  -- Constraints
  CONSTRAINT unique_daily_log UNIQUE(user_id, log_date),
  CONSTRAINT check_positive_counts CHECK (
    subhanallah_count >= 0 AND
    alhamdulillah_count >= 0 AND
    allahuakbar_count >= 0 AND
    istighfar_count >= 0 AND
    salawat_count >= 0 AND
    custom_dhikr_count >= 0 AND
    quran_pages_read >= 0 AND
    quran_minutes_read >= 0
  )
);

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS idx_spiritual_logs_user_date ON spiritual_logs(user_id, log_date DESC);

-- ============================================
-- SPIRITUAL GOALS TABLE
-- User's personal spiritual goals
-- ============================================
CREATE TABLE IF NOT EXISTS spiritual_goals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Daily goals
  daily_dhikr_target INTEGER DEFAULT 100,
  daily_quran_pages_target INTEGER DEFAULT 1,
  daily_quran_minutes_target INTEGER DEFAULT 15,
  
  -- Prayer goals
  aim_for_sunnah_prayers BOOLEAN DEFAULT false,
  aim_for_tahajjud BOOLEAN DEFAULT false,
  
  -- Adhkar goals
  morning_adhkar_enabled BOOLEAN DEFAULT true,
  evening_adhkar_enabled BOOLEAN DEFAULT true,
  sleep_adhkar_enabled BOOLEAN DEFAULT true,
  
  -- Reminder settings
  fajr_reminder_enabled BOOLEAN DEFAULT false,
  dhikr_reminder_enabled BOOLEAN DEFAULT false,
  dhikr_reminder_time TIME,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  
  -- One row per user
  CONSTRAINT unique_user_goals UNIQUE(user_id)
);

-- ============================================
-- ADHKAR CONTENT TABLE
-- Pre-populated Islamic adhkar and duas
-- ============================================
CREATE TABLE IF NOT EXISTS adhkar_content (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  category TEXT NOT NULL CHECK (category IN ('morning', 'evening', 'sleep', 'protection', 'general', 'after_salah')),
  title_arabic TEXT NOT NULL,
  title_english TEXT NOT NULL,
  content_arabic TEXT NOT NULL,
  content_transliteration TEXT,
  content_english TEXT NOT NULL,
  
  -- Recitation guidance
  repeat_count INTEGER DEFAULT 1,
  source TEXT, -- Hadith reference
  benefit TEXT, -- Explanation of reward/benefit
  
  -- Ordering
  display_order INTEGER DEFAULT 0,
  
  -- Active flag
  is_active BOOLEAN DEFAULT true,
  
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Index for category lookups
CREATE INDEX IF NOT EXISTS idx_adhkar_category ON adhkar_content(category, display_order);

-- ============================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================
ALTER TABLE spiritual_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE spiritual_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE adhkar_content ENABLE ROW LEVEL SECURITY;

-- Drop existing policies first (idempotent migration)
DROP POLICY IF EXISTS "Users can view own spiritual logs" ON spiritual_logs;
DROP POLICY IF EXISTS "Users can create own spiritual logs" ON spiritual_logs;
DROP POLICY IF EXISTS "Users can update own spiritual logs" ON spiritual_logs;
DROP POLICY IF EXISTS "Users can view own goals" ON spiritual_goals;
DROP POLICY IF EXISTS "Users can create own goals" ON spiritual_goals;
DROP POLICY IF EXISTS "Users can update own goals" ON spiritual_goals;
DROP POLICY IF EXISTS "Anyone can view adhkar content" ON adhkar_content;

-- Spiritual logs: users can only access their own
CREATE POLICY "Users can view own spiritual logs"
  ON spiritual_logs FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own spiritual logs"
  ON spiritual_logs FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own spiritual logs"
  ON spiritual_logs FOR UPDATE
  USING (auth.uid() = user_id);

-- Spiritual goals: users can only access their own
CREATE POLICY "Users can view own goals"
  ON spiritual_goals FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own goals"
  ON spiritual_goals FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own goals"
  ON spiritual_goals FOR UPDATE
  USING (auth.uid() = user_id);

-- Adhkar content: public read access
CREATE POLICY "Anyone can view adhkar content"
  ON adhkar_content FOR SELECT
  USING (is_active = true);

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Get or create today's spiritual log
CREATE OR REPLACE FUNCTION get_or_create_spiritual_log()
RETURNS UUID AS $$
DECLARE
  log_id UUID;
BEGIN
  -- Try to find existing log
  SELECT id INTO log_id
  FROM spiritual_logs
  WHERE user_id = auth.uid() AND log_date = CURRENT_DATE;
  
  -- Create if not exists
  IF log_id IS NULL THEN
    INSERT INTO spiritual_logs (user_id, log_date)
    VALUES (auth.uid(), CURRENT_DATE)
    RETURNING id INTO log_id;
  END IF;
  
  RETURN log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update dhikr count
CREATE OR REPLACE FUNCTION increment_dhikr(
  p_dhikr_type TEXT,
  p_count INTEGER DEFAULT 1
)
RETURNS JSONB AS $$
DECLARE
  log_id UUID;
  new_count INTEGER;
BEGIN
  -- Get or create today's log
  log_id := get_or_create_spiritual_log();
  
  -- Update the appropriate counter
  EXECUTE format(
    'UPDATE spiritual_logs SET %I = %I + $1, updated_at = now() WHERE id = $2 RETURNING %I',
    p_dhikr_type || '_count',
    p_dhikr_type || '_count',
    p_dhikr_type || '_count'
  ) INTO new_count USING p_count, log_id;
  
  RETURN jsonb_build_object('success', true, 'new_count', new_count);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Mark prayer as done
CREATE OR REPLACE FUNCTION mark_prayer_done(p_prayer TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  log_id UUID;
BEGIN
  log_id := get_or_create_spiritual_log();
  
  EXECUTE format(
    'UPDATE spiritual_logs SET %I = true, updated_at = now() WHERE id = $1',
    p_prayer || '_prayed'
  ) USING log_id;
  
  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Mark adhkar session completed
CREATE OR REPLACE FUNCTION mark_adhkar_completed(p_session TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  log_id UUID;
BEGIN
  log_id := get_or_create_spiritual_log();
  
  EXECUTE format(
    'UPDATE spiritual_logs SET %I = true, updated_at = now() WHERE id = $1',
    p_session || '_adhkar_completed'
  ) USING log_id;
  
  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get spiritual streak (consecutive days with any activity)
CREATE OR REPLACE FUNCTION get_spiritual_streak()
RETURNS INTEGER AS $$
DECLARE
  streak INTEGER := 0;
  check_date DATE := CURRENT_DATE;
  has_activity BOOLEAN;
BEGIN
  LOOP
    SELECT EXISTS(
      SELECT 1 FROM spiritual_logs
      WHERE user_id = auth.uid()
        AND log_date = check_date
        AND (
          fajr_prayed OR dhuhr_prayed OR asr_prayed OR maghrib_prayed OR isha_prayed
          OR subhanallah_count > 0 OR alhamdulillah_count > 0 OR allahuakbar_count > 0
          OR quran_pages_read > 0 OR quran_minutes_read > 0
          OR morning_adhkar_completed OR evening_adhkar_completed
        )
    ) INTO has_activity;
    
    IF has_activity THEN
      streak := streak + 1;
      check_date := check_date - 1;
    ELSE
      EXIT;
    END IF;
  END LOOP;
  
  RETURN streak;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
