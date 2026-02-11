-- =========================================
-- Sync Spiritual Activities to Challenges
-- =========================================
-- This migration creates triggers to automatically update challenge 
-- progress when users log spiritual activities or update their clean streak.

-- Function to sync spiritual log updates (dhikr & quran)
CREATE OR REPLACE FUNCTION sync_spiritual_to_challenges()
RETURNS TRIGGER AS $$
DECLARE
  v_participation RECORD;
  v_total_dhikr INTEGER;
BEGIN
  -- Calculate total dhikr from log
  v_total_dhikr := COALESCE(NEW.subhanallah_count, 0) + 
                   COALESCE(NEW.alhamdulillah_count, 0) + 
                   COALESCE(NEW.allahuakbar_count, 0) +
                   COALESCE(NEW.istighfar_count, 0) +
                   COALESCE(NEW.salawat_count, 0) +
                   COALESCE(NEW.custom_dhikr_count, 0);
  
  -- Update dhikr and quran challenges
  FOR v_participation IN
    SELECT cp.id, c.challenge_type, c.target_value
    FROM challenge_participants cp
    JOIN challenges c ON c.id = cp.challenge_id
    WHERE cp.user_id = NEW.user_id
      AND cp.is_active = true
      AND c.status = 'active'
      AND c.challenge_type IN ('dhikr', 'quran')
      AND CURRENT_DATE BETWEEN c.start_date AND c.end_date
  LOOP
    IF v_participation.challenge_type = 'dhikr' THEN
      UPDATE challenge_participants
      SET 
        current_progress = v_total_dhikr,
        best_progress = GREATEST(best_progress, v_total_dhikr),
        completed_at = CASE 
          WHEN v_total_dhikr >= v_participation.target_value AND completed_at IS NULL 
          THEN now() 
          ELSE completed_at 
        END,
        updated_at = now()
      WHERE id = v_participation.id;
    ELSIF v_participation.challenge_type = 'quran' THEN
      UPDATE challenge_participants
      SET 
        current_progress = COALESCE(NEW.quran_pages_read, 0),
        best_progress = GREATEST(best_progress, COALESCE(NEW.quran_pages_read, 0)),
        completed_at = CASE 
          WHEN COALESCE(NEW.quran_pages_read, 0) >= v_participation.target_value AND completed_at IS NULL 
          THEN now() 
          ELSE completed_at 
        END,
        updated_at = now()
      WHERE id = v_participation.id;
    END IF;
  END LOOP;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to sync clean streak updates from users table
CREATE OR REPLACE FUNCTION sync_user_streak_to_challenges()
RETURNS TRIGGER AS $$
DECLARE
  v_participation RECORD;
BEGIN
  -- Only proceed if streak changed
  IF NEW.current_streak_days IS DISTINCT FROM OLD.current_streak_days THEN
    -- Update all active streak challenges
    FOR v_participation IN
      SELECT cp.id, c.target_value
      FROM challenge_participants cp
      JOIN challenges c ON c.id = cp.challenge_id
      WHERE cp.user_id = NEW.id
        AND cp.is_active = true
        AND c.status = 'active'
        AND c.challenge_type = 'streak'
        AND CURRENT_DATE BETWEEN c.start_date AND c.end_date
    LOOP
      UPDATE challenge_participants
      SET 
        current_progress = COALESCE(NEW.current_streak_days, 0),
        best_progress = GREATEST(best_progress, COALESCE(NEW.current_streak_days, 0)),
        completed_at = CASE 
          WHEN COALESCE(NEW.current_streak_days, 0) >= v_participation.target_value AND completed_at IS NULL 
          THEN now() 
          ELSE completed_at 
        END,
        updated_at = now()
      WHERE id = v_participation.id;
    END LOOP;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger on spiritual_logs
DROP TRIGGER IF EXISTS sync_spiritual_challenges_trigger ON spiritual_logs;
CREATE TRIGGER sync_spiritual_challenges_trigger
  AFTER INSERT OR UPDATE ON spiritual_logs
  FOR EACH ROW
  EXECUTE FUNCTION sync_spiritual_to_challenges();

-- Create trigger on users table for streak updates
DROP TRIGGER IF EXISTS sync_user_streak_challenges_trigger ON users;
CREATE TRIGGER sync_user_streak_challenges_trigger
  AFTER UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION sync_user_streak_to_challenges();

