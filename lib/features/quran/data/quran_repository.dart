import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audio_session/audio_session.dart';
import '../domain/models/surah.dart';
import '../domain/models/ayah.dart';
import '../domain/models/quran_bookmark.dart';

class QuranRepository extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final String _baseUrl = 'https://api.alquran.cloud/v1';
  final SupabaseClient _supabase = Supabase.instance.client;

  AudioPlayer get audioPlayer => _audioPlayer;
  String? _playingAyahUrl;
  String? get playingAyahUrl => _playingAyahUrl;

  // ── Local-first bookmark cache ──────────────────────────────────
  final Set<String> _bookmarkKeys = {};
  final Map<String, QuranBookmark> _bookmarkCache = {};
  bool _bookmarksLoaded = false;

  bool isBookmarked(int surahNumber, int ayahNumber) =>
      _bookmarkKeys.contains('$surahNumber:$ayahNumber');

  List<QuranBookmark> get bookmarksList =>
      _bookmarkCache.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  bool get bookmarksLoaded => _bookmarksLoaded;
  // ────────────────────────────────────────────────────────────────

  QuranRepository() {
    _init();
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());

    _audioPlayer.playbackEventStream.listen(
      (event) {},
      onError: (Object e, StackTrace st) {
        _errorMessage = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );

    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _playingAyahUrl = null;
        _isLoading = false;
        notifyListeners();
      }
    });

    // Pre-load bookmarks into local cache
    await loadBookmarks();
  }

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  set playingAyahUrl(String? value) {
    if (_playingAyahUrl != value) {
      _playingAyahUrl = value;
      notifyListeners();
    }
  }

  // ══════════════════════════════════════════════════════════════════
  //  SURAH & AYAH FETCHING
  // ══════════════════════════════════════════════════════════════════

  Future<List<Surah>> getSurahs() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/surah'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List)
            .map((json) => Surah.fromJson(json))
            .toList();
      }
      throw Exception('Failed to load Surahs');
    } catch (e) {
      throw Exception('Error fetching Surahs: $e');
    }
  }

  Future<List<Ayah>> getSurahAyahs(
    int surahNumber, {
    String edition = 'ar.alafasy',
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/surah/$surahNumber/$edition'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseAyahList(data['data']['ayahs'] as List);
      }
      throw Exception('Failed to load Surah detail');
    } catch (e) {
      throw Exception('Error fetching Ayahs: $e');
    }
  }

  /// Fetch all ayahs for a specific Juz with audio
  Future<Map<String, dynamic>> getJuzAyahs(
    int juzNumber, {
    String edition = 'ar.alafasy',
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/juz/$juzNumber/$edition'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final juzData = data['data'];
        final ayahs = _parseAyahList(juzData['ayahs'] as List);

        // Group ayahs by surah number for section headers
        final Map<int, List<Ayah>> groupedBySurah = {};
        for (final ayah in ayahs) {
          // The API gives us `surah` info inside each ayah for juz endpoints
          // We need to figure out which surah each ayah belongs to
          // We can derive it from the ayah's global number range
          groupedBySurah.putIfAbsent(ayah.surahNumber, () => []).add(ayah);
        }

        return {
          'ayahs': ayahs,
          'grouped': groupedBySurah,
          'juzNumber': juzNumber,
        };
      }
      throw Exception('Failed to load Juz $juzNumber');
    } catch (e) {
      throw Exception('Error fetching Juz: $e');
    }
  }

  List<Ayah> _parseAyahList(List<dynamic> ayahsJson) {
    return ayahsJson.map((json) {
      final ayah = Ayah.fromJson(json);
      final secureAudio = ayah.audio?.replaceFirst('http://', 'https://');
      return Ayah(
        number: ayah.number,
        text: ayah.text,
        numberInSurah: ayah.numberInSurah,
        juz: ayah.juz,
        manzil: ayah.manzil,
        page: ayah.page,
        ruku: ayah.ruku,
        hizbQuarter: ayah.hizbQuarter,
        sajda: ayah.sajda,
        audio: secureAudio,
        audioSecondary: ayah.audioSecondary,
        surahNumber: ayah.surahNumber,
        surahName: ayah.surahName,
      );
    }).toList();
  }

  // ══════════════════════════════════════════════════════════════════
  //  AUDIO PLAYBACK
  // ══════════════════════════════════════════════════════════════════

  Future<void> playAyah(String audioUrl) async {
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    if (audioUrl.isEmpty) {
      _errorMessage = 'Invalid audio URL';
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      playingAyahUrl = audioUrl;
      await _audioPlayer.stop();

      final source = AudioSource.uri(Uri.parse(audioUrl), tag: audioUrl);

      await _audioPlayer.setAudioSource(source);
      _isLoading = false;
      notifyListeners();

      await _audioPlayer.play();
    } catch (e) {
      playingAyahUrl = null;
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> stopAudio() async {
    playingAyahUrl = null;
    await _audioPlayer.stop();
  }

  // ══════════════════════════════════════════════════════════════════
  //  BOOKMARKS — LOCAL-FIRST WITH SUPABASE SYNC
  // ══════════════════════════════════════════════════════════════════

  /// Load all bookmarks from Supabase into local cache (called once on init)
  Future<void> loadBookmarks() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        _bookmarksLoaded = true;
        notifyListeners();
        return;
      }

      final response = await _supabase
          .from('quran_bookmarks')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      _bookmarkKeys.clear();
      _bookmarkCache.clear();

      for (final json in response as List) {
        final bookmark = QuranBookmark.fromJson(json);
        final key = '${bookmark.surahNumber}:${bookmark.ayahNumber}';
        _bookmarkKeys.add(key);
        _bookmarkCache[key] = bookmark;
      }

      _bookmarksLoaded = true;
      notifyListeners();
    } catch (e) {
      // Silently fail — bookmarks are a secondary feature
      _bookmarksLoaded = true;
      notifyListeners();
      debugPrint('QuranRepository: Failed to load bookmarks: $e');
    }
  }

  /// Toggle a bookmark with instant local UI update + background Supabase sync
  Future<void> toggleBookmark({
    required int surahNumber,
    required int ayahNumber,
    required String surahName,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to bookmark Ayahs');
    }

    final key = '$surahNumber:$ayahNumber';
    final wasBookmarked = _bookmarkKeys.contains(key);

    // ── Optimistic local update (INSTANT) ──
    if (wasBookmarked) {
      _bookmarkKeys.remove(key);
      _bookmarkCache.remove(key);
    } else {
      _bookmarkKeys.add(key);
      _bookmarkCache[key] = QuranBookmark(
        id: 'local-${DateTime.now().millisecondsSinceEpoch}',
        userId: user.id,
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        surahName: surahName,
        createdAt: DateTime.now(),
      );
    }
    notifyListeners(); // UI updates immediately

    // ── Background Supabase sync ──
    try {
      if (wasBookmarked) {
        await _supabase
            .from('quran_bookmarks')
            .delete()
            .eq('user_id', user.id)
            .eq('surah_number', surahNumber)
            .eq('ayah_number', ayahNumber);
      } else {
        final insertedRows = await _supabase.from('quran_bookmarks').insert({
          'user_id': user.id,
          'surah_number': surahNumber,
          'ayah_number': ayahNumber,
          'surah_name': surahName,
        }).select();

        // Update local cache with real server ID
        if (insertedRows.isNotEmpty) {
          _bookmarkCache[key] = QuranBookmark.fromJson(insertedRows[0]);
          // No need to notifyListeners — ID change is invisible to UI
        }
      }
    } catch (e) {
      // ── Rollback on failure ──
      if (wasBookmarked) {
        _bookmarkKeys.add(key);
        _bookmarkCache[key] = QuranBookmark(
          id: 'rollback',
          userId: user.id,
          surahNumber: surahNumber,
          ayahNumber: ayahNumber,
          surahName: surahName,
          createdAt: DateTime.now(),
        );
      } else {
        _bookmarkKeys.remove(key);
        _bookmarkCache.remove(key);
      }
      notifyListeners();
      debugPrint('QuranRepository: Bookmark sync failed, rolled back: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}

// ══════════════════════════════════════════════════════════════════════
//  PROVIDERS
// ══════════════════════════════════════════════════════════════════════

final quranRepositoryProvider = ChangeNotifierProvider<QuranRepository>((ref) {
  final repo = QuranRepository();
  ref.onDispose(() => repo.dispose());
  return repo;
});

final surahsProvider = FutureProvider<List<Surah>>((ref) {
  return ref.watch(quranRepositoryProvider).getSurahs();
});

final surahAyahsProvider = FutureProvider.family<List<Ayah>, int>((
  ref,
  surahNumber,
) {
  return ref.watch(quranRepositoryProvider).getSurahAyahs(surahNumber);
});

final juzAyahsProvider = FutureProvider.family<Map<String, dynamic>, int>((
  ref,
  juzNumber,
) {
  return ref.watch(quranRepositoryProvider).getJuzAyahs(juzNumber);
});
