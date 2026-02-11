import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/challenges_repository.dart';
import '../data/models/user_badge.dart';

/// Screen displaying all user badges
class BadgesScreen extends ConsumerWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgesAsync = ref.watch(myBadgesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('My Badges'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: badgesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF4ECDC4)),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
        ),
        data: (badges) {
          if (badges.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🎖️', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text(
                    'No badges yet',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete challenges and milestones\nto earn badges!',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Group badges by type
          final grouped = <String, List<UserBadge>>{};
          for (final badge in badges) {
            grouped.putIfAbsent(badge.badgeType, () => []).add(badge);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: grouped.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(entry.key),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: entry.value
                        .map((badge) => BadgeCard(badge: badge))
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String type) {
    final displayName = type[0].toUpperCase() + type.substring(1);
    return Text(
      '$displayName Badges',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class BadgeCard extends StatelessWidget {
  final UserBadge badge;

  const BadgeCard({super.key, required this.badge});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showBadgeDetails(context),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1A1A2E),
              const Color(0xFF2D2D44).withValues(alpha: 0.5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: badge.isFeatured
                ? Colors.amber.withValues(alpha: 0.5)
                : Colors.white10,
          ),
          boxShadow: badge.isFeatured
              ? [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.2),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(badge.displayIcon, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              badge.badgeName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showBadgeDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF4ECDC4).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  badge.displayIcon,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              badge.badgeName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (badge.badgeDescription != null) ...[
              const SizedBox(height: 8),
              Text(
                badge.badgeDescription!,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Earned on ${_formatDate(badge.earnedAt)}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
