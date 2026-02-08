import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prevention/core/theme/app_colors.dart';
import '../data/content_repository.dart';

class IslamicCornerScreen extends ConsumerWidget {
  const IslamicCornerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Islamic Corner',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Verses'),
              Tab(text: 'Hadiths'),
              Tab(text: 'Duas'),
              Tab(text: 'Quotes'),
            ],
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
          ),
        ),
        body: const TabBarView(
          children: [
            ContentList(type: 'verse'),
            ContentList(type: 'hadith'),
            ContentList(type: 'dua'),
            ContentList(type: 'quote'),
          ],
        ),
      ),
    );
  }
}

class ContentList extends ConsumerWidget {
  final String type;
  const ContentList({super.key, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(contentStreamProvider(type));

    return contentAsync.when(
      data: (items) {
        if (items.isEmpty) return const Center(child: Text('No content yet.'));
        return ListView.separated(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item['title'] != null)
                      Text(
                        item['title'],
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    if (item['title'] != null) const SizedBox(height: 8),
                    Text(
                      item['content'],
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                    if (item['source'] != null) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '- ${item['source']}',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text('Offline', style: TextStyle(color: Colors.grey[400], fontSize: 18)),
            const SizedBox(height: 8),
            Text('Connect to internet to load content', 
              style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
