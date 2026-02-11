import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/spiritual_repository.dart';
import '../data/models/adhkar_item.dart';

/// Adhkar reader screen - browse and recite adhkar by category
class AdhkarReaderScreen extends ConsumerStatefulWidget {
  final String? initialCategory;

  const AdhkarReaderScreen({super.key, this.initialCategory});

  @override
  ConsumerState<AdhkarReaderScreen> createState() => _AdhkarReaderScreenState();
}

class _AdhkarReaderScreenState extends ConsumerState<AdhkarReaderScreen> {
  AdhkarCategory _selectedCategory = AdhkarCategory.morning;
  int _currentIndex = 0;
  PageController? _pageController;
  Map<int, int> _reciteCounts = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _selectedCategory = AdhkarCategoryX.fromString(widget.initialCategory!);
    }
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  void _incrementReciteCount(int index, int maxCount) {
    final current = _reciteCounts[index] ?? 0;
    if (current < maxCount) {
      setState(() => _reciteCounts[index] = current + 1);
    }
  }

  Future<void> _markSessionComplete() async {
    try {
      await ref
          .read(spiritualRepositoryProvider)
          .markAdhkarCompleted(_selectedCategory);
      ref.invalidate(todaysSpiritualLogProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session completed! Barakallahu feek'),
            backgroundColor: Color(0xFF4ECDC4),
          ),
        );
      }
    } catch (e) {
      // Silent fail
    }
  }

  @override
  Widget build(BuildContext context) {
    final adhkarAsync = ref.watch(adhkarByCategoryProvider(_selectedCategory));

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Category tabs
            _buildCategoryTabs(),

            // Content
            Expanded(
              child: adhkarAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF4ECDC4)),
                ),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading adhkar',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                ),
                data: (items) => items.isEmpty
                    ? _buildEmptyState()
                    : _buildAdhkarPages(items),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          const Spacer(),
          Text(
            _selectedCategory.arabicName,
            style: const TextStyle(
              fontFamily: 'Amiri',
              color: Color(0xFF4ECDC4),
              fontSize: 22,
            ),
            textDirection: TextDirection.rtl,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.check_circle_outline, color: Colors.white),
            onPressed: _markSessionComplete,
            tooltip: 'Mark session complete',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final categories = [
      AdhkarCategory.morning,
      AdhkarCategory.evening,
      AdhkarCategory.sleep,
      AdhkarCategory.afterSalah,
      AdhkarCategory.protection,
    ];

    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(cat.displayName),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedCategory = cat;
                  _currentIndex = 0;
                  _reciteCounts = {};
                });
                _pageController?.jumpToPage(0);
              },
              backgroundColor: const Color(0xFF1A1A2E),
              selectedColor: const Color(0xFF4ECDC4),
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide.none,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_outlined,
            color: Colors.white.withValues(alpha: 0.3),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No adhkar available',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdhkarPages(List<AdhkarItem> items) {
    return Column(
      children: [
        // Page indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${_currentIndex + 1} / ${items.length}',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Pages
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: items.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) =>
                _buildAdhkarCard(items[index], index),
          ),
        ),

        // Navigation buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                onPressed: _currentIndex > 0
                    ? () => _pageController?.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      )
                    : null,
                icon: const Icon(Icons.arrow_back_ios),
                color: Colors.white54,
              ),
              const Spacer(),
              IconButton(
                onPressed: _currentIndex < items.length - 1
                    ? () => _pageController?.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      )
                    : null,
                icon: const Icon(Icons.arrow_forward_ios),
                color: Colors.white54,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdhkarCard(AdhkarItem item, int index) {
    final reciteCount = _reciteCounts[index] ?? 0;
    final isComplete = reciteCount >= item.repeatCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => _incrementReciteCount(index, item.repeatCount),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isComplete
                  ? const Color(0xFF4ECDC4).withValues(alpha: 0.5)
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Text(
                item.titleArabic,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 18,
                  color: Color(0xFF4ECDC4),
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Arabic content
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.contentArabic,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 26,
                    color: Colors.white,
                    height: 2,
                  ),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),

              // Transliteration
              if (item.contentTransliteration != null) ...[
                Text(
                  item.contentTransliteration!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
              ],

              // Translation
              Text(
                item.contentEnglish,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 15,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Repeat counter
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isComplete
                          ? const Color(0xFF4ECDC4).withValues(alpha: 0.2)
                          : const Color(0xFF2D2D44),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isComplete ? Icons.check_circle : Icons.touch_app,
                          color: isComplete
                              ? const Color(0xFF4ECDC4)
                              : Colors.white54,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isComplete
                              ? 'Complete!'
                              : 'Tap to count: $reciteCount/${item.repeatCount}',
                          style: TextStyle(
                            color: isComplete
                                ? const Color(0xFF4ECDC4)
                                : Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Source
              if (item.source != null) ...[
                const SizedBox(height: 16),
                Text(
                  item.source!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              // Benefit
              if (item.benefit != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ECDC4).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Color(0xFFFFD93D),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.benefit!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
