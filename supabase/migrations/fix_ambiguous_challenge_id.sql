-- Fix ambiguous column reference in get_my_active_challenges
-- Run this in Supabase SQL Editor

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
