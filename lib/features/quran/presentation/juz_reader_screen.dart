import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/quran_repository.dart';
import '../domain/models/ayah.dart';
import 'providers/quran_reading_session.dart';

class JuzReaderScreen extends ConsumerStatefulWidget {
  final int juzNumber;
  const JuzReaderScreen({super.key, required this.juzNumber});

  @override
  ConsumerState<JuzReaderScreen> createState() => _JuzReaderScreenState();
}

class _JuzReaderScreenState extends ConsumerState<JuzReaderScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(quranRepositoryProvider).addListener(_onRepoChange);
    // Start tracking time
    Future.microtask(
      () => ref.read(quranReadingSessionProvider.notifier).startSession(),
    );
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
    super.dispose();
  }

  Future<void> _playAyah(Ayah ayah) async {
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

  Future<void> _toggleBookmark(Ayah ayah) async {
    final surahNumber = ayah.surahNumber;
    final surahName = ayah.surahName;

    if (surahNumber == 0) return; // Safety check

    try {
      await ref
          .read(quranRepositoryProvider)
          .toggleBookmark(
            surahNumber: surahNumber,
            ayahNumber: ayah.numberInSurah,
            surahName: surahName,
          );

      if (mounted) {
        final isNowBookmarked = ref
            .read(quranRepositoryProvider)
            .isBookmarked(surahNumber, ayah.numberInSurah);

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

  @override
  Widget build(BuildContext context) {
    final juzAsync = ref.watch(juzAyahsProvider(widget.juzNumber));

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
          'Juz ${widget.juzNumber}',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: juzAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF4ECDC4)),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load Juz ${widget.juzNumber}',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                '$err',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ECDC4),
                ),
                onPressed: () =>
                    ref.invalidate(juzAyahsProvider(widget.juzNumber)),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Color(0xFF0D0D1A)),
                ),
              ),
            ],
          ),
        ),
        data: (juzData) {
          // final ayahs = juzData['ayahs'] as List<Ayah>;
          final grouped = juzData['grouped'] as Map<int, List<Ayah>>;
          final surahNumbers = grouped.keys.toList()..sort();

          // Build a flat list with surah headers interleaved
          final List<dynamic> items = [];
          for (final surahNum in surahNumbers) {
            final surahAyahs = grouped[surahNum]!;
            final firstAyah = surahAyahs.first;
            items.add(
              _SurahHeader(
                surahNumber: surahNum,
                surahName: firstAyah.surahName,
              ),
            );
            items.addAll(surahAyahs);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];

              if (item is _SurahHeader) {
                return Padding(
                  padding: EdgeInsets.only(
                    top: index == 0 ? 0 : 24,
                    bottom: 12,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF4ECDC4).withValues(alpha: 0.15),
                          const Color(0xFF4ECDC4).withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF4ECDC4).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(
                                0xFF4ECDC4,
                              ).withValues(alpha: 0.5),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${item.surahNumber}',
                              style: const TextStyle(
                                color: Color(0xFF4ECDC4),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.surahName,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.menu_book_rounded,
                          color: Color(0xFF4ECDC4),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                );
              }

              final ayah = item as Ayah;
              return _JuzAyahTile(
                ayah: ayah,
                onPlay: () => _playAyah(ayah),
                onBookmark: () => _toggleBookmark(ayah),
              );
            },
          );
        },
      ),
    );
  }
}

/// Simple data class for surah section headers
class _SurahHeader {
  final int surahNumber;
  final String surahName;
  const _SurahHeader({required this.surahNumber, required this.surahName});
}

/// Individual Ayah tile in Juz view
class _JuzAyahTile extends ConsumerWidget {
  final Ayah ayah;
  final VoidCallback onPlay;
  final VoidCallback onBookmark;

  const _JuzAyahTile({
    required this.ayah,
    required this.onPlay,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(quranRepositoryProvider);
    final isPlaying = repo.playingAyahUrl == ayah.audio;
    final isLoadingThis = repo.isLoading && repo.playingAyahUrl == ayah.audio;
    final isBookmarked = repo.isBookmarked(
      ayah.surahNumber,
      ayah.numberInSurah,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4ECDC4).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${ayah.surahNumber}:${ayah.numberInSurah}',
                  style: const TextStyle(
                    color: Color(0xFF4ECDC4),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                children: [
                  if (isLoadingThis)
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF4ECDC4),
                        ),
                      ),
                    )
                  else
                    IconButton(
                      iconSize: 22,
                      icon: Icon(
                        isPlaying ? Icons.stop_circle : Icons.play_circle,
                        color: isPlaying
                            ? const Color(0xFF4ECDC4)
                            : Colors.white54,
                      ),
                      onPressed: isPlaying ? () => repo.stopAudio() : onPlay,
                    ),
                  IconButton(
                    iconSize: 22,
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
          const SizedBox(height: 8),
          Text(
            ayah.text,
            style: GoogleFonts.amiri(
              color: isPlaying
                  ? const Color(0xFF4ECDC4)
                  : Colors.white.withValues(alpha: 0.9),
              fontSize: 24,
              height: 2.0,
            ),
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
          ),
          const Divider(color: Colors.white10, height: 24),
        ],
      ),
    );
  }
}
