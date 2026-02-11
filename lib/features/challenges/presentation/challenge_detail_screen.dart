import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/challenges_repository.dart';
import '../data/models/challenge.dart';

/// Detailed view of a single challenge with leaderboard
class ChallengeDetailScreen extends ConsumerWidget {
  final String challengeId;

  const ChallengeDetailScreen({super.key, required this.challengeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengeAsync = ref.watch(challengeProvider(challengeId));
    final leaderboardAsync = ref.watch(leaderboardProvider(challengeId));
    final participationAsync = ref.watch(myParticipationProvider(challengeId));

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: challengeAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF4ECDC4)),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
        ),
        data: (challenge) {
          if (challenge == null) {
            return const Center(
              child: Text(
                'Challenge not found',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              // App bar with challenge header
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: const Color(0xFF1A1A2E),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHeader(challenge),
                ),
              ),

              // My progress section
              SliverToBoxAdapter(
                child: participationAsync.when(
                  loading: () => const SizedBox(),
                  error: (_, _) => const SizedBox(),
                  data: (participation) {
                    if (participation == null) {
                      return _buildJoinButton(context, ref, challenge);
                    }
                    return _buildMyProgressCard(
                      context,
                      challenge,
                      participation,
                    );
                  },
                ),
              ),

              // Leaderboard header
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Text(
                    '🏆 Leaderboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Leaderboard list
              leaderboardAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF4ECDC4)),
                  ),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Center(
                    child: Text(
                      'Error: $e',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
                data: (entries) {
                  if (entries.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'No participants yet. Be the first!',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _LeaderboardTile(
                        entry: entries[index],
                        target: challenge.targetValue,
                      ),
                      childCount: entries.length,
                    ),
                  );
                },
              ),

              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(Challenge challenge) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1A1A2E), const Color(0xFF0D0D1A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                challenge.challengeType.icon,
                style: const TextStyle(fontSize: 40),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4ECDC4).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        challenge.challengeType.displayName,
                        style: const TextStyle(
                          color: Color(0xFF4ECDC4),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      challenge.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            challenge.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatChip(
                Icons.flag,
                '${challenge.targetValue} ${challenge.targetUnit}',
              ),
              const SizedBox(width: 16),
              _buildStatChip(
                Icons.calendar_today,
                '${challenge.daysRemaining} days left',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white54),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildJoinButton(
    BuildContext context,
    WidgetRef ref,
    Challenge challenge,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: () async {
          final success = await ref
              .read(challengesRepositoryProvider)
              .joinChallenge(challenge.id);

          if (success && context.mounted) {
            ref.invalidate(myParticipationProvider(challengeId));
            ref.invalidate(leaderboardProvider(challengeId));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You joined the challenge!'),
                backgroundColor: Color(0xFF4ECDC4),
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4ECDC4),
          foregroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Join Challenge',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildMyProgressCard(
    BuildContext context,
    Challenge challenge,
    ChallengeParticipant participation,
  ) {
    final progress = participation.currentProgress;
    final target = challenge.targetValue;
    final percent = (progress / target).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF4ECDC4).withValues(alpha: 0.2),
              const Color(0xFF1A1A2E),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF4ECDC4).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Progress',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '$progress',
                  style: const TextStyle(
                    color: Color(0xFF4ECDC4),
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '/ $target ${challenge.targetUnit}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                if (participation.currentRank != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _getRankColor(participation.currentRank!),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '#${participation.currentRank}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 12,
                backgroundColor: const Color(0xFF2D2D44),
                valueColor: AlwaysStoppedAnimation(
                  percent >= 1.0 ? Colors.green : const Color(0xFF4ECDC4),
                ),
              ),
            ),
            if (participation.hasCompleted) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    'Completed!',
                    style: TextStyle(
                      color: Colors.green.shade400,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return Colors.orange.shade700;
      default:
        return const Color(0xFF4ECDC4);
    }
  }
}

class _LeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final int target;

  const _LeaderboardTile({required this.entry, required this.target});

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isCurrentUser = entry.userId == currentUserId;
    final percent = (entry.currentProgress / target).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? const Color(0xFF4ECDC4).withValues(alpha: 0.1)
            : const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: const Color(0xFF4ECDC4))
            : null,
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getRankColor(entry.rank).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: entry.rank <= 3
                  ? Text(
                      _getRankEmoji(entry.rank),
                      style: const TextStyle(fontSize: 20),
                    )
                  : Text(
                      '${entry.rank}',
                      style: TextStyle(
                        color: _getRankColor(entry.rank),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          // Name and progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName,
                  style: TextStyle(
                    color: isCurrentUser
                        ? const Color(0xFF4ECDC4)
                        : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 4,
                    backgroundColor: const Color(0xFF2D2D44),
                    valueColor: AlwaysStoppedAnimation(
                      percent >= 1.0 ? Colors.green : const Color(0xFF4ECDC4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.currentProgress}',
                style: const TextStyle(
                  color: Color(0xFF4ECDC4),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              if (entry.completedAt != null)
                const Text(
                  '✓ Done',
                  style: TextStyle(color: Colors.green, fontSize: 12),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return Colors.orange.shade700;
      default:
        return const Color(0xFF4ECDC4);
    }
  }

  String _getRankEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '';
    }
  }
}
