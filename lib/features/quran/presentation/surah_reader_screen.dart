import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/quran_repository.dart';
import '../domain/models/ayah.dart';
import '../../spiritual/data/spiritual_repository.dart';
import 'providers/quran_reading_session.dart';

class SurahReaderScreen extends ConsumerStatefulWidget {
  final int surahNumber;
  const SurahReaderScreen({super.key, required this.surahNumber});

  @override
  ConsumerState<SurahReaderScreen> createState() => _SurahReaderScreenState();
}

class _SurahReaderScreenState extends ConsumerState<SurahReaderScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _setupAudioListeners();
    // Start tracking time
    Future.microtask(_onSessionStart);
  }

  void _setupAudioListeners() {
    ref.read(quranRepositoryProvider).addListener(_onRepoChange);
  }

  void _onSessionStart() {
    ref.read(quranReadingSessionProvider.notifier).startSession();
  }

  void _onRepoChange() {
    final repo = ref.read(quranRepositoryProvider);
    if (repo.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Audio Error: ${repo.errorMessage}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  void dispose() {
    // End tracking time (logs minutes automatically)
    ref.read(quranReadingSessionProvider.notifier).endSession();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _toggleBookmark(Ayah ayah, String surahName) async {
    try {
      await ref
          .read(quranRepositoryProvider)
          .toggleBookmark(
            surahNumber: widget.surahNumber,
            ayahNumber: ayah.numberInSurah,
            surahName: surahName,
          );

      if (mounted) {
        final isNowBookmarked = ref
            .read(quranRepositoryProvider)
            .isBookmarked(widget.surahNumber, ayah.numberInSurah);

        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isNowBookmarked
                  ? '✓ Ayah ${ayah.numberInSurah} bookmarked'
                  : 'Bookmark removed',
            ),
            backgroundColor: isNowBookmarked
                ? const Color(0xFF4ECDC4)
                : Colors.white24,
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bookmark failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _playAyah(Ayah ayah, int index) async {
    if (ayah.audio == null) return;

    try {
      await ref.read(quranRepositoryProvider).playAyah(ayah.audio!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing audio: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _logProgress() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      // Optimistic update via Notifier
      await ref
          .read(todaysSpiritualLogProvider.notifier)
          .updateQuranReading(pages: 1);
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Progress logged to Spiritual Journey!'),
          backgroundColor: Color(0xFF4ECDC4),
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to log progress: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ayahsAsync = ref.watch(surahAyahsProvider(widget.surahNumber));
    final surahsAsync = ref.watch(surahsProvider);

    final surahName = surahsAsync.when(
      data: (surahs) =>
          surahs.firstWhere((s) => s.number == widget.surahNumber).englishName,
      loading: () => 'Loading...',
      error: (_, _) => 'Surah',
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          surahName,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Color(0xFF4ECDC4)),
            onPressed: _logProgress,
            tooltip: 'Log reading progress',
          ),
        ],
      ),
      body: ayahsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF4ECDC4)),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Error: $err',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        data: (ayahs) {
          return ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: ayahs.length,
            separatorBuilder: (context, index) =>
                const Divider(color: Colors.white10, height: 32),
            itemBuilder: (context, index) {
              final ayah = ayahs[index];

              return _AyahTile(
                ayah: ayah,
                surahNumber: widget.surahNumber,
                surahName: surahName,
                onPlay: () => _playAyah(ayah, index),
                onBookmark: () => _toggleBookmark(ayah, surahName),
              );
            },
          );
        },
      ),
    );
  }
}

/// Extracted Ayah tile widget for clean rebuild isolation
class _AyahTile extends ConsumerWidget {
  final Ayah ayah;
  final int surahNumber;
  final String surahName;
  final VoidCallback onPlay;
  final VoidCallback onBookmark;

  const _AyahTile({
    required this.ayah,
    required this.surahNumber,
    required this.surahName,
    required this.onPlay,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(quranRepositoryProvider);
    final isPlaying = repo.playingAyahUrl == ayah.audio;
    final isLoadingThis = repo.isLoading && repo.playingAyahUrl == ayah.audio;
    final isBookmarked = repo.isBookmarked(surahNumber, ayah.numberInSurah);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4ECDC4).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$surahNumber:${ayah.numberInSurah}',
                style: const TextStyle(
                  color: Color(0xFF4ECDC4),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Row(
              children: [
                // Play / Loading button
                if (isLoadingThis)
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF4ECDC4),
                      ),
                    ),
                  )
                else
                  IconButton(
                    icon: Icon(
                      isPlaying ? Icons.stop_circle : Icons.play_circle,
                      color: isPlaying
                          ? const Color(0xFF4ECDC4)
                          : Colors.white54,
                    ),
                    onPressed: isPlaying ? () => repo.stopAudio() : onPlay,
                  ),

                // Bookmark button — reads directly from local cache
                IconButton(
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: isBookmarked
                        ? const Color(0xFF4ECDC4)
                        : Colors.white54,
                  ),
                  onPressed: onBookmark,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          ayah.text,
          style: GoogleFonts.amiri(
            color: isPlaying
                ? const Color(0xFF4ECDC4)
                : Colors.white.withValues(alpha: 0.9),
            fontSize: 26,
            height: 2.0,
          ),
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
        ),
      ],
    );
  }
}
