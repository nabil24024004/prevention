-- ============================================
-- SEED DATA: Adhkar Content
-- Run this in Supabase SQL Editor to populate adhkar
-- ============================================

-- Clear existing data (optional - run if you want fresh data)
-- TRUNCATE adhkar_content;

-- ============================================
-- MORNING ADHKAR (أذكار الصباح)
-- ============================================

INSERT INTO adhkar_content (category, title_arabic, title_english, content_arabic, content_transliteration, content_english, repeat_count, source, benefit, display_order) VALUES

('morning', 'آية الكرسي', 'Ayatul Kursi', 
'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ',
'Allahu la ilaha illa Huwa, Al-Hayyul-Qayyum...',
'Allah - there is no deity except Him, the Ever-Living, the Sustainer of existence...',
1, 'Quran 2:255', 'Protection until evening', 1),

('morning', 'سيد الاستغفار', 'Master of Seeking Forgiveness',
'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ خَلَقْتَنِي وَأَنَا عَبْدُكَ وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ',
'Allahumma anta Rabbi la ilaha illa anta, khalaqtani wa ana abduka...',
'O Allah, You are my Lord, none has the right to be worshipped except You, You created me and I am Your servant...',
1, 'Bukhari', 'Whoever says this during the day with conviction and dies that day enters Paradise', 2),

('morning', 'التسبيح', 'Glorification',
'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
'Subhan Allahi wa bihamdihi',
'Glory is to Allah and praise is to Him',
100, 'Muslim', 'Sins are forgiven even if like the foam of the sea', 3),

('morning', 'لا إله إلا الله', 'Tawheed',
'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
'La ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamdu, wa Huwa ala kulli shayin Qadir',
'None has the right to be worshipped except Allah, alone, without partner. To Him belongs all sovereignty and praise, and He is over all things omnipotent.',
10, 'Bukhari & Muslim', 'Equivalent to freeing ten slaves, recorded as ten good deeds, ten bad deeds erased, protection from Shaytan', 4),

('morning', 'أذكار الصباح', 'Morning Protection',
'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
'Asbahna wa asbahal-mulku lillah, walhamdu lillah...',
'We have reached the morning and at this very time all sovereignty belongs to Allah, and all praise is for Allah...',
1, 'Muslim', 'Start your morning with the remembrance of Allah', 5);

-- ============================================
-- EVENING ADHKAR (أذكار المساء)
-- ============================================

INSERT INTO adhkar_content (category, title_arabic, title_english, content_arabic, content_transliteration, content_english, repeat_count, source, benefit, display_order) VALUES

('evening', 'آية الكرسي', 'Ayatul Kursi',
'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ',
'Allahu la ilaha illa Huwa, Al-Hayyul-Qayyum...',
'Allah - there is no deity except Him, the Ever-Living, the Sustainer of existence...',
1, 'Quran 2:255', 'Protection until morning', 1),

('evening', 'أذكار المساء', 'Evening Protection',
'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
'Amsayna wa amsal-mulku lillah, walhamdu lillah...',
'We have reached the evening and at this very time all sovereignty belongs to Allah...',
1, 'Muslim', 'Start your evening with the remembrance of Allah', 2),

('evening', 'المعوذات', 'The Protective Surahs',
'قُلْ هُوَ اللَّهُ أَحَدٌ...\nقُلْ أَعُوذُ بِرَبِّ الْفَلَقِ...\nقُلْ أَعُوذُ بِرَبِّ النَّاسِ...',
'Qul Huwa Allahu Ahad... Qul A''udhu bi Rabbil-Falaq... Qul A''udhu bi Rabbin-Nas...',
'Surah Al-Ikhlas, Al-Falaq, and An-Nas',
3, 'Abu Dawud, Tirmidhi', 'Protection from all evil', 3),

('evening', 'التسبيح', 'Glorification',
'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
'Subhan Allahi wa bihamdihi',
'Glory is to Allah and praise is to Him',
100, 'Muslim', 'Sins are forgiven even if like the foam of the sea', 4);

-- ============================================
-- BEFORE SLEEP ADHKAR (أذكار النوم)
-- ============================================

INSERT INTO adhkar_content (category, title_arabic, title_english, content_arabic, content_transliteration, content_english, repeat_count, source, benefit, display_order) VALUES

('sleep', 'آية الكرسي', 'Ayatul Kursi',
'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ...',
'Allahu la ilaha illa Huwa, Al-Hayyul-Qayyum...',
'Allah - there is no deity except Him, the Ever-Living, the Sustainer of existence...',
1, 'Quran 2:255, Bukhari', 'Allah will appoint a guardian angel for you until morning', 1),

('sleep', 'دعاء النوم', 'Sleep Dua',
'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
'Bismika Allahumma amutu wa ahya',
'In Your name, O Allah, I die and I live',
1, 'Bukhari', 'Remembering Allah as you sleep', 2),

('sleep', 'التسبيح والتحميد والتكبير', 'Glorification, Praise, and Magnification',
'سُبْحَانَ اللَّهِ\nالْحَمْدُ لِلَّهِ\nاللَّهُ أَكْبَرُ',
'SubhanAllah, Alhamdulillah, Allahu Akbar',
'Glory be to Allah, Praise be to Allah, Allah is the Greatest',
33, 'Bukhari & Muslim', 'The Prophet ﷺ taught Fatimah and Ali to say this before sleep', 3),

('sleep', 'سورة الملك', 'Surah Al-Mulk',
'تَبَارَكَ الَّذِي بِيَدِهِ الْمُلْكُ وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ...',
'Tabarakal-ladhi biyadihil-mulk...',
'Blessed is He in whose hand is dominion...',
1, 'Tirmidhi', 'Intercedes for its reciter until he is forgiven', 4);

-- ============================================
-- PROTECTION ADHKAR (أذكار الحماية)
-- ============================================

INSERT INTO adhkar_content (category, title_arabic, title_english, content_arabic, content_transliteration, content_english, repeat_count, source, benefit, display_order) VALUES

('protection', 'الاستعاذة من الشيطان', 'Seeking Refuge from Shaytan',
'أَعُوذُ بِاللَّهِ السَّمِيعِ الْعَلِيمِ مِنَ الشَّيْطَانِ الرَّجِيمِ',
'A''udhu billahis-sami''il-''alim minash-shaytanir-rajim',
'I seek refuge in Allah, the All-Hearing and All-Knowing, from the accursed Shaytan',
1, 'Abu Dawud', 'Protection from the whispers of Shaytan', 1),

('protection', 'المعوذتان', 'The Two Protective Surahs',
'قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ...\nقُلْ أَعُوذُ بِرَبِّ النَّاسِ...',
'Qul A''udhu bi Rabbil-Falaq... Qul A''udhu bi Rabbin-Nas...',
'Say: I seek refuge in the Lord of the daybreak... Say: I seek refuge in the Lord of mankind...',
3, 'Bukhari, Muslim', 'The Prophet ﷺ would seek refuge with these surahs from every evil', 2),

('protection', 'دعاء الحماية', 'Protection Supplication',
'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ',
'Bismillahil-ladhi la yadurru ma''asmihi shay''un fil-ardi wa la fis-sama''i wa Huwas-Sami''ul-''Alim',
'In the name of Allah with whose name nothing can harm on earth or in heaven, and He is the All-Hearing, All-Knowing',
3, 'Abu Dawud, Tirmidhi', 'Nothing will harm you until evening/morning', 3);

-- ============================================
-- AFTER SALAH ADHKAR (أذكار بعد الصلاة)
-- ============================================

INSERT INTO adhkar_content (category, title_arabic, title_english, content_arabic, content_transliteration, content_english, repeat_count, source, benefit, display_order) VALUES

('after_salah', 'الاستغفار', 'Seeking Forgiveness',
'أَسْتَغْفِرُ اللَّهَ',
'Astaghfirullah',
'I seek forgiveness from Allah',
3, 'Muslim', 'Seeking forgiveness for any shortcomings in prayer', 1),

('after_salah', 'اللهم أنت السلام', 'You are Peace',
'اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ',
'Allahumma antas-Salam wa minkas-salam, tabarakta ya Dhal-Jalali wal-Ikram',
'O Allah, You are Peace and from You is peace. Blessed are You, O Owner of majesty and honor',
1, 'Muslim', 'Said immediately after the tasleem', 2),

('after_salah', 'التسبيح', 'Post-Prayer Dhikr',
'سُبْحَانَ اللَّهِ\nالْحَمْدُ لِلَّهِ\nاللَّهُ أَكْبَرُ',
'SubhanAllah, Alhamdulillah, Allahu Akbar',
'Glory be to Allah, Praise be to Allah, Allah is the Greatest',
33, 'Bukhari & Muslim', 'Whoever says this after every prayer will have his sins forgiven', 3),

('after_salah', 'آية الكرسي', 'Ayatul Kursi',
'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ...',
'Allahu la ilaha illa Huwa, Al-Hayyul-Qayyum...',
'Allah - there is no deity except Him, the Ever-Living, the Sustainer of existence...',
1, 'Nasai', 'Nothing prevents him from entering Paradise except death', 4);

-- ============================================
-- GENERAL ADHKAR (أذكار عامة)
-- ============================================

INSERT INTO adhkar_content (category, title_arabic, title_english, content_arabic, content_transliteration, content_english, repeat_count, source, benefit, display_order) VALUES

('general', 'الصلاة على النبي', 'Salawat on the Prophet',
'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ إِنَّكَ حَمِيدٌ مَجِيدٌ',
'Allahumma salli ala Muhammad wa ala ali Muhammad...',
'O Allah, send prayers upon Muhammad and the family of Muhammad...',
10, 'Bukhari', 'Allah sends ten blessings on you for every one salawat', 1),

('general', 'لا حول ولا قوة إلا بالله', 'There is no power except with Allah',
'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
'La hawla wa la quwwata illa billah',
'There is no might nor power except with Allah',
10, 'Bukhari & Muslim', 'A treasure from the treasures of Paradise', 2),

('general', 'الحمد لله', 'Praise be to Allah',
'الْحَمْدُ لِلَّهِ',
'Alhamdulillah',
'All praise is due to Allah',
100, 'Tirmidhi', 'Fills the scales on the Day of Judgment', 3);
