import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/challenges_repository.dart';
import '../data/models/challenge.dart';

/// Main hub for community challenges
class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Community Challenges'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events),
            onPressed: () => context.push('/challenges/badges'),
            tooltip: 'My Badges',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myChallengesProvider);
          ref.invalidate(activeChallengesProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // My active challenges
              _buildSectionHeader(context, 'My Challenges'),
              const SizedBox(height: 12),
              _buildMyChallenges(context, ref),

              const SizedBox(height: 32),

              // Discover challenges
              _buildSectionHeader(context, 'Discover Challenges'),
              const SizedBox(height: 12),
              _buildDiscoverChallenges(context, ref),

              // Bottom padding to ensure last item is visible above FAB
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/challenges/create'),
        backgroundColor: const Color(0xFF4ECDC4),
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text(
          'Create Challenge',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildMyChallenges(BuildContext context, WidgetRef ref) {
    final myChallenges = ref.watch(myChallengesProvider);

    return myChallenges.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF4ECDC4)),
      ),
      error: (e, _) => Center(
        child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
      ),
      data: (challenges) {
        if (challenges.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                const Text('🎯', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(
                  'No active challenges yet',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join a challenge below to get started!',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: challenges.map((data) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _MyChallengeCard(data: data),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDiscoverChallenges(BuildContext context, WidgetRef ref) {
    final challenges = ref.watch(activeChallengesProvider);

    return challenges.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF4ECDC4)),
      ),
      error: (e, _) => Center(
        child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
      ),
      data: (list) {
        if (list.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                'No challenges available right now',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              ),
            ),
          );
        }

        return Column(
          children: list.map((challenge) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _DiscoverChallengeCard(challenge: challenge),
            );
          }).toList(),
        );
      },
    );
  }
}

class _MyChallengeCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _MyChallengeCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final progress = data['my_progress'] as int? ?? 0;
    final target = data['target_value'] as int? ?? 1;
    final progressPercent = (progress / target).clamp(0.0, 1.0);
    final daysLeft = _getDaysLeft();

    return GestureDetector(
      onTap: () => context.push('/challenges/${data['challenge_id']}'),
      child: Container(
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
          border: Border.all(color: const Color(0xFF4ECDC4).withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(_getTypeIcon(), style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['title'] as String? ?? 'Challenge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$daysLeft days left',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildRankBadge(),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progressPercent,
                      minHeight: 8,
                      backgroundColor: const Color(0xFF2D2D44),
                      valueColor: AlwaysStoppedAnimation(
                        progressPercent >= 1.0
                            ? Colors.green
                            : const Color(0xFF4ECDC4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$progress / $target',
                  style: const TextStyle(
                    color: Color(0xFF4ECDC4),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeIcon() {
    final type = data['challenge_type'] as String?;
    switch (type) {
      case 'streak':
        return '🔥';
      case 'dhikr':
        return '📿';
      case 'quran':
        return '📖';
      default:
        return '🎯';
    }
  }

  int _getDaysLeft() {
    final endDate = DateTime.tryParse(data['end_date']?.toString() ?? '');
    if (endDate == null) return 0;
    return endDate.difference(DateTime.now()).inDays + 1;
  }

  Widget _buildRankBadge() {
    final rank = data['my_rank'] as int?;
    if (rank == null) return const SizedBox();

    Color badgeColor;
    switch (rank) {
      case 1:
        badgeColor = Colors.amber;
        break;
      case 2:
        badgeColor = Colors.grey.shade400;
        break;
      case 3:
        badgeColor = Colors.orange.shade700;
        break;
      default:
        badgeColor = const Color(0xFF4ECDC4);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor),
      ),
      child: Text(
        '#$rank',
        style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _DiscoverChallengeCard extends ConsumerWidget {
  final Challenge challenge;

  const _DiscoverChallengeCard({required this.challenge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/challenges/${challenge.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  challenge.challengeType.icon,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        challenge.description,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoChip(
                  Icons.flag,
                  '${challenge.targetValue} ${challenge.targetUnit}',
                ),
                const SizedBox(width: 12),
                _buildInfoChip(
                  Icons.calendar_today,
                  '${challenge.daysRemaining} days left',
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => _joinChallenge(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4ECDC4),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  child: const Text(
                    'Join',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white54),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  Future<void> _joinChallenge(BuildContext context, WidgetRef ref) async {
    try {
      final success = await ref
          .read(challengesRepositoryProvider)
          .joinChallenge(challenge.id);

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Joined "${challenge.title}"!'),
            backgroundColor: const Color(0xFF4ECDC4),
          ),
        );
        ref.invalidate(myChallengesProvider);
        ref.invalidate(activeChallengesProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error joining: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
