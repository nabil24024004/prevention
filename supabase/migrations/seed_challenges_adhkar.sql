-- Seed data for Community Challenges and Adhkar Content
-- Run this after deploying the schema migrations

-- =============================================================================
-- SAMPLE CHALLENGES
-- =============================================================================

-- 7-Day Streak Challenge
INSERT INTO public.challenges (
  id, title, description, challenge_type, start_date, end_date,
  target_value, target_unit, is_public, status, max_participants
) VALUES (
  gen_random_uuid(),
  '7-Day Clean Streak',
  'Maintain a clean streak for 7 consecutive days. Stay strong together!',
  'streak',
  CURRENT_DATE,
  CURRENT_DATE + INTERVAL '30 days',
  7,
  'days',
  true,
  'active',
  0
);

-- 30-Day Streak Challenge
INSERT INTO public.challenges (
  id, title, description, challenge_type, start_date, end_date,
  target_value, target_unit, is_public, status, max_participants
) VALUES (
  gen_random_uuid(),
  '30-Day Transformation',
  'Complete a full 30-day streak. Build unshakeable discipline!',
  'streak',
  CURRENT_DATE,
  CURRENT_DATE + INTERVAL '45 days',
  30,
  'days',
  true,
  'active',
  0
);

-- 1000 Dhikr Challenge
INSERT INTO public.challenges (
  id, title, description, challenge_type, start_date, end_date,
  target_value, target_unit, is_public, status, max_participants
) VALUES (
  gen_random_uuid(),
  '1000 Dhikr in a Week',
  'Complete 1000 dhikr recitations this week. Fill your heart with remembrance.',
  'dhikr',
  CURRENT_DATE,
  CURRENT_DATE + INTERVAL '7 days',
  1000,
  'dhikr',
  true,
  'active',
  0
);

-- Quran Reading Challenge
INSERT INTO public.challenges (
  id, title, description, challenge_type, start_date, end_date,
  target_value, target_unit, is_public, status, max_participants
) VALUES (
  gen_random_uuid(),
  'Quran Month',
  'Read 30 pages of Quran this month. One page a day keeps Shaytan away.',
  'quran',
  CURRENT_DATE,
  CURRENT_DATE + INTERVAL '30 days',
  30,
  'pages',
  true,
  'active',
  0
);

-- 5 Salah Challenge
INSERT INTO public.challenges (
  id, title, description, challenge_type, start_date, end_date,
  target_value, target_unit, is_public, status, max_participants
) VALUES (
  gen_random_uuid(),
  'Perfect Prayer Week',
  'Pray all 5 daily prayers for 7 days. Never miss a beat.',
  'custom',
  CURRENT_DATE,
  CURRENT_DATE + INTERVAL '7 days',
  35,
  'prayers',
  true,
  'active',
  0
);

-- =============================================================================
-- ADHKAR CONTENT
-- Column mapping: title_arabic, title_english, content_arabic, 
--                 content_transliteration, content_english, repeat_count, 
--                 source, display_order
-- =============================================================================

INSERT INTO public.adhkar_content (
  id, category, title_arabic, title_english, content_arabic, 
  content_transliteration, content_english, repeat_count, source, display_order
) VALUES

-- Morning Adhkar
(gen_random_uuid(), 'morning', 
 'دعاء الصباح', 'Morning Supplication',
 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
 'Asbahna wa asbahal mulku lillah, walhamdulillah, la ilaha illallahu wahdahu la shareeka lah, lahul mulku wa lahul hamd, wa huwa ala kulli shayin qadeer',
 'We have reached the morning and at this very time all sovereignty belongs to Allah. All praise is due to Allah. None has the right to be worshipped except Allah, alone, without any partner.',
 1, 'Abu Dawud 4:317', 1),

(gen_random_uuid(), 'morning',
 'التوكل على الله', 'Reliance on Allah',
 'اللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ النُّشُورُ',
 'Allahumma bika asbahna, wa bika amsayna, wa bika nahya, wa bika namoot, wa ilaykan nushoor',
 'O Allah, by Your leave we have reached the morning, by Your leave we live and die and unto You is our resurrection.',
 1, 'Tirmidhi 5:466', 2),

(gen_random_uuid(), 'morning',
 'التسبيح', 'Glorification',
 'سُبْحَانَ اللهِ وَبِحَمْدِهِ',
 'SubhanAllahi wa bihamdihi',
 'Glory is to Allah and praise is to Him.',
 100, 'Muslim 4:2071', 3),

(gen_random_uuid(), 'morning',
 'التوحيد', 'Declaration of Oneness',
 'لَا إِلَهَ إِلَّا اللهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
 'La ilaha illallahu wahdahu la shareeka lah, lahul mulku wa lahul hamd, wa huwa ala kulli shayin qadeer',
 'None has the right to be worshipped except Allah, alone, without partner. To Him belongs all sovereignty and praise.',
 10, 'Bukhari 4:95', 4),

(gen_random_uuid(), 'morning',
 'الاستغفار', 'Seeking Forgiveness',
 'أَسْتَغْفِرُ اللهَ وَأَتُوبُ إِلَيْهِ',
 'Astaghfirullaha wa atoobu ilayhi',
 'I seek Allahs forgiveness and I repent to Him.',
 100, 'Bukhari 11:101', 5),

-- Evening Adhkar
(gen_random_uuid(), 'evening',
 'دعاء المساء', 'Evening Supplication',
 'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
 'Amsayna wa amsal mulku lillah, walhamdulillah, la ilaha illallahu wahdahu la shareeka lah, lahul mulku wa lahul hamd, wa huwa ala kulli shayin qadeer',
 'We have reached the evening and at this very time all sovereignty belongs to Allah. All praise is due to Allah.',
 1, 'Abu Dawud 4:317', 1),

(gen_random_uuid(), 'evening',
 'التوكل على الله', 'Reliance on Allah',
 'اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ الْمَصِيرُ',
 'Allahumma bika amsayna, wa bika asbahna, wa bika nahya, wa bika namoot, wa ilaykal maseer',
 'O Allah, by Your leave we have reached the evening, by Your leave we live and die and unto You is our return.',
 1, 'Tirmidhi 5:466', 2),

(gen_random_uuid(), 'evening',
 'التسبيح', 'Glorification',
 'سُبْحَانَ اللهِ وَبِحَمْدِهِ',
 'SubhanAllahi wa bihamdihi',
 'Glory is to Allah and praise is to Him.',
 100, 'Muslim 4:2071', 3),

(gen_random_uuid(), 'evening',
 'الاستعاذة', 'Seeking Refuge',
 'أَعُوذُ بِكَلِمَاتِ اللهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
 'Aoodhu bikalimatillahit-tammaati min sharri ma khalaq',
 'I seek refuge in the perfect words of Allah from the evil of that which He has created.',
 3, 'Muslim 4:2081', 4),

-- Sleep Adhkar
(gen_random_uuid(), 'sleep',
 'دعاء النوم', 'Sleep Supplication',
 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
 'Bismika Allahumma amootu wa ahya',
 'In Your name O Allah, I die and I live.',
 1, 'Bukhari 11:113', 1),

(gen_random_uuid(), 'sleep',
 'الحماية من العذاب', 'Protection from Punishment',
 'اللَّهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ',
 'Allahumma qinee adhabaka yawma tabathu ibadak',
 'O Allah, save me from Your punishment on the Day when You resurrect Your servants.',
 3, 'Abu Dawud 4:311', 2),

(gen_random_uuid(), 'sleep',
 'التسبيح قبل النوم', 'Pre-Sleep Glorification',
 'سُبْحَانَ اللهِ',
 'SubhanAllah',
 'Glory is to Allah.',
 33, 'Bukhari & Muslim', 3),

(gen_random_uuid(), 'sleep',
 'الحمد قبل النوم', 'Pre-Sleep Praise',
 'الْحَمْدُ لِلَّهِ',
 'Alhamdulillah',
 'All praise is due to Allah.',
 33, 'Bukhari & Muslim', 4),

(gen_random_uuid(), 'sleep',
 'التكبير قبل النوم', 'Pre-Sleep Magnification',
 'اللهُ أَكْبَرُ',
 'Allahu Akbar',
 'Allah is the Greatest.',
 34, 'Bukhari & Muslim', 5),

-- General Adhkar (using 'general' instead of 'wakeup')
(gen_random_uuid(), 'general',
 'دعاء الاستيقاظ', 'Waking Up Supplication',
 'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ',
 'Alhamdulillahil-lathee ahyana bada ma amatana wa ilayhin-nushoor',
 'All praise is due to Allah who gave us life after having taken it from us and unto Him is the resurrection.',
 1, 'Bukhari', 1);
