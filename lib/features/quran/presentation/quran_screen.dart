import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/models/surah.dart';
import '../data/quran_repository.dart';

class QuranScreen extends ConsumerStatefulWidget {
  const QuranScreen({super.key});

  @override
  ConsumerState<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends ConsumerState<QuranScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surahsAsync = ref.watch(surahsProvider);

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
          'Al-Quran Sharif',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF4ECDC4),
          labelColor: const Color(0xFF4ECDC4),
          unselectedLabelColor: Colors.white54,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Surah'),
            Tab(text: 'Juz'),
            Tab(text: 'Bookmarks'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search Surah...',
                hintStyle: const TextStyle(color: Colors.white24),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1A1A2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSurahList(surahsAsync),
                _buildJuzList(),
                _buildBookmarksList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahList(AsyncValue<List<Surah>> surahsAsync) {
    return surahsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF4ECDC4)),
      ),
      error: (err, stack) => Center(
        child: Text('Error: $err', style: const TextStyle(color: Colors.white)),
      ),
      data: (surahs) {
        final filteredSurahs = surahs.where((s) {
          return s.englishName.toLowerCase().contains(_searchQuery) ||
              s.name.contains(_searchQuery) ||
              s.number.toString() == _searchQuery;
        }).toList();

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: filteredSurahs.length,
          separatorBuilder: (context, index) =>
              const Divider(color: Colors.white10),
          itemBuilder: (context, index) {
            final surah = filteredSurahs[index];
            return ListTile(
              onTap: () =>
                  context.push('/spiritual/quran/surah/${surah.number}'),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF4ECDC4).withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    surah.number.toString(),
                    style: const TextStyle(
                      color: Color(0xFF4ECDC4),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              title: Text(
                surah.englishName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                '${surah.revelationType} • ${surah.numberOfAyahs} Ayahs',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              trailing: Text(
                surah.name,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  color: Color(0xFF4ECDC4),
                  fontSize: 18,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildJuzList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 30,
      itemBuilder: (context, index) {
        final juzNumber = index + 1;
        return ListTile(
          onTap: () => context.push('/spiritual/quran/juz/$juzNumber'),
          title: Text(
            'Juz $juzNumber',
            style: const TextStyle(color: Colors.white),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            color: Colors.white24,
            size: 16,
          ),
        );
      },
    );
  }

  Widget _buildBookmarksList() {
    // Watch the repository to get instant updates from local cache
    final repo = ref.watch(quranRepositoryProvider);
    final bookmarks = repo.bookmarksList;

    if (!repo.bookmarksLoaded) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4ECDC4)),
      );
    }

    if (bookmarks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              color: Colors.white.withValues(alpha: 0.15),
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'No bookmarks yet',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the bookmark icon while reading\nto save your favorite Ayahs.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: bookmarks.length,
      separatorBuilder: (context, index) =>
          const Divider(color: Colors.white10),
      itemBuilder: (context, index) {
        final bookmark = bookmarks[index];
        return Dismissible(
          key: ValueKey('${bookmark.surahNumber}:${bookmark.ayahNumber}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.redAccent.withValues(alpha: 0.2),
            child: const Icon(Icons.delete, color: Colors.redAccent),
          ),
          onDismissed: (_) {
            ref
                .read(quranRepositoryProvider)
                .toggleBookmark(
                  surahNumber: bookmark.surahNumber,
                  ayahNumber: bookmark.ayahNumber,
                  surahName: bookmark.surahName,
                );
          },
          child: ListTile(
            onTap: () =>
                context.push('/spiritual/quran/surah/${bookmark.surahNumber}'),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF4ECDC4).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.bookmark, color: Color(0xFF4ECDC4), size: 20),
              ),
            ),
            title: Text(
              '${bookmark.surahName} • Ayah ${bookmark.ayahNumber}',
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              'Added ${bookmark.createdAt.toString().split(' ')[0]}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white24),
              onPressed: () {
                ref
                    .read(quranRepositoryProvider)
                    .toggleBookmark(
                      surahNumber: bookmark.surahNumber,
                      ayahNumber: bookmark.ayahNumber,
                      surahName: bookmark.surahName,
                    );
              },
            ),
          ),
        );
      },
    );
  }
}
